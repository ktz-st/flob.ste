"""Host regression checks for the role atlas and original runtime colour data."""
import json
import re
import random
import unittest
from pathlib import Path
from PIL import Image
from build_full_sprite_atlas import load_constants, parse_byte_file
from generate_world_sprite_atlas_map import (
    find_world_sprite_sources, compute_label_addresses, WORLD_DIRS,
)
from sprite_palette_roles import apply_roles
from sprite_room_bindings import apply_bindings

ROOT = Path(__file__).resolve().parent


class PaletteRolesTests(unittest.TestCase):
    def test_ems_endmasks(self):
        for name in ('flob','slime'):
            text=(ROOT/f'generated/sprite_assets_atlas/{name}.inc').read_text()
            def array(suffix):
                body=re.search(r'const SPR_'+name.upper()+'_'+suffix+r'\s*:.*?=\((.*?)\);',text,re.S)[1]
                return [int(v,16) for v in re.findall(r'\$([0-9A-F]{4})',body)]
            words=array('WORDS'); offsets=array('EMS_OFFSETS'); masks=array('EMS_MASKS')
            frames=[tuple(map(int,m)) for m in re.findall(
                r'widthPx:(\d+); heightPx:(\d+); rowWords:(\d+); maskOffset:(\d+); dataOffset:(\d+); paletteOffset:(\d+)',text)]
            for f,(w,h,rw,mo,do,aux) in enumerate(frames):
                self.assertEqual(aux,offsets[f])
                self.assertEqual(rw,1)
                for shift in range(16):
                    for y in range(h):
                        expected=(((~words[mo+y])&0xFFFF)<<16)>>shift
                        off=aux+(shift*h+y)*2
                        self.assertEqual((masks[off]<<16)|masks[off+1],expected)

    def test_slime_crop_preserves_pixels(self):
        directory = ROOT / 'images/sprite_atlas'
        meta = json.loads((directory / 'game_sprites.json').read_text())
        sheet = Image.open(directory / 'game_sprites.png')
        text = (ROOT / 'generated/sprite_assets_atlas/slime.inc').read_text()
        cx = int(re.search(r'CROP_X = (\d+)', text)[1])
        cy = int(re.search(r'CROP_Y = (\d+)', text)[1])
        frames = [tuple(map(int, match)) for match in re.findall(
            r'widthPx:(\d+); heightPx:(\d+); rowWords:(\d+); maskOffset:(\d+); dataOffset:(\d+)', text)]
        words = [int(v, 16) for v in re.findall(r'\$([0-9A-F]{4})', text)]
        sources = sorted((f for f in meta['frames'] if f['sprite']=='slime'), key=lambda f:f['frame'])
        for f, (w,h,rw,mo,do) in zip(sources, frames):
            for y in range(f['h']):
                for x in range(f['w']):
                    color = 0
                    if cx <= x < cx+w and cy <= y < cy+h:
                        sx,sy = x-cx,y-cy
                        bit = 0x8000 >> (sx & 15)
                        block = sy*rw+sx//16
                        color = sum((1 << p) for p in range(4) if words[do+block*4+p]&bit)
                        self.assertEqual(bool(words[mo+block]&bit), color==0)
                    self.assertEqual(color, sheet.getpixel((f['x']+x,f['y']+y)))

    def test_word_collision_matches_pixels(self):
        rng = random.Random(42)
        for _ in range(10000):
            wa,wb = rng.randint(1,16),rng.randint(1,16)
            ax,bx = rng.randint(-20,20),rng.randint(-20,20)
            a,b = rng.getrandbits(16),rng.getrandbits(16)
            left,right = max(ax,bx),min(ax+wa,bx+wb)
            expected = any((a & (0x8000>>(x-ax))) and (b & (0x8000>>(x-bx)))
                           for x in range(left,right))
            actual = False
            if left < right:
                clip = (0xFFFF << (16-(right-left))) & 0xFFFF
                actual = bool((a << (left-ax)) & (b << (left-bx)) & clip)
            self.assertEqual(actual, expected)

    def test_canonical_roles(self):
        directory = ROOT / 'images/sprite_atlas'
        meta = json.loads((directory / 'game_sprites.json').read_text())
        sheet = Image.open(directory / 'game_sprites.png')
        self.assertEqual(meta['palette_roles_version'], 1)
        for row in meta['rows']:
            box = row['x'], row['y'], row['x']+row['w'], row['y']+row['h']
            colors = set(sheet.crop(box).getdata())
            allowed = {0, 10, 11, 12, 13, 14}
            if row['name'] == 'flob':
                allowed = {0, 4, 5, 6, 13, 14}
            elif row['name'] == 'slime':
                allowed = {0, 7, 8, 9, 13, 14}
            self.assertTrue(colors <= allowed, row['name'])
        copy = sheet.copy()
        apply_roles(copy, meta)
        self.assertEqual(copy.tobytes(), sheet.tobytes())
        with self.assertRaises(ValueError):
            apply_bindings(copy, meta)

    def test_runtime_blobs_match_a8(self):
        constants = load_constants()
        for world, label, path in find_world_sprite_sources():
            text = (ROOT / f'worlds/world_{world:02d}_assets.inc').read_text()
            data = bytes(int(v, 16) for v in re.findall(r'\$([0-9a-fA-F]{2})\b', text))
            asm = ROOT.parent / 'flob/worlds' / WORLD_DIRS[world] / f'world_{world:02d}.asm'
            offset = compute_label_addresses(asm)[label] - 0xA000
            raw = bytes(parse_byte_file(path, constants))
            self.assertEqual(data[offset:offset+len(raw)], raw, (world, label))
            n0, n1, h0, h1 = raw[:4]
            self.assertEqual(len(raw), 4+n0+n1+n0*h0+n1*h1)


if __name__ == '__main__':
    unittest.main()
