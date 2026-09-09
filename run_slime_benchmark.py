"""Reproducible PAL/8 MHz Hatari render workload in W0 R06, isolated from saves."""
import argparse
import csv
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
PHASES = ['no slime, stationary Flob', 'no slime, moving Flob',
          'static slime, stationary Flob', 'animated slime, stationary Flob',
          'static slime, moving Flob', 'animated slime, moving Flob']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--hatari', default=str(ROOT.parent/'hatariB/hatari/build-headless/src/hatari'))
    parser.add_argument('--tos', default=str(ROOT.parent/'hatariB/emutos/etos1024k.img'))
    parser.add_argument('--runs', type=int, default=3)
    parser.add_argument('--legacy', action='store_true', help='Use the old eight-pass sprite renderer')
    args = parser.parse_args()
    results = []
    suffix = '_legacy' if args.legacy else '_ems'
    with tempfile.TemporaryDirectory(prefix='flob-r06-') as directory:
        directory = Path(directory)
        program = directory/'BENCH.PRG'
        command = ['/opt/fpc/lib/fpc/3.3.1/ppcross68k','-Tatari','-O2','-Si','-Xs',
            '-dSTE','-dBENCH_SLIME','-vw','-vm','-vi',f'-o{program}','flob.pas']
        if args.legacy: command[1:1]=['-dNO_EMS','-dNO_IMS']
        subprocess.run(command,cwd=ROOT,check=True)
        for run in range(args.runs):
            csv_path = directory/'BENCH.CSV'
            csv_path.unlink(missing_ok=True)
            command = [args.hatari,'--machine','ste','--memsize','4','--cpulevel','0',
                '--cpuclock','8','--monitor','rgb','--tos',args.tos,'--fast-boot','true',
                '--fast-forward','true','--frameskips','0','--sound','off',
                '--joy0','none','--joy1','none','--confirm-quit','false',
                '--run-vbls','9000','--benchmark',str(program)]
            process = subprocess.run(command,env=dict(os.environ,SDL_VIDEODRIVER='dummy',
                SDL_AUDIODRIVER='dummy'),capture_output=True,text=True,timeout=90,check=True)
            (ROOT/f'reports/slime_r06{suffix}_run{run+1}.log').write_text(process.stdout+process.stderr)
            raw = csv_path.read_text()
            (ROOT/f'reports/slime_r06{suffix}_run{run+1}.csv').write_text(raw)
            rows = [{k:int(v) for k,v in row.items()} for row in csv.DictReader(io.StringIO(raw))]
            assert len(rows)==6
            for row in rows:
                # HZ200 and VBL must confirm PAL, not an accidental 60 Hz boot.
                assert abs(row['hz200_ticks']/row['vbls']-4)<0.03
                assert row['frames_1vbl']+row['frames_2vbl']+row['frames_3plus_vbl']==row['frames']
                row['run']=run+1
                row['workload']=PHASES[row['phase']]
                row['fps']=50*row['frames']/row['vbls']
            results.extend(rows)
    (ROOT/f'reports/slime_r06_benchmark{suffix}.json').write_text(json.dumps(results,indent=2)+'\n')
    lines = ['# W0 R06 Renderer Benchmark: '+suffix[1:],'',
        'Hatari, STE 68000 8 MHz, 4 MB, forced PAL 50 Hz, EmuTOS. 512 iterations per phase.',
        'Six small slime, original room background and static world objects. Music callback enabled;',
        'host sound output disabled. Warm-up paints both buffers before counters start.',
        'Controlled rendering test, NOT full gameplay FPS: physics, pickup, NPC animation and messages',
        'are excluded. Moving Flob traverses 90..121 logical X, two screen pixels per step, fixed shape.',
        'Slime animation follows the production sysframe counter (one increment per iteration).',
        'Timing uses emulated VBL and HZ200, not host fast-forward speed. HZ200 samples have 5 ms granularity.',
        '', '| Workload | FPS min..max | 2-VBL frames / 512 | Blits / 512 |',
        '|---|---:|---:|---:|']
    for phase,name in enumerate(PHASES):
        rows=[r for r in results if r['phase']==phase]
        fps=[r['fps'] for r in rows]
        stalls=[r['frames_2vbl'] for r in rows]
        lines.append(f"| {name} | {min(fps):.2f}..{max(fps):.2f} | {min(stalls)}..{max(stalls)} | {rows[0]['blits']} |")
    lines += ['', 'Legacy starts the blitter eight times per sprite; EMS starts once per sprite row.',
        'Six changing slime require 48 legacy starts or 36 EMS starts, plus Flob and background restoration.',
        'Both backbuffers must be refreshed after an animation change: 32 changes x 2 buffers x 6 slime = 384 blits.',
        'sysframe is iteration-driven, so missed VBL deadlines also slow the animation and movement.',
        'Blit counts count sprite calls, not individual hardware starts.']
    report='\n'.join(lines)+'\n'
    (ROOT/f'reports/slime_r06_benchmark{suffix}.md').write_text(report)
    print(report)


if __name__=='__main__':
    main()
