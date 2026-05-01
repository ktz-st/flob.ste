#!/usr/bin/env python3
"""
Generate STE-native masked sprite assets from the unified indexed atlas.

Input:
  flob-ste/images/sprite_atlas/all_sprites.png
  flob-ste/images/sprite_atlas/all_sprites.json

Output:
  flob-ste/generated/sprite_assets_atlas/*.inc
  flob-ste/generated/sprite_assets_atlas.inc
  flob-ste/generated/sprite_atlas_palette.inc
"""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

from PIL import Image

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_STE = ROOT / "flob-ste"
ATLAS_JSON = FLOB_STE / "images" / "sprite_atlas" / "all_sprites.json"
ATLAS_PNG = FLOB_STE / "images" / "sprite_atlas" / "all_sprites.png"
OUT_DIR = FLOB_STE / "generated" / "sprite_assets_atlas"
MASTER_INC = FLOB_STE / "generated" / "sprite_assets_atlas.inc"
PALETTE_INC = FLOB_STE / "generated" / "sprite_atlas_palette.inc"


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


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    meta = json.loads(ATLAS_JSON.read_text())
    atlas = Image.open(ATLAS_PNG)
    if atlas.mode != "P":
        raise ValueError("Atlas must be indexed PNG (mode P)")
    atlas_px = atlas.load()

    palette_rgb = [tuple(rgb) for rgb in meta["palette_rgb"]]
    palette_words = [rgb_to_st_word(rgb) for rgb in palette_rgb]

    by_sprite: dict[str, list[dict]] = defaultdict(list)
    for frame_meta in meta["frames"]:
        by_sprite[frame_meta["sprite"]].append(frame_meta)
    for frames in by_sprite.values():
        frames.sort(key=lambda item: item["frame"])

    outputs: list[Path] = []
    for sprite_name in sorted(by_sprite):
        ident = to_ident(sprite_name)
        frames_meta = []
        word_blob: list[int] = []

        for frame_meta in by_sprite[sprite_name]:
            x = int(frame_meta["x"])
            y = int(frame_meta["y"])
            w = int(frame_meta["w"])
            h = int(frame_meta["h"])
            indices: list[int] = []
            for py in range(y, y + h):
                for px in range(x, x + w):
                    indices.append(int(atlas_px[px, py]) & 0x0F)

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
