# W1 R13 Renderer Benchmark: ems_geometric_linear

Hatari, STE 68000 8 MHz, 4 MB, forced PAL 50 Hz, EmuTOS. 512 iterations per phase.
16 small slime, no world objects. Original background, music callback enabled;
host sound output disabled. Warm-up paints both buffers before counters start.
Controlled rendering test, NOT full gameplay FPS: physics, pickup, NPC animation and messages
are excluded. Moving Flob traverses 90..121 logical X, two screen pixels per step, fixed shape.
Slime animation follows the production sysframe counter (one increment per iteration).
Timing uses emulated VBL and HZ200, not host fast-forward speed. HZ200 samples have 5 ms granularity.

| Workload | FPS min..max | 2-VBL frames / 512 | 3+ VBL frames / 512 | Blits / 512 |
|---|---:|---:|---:|---:|
| no slime, stationary Flob | 50.00..50.00 | 0..0 | 0..0 | 0 |
| no slime, moving Flob | 50.00..50.00 | 0..0 | 0..0 | 511 |
| static slime, stationary Flob | 50.00..50.00 | 0..0 | 0..0 | 0 |
| animated slime, stationary Flob | 44.52..44.52 | 63..63 | 0..0 | 1008 |
| static slime, moving Flob | 50.00..50.00 | 0..0 | 0..0 | 671 |
| animated slime, moving Flob | 44.52..44.52 | 63..63 | 0..0 | 1663 |

Legacy starts the blitter eight times per sprite; EMS starts once per sprite row.
Both backbuffers must be refreshed after an animation change.
sysframe is iteration-driven, so missed VBL deadlines also slow the animation and movement.
Blit counts count sprite calls, not individual hardware starts.
