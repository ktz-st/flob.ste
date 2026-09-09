"""Approved A8 frame-colour bindings, not inferred RGB palette matches."""
import json
import shutil
from datetime import datetime
from pathlib import Path

from PIL import Image
from build_full_sprite_atlas import load_constants, parse_byte_file
from create_game_sprite_sheet import make_guide

ROOT = Path(__file__).resolve().parent
ATLAS = ROOT / 'images/sprite_atlas'

# Atlas row, original PMG colour, room palette index, approved source frames.
# See reports/sprite_room_colors.md. Room-dependent sprite_drop is excluded.
BINDINGS = (
    ('sprite_cagedoor_p0', 0xE6, 2, tuple(range(11))),
    ('sprite_bench_portal_p0', 0x86, 2, (0,)),
    ('sprite_drop_eyes_p1', 0x12, 3, (1, 2)),
    ('sprite_valve_thunder_p1', 0x72, 3, (5,)),
    ('sprite_bubbles_p1', 0xCD, 1, tuple(range(8))),
    ('sprite_stone_drops_p0', 0xDC, 1, (0,)),
    ('sprite_eyes_tail_p0', 0x00, 3, (1, 2)),
    ('sprite_eyes_tail_p1', 0x00, 3, (0, 1, 2, 3)),
    ('sprite_hole1_p0', 0x02, 3, (1, 3)),
    ('sprite_craneconsole_p1', 0xB2, 3, (1, 2)),
    ('sprite_exit_eyes_w03_p1', 0x00, 3, (1, 2)),
    ('sprite_hole_p0', 0xE4, 2, (0,)),
    ('sprite_fire_console_p0', 0x16, 2, (2,)),
    ('sprite_button_eyes_p1', 0xCA, 1, (1,)),
    ('sprite_eyes_eyes_p0', 0x02, 3, (1, 2)),
    ('sprite_key_lamp_p1', 0xCE, 1, (1,)),
)


def apply_bindings(sheet, meta):
    """Change only opaque source-mask pixels; preserve palette and geometry."""
    assert sheet.mode == 'P'
    constants = load_constants()
    rows = {r['name']: r for r in meta['rows']}
    applied = []
    for name, color, slot, frames in BINDINGS:
        row = rows[name]
        assert row['merge_mode'] == 'direct'
        plane = int(name[-1])
        raw = parse_byte_file(ROOT.parent / row['source_json'], constants)
        counts, heights = raw[:2], raw[2:4]
        color_offset = 4 + (counts[0] if plane else 0)
        data_offset = 4 + sum(counts) + (counts[0] * heights[0] if plane else 0)
        pixels = 0
        for frame in frames:
            assert frame < counts[plane] and frame < row['frame_count']
            assert raw[color_offset + frame] == color, (name, frame)
            for y in range(min(row['frame_h'], heights[plane] * 2)):
                mask = raw[data_offset + frame * heights[plane] + y // 2]
                for x in range(min(row['frame_w'], 16)):
                    pos = (row['x'] + frame * row['slot_w'] + x, row['y'] + y)
                    if mask & (128 >> (x // 2)) and sheet.getpixel(pos) != 0:
                        sheet.putpixel(pos, slot)
                        pixels += 1
        assert pixels, name
        applied.append(dict(row=name, a8_color=f'{color:02X}',
                            palette_index=slot, frames=list(frames), pixels=pixels))
    meta['room_color_bindings'] = applied
    return applied


def main():
    sheet = Image.open(ATLAS / 'game_sprites.png')
    meta = json.loads((ATLAS / 'game_sprites.json').read_text())
    palette = sheet.getpalette()
    before = bytes(sheet.getdata())
    applied = apply_bindings(sheet, meta)
    after = bytes(sheet.getdata())
    assert palette == sheet.getpalette()
    assert all((a == 0) == (b == 0) for a, b in zip(before, after))
    assert all(a == b or b in (1, 2, 3) for a, b in zip(before, after))
    backup = ATLAS / 'backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    for name in ('game_sprites.png', 'game_sprites.json', 'game_sprites_guide.png'):
        shutil.copy2(ATLAS / name, backup / name)
    sheet.save(ATLAS / 'game_sprites.png', transparency=0)
    (ATLAS / 'game_sprites.json').write_text(json.dumps(meta, indent=2) + '\n')
    make_guide(sheet, meta['rows'], meta['frames'], ATLAS / 'game_sprites_guide.png')
    print('Backup:', backup)
    print('Bindings:', len(applied), 'changed pixels:', sum(a != b for a, b in zip(before, after)))


if __name__ == '__main__':
    main()
