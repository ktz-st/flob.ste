#!/usr/bin/env python3
"""Import original 2bpp world tiles into canonical Scale2x PNG files.

The generated indexed PNG files become artist-owned build sources. Existing
files are never overwritten unless --force is passed explicitly.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

import generate_world_tiles as legacy


ROOT = Path(__file__).resolve().parent
OUTPUT_ROOT = ROOT / "game_tiles"

PREVIEW_PALETTE = [
    0, 0, 0,
    255, 255, 255,
    170, 170, 170,
    85, 85, 85,
] + [0, 0, 0] * 252


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace canonical tile PNG files with fresh Scale2x imports",
    )
    return parser.parse_args()


def scale2x(width: int, height: int, pixels: list[int]) -> Image.Image:
    output = Image.new("P", (width * 2, height * 2), 0)
    output.putpalette(PREVIEW_PALETTE)
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

    output.info["transparency"] = 0
    return output


def validate_existing(path: Path, expected_size: tuple[int, int]) -> None:
    image = Image.open(path)
    if image.mode != "P":
        raise ValueError(f"{path}: canonical tile must be an indexed PNG")
    if image.size != expected_size:
        raise ValueError(f"{path}: expected {expected_size}, got {image.size}")
    used = set(image.getdata())
    if not used.issubset({0, 1, 2, 3}):
        raise ValueError(f"{path}: palette indices outside 0..3: {sorted(used)}")


def main() -> None:
    args = parse_args()
    manifest_tiles: list[dict] = []
    created = 0
    preserved = 0

    for world_index, world_dir in enumerate(legacy.WORLD_DIRS):
        asm_path = legacy.WORLDS_SRC / world_dir / f"world_{world_index:02d}.asm"
        labels = legacy.compute_label_addresses(asm_path)
        source_tiles = legacy.extract_tiles(asm_path, labels)
        output_dir = OUTPUT_ROOT / f"world_{world_index:02d}"
        output_dir.mkdir(parents=True, exist_ok=True)
        canonical_by_addr: dict[int, tuple[Path, str]] = {}

        for tile_index, tile in enumerate(source_tiles):
            label = str(tile["label"])
            source_addr = int(tile["source_addr"])
            alias_of = None
            if source_addr in canonical_by_addr:
                output_path, alias_of = canonical_by_addr[source_addr]
            else:
                output_path = output_dir / f"{tile_index:02d}_{label}.png"
                canonical_by_addr[source_addr] = (output_path, label)
            width = int(tile["source_width"])
            height = int(tile["source_height"])
            final_indices = [
                legacy.ATARI_TO_ST_INDEX[int(value)]
                for value in tile["source_pixels"]
            ]
            expected_size = (width * 2, height * 2)

            if alias_of is None:
                if output_path.exists() and not args.force:
                    validate_existing(output_path, expected_size)
                    preserved += 1
                else:
                    image = scale2x(width, height, final_indices)
                    image.save(output_path, optimize=True, transparency=0)
                    created += 1

            manifest_entry = {
                "world": world_index,
                "index": tile_index,
                "label": label,
                "source_addr": source_addr,
                "image": str(output_path.relative_to(ROOT)),
                "size": list(expected_size),
                "palette_indices": [0, 1, 2, 3],
                "transparent_index": 0,
            }
            if alias_of is not None:
                manifest_entry["alias_of"] = alias_of
            manifest_tiles.append(manifest_entry)

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    manifest = {
        "canonical_build_source": True,
        "scale_algorithm": "Scale2x",
        "transparent_index": 0,
        "tile_count": len(manifest_tiles),
        "tiles": manifest_tiles,
    }
    manifest_path = OUTPUT_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"canonical tiles: {len(manifest_tiles)}")
    print(f"artwork created: {created}, preserved: {preserved}")
    print(f"wrote {manifest_path}")
    if preserved and not args.force:
        print("existing PNG files were preserved; use --force only to discard artist edits")


if __name__ == "__main__":
    main()
