#!/usr/bin/env python3
"""Import original end-world icons into canonical Scale2x PNG files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE_ROOT = ROOT.parent / "flob" / "assets"
OUTPUT_ROOT = ROOT / "game_endworld_icons"
SRC_SIZE = (32, 40)
TARGET_SIZE = (64, 80)
ICONS = [
    ("bigmap", "bigmap.gif"),
    ("bigvial", "bigvial.gif"),
    ("bigformula", "bigformula.gif"),
    ("skull", "skull.gif"),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace canonical icon PNG files with fresh Scale2x imports",
    )
    return parser.parse_args()


def scale2x(source: Image.Image) -> Image.Image:
    if source.mode != "P" or source.size != SRC_SIZE:
        raise ValueError(f"Expected indexed {SRC_SIZE[0]}x{SRC_SIZE[1]} icon")
    pixels = [int(value) for value in source.getdata()]
    if not set(pixels).issubset({0, 1, 2, 3}):
        raise ValueError("End-world icon uses palette indices outside 0..3")

    width, height = source.size
    output = Image.new("P", TARGET_SIZE, 0)
    output.putpalette(source.getpalette() or [])
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
    if image.mode != "P" or image.size != TARGET_SIZE:
        raise ValueError(f"{path}: expected indexed {TARGET_SIZE[0]}x{TARGET_SIZE[1]} PNG")
    used = set(image.getdata())
    if not used.issubset({0, 1, 2, 3}):
        raise ValueError(f"{path}: palette indices outside 0..3: {sorted(used)}")


def main() -> None:
    args = parse_args()
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    entries: list[dict] = []
    created = 0
    preserved = 0

    for name, source_name in ICONS:
        source_path = SOURCE_ROOT / source_name
        output_path = OUTPUT_ROOT / f"{name}.png"
        if output_path.exists() and not args.force:
            validate_existing(output_path)
            preserved += 1
        else:
            source = Image.open(source_path)
            if source.mode != "P":
                source = source.convert("P")
            scale2x(source).save(output_path, optimize=True)
            created += 1
        entries.append({
            "name": name,
            "source": str(source_path.relative_to(ROOT.parent)),
            "image": str(output_path.relative_to(ROOT)),
            "size": list(TARGET_SIZE),
            "palette_indices": [0, 1, 2, 3],
        })

    manifest = {
        "canonical_build_source": True,
        "scale_algorithm": "Scale2x",
        "source_size": list(SRC_SIZE),
        "target_size": list(TARGET_SIZE),
        "icon_count": len(entries),
        "icons": entries,
    }
    manifest_path = OUTPUT_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"canonical end-world icons: {len(entries)}")
    print(f"artwork created: {created}, preserved: {preserved}")
    print(f"wrote {manifest_path}")


if __name__ == "__main__":
    main()
