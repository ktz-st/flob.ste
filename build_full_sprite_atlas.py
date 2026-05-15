#!/usr/bin/env python3
"""
Build the editable STE sprite atlas from every sprite used by world data.

The rows generated from original world sprite labels intentionally keep the
source label name, e.g. sprite_bench_portal_p0. That makes the Pascal lookup
from PUT_SPRITES,a(sprite_bench_portal) mechanical and avoids fragile aliases.
"""

from __future__ import annotations

import json
import math
import re
import hashlib
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_SRC = ROOT / "flob"
FLOB_STE = ROOT / "flob-ste"
WORLDS_SRC = FLOB_SRC / "worlds"
SHEETS_DIR = FLOB_STE / "images" / "sprite_sheets_lsy"
OUT_DIR = FLOB_STE / "images" / "sprite_atlas"
ATLAS_PNG = OUT_DIR / "all_sprites.png"
ATLAS_JSON = OUT_DIR / "all_sprites.json"

WORLD_DIRS = [
    "00_Escape_From_The_Lab",
    "01_Abominable_Sewers",
    "02_Suburbian_Parkour",
    "03_Hazardous_Mudlands",
    "04_Silver_Dust_Mines",
    "05_Return_To_The_Lab",
]

RESERVED_INDICES = [0, 1, 2, 3, 15]
SPRITE_SLOT_START = 4
SPRITE_SLOT_END = 14
SPRITE_COLOR_COUNT = SPRITE_SLOT_END - SPRITE_SLOT_START + 1
PREVIEW_SCALE_X = 2
PREVIEW_SCALE_Y = 2
FRAME_GAP = 0
ROW_GAP = 0

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*$")
ICL_RE = re.compile(r"^\s*icl\s+'([^']+)'\s*$", re.IGNORECASE)
PUT_SPRITES_RE = re.compile(r"dta\s+PUT_SPRITES,\s*a\((sprite_[^)]+)\)", re.IGNORECASE)
BYTE_LINE_RE = re.compile(r"^\s*\.byte\s*(.*)$", re.IGNORECASE)
CONST_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?);?\s*$")


@dataclass
class FrameEntry:
    frame: int
    image: Image.Image
    w: int
    h: int
    source_x: int = 0
    source_y: int = 0


@dataclass
class SpriteEntry:
    name: str
    source_png: str
    source_json: str
    row_width: int
    row_height: int
    frames: list[FrameEntry]


def strip_comment(line: str) -> str:
    return line.split(";", 1)[0].rstrip()


def split_csv(expr: str) -> list[str]:
    parts: list[str] = []
    current: list[str] = []
    in_quote = False
    for ch in expr:
        if ch == '"':
            in_quote = not in_quote
        if ch == "," and not in_quote:
            token = "".join(current).strip()
            if token:
                parts.append(token)
            current = []
        else:
            current.append(ch)
    token = "".join(current).strip()
    if token:
        parts.append(token)
    return parts


def parse_value(token: str, constants: dict[str, int]) -> int:
    token = token.strip()
    if not token:
        return 0
    if token.startswith("$"):
        return int(token[1:], 16) & 0xFF
    if token.startswith("%"):
        return int(token[1:], 2) & 0xFF
    if token.lower().startswith("0x"):
        return int(token, 16) & 0xFF
    if token in constants:
        return constants[token] & 0xFF
    return int(token, 10) & 0xFF


def load_constants() -> dict[str, int]:
    constants: dict[str, int] = {}
    for path in (FLOB_SRC / "const.inc", FLOB_STE / "const.inc"):
        if not path.exists():
            continue
        for raw_line in path.read_text(errors="ignore").splitlines():
            line = strip_comment(raw_line).strip()
            match = CONST_RE.match(line)
            if not match:
                continue
            name, value = match.groups()
            value = value.strip()
            try:
                constants[name] = parse_value(value, constants)
            except ValueError:
                pass
    return constants


def parse_byte_file(path: Path, constants: dict[str, int]) -> list[int]:
    data: list[int] = []
    for raw_line in path.read_text(errors="ignore").splitlines():
        line = strip_comment(raw_line)
        match = BYTE_LINE_RE.match(line)
        if not match:
            continue
        for token in split_csv(match.group(1)):
            data.append(parse_value(token, constants))
    return data


def find_world_sprite_sources() -> list[tuple[int, str, Path]]:
    found: dict[tuple[int, str], Path] = {}
    for world_idx, world_dir in enumerate(WORLD_DIRS):
        asm_path = WORLDS_SRC / world_dir / f"world_{world_idx:02d}.asm"
        if not asm_path.exists():
            continue
        used = set(PUT_SPRITES_RE.findall(asm_path.read_text(errors="ignore")))
        current_label: str | None = None
        for raw_line in asm_path.read_text(errors="ignore").splitlines():
            stripped = strip_comment(raw_line).strip()
            if not stripped:
                continue
            label_match = LABEL_RE.match(stripped)
            if label_match:
                current_label = label_match.group(1)
                continue
            icl_match = ICL_RE.match(stripped)
            if icl_match and current_label in used:
                found[(world_idx, current_label)] = (asm_path.parent / icl_match.group(1)).resolve()
    return [(world_idx, label, path) for (world_idx, label), path in sorted(found.items())]


def labels_with_different_sources(sources: list[tuple[int, str, Path]]) -> set[str]:
    hashes_by_label: dict[str, set[str]] = {}
    for _world_idx, label, path in sources:
        digest = hashlib.sha1(path.read_bytes()).hexdigest()
        hashes_by_label.setdefault(label, set()).add(digest)
    return {label for label, hashes in hashes_by_label.items() if len(hashes) > 1}


def atlas_label_for_source(world_idx: int, label: str, duplicate_labels: set[str]) -> str:
    if label in duplicate_labels:
        return f"{label}_w{world_idx:02d}"
    return label


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


def frame_image(rows: list[int], color: int, height: int) -> Image.Image:
    img = Image.new("RGBA", (16, height * PREVIEW_SCALE_Y), (0, 0, 0, 0))
    rgb = atari_color_to_rgb(color)
    for y, row in enumerate(rows):
        for bit in range(8):
            if (row & (0x80 >> bit)) == 0:
                continue
            for sy in range(PREVIEW_SCALE_Y):
                for sx in range(PREVIEW_SCALE_X):
                    img.putpixel((bit * PREVIEW_SCALE_X + sx, y * PREVIEW_SCALE_Y + sy), (*rgb, 255))
    return img


def sprite_entries_from_a65(label: str, path: Path, constants: dict[str, int]) -> list[SpriteEntry]:
    data = parse_byte_file(path, constants)
    if len(data) < 4:
        return []
    frame_counts = [data[0], data[1]]
    heights = [data[2], data[3]]
    offset = 4
    colors: list[list[int]] = [[], []]
    frames: list[list[list[int]]] = [[], []]
    for plane in range(2):
        count = frame_counts[plane]
        colors[plane] = data[offset:offset + count]
        offset += count
    for plane in range(2):
        count = frame_counts[plane]
        height = heights[plane]
        for frame_idx in range(count):
            rows = data[offset:offset + height]
            offset += height
            frames[plane].append(rows)

    entries: list[SpriteEntry] = []
    for plane in range(2):
        count = frame_counts[plane]
        height = heights[plane]
        if count == 0 or height == 0:
            continue
        frame_entries: list[FrameEntry] = []
        visible = False
        for frame_idx in range(count):
            color = colors[plane][frame_idx] if frame_idx < len(colors[plane]) else 0
            img = frame_image(frames[plane][frame_idx], color, height)
            if img.getbbox() is not None:
                visible = True
            frame_entries.append(FrameEntry(frame=frame_idx, image=img, w=16, h=height * PREVIEW_SCALE_Y))
        if not visible:
            continue
        entries.append(
            SpriteEntry(
                name=f"{label}_p{plane}",
                source_png="",
                source_json=str(path.relative_to(FLOB_SRC.parent)),
                row_width=sum(frame.w + FRAME_GAP for frame in frame_entries) - FRAME_GAP,
                row_height=max(frame.h for frame in frame_entries),
                frames=frame_entries,
            )
        )
    return entries


def load_sheet_entries() -> list[SpriteEntry]:
    entries: list[SpriteEntry] = []
    for json_path in sorted(SHEETS_DIR.glob("*.json")):
        meta = json.loads(json_path.read_text())
        png_path = json_path.with_suffix(".png")
        sheet = Image.open(png_path).convert("RGBA")
        frames: list[FrameEntry] = []
        row_width = 0
        row_height = 0
        for frame_meta in meta["frames_meta"]:
            x = int(frame_meta["x"])
            y = int(frame_meta["y"])
            w = int(frame_meta["w"])
            h = int(frame_meta["h"])
            frames.append(FrameEntry(int(frame_meta["frame"]), sheet.crop((x, y, x + w, y + h)), w, h, x, y))
            row_width += w + FRAME_GAP
            row_height = max(row_height, h)
        if frames:
            row_width -= FRAME_GAP
            entries.append(SpriteEntry(meta["name"], str(png_path.relative_to(FLOB_STE)), str(json_path.relative_to(FLOB_STE)), row_width, row_height, frames))
    return entries


def build_rgba_atlas(entries: list[SpriteEntry]) -> tuple[Image.Image, dict]:
    width = max((entry.row_width for entry in entries), default=16)
    height = max(16, sum(entry.row_height for entry in entries) + ROW_GAP * max(0, len(entries) - 1))
    atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    rows_meta = []
    frames_meta = []
    y_cursor = 0
    for entry in entries:
        x_cursor = 0
        rows_meta.append({
            "name": entry.name,
            "x": 0,
            "y": y_cursor,
            "w": entry.row_width,
            "h": entry.row_height,
            "source_png": entry.source_png,
            "source_json": entry.source_json,
            "frame_count": len(entry.frames),
        })
        for frame in entry.frames:
            atlas.alpha_composite(frame.image, (x_cursor, y_cursor))
            frames_meta.append({
                "sprite": entry.name,
                "frame": frame.frame,
                "x": x_cursor,
                "y": y_cursor,
                "w": frame.w,
                "h": frame.h,
                "source_x": frame.source_x,
                "source_y": frame.source_y,
                "source_png": entry.source_png,
            })
            x_cursor += frame.w + FRAME_GAP
        y_cursor += entry.row_height + ROW_GAP
    return atlas, {
        "name": "all_sprites",
        "image": str(ATLAS_PNG.relative_to(FLOB_STE)),
        "reserved_indices": RESERVED_INDICES,
        "sprite_indices": list(range(SPRITE_SLOT_START, SPRITE_SLOT_END + 1)),
        "rows": rows_meta,
        "frames": frames_meta,
    }


def quantize_opaque_colors(atlas: Image.Image) -> list[tuple[int, int, int]]:
    opaque = [(r, g, b) for (r, g, b, a) in atlas.getdata() if a]
    if not opaque:
        return []
    sample_w = min(512, max(1, len(opaque)))
    sample_h = math.ceil(len(opaque) / sample_w)
    sample = Image.new("RGB", (sample_w, sample_h))
    sample.putdata(opaque + [(0, 0, 0)] * (sample_w * sample_h - len(opaque)))
    quantized = sample.quantize(colors=SPRITE_COLOR_COUNT, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal = quantized.getpalette()[: SPRITE_COLOR_COUNT * 3]
    colors: list[tuple[int, int, int]] = []
    for i in range(0, len(pal), 3):
        rgb = (pal[i], pal[i + 1], pal[i + 2])
        if rgb not in colors:
            colors.append(rgb)
    return colors[:SPRITE_COLOR_COUNT]


def nearest_color_index(rgb: tuple[int, int, int], palette: list[tuple[int, int, int]]) -> int:
    best_idx = 0
    best_dist = 1 << 30
    for i, pal_rgb in enumerate(palette):
        dr = rgb[0] - pal_rgb[0]
        dg = rgb[1] - pal_rgb[1]
        db = rgb[2] - pal_rgb[2]
        dist = dr * dr + dg * dg + db * db
        if dist < best_dist:
            best_idx = i
            best_dist = dist
    return best_idx


def build_indexed_atlas(atlas: Image.Image, sprite_palette: list[tuple[int, int, int]]) -> tuple[Image.Image, list[tuple[int, int, int]]]:
    full_palette: list[tuple[int, int, int]] = [
        (0, 0, 0),
        (32, 32, 32),
        (96, 96, 96),
        (224, 224, 224),
        *sprite_palette,
    ]
    while len(full_palette) < 15:
        full_palette.append((0, 0, 0))
    full_palette.append((255, 0, 255))
    indexed = Image.new("P", atlas.size, 0)
    flat_palette: list[int] = []
    for rgb in full_palette:
        flat_palette.extend(rgb)
    flat_palette.extend([0] * (768 - len(flat_palette)))
    indexed.putpalette(flat_palette)
    indexed.info["transparency"] = 0
    src = atlas.load()
    dst = indexed.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            r, g, b, a = src[x, y]
            if a == 0 or not sprite_palette:
                dst[x, y] = 0
            else:
                dst[x, y] = SPRITE_SLOT_START + nearest_color_index((r, g, b), sprite_palette)
    return indexed, full_palette


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    constants = load_constants()
    entries = load_sheet_entries()
    seen = {entry.name for entry in entries}
    sources = find_world_sprite_sources()
    duplicate_labels = labels_with_different_sources(sources)
    for world_idx, label, path in sources:
        atlas_label = atlas_label_for_source(world_idx, label, duplicate_labels)
        for entry in sprite_entries_from_a65(atlas_label, path, constants):
            if entry.name not in seen:
                entries.append(entry)
                seen.add(entry.name)
    entries.sort(key=lambda item: item.name)
    atlas_rgba, meta = build_rgba_atlas(entries)
    sprite_palette = quantize_opaque_colors(atlas_rgba)
    indexed, full_palette = build_indexed_atlas(atlas_rgba, sprite_palette)
    meta["palette_rgb"] = [list(rgb) for rgb in full_palette]
    meta["sprite_color_count"] = len(sprite_palette)
    meta["quantized_from_unique_colors"] = len({(r, g, b) for (r, g, b, a) in atlas_rgba.getdata() if a})
    meta["atlas_size"] = {"w": atlas_rgba.width, "h": atlas_rgba.height}
    indexed.save(ATLAS_PNG, transparency=0)
    ATLAS_JSON.write_text(json.dumps(meta, indent=2))
    print(f"wrote {ATLAS_PNG}")
    print(f"wrote {ATLAS_JSON}")
    print(f"sprite rows: {len(entries)}")
    print(f"sprite colors used: {len(sprite_palette)} / {SPRITE_COLOR_COUNT}")


if __name__ == "__main__":
    main()
