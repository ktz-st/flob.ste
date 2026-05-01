#!/usr/bin/env python3
"""
Generate STE-native masked sprite assets from editable PNG sprite sheets.

Input:
  flob-ste/images/sprite_sheets_lsy/*.png
  flob-ste/images/sprite_sheets_lsy/*.json

Output:
  flob-ste/generated/sprite_assets_lsy/*.inc
  flob-ste/generated/sprite_assets_lsy.inc
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_STE = ROOT / "flob-ste"
SHEETS_DIR = FLOB_STE / "images" / "sprite_sheets_lsy"
OUT_DIR = FLOB_STE / "generated" / "sprite_assets_lsy"
MASTER_INC = FLOB_STE / "generated" / "sprite_assets_lsy.inc"


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


def load_frame_rgba(sheet: Image.Image, frame_meta: dict) -> Image.Image:
    x = frame_meta["x"]
    y = frame_meta["y"]
    w = frame_meta["w"]
    h = frame_meta["h"]
    return sheet.crop((x, y, x + w, y + h)).convert("RGBA")


def collect_palette(
    frame: Image.Image, fixed_palette: list[tuple[int, int, int]] | None = None
) -> tuple[list[tuple[int, int, int]], list[int]]:
    palette: list[tuple[int, int, int]] = []
    indices: list[int] = []
    px = frame.load()
    if fixed_palette:
        palette = list(fixed_palette)
    for y in range(frame.height):
        for x in range(frame.width):
            r, g, b, a = px[x, y]
            if a == 0:
                indices.append(0)
                continue
            rgb = (r, g, b)
            try:
                idx = palette.index(rgb) + 1
            except ValueError:
                if len(palette) >= 15:
                    raise ValueError("Sprite frame uses more than 15 opaque colors")
                palette.append(rgb)
                idx = len(palette)
            indices.append(idx)
    return palette, indices


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
                color = row[x]
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


def generate_one(json_path: Path) -> Path:
    meta = json.loads(json_path.read_text())
    png_path = json_path.with_suffix(".png")
    sheet = Image.open(png_path).convert("RGBA")
    ident = to_ident(meta["name"])

    frames_meta = []
    word_blob: list[int] = []
    palette_blob: list[int] = []
    fixed_palette: list[tuple[int, int, int]] | None = None

    if meta.get("name") == "flob":
        first_meta = meta["frames_meta"][0]
        if "p0_rgb" in first_meta and "p1_rgb" in first_meta and "overlap_rgb" in first_meta:
            fixed_palette = [
                tuple(first_meta["p0_rgb"]),
                tuple(first_meta["p1_rgb"]),
                tuple(first_meta["overlap_rgb"]),
            ]

    for frame_meta in meta["frames_meta"]:
        frame = load_frame_rgba(sheet, frame_meta)
        palette_rgbs, indices = collect_palette(frame, fixed_palette)
        palette_words = [rgb_to_st_word(rgb) for rgb in palette_rgbs]
        row_words, mask_words, gfx_words = pack_masked_words(frame.width, frame.height, indices)

        palette_offset = len(palette_blob)
        palette_blob.extend(palette_words)

        mask_offset = len(word_blob)
        word_blob.extend(mask_words)
        data_offset = len(word_blob)
        word_blob.extend(gfx_words)

        frames_meta.append(
            "    (widthPx:{w}; heightPx:{h}; rowWords:{rw}; maskOffset:{mo}; "
            "dataOffset:{do}; paletteOffset:{po}; paletteCount:{pc})".format(
                w=frame.width,
                h=frame.height,
                rw=row_words,
                mo=mask_offset,
                do=data_offset,
                po=palette_offset,
                pc=len(palette_words),
            )
        )

    out_path = OUT_DIR / f"{meta['name']}.inc"
    with out_path.open("w") as f:
        f.write(f"const SPR_{ident}_FRAME_COUNT = {len(frames_meta)};\n")
        f.write(f"const SPR_{ident}_FRAMES : array[0..{len(frames_meta)-1}] of TSteSpriteFrame = (\n")
        f.write(",\n".join(frames_meta))
        f.write("\n);\n\n")
        f.write(words_to_pascal_array(f"SPR_{ident}_WORDS", word_blob))
        f.write("\n")
        f.write(words_to_pascal_array(f"SPR_{ident}_PALS", palette_blob))
    return out_path


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = []
    for json_path in sorted(SHEETS_DIR.glob("*.json")):
        out_path = generate_one(json_path)
        outputs.append(out_path)
        print(f"generated {json_path.name} -> {out_path.name}")

    with MASTER_INC.open("w") as f:
        for out_path in outputs:
            f.write(f"{{$i generated/sprite_assets_lsy/{out_path.name}}}\n")

    print(f"done: {len(outputs)} sprite asset includes in {OUT_DIR}")


if __name__ == "__main__":
    main()
