"""Compare EMS and legacy output using Hatari's actual blitter emulation."""
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent


def main():
    subprocess.run(['make','ems.o','ims.o'],cwd=ROOT,check=True)
    with tempfile.TemporaryDirectory(prefix='flob-ems-') as directory:
        directory = Path(directory)
        program = directory/'VERIFY.PRG'
        subprocess.run(['/opt/fpc/lib/fpc/3.3.1/ppcross68k','-Tatari','-O2','-Si','-Xs',
            '-dSTE','-dNO_IMS','-dVERIFY_EMS','-vw','-vm','-vi',f'-o{program}','flob.pas'],cwd=ROOT,check=True)
        command = [str(ROOT.parent/'hatariB/hatari/build-headless/src/hatari'),
            '--machine','ste','--memsize','4','--cpulevel','0','--cpuclock','8',
            '--monitor','rgb','--tos',str(ROOT.parent/'hatariB/emutos/etos1024k.img'),
            '--fast-boot','true','--fast-forward','true','--frameskips','0','--sound','off',
            '--joy0','none','--joy1','none','--confirm-quit','false',
            '--run-vbls','90000','--benchmark',str(program)]
        with (ROOT/'reports/ems_verification.log').open('w') as log:
            process = subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,
                env=dict(os.environ,SDL_VIDEODRIVER='dummy',SDL_AUDIODRIVER='dummy'))
            result = ''
            try:
                deadline = time.monotonic()+100
                while time.monotonic()<deadline:
                    path=directory/'EMS.TXT'
                    if path.exists(): result=path.read_text()
                    if 'EMS calls:' in result or 'FAIL' in result: break
                    if process.poll() is not None: break
                    time.sleep(0.25)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try: process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill(); process.wait()
        (ROOT/'reports/ems_verification.txt').write_text(result)
        assert 'PASS 2304 framebuffer comparisons' in result, result
        assert 'EMS calls: 1304' in result, result
        assert 'FAIL' not in result, result
        print('\n'.join(result.splitlines()[-2:]))


if __name__=='__main__':
    main()
