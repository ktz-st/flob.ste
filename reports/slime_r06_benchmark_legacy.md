# W0 R06 Renderer Benchmark: legacy

Hatari, STE 68000 8 MHz, 4 MB, forced PAL 50 Hz, EmuTOS. 512 iterations per phase.
Six small slime, original room background and static world objects. Music callback enabled;
host sound output disabled. Warm-up paints both buffers before counters start.
Controlled rendering test, NOT full gameplay FPS: physics, pickup, NPC animation and messages
are excluded. Moving Flob traverses 90..121 logical X, two screen pixels per step, fixed shape.
Slime animation follows the production sysframe counter (one increment per iteration).
Timing uses emulated VBL and HZ200, not host fast-forward speed. HZ200 samples have 5 ms granularity.

| Workload | FPS min..max | 2-VBL frames / 512 | Blits / 512 |
|---|---:|---:|---:|
| no slime, stationary Flob | 50.00..50.00 | 0..0 | 0 |
| no slime, moving Flob | 50.00..50.00 | 0..0 | 511 |
| static slime, stationary Flob | 50.00..50.00 | 0..0 | 0 |
| animated slime, stationary Flob | 50.00..50.00 | 0..0 | 384 |
| static slime, moving Flob | 50.00..50.00 | 0..0 | 511 |
| animated slime, moving Flob | 45.47..45.47 | 51..51 | 895 |

Legacy starts the blitter eight times per sprite; EMS starts once per sprite row.
Six changing slime require 48 legacy starts or 36 EMS starts, plus Flob and background restoration.
Both backbuffers must be refreshed after an animation change: 32 changes x 2 buffers x 6 slime = 384 blits.
sysframe is iteration-driven, so missed VBL deadlines also slow the animation and movement.
Blit counts count sprite calls, not individual hardware starts.
