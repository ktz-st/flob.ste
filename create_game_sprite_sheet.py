#!/usr/bin/env python3
"""Create the canonical artist-editable sprite sheet from an extracted atlas.

The output PNG remains indexed and preserves palette indices exactly. Every
sprite row starts on a 16-pixel boundary, while JSON retains each frame's real
height so transparent padding is never included in generated STE assets.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

from sprite_combined_config import (
    MERGED_COMPOUND_ATLAS_GAPS,
    MERGED_OVERLAY_ATLAS_NAMES,
)


ROOT = Path(__file__).resolve().parent
ATLAS_DIR = ROOT / "images" / "sprite_atlas"
GRID_SIZE = 16
MIN_SHEET_WIDTH = 256


def aligned(value: int, alignment: int = GRID_SIZE) -> int:
    return (value + alignment - 1) // alignment * alignment


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        default="used_sprites",
        help="Source atlas basename under images/sprite_atlas",
    )
    parser.add_argument(
        "--output",
        default="game_sprites",
        help="Output basename under images/sprite_atlas",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite an existing canonical sheet",
    )
    parser.add_argument(
        "--guide-only",
        action="store_true",
        help="Rebuild only the labelled guide from the canonical output",
    )
    return parser.parse_args()


def make_guide(
    sheet: Image.Image,
    rows: list[dict],
    frames: list[dict],
    output_path: Path,
) -> None:
    scale = 2
    label_width = 320
    top_margin = 24
    guide = Image.new(
        "RGB",
        (label_width + sheet.width * scale, top_margin + sheet.height * scale),
        (28, 30, 32),
    )
    rgba = sheet.convert("RGBA")
    transparent_index = sheet.info.get("transparency", 0)
    if sheet.mode == "P":
        alpha = Image.new("L", sheet.size, 255)
        alpha.putdata([0 if px == transparent_index else 255 for px in sheet.getdata()])
        rgba.putalpha(alpha)
    guide.paste(
        rgba.resize((sheet.width * scale, sheet.height * scale), Image.Resampling.NEAREST),
        (label_width, top_margin),
        rgba.resize((sheet.width * scale, sheet.height * scale), Image.Resampling.NEAREST),
    )

    draw = ImageDraw.Draw(guide)
    draw.text((8, 6), "game_sprites.png - grid 16x16, build source", fill=(245, 245, 245))
    for x in range(0, sheet.width + 1, GRID_SIZE):
        gx = label_width + x * scale
        draw.line((gx, top_margin, gx, guide.height), fill=(65, 70, 74))

    frames_by_name: dict[str, list[dict]] = {}
    for frame in frames:
        frames_by_name.setdefault(frame["sprite"], []).append(frame)

    for row in rows:
        y = top_margin + int(row["y"]) * scale
        slot_height = int(row["slot_h"]) * scale
        draw.line((label_width, y, guide.width, y), fill=(115, 120, 124))
        draw.text((8, y + 3), row["name"], fill=(235, 235, 235))
        draw.text(
            (240, y + 3),
            f'{row["frame_count"]}f {row["frame_h"]}px',
            fill=(175, 180, 184),
        )
        for frame in frames_by_name.get(row["name"], []):
            fx = label_width + int(frame["x"]) * scale + 3
            draw.text((fx, y + 2), str(frame["frame"]), fill=(255, 220, 96))
        draw.line(
            (label_width, y + slot_height, guide.width, y + slot_height),
            fill=(65, 70, 74),
        )

    guide.save(output_path)


def main() -> None:
    args = parse_args()
    source_png = ATLAS_DIR / f"{args.source}.png"
    source_json = ATLAS_DIR / f"{args.source}.json"
    output_png = ATLAS_DIR / f"{args.output}.png"
    output_json = ATLAS_DIR / f"{args.output}.json"
    output_guide = ATLAS_DIR / f"{args.output}_guide.png"

    if args.guide_only:
        if not output_png.exists() or not output_json.exists():
            raise FileNotFoundError(f"Missing canonical atlas {output_png} / {output_json}")
        sheet = Image.open(output_png)
        output_meta = json.loads(output_json.read_text())
        make_guide(sheet, output_meta["rows"], output_meta["frames"], output_guide)
        print(f"wrote {output_guide} (reference only, not used by build)")
        return

    if not source_png.exists() or not source_json.exists():
        raise FileNotFoundError(f"Missing source atlas {source_png} / {source_json}")
    if not args.force and (output_png.exists() or output_json.exists()):
        raise FileExistsError(
            f"{output_png.name} already exists; use --force only to replace artist work"
        )

    source = Image.open(source_png)
    if source.mode != "P":
        raise ValueError("Source atlas must be an indexed PNG (mode P)")
    meta = json.loads(source_json.read_text())
    source_rows = meta.get("rows", [])
    source_frames = meta.get("frames", [])
    if not source_rows or not source_frames:
        raise ValueError("Source atlas JSON has no rows or frames")

    frames_by_name: dict[str, list[dict]] = {}
    for frame in source_frames:
        frames_by_name.setdefault(frame["sprite"], []).append(frame)
    for frames in frames_by_name.values():
        frames.sort(key=lambda item: item["frame"])

    transparent_index = int(source.info.get("transparency", 0))
    palette = source.getpalette()
    if palette is None:
        raise ValueError("Source atlas has no indexed palette")

    def frame_image(frame: dict) -> Image.Image:
        return source.crop(
            (
                int(frame["x"]),
                int(frame["y"]),
                int(frame["x"]) + int(frame["w"]),
                int(frame["y"]) + int(frame["h"]),
            )
        )

    def paste_opaque(dst: Image.Image, src: Image.Image, x: int) -> None:
        mask = Image.new("L", src.size, 0)
        mask.putdata([0 if px == transparent_index else 255 for px in src.getdata()])
        dst.paste(src, (x, 0), mask)

    def merge_pair(base_name: str, gap_px: int) -> list[Image.Image]:
        p0_name = f"{base_name}_p0"
        p1_name = f"{base_name}_p1"
        p0_frames = frames_by_name.get(p0_name)
        p1_frames = frames_by_name.get(p1_name)
        if not p0_frames or not p1_frames:
            raise ValueError(f"Missing source layers {p0_name}/{p1_name}")
        if len(p0_frames) != len(p1_frames):
            raise ValueError(f"Layer frame count differs for {base_name}")

        merged: list[Image.Image] = []
        for p0_frame, p1_frame in zip(p0_frames, p1_frames):
            if int(p0_frame["h"]) != int(p1_frame["h"]):
                raise ValueError(f"Layer frame height differs for {base_name}")
            width = max(int(p0_frame["w"]), gap_px + int(p1_frame["w"]))
            height = int(p0_frame["h"])
            image = Image.new("P", (width, height), transparent_index)
            image.putpalette(palette)
            paste_opaque(image, frame_image(p0_frame), 0)
            # P1 is the top layer, matching the existing STE blit order.
            paste_opaque(image, frame_image(p1_frame), gap_px)
            merged.append(image)
        return merged

    overlay_by_layer: dict[str, str] = {}
    compound_by_layer: dict[str, tuple[str, int]] = {}
    for base_name in MERGED_OVERLAY_ATLAS_NAMES:
        overlay_by_layer[f"{base_name}_p0"] = base_name
        overlay_by_layer[f"{base_name}_p1"] = base_name
    for base_name, gap_a8 in MERGED_COMPOUND_ATLAS_GAPS.items():
        compound_by_layer[f"{base_name}_p0"] = (base_name, gap_a8 * 2)
        compound_by_layer[f"{base_name}_p1"] = (base_name, gap_a8 * 2)

    entries: list[dict] = []
    emitted: set[str] = set()
    for source_row in source_rows:
        source_name = source_row["name"]
        if source_name in overlay_by_layer:
            base_name = overlay_by_layer[source_name]
            name = f"{base_name}_merged"
            if name in emitted:
                continue
            images = merge_pair(base_name, 0)
            merge_mode = "overlay"
            derived_from = [f"{base_name}_p0", f"{base_name}_p1"]
        elif source_name in compound_by_layer:
            base_name, gap_px = compound_by_layer[source_name]
            name = f"{base_name}_compound"
            if name in emitted:
                continue
            images = merge_pair(base_name, gap_px)
            merge_mode = "compound"
            derived_from = [f"{base_name}_p0", f"{base_name}_p1"]
        else:
            name = source_name
            images = [frame_image(frame) for frame in frames_by_name.get(name, [])]
            merge_mode = "direct"
            derived_from = [name]

        if not images:
            raise ValueError(f"Sprite row {name} has no frames")
        frame_width = images[0].width
        frame_height = images[0].height
        if any(image.size != (frame_width, frame_height) for image in images):
            raise ValueError(f"Frame dimensions differ within sprite {name}")
        slot_width = aligned(frame_width)
        entries.append(
            {
                "name": name,
                "images": images,
                "frame_w": frame_width,
                "frame_h": frame_height,
                "slot_w": slot_width,
                "slot_h": aligned(frame_height),
                "merge_mode": merge_mode,
                "derived_from": derived_from,
                "source_row": source_row,
            }
        )
        emitted.add(name)

    output_rows: list[dict] = []
    output_frames: list[dict] = []
    next_y = 0
    sheet_width = MIN_SHEET_WIDTH
    for entry in entries:
        sheet_width = max(sheet_width, entry["slot_w"] * len(entry["images"]))
    sheet_width = aligned(sheet_width)

    for entry in entries:
        name = entry["name"]
        source_row = entry["source_row"]
        row = dict(source_row)
        row["name"] = name
        row["x"] = 0
        row["y"] = next_y
        row["w"] = entry["slot_w"] * len(entry["images"])
        row["h"] = entry["frame_h"]
        row["frame_count"] = len(entry["images"])
        row["slot_w"] = entry["slot_w"]
        row["slot_h"] = entry["slot_h"]
        row["frame_w"] = entry["frame_w"]
        row["frame_h"] = entry["frame_h"]
        row["merge_mode"] = entry["merge_mode"]
        row["derived_from"] = entry["derived_from"]
        output_rows.append(row)

        for frame_index, image in enumerate(entry["images"]):
            output_frames.append(
                {
                    "sprite": name,
                    "frame": frame_index,
                    "x": frame_index * entry["slot_w"],
                    "y": next_y,
                    "w": image.width,
                    "h": image.height,
                    "source_x": 0,
                    "source_y": 0,
                    "source_png": "",
                }
            )

        next_y += entry["slot_h"]

    sheet = Image.new("P", (sheet_width, next_y), transparent_index)
    sheet.putpalette(palette)
    sheet.info["transparency"] = transparent_index

    for entry, row in zip(entries, output_rows):
        for frame_index, image in enumerate(entry["images"]):
            sheet.paste(image, (frame_index * entry["slot_w"], int(row["y"])))

    output_meta = dict(meta)
    output_meta["name"] = args.output
    output_meta["image"] = str(output_png.relative_to(ROOT))
    output_meta["rows"] = output_rows
    output_meta["frames"] = output_frames
    output_meta["atlas_size"] = {"w": sheet.width, "h": sheet.height}
    output_meta["layout"] = {
        "canonical_build_source": True,
        "grid_w": GRID_SIZE,
        "grid_h": GRID_SIZE,
        "sheet_w": sheet_width,
        "row_height_rule": "ceil(frame_h / 16) * 16",
        "frame_width_rule": "ceil(frame_w / 16) * 16",
        "combined_layers_are_final": True,
        "transparent_index": int(sheet.info["transparency"]),
    }

    sheet.save(output_png, transparency=sheet.info["transparency"])
    output_json.write_text(json.dumps(output_meta, indent=2) + "\n")
    make_guide(sheet, output_rows, output_frames, output_guide)

    print(f"wrote {output_png} ({sheet.width}x{sheet.height})")
    print(f"wrote {output_json}")
    print(f"wrote {output_guide} (reference only, not used by build)")
    print(f"sprite rows: {len(output_rows)}, frames: {len(output_frames)}")


if __name__ == "__main__":
    main()
