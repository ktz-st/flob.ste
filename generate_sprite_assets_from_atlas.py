#!/usr/bin/env python3
"""
Generate STE-native masked sprite assets from the indexed sprite atlas.

Input:
  flob-ste/images/sprite_atlas/used_sprites.png
  flob-ste/images/sprite_atlas/used_sprites.json

Output:
  flob-ste/generated/sprite_assets_atlas/*.inc
  flob-ste/generated/sprite_assets_atlas.inc
  flob-ste/generated/sprite_atlas_palette.inc
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path

from PIL import Image

from sprite_combined_config import (
    MERGED_COMPOUND_ATLAS_GAPS,
    MERGED_OVERLAY_ATLAS_NAMES,
)

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_STE = ROOT / "flob-ste"
DEFAULT_ATLAS_NAME = "used_sprites"
OUT_DIR = FLOB_STE / "generated" / "sprite_assets_atlas"
MASTER_INC = FLOB_STE / "generated" / "sprite_assets_atlas.inc"
PALETTE_INC = FLOB_STE / "generated" / "sprite_atlas_palette.inc"

FLOB_EXPLOSION_MASKS = (
    (0x10, 0x82, 0x20, 0x08, 0x81, 0x10, 0x44, 0x00),
    (0x22, 0x08, 0x81, 0x10, 0x04, 0x41, 0x08, 0x00),
)


def to_ident(name: str) -> str:
    return "".join(ch if ch.isalnum() else "_" for ch in name).upper()


def rgb_to_st_word(rgb: tuple[int, int, int]) -> int:
    r = (rgb[0] * 7 + 127) // 255
    g = (rgb[1] * 7 + 127) // 255
    b = (rgb[2] * 7 + 127) // 255
    return (r << 8) | (g << 4) | b


def words_to_pascal_array(name: str, data: list[int]) -> str:
    if not data:
        data = [0]
    vals = [f"${w:04X}" for w in data]
    rows = []
    for i in range(0, len(vals), 8):
        rows.append("  " + ",".join(vals[i:i + 8]))
    body = ",\n".join(rows)
    return f"const {name} : array[0..{len(data)-1}] of word=(\n{body}\n);\n"


def pack_masked_words(width: int, height: int, indices: list[int]) -> tuple[int, list[int], list[int]]:
    row_words = (width + 15) // 16
    mask_words: list[int] = []
    gfx_words: list[int] = []

    for y in range(height):
        row = indices[y * width:(y + 1) * width]
        for word_idx in range(row_words):
            mask = 0xFFFF
            planes = [0, 0, 0, 0]
            base_x = word_idx * 16
            for bit_idx in range(16):
                x = base_x + bit_idx
                if x >= width:
                    continue
                color = row[x] & 0x0F
                if color == 0:
                    continue
                bit = 1 << (15 - bit_idx)
                mask &= (~bit) & 0xFFFF
                if color & 1:
                    planes[0] |= bit
                if color & 2:
                    planes[1] |= bit
                if color & 4:
                    planes[2] |= bit
                if color & 8:
                    planes[3] |= bit
            mask_words.append(mask)
            gfx_words.extend(planes)

    return row_words, mask_words, gfx_words


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--atlas",
        default=DEFAULT_ATLAS_NAME,
        help="Atlas basename under images/sprite_atlas, without .png/.json",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    atlas_json = FLOB_STE / "images" / "sprite_atlas" / f"{args.atlas}.json"
    atlas_png = FLOB_STE / "images" / "sprite_atlas" / f"{args.atlas}.png"

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old_inc in OUT_DIR.glob("*.inc"):
        old_inc.unlink()

    meta = json.loads(atlas_json.read_text())
    atlas = Image.open(atlas_png)
    if atlas.mode != "P":
        raise ValueError("Atlas must be indexed PNG (mode P)")
    atlas_px = atlas.load()

    raw_palette = atlas.getpalette()
    if raw_palette is None:
        raise ValueError("Atlas PNG has no indexed palette")
    palette_rgb = [
        tuple(raw_palette[i * 3:i * 3 + 3])
        for i in range(16)
    ]
    palette_words = [rgb_to_st_word(rgb) for rgb in palette_rgb]

    by_sprite: dict[str, list[dict]] = defaultdict(list)
    for frame_meta in meta["frames"]:
        by_sprite[frame_meta["sprite"]].append(frame_meta)
    for frames in by_sprite.values():
        frames.sort(key=lambda item: item["frame"])

    generated_sprites: dict[str, list[dict]] = dict(by_sprite)
    for base_name in sorted(MERGED_OVERLAY_ATLAS_NAMES):
        p0_name = f"{base_name}_p0"
        p1_name = f"{base_name}_p1"
        if p0_name not in by_sprite or p1_name not in by_sprite:
            raise ValueError(f"Missing overlay rows {p0_name}/{p1_name}")
        p0_frames = by_sprite[p0_name]
        p1_frames = by_sprite[p1_name]
        if len(p0_frames) != len(p1_frames):
            raise ValueError(f"Overlay frame count differs for {base_name}")

        merged_frames: list[dict] = []
        for p0_frame, p1_frame in zip(p0_frames, p1_frames):
            if (p0_frame["w"], p0_frame["h"]) != (p1_frame["w"], p1_frame["h"]):
                raise ValueError(f"Overlay frame dimensions differ for {base_name}")
            merged_frames.append({
                "frame": p0_frame["frame"],
                "x": p0_frame["x"],
                "y": p0_frame["y"],
                "w": p0_frame["w"],
                "h": p0_frame["h"],
                "merge_p0": p0_frame,
                "merge_p1": p1_frame,
            })
        del generated_sprites[p0_name]
        del generated_sprites[p1_name]
        generated_sprites[f"{base_name}_merged"] = merged_frames

    for base_name, gap_a8 in sorted(MERGED_COMPOUND_ATLAS_GAPS.items()):
        p0_name = f"{base_name}_p0"
        p1_name = f"{base_name}_p1"
        if p0_name not in by_sprite or p1_name not in by_sprite:
            raise ValueError(f"Missing compound rows {p0_name}/{p1_name}")
        p0_frames = by_sprite[p0_name]
        p1_frames = by_sprite[p1_name]
        if len(p0_frames) != len(p1_frames):
            raise ValueError(f"Compound frame count differs for {base_name}")

        gap_px = gap_a8 * 2
        compound_frames: list[dict] = []
        for p0_frame, p1_frame in zip(p0_frames, p1_frames):
            if int(p0_frame["h"]) != int(p1_frame["h"]):
                raise ValueError(f"Compound frame height differs for {base_name}")
            compound_frames.append({
                "frame": p0_frame["frame"],
                "x": p0_frame["x"],
                "y": p0_frame["y"],
                "w": max(int(p0_frame["w"]), gap_px + int(p1_frame["w"])),
                "h": p0_frame["h"],
                "compound_p0": p0_frame,
                "compound_p1": p1_frame,
                "compound_gap_px": gap_px,
            })
        del generated_sprites[p0_name]
        del generated_sprites[p1_name]
        generated_sprites[f"{base_name}_compound"] = compound_frames

    # The A8 death effect moves Flob's final P0/P1 patterns independently.
    # Keep deriving these helper sprites from the editable atlas so recolouring
    # Flob does not require hand-maintained Pascal assets.
    if "flob" not in by_sprite or len(by_sprite["flob"]) <= 14:
        raise ValueError("Flob frame 14 is required for the death animation")
    explosion_frame = by_sprite["flob"][14]
    for layer in range(2):
        layer_frame = dict(explosion_frame)
        layer_frame["flob_explosion_layer"] = layer
        generated_sprites[f"flob_explode_p{layer}"] = [layer_frame]

    generated_sprites["flob_particle_p0"] = [{
        "frame": 0,
        "x": int(explosion_frame["x"]) + 6,
        "y": int(explosion_frame["y"]),
        "w": 2,
        "h": 2,
    }]
    generated_sprites["flob_particle_p1"] = [{
        "frame": 0,
        "x": int(explosion_frame["x"]) + 4,
        "y": int(explosion_frame["y"]),
        "w": 2,
        "h": 2,
    }]

    outputs: list[Path] = []
    for sprite_name in sorted(generated_sprites):
        ident = to_ident(sprite_name)
        frames_meta = []
        word_blob: list[int] = []

        def append_frame(frame_meta: dict, vertical_flip: bool = False) -> None:
            x = int(frame_meta["x"])
            y = int(frame_meta["y"])
            w = int(frame_meta["w"])
            h = int(frame_meta["h"])
            indices: list[int] = []
            merge_p0 = frame_meta.get("merge_p0")
            merge_p1 = frame_meta.get("merge_p1")
            compound_p0 = frame_meta.get("compound_p0")
            compound_p1 = frame_meta.get("compound_p1")
            compound_gap_px = int(frame_meta.get("compound_gap_px", 0))
            explosion_layer = frame_meta.get("flob_explosion_layer")
            row_range = range(h - 1, -1, -1) if vertical_flip else range(h)
            for row_y in row_range:
                for column_x in range(w):
                    if explosion_layer is not None:
                        logical_x = column_x // 2
                        logical_y = row_y // 2
                        bit = 0x80 >> logical_x
                        if FLOB_EXPLOSION_MASKS[explosion_layer][logical_y] & bit:
                            color_index = int(atlas_px[x + column_x, y + row_y])
                        else:
                            color_index = 0
                    elif compound_p0 is not None and compound_p1 is not None:
                        p0_index = 0
                        p1_index = 0
                        if column_x < int(compound_p0["w"]):
                            p0_index = int(atlas_px[
                                int(compound_p0["x"]) + column_x,
                                int(compound_p0["y"]) + row_y,
                            ])
                        p1_x = column_x - compound_gap_px
                        if 0 <= p1_x < int(compound_p1["w"]):
                            p1_index = int(atlas_px[
                                int(compound_p1["x"]) + p1_x,
                                int(compound_p1["y"]) + row_y,
                            ])
                        color_index = p1_index if p1_index != 0 else p0_index
                    elif merge_p0 is not None and merge_p1 is not None:
                        p0_index = int(atlas_px[
                            int(merge_p0["x"]) + column_x,
                            int(merge_p0["y"]) + row_y,
                        ])
                        p1_index = int(atlas_px[
                            int(merge_p1["x"]) + column_x,
                            int(merge_p1["y"]) + row_y,
                        ])
                        # This matches the existing P0-then-P1 masked blit order.
                        color_index = p1_index if p1_index != 0 else p0_index
                    else:
                        color_index = int(atlas_px[x + column_x, y + row_y])
                    if color_index > 15:
                        raise ValueError(
                            f"{args.atlas}.png uses palette index {color_index} at "
                            f"frame pixel ({column_x},{row_y}) in sprite {sprite_name}; "
                            "STE sprites support only indices 0..15"
                        )
                    indices.append(color_index)

            row_words, mask_words, gfx_words = pack_masked_words(w, h, indices)
            mask_offset = len(word_blob)
            word_blob.extend(mask_words)
            data_offset = len(word_blob)
            word_blob.extend(gfx_words)

            frames_meta.append(
                "    (widthPx:{w}; heightPx:{h}; rowWords:{rw}; maskOffset:{mo}; "
                "dataOffset:{do}; paletteOffset:0; paletteCount:0)".format(
                    w=w,
                    h=h,
                    rw=row_words,
                    mo=mask_offset,
                    do=data_offset,
                )
            )

        for frame_meta in generated_sprites[sprite_name]:
            append_frame(frame_meta)
        for frame_meta in generated_sprites[sprite_name]:
            append_frame(frame_meta, vertical_flip=True)

        out_path = OUT_DIR / f"{sprite_name}.inc"
        with out_path.open("w") as f:
            f.write(f"const SPR_{ident}_FRAME_COUNT = {len(frames_meta)};\n")
            f.write(
                f"const SPR_{ident}_FRAMES : array[0..{len(frames_meta)-1}] of TSteSpriteFrame = (\n"
            )
            f.write(",\n".join(frames_meta))
            f.write("\n);\n\n")
            f.write(words_to_pascal_array(f"SPR_{ident}_WORDS", word_blob))
        outputs.append(out_path)
        print(f"generated atlas sprite {sprite_name} -> {out_path.name}")

    with MASTER_INC.open("w") as f:
        for out_path in outputs:
            f.write(f"{{$i generated/sprite_assets_atlas/{out_path.name}}}\n")

    with PALETTE_INC.open("w") as f:
        f.write(words_to_pascal_array("SPRITE_ATLAS_PAL", palette_words))

    print(f"wrote {MASTER_INC}")
    print(f"wrote {PALETTE_INC}")


if __name__ == "__main__":
    main()
