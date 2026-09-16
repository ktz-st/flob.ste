"""Guard W4's binary tile references and the valve/water collision asset."""
import json
import unittest
from pathlib import Path
from PIL import Image
from generate_world_tiles import pack_collision_pixels

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'flob/worlds/04_Silver_Dust_Mines'


class W4TilesTest(unittest.TestCase):
    def test_manifest_matches_binary(self):
        tiles = [t for t in json.loads((ROOT / 'game_tiles/manifest.json').read_text())['tiles'] if t['world'] == 4]
        names = ['door', 'cover', 'krata', 'bridge_up', 'bridge_down', 'cable', 'water']
        binary = (SOURCE / 'world_04_assets.bin').read_bytes()
        self.assertEqual(len(tiles), len(names))
        for tile, name in zip(tiles, names):
            with self.subTest(tile=tile['label']):
                w, h = tile['size']
                signature = bytes((w // 8, h // 2)) + (SOURCE / f'{name}.gfx').read_bytes()
                self.assertEqual(binary.count(signature), 1)
                self.assertEqual(tile['source_addr'], 0xa000 + binary.index(signature))

    def test_room_water_reference_and_lethal_pixels(self):
        world = (SOURCE / 'world_04.bin').read_bytes()
        # PUT_TILE, ON_NO_GOAL, goal 6, x 27, y 11, address $A693.
        self.assertIn(bytes.fromhex('13 02 06 1b 0b 93 a6'), world)
        with Image.open(ROOT / 'game_tiles/world_04/06_tile_water.png') as image:
            packed = pack_collision_pixels(list(image.getdata()), *image.size)
        pixels = [(b >> s) & 3 for b in packed for s in (6, 4, 2, 0)]
        self.assertEqual(set(pixels), {0, 3})
        self.assertGreater(pixels.count(3), 80)


if __name__ == '__main__':
    unittest.main()
