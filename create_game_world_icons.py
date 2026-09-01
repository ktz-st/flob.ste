#!/usr/bin/env python3
"""Import original world selector icons into canonical Scale2x PNG files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
FLOB_SRC = ROOT.parent / "flob"
WORLDS_SRC = FLOB_SRC / "worlds"
OUTPUT_ROOT = ROOT / "game_world_icons"
SRC_ICON_W = 96
SRC_ICON_H = 40
ICON_W = 192
ICON_H = 80

WORLD_DIRS = [
    "00_Escape_From_The_Lab",
    "01_Abominable_Sewers",
    "02_Suburbian_Parkour",
    "03_Hazardous_Mudlands",
    "04_Silver_Dust_Mines",
    "05_Return_To_The_Lab",
]


def normalize_palette(
    palette: list[int], pixels: list[int], n: int = 4
) -> tuple[list[int], list[int]]:
    def luminance(entry: tuple[int, int, int, int]) -> int:
        _, red, green, blue = entry
        return red * 299 + green * 587 + blue * 114

    entries = [
        (index, palette[index * 3], palette[index * 3 + 1], palette[index * 3 + 2])
        for index in range(n)
    ]
    sorted_entries = sorted(entries, key=luminance)
    remap = {
        old_index: new_index
        for new_index, (old_index, _, _, _) in enumerate(sorted_entries)
    }
    new_palette = list(palette)
    for new_index, (_, red, green, blue) in enumerate(sorted_entries):
        base = new_index * 3
        new_palette[base:base + 3] = [red, green, blue]
    return new_palette, [remap[int(pixel)] for pixel in pixels]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace canonical icon PNG files with fresh Scale2x imports",
    )
    return parser.parse_args()


def scale2x(source: Image.Image) -> Image.Image:
    if source.mode != "P":
        raise ValueError("World icon source must be an indexed image")
    if source.size != (SRC_ICON_W, SRC_ICON_H):
        raise ValueError(
            f"Expected {SRC_ICON_W}x{SRC_ICON_H}, got {source.size}"
        )

    raw_palette = source.getpalette() or []
    pixels = [int(value) for value in source.getdata()]
    if not set(pixels).issubset({0, 1, 2, 3}):
        raise ValueError("World icon uses palette indices outside 0..3")
    palette, pixels = normalize_palette(raw_palette, pixels, n=4)

    width, height = source.size
    output = Image.new("P", (width * 2, height * 2), 0)
    output.putpalette(palette)
    dst = output.load()

    def pixel(x: int, y: int) -> int:
        x = min(width - 1, max(0, x))
        y = min(height - 1, max(0, y))
        return pixels[y * width + x]

    for y in range(height):
        for x in range(width):
            center = pixel(x, y)
            top = pixel(x, y - 1)
            left = pixel(x - 1, y)
            right = pixel(x + 1, y)
            bottom = pixel(x, y + 1)

            dst[x * 2, y * 2] = (
                left if left == top and left != bottom and top != right else center
            )
            dst[x * 2 + 1, y * 2] = (
                right if top == right and top != left and right != bottom else center
            )
            dst[x * 2, y * 2 + 1] = (
                left if left == bottom and left != top and bottom != right else center
            )
            dst[x * 2 + 1, y * 2 + 1] = (
                right if bottom == right and left != bottom and top != right else center
            )

    return output


def validate_existing(path: Path) -> None:
    image = Image.open(path)
    if image.mode != "P":
        raise ValueError(f"{path}: canonical icon must be an indexed PNG")
    if image.size != (ICON_W, ICON_H):
        raise ValueError(
            f"{path}: expected {ICON_W}x{ICON_H}, got {image.size}"
        )
    used = set(image.getdata())
    if not used.issubset({0, 1, 2, 3}):
        raise ValueError(f"{path}: palette indices outside 0..3: {sorted(used)}")


def main() -> None:
    args = parse_args()
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    manifest_icons: list[dict] = []
    created = 0
    preserved = 0

    for world_index, world_dir in enumerate(WORLD_DIRS):
        source_path = (
            WORLDS_SRC / world_dir / "images" / "icon.gif"
        )
        output_path = OUTPUT_ROOT / f"world_{world_index:02d}.png"

        if output_path.exists() and not args.force:
            validate_existing(output_path)
            preserved += 1
        else:
            source = Image.open(source_path)
            if source.mode != "P":
                source = source.convert("P")
            scale2x(source).save(output_path, optimize=True)
            created += 1

        manifest_icons.append({
            "world": world_index,
            "source": str(source_path.relative_to(ROOT.parent)),
            "image": str(output_path.relative_to(ROOT)),
            "size": [ICON_W, ICON_H],
            "palette_indices": [0, 1, 2, 3],
        })

    manifest = {
        "canonical_build_source": True,
        "scale_algorithm": "Scale2x",
        "source_size": [SRC_ICON_W, SRC_ICON_H],
        "target_size": [ICON_W, ICON_H],
        "icon_count": len(manifest_icons),
        "icons": manifest_icons,
    }
    manifest_path = OUTPUT_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"canonical world icons: {len(manifest_icons)}")
    print(f"artwork created: {created}, preserved: {preserved}")
    print(f"wrote {manifest_path}")
    if preserved and not args.force:
        print("existing PNG files were preserved; use --force only to discard artist edits")


if __name__ == "__main__":
    main()
