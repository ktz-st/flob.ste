# CPU Card-Flip (2026-10-10)

## Worms Reference

`../worms-amiga/ste/port/wormste.cpp`, `hud_rows`, uses a precomputed
screen-row to source-row map, copies 160-byte rows as longwords, and skips
rows already showing that source. `port/tools/hud_pack.py` reconstructs
the original Amiga Copper modulo table into `c_hud_flip[15][38]`.

Flob retains its four-step animation (160/80/32/8/0). These heights need
constant source strides: 160/320/800/3200 bytes. The CPU path now resolves
the stride and centered destination once and calls `CopyFlipRowsCPU`.
Its row loop has five unrolled 32-byte MOVEM transfers, no division and no
per-row Pascal call. `MirrorPlayfieldCPU` exchanges top/bottom rows directly
in registers instead of using three Move calls and a temporary line.

The Worms single-panel row cache is not transplanted: Flob has two separate
page histories and changes BKG halfway through the effect. Existing per-page
height tracking and border-only clearing remain unchanged. The STE blitter
path, VSync, palette, sprite layering and gameplay timing are unchanged.

## Target Measurement

Command: `python3 verify_cpu_render.py --gameplay`.
Hatari headless, 68000 at 8 MHz, 4 MB, ST without blitter and STE with forced
CPU rendering. TOS uses the existing configuration. Each batch runs 64 times;
times use the target's 200 Hz clock (5 ms/tick), without VSync or presentation.

| Machine | Batch | Old ticks | New ticks | Speedup |
| --- | --- | ---: | ---: | ---: |
| ST | All four nonzero squash heights | 3599 | 379 | 9.50x |
| ST | In-place BKG mirror | 1880 | 236 | 7.97x |
| STE, CPU | All four nonzero squash heights | 3610 | 380 | 9.50x |
| STE, CPU | In-place BKG mirror | 1886 | 236 | 7.99x |

This measures kernels, not a 9.5x speedup of the complete animation: its
eight screen presentations, clearing, overlays and final buffer rebuild
still have their own costs.

Both gameplay suites passed. Flip pixels are compared with an independent
old-style sampler, including arbitrary-height fallback (73), zero and invalid
height. BKG mirror is compared in both directions over the entire 32000-byte
screen, including unchanged HUD/message areas. Existing collision, occlusion,
dirty-render, sprite overlap, switch, pickup and input regressions also pass.

Builds: `make all` and `make st`.
