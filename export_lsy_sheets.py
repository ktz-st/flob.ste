#!/usr/bin/env python3
"""
Export Atari PMG LSY sources as editable PNG sprite sheets.

This is an intermediate asset step:
1. Parse legacy .lsy PMG sources from the original Atari project.
2. Render each animation frame into a grid-based PNG sheet.
3. Emit JSON metadata describing the sheet layout for a later
   "PNG/GIF -> native ST sprite" conversion step.

Output:
  flob-ste/images/sprite_sheets_lsy/<name>.png
  flob-ste/images/sprite_sheets_lsy/<name>.json
"""

from __future__ import annotations

import json
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_SRC = ROOT / "flob"
FLOB_STE = ROOT / "flob-ste"
OUT_DIR = FLOB_STE / "images" / "sprite_sheets_lsy"
PREVIEW_SCALE_X = 2
PREVIEW_SCALE_Y = 1

LSY_SOURCES = [
    FLOB_SRC / "assets" / "pmg sources",
]

WORLD_LSY_GLOBS = [
    FLOB_SRC / "worlds",
]

RE_DEFINE = re.compile(r"#define\s+([A-Z0-9_]+)\s*\((\d+)\)")
RE_ARRAY = re.compile(
    r"const\s+unsigned\s+char\s+([A-Z0-9_]+)(?:\[[^\]]+\])+(?:\s*=\s*)\{(.*?)\};",
    re.S,
)
RE_HEX = re.compile(r"0x([0-9a-fA-F]{1,2})")


@dataclass
class LsySprite:
    name: str
    source_path: str
    frames: int
    height: int
    gap: int
    p0_colours: list[int]
    p1_colours: list[int]
    p0_data: list[list[int]]
    p1_data: list[list[int]]

    @property
    def uses_p1(self) -> bool:
        return any(any(row) for row in self.p1_data)

    @property
    def logical_width(self) -> int:
        if not self.uses_p1:
            return 8
        return max(8, self.gap + 8)


def sanitize_name(path: Path) -> str:
    return path.stem.replace(" ", "_").replace("-", "_")


def ceil16(value: int) -> int:
    return max(16, ((value + 15) // 16) * 16)


def parse_define_map(text: str) -> dict[str, int]:
    return {name: int(value) for name, value in RE_DEFINE.findall(text)}


def parse_array_map(text: str) -> dict[str, list[int]]:
    arrays: dict[str, list[int]] = {}
    for name, body in RE_ARRAY.findall(text):
        arrays[name] = [int(v, 16) for v in RE_HEX.findall(body)]
    return arrays


def split_frames(flat: list[int], frames: int, height: int, label: str, path: Path) -> list[list[int]]:
    expected = frames * height
    if len(flat) != expected:
        raise ValueError(f"{path.name}: {label} expected {expected} bytes, got {len(flat)}")
    return [flat[i * height:(i + 1) * height] for i in range(frames)]


def parse_lsy(path: Path) -> LsySprite:
    text = path.read_text(encoding="utf-8", errors="ignore")
    define_map = parse_define_map(text)
    array_map = parse_array_map(text)

    frames = define_map["FRAMES"]
    height = define_map["HEIGHT"]
    gap = define_map.get("GAP", 0)

    p0_colours = array_map.get("P0COLOURS", [])
    p1_colours = array_map.get("P1COLOURS", [])
    p0_flat = array_map.get("P0DATA", [])
    p1_flat = array_map.get("P1DATA", [])

    if len(p0_colours) != frames:
        raise ValueError(f"{path.name}: P0COLOURS expected {frames} entries, got {len(p0_colours)}")
    if len(p1_colours) != frames:
        p1_colours = [0] * frames
    if len(p1_colours) != frames:
        raise ValueError(f"{path.name}: P1COLOURS expected {frames} entries, got {len(p1_colours)}")

    p0_data = split_frames(p0_flat, frames, height, "P0DATA", path)
    if p1_flat:
        p1_data = split_frames(p1_flat, frames, height, "P1DATA", path)
    else:
        p1_data = [[0] * height for _ in range(frames)]

    return LsySprite(
        name=sanitize_name(path),
        source_path=str(path),
        frames=frames,
        height=height,
        gap=gap,
        p0_colours=p0_colours,
        p1_colours=p1_colours,
        p0_data=p0_data,
        p1_data=p1_data,
    )


def atari_color_to_rgb(value: int) -> tuple[int, int, int]:
    """
    Lightweight preview palette, not a strict Atari color match.
    High nibble = hue sector, low nibble = luminance.
    Good enough for editable preview sheets.
    """
    if value == 0:
        return (0, 0, 0)
    hue = ((value >> 4) & 0x0F) / 16.0
    lum = (value & 0x0F) / 15.0
    sat = 0.85

    i = int(hue * 6.0) % 6
    f = hue * 6.0 - int(hue * 6.0)
    p = lum * (1.0 - sat)
    q = lum * (1.0 - f * sat)
    t = lum * (1.0 - (1.0 - f) * sat)

    if i == 0:
        r, g, b = lum, t, p
    elif i == 1:
        r, g, b = q, lum, p
    elif i == 2:
        r, g, b = p, lum, t
    elif i == 3:
        r, g, b = p, q, lum
    elif i == 4:
        r, g, b = t, p, lum
    else:
        r, g, b = lum, p, q

    return (int(r * 255), int(g * 255), int(b * 255))


def mix_rgb(a: tuple[int, int, int], b: tuple[int, int, int]) -> tuple[int, int, int]:
    return (
        min(255, (a[0] + b[0]) // 2 + 24),
        min(255, (a[1] + b[1]) // 2 + 24),
        min(255, (a[2] + b[2]) // 2 + 24),
    )


def draw_frame(sprite: LsySprite, frame_idx: int, cell_w: int, cell_h: int) -> Image.Image:
    img = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
    p0_rgb = atari_color_to_rgb(sprite.p0_colours[frame_idx])
    p1_rgb = atari_color_to_rgb(sprite.p1_colours[frame_idx])
    overlap_rgb = mix_rgb(p0_rgb, p1_rgb)

    # Center vertically for easier editing in the sheet.
    x0_off = 0
    x1_off = sprite.gap if sprite.uses_p1 else 0
    y_off = max(0, (cell_h - sprite.height) // 2)

    for y in range(sprite.height):
        b0 = sprite.p0_data[frame_idx][y]
        b1 = sprite.p1_data[frame_idx][y]
        row_y = y_off + y * PREVIEW_SCALE_Y
        for x in range(sprite.logical_width):
            p0_on = False
            p1_on = False

            local0 = x - x0_off
            if 0 <= local0 < 8:
                p0_on = (b0 & (0x80 >> local0)) != 0

            if sprite.uses_p1:
                local1 = x - x1_off
                if 0 <= local1 < 8:
                    p1_on = (b1 & (0x80 >> local1)) != 0

            if p0_on and p1_on:
                for sy in range(PREVIEW_SCALE_Y):
                    for sx in range(PREVIEW_SCALE_X):
                        img.putpixel((x * PREVIEW_SCALE_X + sx, row_y + sy), (*overlap_rgb, 255))
            elif p0_on:
                for sy in range(PREVIEW_SCALE_Y):
                    for sx in range(PREVIEW_SCALE_X):
                        img.putpixel((x * PREVIEW_SCALE_X + sx, row_y + sy), (*p0_rgb, 255))
            elif p1_on:
                for sy in range(PREVIEW_SCALE_Y):
                    for sx in range(PREVIEW_SCALE_X):
                        img.putpixel((x * PREVIEW_SCALE_X + sx, row_y + sy), (*p1_rgb, 255))
    return img


def build_sheet(sprite: LsySprite) -> tuple[Image.Image, dict]:
    logical_w = sprite.logical_width
    logical_h = sprite.height
    preview_w = logical_w * PREVIEW_SCALE_X
    preview_h = logical_h * PREVIEW_SCALE_Y
    cell_w = ceil16(preview_w)
    cell_h = ceil16(preview_h)

    cols = min(8, sprite.frames)
    rows = math.ceil(sprite.frames / cols)
    sheet = Image.new("RGBA", (cell_w * cols, cell_h * rows), (0, 0, 0, 0))

    frames_meta = []
    for frame_idx in range(sprite.frames):
        col = frame_idx % cols
        row = frame_idx // cols
        x = col * cell_w
        y = row * cell_h
        frame_img = draw_frame(sprite, frame_idx, cell_w, cell_h)
        sheet.alpha_composite(frame_img, (x, y))
        frames_meta.append({
            "frame": frame_idx,
            "x": x,
            "y": y,
            "w": cell_w,
            "h": cell_h,
            "content_w": logical_w,
            "content_h": logical_h,
            "preview_w": preview_w,
            "preview_h": preview_h,
            "p0_color": sprite.p0_colours[frame_idx],
            "p1_color": sprite.p1_colours[frame_idx],
        })

    meta = {
        "name": sprite.name,
        "source": sprite.source_path,
        "frames": sprite.frames,
        "height": sprite.height,
        "gap": sprite.gap,
        "logical_width": logical_w,
        "preview_scale_x": PREVIEW_SCALE_X,
        "preview_scale_y": PREVIEW_SCALE_Y,
        "preview_width": preview_w,
        "preview_height": preview_h,
        "cell_width": cell_w,
        "cell_height": cell_h,
        "columns": cols,
        "rows": rows,
        "uses_p1": sprite.uses_p1,
        "frames_meta": frames_meta,
    }
    return sheet, meta


def iter_lsy_files() -> Iterable[Path]:
    seen: set[Path] = set()
    for base in LSY_SOURCES:
        if not base.exists():
            continue
        for path in sorted(base.glob("*.lsy")):
            if path not in seen:
                seen.add(path)
                yield path
    for worlds_root in WORLD_LSY_GLOBS:
        if not worlds_root.exists():
            continue
        for path in sorted(worlds_root.glob("*/*.lsy")):
            if path not in seen:
                seen.add(path)
                yield path


def export_one(path: Path) -> tuple[Path, Path]:
    sprite = parse_lsy(path)
    sheet, meta = build_sheet(sprite)
    png_path = OUT_DIR / f"{sprite.name}.png"
    json_path = OUT_DIR / f"{sprite.name}.json"
    sheet.save(png_path)
    json_path.write_text(json.dumps(meta, indent=2))
    return png_path, json_path


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    count = 0
    for path in iter_lsy_files():
        png_path, _ = export_one(path)
        print(f"exported {path.name} -> {png_path.name}")
        count += 1
    print(f"done: {count} sheets in {OUT_DIR}")


if __name__ == "__main__":
    main()
