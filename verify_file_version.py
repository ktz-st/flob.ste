"""Verify all external payloads on target, optionally run gameplay regressions.

Uses a private disk copy, headless Hatari and configured TOS. Never touches
the user's emulator, original PRGs or save files.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from build_file_version import ROOT, DEFAULT_OUTPUT, prepare, build, pack_prg
from file_bundle import HEADER_BYTES


def run(source, disk, defines, report_name, marker, label, timeout=300, machine='ste', memory='1'):
    with tempfile.TemporaryDirectory(prefix='flob-files-check-') as tmp:
        tmp = Path(tmp)
        shutil.copytree(disk, tmp / 'disk')
        runtime = tmp / 'disk'
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
                        '-dSTE', '-dSAFE_FLIP_VBL', '-dSTAGGER_SLIME', '-vw', '-vm', '-vi',
                        '-dVERIFY_FILE_IO_ERRORS',
                        *defines, f'-o{runtime / "VERIFY.PRG"}', 'flob.pas'], cwd=source, check=True)
        pack_prg(runtime / 'VERIFY.PRG')
        if label == 'missing':
            (runtime / 'COMMON/FONT.BIN').unlink()
        if label == 'truncated':
            target = runtime / 'COMMON/FONT.BIN'
            target.write_bytes(target.read_bytes()[:-1])
        if label == 'corrupted':
            target = runtime / 'COMMON/FONT.BIN'
            data = bytearray(target.read_bytes())
            data[HEADER_BYTES] ^= 1
            target.write_bytes(data)
        if label == 'missing_world':
            (runtime / 'WORLD0/GFX.BIN').unlink()
        if label == 'truncated_intro':
            target = runtime / 'INTRO/GFX.BIN'
            target.write_bytes(target.read_bytes()[:-1])
        command = [str(ROOT.parent / 'hatariB/hatari/build-headless/src/hatari'),
                   '--machine', machine, '--memsize', memory, '--cpulevel', '0', '--cpuclock', '8',
                   '--monitor', 'rgb', '--fast-boot', 'true', '--fast-forward', 'true',
                   '--frameskips', '0', '--sound', 'off', '--joy0', 'none', '--joy1', 'none',
                   '--confirm-quit', 'false', '--run-vbls', '1000000',
                   '--benchmark', str(runtime / 'VERIFY.PRG')]
        report_path = ROOT / f'reports/file_assets_{label}.txt'
        log_path = report_path.with_suffix('.log')
        result = ''
        with log_path.open('w') as log:
            process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                env=dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy'))
            try:
                deadline = time.monotonic() + timeout
                while time.monotonic() < deadline:
                    report = runtime / report_name
                    if report.exists():
                        result = report.read_text()
                    error = runtime / 'FILE.ERR'
                    if error.exists() and report_name != 'FILE.ERR':
                        result = 'FAIL ' + error.read_text()
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
        report_path.write_text(result)
        assert marker in result and 'FAIL' not in result, (label, result, log_path)
        print(label, result, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gameplay', action='store_true')
    parser.add_argument('--lifetime', action='store_true')
    args = parser.parse_args()
    source, disk = prepare(DEFAULT_OUTPUT)
    build(source, disk)
    run(source, disk, ['-dVERIFY_FILE_ASSETS'], 'LOAD.OK', 'PASS', 'crc')
    run(source, disk, ['-dVERIFY_FILE_ASSETS'], 'FILE.ERR', 'Cannot open file', 'missing')
    run(source, disk, ['-dVERIFY_FILE_ASSETS'], 'FILE.ERR', 'Wrong file size', 'truncated')
    run(source, disk, ['-dVERIFY_FILE_ASSETS'], 'FILE.ERR', 'Payload checksum mismatch', 'corrupted')
    if args.gameplay:
        run(source, disk, ['-dVERIFY_GAMEPLAY'], 'GAMEPLAY.TXT', 'DONE', 'gameplay')
        run(source, disk, ['-dVERIFY_GAMEPLAY', '-dCPU_RENDER'], 'GAMEPLAY.TXT', 'DONE', 'gameplay_st', machine='st')
    if args.lifetime:
        for machine in ('ste', 'st'):
            run(source, disk, ['-dVERIFY_RESOURCE_LIFETIME'], 'LIFETIME.TXT', 'DONE',
                f'lifetime_{machine}', machine=machine)
        run(source, disk, ['-dVERIFY_RESOURCE_LIFETIME'], 'FILE.ERR', 'Cannot open file', 'missing_world')
        run(source, disk, ['-dVERIFY_RESOURCE_LIFETIME'], 'FILE.ERR', 'Wrong file size', 'truncated_intro')


if __name__ == '__main__':
    main()
