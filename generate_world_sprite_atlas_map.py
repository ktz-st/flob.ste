#!/usr/bin/env python3
"""
Generate Pascal lookup from PUT_SPRITES source addresses to atlas rows.

Atlas rows are named after original labels:
  sprite_bench_portal_p0
  sprite_bench_portal_p1
so the generated mapping is deliberately mechanical and easy to audit.
"""

from __future__ import annotations

import json
import re
import hashlib
from pathlib import Path

ROOT = Path("/Users/kriss/GCC.ELF")
FLOB_SRC = ROOT / "flob"
FLOB_STE = ROOT / "flob-ste"
WORLDS_SRC = FLOB_SRC / "worlds"
ATLAS_JSON = FLOB_STE / "images" / "sprite_atlas" / "all_sprites.json"
OUT_PATH = FLOB_STE / "generated" / "world_sprite_atlas_map.inc"

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
BYTE_LINE_RE = re.compile(r"^\s*\.byte\s*(.*)$", re.IGNORECASE)
PUT_SPRITES_RE = re.compile(r"dta\s+PUT_SPRITES,\s*a\((sprite_[^)]+)\)", re.IGNORECASE)


def strip_comment(line: str) -> str:
    return line.split(";", 1)[0].rstrip()


def split_csv(expr: str) -> list[str]:
    parts: list[str] = []
    current: list[str] = []
    in_quote = False
    depth = 0
    for ch in expr:
        if ch == '"':
            in_quote = not in_quote
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
    for raw_line in path.read_text(errors="ignore").splitlines():
        line = strip_comment(raw_line)
        match = BYTE_LINE_RE.match(line)
        if match:
            total += len(split_csv(match.group(1)))
    return total


def compute_label_addresses(asm_path: Path) -> dict[str, int]:
    labels: dict[str, int] = {}
    pc = 0
    for raw_line in asm_path.read_text(errors="ignore").splitlines():
        stripped = strip_comment(raw_line).strip()
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
    return labels


def find_world_sprite_sources() -> list[tuple[int, str, Path]]:
    found: dict[tuple[int, str], Path] = {}
    for world_idx, world_dir in enumerate(WORLD_DIRS):
        asm_path = WORLDS_SRC / world_dir / f"world_{world_idx:02d}.asm"
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


def to_ident(name: str) -> str:
    return "".join(ch if ch.isalnum() else "_" for ch in name).upper()


def emit_assign(slot: int, atlas_name: str) -> list[str]:
    ident = to_ident(atlas_name)
    return [
        f"            spriteAtlasFrames[{slot}] := @SPR_{ident}_FRAMES[0];",
        f"            spriteAtlasWords[{slot}] := @SPR_{ident}_WORDS[0];",
        f"            spriteAtlasFrameCount[{slot}] := SPR_{ident}_FRAME_COUNT;",
    ]


def main() -> None:
    atlas_meta = json.loads(ATLAS_JSON.read_text())
    atlas_names = {row["name"] for row in atlas_meta["rows"]}
    duplicate_labels = labels_with_different_sources(find_world_sprite_sources())

    lines: list[str] = []
    lines.append("procedure ClearWorldSpriteAtlas;")
    lines.append("begin")
    lines.append("    FillChar(spriteAtlasFrames, SizeOf(spriteAtlasFrames), 0);")
    lines.append("    FillChar(spriteAtlasWords, SizeOf(spriteAtlasWords), 0);")
    lines.append("    FillChar(spriteAtlasFrameCount, SizeOf(spriteAtlasFrameCount), 0);")
    lines.append("end;")
    lines.append("")
    lines.append("procedure SetupWorldSpriteAtlas(worldNum: byte; addr: word);")
    lines.append("begin")
    lines.append("    ClearWorldSpriteAtlas;")
    lines.append("    case worldNum of")

    mapped = 0
    missing: list[str] = []
    for world_idx, world_dir in enumerate(WORLD_DIRS):
        asm_path = WORLDS_SRC / world_dir / f"world_{world_idx:02d}.asm"
        labels = compute_label_addresses(asm_path)
        text = asm_path.read_text(errors="ignore")
        used_labels = sorted(set(PUT_SPRITES_RE.findall(text)), key=lambda label: labels.get(label, 0))
        lines.append(f"        {world_idx}: case addr of")
        for label in used_labels:
            if label not in labels:
                continue
            atlas_label = atlas_label_for_source(world_idx, label, duplicate_labels)
            p0 = f"{atlas_label}_p0"
            p1 = f"{atlas_label}_p1"
            has_p0 = p0 in atlas_names
            has_p1 = p1 in atlas_names
            if not has_p0 and not has_p1:
                missing.append(label)
                continue
            mapped += 1
            lines.append(f"            ${labels[label]:04X}: begin // {label}")
            if has_p0:
                lines.extend(emit_assign(0, p0))
            if has_p1:
                lines.extend(emit_assign(1, p1))
            lines.append("            end;")
        lines.append("        end;")
    lines.append("    end;")
    lines.append("end;")
    lines.append("")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text("\n".join(lines))
    print(f"wrote {OUT_PATH}")
    print(f"mapped world sprite labels: {mapped}")
    if missing:
        print("missing atlas rows:")
        for label in sorted(set(missing)):
            print(f"  {label}")


if __name__ == "__main__":
    main()
