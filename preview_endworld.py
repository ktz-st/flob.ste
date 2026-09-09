#!/usr/bin/env python3
"""Host preview of the STE summary layout; does not modify game artwork."""
import re
from pathlib import Path
from PIL import Image
from generate_selector_assets import glyphs
from create_game_world_icons import WORLD_DIRS
from render_title_dli import numbers

ROOT = Path(__file__).resolve().parent


def main():
    rgb = bytes.fromhex((ROOT/'assets/a8_pal_rgb.hex').read_text())
    font = glyphs()
    output = ROOT/'images/endworld_ste_preview'
    output.mkdir(parents=True,exist_ok=True)
    montage = Image.new('RGB',(1280,200))
    for column,(world,won) in enumerate([(0,True),(1,True),(5,True),(0,False)]):
        asm=(ROOT.parent/'flob/worlds'/WORLD_DIRS[world]/f'world_{world:02d}.asm').read_text()
        goal=numbers(re.search(r'dta ([^;]+); goal colors',asm)[1])
        name = ('bigmap' if world==0 else 'bigformula' if world==5 else 'bigvial') if won else 'skull'
        source=Image.open(ROOT.parent/'flob/assets'/f'{name}.gif')
        packed=(ROOT.parent/'flob/assets'/f'{name}.gfx').read_bytes()
        for i,c in enumerate(source.getdata()):
            assert ((packed[i//4]>>(6-2*(i%4)))&3)==[0,3,1,2][c]
        c0,c1,c2 = (0x82,*goal) if won else (0x38,0x3f,0x34)
        if won and world==0: c1,c2=0xba,0x26
        colors=[0,c2,c0,c1,0x18 if won else 0x98,0x14 if won else 0x94,goal[1],0x9a,0x94]
        palette=sum((list(rgb[c*3:c*3+3]) for c in colors),[])
        screen=Image.new('P',(320,200))
        screen.putpalette(palette+[0]*(768-len(palette)))
        icon=Image.open(ROOT/'game_endworld_icons'/f'{name}.png')
        assert icon.mode=='P' and icon.size==(64,80) and max(icon.getdata())<=3
        screen.paste(icon,(128,32))
        def text(s,y,c):
            assert len(s)<=20 and y+16<=200
            x=(320-len(s)*16)//2
            for char in s:
                glyph=font[ord(char)-32]
                for gy in range(16):
                    for gx in range(16):
                        if glyph.getpixel((gx,gy)): screen.putpixel((x+gx,y+gy),c)
                x+=16
        for s,y,fg,shadow in [('Congratulations!' if won else 'Game Over',8,4,5),
                              ('Score 1234',150,7,8),('Slimes 42 of 109',170,7,8)]:
            text(s,y+2,shadow)
            text(s,y,fg)
        text('Game Time 02:34',128,6)
        screen.save(output/f'{name}.png')
        montage.paste(screen.convert('RGB'),(column*320,0))
    montage.save(output/'comparison.png')
    print('Four summary variants: palette index mappings and layout bounds OK')


if __name__=='__main__': main()
