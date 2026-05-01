#!/usr/bin/env python3
"""
Export Flob animation frames from the original sprites.asm into an editable PNG sheet.
"""

from __future__ import annotations

import json
import math
import re
from pathlib import Path

from PIL import Image

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_SRC = ROOT / "flob"
FLOB_STE = ROOT / "flob-ste"

SPRITES_ASM = FLOB_SRC / "assets" / "sprites.asm"
CONST_INC = FLOB_SRC / "const.inc"
OUT_DIR = FLOB_STE / "images" / "sprite_sheets_lsy"

PREVIEW_SCALE_X = 2
PREVIEW_SCALE_Y = 2
CELL_W = 16
CELL_H = 16
FRAME_W = 8
FRAME_H = 8
COLS = 8

RE_LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*$")
RE_DTA = re.compile(r"^\s*dta\s+(.+)$", re.IGNORECASE)
RE_ADDR = re.compile(r"a\(([^)]+)\)")
RE_CONST = re.compile(r"^\s*(FLOB_COL[01])\s*=\s*\$([0-9A-Fa-f]+)\s*;")


def strip_comment(line: str) -> str:
    if ";" in line:
        line = line.split(";", 1)[0]
    return line.rstrip()


def split_csv(expr: str) -> list[str]:
    return [part.strip() for part in expr.split(",") if part.strip()]


def parse_num(token: str, consts: dict[str, int]) -> int:
    if token in consts:
        return consts[token]
    if token.startswith("$"):
        return int(token[1:], 16)
    if token.startswith("%"):
        return int(token[1:], 2)
    return int(token, 10)


def atari_color_to_rgb(value: int) -> tuple[int, int, int]:
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


def parse_consts() -> dict[str, int]:
    consts: dict[str, int] = {}
    for line in CONST_INC.read_text().splitlines():
        m = RE_CONST.match(line)
        if m:
            consts[m.group(1)] = int(m.group(2), 16)
    return consts


def parse_sprite_frames(consts: dict[str, int]):
    lines = SPRITES_ASM.read_text().splitlines()
    labels: dict[str, list[int]] = {}
    frames0: list[str] = []
    frames1: list[str] = []
    current_label: str | None = None

    for raw in lines:
        line = strip_comment(raw)
        stripped = line.strip()
        if not stripped:
            continue

        m = RE_LABEL.match(stripped)
        if m:
            current_label = m.group(1)
            continue

        dta = RE_DTA.match(stripped)
        if not dta or current_label is None:
            continue

        if current_label == "flobFrames0":
            frames0.extend(RE_ADDR.findall(dta.group(1)))
            continue
        if current_label == "flobFrames1":
            frames1.extend(RE_ADDR.findall(dta.group(1)))
            continue

        if current_label.startswith("f_flob"):
            vals = [parse_num(tok, consts) & 0xFF for tok in split_csv(dta.group(1))]
            labels[current_label] = vals

    if len(frames0) != 16 or len(frames1) != 16:
        raise ValueError("Expected 16 Flob frame entries in flobFrames0/flobFrames1")
    return frames0, frames1, labels


def draw_frame(p0: list[int], p1: list[int], rgb0: tuple[int, int, int], rgb1: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    overlap = mix_rgb(rgb0, rgb1)
    y_off = (CELL_H - FRAME_H * PREVIEW_SCALE_Y) // 2
    for row in range(FRAME_H):
        b0 = p0[row]
        b1 = p1[row]
        py = y_off + row * PREVIEW_SCALE_Y
        for bit in range(FRAME_W):
            mask = 0x80 >> bit
            p0_on = (b0 & mask) != 0
            p1_on = (b1 & mask) != 0
            if not (p0_on or p1_on):
                continue
            color = overlap if (p0_on and p1_on) else (rgb0 if p0_on else rgb1)
            for sy in range(PREVIEW_SCALE_Y):
                for sx in range(PREVIEW_SCALE_X):
                    img.putpixel((bit * PREVIEW_SCALE_X + sx, py + sy), (*color, 255))
    return img


def main() -> None:
    consts = parse_consts()
    frames0, frames1, labels = parse_sprite_frames(consts)
    rgb0 = atari_color_to_rgb(consts["FLOB_COL0"])
    rgb1 = atari_color_to_rgb(consts["FLOB_COL1"])
    overlap_rgb = mix_rgb(rgb0, rgb1)

    rows = math.ceil(len(frames0) / COLS)
    sheet = Image.new("RGBA", (CELL_W * COLS, CELL_H * rows), (0, 0, 0, 0))
    meta_frames = []

    for i, (name0, name1) in enumerate(zip(frames0, frames1)):
        frame = draw_frame(labels[name0], labels[name1], rgb0, rgb1)
        col = i % COLS
        row = i // COLS
        x = col * CELL_W
        y = row * CELL_H
        sheet.alpha_composite(frame, (x, y))
        meta_frames.append({
            "frame": i,
            "name_p0": name0,
            "name_p1": name1,
            "x": x,
            "y": y,
            "w": CELL_W,
            "h": CELL_H,
            "content_w": FRAME_W,
            "content_h": FRAME_H,
            "preview_w": FRAME_W * PREVIEW_SCALE_X,
            "preview_h": FRAME_H * PREVIEW_SCALE_Y,
            "p0_color": consts["FLOB_COL0"],
            "p1_color": consts["FLOB_COL1"],
            "p0_rgb": list(rgb0),
            "p1_rgb": list(rgb1),
            "overlap_rgb": list(overlap_rgb),
        })

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    png_path = OUT_DIR / "flob.png"
    json_path = OUT_DIR / "flob.json"
    sheet.save(png_path)
    json_path.write_text(json.dumps({
        "name": "flob",
        "source": str(SPRITES_ASM),
        "frames": len(frames0),
        "height": FRAME_H,
        "gap": 0,
        "logical_width": FRAME_W,
        "preview_scale_x": PREVIEW_SCALE_X,
        "preview_scale_y": PREVIEW_SCALE_Y,
        "cell_width": CELL_W,
        "cell_height": CELL_H,
        "columns": COLS,
        "rows": rows,
        "uses_p1": True,
        "frames_meta": meta_frames,
    }, indent=2))
    print(f"exported {png_path}")
    print(f"wrote {json_path}")


if __name__ == "__main__":
    main()
