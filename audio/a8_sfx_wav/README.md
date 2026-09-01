# Flob Atari 8-bit SFX renders

These WAV files are faithful renders of the original Raster Music Tracker
instruments through ASAP's POKEY emulator. The extraction harness calls the
same note and stereo channels as `FSfx` in the Atari 8-bit game, but does not
advance or mix the music tracks.

Format: stereo, signed 16-bit PCM, 25033 Hz. Trailing silence is trimmed while
keeping 100 ms after the final non-zero sample.

Regenerate the complete set from the original sources with:

```sh
make sfx-wav
```

`beep.wav`, `teleport.wav`, and `scrape.wav` are named copies of `console.wav`,
`reveal.wav`, and `gas.wav`, matching the aliases in the original `const.inc`.
See `manifest.json` for source constants, RMT instrument indices, durations,
and checksums.
