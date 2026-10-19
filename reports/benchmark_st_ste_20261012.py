import argparse
import csv
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
HATARI = ROOT.parent / 'hatariB/hatari/build-headless/src/hatari'
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', action='store_true')
parser.add_argument('--label', default='')
args = parser.parse_args()
results = []
for world, room in ((0, 11), (1, 13)):
    with tempfile.TemporaryDirectory(prefix='flob-audit-') as folder:
        folder = Path(folder)
        (folder / 'flob.pas').write_bytes((ROOT / 'flob.pas').read_bytes())
        bench = (ROOT / 'benchmark_slime.inc').read_text()
        bench = bench.replace('BenchRoom = 6;', 'BenchRoom = 11;')
        (folder / 'benchmark_slime.inc').write_text(bench)
        prg = folder / 'AUDIT.PRG'
        defs = ['STE', 'BENCH_SLIME', 'BENCH_PROFILE', 'SAFE_FLIP_VBL', 'STAGGER_SLIME']
        if args.baseline:
            defs.remove('BENCH_PROFILE')
        if world == 1:
            defs.append('BENCH_W1_R13')
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k', '-Tatari', '-O2', '-Si', '-Xs',
                        '-vw', '-vm', '-vi', f'-Fi{ROOT}', f'-Fo{ROOT}', f'-o{prg}',
                        *[f'-d{x}' for x in defs], str(folder / 'flob.pas')], cwd=ROOT, check=True)
        for machine in ('st', 'ste'):
            for name in ('BENCH.CSV', 'PROFILE.CSV', 'COLL.TXT'):
                (folder / name).unlink(missing_ok=True)
            tag = f'audit_20261012_{machine}_w{world}_r{room:02d}'
            if args.baseline:
                tag += '_baseline'
            tag += args.label
            cmd = [str(HATARI), '--machine', machine, '--memsize', '4', '--cpulevel', '0',
                   '--cpuclock', '8', '--monitor', 'rgb', '--fast-boot', 'true',
                   '--fast-forward', 'true', '--frameskips', '0', '--sound', 'off',
                   '--joy0', 'none', '--joy1', 'none', '--confirm-quit', 'false',
                   '--run-vbls', '15000', '--benchmark', str(prg)]
            if machine == 'st':
                cmd[1:1] = ['--blitter', 'false']
            with (ROOT / f'reports/{tag}.log').open('w') as log:
                p = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT,
                    env=dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy'))
                try:
                    deadline = time.monotonic() + 180
                    while time.monotonic() < deadline:
                        out = folder / 'BENCH.CSV'
                        if out.exists() and len(out.read_text().splitlines()) == 7:
                            break
                        if p.poll() is not None:
                            break
                        time.sleep(.2)
                    raw = out.read_text()
                finally:
                    if p.poll() is None:
                        p.terminate()
                        try:
                            p.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            p.kill()
                            p.wait()
            rows = [{k: int(v) for k, v in row.items()} for row in csv.DictReader(raw.splitlines())]
            assert len(rows) == 6
            for row in rows:
                assert abs(row['hz200_ticks'] / row['vbls'] - 4) < .04
                assert sum(row[k] for k in ('frames_1vbl','frames_2vbl','frames_3plus_vbl')) == 512
                row['fps'] = 50 * row['frames'] / row['vbls']
            for name in (('BENCH.CSV',) if args.baseline else ('BENCH.CSV', 'PROFILE.CSV', 'COLL.TXT')):
                (ROOT / f'reports/{tag}_{name.lower()}').write_bytes((folder / name).read_bytes())
            item = dict(machine=machine, world=world, room=room, rows=rows)
            results.append(item)
            result_name = 'audit_20261012_render_baseline.json' if args.baseline else 'audit_20261012_render.json'
            result_name = result_name.replace('.json', args.label + '.json')
            (ROOT / f'reports/{result_name}').write_text(json.dumps(results, indent=2)+'\n')
            print(tag, json.dumps(rows[5]), flush=True)
