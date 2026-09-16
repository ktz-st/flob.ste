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
    parser.add_argument('--w1-r13', action='store_true', help='Measure W1 R13 with 16 slime')
    parser.add_argument('--profile', action='store_true', help='Instrument render stages; separate from baseline timings')
    parser.add_argument('--legacy', action='store_true', help='Use the old eight-pass sprite renderer')
    parser.add_argument('--simple-restore', action='store_true', help='Restore independent rectangles and redraw every sprite')
    parser.add_argument('--emx', action='store_true', help='Generated slime blitter programs')
    parser.add_argument('--cpu', action='store_true', help='Preshifted slime CPU renderer')
    parser.add_argument('--stagger', action='store_true', help='Delay odd slime animation by one tick')
    parser.add_argument('--prepared-restore', action='store_true', help='Experimental cached blitter records')
    parser.add_argument('--legacy-dirty', action='store_true', help='Previous merged dirty bookkeeping')
    args = parser.parse_args()
    assert not (args.cpu and (args.emx or args.legacy))
    results = []
    suffix = '_legacy' if args.legacy else '_ems'
    if args.simple_restore: suffix += '_simple'
    if args.emx: suffix += '_emx'
    if args.cpu: suffix += '_cpu'
    if args.stagger: suffix += '_stagger'
    suffix += '_prepared' if args.prepared_restore else '_geometric'
    suffix += '_legacydirty' if args.legacy_dirty else '_linear'
    if args.profile: suffix += '_profile'
    tag = 'w1_r13' if args.w1_r13 else 'r06'
    title = 'W1 R13' if args.w1_r13 else 'W0 R06'
    with tempfile.TemporaryDirectory(prefix='flob-r06-') as directory:
        directory = Path(directory)
        program = directory/'BENCH.PRG'
        command = ['/opt/fpc/lib/fpc/3.3.1/ppcross68k','-Tatari','-O2','-Si','-Xs',
            '-dSTE','-dBENCH_SLIME','-vw','-vm','-vi',f'-o{program}','flob.pas']
        if args.legacy: command[1:1]=['-dNO_EMS','-dNO_IMS']
        if args.w1_r13: command.insert(1, '-dBENCH_W1_R13')
        if args.profile: command.insert(1, '-dBENCH_PROFILE')
        if args.simple_restore: command.insert(1, '-dSIMPLE_RESTORE')
        if args.prepared_restore: command.insert(1, '-dPREPARED_RESTORE')
        if args.legacy_dirty: command.insert(1, '-dLEGACY_DIRTY_BOOKKEEPING')
        if args.stagger: command.insert(1, '-dSTAGGER_SLIME')
        subprocess.run(['make', 'restore.o'], cwd=ROOT, check=True)
        if args.cpu:
            subprocess.run(['make', 'slime_cpu.o'], cwd=ROOT, check=True)
            command.insert(1, '-dSLIME_CPU')
        if args.emx:
            subprocess.run(['make', 'slime_emx.o'], cwd=ROOT, check=True)
            command.insert(1, '-dSLIME_EMX')
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
            (ROOT/f'reports/slime_{tag}{suffix}_run{run+1}.log').write_text(process.stdout+process.stderr)
            raw = csv_path.read_text()
            if args.profile:
                for filename in ('PROFILE.CSV', 'COLL.TXT'):
                    data = (directory/filename).read_text()
                    (ROOT/f'reports/slime_{tag}{suffix}_run{run+1}_{filename.lower()}').write_text(data)
                    print(data)
            (ROOT/f'reports/slime_{tag}{suffix}_run{run+1}.csv').write_text(raw)
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
    (ROOT/f'reports/slime_{tag}_benchmark{suffix}.json').write_text(json.dumps(results,indent=2)+'\n')
    lines = [f'# {title} Renderer Benchmark: '+suffix[1:],'',
        'Hatari, STE 68000 8 MHz, 4 MB, forced PAL 50 Hz, EmuTOS. 512 iterations per phase.',
        ('16 small slime, no world objects.' if args.w1_r13 else 'Six small slime and static world objects.') + ' Original background, music callback enabled;',
        'host sound output disabled. Warm-up paints both buffers before counters start.',
        'Controlled rendering test, NOT full gameplay FPS: physics, pickup, NPC animation and messages',
        'are excluded. Moving Flob traverses 90..121 logical X, two screen pixels per step, fixed shape.',
        'Slime animation follows the production sysframe counter (one increment per iteration).',
        'Timing uses emulated VBL and HZ200, not host fast-forward speed. HZ200 samples have 5 ms granularity.',
        '', '| Workload | FPS min..max | 2-VBL frames / 512 | 3+ VBL frames / 512 | Blits / 512 |',
        '|---|---:|---:|---:|---:|']
    for phase,name in enumerate(PHASES):
        rows=[r for r in results if r['phase']==phase]
        fps=[r['fps'] for r in rows]
        stalls=[r['frames_2vbl'] for r in rows]
        long_stalls=[r['frames_3plus_vbl'] for r in rows]
        lines.append(f"| {name} | {min(fps):.2f}..{max(fps):.2f} | {min(stalls)}..{max(stalls)} | {min(long_stalls)}..{max(long_stalls)} | {rows[0]['blits']} |")
    lines += ['', 'Legacy starts the blitter eight times per sprite; EMS starts once per sprite row.',
        'Both backbuffers must be refreshed after an animation change.',
        'sysframe is iteration-driven, so missed VBL deadlines also slow the animation and movement.',
        'Blit counts count sprite calls, not individual hardware starts.']
    report='\n'.join(lines)+'\n'
    (ROOT/f'reports/slime_{tag}_benchmark{suffix}.md').write_text(report)
    print(report)


if __name__=='__main__':
    main()
