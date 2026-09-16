#!/usr/bin/env python3
"""Explicit A8 credits import; normal builds preserve canonical PNG artwork."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw
from create_game_tiles import scale2x
from render_title_dli import array

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'game_credits'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--force', action='store_true')
    args = parser.parse_args()
    original = ROOT.parent / 'flob'
    colors = array((original / 'flob.pas').read_text(), 'credColors')
    assert len(colors) == 24
    rgb = bytes.fromhex((ROOT / 'assets/a8_pal_rgb.hex').read_text())
    OUT.mkdir(exist_ok=True)
    entries = []
    preview = Image.new('RGB', (640, 4 * 224), '#181818')
    draw = ImageDraw.Draw(preview)
    for slide in range(7):
        raw_path = original / 'assets/credits' / f'credits_slides_{slide + 1:02d}.gfx'
        raw = raw_path.read_bytes()
        assert len(raw) == 4000
        pixels = [(v >> shift) & 3 for v in raw for shift in (6, 4, 2, 0)]
        palette = []
        # dlicredits: selector 0=COLBK, 1=PF0, 2=PF1, 3=PF2.
        indices = [0] + colors[slide * 3:slide * 3 + 3]
        for index in indices:
            palette.extend(((v * 15 + 127) // 255) * 17 for v in rgb[index * 3:index * 3 + 3])
        palette += [0] * (768 - len(palette))
        path = OUT / f'credits_{slide + 1:02d}.png'
        if args.force or not path.exists():
            image = scale2x(160, 100, pixels)
            image.putpalette(palette)
            image.info.pop('transparency', None)
            image.save(path)
        image = Image.open(path)
        assert image.mode == 'P' and image.size == (320, 200)
        assert max(image.getdata()) < 16
        x, y = (slide % 2) * 320, (slide // 2) * 224
        preview.paste(image.convert('RGB'), (x, y + 24))
        draw.text((x + 8, y + 6), f'Credits {slide + 1:02d}', fill='white')
        entries.append({'image': path.name, 'a8_selectors': indices,
                        'source': str(raw_path.relative_to(original))})
    (OUT / 'manifest.json').write_text(json.dumps({
        'canonical_build_source': True, 'size': [320, 200], 'smoothing': 'Scale2x',
        'source_mode': 'ANTIC D: 160x100, two scanlines per data row',
        'dli': 'dlicredits sets PF0..2 from credColors; COLBK=0. '
               'Settled slide palette; next-slide DLI during scrolling is not baked into a slide.',
        'removed_slide': '08: In Stereo Where Available', 'images': entries,
    }, indent=2) + '\n')
    preview.save(ROOT / 'reports/credits_ste_preview.png')
    print('Seven canonical 320x200 credits PNGs; existing artwork preserved unless --force.')


if __name__ == '__main__':
    main()
