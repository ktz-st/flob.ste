#!/usr/bin/env python3
"""Import the original title artwork into canonical Scale2x PNG files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE_ROOT = ROOT.parent / "flob" / "assets"
OUTPUT_ROOT = ROOT / "game_title"
SOURCE_SIZE = (160, 92)
TARGET_SIZE = (320, 184)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace canonical title PNG files with fresh Scale2x imports",
    )
    return parser.parse_args()


def scale2x(source: Image.Image) -> Image.Image:
    if source.mode != "P" or source.size != SOURCE_SIZE:
        raise ValueError(f"Title source must be indexed {SOURCE_SIZE[0]}x{SOURCE_SIZE[1]}")
    pixels = [int(value) for value in source.getdata()]
    used = set(pixels)
    if not used.issubset({0, 1, 2, 3}):
        raise ValueError(f"Title uses palette indices outside 0..3: {sorted(used)}")

    width, height = source.size
    output = Image.new("P", TARGET_SIZE, 0)
    output.putpalette(source.getpalette() or [0] * 768)
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
            dst[x * 2, y * 2] = left if left == top and left != bottom and top != right else center
            dst[x * 2 + 1, y * 2] = right if top == right and top != left and right != bottom else center
            dst[x * 2, y * 2 + 1] = left if left == bottom and left != top and bottom != right else center
            dst[x * 2 + 1, y * 2 + 1] = right if bottom == right and left != bottom and top != right else center
    return output


def build_source(crowned: bool) -> Image.Image:
    title = Image.open(SOURCE_ROOT / "flob_title.gif")
    if title.mode != "P":
        title = title.convert("P")
    if not crowned:
        return title.copy()

    crown = Image.open(SOURCE_ROOT / "crown2.gif")
    if crown.mode != "P":
        crown = crown.convert("P")
    if crown.size != (160, 33):
        raise ValueError(f"Crown source must be indexed 160x33, got {crown.size}")
    if not set(crown.getdata()).issubset({0, 1, 2, 3}):
        raise ValueError("Crown uses palette indices outside 0..3")

    # Both original images use the same four logical grayscale indices.
    title.paste(crown, (0, 0))
    return title


def validate(path: Path) -> list[int]:
    image = Image.open(path)
    if image.mode != "P" or image.size != TARGET_SIZE:
        raise ValueError(f"{path}: canonical title must be indexed 320x184")
    used = sorted(set(int(value) for value in image.getdata()))
    if not set(used).issubset({0, 1, 2, 3}):
        raise ValueError(f"{path}: palette indices outside 0..3: {used}")
    return used


def main() -> None:
    args = parse_args()
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    entries = []
    created = 0
    preserved = 0

    for name, crowned in (("title", False), ("title_crown", True)):
        output_path = OUTPUT_ROOT / f"{name}.png"
        if output_path.exists() and not args.force:
            used = validate(output_path)
            preserved += 1
        else:
            scale2x(build_source(crowned)).save(output_path, optimize=True)
            used = validate(output_path)
            created += 1
        entries.append({
            "name": "IMG_TITLE_CROWN" if crowned else "IMG_TITLE",
            "image": str(output_path.relative_to(ROOT)),
            "size": list(TARGET_SIZE),
            "palette_indices": used,
        })

    manifest = {
        "canonical_build_source": True,
        "scale_algorithm": "Scale2x",
        "source_size": list(SOURCE_SIZE),
        "target_size": list(TARGET_SIZE),
        "images": entries,
    }
    manifest_path = OUTPUT_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"canonical title images: {len(entries)}")
    print(f"artwork created: {created}, preserved: {preserved}")
    print(f"wrote {manifest_path}")
    if preserved and not args.force:
        print("existing PNG files were preserved; use --force only to discard artist edits")


if __name__ == "__main__":
    main()
