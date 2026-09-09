"""Explicit migration to semantic STE palette slots; normal builds use the PNG."""
import json
import shutil
from datetime import datetime
from pathlib import Path
from PIL import Image
from build_full_sprite_atlas import load_constants, parse_byte_file
from sprite_combined_config import MERGED_COMPOUND_ATLAS_GAPS
from create_game_sprite_sheet import make_guide

ROOT = Path(__file__).resolve().parent
DIR = ROOT / 'images/sprite_atlas'


def apply_roles(sheet, meta):
    if meta.get('palette_roles_version') == 1:
        return
    old = sheet.copy()
    constants = load_constants()
    for row in meta['rows']:
        name = row['name']
        if row['source_json'].endswith('.a65'):
            raw = parse_byte_file(ROOT.parent / row['source_json'], constants)
            counts, heights = raw[:2], raw[2:4]
            offsets = [4 + sum(counts), 4 + sum(counts) + counts[0] * heights[0]]
            gap = MERGED_COMPOUND_ATLAS_GAPS[name.removesuffix('_compound')] * 2 if row['merge_mode'] == 'compound' else 0
        for f in range(row['frame_count']):
            for y in range(row['frame_h']):
                for x in range(row['frame_w']):
                    pos = row['x'] + f * row['slot_w'] + x, row['y'] + y
                    index = old.getpixel(pos)
                    if not index:
                        continue
                    if name in ('flob', 'slime'):
                        # Preserve the smoothed silhouette and white eyes.
                        mapping = {4:4, 5:5, 6:6, 10:14, 11:13, 14:4}
                        if index not in mapping:
                            raise ValueError(f'Unclassified {name} colour {index}')
                        value = mapping[index]
                        if name == 'slime' and value in (4, 5, 6):
                            value += 3
                    elif row['merge_mode'] == 'direct':
                        value = 10 + int(name[-1])
                    else:
                        hits = []
                        for p in range(2):
                            sx = x - (gap if p else 0)
                            if (0 <= sx < 16 and f < counts[p] and y // 2 < heights[p]
                                    and raw[offsets[p] + f * heights[p] + y // 2] & (128 >> (sx // 2))):
                                hits.append(p)
                        if not hits:
                            raise ValueError(f'No source layer for {name} {f} {x},{y}')
                        value = 12 if len(hits) == 2 else 10 + hits[0]
                    sheet.putpixel(pos, value)
    palette = sheet.getpalette()
    a8 = bytes.fromhex((ROOT / 'assets/a8_pal_rgb.hex').read_text())
    for slot, color in ((4,0x34),(5,0x38),(6,0x3c),(7,0x34),(8,0x38),(9,0x3c),
                        (10,0x24),(11,0x28),(12,0x2c)):
        palette[slot*3:slot*3+3] = [((v*15+127)//255)*17 for v in a8[color*3:color*3+3]]
    palette[39:45] = [0,0,0,255,255,255]
    sheet.putpalette(palette)
    meta['palette_rgb'] = [palette[i*3:i*3+3] for i in range(16)]
    meta['palette_roles_version'] = 1
    meta['room_color_bindings'] = []
    meta['palette_roles'] = {'room':[0,1,2,3], 'flob':[4,5,6], 'slime':[7,8,9],
                             'objects':[10,11,12], 'black':13, 'white':14, 'message':15}


def main():
    meta = json.loads((DIR / 'game_sprites.json').read_text())
    sheet = Image.open(DIR / 'game_sprites.png')
    backup = DIR / 'backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    for name in ('game_sprites.png','game_sprites.json','game_sprites_guide.png'):
        shutil.copy2(DIR / name, backup / name)
    apply_roles(sheet, meta)
    sheet.save(DIR / 'game_sprites.png', transparency=0)
    (DIR / 'game_sprites.json').write_text(json.dumps(meta, indent=2)+'\n')
    make_guide(sheet, meta['rows'], meta['frames'], DIR / 'game_sprites_guide.png')
    print('Role atlas written; backup:', backup)


if __name__ == '__main__':
    main()
