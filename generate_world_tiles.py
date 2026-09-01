#!/usr/bin/env python3
"""Generate STE-native masked tiles from canonical indexed PNG files.

The one-time create_game_tiles.py importer owns extraction from the original
Atari 8-bit sources. Normal builds read only game_tiles/manifest.json and the
artist-editable Scale2x PNG files, then pack one unshifted mask + 4bpp payload.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image

FLOB_SRC = Path("/Users/kriss/GCC.ELF/flob")
FLOB_STE = Path("/Users/kriss/GCC.ELF/flob-ste")
WORLDS_SRC = FLOB_SRC / "worlds"
OUT_DIR = FLOB_STE / "worlds"
GAME_TILES = FLOB_STE / "game_tiles"

WORLD_DIRS = [
    "00_Escape_From_The_Lab",
    "01_Abominable_Sewers",
    "02_Suburbian_Parkour",
    "03_Hazardous_Mudlands",
    "04_Silver_Dust_Mines",
    "05_Return_To_The_Lab",
]

ORG_RE = re.compile(r"^\s*org\s+\$([0-9a-fA-F]+)(?:\s*,\s*\$[0-9a-fA-F]+)?\s*$", re.IGNORECASE)
LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*$")
INS_RE = re.compile(r"^\s*ins\s+'([^']+)'\s*$", re.IGNORECASE)
ICL_RE = re.compile(r"^\s*icl\s+'([^']+)'\s*$", re.IGNORECASE)
DTA_RE = re.compile(r"^\s*dta\s+(.+)$", re.IGNORECASE)
BYTE_RE = re.compile(r"^\s*\.byte\s+(.+)$", re.IGNORECASE)
ATARI_TO_ST_INDEX = {
    0: 0,
    1: 2,
    2: 1,
    3: 3,
}


def strip_comment(line: str) -> str:
    if ";" in line:
        line = line.split(";", 1)[0]
    return line.rstrip()


def split_csv(expr: str) -> list[str]:
    parts: list[str] = []
    current: list[str] = []
    in_quote = False
    depth = 0

    for ch in expr:
        if ch == '"':
            in_quote = not in_quote
            current.append(ch)
            continue
        if not in_quote:
            if ch == "(":
                depth += 1
            elif ch == ")" and depth > 0:
                depth -= 1
            elif ch == "," and depth == 0:
                token = "".join(current).strip()
                if token:
                    parts.append(token)
                current = []
                continue
        current.append(ch)

    token = "".join(current).strip()
    if token:
        parts.append(token)
    return parts


def parse_numeric_token(token: str) -> int:
    token = token.strip()
    if token.startswith("$"):
        return int(token[1:], 16)
    if token.startswith("%"):
        return int(token[1:], 2)
    return int(token, 10)


def is_label_line(text: str) -> bool:
    return LABEL_RE.match(text) is not None


def dta_token_size(token: str) -> int:
    token = token.strip()
    if not token:
        return 0
    if token.startswith('"') and token.endswith('"'):
        return len(token[1:-1])
    if token.lower().startswith("a("):
        return 2
    if token.lower().startswith("f("):
        return 4
    return 1


def included_byte_count(path: Path) -> int:
    total = 0
    for raw_line in path.read_text().splitlines():
        line = strip_comment(raw_line)
        if not line.strip():
            continue
        match = BYTE_RE.match(line)
        if not match:
            continue
        total += len(split_csv(match.group(1)))
    return total


def compute_label_addresses(asm_path: Path) -> dict[str, int]:
    labels: dict[str, int] = {}
    pc = 0

    for raw_line in asm_path.read_text().splitlines():
        line = strip_comment(raw_line)
        stripped = line.strip()
        if not stripped:
            continue

        org_match = ORG_RE.match(stripped)
        if org_match:
            pc = int(org_match.group(1), 16)
            continue

        label_match = LABEL_RE.match(stripped)
        if label_match:
            labels[label_match.group(1)] = pc
            continue

        ins_match = INS_RE.match(stripped)
        if ins_match:
            pc += len((asm_path.parent / ins_match.group(1)).read_bytes())
            continue

        icl_match = ICL_RE.match(stripped)
        if icl_match:
            inc_path = (asm_path.parent / icl_match.group(1)).resolve()
            if inc_path.suffix.lower() == ".a65":
                pc += included_byte_count(inc_path)
            continue

        dta_match = DTA_RE.match(stripped)
        if dta_match:
            for token in split_csv(dta_match.group(1)):
                pc += dta_token_size(token)
            continue

    return labels


def decode_atari_2bpp(raw: bytes, width_bytes: int, height_rows: int) -> list[int]:
    out: list[int] = []
    expected = width_bytes * height_rows
    if len(raw) != expected:
        raise ValueError(f"tile payload size mismatch: expected {expected}, got {len(raw)}")

    for row in range(height_rows):
        row_bytes = raw[row * width_bytes:(row + 1) * width_bytes]
        for b in row_bytes:
            out.extend([
                (b >> 6) & 0x03,
                (b >> 4) & 0x03,
                (b >> 2) & 0x03,
                b & 0x03,
            ])
    return out


def read_inline_tile_bytes(lines: list[str], start_idx: int, expected_size: int) -> tuple[bytes, int]:
    data: list[int] = []
    j = start_idx

    while j < len(lines) and len(data) < expected_size:
        stripped = strip_comment(lines[j]).strip()
        if not stripped:
            j += 1
            continue
        if is_label_line(stripped):
            break
        dta_match = DTA_RE.match(stripped)
        if not dta_match:
            break
        for token in split_csv(dta_match.group(1)):
            data.append(parse_numeric_token(token) & 0xFF)
        j += 1

    if len(data) != expected_size:
        raise ValueError(
            f"inline tile payload size mismatch: expected {expected_size}, got {len(data)}"
        )

    return bytes(data), j - 1


def scale_pixels_x2(src_pixels: list[int], src_width: int, src_height: int) -> tuple[int, int, list[int]]:
    dst_width = src_width * 2
    dst_height = src_height * 2
    dst: list[int] = []

    for y in range(src_height):
        row = src_pixels[y * src_width:(y + 1) * src_width]
        scaled_row: list[int] = []
        for pix in row:
            scaled_row.extend([pix, pix])
        dst.extend(scaled_row)
        dst.extend(scaled_row)

    return dst_width, dst_height, dst


def words_to_pascal_array(name: str, data: list[int]) -> str:
    vals = [f"${w:04X}" for w in data]
    rows = []
    for i in range(0, len(vals), 8):
        rows.append("  " + ",".join(vals[i:i + 8]))
    body = ",\n".join(rows)
    return f"const {name} : array[0..{len(data)-1}] of word=(\n{body}\n);\n"


def pack_st_masked_words(src_pixels: list[int], width_px: int, height_px: int) -> tuple[int, list[int], list[int]]:
    width_words = (width_px + 15) // 16
    mask_words: list[int] = []
    gfx_words: list[int] = []

    for y in range(height_px):
        row = src_pixels[y * width_px:(y + 1) * width_px]
        for word_idx in range(width_words):
            mask = 0xFFFF
            p0 = 0
            p1 = 0
            p2 = 0
            p3 = 0
            base_x = word_idx * 16

            for bit_idx in range(16):
                src_x = base_x + bit_idx
                if src_x < 0 or src_x >= width_px:
                    continue
                c = row[src_x]
                if c == 0:
                    continue
                bit = 1 << (15 - bit_idx)
                mask &= (~bit) & 0xFFFF
                if c & 1:
                    p0 |= bit
                if c & 2:
                    p1 |= bit
                if c & 4:
                    p2 |= bit
                if c & 8:
                    p3 |= bit

            mask_words.append(mask)
            gfx_words.extend([p0, p1, p2, p3])

    return width_words, mask_words, gfx_words


def extract_tiles(asm_path: Path, labels: dict[str, int]) -> list[dict]:
    lines = asm_path.read_text().splitlines()
    tiles: list[dict] = []

    i = 0
    while i < len(lines):
        stripped = strip_comment(lines[i]).strip()
        label_match = LABEL_RE.match(stripped)
        if label_match and label_match.group(1).startswith("tile_"):
            tile_labels = [label_match.group(1)]
            j = i + 1
            while j < len(lines):
                next_line = strip_comment(lines[j]).strip()
                if not next_line:
                    j += 1
                    continue
                label_match = LABEL_RE.match(next_line)
                if label_match and label_match.group(1).startswith("tile_"):
                    tile_labels.append(label_match.group(1))
                    j += 1
                    continue
                break
            while j < len(lines) and not strip_comment(lines[j]).strip():
                j += 1
            dta_line = strip_comment(lines[j]).strip() if j < len(lines) else ""
            dta_match = DTA_RE.match(dta_line)
            if not dta_match:
                raise ValueError(f"expected dta after {'/'.join(tile_labels)} in {asm_path}")
            dims = split_csv(dta_match.group(1))
            if len(dims) < 2:
                raise ValueError(f"expected width,height in {'/'.join(tile_labels)} from {asm_path}")
            width_bytes = parse_numeric_token(dims[0])
            height_rows = parse_numeric_token(dims[1])
            expected_size = width_bytes * height_rows

            j += 1
            while j < len(lines) and not strip_comment(lines[j]).strip():
                j += 1
            payload_line = strip_comment(lines[j]).strip() if j < len(lines) else ""
            ins_match = INS_RE.match(payload_line)
            if ins_match:
                gfx_path = (asm_path.parent / ins_match.group(1)).resolve()
                gfx_raw = gfx_path.read_bytes()
            else:
                gfx_raw, j = read_inline_tile_bytes(lines, j, expected_size)
            src_pixels = decode_atari_2bpp(gfx_raw, width_bytes, height_rows)
            src_width = width_bytes * 4
            width_px, height_px, scaled_pixels = scale_pixels_x2(src_pixels, src_width, height_rows)

            for label in tile_labels:
                tiles.append({
                    "label": label,
                    "source_addr": labels[label],
                    "source_width": src_width,
                    "source_height": height_rows,
                    "source_pixels": src_pixels,
                    "width_px": width_px,
                    "height_px": height_px,
                    "pixels": scaled_pixels,
                })
            i = j
        i += 1

    return tiles


def write_world_tile_include(world_idx: int, tiles: list[dict]) -> None:
    word_blob: list[int] = []
    records: list[str] = []

    for tile in tiles:
        row_words, mask, gfx = pack_st_masked_words(
            tile["pixels"], tile["width_px"], tile["height_px"]
        )
        data_offset = len(word_blob)
        word_blob.extend(mask)
        word_blob.extend(gfx)
        records.append(
            f"    (sourceAddr:${tile['source_addr']:04X}; widthPx:{tile['width_px']}; "
            f"heightPx:{tile['height_px']}; rowWords:{row_words}; "
            f"dataOffset:{data_offset})"
        )

    world_name = f"W{world_idx:02d}"
    out_path = OUT_DIR / f"world_{world_idx:02d}_tiles.inc"
    with out_path.open("w") as f:
        f.write(f"const {world_name}_TILE_COUNT = {len(tiles)};\n")
        if tiles:
            f.write(f"const {world_name}_TILES : array[0..{len(tiles)-1}] of TSteTile = (\n")
            f.write(",\n".join(records))
            f.write("\n);\n\n")
            f.write(words_to_pascal_array(f"{world_name}_TILE_WORDS", word_blob))
        else:
            f.write(f"const {world_name}_TILES : array[0..0] of TSteTile = (\n")
            f.write("    (sourceAddr:0; widthPx:0; heightPx:0; rowWords:0; dataOffset:0)\n")
            f.write(");\n\n")
            f.write(f"const {world_name}_TILE_WORDS : array[0..0] of word=(\n  $0000\n);\n")


def write_master_include() -> None:
    out_path = OUT_DIR / "world_tiles.inc"
    with out_path.open("w") as f:
        f.write("// Generated from canonical game_tiles indexed PNG files.\n")
        for idx in range(len(WORLD_DIRS)):
            f.write(f"{{$i worlds/world_{idx:02d}_tiles.inc}}\n")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    manifest_path = GAME_TILES / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    if not manifest.get("canonical_build_source"):
        raise ValueError(f"{manifest_path}: not marked as a canonical build source")

    by_world: dict[int, list[dict]] = {idx: [] for idx in range(len(WORLD_DIRS))}
    seen_addresses: set[tuple[int, int]] = set()
    for entry in manifest["tiles"]:
        world_idx = int(entry["world"])
        source_addr = int(entry["source_addr"])
        address_key = (world_idx, source_addr)
        if address_key in seen_addresses:
            continue
        seen_addresses.add(address_key)
        image_path = FLOB_STE / entry["image"]
        image = Image.open(image_path)
        if image.mode != "P":
            raise ValueError(f"{image_path}: tile must be an indexed PNG")
        expected_size = tuple(int(value) for value in entry["size"])
        if image.size != expected_size:
            raise ValueError(
                f"{image_path}: expected {expected_size}, got {image.size}"
            )
        pixels = [int(value) for value in image.getdata()]
        used_indices = set(pixels)
        if not used_indices.issubset({0, 1, 2, 3}):
            raise ValueError(
                f"{image_path}: palette indices outside 0..3: "
                f"{sorted(used_indices)}"
            )
        by_world[world_idx].append({
            "index": int(entry["index"]),
            "label": entry["label"],
            "source_addr": source_addr,
            "width_px": image.width,
            "height_px": image.height,
            "pixels": pixels,
        })

    for idx in range(len(WORLD_DIRS)):
        tiles = sorted(by_world[idx], key=lambda tile: tile["index"])
        write_world_tile_include(idx, tiles)
        print(f"world_{idx:02d}: {len(tiles)} canonical tiles")

    write_master_include()


if __name__ == "__main__":
    main()
