"""File-only lifetime hooks. Never rewrite the embedded edition's sources."""
import re
import zlib
from file_bundle import HEADER_BYTES


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f'File-version hook changed: {old!r}')
    return text.replace(old, new)


def edit_routine(text, start, end, edit):
    a = text.index(start)
    b = text.index(end, a)
    return text[:a] + edit(text[a:b]) + text[b:]


def generate_dynamic_resources(root, source, visited, groups, bundles):
    names = {e['symbol'] for entries in groups.values() for e in entries} - {'FlobFont'}
    sizes = {e['symbol']: e['size'] for entries in groups.values() for e in entries}
    tables = []
    # Leave Pascal strings and comments untouched when adding dereferences.
    token = re.compile(r"'(?:''|[^'])*'|\{.*?\}|\(\*.*?\*\)|//[^\n]*|\b\w+\b", re.S)
    pointer_table = re.compile(r'(\w+)\s*:\s*(array\s*\[[^]]+\]\s*of\s*pointer)\s*=\s*\((.*?)\);', re.S | re.I)
    for relative in sorted(visited):
        path = source / relative
        text = path.read_text()
        declarations = []

        def declaration(m):
            name, kind = m.groups()
            if name not in names:
                return m[0]
            declarations.append(f'type TFile_{name} = {kind};\n'
                f'{{$if SizeOf(TFile_{name}) <> {sizes[name]}}}{{$fatal Resource size mismatch: {name}}}{{$endif}}\n'
                f'var {name}: ^TFile_{name};')
            return f'FILEDECLPLACEHOLDER{len(declarations)-1}'

        text = re.sub(r'var (\w+): (array\s*\[[^]]+\]\s*of\s*\w+);', declaration, text)

        def table(m):
            refs = re.findall(r'@(\w+)\[0\]', m[3])
            if not any(n in names for n in refs):
                return m[0]
            if not refs or not all(n in names for n in refs):
                raise ValueError(f'Mixed resource pointer table {m[1]}')
            tables.extend((f'{m[1]}[{i}]', name) for i, name in enumerate(refs))
            return f'var {m[1]}: {m[2]};\nconst\n'

        text = pointer_table.sub(table, text)
        text = token.sub(lambda m: m[0] + '^' if m[0] in names else m[0], text)
        text = re.sub(r'FILEDECLPLACEHOLDER(\d+)', lambda m: declarations[int(m[1])], text)
        text = re.sub(r'\bconst\s*(?=var\b|type\b|const\b|\Z)', '', text, flags=re.I)
        path.write_text(text)

    paths = sorted(groups)
    ids = {p: i for i, p in enumerate(paths)}
    resident = [ids[p] for p in paths if p.startswith(('COMMON/', 'TITLE/'))]
    api = ['const FILE_GROUP_COUNT = %d;' % len(paths)]
    api += ['type TFilePalette = array[0..15] of word;',
            'var fileVideoReady, fileInputReady: boolean;',
            'procedure LoadFileAssets; forward;',
            'procedure FileEnsureWorld(w: byte); forward;',
            'procedure FileReleaseWorld; forward;',
            'procedure FileWorldInfo(w: byte); forward;',
            'procedure FileBeginScene(bank: byte); forward;',
            'procedure FileEndScene(bank: byte); forward;',
            'procedure FileEnsureMusic(song: byte); forward;',
            'procedure VerifyFileResources; forward;']
    (source / 'file_resource_api.inc').write_text('\n'.join(api) + '\n')

    desc = ['type TFileBinding = record slot: PPointer; offset: longword; end;',
            '     TFileLink = record dst, src: PPointer; end;', 'const']
    bindings, ranges = [], []
    for path in paths:
        start = len(bindings)
        for entry in groups[path]:
            if entry['symbol'] != 'FlobFont':
                bindings.append(f"(slot: @{entry['symbol']}; offset: {entry['offset']-HEADER_BYTES})")
        ranges.append((start, len(bindings)-start))
    desc.append(f'FILE_BINDINGS: array[0..{len(bindings)-1}] of TFileBinding = (' + ',\n'.join(bindings) + ');')
    desc.append(f'FILE_LINKS: array[0..{len(tables)-1}] of TFileLink = (' + ',\n'.join(
        f'(dst: @{table}; src: @{name})' for table, name in tables) + ');')
    def array(name, kind, values):
        desc.append(f'{name}: array[0..{len(values)-1}] of {kind} = (' + ',\n'.join(map(str, values)) + ');')
    array('FILE_PATHS', 'string[31]', ["'" + p.replace('/', '\\') + "'" for p in paths])
    array('FILE_SIZES', 'longint', [sum((e['size']+1)&~1 for e in groups[p]) for p in paths])
    array('FILE_STORED_SIZES', 'longint', [bundles[p]['stored_bytes'] for p in paths])
    array('FILE_STORED_CRCS', 'longword', ['$%08X' % bundles[p]['stored_crc32'] for p in paths])
    crc_table = []
    for i in range(256):
        crc = i
        for _ in range(8):
            crc = (crc >> 1) ^ (0xEDB88320 if crc & 1 else 0)
        crc_table.append('$%08X' % crc)
    array('FILE_CRC_TABLE', 'longword', crc_table)
    array('FILE_CRCS', 'longword', ['$%08X' % zlib.crc32(b''.join(e['payload'] + b'\0'*(e['size']&1) for e in groups[p])) for p in paths])
    array('FILE_COUNTS', 'word', [len(groups[p]) for p in paths])
    array('FILE_FIRST', 'word', [r[0] for r in ranges])
    array('FILE_LENGTH', 'word', [r[1] for r in ranges])
    array('FILE_RESIDENT', 'boolean', ['true' if i in resident else 'false' for i in range(len(paths))])
    array('FILE_WORLD_GROUPS', 'array[0..2] of byte', ['(%s)' % ','.join(str(ids[f'WORLD{w}/{k}.BIN']) for k in ('GFX','MAPS','SPRITES')) for w in range(6)])
    array('FILE_WORLD_MUSIC', 'byte', [ids[f'WORLD{w}/MSX.BIN'] for w in range(5)])
    for p in ('TITLE/MSX.BIN','INTRO/MSX.BIN','OUTRO/MSX.BIN','ENDING/MSX.BIN','INTRO/GFX.BIN','OUTRO/GFX.BIN','CREDITS/GFX.BIN','COMMON/FONT.BIN'):
        desc.append('FILE_' + p.replace('/', '_').replace('.BIN', '') + ' = ' + str(ids[p]) + ';')
    desc.append(f"FILE_FONT_BYTES = {sizes['FlobFont']};")
    (source / 'file_resource_tables.inc').write_text('\n'.join(desc) + '\n')
    runtime = (root / 'file_resource_runtime.inc').read_text()
    runtime = runtime.replace('{ WORLD_INFO_CASES }', '\n'.join(
        f'        {w}: packedData := @{"WORLD_%02d_DATA_APL" % w}^[0];' for w in range(6)))
    runtime += '\n{$ifdef VERIFY_RESOURCE_LIFETIME}\n' + (root / 'file_resource_verify.inc').read_text() + '\n{$endif}\n'
    runtime = runtime.replace('    FileCleanup;\n    Halt;',
        "    FileCleanup;\n{$ifdef VERIFY_FLOPPY}\n    Writeln('FLOB_VERIFY_DONE');\n{$endif}\n    Halt;")
    (source / 'file_loader.inc').write_text(runtime)

    path = source / 'flob.pas'
    text = path.read_text()
    text = replace_once(text, '{$mode objfpc}', '{$mode objfpc}\n{$M 65536,65536,65536}')
    text = replace_once(text, 'procedure ReadInput; forward;', '{$i file_resource_api.inc}\nprocedure ReadInput; forward;')
    text = replace_once(text, '\nbegin\n    gemdos_super(pointer(0));', '\n{$i file_loader.inc}\nbegin\n    gemdos_super(pointer(0));')
    text = replace_once(text, '    ScreenInit;\n{$ifdef VERIFY_CPU_RENDER}',
        '    ScreenInit;\n    fileVideoReady := true;\n    BlackAll;\n    LoadFileAssets;\n{$ifdef VERIFY_FILE_ASSETS}\n    VerifyFileResources;\n{$endif}\n{$ifdef VERIFY_CPU_RENDER}')
    text = replace_once(text, '    InstallInput;\n    sysframe', '    InstallInput;\n    fileInputReady := true;\n    sysframe')
    text = replace_once(text, '    worldCurrent := 0;\n\n{$ifdef VERIFY_CREDITS}',
        '    worldCurrent := 0;\n{$ifdef VERIFY_RESOURCE_LIFETIME}\n    VerifyResourceLifetime;\n{$endif}\n\n{$ifdef VERIFY_CREDITS}')
    text = replace_once(text, '    FillChar(oldPalette, SizeOf(oldPalette), 0);',
        '    for i := 0 to 15 do oldPalette[i] := xbios_setcolor(i, -1);')
    text = replace_once(text, 'procedure ScreenInit;\n', 'procedure ScreenInit;\nvar i: byte;\n')
    text = text.replace('var pairBase: longword;', '    pairBase: longword;')
    text = edit_routine(text, 'procedure PlaySong(p: byte);', 'procedure StopSong;',
        lambda s: replace_once(s, '    packedMusic := nil;', '    FileEnsureMusic(p);\n    packedMusic := nil;'))
    text = edit_routine(text, 'procedure LoadWorld(w: byte);\nvar', 'procedure InitWorld;',
        lambda s: replace_once(s, '    packedWorldData := nil;', '    FileEnsureWorld(w);\n    packedWorldData := nil;'))
    for start, end in [('procedure CheckAchievements;\nvar', 'procedure DrawEndWorldIcon'),
                       ('procedure ShowStats;\nconst', 'procedure PauseGame;'),
                       ('function ShowWorldSelector: boolean;', 'procedure LoadTitleTo')]:
        text = edit_routine(text, start, end, lambda s: s.replace('LoadWorld(', 'FileWorldInfo('))
    text = edit_routine(text, 'procedure CheckAchievements;\nvar', 'procedure DrawEndWorldIcon',
        lambda s: s.replace('var w, achNum, i: byte;', 'var w, achNum, i: byte;\n    savedWorld: TWorld;\n    savedData: PByte;')
        .replace('    newAchivements  := 0;', '    savedWorld := world;\n    savedData := currentWorldData;\n    newAchivements  := 0;')
        .replace('    for i := 12 to 23 do CheckAchievement(i);', '    for i := 12 to 23 do CheckAchievement(i);\n    world := savedWorld;\n    currentWorldData := savedData;'))
    text = edit_routine(text, 'procedure InitTitle;', 'procedure ShowTitleScreen;',
        lambda s: s.replace('    BlackAll;', '    BlackAll;\n    FileReleaseWorld;'))
    text = edit_routine(text, 'procedure ShowCutScene(csbank, cscount: byte);\nvar', 'procedure ShowCredits;\nvar',
        lambda s: replace_once(s.replace('    BlackAll;', '    BlackAll;\n    FileBeginScene(csbank);'),
            '    WaitForStartKeyUp;\n    WaitFrame;\nend;', '    WaitForStartKeyUp;\n    WaitFrame;\n    FileEndScene(csbank);\nend;'))
    text = edit_routine(text, 'procedure ShowCredits;\nvar', 'procedure ShowScene(scene:',
        lambda s: replace_once(s.replace('    BlackAll;', '    BlackAll;\n    FileBeginScene(CREDITS_BANK);'),
            "    WaitForStartKeyUp;\n{$ifdef VERIFY_CREDITS}", "    WaitForStartKeyUp;\n    FileEndScene(CREDITS_BANK);\n{$ifdef VERIFY_CREDITS}"))
    text = replace_once(text, '            StopSong;\n            keyboardInputEnabled := false;',
        '            StopSong;\n            BlackAll;\n            LoadWorld(worldCurrent);\n            keyboardInputEnabled := false;')
    text = text.replace('    ScreenDone;\n    Halt;',
        "    ScreenDone;\n{$ifdef VERIFY_FLOPPY}\n    Writeln('FLOB_VERIFY_DONE');\n{$endif}\n    Halt;")
    path.write_text(text)
