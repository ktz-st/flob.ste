#!/usr/bin/env python3
"""Convert A8 stats header to a Scale2x 320x42 STE planar bitmap."""
from pathlib import Path
from PIL import Image
from generate_selector_assets import scale2x
from generate_world_icons import word_array

ROOT = Path(__file__).resolve().parent


def main():
    raw = (ROOT.parent / 'flob/assets/stats_header.gfx').read_bytes()
    assert len(raw) == 40 * 21
    src = Image.new('P', (160,21))
    src.putdata([(raw[y*40+x//4] >> (6-2*(x%4))) & 3
                 for y in range(21) for x in range(160)])
    im = scale2x(src)
    words = []
    for y in range(42):
        for bx in range(0,320,16):
            for plane in range(4):
                words.append(sum(((im.getpixel((bx+x,y))>>plane)&1)<<(15-x)
                                 for x in range(16)))
    (ROOT/'assets/stats_header.inc').write_text(word_array('STATS_HEADER_WORDS', words))
    rgb=bytes.fromhex((ROOT/'assets/a8_pal_rgb.hex').read_text())
    palette=sum((list(rgb[c*3:c*3+3]) for c in (0,0x38,0x3c,0x34)),[])
    im.putpalette(palette+[0]*(768-len(palette)))
    im.save(ROOT/'images/stats_header_ste.png')
    # Verify the generated planes, not just the preview image.
    for y in range(42):
        for x in range(320):
            off=y*80+(x//16)*4
            pixel=sum(((words[off+p]>>(15-x%16))&1)<<p for p in range(4))
            assert pixel==im.getpixel((x,y))
    print('Stats header: 320x42 Scale2x; planar roundtrip OK')


if __name__=='__main__': main()
