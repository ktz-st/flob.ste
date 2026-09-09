#!/usr/bin/env python3
"""Source-derived PAL stats display list and DLI, with illustrative values."""
import json
import re
from pathlib import Path
from PIL import Image
from render_title_dli import numbers

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent/'flob'
OUT = ROOT/'images/stats_dli_reference'


def main():
    header=(SOURCE/'assets/stats_header.gfx').read_bytes()
    labels=(SOURCE/'assets/STATS.ASC').read_bytes()
    font=(SOURCE/'assets/flob.fnt').read_bytes()
    assert len(header)==21*40 and len(labels)==18*40
    palette=bytes.fromhex((ROOT/'assets/a8_pal_rgb.hex').read_text())
    rgb=[tuple(palette[i:i+3]) for i in range(0,768,3)]
    sprites=(SOURCE/'assets/sprites.asm').read_text()
    arrows=[numbers(re.search(r'^'+name+r'\s*\n(.*?)^'+end,sprites,re.M|re.S)[1])
            for name,end in [('larrow','rarrow'),('rarrow','ach_cursor')]]
    OUT.mkdir(parents=True,exist_ok=True)
    montage=Image.new('RGB',(640,224))
    for page in (0,6):
        text=bytearray(40)+bytearray(labels)
        def put(row,col,s):
            for i,c in enumerate(s):
                code=ord(c)
                if 32<=code<96: code-=32
                text[row*40+col+i]=code
        name='Escape from the Lab' if page==0 else 'Total Game Stats'
        put(0,(40-len(name))//2,name)
        # A fresh-state example, not a read of the player's save file.
        values=['0','0','0','0','','0','0','0','0','0','0:00','0','0','0'] if page==0 else [
            '0','0','0','','','','','0','0','0','0:00','0','0','0','0','0','0','1']
        for row,value in enumerate(values,1): put(row,22,value)
        image=Image.new('RGB',(320,224),rgb[0])
        # PAL scanline 8 at output y=0. dlist_stats: 16 blank lines,
        # 21 mode-D rows, blank4+DLI, one mode2 row, blank4, 18 mode2 rows.
        for y in range(42):
            for x in range(320):
                sx=x//2
                c=(header[(y//2)*40+sx//4]>>(6-2*(sx%4)))&3
                image.putpixel((x,24+y-8),rgb[[0,0x38,0x3c,0x34][c]])
        for row in range(19):
            start=70 if row==0 else 82+(row-1)*8
            for gy in range(8):
                scan=start+gy
                # dlistats2: white heading gradient then dim/bright groups.
                if scan<74: color=15
                elif scan<79: color=[13,11,9,7,8][scan-74]
                else: color=8
                if 104<=scan<136: color=12 if page<6 else 2
                if scan>=192: color=2 if page<6 else 12
                for col in range(40):
                    code=text[row*40+col]
                    bits=font[(code&127)*8+gy]
                    if code&128: bits^=255
                    for gx in range(8):
                        if bits&(128>>gx): image.putpixel((col*8+gx,scan-8),rgb[color])
        for index,visible in enumerate((page>0,page<6)):
            if not visible: continue
            for row,bits in enumerate(arrows[index]):
                for bit in range(8):
                    if bits&(128>>bit):
                        for dy in range(2):
                            for dx in range(2):
                                image.putpixel((index*304+bit*2+dx,(10+row)*2-8+dy),rgb[0x94])
        name='world_00' if page==0 else 'global'
        image.save(OUT/f'{name}.png')
        montage.paste(image,(0 if page==0 else 320,0))
    montage.resize((1280,448),Image.Resampling.NEAREST).save(OUT/'comparison.png')
    (OUT/'raster.json').write_text(json.dumps({
        'source':['ShowStats','dlist_stats.asm','dlistats/dlistats2','stats_header.gfx','STATS.ASC','flob.fnt'],
        'region':'PAL', 'output_scanlines':[8,231],
        'bitmap_scanlines':[24,65], 'page_name_scanlines':[70,77],
        'table_scanlines':[82,225], 'palette_bands':[104,136,192],
        'values':'illustrative fresh state; not loaded from a save',
        'verification':'source-derived, exact DLI write timing not verified in an A8 emulator',
    },indent=2)+'\n')
    print(OUT/'comparison.png')


if __name__=='__main__': main()
