# Flob Atari STE SFX

Game-ready conversions of the original Atari 8-bit POKEY effects.

Format: mono, unsigned 8-bit PCM WAV, 12517 Hz. The sample rate and resolution
match Atari STE DMA playback. WAV stores 8-bit PCM as unsigned values, so a
matching `.raw` file is generated with bit 7 toggled. Each `.raw` contains
signed 8-bit mono PCM without a header and is ready for STE DMA playback.
The 25033 Hz stereo 16-bit reference renders remain in `../a8_sfx_wav`.

Regenerate both sets with:

```sh
make sfx-wav
```
