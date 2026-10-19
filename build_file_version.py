"""Build a separate file-backed Flob without changing embedded assets.

Only literal byte/word/longword resource arrays are extracted. Relocatable
pointer tables and gameplay/frame descriptors remain compiled Pascal metadata.
Resources use group-owned allocations and scene/world lifetime hooks.
"""
import argparse
import collections
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import zlib
from dynamic_file_resources import generate_dynamic_resources
from file_bundle import HEADER_BYTES, HEADER, encode

ROOT = Path(__file__).resolve().parent
DEFAULT_OUTPUT = ROOT.parent / 'flob-files'
INCLUDE = re.compile(r'\{\$i\s+([^}]+\.inc)\}', re.I)
ARRAY = re.compile(
    r'(?P<name>\w+)\s*:\s*(?P<type>array\s*\[[^]]+\]\s*of\s*'
    r'(?P<element>byte|word|longword))\s*=\s*\((?P<data>.*?)\)\s*;', re.I | re.S)
CORE_SPRITES = frozenset(('SPR_FLOB', 'SPR_SLIME', 'SPR_FLOB_EXPLODE_P0',
                         'SPR_FLOB_EXPLODE_P1', 'SPR_FLOB_PARTICLE_P0',
                         'SPR_FLOB_PARTICLE_P1'))


def sprite_world_usage(text):
    """Read the same generated dispatch table used by the game, not filenames."""
    usage = collections.defaultdict(set)
    worlds = set()
    world = None
    for line in text.splitlines():
        match = re.fullmatch(r'\s*(\d+): case addr of\s*', line)
        if match:
            world = int(match[1])
            if world not in range(6):
                raise ValueError(f'Unexpected world {world}')
            worlds.add(world)
        for name in re.findall(r'spriteAtlasWords\[\d+\]\s*:=\s*@([A-Z0-9_]+)_WORDS\[0\]', line):
            if world is None:
                raise ValueError('Sprite mapping outside a world')
            usage[name].add(world)
    if worlds != set(range(6)):
        raise ValueError('Incomplete world sprite dispatch table')
    return usage


def sprite_groups(name, usage):
    base = re.sub(r'_(WORDS|EMS_OFFSETS|EMS_MASKS)$', '', name)
    if base in CORE_SPRITES:
        return ['COMMON/SPRITES.BIN'], []
    if base not in usage:
        raise ValueError(f'Unmapped sprite resource {name}')
    worlds = sorted(usage[base])
    return [f'WORLD{world}/SPRITES.BIN' for world in worlds], worlds


def group_for(path, name):
    if re.fullmatch(r'WORLD_\d\d_DATA_APL', name):
        return 'COMMON/WORLDINF.BIN'
    if name.startswith('MUSIC_'):
        world = re.search(r'WORLD_(\d\d)', name)
        if world:
            return f'WORLD{int(world[1])}/MSX.BIN'
        return {'THEME': 'TITLE', 'INTRO': 'INTRO', 'OUTRO': 'OUTRO',
                'ENDGAME': 'ENDING'}[name.split('_')[1]] + '/MSX.BIN'
    world = re.search(r'(?:world_|^W)(\d\d)', path.name if 'world_' in path.name else name, re.I)
    if world:
        kind = 'GFX' if path.parts[0] == 'images' or 'tile' in path.name else 'MAPS'
        return f'WORLD{int(world[1])}/{kind}.BIN'
    if name.startswith('SFX_'):
        return 'COMMON/SFX.BIN'
    if name.startswith('IMG_'):
        category = name.split('_')[1]
        return {'TITLE': 'TITLE', 'INTRO': 'INTRO', 'OUTRO': 'OUTRO',
                'CREDITS': 'CREDITS'}.get(category, 'COMMON') + '/GFX.BIN'
    if path.parts[0] == 'generated' and 'sprite_assets_atlas' in str(path):
        return 'COMMON/SPRITES.BIN'
    return 'COMMON/UI.BIN'


def literal_bytes(match):
    data = re.sub(r'\{.*?\}|//[^\n]*|\(\*.*?\*\)', '', match['data'], flags=re.S)
    data = data.replace('(', '').replace(')', '')
    values = []
    for token in data.split(','):
        token = token.strip()
        if not re.fullmatch(r'\$[0-9a-fA-F]+|\d+', token):
            raise ValueError(f"Non-literal resource {match['name']}: {token!r}")
        values.append(int(token[1:], 16) if token.startswith('$') else int(token))
    code = {'byte': 'B', 'word': 'H', 'longword': 'I'}[match['element'].lower()]
    return struct.pack('>' + code * len(values), *values)


def prepare(output):
    source, disk = output / 'src', output / 'disk'
    source.mkdir(parents=True, exist_ok=True)
    disk.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / 'FILE_VERSION.md', output / 'README.md')
    groups = collections.defaultdict(list)
    visited = set()
    assets = []
    sprite_usage = sprite_world_usage((ROOT / 'generated/world_sprite_atlas_map.inc').read_text())

    def visit(relative):
        if relative in visited:
            return
        visited.add(relative)
        text = (ROOT / relative).read_text()
        for include in INCLUDE.findall(text):
            visit(Path(include.strip()))
        is_resource = relative.parts[0] in ('assets', 'images', 'worlds', 'generated') or relative.name == 'palette.inc'
        if is_resource:
            # This distribution is PSG-only. Do not export the dormant DMA data.
            text = re.sub(r'\{\$ifdef DMA_SFX\}.*?\{\$endif\}', '', text, flags=re.S)

            def extract(match):
                payload = literal_bytes(match)
                name = match['name']
                entry = dict(symbol=name, source=str(relative), size=len(payload),
                             sha256=hashlib.sha256(payload).hexdigest(),
                             crc32=zlib.crc32(payload), payload=payload,
                             destination=f'@{name}', expression=f'SizeOf({name})')
                group = group_for(relative, name)
                if group == 'COMMON/SPRITES.BIN':
                    destinations, worlds = sprite_groups(name, sprite_usage)
                    entry['worlds'] = worlds
                    entry['resident_core'] = not worlds
                    for destination in destinations:
                        # Each bundle has its own offset even for shared payloads.
                        groups[destination].append(entry.copy())
                else:
                    groups[group].append(entry)
                assets.append(entry)
                return f"var {name}: {match['type']};\nconst\n"

            text = ARRAY.sub(extract, text)
            # Declarations were in const sections; remove only empty sections.
            text = re.sub(r'\bconst\s*(?=var\b|const\b|\Z)', '', text, flags=re.I)
        target = source / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    visit(Path('flob.pas'))
    exported_symbols = {entry['symbol'] for entry in assets}
    missing = {name + '_WORDS' for name in sprite_usage} - exported_symbols
    if missing:
        raise ValueError(f'Mapped sprites missing from exports: {sorted(missing)}')
    shutil.copytree(ROOT / 'asm', source / 'asm', dirs_exist_ok=True)
    shutil.copy2(ROOT / 'unapl.s', source / 'unapl.s')
    font = (ROOT / 'font/flob.fnt').read_bytes()
    font_source = (source / 'asm/font.s').read_text()
    font_source = font_source.replace('section data', 'section bss')
    font_source = font_source.replace('incbin\t"font/flob.fnt"', f'ds.b\t{len(font)}')
    assert 'incbin' not in font_source.lower()
    (source / 'asm/font.s').write_text(font_source)
    entry = dict(symbol='FlobFont', source='font/flob.fnt', size=len(font),
                 sha256=hashlib.sha256(font).hexdigest(), crc32=zlib.crc32(font),
                 payload=font, destination='@FlobFont', expression=str(len(font)))
    groups['COMMON/FONT.BIN'].append(entry)
    assets.append(entry)

    manifest = dict(version=2, stage='dynamic-group-storage', groups=[])
    bundles = {}
    for filename, entries in sorted(groups.items()):
        payload = bytearray()
        for entry in entries:
            entry['offset'] = HEADER_BYTES + len(payload)
            payload.extend(entry['payload'])
            if len(payload) & 1:
                payload.append(0)
        crc = zlib.crc32(payload)
        bundle = encode(payload, len(entries))
        stored_size, stored_crc = HEADER.unpack_from(bundle)[-2:]
        bundles[filename] = dict(bytes=len(bundle), unpacked_bytes=len(payload),
            stored_bytes=stored_size, stored_crc32=stored_crc,
            compression='apultra' if stored_size < len(payload) else 'raw')
        target = disk / filename
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(bundle)
        manifest['groups'].append(dict(path=filename, **bundles[filename],
            crc32=crc, assets=[{k: v for k, v in e.items() if k not in
                ('payload', 'destination', 'expression')} for e in entries]))
    manifest['payload_bytes'] = sum(e['size'] for e in assets)
    manifest['asset_count'] = len(assets)
    manifest['stored_payload_bytes'] = sum(e['size'] for entries in groups.values() for e in entries)
    manifest['stored_entry_count'] = sum(len(entries) for entries in groups.values())
    manifest['disk_bytes'] = sum(g['bytes'] for g in manifest['groups'])
    manifest['disk_payload_bytes'] = sum(g['stored_bytes'] for g in manifest['groups'])
    manifest['shared_sprites'] = {name: sorted(worlds) for name, worlds in sorted(sprite_usage.items())
                                  if len(worlds) > 1}
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    generate_dynamic_resources(ROOT, source, visited, groups, bundles)
    print(f"Exported {len(assets)} arrays, {manifest['payload_bytes']} bytes, {len(groups)} groups to {disk}")
    return source, disk


def pack_prg(path):
    subprocess.run(['upx', '--best', str(path)], check=True)
    subprocess.run(['upx', '-t', str(path)], check=True)


def build(source, disk, verify=False):
    for name in ('unapl', 'font', 'ems', 'ims', 'restore', 'render_cpu', 'ikbd', 'psgsound'):
        path = f'asm/{name}.s' if name != 'unapl' else 'unapl.s'
        subprocess.run(['vasmm68k_mot', '-quiet', '-Faout', '-o', f'{name}.o', path], cwd=source, check=True)
    for name, defines in [('FLOB.PRG', []), ('FLOBST.PRG', ['-dCPU_RENDER'])]:
        if verify:
            name, defines = 'VERIFY.PRG', ['-dVERIFY_FILE_ASSETS']
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
                        '-dSTE', '-dSAFE_FLIP_VBL', '-dSTAGGER_SLIME', '-vw', '-vm', '-vi',
                        *defines, f'-o{disk / name}', 'flob.pas'], cwd=source, check=True)
        pack_prg(disk / name)
        if verify:
            break
    # FPC places the main object next to -o; it is not a disk resource.
    (disk / 'flob.o').unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--build', action='store_true')
    parser.add_argument('--verify-build', action='store_true')
    parser.add_argument('--floppy', action='store_true', help='Build release PRGs and a 720 KiB floppy image')
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT or ROOT in output.parents:
        raise SystemExit('Output must be separate from the embedded project')
    source, disk = prepare(output)
    if args.floppy and args.verify_build:
        parser.error('--floppy requires a release build, not --verify-build')
    if args.build or args.verify_build or args.floppy:
        build(source, disk, args.verify_build)
    if args.floppy:
        from build_floppy import create_image
        create_image(disk, json.loads((output / 'manifest.json').read_text()), output / 'FLOB720.ST')


if __name__ == '__main__':
    main()
