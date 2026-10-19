"""Verify native CPU kernels on STE and on an ST with no blitter."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--machine', choices=('st', 'ste', 'both'), default='both')
    parser.add_argument('--tos', type=Path, help='Optional TOS override; default uses Hatari configuration')
    parser.add_argument('--gameplay', action='store_true', help='Run existing gameplay regression suite on CPU')
    parser.add_argument('--native-gameplay', action='store_true', help='Run gameplay suite with hardware-selected renderer')
    args = parser.parse_args()
    gameplay = args.gameplay or args.native_gameplay
    subprocess.run(['make', 'render_cpu.o', 'ems.o', 'ims.o', 'restore.o'], cwd=ROOT, check=True)
    machines = ('ste', 'st') if args.machine == 'both' else (args.machine,)
    for machine in machines:
        with tempfile.TemporaryDirectory(prefix=f'flob-cpu-{machine}-') as folder:
            folder = Path(folder)
            program = folder / 'VERIFY.PRG'
            defines = ['-dVERIFY_GAMEPLAY', '-dSAFE_FLIP_VBL', '-dSTAGGER_SLIME'] if gameplay else ['-dVERIFY_CPU_RENDER']
            if args.gameplay and not args.native_gameplay:
                defines.append('-dCPU_RENDER')
            subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
                            *defines, '-vw', '-vm', '-vi',
                            f'-o{program}', 'flob.pas'], cwd=ROOT, check=True)
            command = [str(ROOT.parent / 'hatariB/hatari/build-headless/src/hatari'),
                       '--machine', machine, '--memsize', '4', '--cpulevel', '0', '--cpuclock', '8',
                       '--monitor', 'rgb', '--fast-boot', 'true', '--fast-forward', 'true',
                       '--frameskips', '0', '--sound', 'off', '--joy0', 'none', '--joy1', 'none',
                       '--confirm-quit', 'false', '--run-vbls', '1000000']
            if machine == 'st':
                command += ['--blitter', 'false']
            if args.tos:
                command += ['--tos', str(args.tos.resolve())]
            command += ['--benchmark', str(program)]
            result = ''
            tag = f'native_gameplay_{machine}' if args.native_gameplay else (f'cpu_gameplay_{machine}' if gameplay else f'cpu_render_{machine}')
            with (ROOT / f'reports/{tag}.log').open('w') as log:
                process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                    env=dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy'))
                try:
                    deadline = time.monotonic() + 240
                    while time.monotonic() < deadline:
                        report = folder / ('GAMEPLAY.TXT' if gameplay else 'CPU.TXT')
                        if report.exists():
                            result = report.read_text()
                        if 'DONE' in result or 'FAIL' in result or process.poll() is not None:
                            break
                        time.sleep(.25)
                finally:
                    if process.poll() is None:
                        process.terminate()
                        try:
                            process.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            process.kill()
                            process.wait()
            (ROOT / f'reports/{tag}.txt').write_text(result)
            assert 'DONE' in result and 'FAIL' not in result, result
            expected = 'TRUE' if machine == 'ste' else 'FALSE'
            if not gameplay:
                assert f'hardware_blitter={expected}' in result, result
            elif args.native_gameplay:
                assert f'renderer_blitter={expected}' in result, result
            print(machine, '\n'.join(line for line in result.splitlines() if not line.startswith('sprite=')))


if __name__ == '__main__':
    main()
