#!/usr/bin/env python3
"""
Generate STE planar bitmap4 icons for the end-world summary screen.

Input assets are editable canonical 64x80 indexed PNGs.
Output bitmaps use the same raw ST-low interleaved bitplane layout as screen
memory, so they can be copied with BlitterCopyBitmap4.
"""

from __future__ import annotations

import json
from pathlib import Path
from PIL import Image

FLOB_STE = Path("/Users/kriss/GCC.ELF/flob-ste")
GAME_ICONS = FLOB_STE / "game_endworld_icons"
OUT = FLOB_STE / "assets" / "endworld_icons.inc"

ICONS = {
    "bigmap": "END_ICON_BIGMAP",
    "bigvial": "END_ICON_BIGVIAL",
    "bigformula": "END_ICON_BIGFORMULA",
    "skull": "END_ICON_SKULL",
}

ICON_W = 64
ICON_H = 80


def ste_word_from_rgb(r: int, g: int, b: int) -> int:
    # Standard ST 3-bit palette component range 0..7.
    rr = (r * 7 + 127) // 255
    gg = (g * 7 + 127) // 255
    bb = (b * 7 + 127) // 255
    return (rr << 8) | (gg << 4) | bb


def image_palette_words(path: Path) -> list[int]:
    im = Image.open(path)
    palette = im.getpalette() or []
    words: list[int] = []
    for i in range(16):
        base = i * 3
        if base + 2 < len(palette):
            words.append(ste_word_from_rgb(palette[base], palette[base + 1], palette[base + 2]))
        else:
            words.append(0)
    return words


def image_to_st_bitmap4(path: Path) -> bytes:
    im = Image.open(path)
    if im.mode != "P":
        im = im.convert("P")
    if im.size != (ICON_W, ICON_H):
        raise RuntimeError(f"{path}: expected {ICON_W}x{ICON_H}, got {im.size}")

    pixels = list(im.getdata())
    out = bytearray()
    for y in range(ICON_H):
        row = pixels[y * ICON_W : (y + 1) * ICON_W]
        for block_x in range(0, ICON_W, 16):
            for plane in range(4):
                word = 0
                for bit in range(16):
                    color = row[block_x + bit] & 15
                    if color & (1 << plane):
                        word |= 1 << (15 - bit)
                out.append((word >> 8) & 255)
                out.append(word & 255)
    return bytes(out)


def byte_array(name: str, data: bytes) -> str:
    vals = [f"${b:02X}" for b in data]
    rows = []
    for i in range(0, len(vals), 16):
        rows.append("    " + ",".join(vals[i : i + 16]))
    return f"const {name}: array[0..{len(data) - 1}] of byte = (\n" + ",\n".join(rows) + "\n);\n"


def word_array(name: str, data: list[int]) -> str:
    vals = [f"${w:03X}" for w in data]
    rows = []
    for i in range(0, len(vals), 8):
        rows.append("    " + ",".join(vals[i : i + 8]))
    return f"const {name}: array[0..{len(data) - 1}] of word = (\n" + ",\n".join(rows) + "\n);\n"


def main() -> None:
    manifest_path = GAME_ICONS / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    if not manifest.get("canonical_build_source"):
        raise RuntimeError(f"{manifest_path}: not marked as a canonical build source")
    if int(manifest.get("icon_count", 0)) != len(ICONS):
        raise RuntimeError(f"{manifest_path}: expected {len(ICONS)} icons")
    entries = {entry["name"]: FLOB_STE / entry["image"] for entry in manifest["icons"]}
    first_icon_path = entries["bigmap"]
    chunks = [
        "// Generated from canonical game_endworld_icons indexed PNG files.",
        f"const END_ICON_WIDTH = {ICON_W};",
        f"const END_ICON_HEIGHT = {ICON_H};",
        "",
        word_array("END_ICON_PAL", image_palette_words(first_icon_path)),
    ]
    for name, const_name in ICONS.items():
        chunks.append(byte_array(const_name, image_to_st_bitmap4(entries[name])))
    OUT.write_text("\n".join(chunks))
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
