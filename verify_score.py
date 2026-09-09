"""Check score-only refresh against full HUD rendering in Hatari."""
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent


def main(define='VERIFY_SCORE', filename='SCORE.TXT', report='score',
         success='PASS 12 score changes', marker='PASS'):
    subprocess.run(['make', 'ems.o', 'ims.o', 'restore.o'], cwd=ROOT, check=True)
    with tempfile.TemporaryDirectory(prefix='flob-score-') as directory:
        directory = Path(directory)
        program = directory / 'VERIFY.PRG'
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
                        '-dSTE', f'-d{define}', '-vw', '-vm', '-vi',
                        f'-o{program}', 'flob.pas'], cwd=ROOT, check=True)
        cmd = [str(ROOT.parent / 'hatariB/hatari/build-headless/src/hatari'),
               '--machine', 'ste', '--memsize', '4', '--cpulevel', '0', '--cpuclock', '8',
               '--monitor', 'rgb', '--tos', str(ROOT.parent / 'hatariB/emutos/etos1024k.img'),
               '--fast-boot', 'true', '--fast-forward', 'true', '--frameskips', '0',
               '--sound', 'off', '--joy0', 'none', '--joy1', 'none', '--confirm-quit', 'false',
               '--run-vbls', '90000', '--benchmark', str(program)]
        result = ''
        with (ROOT / f'reports/{report}_verification.log').open('w') as log:
            process = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT,
                env=dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy'))
            try:
                deadline = time.monotonic() + 90
                while time.monotonic() < deadline:
                    path = directory / filename
                    if path.exists():
                        result = path.read_text()
                    if marker in result or 'FAIL' in result or process.poll() is not None:
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
    (ROOT / f'reports/{report}_verification.txt').write_text(result)
    assert success in result and 'FAIL' not in result, result
    print(result)


if __name__ == '__main__':
    main()
