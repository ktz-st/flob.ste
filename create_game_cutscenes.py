#!/usr/bin/env python3
"""Import original intro/outro slides into canonical Scale2x PNG files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE_ROOT = ROOT.parent / "flob" / "assets" / "intro"
OUTPUT_ROOT = ROOT / "game_cutscenes"
SOURCE_SIZE = (160, 80)
TARGET_SIZE = (320, 160)

SLIDES = [
    *(('intro', index) for index in range(6)),
    *(('outro', index) for index in range(3)),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace canonical PNG files with fresh Scale2x imports",
    )
    return parser.parse_args()


def scale2x(source: Image.Image) -> Image.Image:
    if source.mode != "P":
        raise ValueError("Cutscene source must be an indexed image")
    if source.size != SOURCE_SIZE:
        raise ValueError(f"Expected {SOURCE_SIZE}, got {source.size}")

    pixels = [int(value) for value in source.getdata()]
    used = set(pixels)
    if not used.issubset({0, 1, 2, 3}):
        raise ValueError(f"Cutscene uses palette indices outside 0..3: {sorted(used)}")

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


def validate_existing(path: Path) -> list[int]:
    image = Image.open(path)
    if image.mode != "P":
        raise ValueError(f"{path}: canonical slide must be an indexed PNG")
    if image.size != TARGET_SIZE:
        raise ValueError(f"{path}: expected {TARGET_SIZE}, got {image.size}")
    used = sorted(set(int(value) for value in image.getdata()))
    if not set(used).issubset({0, 1, 2, 3}):
        raise ValueError(f"{path}: palette indices outside 0..3: {used}")
    return used


def main() -> None:
    args = parse_args()
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    manifest_slides: list[dict] = []
    created = 0
    preserved = 0

    for kind, index in SLIDES:
        stem = f"{kind}_{index:02d}"
        source_path = SOURCE_ROOT / f"{stem}.gif"
        output_path = OUTPUT_ROOT / f"{stem}.png"

        if output_path.exists() and not args.force:
            used = validate_existing(output_path)
            preserved += 1
        else:
            source = Image.open(source_path)
            if source.mode != "P":
                source = source.convert("P")
            scale2x(source).save(output_path, optimize=True)
            used = validate_existing(output_path)
            created += 1

        manifest_slides.append({
            "name": f"IMG_{kind.upper()}_{index:02d}",
            "kind": kind,
            "slide": index,
            "source": str(source_path.relative_to(ROOT.parent)),
            "image": str(output_path.relative_to(ROOT)),
            "size": list(TARGET_SIZE),
            "palette_indices": used,
        })

    manifest = {
        "canonical_build_source": True,
        "scale_algorithm": "Scale2x",
        "source_size": list(SOURCE_SIZE),
        "target_size": list(TARGET_SIZE),
        "image_count": len(manifest_slides),
        "images": manifest_slides,
    }
    manifest_path = OUTPUT_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"canonical cutscene slides: {len(manifest_slides)}")
    print(f"artwork created: {created}, preserved: {preserved}")
    print(f"wrote {manifest_path}")
    if preserved and not args.force:
        print("existing PNG files were preserved; use --force only to discard artist edits")


if __name__ == "__main__":
    main()
