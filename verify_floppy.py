"""Test packed executables/resources through a real emulated floppy at 1 MiB.

Private image copies; no GEMDOS host drive, no TOS override, no user emulator.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from PIL import Image

from build_file_version import ROOT, DEFAULT_OUTPUT, prepare, build, pack_prg
from build_floppy import create_image

HATARI = ROOT.parent / 'hatariB/hatari/build-headless/src/hatari'


class FloppySession:
    def __init__(self, image, machine, directory, label):
        self.fifo = directory / 'control.fifo'
        self.log_path = ROOT / f'reports/floppy_{label}_{machine}.log'
        self.log = self.log_path.open('w')
        command = [str(HATARI), '--machine', machine, '--memsize', '1', '--ttram', '0',
            '--cpulevel', '0', '--cpuclock', '8', '--monitor', 'rgb', '--vdi', 'false',
            '--harddrive', 'none', '--ide-master', 'none', '--ide-slave', 'none',
            '--disk-a', str(image), '--drive-a', 'true', '--drive-a-heads', '2',
            '--drive-b', 'false', '--auto', 'A:\\FLOB.PRG', '--protect-floppy', 'off',
            '--fastfdc', 'false', '--fast-boot', 'true', '--fast-forward', 'true',
            '--frameskips', '0', '--sound', 'off', '--joy0', 'none', '--joy1', 'none',
            '--confirm-quit', 'false', '--run-vbls', '100000', '--conout', '2',
            '--cmd-fifo', str(self.fifo), '--statusbar', 'false']
        if machine == 'st':
            command += ['--blitter', 'false']
        for device in ('--acsi', '--scsi'):
            for i in range(8):
                command += [device, f'{i}=none']
        self.process = subprocess.Popen(command, stdout=self.log, stderr=subprocess.STDOUT,
            env=dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy'))
        self.wait(lambda: self.fifo.exists(), 10)

    def wait(self, condition, timeout):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if condition():
                return
            if self.process.poll() is not None:
                raise RuntimeError(self.log_path.read_text())
            time.sleep(.1)
        raise TimeoutError(self.log_path)

    def command(self, text):
        fd = os.open(self.fifo, os.O_WRONLY | os.O_NONBLOCK)
        try:
            os.write(fd, (text + '\n').encode())
        finally:
            os.close(fd)

    def shot(self, machine, phase):
        target = ROOT / f'reports/floppy_release_{machine}_{phase}.png'
        target.unlink(missing_ok=True)
        self.command(f'hatari-debug screenshot {target}')
        self.wait(target.exists, 10)
        return target

    def visible_shot(self, machine, phase, timeout=60):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            target = self.shot(machine, phase)
            with Image.open(target) as picture:
                if sum(sum(rgb) > 30 for rgb in picture.convert('RGB').getdata()) > 10000:
                    return target
            time.sleep(1)
        self.command('hatari-debug r')
        self.command('hatari-debug info basepage')
        self.command('hatari-debug d pc')
        time.sleep(1)
        raise RuntimeError(f'Black screen at {phase}: {self.log_path}')

    def tap(self, scan):
        self.command(f'hatari-event keydown {scan:02d}')
        time.sleep(.15)
        self.command(f'hatari-event keyup {scan:02d}')

    def close(self):
        if self.process.poll() is None:
            self.command('hatari-shortcut quit')
            try:
                self.process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.process.terminate()
                self.process.wait(timeout=5)
        self.log.close()


def target_test(source, disk, manifest, machine, define, report_name, label):
    with tempfile.TemporaryDirectory(prefix='flob-floppy-test-') as tmp:
        tmp = Path(tmp)
        prg = tmp / 'FLOB.PRG'
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
            '-dSTE', '-dSAFE_FLIP_VBL', '-dSTAGGER_SLIME', '-dVERIFY_FLOPPY',
            '-dVERIFY_FILE_IO_ERRORS', f'-d{define}', '-vw', '-vm', '-vi',
            f'-o{prg}', 'flob.pas'], cwd=source, check=True)
        pack_prg(prg)
        image = tmp / 'test.st'
        create_image(disk, manifest, image, prg)
        session = FloppySession(image, machine, tmp, label)
        try:
            session.wait(lambda: 'FLOB_VERIFY_DONE' in session.log_path.read_text() or
                         'Flob resource error' in session.log_path.read_text(), 300)
        finally:
            session.close()
        result = tmp / 'result.txt'
        subprocess.run(['mcopy', '-i', str(image), '::/' + report_name, str(result)], check=True)
        text = result.read_text()
        (ROOT / f'reports/floppy_{label}_{machine}.txt').write_text(text)
        assert 'FAIL' not in text and ('DONE' in text or 'PASS CRC32' in text), text
        assert 'GEMDOS HDD emulation, C:' not in session.log_path.read_text()
        print(machine, label, text, flush=True)


def release_smoke(image, machine):
    with tempfile.TemporaryDirectory(prefix='flob-floppy-release-') as tmp:
        tmp = Path(tmp)
        private = tmp / 'release.st'
        shutil.copy2(image, private)
        session = FloppySession(private, machine, tmp, 'release')
        try:
            time.sleep(15)
            session.command('hatari-option --fast-forward false')
            time.sleep(.5)
            session.visible_shot(machine, 'title')
            session.tap(57)  # Space / FIRE
            time.sleep(1.5)
            session.visible_shot(machine, 'selector')
            session.tap(57)
            time.sleep(5)
            session.visible_shot(machine, 'intro')
            session.tap(57)
            time.sleep(12)
            session.visible_shot(machine, 'room')
            session.tap(57)
            time.sleep(1.5)
            session.command('hatari-event keydown 77')  # Right
            time.sleep(1)
            session.command('hatari-event keyup 77')
            session.shot(machine, 'moved')
        finally:
            session.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--smoke-only', action='store_true')
    parser.add_argument('--no-build', action='store_true')
    args = parser.parse_args()
    source, disk = DEFAULT_OUTPUT / 'src', DEFAULT_OUTPUT / 'disk'
    if not args.no_build:
        source, disk = prepare(DEFAULT_OUTPUT)
        build(source, disk)
    manifest = json.loads((DEFAULT_OUTPUT / 'manifest.json').read_text())
    image = DEFAULT_OUTPUT / 'FLOB720.ST'
    create_image(disk, manifest, image)
    for machine in ('ste', 'st'):
        if not args.smoke_only:
            target_test(source, disk, manifest, machine, 'VERIFY_FILE_ASSETS', 'LOAD.OK', 'crc')
            target_test(source, disk, manifest, machine, 'VERIFY_RESOURCE_LIFETIME', 'LIFETIME.TXT', 'lifetime')
            target_test(source, disk, manifest, machine, 'VERIFY_GAMEPLAY', 'GAMEPLAY.TXT', 'gameplay')
        release_smoke(image, machine)


if __name__ == '__main__':
    main()
