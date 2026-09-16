"""Extract the first POKEY, not a downmix of both stereo chips."""
from pathlib import Path
import wave
from array import array

root = Path(__file__).resolve().parent
for name in ('intro', 'world_00', 'world_01', 'world_02', 'world_03', 'world_04', 'outro', 'endgame', 'theme'):
    with wave.open(str(root / f'{name}_pokey_stereo.wav'), 'rb') as src:
        assert src.getsampwidth() == 2
        channels = src.getnchannels()
        assert channels == 2
        rate = src.getframerate()
        data = array('h', src.readframes(src.getnframes()))
    with wave.open(str(root / f'{name}_pokey_mono.wav'), 'wb') as dst:
        dst.setnchannels(1)
        dst.setsampwidth(2)
        dst.setframerate(rate)
        dst.writeframes(data[::channels].tobytes())
    print(name, len(data) // channels, 'samples', rate, 'Hz')
