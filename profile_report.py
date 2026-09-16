"""Attribute an hrdb !profile capture to FPC map symbols and write a report.

Cycles land on the instruction that was executing, so a blitter burst is
charged to the register write that started it. These are CPU cycles, not frame
share: the FPS and budget columns come from SwapScreen entry counts and
emulated time, not from the cycle shares.
"""
import argparse
import bisect
import json
from pathlib import Path

import fpcmap

ROOT = Path(__file__).resolve().parent
TEXT_END = 0x13B90          # program text size; addresses past it are data/TOS
PAL_FRAME_CYCLES = 160000   # 8 MHz / 50 Hz
CPU_HZ = 8_000_000


def pretty(name):
    name = name.replace('n_p$flob_$$_', '').replace('n_system_$$_', 'System.')
    name = name.replace('n_p$flob$_$', '').replace('n_', '')
    return name.split('$')[0]


class Capture:
    def __init__(self, path, map_path=None):
        data = json.loads(Path(path).read_text())
        self.path, self.room, self.move = path, data['room'], data['move']
        self.world = data.get('world', 0)
        self.base, self.lines = data['base'], data['lines']
        # A capture written by profile_room.py carries the symbol table of the
        # build it measured; only an older one needs --map, and then the map
        # must be that build's or every name is wrong.
        if data.get('symbols'):
            self.symbols = sorted(tuple(s) for s in data['symbols'])
        elif map_path:
            self.symbols = fpcmap.text_symbols(map_path)
        else:
            raise SystemExit(f'{path} has no embedded symbols; pass --map '
                             'pointing at the map of the build it measured')
        self.offsets = [o for o, _, _ in self.symbols]
        self.total = sum(c for _, _, c in self.lines) or 1
        self.frames = self._entry_count('n_p$flob_$$_swapscreen')
        self.vsync = self._cycles_in('n_p$flob_$$_vsync')
        self.work = self.total - self.vsync
        self.seconds = self.total / CPU_HZ

    def _range(self, name):
        for offset, size, symbol in self.symbols:
            if symbol == name:
                return offset, size
        raise KeyError(name)

    def _entry_count(self, name):
        """Executions of a routine's first instruction, i.e. its call count."""
        offset, _ = self._range(name)
        for addr, count, _ in self.lines:
            if addr - self.base == offset:
                return count
        return 0

    def _cycles_in(self, name):
        offset, size = self._range(name)
        return sum(c for a, _, c in self.lines if offset <= a - self.base < offset + size)

    @property
    def fps(self):
        return self.frames / self.seconds if self.seconds else 0

    def aggregate(self):
        """{symbol: (cycles, instructions, calls)}, calls only where resolvable."""
        cycles, instructions, calls = {}, {}, {}
        for addr, count, cycle in self.lines:
            offset = addr - self.base
            if 0 <= offset < TEXT_END:
                i = bisect.bisect_right(self.offsets, offset) - 1
                start, _, symbol = self.symbols[i]
                key = pretty(symbol)
                if offset == start:
                    calls[key] = count
            elif 0xE00000 <= addr < 0xF00000 or addr >= 0xFC0000:
                key = '[TOS ROM]'
            elif addr < 0x800:
                key = '[vectors]'
            else:
                key = '[other]'
            cycles[key] = cycles.get(key, 0) + cycle
            instructions[key] = instructions.get(key, 0) + count
        return {k: (v, instructions[k], calls.get(k, 0)) for k, v in cycles.items()}

    def hot_addresses(self, name, top=8):
        """Per-address split inside one routine. A symbol table says which
        routine to look at; only this says what to do about it."""
        offset, size = self._range(name)
        inside = [(a - self.base - offset, n, c) for a, n, c in self.lines
                  if offset <= a - self.base < offset + size]
        return sorted(inside, key=lambda row: -row[2])[:top]


def table(capture, floor=300):
    rows = []
    for key, (cycles, _, calls) in sorted(capture.aggregate().items(),
                                          key=lambda kv: -kv[1][0]):
        if key.lower() == 'vsync' or cycles / capture.frames < floor:
            continue
        rows.append((key, cycles / capture.frames, 100 * cycles / capture.work,
                     calls / capture.frames, cycles / calls if calls else 0))
    return rows


def report(captures, title='Room CPU Cycle Profile'):
    out = [f'# {title}', '',
           'hatari-hrdb cycle profile of the real gameplay loop. STE 68000 8 MHz, 4 MB,',
           'EmuTOS 1024k, forced PAL 50 Hz. Unlike run_slime_benchmark.py this is not a',
           'controlled renderer workload: physics, hazards, collisions, input and music',
           'are included. Frame counts are SwapScreen entry executions; a PAL frame at',
           f'8 MHz is {PAL_FRAME_CYCLES:,} cycles.', '',
           '| Capture | Frames | FPS | Cycles/frame | Work/frame (excl. VSync) | vs budget |',
           '|---|---:|---:|---:|---:|---:|']
    for c in captures:
        label = f"W{c.world} R{c.room:02d}, {'moving' if c.move else 'idle'}"
        out.append(f'| {label} | {c.frames} | {c.fps:.1f} | {c.total / c.frames:,.0f} '
                   f'| {c.work / c.frames:,.0f} '
                   f'| {100 * (c.work / c.frames) / PAL_FRAME_CYCLES:.0f}% |')
    for c in captures:
        out += ['', f"## W{c.world} R{c.room:02d}, {'moving' if c.move else 'idle'}", '',
                '| Routine | cyc/frame | % work | calls/frame | cyc/call |',
                '|---|---:|---:|---:|---:|']
        for name, per_frame, share, calls, per_call in table(c):
            out.append(f'| `{name}` | {per_frame:,.0f} | {share:.1f} | {calls:.1f} '
                       f'| {per_call:,.0f} |' if calls else
                       f'| `{name}` | {per_frame:,.0f} | {share:.1f} | – | – |')
    return '\n'.join(out) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('captures', nargs='+', help='profile JSON from profile_room.py')
    parser.add_argument('--map', default=None,
                        help='map for captures without an embedded symbol table')
    parser.add_argument('--out', default=None, help='write markdown here')
    parser.add_argument('--split', action='append', default=[],
                        help='also show the per-address split of this text symbol')
    args = parser.parse_args()

    captures = [Capture(p, args.map) for p in args.captures]
    text = report(captures)
    print(text)
    for name in args.split:
        for c in captures:
            print(f'\n== {name} in R{c.room:02d} '
                  f"({'moving' if c.move else 'idle'}) ==")
            for offset, count, cycles in c.hot_addresses(name):
                print(f'   +{offset:04x} {cycles:12,d} cyc {count:9,d} x '
                      f'{cycles / max(count, 1):7.1f} cyc/x')
    if args.out:
        Path(args.out).write_text(text)
        print('written', args.out)


if __name__ == '__main__':
    main()
