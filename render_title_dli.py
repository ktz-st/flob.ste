#!/usr/bin/env python3
"""Source-derived PAL title reference; does not replace canonical game artwork."""
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'flob'
OUTPUT = ROOT / 'images' / 'title_dli_reference'


def numbers(text):
    return [int(t[1:], 16) if t.startswith('$') else
            int(t[1:], 2) if t.startswith('%') else int(t)
            for t in re.findall(r'\$[0-9a-fA-F]+|%[01]+|\b\d+\b', text)]


def array(text, name):
    match = re.search(re.escape(name) + r':\s*array[^=]+?=\s*\((.*?)\);', text, re.S)
    if not match:
        raise ValueError(name)
    return numbers(match[1])


def ste_labels(bitmap):
    """Reuse the title's hand-drawn glyphs, including their variable widths."""
    pixels = [[(bitmap[y * 40 + x // 4] >> (6 - 2 * (x % 4))) & 3
               for x in range(160)] for y in range(92)]
    glyphs = {}
    for y, text in [(72, 'PRESSSTARTTOPLAY'),
                    (83, 'SELECTFORACHIEVEMENTSHELPFORCREDITS')]:
        occupied = [(y != 72 or 45 <= x < 116) and
                    any(pixels[row][x] for row in range(y, y + 8))
                    for x in range(160)]
        spans = []
        for x, value in enumerate(occupied):
            if value and (x == 0 or not occupied[x - 1]):
                start = x
            if value and (x == 159 or not occupied[x + 1]):
                spans.append((start, x + 1))
        assert len(spans) == len(text)
        for char, (left, right) in zip(text, spans):
            glyphs.setdefault(char, [[bool(v) for v in row[left:right]]
                                     for row in pixels[y:y + 8]])

    def width(text):
        return sum(3 if c == ' ' else len(glyphs[c][0]) + 1 for c in text) - 1

    def draw(text, x, y, key):
        for i, char in enumerate(text):
            if char == ' ':
                x += 3
                continue
            glyph = glyphs[char]
            color = 1 if key[0] <= i < key[1] else 3
            for dy, row in enumerate(glyph):
                for dx, on in enumerate(row):
                    if on:
                        pixels[y + dy][x + dx] = color
            x += len(glyph[0]) + 1

    for y in range(72, 80):
        pixels[y][45:116] = [0] * 71
    for y in range(83, 91):
        pixels[y][:] = [0] * 160
    text = 'PRESS FIRE TO START'
    draw(text, (160 - width(text)) // 2, 72, (6, 10))
    draw('A FOR ACHIEVEMENTS', 2, 83, (0, 1))
    text = 'C FOR CREDITS'
    draw(text, 158 - width(text), 83, (0, 1))
    packed = bytearray(len(bitmap))
    for y, row in enumerate(pixels):
        for x, value in enumerate(row):
            packed[y * 40 + x // 4] |= value << (6 - 2 * (x % 4))
    return packed


def main():
    pas = (SOURCE / 'flob.pas').read_text()
    colors = array(pas, 'mainTitleColors')
    bitmap = bytearray((SOURCE / 'assets/flob_title.gfx').read_bytes())
    assert len(bitmap) == 40 * 92
    for x, y, tile in [(1, 71, array(pas, '_mono')),
                       (35, 71, array((SOURCE / 'vnumber.inc').read_text(), '_VERGFX'))]:
        width, height = tile[:2]
        assert len(tile) == 2 + width * height
        for row in range(height):
            for col in range(width):
                value = tile[2 + row * width + col]
                offset = (y + row) * 40 + x + col
                for shift in (6, 4, 2, 0):
                    if (value >> shift) & 3:
                        bitmap[offset] = (bitmap[offset] & ~(3 << shift)) | (value & (3 << shift))

    # ANTIC starts its display list at PAL scanline 8. Four 8-line blanks
    # precede the bitmap; mode D repeats each source row for two scanlines.
    dl = (SOURCE / 'dlist_title.asm').read_text()
    dl = dl.split('display_list_title', 1)[1]
    instructions = []
    for line in dl.splitlines():
        if 'dta' not in line:
            continue
        for token in line.split('dta', 1)[1].split(','):
            token = token.strip()
            if token.startswith('$'):
                instructions.append(int(token.split()[0][1:], 16) |
                                    (128 if '+ DL_DLI' in token else 0))
    scanline = 8
    rows = []
    for op in instructions:
        if op == 0x41:
            break
        if op & 15 == 0:
            scanline += ((op >> 4) & 7) + 1
        elif op & 15 == 13:
            rows.append(scanline)
            scanline += 2
        else:
            raise ValueError(f'Unsupported ANTIC instruction {op:02x}')
    assert len(rows) == 92
    palette = bytes.fromhex((ROOT / 'assets/a8_pal_rgb.hex').read_text())
    assert len(palette) == 768
    rgb = [tuple(palette[i:i+3]) for i in range(0, 768, 3)]
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for late, adapted in [(False, False), (True, False), (False, True), (True, True)]:
        render_bitmap = ste_labels(bitmap) if adapted else bitmap
        image = Image.new('RGB', (320, 184))
        for y in range(184):
            band = colors[:3] if rows[y // 2] + y % 2 < 180 else colors[3:]
            band = list(band)
            if late and rows[y // 2] + y % 2 >= 180:
                band[1] = 0
            selectors = [0] + band
            for x in range(320):
                sx = x // 2
                selector = (render_bitmap[(y // 2) * 40 + sx // 4] >> (6 - 2 * (sx % 4))) & 3
                image.putpixel((x, y), rgb[selectors[selector]])
        name = 'title_after_150_frames' if late else 'title_initial'
        if adapted:
            name += '_ste'
        image.save(OUTPUT / f'{name}.png')
        print(name, image.size, len(set(image.getdata())), 'colors')
    (OUTPUT / 'raster.json').write_text(json.dumps({
        'source': 'flob/assets/flob_title.gfx', 'mode': 'ANTIC D',
        'region': 'PAL', 'bitmap_first_scanline': rows[0],
        'color_change_scanline': 180, 'color_change_image_y': 180 - rows[0],
        'initial_pf_colors': colors[:3], 'lower_pf_colors': colors[3:],
        'pmg': 'disabled by DisplayOn', 'overlays': ['mono', 'source version'],
        'verification': 'source-derived; precise DLI boundary not verified in an A8 emulator',
        'scaling': 'nearest-neighbour 160x92 to 320x184',
        'ste_labels': ['PRESS FIRE TO START', 'A FOR ACHIEVEMENTS', 'C FOR CREDITS'],
        'ste_label_art': 'glyphs recovered from source bitmap; suffix _ste'
    }, indent=2) + '\n')


if __name__ == '__main__':
    main()
