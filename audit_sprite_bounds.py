"""Measure packed sprite transparency and conservative shared-frame crops."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def main():
    results = []
    for path in sorted((ROOT / 'generated/sprite_assets_atlas').glob('*.inc')):
        text = path.read_text()
        text = text.split('const SPR_' + path.stem.upper() + '_EMS_OFFSETS')[0]
        frames = [tuple(map(int, m)) for m in re.findall(
            r'widthPx:(\d+); heightPx:(\d+); rowWords:(\d+); maskOffset:(\d+); dataOffset:(\d+)', text)]
        words = [int(v, 16) for v in re.findall(r'\$([0-9A-F]{4})', text)]
        # The second half is the generated vertical reflection. Crop the source
        # half as a group; reflected frames need mirrored offset metadata.
        source = frames[:len(frames)//2]
        points = set()
        opaque = 0
        empty = []
        per_frame_bytes = 0
        for index, (w,h,rw,mo,do) in enumerate(source):
            count = 0
            frame_points = []
            for y in range(h):
                for x in range(w):
                    if not words[mo+y*rw+x//16] & (0x8000>>(x&15)):
                        points.add((x,y)); frame_points.append((x,y)); count += 1
            opaque += count
            if not count: empty.append(index)
            else:
                fw = max(x for x,y in frame_points)-min(x for x,y in frame_points)+1
                fh = max(y for x,y in frame_points)-min(y for x,y in frame_points)+1
                per_frame_bytes += ((fw+15)//16)*fh*10*2
        old_bytes = len(words)*2
        if points:
            left,top = min(x for x,y in points),min(y for x,y in points)
            width,height = max(x for x,y in points)-left+1,max(y for x,y in points)-top+1
            new_bytes = ((width+15)//16)*height*10*len(frames)
        else:
            left,top,width,height,new_bytes = 0,0,0,0,0
        results.append(dict(name=path.stem, frames=len(source),
            packed_width=source[0][0], packed_height=source[0][1],
            crop_x=left,crop_y=top,visible_width=width,visible_height=height,
            opaque_pixels=opaque, empty_frames=empty,bytes=old_bytes,
            cropped_bytes=new_bytes,saving_bytes=old_bytes-new_bytes))
        results[-1]['per_frame_cropped_bytes'] = per_frame_bytes
    report = ROOT/'reports/sprite_bounds.json'
    report.write_text(json.dumps(results,indent=2)+'\n')
    old = sum(r['bytes'] for r in results)
    new = sum(r['cropped_bytes'] for r in results)
    per_frame = sum(r['per_frame_cropped_bytes'] for r in results)
    lines = ['# Packed Sprite Bounds', '',
        f'{len(results)} generated sprites: {old} bytes; conservative union crops: {new} bytes; potential saving {old-new} bytes.',
        f'Individual frame crops (including dropping empty frames): {per_frame} bytes, saving {old-per_frame} bytes.',
        '', 'Includes masks, four planes and both orientations. Excludes frame metadata.',
        'No artwork changed. Savings are data/row-transfer estimates, NOT measured FPS.',
        'A common crop preserves animation anchors; flipped frames require mirrored crop offsets.',
        '', '| Sprite | Frames | Packed | Visible Union | Offset | Saving B |',
        '|---|---:|---|---|---|---:|']
    for r in sorted(results,key=lambda r:r['saving_bytes'],reverse=True):
        lines.append(f"| {r['name']} | {r['frames']} | {r['packed_width']}x{r['packed_height']} | {r['visible_width']}x{r['visible_height']} | {r['crop_x']},{r['crop_y']} | {r['saving_bytes']} |")
    lines += ['', '## Individual Frame Crops', '',
        'Requires per-frame anchor offsets in rendering AND collision, including flip handling.',
        'A smaller width still occupies whole 16-pixel planar words; data savings may be zero',
        'while destination spans/background restore rectangles become smaller.',
        f"There are {sum(len(r['empty_frames']) for r in results)} empty source frames.",
        '', '| Sprite | Potential saving B | Empty frames |', '|---|---:|---|']
    for r in sorted(results,key=lambda r:r['bytes']-r['per_frame_cropped_bytes'],reverse=True):
        saving=r['bytes']-r['per_frame_cropped_bytes']
        if saving:
            lines.append(f"| {r['name']} | {saving} | {r['empty_frames']} |")
    report.with_suffix('.md').write_text('\n'.join(lines)+'\n')
    print('\n'.join(lines[:28]))


if __name__=='__main__':
    main()
