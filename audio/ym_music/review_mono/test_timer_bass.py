"""One offline timer-waveform experiment; not a hardware replay or FYM asset.

Keep the existing preview renderer's gain/noise model for a controlled A/B.
Only distortion-C voices use the volume-wave sequence from the supplied MYM
modules. Integrate that waveform across samples to limit aliasing.
"""
from pathlib import Path
import argparse
import sys
import json
import struct
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))
import convert_rmt_to_ym as converter

OUT = Path(__file__).resolve().parent
MYM = ROOT.parent / 'st-pokey-music/analysis/CHOPPER.snd'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--track', choices=('world_03', 'outro', 'endgame'), default='world_03')
    args = parser.parse_args()
    stem = 'flob_' + args.track
    metadata = json.loads((OUT / (stem + '.json')).read_text())
    source_path = Path(metadata['source'])
    data = MYM.read_bytes()
    seq_base = data.index(b'MYM1INST') + 8 + 2048 + 32
    # SID replay caps the stored 17-step sequence to 16 steps.
    attenuation = struct.unpack('>16H', data[seq_base+128:seq_base+160])
    assert set(attenuation) == {0, 15}
    shape = np.array([1.0 if value == 0 else -1.0 for value in attenuation])
    shape -= shape.mean()
    integral_table = np.concatenate(([0.0], np.cumsum(shape)))

    def integral(phase):
        local = np.mod(phase, 16.0)
        index = np.floor(local).astype(int)
        return integral_table[index] + (local-index)*shape[index]

    seconds, _ = converter.detect_song_timing(source_path, metadata['song'])
    pokey = converter.dump_left_pokey(source_path, metadata['song'], seconds)
    allocations = converter.allocate_dynamic_channels(pokey, (0, 1, 2, 3))
    frames = [converter.convert_frame(f, a, metadata['volume_attenuation'])
              for f, a in zip(pokey, allocations)]
    phases = [0.0]*3
    timer_phases = [0.0]*3
    noise_phase, lfsr = 0.0, 0x1FFFF
    volumes = [0.0] + [10.0**((v-15)*1.5/20.0) for v in range(1, 16)]
    pcm, control = [], []
    affected = 0
    max_timers = 0
    for source, allocation, regs in zip(pokey, allocations, frames):
        count = converter.WAV_RATE // 50
        noise = []
        noise_delta = converter.YM_CLOCK / (16*max(1, regs[6]&31)*converter.WAV_RATE)
        for _ in range(count):
            noise_phase += noise_delta
            while noise_phase >= 1:
                noise_phase -= 1
                lfsr = (lfsr >> 1) | (((lfsr ^ (lfsr >> 3)) & 1) << 16)
            noise.append(bool(lfsr & 1))
        mix = np.zeros(count)
        old_mix = np.zeros(count)
        active = 0
        for ch, src_ch in enumerate(allocation):
            period = max(1, regs[2*ch] | ((regs[2*ch+1]&15)<<8))
            delta = converter.YM_CLOCK / (16*period*converter.WAV_RATE)
            phase = (phases[ch] + delta*np.arange(1, count+1)) % 1
            phases[ch] = float(phase[-1])
            gate = np.ones(count, dtype=bool)
            if not regs[7] & (1<<ch):
                gate &= phase < .5
            if not regs[7] & (1<<(ch+3)):
                gate &= noise
            amplitude = volumes[regs[8+ch]&15]
            square = np.where(gate, amplitude, -amplitude)
            old_mix += square
            if source.audc[src_ch]&0xf0 == 0xc0 and amplitude:
                active += 1
                affected += 1
                step = 16*delta
                edges = timer_phases[ch] + step*np.arange(count+1)
                mix += amplitude*(integral(edges[1:])-integral(edges[:-1]))/step
                timer_phases[ch] = float(edges[-1] % 16)
            else:
                mix += square
        max_timers = max(max_timers, active)
        pcm.append(np.clip(np.rint(mix*8500), -32767, 32767).astype('<i2'))
        control.append(np.clip(np.rint(old_mix*8500), -32767, 32767).astype('<i2'))
    for name, parts in [(stem + '_timer_test', pcm), (stem + '_timer_control', control)]:
        with wave.open(str(OUT / (name+'.wav')), 'wb') as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(converter.WAV_RATE)
            wav.writeframes(np.concatenate(parts).tobytes())
    report = dict(track=stem, frames=len(frames), affected_voice_frames=affected,
                  maximum_simultaneous_timer_voices=max_timers,
                  attenuation_sequence=list(attenuation),
                  note='Offline waveform concept only; no MFP divider quantization, interrupt jitter or STE CPU cost measured. Existing preview volume ladder retained for A/B. No game files replaced.')
    (OUT/(stem + '_timer_test.json')).write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
