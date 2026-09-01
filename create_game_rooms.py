#!/usr/bin/env python3
"""Create canonical room artwork and collision maps in a one-time import.

Artwork is converted to indexed 320x160 PNG with Scale2x. Collision remains an
indexed semantic 160x80 map. Both become artist-owned build sources and are
never overwritten unless --force is passed explicitly.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
FLOB_SRC = ROOT.parent / "flob"
WORLDS_SRC = FLOB_SRC / "worlds"
OUTPUT_ROOT = ROOT / "game_rooms"

WORLD_DIRS = [
    "00_Escape_From_The_Lab",
    "01_Abominable_Sewers",
    "02_Suburbian_Parkour",
    "03_Hazardous_Mudlands",
    "04_Silver_Dust_Mines",
    "05_Return_To_The_Lab",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace existing canonical PNG files with fresh Scale2x exports",
    )
    return parser.parse_args()


def scale2x(source: Image.Image) -> Image.Image:
    if source.mode != "P":
        raise ValueError("Room source must be an indexed image")
    if source.size != (160, 80):
        raise ValueError(f"Expected 160x80 room, got {source.size}")

    used_indices = set(source.getdata())
    if not used_indices.issubset({0, 1, 2, 3}):
        raise ValueError(f"Room uses palette indices outside 0..3: {used_indices}")

    width, height = source.size
    src = source.load()
    output = Image.new("P", (width * 2, height * 2), 0)
    palette = source.getpalette()
    if palette is None:
        raise ValueError("Room source has no indexed palette")
    output.putpalette(palette)
    dst = output.load()

    for y in range(height):
        for x in range(width):
            center = src[x, y]
            top = src[x, max(0, y - 1)]
            left = src[max(0, x - 1), y]
            right = src[min(width - 1, x + 1), y]
            bottom = src[x, min(height - 1, y + 1)]

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


def normalized_collision(source: Image.Image) -> Image.Image:
    """Preserve the original 160x80 collision semantics as indices 0..3."""
    if source.mode != "P" or source.size != (160, 80):
        raise ValueError("Collision source must be an indexed 160x80 image")
    palette = source.getpalette()
    if palette is None:
        raise ValueError("Collision source has no indexed palette")

    def luminance(index: int) -> int:
        offset = index * 3
        red, green, blue = palette[offset:offset + 3]
        return red * 299 + green * 587 + blue * 114

    sorted_source = sorted(range(4), key=luminance)
    remap = {old: new for new, old in enumerate(sorted_source)}
    output = Image.new("P", source.size, 0)
    output_palette = list(palette)
    for new, old in enumerate(sorted_source):
        output_palette[new * 3:new * 3 + 3] = palette[old * 3:old * 3 + 3]
    output.putpalette(output_palette)
    output.putdata([remap[int(pixel)] for pixel in source.getdata()])
    return output


def main() -> None:
    args = parse_args()
    manifest_rooms: list[dict] = []
    created = 0
    skipped = 0
    collision_created = 0
    collision_skipped = 0

    for world_index, world_dir in enumerate(WORLD_DIRS):
        source_dir = WORLDS_SRC / world_dir / "images"
        output_dir = OUTPUT_ROOT / f"world_{world_index:02d}"
        output_dir.mkdir(parents=True, exist_ok=True)

        room_paths = sorted(
            source_dir.glob("room_*.gif"),
            key=lambda path: int(path.stem.split("_")[-1]),
        )
        for source_path in room_paths:
            room_number = int(source_path.stem.split("_")[-1])
            output_path = output_dir / f"room_{room_number:02d}.png"
            collision_path = output_dir / f"room_{room_number:02d}_collision.png"
            source = Image.open(source_path)
            if source.mode != "P":
                source = source.convert("P")
            if output_path.exists() and not args.force:
                skipped += 1
            else:
                room = scale2x(source)
                room.save(output_path, optimize=True)
                created += 1

            if collision_path.exists() and not args.force:
                collision_skipped += 1
            else:
                collision = normalized_collision(source)
                collision.save(collision_path, optimize=True)
                collision_created += 1

            manifest_rooms.append(
                {
                    "world": world_index,
                    "room": room_number,
                    "source": str(source_path.relative_to(ROOT.parent)),
                    "image": str(output_path.relative_to(ROOT)),
                    "collision": str(collision_path.relative_to(ROOT)),
                    "size": [320, 160],
                    "collision_size": [160, 80],
                    "palette_indices": [0, 1, 2, 3],
                }
            )

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    manifest = {
        "canonical_build_source": True,
        "scale_algorithm": "Scale2x",
        "source_size": [160, 80],
        "target_size": [320, 160],
        "room_count": len(manifest_rooms),
        "rooms": manifest_rooms,
    }
    manifest_path = OUTPUT_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"canonical rooms: {len(manifest_rooms)}")
    print(f"artwork created: {created}, preserved: {skipped}")
    print(
        f"collision created: {collision_created}, preserved: {collision_skipped}"
    )
    print(f"wrote {manifest_path}")
    if skipped and not args.force:
        print("existing PNG files were preserved; use --force only to discard artist edits")


if __name__ == "__main__":
    main()
