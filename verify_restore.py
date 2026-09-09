"""Compare batched restore with the Pascal reference on an emulated STE."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent


def main():
    subprocess.run(['make', 'restore.o', 'ims.o', 'ems.o'], cwd=ROOT, check=True)
    with tempfile.TemporaryDirectory(prefix='flob-restore-') as directory:
        directory = Path(directory)
        program = directory / 'VERIFY.PRG'
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
                        '-dSTE', '-dNO_RESTORE_ASM', '-dVERIFY_RESTORE', '-vw', '-vm', '-vi',
                        f'-o{program}', 'flob.pas'], cwd=ROOT, check=True)
        cmd = [str(ROOT.parent / 'hatariB/hatari/build-headless/src/hatari'),
               '--machine', 'ste', '--memsize', '4', '--cpulevel', '0', '--cpuclock', '8',
               '--monitor', 'rgb', '--tos', str(ROOT.parent / 'hatariB/emutos/etos1024k.img'),
               '--fast-boot', 'true', '--fast-forward', 'true', '--frameskips', '0',
               '--sound', 'off', '--joy0', 'none', '--joy1', 'none', '--confirm-quit', 'false',
               '--run-vbls', '1000000', '--benchmark', str(program)]
        result = ''
        with (ROOT / 'reports/restore_verification.log').open('w') as log:
            process = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT,
                env=dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy'))
            try:
                deadline = time.monotonic() + 180
                while time.monotonic() < deadline:
                    path = directory / 'RESTORE.TXT'
                    if path.exists():
                        result = path.read_text()
                    if 'BENCH' in result or 'FAIL' in result or process.poll() is not None:
                        break
                    time.sleep(.5)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
    (ROOT / 'reports/restore_verification.txt').write_text(result)
    assert 'PASS comparisons=400' in result, result
    match = re.search(r'pascal_ticks=(\d+) asm_ticks=(\d+)', result)
    assert match, result
    old, new = map(int, match.groups())
    summary = (f'32000 rectangles: Pascal {old*5} ms, ASM {new*5} ms; '
               f'{100*(old-new)/old:.1f}% less time.\n'
               'Hatari STE 8 MHz, HZ200 timing; isolated restore, not gameplay FPS.\n')
    (ROOT / 'reports/restore_benchmark.txt').write_text(summary)
    print(result + summary)


if __name__ == '__main__':
    main()
