#!/usr/bin/env python3
"""Smooth doubled sprite silhouettes without resampling their interior colors."""

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
ATLAS = ROOT / "images/sprite_atlas/game_sprites.png"
LAYOUT = ROOT / "images/sprite_atlas/game_sprites.json"
TARGETS = (
    "sprite_cagedoor_p0",
    "sprite_fireext_merged",
    "sprite_gear_compound",
    "sprite_phone_compound",
)


def bounds(pixels, width, height):
    points = [(x, y) for y in range(height) for x in range(width)
              if pixels[y * width + x] != 0]
    if not points:
        return None
    return (min(x for x, _ in points), min(y for _, y in points),
            max(x for x, _ in points), max(y for _, y in points))


def smooth_frame(image, row, frame_index):
    width, height = row["frame_w"], row["frame_h"]
    if (width | height) & 1:
        raise ValueError(f"{row['name']}: expected even frame dimensions")
    x0 = row["x"] + frame_index * row["slot_w"]
    y0 = row["y"]
    pixels = image.load()
    original = [pixels[x0 + x, y0 + y]
                for y in range(height) for x in range(width)]
    half_width, half_height = width // 2, height // 2

    for y in range(half_height):
        for x in range(half_width):
            block = {original[(2 * y + dy) * width + 2 * x + dx]
                     for dy in (0, 1) for dx in (0, 1)}
            if len(block) != 1:
                raise ValueError(f"{row['name']} frame {frame_index}: not a doubled source")

    def sample(x, y):
        if 0 <= x < half_width and 0 <= y < half_height:
            return original[(2 * y) * width + 2 * x]
        return 0

    result = original.copy()
    for y in range(half_height):
        for x in range(half_width):
            center = sample(x, y)
            top, left = sample(x, y - 1), sample(x - 1, y)
            right, bottom = sample(x + 1, y), sample(x, y + 1)
            a, b, c, d, e = map(bool, (top, left, right, bottom, center))
            donors = (left if b == a else center,
                      right if a == c else center,
                      left if b == d else center,
                      right if d == c else center)
            if a == d or b == c:
                donors = (center,) * 4
            for dy in (0, 1):
                for dx in (0, 1):
                    i = dy * 2 + dx
                    donor = donors[i]
                    index = (2 * y + dy) * width + 2 * x + dx
                    if not donor:
                        result[index] = 0
                    elif not e:
                        result[index] = donor

    if bounds(original, width, height) != bounds(result, width, height):
        raise ValueError(f"{row['name']} frame {frame_index}: frame anchor changed")
    for y in range(height):
        for x in range(width):
            pixels[x0 + x, y0 + y] = result[y * width + x]
    return sum(before != after for before, after in zip(original, result))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    atlas = Image.open(ATLAS)
    if atlas.mode != "P":
        raise ValueError("Sprite atlas must stay indexed")
    result = atlas.copy()
    rows = {row["name"]: row for row in json.loads(LAYOUT.read_text())["rows"]}
    for name in TARGETS:
        row = rows[name]
        counts = [smooth_frame(result, row, i) for i in range(row["frame_count"])]
        print(name, counts, "total", sum(counts))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output, optimize=True)


if __name__ == "__main__":
    main()
