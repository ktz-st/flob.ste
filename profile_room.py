"""Cycle-profile the real gameplay loop sitting in one room, under hatari-hrdb.

run_slime_benchmark.py measures a controlled renderer workload in a fixed room.
This measures the production game loop as played: physics, hazards, pickup,
collisions, input and the music callback all run and are all counted.

Getting into an arbitrary room needs three tricks:

  * cheatmode is armed by pressing H during boot -- CRT_HelpPressed tests
    KEY_H_CODE, not the ST Help key -- and bconin is buffered, so a tap
    anywhere in the boot window is picked up by CheckDiags.
  * cheat room stepping ('[' / ']') is not usable on its own: Flob is dropped
    into the next room at his current position and frequently dies there, so
    the room reached is not the room asked for. levelNum is poked instead.
  * Explode's entry is patched with an RTS for the duration of the window.
    Every detection path (FlobTouchesDangerColor, CheckSpriteCollisions,
    CheckSlimeCollision) still runs and is still counted; only the death
    sequence is suppressed, so the capture stays in one room.

The profiler wants break -> profile 1 -> run, in that order; leaving the break
loop is what arms the per-instruction hook. Enabling it while running collects
nothing. See the hatari-debugging skill's hrdb-profiling reference.

    python3 profile_room.py --room 11
    python3 profile_room.py --room 11 --move
    python3 profile_report.py reports/profile_w0_r11_*.json --out reports/x.md
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parent
SKILL_SCRIPTS = os.environ.get(
    'HATARI_SKILL_SCRIPTS',
    str(Path.home() / '.claude/skills/hatari-debugging/scripts'))


def load_harness():
    if not Path(SKILL_SCRIPTS, 'hatari_session.py').exists():
        sys.exit(f'hatari-debugging skill scripts not found at {SKILL_SCRIPTS}\n'
                 'set HATARI_SKILL_SCRIPTS or pass --skill-scripts')
    sys.path.insert(0, SKILL_SCRIPTS)
    from hatari_session import HatariSession
    from hrdb_profile import Rdb, profile_lines
    return HatariSession, Rdb, profile_lines


def build(directory, defines=()):
    """Same sources as flob.prg but unstripped and with a map: -Xs drops the
    symbol table, and stripping is post-link, so text is byte-identical."""
    program = directory / 'FLOBSYM.PRG'
    subprocess.run(['make', 'unapl.o', 'font.o', 'ems.o', 'ims.o', 'restore.o',
                    'ikbd.o', 'dmasound.o', 'sfxsynth.o', 'psgsound.o'],
                   cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    command = ['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-dSTE',
               '-Xm', '-vw', '-vm', '-vi'] + [f'-d{d}' for d in defines] + \
              [f'-o{program}', 'flob.pas']
    subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    shutil.copy(program.with_suffix('.map'), ROOT / 'reports/flobsym.map')
    return program


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--room', type=int, default=11)
    parser.add_argument('--world', type=int, default=0)
    parser.add_argument('--define', action='append', default=[])
    parser.add_argument('--seconds', type=float, default=10.0)
    parser.add_argument('--move', action='store_true',
                        help='drive left/right through the window')
    parser.add_argument('--start-x', type=int, choices=range(160), metavar='0..159',
                        help='override Flob X after room load (A8 coordinates)')
    parser.add_argument('--hatari', default='hatari-hrdb')
    parser.add_argument('--rdb-port', type=int, default=56001,
                        help='requires HATARI_RDB_PORT support for non-default ports')
    parser.add_argument('--tos', default=str(ROOT.parent / 'hatariB/emutos/etos1024k.img'))
    parser.add_argument('--skill-scripts', default=None)
    parser.add_argument('--out', default=None)
    args = parser.parse_args()
    if args.skill_scripts:
        globals()['SKILL_SCRIPTS'] = args.skill_scripts

    HatariSession, Rdb, profile_lines = load_harness()
    import fpcmap

    if not shutil.which('lsof'):
        sys.exit('lsof is required to verify debugger ownership')
    with socket.socket() as probe:
        probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            probe.bind(('127.0.0.1', args.rdb_port))
        except OSError as error:
            sys.exit(f'Debugger port {args.rdb_port} unavailable: {error}')
    os.environ['HATARI_RDB_PORT'] = str(args.rdb_port)

    with tempfile.TemporaryDirectory(prefix='flob-profile-') as directory:
        program = build(Path(directory), args.define)
        addresses = fpcmap.globals_(ROOT / 'reports/flobsym.map')

        session = HatariSession(
            str(program), machine='ste', tos=args.tos, hatari=args.hatari,
            screenshot_dir=str(ROOT / 'reports/profile_shots'),
            sound=False, joysticks=False, socket_path='/tmp/flob_profile.sock',
            extra_args=['--memsize', '4', '--cpulevel', '0', '--cpuclock', '8',
                        '--monitor', 'rgb', '--confirm-quit', 'false'])
        session.start()
        try:
            for _ in range(30):                 # H during boot arms cheatmode
                session.tap('H', hold=0.05, after=0.15)
            session.wait(3)
            base = session.basepage()['text']
            session.debug('w $ffff820a 2')      # PAL 50 Hz; EmuTOS boots this image at 60

            def address(name):
                return base + addresses[f'U_$P$FLOB_$$_{name}']

            def peek(name):
                at = address(name)
                return session.mem(at, 1).u8(at)

            # Boot key timing can miss CheckDiags. Unlock only this test process.
            session.debug('w $%x 1' % address('CHEATMODE'))
            session.tap('SPACE', hold=0.2, after=0.6)      # title -> world selector
            session.wait(2)
            for _ in range(args.world):                   # cheatmode unlocks every world
                session.tap('RIGHT', hold=0.2, after=0.9)
                session.wait(1.2)
            world = base + addresses['U_$P$FLOB_$$_WORLDCURRENT']
            assert session.mem(world, 1).u8(world) == args.world, 'wrong world selected'
            for _ in range(5):                            # confirm, skip any cutscene
                session.tap('SPACE', hold=0.2, after=0.6)
                session.wait(1.5)
            assert peek('LEVELNUM') == 0, 'did not reach gameplay'

            explode = base + addresses['P$FLOB_$$_EXPLODE']
            session.debug('w $%x 78 117' % explode)          # rts
            session.debug('w $%x %d' % (address('LEVELNUM'), args.room))
            session.debug('w $%x 1' % address('ROOM_CHANGED'))
            session.wait(4)
            assert peek('LEVELNUM') == args.room, 'room did not load'
            if args.start_x is not None:
                session.debug('w $%x %d' % (address('FLOBX'), args.start_x))

            owner = subprocess.run(['lsof', '-a', '-p', str(session.proc.pid),
                                    f'-iTCP:{args.rdb_port}', '-sTCP:LISTEN', '-t'],
                                   capture_output=True, text=True)
            assert str(session.proc.pid) in owner.stdout.split(), \
                'debugger listener is not owned by the test emulator; refusing connection'
            rdb = Rdb(port=args.rdb_port)
            rdb.cmd('break', wait=2)
            rdb.cmd('profile 1')
            rdb.cmd('run', wait=0.5)
            if args.move:
                for _ in range(int(args.seconds / 1.2)):
                    session.tap('LEFT', hold=0.35, after=0.25)
                    session.tap('RIGHT', hold=0.35, after=0.25)
            else:
                time.sleep(args.seconds)
            rdb.cmd('break', wait=5)
            message = rdb.take('!profile')
            lines = profile_lines(message) if message else []
            rdb.cmd('profile 0')
            rdb.cmd('run')

            swap = base + addresses['P$FLOB_$$_SWAPSCREEN']
            assert any(a == swap and count > 1 for a, count, _ in lines), \
                'profile has no gameplay frames; refusing invalid capture'
            render = base + addresses['P$FLOB_$$_RENDERQUEUEDSPRITES']
            assert any(a == render and count > 1 for a, count, _ in lines), \
                'profile is not gameplay (possibly a menu); refusing invalid capture'
            flip = base + addresses['P$FLOB_$$_FLIP']
            assert not any(a == flip and count for a, count, _ in lines), \
                'flip occurred during movement-only capture; refusing mixed workload'

            actual_room = peek('LEVELNUM')
            assert actual_room == args.room, f'left the room mid-capture: R{actual_room:02d}'
            shot = session.screenshot()
        finally:
            session.stop()

    suffix = 'move' if args.move else 'idle'
    out = Path(args.out or
               ROOT / f'reports/profile_w{args.world}_r{args.room:02d}_{suffix}.json')
    # Symbol addresses shift on every build, so the capture carries its own
    # table: reading an old capture against a newer map dumps the wrong names
    # and hands you a confident wrong answer.
    symbols = fpcmap.text_symbols(ROOT / 'reports/flobsym.map')
    out.write_text(json.dumps({'base': base, 'world': args.world, 'room': args.room,
                               'move': args.move, 'seconds': args.seconds,
                               'defines': args.define, 'start_x': args.start_x,
                               'hatari': args.hatari, 'rdb_port': args.rdb_port,
                               'start_x_phase': 'after_room_load',
                               'symbols': symbols, 'lines': lines}) + '\n')
    print(f'W{args.world} R{args.room:02d} {suffix}: {len(lines):,} addresses, '
          f'{sum(c for _, _, c in lines):,} cycles -> {out}')
    print('screenshot', shot)


if __name__ == '__main__':
    main()
