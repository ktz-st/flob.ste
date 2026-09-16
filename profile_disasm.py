"""Annotate a routine's disassembly with the cycles the profiler charged to it.

A per-symbol table says which routine to look at; only this says what to do
about it. Stack-frame traffic at the top means register spills (rewrite it);
plain memory operands mean the data layout is the cost.
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SKILL = Path.home() / '.claude/skills/hatari-debugging/scripts'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('capture', help='profile JSON from profile_room.py')
    parser.add_argument('symbol', help='text symbol substring, e.g. renderqueuedsprites')
    parser.add_argument('--top', type=int, default=25)
    parser.add_argument('--tos', default=str(ROOT.parent / 'hatariB/emutos/etos1024k.img'))
    args = parser.parse_args()

    data = json.loads(Path(args.capture).read_text())
    symbols = sorted(tuple(s) for s in data['symbols'])
    hits = [s for s in symbols if args.symbol in s[2]]
    if not hits:
        sys.exit(f'no text symbol matching {args.symbol!r}')
    offset, size, name = hits[0]
    cycles = {a - data['base'] - offset: (n, c) for a, n, c in data['lines']
              if offset <= a - data['base'] < offset + size}
    print(f'{name}  {size} bytes, {sum(c for _, c in cycles.values()):,} cycles in capture')

    # Hatari's debugger is the disassembler here; the PRG carries no symbols.
    sys.path.insert(0, str(SKILL))
    from hatari_session import HatariSession
    import fpcmap
    session = HatariSession(str(ROOT / 'flob.prg'), machine='ste', tos=args.tos,
                            hatari='hatari', sound=False, joysticks=False,
                            socket_path='/tmp/flob_disasm.sock',
                            extra_args=['--memsize', '4', '--cpulevel', '0',
                                        '--cpuclock', '8', '--monitor', 'rgb',
                                        '--confirm-quit', 'false'])
    session.start()
    try:
        session.wait(9)
        base = session.basepage()['text']
        lines = []
        step = 64
        for at in range(offset, offset + size, step):
            out = session.debug('d $%x $%x' % (base + at, base + min(at + step, offset + size)),
                                settle=0.6)
            lines += [l for l in out if re.match(r'^\$?[0-9A-Fa-f]{6,8}', l.strip())]
    finally:
        session.stop()

    rows = []
    for line in lines:
        m = re.match(r'^\$?([0-9A-Fa-f]{6,8})\s*:?\s+(.*)$', line.strip())
        if not m:
            continue
        off = int(m.group(1), 16) - base - offset
        n, c = cycles.get(off, (0, 0))
        rows.append((c, n, off, m.group(2).strip()))
    frames = data.get('frames') or 0
    for c, n, off, text in sorted(rows, reverse=True)[:args.top]:
        if not c:
            break
        print(f'  +{off:04x} {c:10,d} cyc {n:9,d} x {c / max(n, 1):7.1f} c/x   {text[:70]}')
    spill = sum(c for c, n, off, text in rows if '%a6@(-' in text or 'a6,-' in text
                or re.search(r'-\d+\(%?a6\)', text))
    total = sum(c for c, _, _, _ in rows)
    print(f'  stack-frame traffic: {spill:,} of {total:,} cycles '
          f'({100 * spill / max(total, 1):.1f}%)')


if __name__ == '__main__':
    main()
