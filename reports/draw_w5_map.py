"""Draw a room/teleport diagram from the original W5 source connections."""
import re
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT.parent / 'flob/worlds/05_Return_To_The_Lab/world_05.asm').read_text()
blocks = {int(n): b for n, b in re.findall(
    r'^room_(\d+)\s*\n(.*?)(?=^room_\d+|^\s*org \$A000,)', source, re.M | re.S)}
assert len(blocks) == 23
neighbors = {}
teleports = set()
for n, block in blocks.items():
    lines = [line.split(';')[0].strip() for line in block.splitlines()]
    data = [line[4:] for line in lines if line.startswith('dta ')]
    neighbors[n] = [None if v.strip() == 'ROOM_NONE' else int(v) for v in data[1].split(',')]
    for line in lines:
        if 'TELEPORT_ME' in line:
            fields = [v.strip() for v in line[4:].split(',')]
            teleports.add((n, int(fields[7])))
positions = {4: (4, 0)}
queue = deque([4])
deltas = [(0, -1), (1, 0), (0, 1), (-1, 0)]
while queue:
    a = queue.popleft()
    for b, (dx, dy) in zip(neighbors[a], deltas):
        if b is None:
            continue
        proposed = (positions[a][0]+dx, positions[a][1]+dy)
        if b in positions:
            assert positions[b] == proposed
        else:
            positions[b] = proposed
            queue.append(b)
positions.update({0: (0, 0), 6: (0, 1), 5: (5, 0), 17: (5, 2), 22: (4, 3)})
assert set(positions) == set(blocks)
assert len(set(positions.values())) == 23
pairs = sorted({tuple(sorted(p)) for p in teleports})
assert all((b, a) in teleports for a, b in teleports)
tags = {n: [] for n in blocks}
for i, (a, b) in enumerate(pairs, 1):
    tags[a].append(f'T{i}')
    tags[b].append(f'T{i}')

font_path = '/System/Library/Fonts/Menlo.ttc'
font = lambda size: ImageFont.truetype(font_path, size)
canvas = Image.new('RGB', (1490, 950), '#10191c')
draw = ImageDraw.Draw(canvas)
draw.text((38, 24), 'W5 / RETURN TO THE LAB', font=font(30), fill='#eef5ed')
draw.text((38, 70), '23 pokoje | miniatury bez sprajtow i dynamicznych kafli | orientacja podstawowa',
          font=font(16), fill='#acbeba')
boxes = {}
for n, (col, row) in positions.items():
    x, y = 35+(col+1)*204, 122+row*160
    boxes[n] = (x, y, x+176, y+132)
for a, links in neighbors.items():
    for b in links:
        if b is None or a > b:
            continue
        x1, y1, x2, y2 = boxes[a]
        u1, v1, u2, v2 = boxes[b]
        draw.line(((x1+x2)//2, (y1+y2)//2, (u1+u2)//2, (v1+v2)//2),
                  fill='#70978b', width=4)
special = {4: 'START / WYJSCIE', 14: 'KLUCZ DO BIURKA', 18: 'RECEPTURA', 0: 'SEKRET 1', 22: 'SEKRET 2'}
for n, box in boxes.items():
    x, y, x2, y2 = box
    color = '#f0c476' if n in special else '#70978b'
    draw.rounded_rectangle(box, radius=8, fill='#1c2b2f', outline=color, width=2)
    draw.text((x+8, y+6), f'R{n:02d}', font=font(18), fill=color)
    tag = ' '.join(tags[n])
    if tag:
        draw.text((x2-8-draw.textlength(tag, font=font(13)), y+9), tag, font=font(13), fill='#80d6e0')
    with Image.open(ROOT / f'game_rooms/world_05/room_{n:02d}.png') as room:
        thumbnail = room.convert('RGB').resize((160, 80), Image.Resampling.NEAREST)
    canvas.paste(thumbnail, (x+8, y+33))
    if n in special:
        draw.text((x+8, y+115), special[n], font=font(11), fill=color)
draw.line((38, 786, 1450, 786), fill='#3b5455', width=1)
draw.text((38, 809), 'TELEPORTY (w obie strony)', font=font(18), fill='#80d6e0')
for i, (a, b) in enumerate(pairs, 1):
    draw.text((38+(i-1)*278, 844), f'T{i}: R{a:02d} <-> R{b:02d}', font=font(17), fill='#d7e7e3')
draw.text((38, 890), 'Linie = sasiedztwo pokojow. Przejscia moga wymagac przelacznikow lub flipa.',
          font=font(16), fill='#acbeba')
path = ROOT / 'reports/world_05_map.png'
canvas.save(path)
print(path)
print('Teleport pairs:', pairs)
