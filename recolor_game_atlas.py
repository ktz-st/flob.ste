#!/usr/bin/env python3
"""Explicit A8 colour reimport with backup, unchanged layout and reserved slots."""
import json
import shutil
import argparse
from datetime import datetime
from pathlib import Path
from collections import Counter
from PIL import Image
from build_full_sprite_atlas import load_constants, parse_byte_file
from sprite_combined_config import MERGED_COMPOUND_ATLAS_GAPS
from create_game_sprite_sheet import make_guide
from sprite_palette_roles import apply_roles

ROOT=Path(__file__).resolve().parent
DIR=ROOT/'images/sprite_atlas'


def snap(rgb):
    return tuple(((c*15+127)//255)*17 for c in rgb)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source-dir',type=Path,default=DIR)
    args=parser.parse_args()
    backup=DIR/'backups'/datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    for name in ['game_sprites.png','game_sprites.json','game_sprites_guide.png']:
        shutil.copy2(DIR/name,backup/name)
    shutil.copy2(ROOT/'generated/sprite_atlas_palette.inc',backup/'sprite_atlas_palette.inc')
    meta=json.loads((args.source_dir/'game_sprites.json').read_text())
    old=Image.open(args.source_dir/'game_sprites.png')
    oldpal=old.getpalette()
    assert old.mode=='P'
    rgba=Image.new('RGBA',old.size)
    pal=bytes.fromhex((ROOT/'assets/a8_pal_rgb.hex').read_text())
    def rgb(c): return tuple(pal[c*3:c*3+3])
    constants=load_constants()
    restored=[]
    for row in meta['rows']:
        name=row['name']
        if row['source_json'].endswith('.a65'):
            raw=parse_byte_file(ROOT.parent/row['source_json'],constants)
            counts,heights=raw[:2],raw[2:4]
            off=4; colors=[]; planes=[]
            for count in counts:
                colors.append(raw[off:off+count]);off+=count
            for p in range(2):
                frames=[]
                for f in range(counts[p]):
                    frames.append(raw[off:off+heights[p]]);off+=heights[p]
                planes.append(frames)
            assert off==len(raw)
            mode=row['merge_mode']
            gap=MERGED_COMPOUND_ATLAS_GAPS[name.removesuffix('_compound')]*2 if mode=='compound' else 0
            for f in range(row['frame_count']):
                for y in range(row['frame_h']):
                    for x in range(row['frame_w']):
                        hits=[]
                        for p in range(2):
                            if mode=='direct' and not name.endswith(f'_p{p}'):continue
                            sx=x-(gap if p else 0)
                            if 0<=sx<16 and f<counts[p] and y//2<heights[p] and planes[p][f][y//2]&(128>>(sx//2)):
                                hits.append(colors[p][f])
                        if hits:
                            c=hits[0]
                            for v in hits[1:]:c|=v
                            rgba.putpixel((row['x']+f*row['slot_w']+x,row['y']+y),(*rgb(c),255))
            restored.append(name)
        elif name=='slime':
            # Two 2-clock missiles, staggered horizontally, overlap in the
            # middle row. VBL exchanges their horizontal offsets every 16 ticks.
            for f in range(row['frame_count']):
                for y in range(6):
                    for x in range(6):
                        a=(y//2>=1 and f<=x//2<f+2)
                        b=(y//2<=1 and 1-f<=x//2<3-f)
                        if a or b:
                            c=(0x34 if a else 0)|(0x38 if b else 0)
                            rgba.putpixel((row['x']+f*row['slot_w']+5+x,row['y']+5+y),(*rgb(c),255))
            restored.append(name)
        elif name=='flob':
            # Preserve the artist-edited/smoothed Flob geometry and eyes.
            for f in range(row['frame_count']):
                for y in range(row['frame_h']):
                    for x in range(row['frame_w']):
                        pos=(row['x']+f*row['slot_w']+x,row['y']+y)
                        c=old.getpixel(pos)
                        if c:
                            value=tuple(oldpal[c*3:c*3+3])
                            rgba.putpixel(pos,(*value,255))
        else: raise ValueError('Unrecognised source: '+name)
    # Protect the reported colours from collapsing during global reduction.
    pinned=[snap(rgb(c)) for c in (0x34,0x38,0x3c,0x24,0x28,0x2c)]+[(255,255,255),(0,0,0)]
    histogram=Counter(snap(pixel[:3]) for pixel in rgba.getdata() if pixel[3])
    remaining=[c for c in histogram if c not in pinned]
    sample=Image.new('RGB',(sum(histogram[c] for c in remaining),1))
    sample.putdata([c for c in remaining for _ in range(histogram[c])])
    quant=sample.quantize(colors=11-len(pinned),method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
    qp=quant.getpalette()
    chosen=pinned+[snap(tuple(qp[i*3:i*3+3])) for i in range(11-len(pinned))]
    flat=oldpal.copy()
    for i,c in enumerate(chosen,4):flat[i*3:i*3+3]=list(c)
    result=Image.new('P',old.size)
    result.putpalette(flat)
    mapping={c:4+min(range(11),key=lambda i:sum((c[k]-chosen[i][k])**2 for k in range(3))) for c in histogram}
    result.putdata([mapping[snap(p[:3])] if p[3] else 0 for p in rgba.getdata()])
    assert result.getpalette()[:12]==oldpal[:12]
    assert result.getpalette()[45:48]==oldpal[45:48]
    assert set(result.getdata())<=set([0]+list(range(4,15)))
    meta['palette_rgb']=[flat[i*3:i*3+3] for i in range(16)]
    meta['sprite_color_count']=11
    meta['quantized_from_unique_colors']=len(histogram)
    meta['colour_reimport']={'backup':str(backup.relative_to(ROOT)),'source_atlas':str(args.source_dir), 'source':'A8 PAL, PMG colour OR',
        'precision':'STE 4 bits/channel','pinned_a8_colors':['34','38','3c','24','28','2c'],
        'preserved_artwork':['flob'],'restored_rows':len(restored),
        'limitation':'11 shared colours; other A8 colours approximated'}
    meta.pop('palette_roles_version', None)
    apply_roles(result, meta)
    result.save(DIR/'game_sprites.png',transparency=0)
    (DIR/'game_sprites.json').write_text(json.dumps(meta,indent=2)+'\n')
    make_guide(result,meta['rows'],meta['frames'],DIR/'game_sprites_guide.png')
    preview=Image.new('RGB',(384,128))
    for i,name in enumerate(['slime','sprite_fireext_merged']):
        row=next(r for r in meta['rows'] if r['name']==name)
        box=(row['x'],row['y'],row['x']+row['w'],row['y']+row['h'])
        tile=result.crop(box).convert('RGB')
        preview.paste(tile.resize((tile.width*4,tile.height*4),Image.Resampling.NEAREST),(0,i*48))
    preview.save(DIR/'recolored_examples.png')
    print('Backup:',backup)
    print('Restored rows:',len(restored),'source STE RGB colours:',len(histogram),'output:',len(set(chosen)))


if __name__=='__main__':main()
