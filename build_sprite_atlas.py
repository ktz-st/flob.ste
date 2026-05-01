#!/usr/bin/env python3
"""
Build a single indexed PNG atlas from all editable sprite sheets.

Output:
  flob-ste/images/sprite_atlas/all_sprites.png
  flob-ste/images/sprite_atlas/all_sprites.json

Rules:
- one sprite per row
- all frames for a sprite laid out horizontally
- common 16-color indexed palette
- palette indices 0..3 and 15 reserved
- visible sprite colors remapped into indices 4..14
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_STE = ROOT / "flob-ste"
SHEETS_DIR = FLOB_STE / "images" / "sprite_sheets_lsy"
OUT_DIR = FLOB_STE / "images" / "sprite_atlas"
ATLAS_PNG = OUT_DIR / "all_sprites.png"
ATLAS_JSON = OUT_DIR / "all_sprites.json"

RESERVED_INDICES = [0, 1, 2, 3, 15]
SPRITE_SLOT_START = 4
SPRITE_SLOT_END = 14
SPRITE_COLOR_COUNT = SPRITE_SLOT_END - SPRITE_SLOT_START + 1
ROW_GAP = 0
FRAME_GAP = 0


@dataclass
class FrameEntry:
    frame: int
    image: Image.Image
    w: int
    h: int
    source_x: int
    source_y: int


@dataclass
class SpriteEntry:
    name: str
    source_png: str
    source_json: str
    row_width: int
    row_height: int
    frames: list[FrameEntry]


def load_sheet_entries() -> list[SpriteEntry]:
    entries: list[SpriteEntry] = []
    for json_path in sorted(SHEETS_DIR.glob("*.json")):
        if json_path.name == ATLAS_JSON.name:
            continue
        meta = json.loads(json_path.read_text())
        png_path = json_path.with_suffix(".png")
        sheet = Image.open(png_path).convert("RGBA")

        frames: list[FrameEntry] = []
        row_width = 0
        row_height = 0
        for frame_meta in meta["frames_meta"]:
            x = int(frame_meta["x"])
            y = int(frame_meta["y"])
            w = int(frame_meta["w"])
            h = int(frame_meta["h"])
            frame = sheet.crop((x, y, x + w, y + h)).convert("RGBA")
            frames.append(
                FrameEntry(
                    frame=int(frame_meta["frame"]),
                    image=frame,
                    w=w,
                    h=h,
                    source_x=x,
                    source_y=y,
                )
            )
            row_width += w + FRAME_GAP
            row_height = max(row_height, h)
        if frames:
            row_width -= FRAME_GAP
        entries.append(
            SpriteEntry(
                name=meta["name"],
                source_png=str(png_path.relative_to(FLOB_STE)),
                source_json=str(json_path.relative_to(FLOB_STE)),
                row_width=row_width,
                row_height=row_height,
                frames=frames,
            )
        )
    return entries


def build_rgba_atlas(entries: list[SpriteEntry]) -> tuple[Image.Image, dict]:
    width = max((entry.row_width for entry in entries), default=16)
    height = sum(entry.row_height for entry in entries)
    if entries:
        height += ROW_GAP * (len(entries) - 1)
    height = max(height, 16)

    atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    rows_meta = []
    frames_meta = []

    y_cursor = 0
    for entry in entries:
        x_cursor = 0
        row_meta = {
            "name": entry.name,
            "x": 0,
            "y": y_cursor,
            "w": entry.row_width,
            "h": entry.row_height,
            "source_png": entry.source_png,
            "source_json": entry.source_json,
            "frame_count": len(entry.frames),
        }
        rows_meta.append(row_meta)

        for frame in entry.frames:
            atlas.alpha_composite(frame.image, (x_cursor, y_cursor))
            frames_meta.append(
                {
                    "sprite": entry.name,
                    "frame": frame.frame,
                    "x": x_cursor,
                    "y": y_cursor,
                    "w": frame.w,
                    "h": frame.h,
                    "source_x": frame.source_x,
                    "source_y": frame.source_y,
                    "source_png": entry.source_png,
                }
            )
            x_cursor += frame.w + FRAME_GAP
        y_cursor += entry.row_height + ROW_GAP

    meta = {
        "name": "all_sprites",
        "image": str(ATLAS_PNG.relative_to(FLOB_STE)),
        "reserved_indices": RESERVED_INDICES,
        "sprite_indices": list(range(SPRITE_SLOT_START, SPRITE_SLOT_END + 1)),
        "rows": rows_meta,
        "frames": frames_meta,
    }
    return atlas, meta


def quantize_opaque_colors(atlas: Image.Image) -> list[tuple[int, int, int]]:
    opaque = [(r, g, b) for (r, g, b, a) in atlas.getdata() if a]
    if not opaque:
        return []

    sample_w = min(512, max(1, len(opaque)))
    sample_h = math.ceil(len(opaque) / sample_w)
    sample = Image.new("RGB", (sample_w, sample_h))
    sample.putdata(opaque + [(0, 0, 0)] * (sample_w * sample_h - len(opaque)))
    quantized = sample.quantize(colors=SPRITE_COLOR_COUNT, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal = quantized.getpalette()[: SPRITE_COLOR_COUNT * 3]

    colors: list[tuple[int, int, int]] = []
    for i in range(0, len(pal), 3):
        rgb = (pal[i], pal[i + 1], pal[i + 2])
        if rgb not in colors:
            colors.append(rgb)
    return colors[:SPRITE_COLOR_COUNT]


def nearest_color_index(rgb: tuple[int, int, int], palette: list[tuple[int, int, int]]) -> int:
    best_idx = 0
    best_dist = 1 << 30
    for i, pal_rgb in enumerate(palette):
        dr = rgb[0] - pal_rgb[0]
        dg = rgb[1] - pal_rgb[1]
        db = rgb[2] - pal_rgb[2]
        dist = dr * dr + dg * dg + db * db
        if dist < best_dist:
            best_dist = dist
            best_idx = i
    return best_idx


def build_indexed_atlas(atlas: Image.Image, sprite_palette: list[tuple[int, int, int]]) -> tuple[Image.Image, list[tuple[int, int, int]]]:
    full_palette: list[tuple[int, int, int]] = [
        (0, 0, 0),       # 0 transparent
        (32, 32, 32),    # 1 reserved
        (96, 96, 96),    # 2 reserved
        (224, 224, 224), # 3 reserved
        *sprite_palette,
    ]
    while len(full_palette) < 15:
        full_palette.append((0, 0, 0))
    full_palette.append((255, 0, 255))  # 15 reserved

    indexed = Image.new("P", atlas.size, 0)
    flat_palette: list[int] = []
    for rgb in full_palette:
        flat_palette.extend(rgb)
    flat_palette.extend([0] * (768 - len(flat_palette)))
    indexed.putpalette(flat_palette)
    indexed.info["transparency"] = 0

    src = atlas.load()
    dst = indexed.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            r, g, b, a = src[x, y]
            if a == 0:
                dst[x, y] = 0
            else:
                slot = SPRITE_SLOT_START + nearest_color_index((r, g, b), sprite_palette)
                dst[x, y] = slot

    return indexed, full_palette


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    entries = load_sheet_entries()
    atlas_rgba, meta = build_rgba_atlas(entries)
    sprite_palette = quantize_opaque_colors(atlas_rgba)
    indexed, full_palette = build_indexed_atlas(atlas_rgba, sprite_palette)

    meta["palette_rgb"] = [list(rgb) for rgb in full_palette]
    meta["sprite_color_count"] = len(sprite_palette)
    meta["quantized_from_unique_colors"] = len({(r, g, b) for (r, g, b, a) in atlas_rgba.getdata() if a})
    meta["atlas_size"] = {"w": atlas_rgba.width, "h": atlas_rgba.height}

    indexed.save(ATLAS_PNG, transparency=0)
    ATLAS_JSON.write_text(json.dumps(meta, indent=2))
    print(f"wrote {ATLAS_PNG}")
    print(f"wrote {ATLAS_JSON}")
    print(f"sprite colors used: {len(sprite_palette)} / {SPRITE_COLOR_COUNT}")


if __name__ == "__main__":
    main()
