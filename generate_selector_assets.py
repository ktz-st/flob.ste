#!/usr/bin/env python3
"""Build Scale2x menu glyph masks and dedicated, palette-isolated PMG sprites."""
import re
from pathlib import Path
from PIL import Image
from export_flob_sheet import parse_consts, parse_sprite_frames
from create_game_world_icons import WORLD_DIRS, normalize_palette
from generate_world_icons import word_array
from render_title_dli import numbers

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'flob'


def scale2x(src):
    w, h = src.size
    out = Image.new('P', (w * 2, h * 2))
    def p(x, y):
        return src.getpixel((min(w-1, max(0, x)), min(h-1, max(0, y))))
    for y in range(h):
        for x in range(w):
            e, b, d, f, h0 = p(x,y), p(x,y-1), p(x-1,y), p(x+1,y), p(x,y+1)
            values = (d if d == b and d != h0 and b != f else e,
                      f if b == f and b != d and f != h0 else e,
                      d if d == h0 and d != b and h0 != f else e,
                      f if h0 == f and d != h0 and b != f else e)
            for i, value in enumerate(values):
                out.putpixel((x*2+i%2, y*2+i//2), value)
    return out


def glyphs():
    raw = (SOURCE / 'assets/flob.fnt').read_bytes()
    result = []
    for ascii_code in range(32, 128):
        code = ascii_code - 32 if ascii_code < 96 else ascii_code
        src = Image.new('P', (8, 8))
        src.putdata([(raw[code*8+y] >> (7-x)) & 1 for y in range(8) for x in range(8)])
        result.append(scale2x(src))
    return result


def sprites():
    f0, f1, labels = parse_sprite_frames(parse_consts())
    result = []
    for a, b in zip(f0, f1):
        src = Image.new('P', (8, 8))
        src.putdata([[0, 12, 13, 14][((labels[a][y] >> (7-x)) & 1) |
                    (((labels[b][y] >> (7-x)) & 1) << 1)] for y in range(8) for x in range(8)])
        result.append(scale2x(src))
    asm = (SOURCE / 'assets/sprites.asm').read_text()
    for name, end in [('larrow', 'rarrow'), ('rarrow', 'ach_cursor')]:
        rows = numbers(re.search(r'^'+name+r'\s*\n(.*?)^'+end, asm, re.M | re.S)[1])
        assert len(rows) == 30
        src = Image.new('P', (8, 30))
        src.putdata([15 if bits & (128 >> x) else 0 for bits in rows for x in range(8)])
        result.append(scale2x(src))
    return result


def icon_maps():
    maps = []
    for directory in WORLD_DIRS:
        base = SOURCE / 'worlds' / directory
        im = Image.open(base / 'images/icon.gif')
        _, normalized = normalize_palette(im.getpalette(), list(im.getdata()))
        raw = (base / 'icon.gfx').read_bytes()
        mapping = {}
        for i, index in enumerate(normalized):
            logical = (raw[i//4] >> (6-2*(i%4))) & 3
            assert index not in mapping or mapping[index] == logical
            mapping[index] = logical
        assert mapping[0] == 0
        maps.append([mapping.get(i, i) for i in range(4)])
    return maps


def main():
    fonts = glyphs()
    masks = [sum(im.getpixel((x,y)) << (15-x) for x in range(16))
             for im in fonts for y in range(16)]
    chunks = [word_array('SELECTOR_FONT_MASKS', masks)]
    chunks.append('const SELECTOR_ICON_MAP: array[0..5,0..3] of byte = (\n' +
                  ',\n'.join('    ('+','.join(map(str, row))+')' for row in icon_maps()) + '\n);')
    words, frames = [], []
    for im in sprites():
        width, height = im.size
        offset = len(words)
        for y in range(height):
            words.append(sum((im.getpixel((x,y)) == 0) << (15-x) for x in range(16)))
        data = len(words)
        for y in range(height):
            for plane in range(4):
                words.append(sum(((im.getpixel((x,y)) >> plane) & 1) << (15-x) for x in range(16)))
        frames.append(f'    (widthPx:16; heightPx:{height}; rowWords:1; maskOffset:{offset}; dataOffset:{data}; paletteOffset:0; paletteCount:0)')
    chunks.append('const SELECTOR_SPRITE_FRAMES: array[0..17] of TSteSpriteFrame = (\n'+',\n'.join(frames)+'\n);')
    chunks.append(word_array('SELECTOR_SPRITE_WORDS', words))
    (ROOT / 'assets/selector_ui.inc').write_text('\n'.join(chunks))
    preview = Image.new('RGB', (256, 96))
    for i, im in enumerate(fonts):
        im.putpalette([0,0,0,255,255,255]+[0]*762)
        preview.paste(im.convert('RGB'), ((i%16)*16,(i//16)*16))
    preview.save(ROOT / 'font/selector_16x16.png')
    print('Selector: 96 glyphs, 16 Flob frames, 2 arrows;', icon_maps())
    previews(fonts)


def previews(fonts):
    """Host layout check with the same palette slots/coordinates as Pascal."""
    rgb = bytes.fromhex((ROOT / 'assets/a8_pal_rgb.hex').read_text())
    colors = [tuple(rgb[i:i+3]) for i in range(0, 768, 3)]
    output = ROOT / 'images/selector_ste_preview'
    output.mkdir(parents=True, exist_ok=True)
    consts = dict((name, int(value)) for name, value in
                  re.findall(r'^(FRAME_\w+)\s*=\s*(\d+)', (SOURCE / 'const.inc').read_text(), re.M))
    consts['NONE'] = 255
    frames = sprites()
    maps = icon_maps()
    for locked in (False, True):
        montage = Image.new('RGB', (960, 400))
        for index, directory in enumerate(WORLD_DIRS):
            asm = (SOURCE / 'worlds' / directory / f'world_{index:02d}.asm').read_text()
            name = re.search(r'dta\s+\d+,"([^"]+)"', asm)[1].rstrip()
            goal = numbers(re.search(r'dta ([^;]+); goal colors', asm)[1])
            icon_colors = numbers(re.search(r'^icon[ \t]*\n\s*dta ([^;]+)', asm, re.M)[1])
            def field(label):
                value = re.search(r'dta\s+([^;]+);\s*'+label, asm)[1].strip()
                return consts[value] if value in consts else int(value)
            px, py, frame = field('iconFlobX'), field('iconFlobY'), field('iconFlobFrame')
            palette = [0] * 16
            for i in range(1,4):
                palette[i] = ([6,10,2] if locked else icon_colors)[maps[index][i]-1]
            palette[4:11] = [0x84,0x0f,*goal,0x1a,0x26,0x98]
            palette[12:16] = [4,8,12,0x24] if locked else [0x34,0x38,0x3c,0x24]
            im = Image.new('P', (320,200))
            im.putpalette(sum((list(colors[c]) for c in palette), []))
            for y in (28,29,118,119):
                for x in range(320): im.putpixel((x,y),4)
            icon = Image.open(ROOT / 'game_world_icons' / f'world_{index:02d}.png')
            im.paste(icon, (64,34))
            def paste_sprite(sprite, x, y):
                for sy in range(sprite.height):
                    for sx in range(sprite.width):
                        c = sprite.getpixel((sx,sy))
                        if c and 0 <= x+sx <320 and 0 <= y+sy <200:
                            im.putpixel((x+sx,y+sy), c)
            def text(s, y, color):
                s = s[:20]
                x = (320-len(s)*16)//2
                for c in s:
                    glyph = fonts[ord(c)-32]
                    for gy in range(16):
                        for gx in range(16):
                            if glyph.getpixel((gx,gy)): im.putpixel((x+gx,y+gy),color)
                    x +=16
            text('Select World:',10,4)
            text('Select World:',8,5)
            text(name,130,7)
            text(name,128,6)
            if index>0: paste_sprite(frames[16],0,44)
            if index<5: paste_sprite(frames[17],304,44)
            if frame<16: paste_sprite(frames[frame],(px-1)*2,py*2)
            if locked:
                text('LOCKED',162,8)
                text('LOCKED',160,9)
            else:
                total = re.search(r'dta\s+(\d+)\s*; total slime count',asm)[1]
                text('SLIMES 0 of '+total,168,8)
            suffix = '_locked' if locked else ''
            im.save(output / f'world_{index:02d}{suffix}.png')
            montage.paste(im.convert('RGB'), ((index%3)*320,(index//3)*200))
        montage.save(output / ('all_locked.png' if locked else 'all_worlds.png'))


if __name__ == '__main__':
    main()
