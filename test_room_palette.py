"""Regression for W2 R22's missing colour and palette-index preservation."""
import struct
import unittest
from pathlib import Path
from PIL import Image
from create_game_rooms import scale2x
from convert_images import image_to_pi1
from room_palette_config import A8_TO_COLLISION, remap_source

ROOT = Path(__file__).resolve().parent


def original_pixels(world_number=2, room_number=22, directory='02_Suburbian_Parkour'):
    original = ROOT.parent / 'flob'
    cart = (original / 'flob.1.0.3b.car').read_bytes()[16:]
    world = (original / 'worlds' / directory / f'world_{world_number:02d}.bin').read_bytes()
    base = cart.index(world[3:32]) - 3
    assert base % 8192 == 0
    image_bank = base // 8192 + world[50]
    start, size, bank = struct.unpack_from('<HHB', cart, image_bank * 8192 + room_number * 8)
    offset = bank * 8192 + start - 0xA000
    data = cart[offset:offset + size]
    out = bytearray()
    pos = 0

    def length(n):
        nonlocal pos
        if n == 15:
            while True:
                extra = data[pos]
                pos += 1
                n += extra
                if extra != 255:
                    break
        return n

    while pos < len(data) and len(out) < 3200:
        token = data[pos]
        pos += 1
        n = length(token >> 4)
        out.extend(data[pos:pos+n])
        pos += n
        if pos >= len(data):
            break
        distance = int.from_bytes(data[pos:pos+2], 'little')
        pos += 2
        n = length(token & 15) + 4
        for _ in range(n):
            out.append(out[-distance])
    assert len(out) >= 3200
    return [(b >> s) & 3 for b in out[:3200] for s in (6, 4, 2, 0)]


class RoomPaletteTest(unittest.TestCase):
    def test_w3_r12_collision_and_geometry(self):
        pixels = original_pixels(3, 12, '03_Hazardous_Mudlands')
        path = ROOT / 'game_rooms/world_03/room_12.png'
        collision = list(Image.open(path.with_name('room_12_collision.png')).getdata())
        self.assertEqual(collision, [A8_TO_COLLISION[p] for p in pixels])
        # Original PF0 is ground; this room has no lethal PF1 in its base image.
        self.assertNotIn(3, collision)
        self.assertEqual(collision.count(2), 2174)
        with Image.open(ROOT.parent / 'flob/worlds/03_Hazardous_Mudlands/images/room_12.gif') as image:
            source = image.copy()
        expected = list(scale2x(remap_source(source, (3, 12))).getdata())
        self.assertEqual(list(Image.open(path).getdata()), expected)
        words = struct.unpack('>16000H', image_to_pi1(path)[34:])
        for y in range(200):
            for x in range(320):
                off = y * 80 + (x // 16) * 4
                actual = sum(((words[off+p] >> (15-x % 16)) & 1) << p for p in range(4))
                self.assertEqual(actual, expected[(y-20)*320+x] if 20 <= y < 180 else 0)

    def test_collision_matches_cartridge(self):
        collision = Image.open(ROOT / 'game_rooms/world_02/room_22_collision.png')
        self.assertEqual(list(collision.getdata()), [A8_TO_COLLISION[p] for p in original_pixels()])

    def test_smoothing_geometry_preserved(self):
        with Image.open(ROOT.parent / 'flob/worlds/02_Suburbian_Parkour/images/room_22.gif') as image:
            source = image.copy()
        canonical = Image.open(ROOT / 'game_rooms/world_02/room_22.png')
        self.assertEqual(list(canonical.getdata()), list(scale2x(remap_source(source, (2, 22))).getdata()))

    def test_planar_preserves_every_index(self):
        path = ROOT / 'game_rooms/world_02/room_22.png'
        words = struct.unpack('>16000H', image_to_pi1(path)[34:])
        pixels = list(Image.open(path).getdata())
        for y in range(200):
            for x in range(320):
                offset = y * 80 + (x // 16) * 4
                value = sum(((words[offset+p] >> (15-x % 16)) & 1) << p for p in range(4))
                expected = pixels[(y-20)*320+x] if 20 <= y < 180 else 0
                self.assertEqual(value, expected, (x, y))


if __name__ == '__main__':
    unittest.main()
