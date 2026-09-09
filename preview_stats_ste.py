#!/usr/bin/env python3
"""Preview current STE stats layout with illustrative fresh-save values."""
import re
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent


def main():
    pas=(ROOT/'flob.pas').read_text()
    font=(ROOT/'font/flob.fnt').read_bytes()
    header=Image.open(ROOT/'images/stats_header_ste.png').convert('RGB')
    out=ROOT/'images/stats_ste_preview'
    out.mkdir(parents=True,exist_ok=True)
    combined=Image.new('RGB',(640,200))
    for page in range(2):
        image=Image.new('RGB',(320,200))
        image.paste(header,(0,0))
        def text(s,x,y):
            # DrawChar selects the left/right byte of a 16-pixel screen word.
            x=(x//8)*8
            for c in s:
                for dy,bits in enumerate(font[ord(c)*8:ord(c)*8+8]):
                    for dx in range(8):
                        if x+dx<320:
                            image.putpixel((x+dx,y+dy),(255,255,255) if bits&(128>>dx) else (0,0,0))
                x+=8
        def centered(s,y): text(s,(320-len(s)*8)//2,y)
        centered('Escape from the Lab' if page==0 else 'Total Game Stats',46)
        centered('<  Page '+('1' if page==0 else '7')+' / 7  >',58)
        section=pas.split('procedure DrawWorldStats;' if page==0 else 'procedure DrawGlobalStats;',1)[1]
        section=section.split('    end;',1)[0]
        for side,row,label,expr in re.findall(r"DrawEntry\((LEFT_X|RIGHT_X),\s*(\d+),\s*'([^']+)',\s*(.*?)\);",section):
            value='--:--' if 'bestTime' in expr else '--' if 'OptionalNumber' in expr else '0:00' if 'TimeText' in expr else '1' if 'gameRuns' in expr else '0'
            x=8 if side=='LEFT_X' else 168
            y=74+int(row)*12
            text(label,x,y)
            text(value,x+72,y)
        draw=ImageDraw.Draw(image)
        for y in (68,184): draw.rectangle((0,y,319,y+1),fill=(70,70,70))
        centered('LEFT/RIGHT   FIRE: BACK',190)
        image.save(out/('world_00.png' if page==0 else 'global.png'))
        combined.paste(image,(page*320,0))
    combined.resize((1280,400),Image.Resampling.NEAREST).save(out/'comparison.png')
    print(out/'comparison.png')


if __name__=='__main__':main()
