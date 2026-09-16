"""Repair the captured W2 R22 room without replacing code or gameplay state.

This deliberately targets the inspected Hatari 2.6.1 snapshot only. The
embedded PRG remains old, so reloading the room can restore its old assets.
"""
import gzip
import struct
from pathlib import Path

from PIL import Image
from convert_images import image_to_pi1
from create_game_rooms import normalized_collision
from generate_world_data import collision_bytes

ROOT = Path(__file__).resolve().parent


def pack_collision(image):
    p = list(image.getdata())
    return bytes((p[i] << 6) | (p[i+1] << 4) | (p[i+2] << 2) | p[i+3]
                 for i in range(0, len(p), 4))


def main():
    source = ROOT / 'hatari.sav'
    target = ROOT / 'hatari-w2-r22-fixed.sav'
    assert not target.exists(), 'Refusing to overwrite an existing patched save'
    saved = source.read_bytes()
    original = gzip.decompress(saved)
    assert original[:7] == b'2.6.1\0\1'
    ram = 27881
    assert original[ram-21:ram] == bytes.fromhex(
        '00004000 00002000 00002000 00002000 00002000 0a')
    assert original[ram+0x42e:ram+0x432] == bytes.fromhex('00400000')
    assert original[ram+0x44e:ram+0x452] == bytes.fromhex('00189000')

    room = ROOT / 'game_rooms/world_02/room_22.png'
    new = image_to_pi1(room)[3234:28834]
    old_words = list(struct.unpack('>12800H', new))
    for i in range(0, len(old_words), 4):
        p0, p1, _, _ = old_words[i:i+4]
        old_words[i:i+4] = [p1 & ~p0, p0, 0, 0]
    old = struct.pack('>12800H', *old_words)
    background = ram + 0x198c00 + 3200
    assert original[background:background+25600] == old
    assert original.count(old) == 1

    original_gif = ROOT.parent / 'flob/worlds/02_Suburbian_Parkour/images/room_22.gif'
    old_collision = pack_collision(normalized_collision(Image.open(original_gif)))
    assert original.count(old_collision) == 1
    collision = original.index(old_collision)
    assert ram <= collision < ram + 0x400000 - 3200
    output = bytearray(original)
    ranges = []
    for address in (0x189000, 0x190e00, 0x198c00):
        start = ram + address + 3200
        screen = original[start:start+25600]
        words = list(struct.unpack('>12800H', screen))
        reference = struct.unpack('>12800H', old)
        for i in range(0, len(words), 4):
            p0, p1, p2, p3 = words[i:i+4]
            # Only indices 0..3 belong to the room. Preserve all sprites.
            room_mask = ~(p2 | p3) & 0xffff
            assert not ((p0 ^ reference[i]) & room_mask)
            assert not ((p1 ^ reference[i+1]) & room_mask)
            words[i] = (p0 & ~room_mask) | (p1 & room_mask)
            words[i+1] = (p1 & ~room_mask) | ((p0 | p1) & room_mask)
        output[start:start+25600] = struct.pack('>12800H', *words)
        ranges.append((start, start+25600))
    output[collision:collision+3200] = collision_bytes(room.with_name('room_22_collision.png'))
    ranges.append((collision, collision+3200))
    assert output[background:background+25600] == new
    cursor = 0
    for start, end in sorted(ranges):
        assert output[cursor:start] == original[cursor:start]
        cursor = end
    assert output[cursor:] == original[cursor:]
    packed = gzip.compress(bytes(output), mtime=0)
    assert gzip.decompress(packed) == output
    with target.open('xb') as stream:
        stream.write(packed)
    assert source.read_bytes() == saved
    print(f'Created {target}')
    print('Verified: only three playfields and current collision data changed.')
    print('Original snapshot, code, sprites, HUD and gameplay state preserved.')


if __name__ == '__main__':
    main()
