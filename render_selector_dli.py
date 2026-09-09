#!/usr/bin/env python3
"""Source-derived PAL A8 selector reference, not an STE game asset."""
import json
import re
from pathlib import Path

from PIL import Image
from export_flob_sheet import parse_consts, parse_sprite_frames
from render_title_dli import array, numbers

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'flob'
OUT = ROOT / 'images/selector_dli_reference'


def main():
    pas = (SOURCE / 'flob.pas').read_text()
    colors = array(pas, 'selectorColors')
    world = SOURCE / 'worlds/00_Escape_From_The_Lab'
    asm = (world / 'world_00.asm').read_text()
    icon_colors = numbers(re.search(r'^icon[ \t]*\n\s*dta ([^;]+)', asm, re.M)[1])
    goal = numbers(re.search(r'dta ([^;]+); goal colors', asm)[1])
    name = re.search(r'dta 19,"([^"]+)"', asm)[1].rstrip()
    font = (SOURCE / 'assets/flob.fnt').read_bytes()
    bitmap = [[0] * 160 for _ in range(92)]

    def text(s, y, color):
        # PutCString centres within 20 8-pixel glyphs, in byte units.
        x = max(0, 20 - len(s)) * 4
        for c in s:
            code = ord(c)
            code = code - 32 if 32 <= code < 96 else code
            for dy, bits in enumerate(font[code * 8:code * 8 + 8]):
                for dx in range(8):
                    if bits & (128 >> dx):
                        bitmap[y + dy][x + dx] |= color
            x += 8

    def shadow(s, y, color, shade):
        text(s, y + 1, shade)
        text(s, y, color)

    shadow('Select World:', 0, 3, 1)
    bitmap[10] = [1] * 160
    bitmap[55] = [1] * 160
    icon = (world / 'icon.gfx').read_bytes()
    assert len(icon) == 24 * 40
    for y in range(40):
        for x in range(96):
            bitmap[13 + y][32 + x] = (icon[y * 24 + x // 4] >> (6 - 2 * (x % 4))) & 3
    shadow(name, 60, 1, 2)
    shadow('SLIMES 0 of 109', 80, 2, 0)

    # Decode the reused title display list, including its second DLI trigger.
    dl = (SOURCE / 'dlist_title.asm').read_text().split('display_list_title', 1)[1]
    scan = 8
    rows, irqs = [], []
    for line in dl.splitlines():
        if 'dta' not in line:
            continue
        for token in line.split('dta', 1)[1].split(','):
            token = token.strip()
            if not token.startswith('$'):
                continue
            op = int(re.match(r'\$([0-9a-f]+)', token)[1], 16)
            if 'DL_DLI' in token:
                op |= 128
            if op == 0x41:
                break
            height = 2 if op & 15 == 13 else ((op >> 4) & 7) + 1
            if op & 15 == 13:
                rows.append(scan)
            if op & 128:
                irqs.append(scan + height - 1)
            scan += height
    assert len(rows) == 92
    name_scan = irqs[1] + 8
    stats_scan = name_scan + 18
    palette = bytes.fromhex((ROOT / 'assets/a8_pal_rgb.hex').read_text())
    rgb = [tuple(palette[i:i+3]) for i in range(0, 768, 3)]
    image = Image.new('RGB', (320, 184))
    for y in range(184):
        scan = rows[y // 2] + y % 2
        pf = colors[3:6]
        if 61 <= scan < 149:
            pf = icon_colors
        if name_scan <= scan < stats_scan:
            pf = goal + [colors[5]]
        if scan >= stats_scan:
            pf = colors[6:9]
        for x in range(320):
            image.putpixel((x, y), rgb[([0] + pf)[bitmap[y // 2][x // 2]]])

    # Double-line PMG: HPOS is in colour clocks, vertical addresses in pairs
    # of hardware scanlines. World 0 hides the left navigation arrow.
    sprites = (SOURCE / 'assets/sprites.asm').read_text()
    arrow = numbers(re.search(r'^rarrow\s*\n(.*?)^ach_cursor', sprites, re.M | re.S)[1])
    def pmg(rows, hpos, address_y, color):
        for row, bits in enumerate(rows):
            for bit in range(8):
                if bits & (128 >> bit):
                    x = (hpos - 48 + bit) * 2
                    y = (address_y + row) * 2 - 40
                    for dy in range(2):
                        for dx in range(2):
                            if 0 <= x + dx < 320 and 0 <= y + dy < 184:
                                image.putpixel((x + dx, y + dy), rgb[color])
    pmg(arrow, 200, 38, 0x24)
    frames0, frames1, labels = parse_sprite_frames(parse_consts())
    p0, p1 = labels[frames0[1]], labels[frames1[1]]
    # PRIOR bit 5 combines overlapping players with colour-register OR.
    for mask, color in [(0, 0x34), (1, 0x38), (2, 0x34 | 0x38)]:
        bits = [(a & ~b) if mask == 0 else (b & ~a) if mask == 1 else (a & b)
                for a, b in zip(p0, p1)]
        pmg(bits, 74 + 47, 33 + 16, color)
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / 'world_00.png')
    image.resize((960, 552), Image.Resampling.NEAREST).save(OUT / 'world_00_3x.png')
    (OUT / 'raster.json').write_text(json.dumps({
        'source': 'ShowWorldSelector, PutIcon, PutCString, dliselect/dliselect1',
        'state': 'world 0, unlocked, initial stats, 0 collected slimes',
        'region': 'PAL', 'bitmap_first_scanline': rows[0],
        'dli_irq_scanlines': irqs,
        'palette_changes_scanlines': [61, 149, name_scan, stats_scan],
        'icon_colors': icon_colors, 'goal_colors': goal,
        'pmg': 'Flob frame 1, right arrow; normal-width double-line players',
        'verification': 'source-derived; exact WSYNC/raster boundaries and PMG priority not emulator-verified',
    }, indent=2) + '\n')
    print(OUT / 'world_00.png')


if __name__ == '__main__':
    main()
