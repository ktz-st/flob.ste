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
WORLDS_SRC = FLOB_SRC / 'worlds'
ASSETS_SRC = FLOB_SRC / 'assets'
OUTDIR     = FLOB_STE / 'images'

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

def gif_to_pi1(gif_path: Path) -> bytes:
    """
    Convert GIF to PI1 (32034 bytes, ST low 320x200x16).
    Scales to fit 320x200, maintaining aspect ratio, pads with black.
    """
    pnm = subprocess.check_output(['giftopnm', str(gif_path)], stderr=subprocess.DEVNULL)
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
        raise RuntimeError(f'{gif_path}: PI1 size {len(pi1)} != 32034')
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

def gif_to_collision_bytes(gif_path: Path) -> bytes:
    """
    Extract original 160x80 2bpp palette indices (0..3) from room GIF, normalise
    by luminance and pack as 4 pixels per byte, matching Atari/STE GetPix semantics.

    GIF palettes are often shuffled (colour order is not guaranteed).  We sort the
    four palette entries darkest→brightest so the output always has:
        0 = background / air        (black)
        1 = dark decoration         (not solid, not lethal)
        2 = solid ground            (GROUND_COLLISION_COLOR = 2)
        3 = danger / lethal         (DANGER_COLLISION_COLOR = 3)
    """
    from PIL import Image

    im = Image.open(gif_path)
    if im.mode != 'P':
        im = im.convert('P')
    if im.size != (160, 80):
        return None   # non-room image (title, credits, etc.) — no collision data

    # Build luminance-sorted remap for the first 4 palette entries.
    pal = im.getpalette() or []
    def lum(i: int) -> int:
        r, g, b = pal[i * 3], pal[i * 3 + 1], pal[i * 3 + 2]
        return r * 299 + g * 587 + b * 114          # Rec.601, no division needed
    sorted_src = sorted(range(4), key=lum)          # sorted_src[new] = old index
    remap = {old: new for new, old in enumerate(sorted_src)}

    data = list(im.getdata())
    out = bytearray()
    for y in range(80):
        row = data[y * 160:(y + 1) * 160]
        for x in range(0, 160, 4):
            p0 = remap.get(row[x + 0] & 3, 0)
            p1 = remap.get(row[x + 1] & 3, 0)
            p2 = remap.get(row[x + 2] & 3, 0)
            p3 = remap.get(row[x + 3] & 3, 0)
            out.append((p0 << 6) | (p1 << 4) | (p2 << 2) | p3)
    return bytes(out)

def convert_image(gif_path: Path, out_dir: Path, name: str) -> tuple:
    """
    Convert one GIF → NAME.inc with NAME_PAL + NAME (compressed).
    Returns (raw_size, compressed_size).
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    inc_path = out_dir / f'{name}.inc'

    pi1        = gif_to_pi1(gif_path)
    palette    = pi1[2:34]    # 32 bytes: 16 x ST palette word (big-endian)
    raw        = pi1[34:]     # 32000 bytes: 4bpp interleaved bitplanes
    compressed = compress_apultra(raw)
    collision  = gif_to_collision_bytes(gif_path)

    with open(inc_path, 'w') as f:
        f.write(bytes_to_pascal_array(f'{name}_PAL', palette))
        f.write('\n')
        f.write(bytes_to_pascal_array(name, compressed))
        if collision is not None:
            f.write('\n')
            f.write(bytes_to_pascal_array(f'{name}_COL', collision))

    return len(raw), len(compressed)

# -----------------------------------------------------------------------

def process_world(world_idx: int, world_dir_name: str) -> int:
    """Convert all room_NN.gif images for one world."""
    src_images = WORLDS_SRC / world_dir_name / 'images'
    out_dir    = OUTDIR / f'world_{world_idx:02d}'
    prefix     = f'W{world_idx:02d}_IMG'

    print(f'\nWorld {world_idx}: {world_dir_name}')

    room_gifs = sorted(
        src_images.glob('room_*.gif'),
        key=lambda p: int(re.search(r'\d+', p.stem).group()))

    names = []
    for gif in room_gifs:
        img_num = int(re.search(r'\d+', gif.stem).group())
        name    = f'{prefix}_{img_num:02d}'
        raw_sz, cmp_sz = convert_image(gif, out_dir, name)
        ratio = 100 * cmp_sz // raw_sz
        print(f'  {gif.stem}: {raw_sz} -> {cmp_sz} bytes ({ratio}%)')
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
        f.write(f'const W{world_idx:02d}_COL_PTRS: array[0..{len(names)-1}] of pointer = (\n')
        for i, n in enumerate(names):
            comma = '' if i == len(names)-1 else ','
            f.write(f'    @{n}_COL[0]{comma}\n')
        f.write(');\n')

    return len(names)

# -----------------------------------------------------------------------

GLOBAL_IMAGES = {
    # title / credits
    'IMG_TITLE':   ASSETS_SRC / 'flob_title.gif',
    'IMG_CREDITS': ASSETS_SRC / 'flob_credits.gif',
    # intro slides
    **{f'IMG_INTRO_{i:02d}': ASSETS_SRC / 'intro' / f'intro_{i:02d}.gif' for i in range(6)},
    **{f'IMG_OUTRO_{i:02d}': ASSETS_SRC / 'intro' / f'outro_{i:02d}.gif' for i in range(3)},
    'IMG_SCENE_00': ASSETS_SRC / 'intro' / 'scene_00.gif',
    # credits slides
    **{f'IMG_CREDITS_{i:02d}': ASSETS_SRC / 'credits' / f'credits_slides_{i:02d}.gif'
       for i in range(1, 9)},
}

def process_global():
    """Convert global (non-world) images."""
    out_dir = OUTDIR / 'global'
    print('\nGlobal assets:')
    names = []
    for name, gif_path in GLOBAL_IMAGES.items():
        if not gif_path.exists():
            print(f'  SKIP (not found): {gif_path}')
            continue
        raw_sz, cmp_sz = convert_image(gif_path, out_dir, name)
        ratio = 100 * cmp_sz // raw_sz
        print(f'  {gif_path.name}: {raw_sz} -> {cmp_sz} bytes ({ratio}%)')
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
