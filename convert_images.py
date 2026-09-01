#!/usr/bin/env python3
"""
convert_images.py  --  convert GIF level backgrounds to aplib-compressed ST bitplane includes.

Output format per image (one .inc file):
    const NAME_PAL : array[0..31] of byte = (...);   // 16 x 2-byte ST palette words
    const NAME     : array[0..N-1] of byte = (...);  // apultra-compressed bitplane data

Matches the pattern used by fuji-tetris teamlogo.inc.

Usage (from flob-ste/):
    python3 convert_images.py
"""

import os, sys, struct, subprocess, tempfile, re
from pathlib import Path

FLOB_SRC   = Path('/Users/kriss/GCC.ELF/flob')
FLOB_STE   = Path('/Users/kriss/GCC.ELF/flob-ste')
ASSETS_SRC = FLOB_SRC / 'assets'
OUTDIR     = FLOB_STE / 'images'
GAME_ROOMS = FLOB_STE / 'game_rooms'
GAME_CUTSCENES = FLOB_STE / 'game_cutscenes'
GAME_TITLE = FLOB_STE / 'game_title'

WORLD_DIRS = [
    '00_Escape_From_The_Lab',
    '01_Abominable_Sewers',
    '02_Suburbian_Parkour',
    '03_Hazardous_Mudlands',
    '04_Silver_Dust_Mines',
    '05_Return_To_The_Lab',
]

# -----------------------------------------------------------------------

def pnm_dims(pnm_bytes: bytes):
    """Parse width/height from PNM header."""
    lines = pnm_bytes.split(b'\n')
    dims = lines[1].decode().split()
    return int(dims[0]), int(dims[1])

def image_to_pi1(image_path: Path) -> bytes:
    """
    Convert GIF to PI1 (32034 bytes, ST low 320x200x16).
    Scales to fit 320x200, maintaining aspect ratio, pads with black.
    """
    if image_path.suffix.lower() == '.png':
        converter = 'pngtopnm'
    else:
        converter = 'giftopnm'
    pnm = subprocess.check_output([converter, str(image_path)], stderr=subprocess.DEVNULL)
    orig_w, orig_h = pnm_dims(pnm)

    # Scale to fit 320x200, integer scale preferred for pixel art
    scale_x = 320 // orig_w
    scale_y = 200 // orig_h
    scale   = max(1, min(scale_x, scale_y))
    new_w   = orig_w * scale
    new_h   = orig_h * scale

    # If still too small, stretch to exactly 320 wide
    if new_w < 320 and scale < 2:
        new_w = 320
        new_h = orig_h * 320 // orig_w

    # Clamp to 320x200
    new_w = min(new_w, 320)
    new_h = min(new_h, 200)

    pad_top    = (200 - new_h) // 2
    pad_bottom = 200 - new_h - pad_top
    pad_left   = (320 - new_w) // 2
    pad_right  = 320 - new_w - pad_left

    if (orig_w, orig_h) == (new_w, new_h):
        scaled = pnm
    else:
        scaled = subprocess.check_output(
            ['pnmscale', '-xsize', str(new_w), '-ysize', str(new_h)],
            input=pnm, stderr=subprocess.DEVNULL)

    padded = subprocess.check_output(
        ['pnmpad', '-black',
         '-top',    str(pad_top),    '-bottom', str(pad_bottom),
         '-left',   str(pad_left),   '-right',  str(pad_right)],
        input=scaled, stderr=subprocess.DEVNULL)

    pi1 = subprocess.check_output(['ppmtopi1'], input=padded, stderr=subprocess.DEVNULL)
    if len(pi1) != 32034:
        raise RuntimeError(f'{image_path}: PI1 size {len(pi1)} != 32034')
    return pi1

def compress_apultra(raw: bytes) -> bytes:
    """Compress raw bytes with apultra."""
    with tempfile.TemporaryDirectory() as td:
        raw_path = os.path.join(td, 'img.raw')
        apu_path = os.path.join(td, 'img.apu')
        with open(raw_path, 'wb') as f:
            f.write(raw)
        subprocess.check_call(['apultra', raw_path, apu_path],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with open(apu_path, 'rb') as f:
            return f.read()

def bytes_to_pascal_array(name: str, data: bytes) -> str:
    """Format bytes as a Pascal typed const array.

    The 68000 requires word-aligned access; pad to even length so the next
    const in the same segment always starts on an even address.
    """
    if len(data) % 2 != 0:
        data = data + b'\x00'   # alignment padding
    hex_vals = [f'${b:02X}' for b in data]
    rows = []
    for i in range(0, len(hex_vals), 15):
        chunk = hex_vals[i:i+15]
        rows.append('  ' + ','.join(chunk))
    body = ',\n'.join(rows)
    return f'const {name} : array[0..{len(data)-1}] of byte=(\n{body});\n'

def convert_image(image_path: Path, out_dir: Path, name: str) -> tuple:
    """
    Convert one indexed image to NAME.inc with NAME_PAL + NAME (compressed).
    Returns (raw_size, compressed_size).
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    inc_path = out_dir / f'{name}.inc'

    newest_input = max(image_path.stat().st_mtime, Path(__file__).stat().st_mtime)
    if inc_path.exists() and inc_path.stat().st_mtime >= newest_input:
        return None

    pi1        = image_to_pi1(image_path)
    palette    = pi1[2:34]    # 32 bytes: 16 x ST palette word (big-endian)
    raw        = pi1[34:]     # 32000 bytes: 4bpp interleaved bitplanes
    compressed = compress_apultra(raw)

    with open(inc_path, 'w') as f:
        f.write(bytes_to_pascal_array(f'{name}_PAL', palette))
        f.write('\n')
        f.write(bytes_to_pascal_array(name, compressed))

    return len(raw), len(compressed)

# -----------------------------------------------------------------------

def process_world(world_idx: int, world_dir_name: str) -> int:
    """Convert canonical 320x160 room PNG files for one world."""
    src_images = GAME_ROOMS / f'world_{world_idx:02d}'
    out_dir    = OUTDIR / f'world_{world_idx:02d}'
    prefix     = f'W{world_idx:02d}_IMG'

    print(f'\nWorld {world_idx}: {world_dir_name}')

    room_images = sorted(
        src_images.glob('room_[0-9][0-9].png'),
        key=lambda p: int(re.search(r'\d+', p.stem).group()))

    names = []
    for room_png in room_images:
        img_num = int(re.search(r'\d+', room_png.stem).group())
        name    = f'{prefix}_{img_num:02d}'
        result = convert_image(room_png, out_dir, name)
        if result is not None:
            raw_sz, cmp_sz = result
            ratio = 100 * cmp_sz // raw_sz
            print(f'  {room_png.stem}: {raw_sz} -> {cmp_sz} bytes ({ratio}%)')
        names.append(name)

    # Master include for this world
    with open(OUTDIR / f'images_world_{world_idx:02d}.inc', 'w') as f:
        for name in names:
            f.write(f'{{$i images/world_{world_idx:02d}/{name}.inc}}\n')
        f.write(f'\nconst W{world_idx:02d}_IMG_COUNT = {len(names)};\n')
        f.write(f'const W{world_idx:02d}_IMG_PTRS: array[0..{len(names)-1}] of pointer = (\n')
        for i, n in enumerate(names):
            comma = '' if i == len(names)-1 else ','
            f.write(f'    @{n}[0]{comma}\n')
        f.write(');\n')
        f.write(f'const W{world_idx:02d}_PAL_PTRS: array[0..{len(names)-1}] of pointer = (\n')
        for i, n in enumerate(names):
            comma = '' if i == len(names)-1 else ','
            f.write(f'    @{n}_PAL[0]{comma}\n')
        f.write(');\n')
    return len(names)

# -----------------------------------------------------------------------

GLOBAL_IMAGES = {
    # title / credits
    'IMG_TITLE':   GAME_TITLE / 'title.png',
    'IMG_TITLE_CROWN': GAME_TITLE / 'title_crown.png',
    'IMG_CREDITS': ASSETS_SRC / 'flob_credits.gif',
    # Canonical Scale2x cutscene slides.
    **{f'IMG_INTRO_{i:02d}': GAME_CUTSCENES / f'intro_{i:02d}.png' for i in range(6)},
    **{f'IMG_OUTRO_{i:02d}': GAME_CUTSCENES / f'outro_{i:02d}.png' for i in range(3)},
    # credits slides
    **{f'IMG_CREDITS_{i:02d}': ASSETS_SRC / 'credits' / f'credits_slides_{i:02d}.gif'
       for i in range(1, 9)},
}


def process_global():
    """Convert global (non-world) images."""
    out_dir = OUTDIR / 'global'
    print('\nGlobal assets:')
    names = []
    for name, image_path in GLOBAL_IMAGES.items():
        if not image_path.exists():
            print(f'  SKIP (not found): {image_path}')
            continue
        result = convert_image(image_path, out_dir, name)
        if result is not None:
            raw_sz, cmp_sz = result
            ratio = 100 * cmp_sz // raw_sz
            print(f'  {image_path.name}: {raw_sz} -> {cmp_sz} bytes ({ratio}%)')
        names.append(name)

    with open(OUTDIR / 'images_global.inc', 'w') as f:
        for name in names:
            f.write(f'{{$i images/global/{name}.inc}}\n')

# -----------------------------------------------------------------------

if __name__ == '__main__':
    OUTDIR.mkdir(parents=True, exist_ok=True)

    for idx, wdir in enumerate(WORLD_DIRS):
        process_world(idx, wdir)

    process_global()

    # Master images.inc
    with open(OUTDIR / 'images.inc', 'w') as f:
        for idx in range(len(WORLD_DIRS)):
            f.write(f'{{$i images/images_world_{idx:02d}.inc}}\n')
        f.write('{$i images/images_global.inc}\n')

    print('\nDone. images/images.inc written.')
