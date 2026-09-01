#!/usr/bin/env python3
"""Pack canonical 192x80 world selector PNG files as STE planar bitmap4."""

from __future__ import annotations

import json
from pathlib import Path
from PIL import Image

FLOB_STE = Path("/Users/kriss/GCC.ELF/flob-ste")
OUT = FLOB_STE / "assets" / "world_icons.inc"
GAME_WORLD_ICONS = FLOB_STE / "game_world_icons"

WORLD_COUNT = 6
ICON_W = 192
ICON_H = 80


def ste_word_from_rgb(r: int, g: int, b: int) -> int:
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
        raise RuntimeError(f"{path}: canonical icon must be an indexed PNG")
    if im.size != (ICON_W, ICON_H):
        raise RuntimeError(f"{path}: expected {ICON_W}x{ICON_H}, got {im.size}")

    pixels = [int(value) for value in im.getdata()]
    used_indices = set(pixels)
    if not used_indices.issubset({0, 1, 2, 3}):
        raise RuntimeError(
            f"{path}: palette indices outside 0..3: {sorted(used_indices)}"
        )
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
    manifest_path = GAME_WORLD_ICONS / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    if not manifest.get("canonical_build_source"):
        raise RuntimeError(f"{manifest_path}: not marked as a canonical build source")
    if int(manifest.get("icon_count", 0)) != WORLD_COUNT:
        raise RuntimeError(f"{manifest_path}: expected {WORLD_COUNT} icons")
    entries = sorted(manifest["icons"], key=lambda entry: int(entry["world"]))
    icon_paths = [FLOB_STE / entry["image"] for entry in entries]
    chunks = [
        "// Generated from canonical game_world_icons indexed PNG files.",
        f"const WORLD_ICON_WIDTH = {ICON_W};",
        f"const WORLD_ICON_HEIGHT = {ICON_H};",
        "",
    ]
    pal_names: list[str] = []
    names: list[str] = []
    for idx, icon_path in enumerate(icon_paths):
        bitmap = image_to_st_bitmap4(icon_path)

        pal_name = f"WORLD_ICON_PAL_{idx:02d}"
        pal_names.append(pal_name)
        chunks.append(word_array(pal_name, image_palette_words(icon_path)))

        const_name = f"WORLD_ICON_{idx:02d}"
        names.append(const_name)
        chunks.append(byte_array(const_name, bitmap))

    # Pointer array to per-world palettes
    chunks.append(f"const WORLD_ICON_PAL_PTRS: array[0..{len(pal_names) - 1}] of pointer = (")
    for idx, name in enumerate(pal_names):
        comma = "," if idx < len(pal_names) - 1 else ""
        chunks.append(f"    @{name}[0]{comma}")
    chunks.append(");\n")

    chunks.append(f"const WORLD_ICON_PTRS: array[0..{len(names) - 1}] of pointer = (")
    for idx, name in enumerate(names):
        comma = "," if idx < len(names) - 1 else ""
        chunks.append(f"    @{name}[0]{comma}")
    chunks.append(");")
    chunks.append("")

    OUT.write_text("\n".join(chunks))
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
