"""Target-side regression tests for mask collisions, dirty IDs and fire input."""
from verify_score import main
import argparse
import subprocess
from pathlib import Path

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--simple-restore', action='store_true')
    parser.add_argument('--emx', action='store_true')
    parser.add_argument('--cpu', action='store_true')
    parser.add_argument('--stagger', action='store_true')
    parser.add_argument('--prepared-restore', action='store_true')
    args = parser.parse_args()
    defines = []
    assert not (args.cpu and args.emx)
    report = 'gameplay'
    if args.stagger:
        defines.append('STAGGER_SLIME')
        report += '_stagger'
    if args.cpu:
        subprocess.run(['make', 'slime_cpu.o'], cwd=Path(__file__).resolve().parent, check=True)
        defines.append('SLIME_CPU')
        report += '_cpu'
    if args.prepared_restore:
        defines.append('PREPARED_RESTORE')
        report += '_prepared'
    if args.simple_restore:
        defines.append('SIMPLE_RESTORE')
        report += '_simple'
    if args.emx:
        subprocess.run(['make', 'slime_emx.o'], cwd=Path(__file__).resolve().parent, check=True)
        defines.append('SLIME_EMX')
        report += '_emx'
    main('VERIFY_GAMEPLAY', 'GAMEPLAY.TXT',
         report, 'DONE', 'DONE', extra_defines=defines)
