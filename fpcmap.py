"""Parse an FPC (-Xm) linker map into a symbol table.

`flob.prg` is linked with -Xs and carries no symbol table, so a cycle profile
cannot be attributed from the production binary. Building the same sources
without -Xs and with -Xm produces a map whose text offsets are identical (both
builds report text size 0x13b90); this module turns that map into the lookup
table `profile_report.py` uses.
"""
import re

# "  flob.o:  .text.n_p$flob_$$_vsync 1ab0(1e), ...  hex"
ENTRY = re.compile(r'\.(text|rodata|data|bss)\.[a-zA-Z0-9_]*?([^\s,]+)\s+([0-9a-f]+)\(([0-9a-f]+)\)')
# Hand-written .o modules contribute a bare ".text off(size)" with no symbol name.
# Without these the whole asm block (unapl, font, ems, ims, restore, ikbd,
# dmasound, sfxsynth, psgsound) reads as a hole and its cycles land on whatever
# Pascal routine happens to precede it.
BARE = re.compile(r'^\s*(\S+\.o):\s+\.(text|rodata|data|bss)\s+([0-9a-f]+)\(([0-9a-f]+)\)')


def symbols(map_path):
    """[(offset, size, section, name)] sorted by offset."""
    out = []
    started = False
    for line in open(map_path, errors='replace'):
        if line.startswith('Files:'):
            started = True
            continue
        if started and line.strip().startswith('0x'):
            break          # the global-symbol table follows; see globals_()
        if not started:
            continue
        bare = BARE.match(line)
        if bare:
            out.append((int(bare.group(3), 16), int(bare.group(4), 16),
                        bare.group(2), '[asm] ' + bare.group(1)))
        for section, name, offset, size in ENTRY.findall(line):
            out.append((int(offset, 16), int(size, 16), section, name))
    out.sort()
    return out


def globals_(map_path):
    """{'U_$P$FLOB_$$_LEVELNUM': offset} from the map's global symbol table.

    Offsets are relative to the program base, so a runtime address is
    basepage text + offset. They shift on every build: resolve them per run.
    """
    found = {}
    for line in open(map_path, errors='replace'):
        match = re.match(r'\s*0x([0-9a-f]+)\s+(\S+):\s+global', line)
        if match:
            found[match.group(2).rstrip(':')] = int(match.group(1), 16)
    return found


def text_symbols(map_path):
    return sorted((o, s, n) for o, s, sec, n in symbols(map_path) if sec == 'text')


if __name__ == '__main__':
    import sys
    text = text_symbols(sys.argv[1])
    print(f'{len(text)} text symbols, last ends at 0x{text[-1][0] + text[-1][1]:x}')
