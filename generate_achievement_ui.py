#!/usr/bin/env python3
"""Scale2x original trophy tiles, with independent world/master palettes."""
import re
from pathlib import Path
from PIL import Image
from generate_selector_assets import scale2x
from generate_world_icons import word_array
from render_title_dli import numbers

ROOT = Path(__file__).resolve().parent


def main():
    source = (ROOT.parent / 'flob/assets/sprites.asm').read_text()
    frames, words, previews = [], [], []
    for master in (False, True):
        for name, end in [('ach_off','ach_on'),('ach_on','ach_new'),('ach_new','f_flob0_left')]:
            tile = numbers(re.search(r'^'+name+r'\s*\n(.*?)^'+end, source,re.M|re.S)[1])
            assert tile[:2] == [3,10] and len(tile)==32
            im = Image.new('P',(12,10))
            im.putdata([(tile[2+y*3+x//4]>>(6-2*(x%4)))&3 for y in range(10) for x in range(12)])
            im = scale2x(im)
            if master: im.putdata([c+3 if c else 0 for c in im.getdata()])
            previews.append(im.copy())
            padded = Image.new('P',(32,20))
            padded.paste(im,(0,0))
            m = len(words)
            for y in range(20):
                for bx in (0,16):
                    words.append(sum((padded.getpixel((bx+x,y))==0)<<(15-x) for x in range(16)))
            d = len(words)
            for y in range(20):
                for bx in (0,16):
                    for p in range(4):
                        words.append(sum(((padded.getpixel((bx+x,y))>>p)&1)<<(15-x) for x in range(16)))
            frames.append(f'(widthPx:32; heightPx:20; rowWords:2; maskOffset:{m}; dataOffset:{d}; paletteOffset:0; paletteCount:0)')
    # A 24x21 outline padded to 32 pixels; unlike FillRect16 this can be
    # positioned at the grid's alternating 0/8-pixel word alignment.
    cursor = Image.new('P', (32,21))
    for y in range(21):
        for x in range(24):
            if x in (0,23) or y in (0,20): cursor.putpixel((x,y),15)
    m = len(words)
    for y in range(21):
        for bx in (0,16):
            words.append(sum((cursor.getpixel((bx+x,y))==0)<<(15-x) for x in range(16)))
    d = len(words)
    for y in range(21):
        for bx in (0,16):
            bits = sum(bool(cursor.getpixel((bx+x,y)))<<(15-x) for x in range(16))
            words.extend([bits]*4)
    frames.append(f'(widthPx:32; heightPx:21; rowWords:2; maskOffset:{m}; dataOffset:{d}; paletteOffset:0; paletteCount:0)')
    out = 'const ACH_UI_FRAMES: array[0..6] of TSteSpriteFrame = (\n'+',\n'.join(frames)+'\n);\n'
    out += word_array('ACH_UI_WORDS',words)
    (ROOT/'assets/achievement_ui.inc').write_text(out)
    palette = bytes.fromhex((ROOT/'assets/a8_pal_rgb.hex').read_text())
    pal = sum((list(palette[c*3:c*3+3]) for c in [0,8,12,2,0x16,0x1a,0x12]),[])
    sheet = Image.new('RGB',(144,20))
    for i, im in enumerate(previews):
        im.putpalette(pal+[0]*(768-len(pal)))
        sheet.paste(im.convert('RGB'),(24*i,0))
    sheet.resize((576,80),Image.Resampling.NEAREST).save(ROOT/'images/achievement_trophies.png')
    from generate_selector_assets import glyphs
    from PIL import ImageDraw
    screen = Image.new('RGB',(320,200))
    def rgb(c): return tuple(palette[c*3:c*3+3])
    draw = ImageDraw.Draw(screen)
    for y in (20,180): draw.rectangle((0,y,319,y+1), fill=rgb(0x84))
    font = glyphs()
    for y,c in [(2,0x94),(0,0x98)]:
        text='Achievements 0 / 84'
        x=(320-len(text)*16)//2
        for char in text:
            glyph=font[ord(char)-32]
            for gy in range(16):
                for gx in range(16):
                    if glyph.getpixel((gx,gy)): screen.putpixel((x+gx,y+gy),rgb(c))
            x+=16
    for row in range(7):
        for col in range(12):
            screen.paste(previews[3 if row==6 else 0].convert('RGB'),(16+col*24,26+row*22))
    draw.rectangle((16,26,39,46),outline=rgb(12))
    raw=(ROOT.parent/'flob/assets/flob.fnt').read_bytes()
    from generate_achievements import parse_achievements
    first = parse_achievements()[0]
    description = first['name'].rstrip()+': '+first['desc'].rstrip()
    for text,y,c in [('Escape from the Lab Achievement',184,4),(description[:40],192,12)]:
        x=(320-len(text)*8)//2
        for char in text:
            code=ord(char)-32 if 32<=ord(char)<96 else ord(char)
            for gy,bits in enumerate(raw[code*8:code*8+8]):
                for gx in range(8):
                    if bits&(128>>gx): screen.putpixel((x+gx,y+gy),rgb(c))
            x+=8
    screen.resize((960,600),Image.Resampling.NEAREST).save(ROOT/'images/achievements_ste_preview.png')
    print('Generated six masked trophy sprites')


if __name__=='__main__': main()
