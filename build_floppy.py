"""Build a standard 80-track, 2-sided, 9-sector FAT12 floppy, no overformat."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile


def create_image(disk, manifest, image, prg=None):
    disk, image = Path(disk), Path(image)
    prg = Path(prg) if prg else disk / 'FLOB.PRG'
    entries = {'FLOB.PRG': prg}
    entries.update({g['path']: disk / g['path'] for g in manifest['groups']})
    dirs = sorted({str(Path(name).parent) for name in entries if '/' in name})
    image.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='flob-floppy-', dir=image.parent) as tmp:
        tmp = Path(tmp)
        candidate = tmp / 'disk.st'
        subprocess.run(['mformat', '-i', str(candidate), '-C', '-f', '720', '-v', 'FLOB', '::'], check=True)
        for name in dirs:
            subprocess.run(['mmd', '-i', str(candidate), '::/' + name], check=True)
        for name, path in entries.items():
            subprocess.run(['mcopy', '-i', str(candidate), str(path), '::/' + name], check=True)
        data = candidate.read_bytes()
        assert len(data) == 737280
        sector, cluster, reserved, fats, roots, sectors = struct.unpack_from('<HBHBHH', data, 11)
        fat_sectors, spt, sides = struct.unpack_from('<HHH', data, 22)
        assert (sector, sectors, spt, sides) == (512, 1440, 9, 2)
        root_sectors = (roots * 32 + sector - 1) // sector
        clusters = (sectors - reserved - fats * fat_sectors - root_sectors) // cluster
        fat = data[reserved*sector:(reserved+fat_sectors)*sector]
        for copy in range(1, fats):
            assert fat == data[(reserved+copy*fat_sectors)*sector:(reserved+(copy+1)*fat_sectors)*sector]
        def fat12(n):
            value = int.from_bytes(fat[n*3//2:n*3//2+2], 'little')
            return (value >> 4 if n & 1 else value) & 0xFFF
        free = sum(fat12(n) == 0 for n in range(2, clusters+2)) * cluster * sector
        if free < 1024:
            raise ValueError(f'Only {free} bytes free: no room for FLOB.SAV')
        # Independent extraction through mtools verifies the actual filesystem.
        for name, path in entries.items():
            unpacked = tmp / 'readback'
            subprocess.run(['mcopy', '-o', '-i', str(candidate), '::/' + name, str(unpacked)], check=True)
            assert unpacked.read_bytes() == path.read_bytes(), name
        report = dict(image_bytes=len(data), data_capacity=clusters*cluster*sector,
            free_bytes=free, used_bytes=clusters*cluster*sector-free,
            files=len(entries), tracks=80, sides=sides, sectors_per_track=spt,
            sector_bytes=sector, cluster_bytes=cluster*sector,
            sha256=hashlib.sha256(data).hexdigest(),
            prg_sha256=hashlib.sha256(prg.read_bytes()).hexdigest())
        candidate.replace(image)
    image.with_suffix('.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'{image}: 720 KiB, {free} bytes free, {len(entries)} files', flush=True)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parent.parent / 'flob-files')
    args = parser.parse_args()
    manifest = json.loads((args.output / 'manifest.json').read_text())
    create_image(args.output / 'disk', manifest, args.output / 'FLOB720.ST')
