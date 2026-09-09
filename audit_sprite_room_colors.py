#!/usr/bin/env python3
"""Static audit of visible PMG frame colours versus all room usage palettes."""
import json
import re
import hashlib
from pathlib import Path
from collections import defaultdict
from build_full_sprite_atlas import find_world_sprite_sources, load_constants, parse_byte_file, WORLD_DIRS

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/'flob/worlds'


def main():
    constants=load_constants()
    sources={(w,label):path for w,label,path in find_world_sprite_sources()}
    usages=[]
    for world,directory in enumerate(WORLD_DIRS):
        path=SOURCE/directory/f'world_{world:02d}.asm'
        text='\n'.join(l.split(';',1)[0] for l in path.read_text().splitlines())
        for match in re.finditer(r'^room_(\d+)\s*\n(.*?)(?=^room_\d+\s*$|\Z)',text,re.M|re.S):
            room=int(match[1]); body=match[2].split('dta LEVEL_END')[0]
            first=re.search(r'\bdta\s+([^\n]+)',body)[1]
            def value(t):
                t=t.strip()
                return int(t[1:],16) if t.startswith('$') else int(t)
            palette=[value(t) for t in first.split(',')]
            assert len(palette)==4,(world,room,palette)
            alternatives=[]
            for command in re.findall(r'\bdta\s+SET_COLORS,([^\n]+)',body):
                alternatives.append([value(t) for t in command.split(',')[2:6]])
            for label in re.findall(r'\bdta\s+PUT_SPRITES,\s*a\((sprite_\w+)\)',body):
                state=re.search(r'PUT_SPRITES,\s*a\('+re.escape(label)+r'\)\s*\n\s*dta\s+(SPRITE_\w+)',body)
                if not state: raise ValueError((world,room,label,'missing sprite state'))
                active_planes=1 if state[1]=='SPRITE_SINGLE' else 0 if state[1]=='SPRITE_NONE' else 2
                source=sources[(world,label)]
                raw=parse_byte_file(source,constants)
                counts,heights=raw[:2],raw[2:4]
                pos=4; colors=[]
                for count in counts:colors.append(raw[pos:pos+count]);pos+=count
                for p in range(2):
                    by_color=defaultdict(list)
                    for f in range(counts[p]):
                        bits=raw[pos:pos+heights[p]];pos+=heights[p]
                        if p<active_planes and any(bits):by_color[colors[p][f]].append(f)
                    for c,frames in by_color.items():
                        # The STE room mapper is [A8 bg, A8 PF1, A8 PF0, A8 PF2].
                        def slots(pal):return [i for i,v in enumerate([pal[3],pal[1],pal[0],pal[2]]) if v==c]
                        usages.append(dict(world=world,room=room,label=label,plane=p,color=c,
                            frames=frames,room_colors=palette,ste_slots=slots(palette),
                            conditional_slots=[slots(a) for a in alternatives],
                            source=str(source.relative_to(ROOT.parent)),
                            key=hashlib.sha256(bytes(raw)).hexdigest()+f':{p}:{c}'))
    grouped=defaultdict(list)
    for u in usages:grouped[u['key']].append(u)
    candidates=[]
    for group in grouped.values():
        if not any(u['ste_slots'] or any(u['conditional_slots']) for u in group):continue
        common={1,2,3}
        for u in group:
            common &= set(u['ste_slots'])
            for slots in u['conditional_slots']:common &= set(slots)
        for u in group:
            u['classification']='stable source-colour binding' if common else 'room/state dependent'
            u['common_slots']=sorted(common)
            candidates.append(u)
    candidates.sort(key=lambda u:(u['world'],u['room'],u['label'],u['plane'],u['color']))
    out=ROOT/'reports'
    out.mkdir(exist_ok=True)
    (out/'sprite_room_colors.json').write_text(json.dumps(candidates,indent=2)+'\n')
    lines=['# Sprite / Room Colour Audit','',
        'Exact A8 register-value matches only, not visual similarity. No atlas changes.',
        'All nonempty source frames are considered; animation reachability is not simulated.',
        'Stable means a source-plane-colour can use the same nonzero STE room slot in every known usage/state.',
        'This does not establish artistic intent. PMG overlap colours and priority effects require a separate pixel-level audit.',
        'Index 0 is reported but is not a safe sprite binding with the current transparency convention.','',
        '| World/room | Sprite | Plane | A8 | Frames | STE slots | Conditional slots | Classification |',
        '|---|---|---|---|---|---|---|---|']
    for u in candidates:
        lines.append(f"| W{u['world']} R{u['room']:02} | {u['label']} | P{u['plane']} | ${u['color']:02X} | {','.join(map(str,u['frames']))} | {u['ste_slots']} | {u['conditional_slots']} | {u['classification']} |")
    (out/'sprite_room_colors.md').write_text('\n'.join(lines)+'\n')
    print('Usage/frame-colour records:',len(usages),'candidate records:',len(candidates))
    for key,group in grouped.items():
        if group[0].get('common_slots'):
            print('STABLE',group[0]['label'], 'P'+str(group[0]['plane']),hex(group[0]['color']),group[0]['common_slots'],[(u['world'],u['room']) for u in group])
    print('Other nonzero matches:')
    for u in candidates:
        if not u['common_slots'] and any(i for i in u['ste_slots']):
            print(u['world'],u['room'],u['label'],u['plane'],hex(u['color']),u['ste_slots'],u['conditional_slots'])


if __name__=='__main__':main()
