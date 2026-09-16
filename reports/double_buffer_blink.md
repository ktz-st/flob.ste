# One-frame blink at the double-buffer page flip

Occasional single-frame picture corruption during gameplay, reported in W1 R13.

## Cause

`SwapScreen` points the shifter at the freshly rendered page through
`SetPhysicalScreen`, which writes the video base as three independent bytes:

```
move.b  %d1,-32255     ; $FFFF8201  bits 16-23
move.l  %d0,%d1        ;  4 cycles
lsr.l   #8,%d1         ; 24 cycles
move.b  %d1,-32253     ; $FFFF8203  bits 8-15
move.b  %d0,-32243     ; $FFFF820D  bits 0-7
```

The shifter reloads its address counter from these registers at the frame
boundary. That reload is not synchronised with the CPU, so a frame boundary
falling in the ~28 cycles between the `$8201` and `$8203` writes latches an
address built from the **new** high byte and the **old** middle byte, and one
whole frame is displayed from it. Both buffers are 256-byte aligned, so
`$820D` is always 0 and only these two bytes race.

With the measured layout (LOG `$193200`, PHY `$18b400`, BKG `$19b000`) the two
mixed addresses are:

* `$19b400` — inside `SCREEN_BKG`, offset `$400`: the room background shifted by
  6.4 lines, with no sprites and a shredded HUD.
* `$189300` — below every buffer: uninitialised memory.

`reports/blink_frame_373_normal.png` and `reports/blink_frame_374_corrupt.png`
are consecutive emulated frames from one capture; the second is the `$19b400`
case.

## Why it is intermittent, and why in a heavy room

The write happens immediately before `VSync`, so its phase inside the frame
equals the render time. It can only meet the reload when the per-frame work sits
around 100% of the PAL budget. Profiling W1 R13: mean work **72%** of the
160,000-cycle budget, but **1.13 VBL per frame** (44.4 FPS) — a tail of frames
crosses the boundary every second, and any of those can land in the 28-cycle
window. That is roughly 1 frame in 5,700, about one blink every two minutes.

In a room that stays well inside the budget (W0 R06: 53%, a steady 50 FPS) the
write never approaches the boundary and the blink cannot occur. This is why it
looks random and room-dependent.

## Evidence

`SetPhysicalScreen` was instrumented under `{$ifdef PROBE_FLIP}` to compare the
`$466` VBL counter before and after the three writes, counting how often the
write straddles a frame boundary. `{$ifdef PROBE_FLIP_WIDEN}` widens the window
from 28 cycles to about 6,000, which turns a two-minute wait into a per-second
event without changing the mechanism.

Every emulated frame was recorded to AVI and scanned for frames differing from
**both** neighbours (a one-frame anomaly, as opposed to the flip animation,
which changes progressively).

| Build | Room | Page flips | Straddled a boundary | Corrupted frames |
|---|---|---:|---:|---:|
| unmodified | W1 R13, moving | 1,443 | 0 | 0 of ~7,000 |
| unmodified | W0 R11, idle | 1,711 | 8 (0.47%) | 0 of 2,336 |
| widened window | W1 R13, moving | 2,124 | 75 (3.53%) | **75** |
| widened window | W0 R11, idle | 1,309 | 555 (42.4%) | **~1,200 of 2,337** |
| widened window **+ SAFE_FLIP_ALIGN** | W0 R11, idle | 1,308 | 531 (40.6%) | **0** |

Two things are settled by this.

**The mechanism is real.** In the widened W1 R13 run, seventy-five straddles
produced seventy-five corrupted frames, one to one. In the widened W0 R11 run
the write sits so close to the boundary that 42% of page flips straddle it and
the median frame-to-frame difference rises to 24.5, i.e. roughly every other
frame is wrong.

**The fix removes it.** With both buffers in one 64 KB page the write still
straddles a frame boundary 531 times out of 1,308 — the same exposure — and not
one frame is corrupted, because only `$8203` changes and a single `move.b`
cannot be latched half-done.

**What is not settled:** the natural 28-cycle window was never observed to fire.
Across roughly 9,400 recorded frames with the unmodified code, zero frames were
corrupted, even though the probe shows the write does land on a frame boundary
(8 times in 40 s in W0 R11). A straddle is necessary but not sufficient: the
shifter's reload happens at a fixed instant that the 28-cycle gap only sometimes
covers, whereas the 6,000-cycle gap covers it every time. So the defect is
proven to exist and proven to be fixable, but it has not been caught producing a
blink at its natural rate. Whether it is the blink seen in play has to be
settled by playing the fixed build.

## Frame budget and why the rate changes

The write's phase inside the frame equals the render time, so the exposure
depends on how much of the per-frame work distribution sits near a VBL boundary.
The renderer optimisations moved that distribution:

| Room | Work/frame before | after |
|---|---:|---:|
| W0 R11, idle | 107% of budget | 92% |
| W0 R11, moving | 116% | 105% |
| W1 R13, idle | — | 72% (but 1.13 VBL/frame) |

W0 R11 at 92% with a spread that crosses 100% keeps the write near the boundary
constantly, which is why the widened probe straddles 42% of the time there and
only 3.5% in W1 R13. The defect is old; the optimisation changed how often the
write meets the boundary.

## Fix applied: the shifter is programmed from the VBL queue

`SetPhysicalScreen` no longer touches the hardware. It stores the address in
`pendingScreen`, and `VblSetScreen` — installed into the TOS VBL queue
(`$454` / `$456`) by `ScreenInit` and removed by `ScreenDone` — programs the
shifter from inside the vertical blank, where no display is being fetched and
the byte writes cannot be split.

It writes the **video counter** (`$FFFF8205/07/09`) as well as the base
(`$FFFF8201/03/0D`). That is the part that matters for latency: the ST reloads
the counter from the base near the end of the previous frame, *before* the VBL
interrupt, so programming only the base from a VBL routine would take effect one
frame late and leave the game rendering into a page still on screen. Forcing the
counter makes the new page current for the frame that is starting. This is the
idiom AGTools' STE display service uses (`agtools/agtsys/m68k/ste/display.s`).

If the VBL queue has no free slot, `vblSlot` stays -1 and `SetPhysicalScreen`
falls back to writing the registers directly, as before.

| Build | Room | Page flips | Rate | Corrupted frames |
|---|---|---:|---:|---:|
| unmodified | W0 R11, idle | 1,711 | 42.8/s | 0 of 2,336 |
| **VBL queue** | W0 R11, idle | 1,700 | 42.5/s | **0 of 2,337** |

Same frame rate, so the change costs nothing and adds no latency; peak
frame-to-frame difference is 0.342 against the baseline's 0.341, i.e. no tearing
was introduced. Enabled by default through `-dSAFE_FLIP_VBL` in `PFLAGS`.
Regression suites pass: `verify_gameplay.py` (all 13 checks), `verify_ems.py`,
`verify_score.py`, `test_sprite_palette_roles`.

The `SAFE_FLIP_ALIGN` variant — both buffers in one 64 KB page so only `$8203`
changes — remains in the source as an alternative; it also measured zero
corrupted frames against 531 straddles, but costs about 64 KB of RAM.
