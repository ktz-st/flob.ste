"""One-time index repair; preserves existing smoothed room geometry."""
from pathlib import Path
from PIL import Image
from create_game_rooms import normalized_collision
from room_palette_config import remap_source, ST_PREVIEW_PALETTE

ROOT = Path(__file__).resolve().parent


def repair(world, number, directory):
    key = (world, number)
    room_path = ROOT / f'game_rooms/world_{world:02d}/room_{number:02d}.png'
    collision_path = room_path.with_name(f'room_{number:02d}_collision.png')
    room = Image.open(room_path)
    source = Image.open(ROOT.parent / 'flob/worlds' / directory / f'images/room_{number:02d}.gif')
    expected_collision = remap_source(source, key, collision=True)
    collision = Image.open(collision_path)
    if room.getpalette()[:12] == ST_PREVIEW_PALETTE[:12]:
        assert list(collision.getdata()) == list(expected_collision.getdata())
        print(f'W{world} R{number:02d} already repaired')
        return
    assert room.getpalette()[:12] == source.getpalette()[:12]
    assert list(collision.getdata()) == list(normalized_collision(source).getdata()), 'Collision artwork changed; review manually'
    remap_source(room, key).save(room_path, optimize=True)
    expected_collision.save(collision_path, optimize=True)
    print(f'Repaired W{world} R{number:02d} image indices and collision selectors; geometry preserved')


def main():
    repair(2, 22, '02_Suburbian_Parkour')
    repair(3, 12, '03_Hazardous_Mudlands')


if __name__ == '__main__':
    main()
