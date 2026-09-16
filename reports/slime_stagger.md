# Staggered Slime Animation

2026-09-12. Optional `STAGGER_SLIME`; disabled in normal builds.

Even slime IDs retain the original animation phase. Odd IDs change one game tick
later. Every slime still changes frame once per 16 ticks; no required drawing or
background restore is skipped. Collision reads the last queued frame separately
for each slime, not a shared global animation frame. Counter wrap is handled.

## Result

Controlled W1 R13 renderer benchmark, STE 8 MHz PAL 50 Hz, 16 slime, EMS,
music callback enabled. Three runs per variant, 512 iterations per phase.
Both buffers are warmed at sysframe zero before measurements. Physics, pickups,
NPC logic and messages are excluded; these are not full-game FPS measurements.

| Animated slime workload | Synchronized | Odd IDs delayed one tick |
|---|---:|---:|
| Stationary Flob | 44.52 FPS | 42.11 FPS |
| Moving Flob | 44.52 FPS | 42.11 FPS |
| Two-VBL iterations / 512 | 63 | 96 |

The synchronized result differs slightly from the earlier 44.44 FPS baseline
because warm-up now fixes the initial animation phase. The 512-iteration window
ends after only one page has received its final synchronized animation change.

The split is slower with this double-buffer renderer. A changed frame must reach
both pages: the first iteration updates even IDs on one page, the second updates
both groups on the other page, and the third updates odd IDs on the first page.
The reduced-load iterations still miss a single-VBL deadline in this workload,
so there are three delayed iterations rather than two per animation change.

All non-animated phases stay at 50 FPS. The experiment is therefore retained only
behind a define, not enabled as an optimization. No movement/animation-rate
constants have been changed.

## Reproduction And Validation

```sh
python3 run_slime_benchmark.py --w1-r13 --runs 3
python3 run_slime_benchmark.py --w1-r13 --stagger --runs 3
python3 verify_gameplay.py --stagger
```

Regression passes include 128 extra slime animation framebuffer comparisons,
both pages/orientations, sysframe wrap, queued frames and collision-frame
selection. Existing overlap, Flob foreground, collision and input tests pass.

Raw results: `slime_w1_r13_ems_stagger_geometric_linear_run*.csv` and
`gameplay_stagger_verification.txt`.

## Reversed by a full-loop measurement (2026-09-16)

The table above is a *controlled renderer* benchmark: every frame does the same
drawing work, so spreading one animation change over three iterations instead of
two is simply more work, and FPS falls. The production loop is not like that —
most frames redraw only a sprite or two and finish well inside the VBL, so the
question is not total work but whether the peak frame fits.

Profiled with `profile_room.py` on the real gameplay loop in W1 R13:

| | Synchronized | Odd IDs delayed one tick |
|---|---:|---:|
| FPS | 44.3 | **46.7** |
| Work/frame | 98,399 (61% of budget) | 100,199 (63%) |
| Cycles/frame incl. VSync | 180,538 | 171,373 |

Work per frame goes *up* 1.8% and the frame rate goes up with it — only possible
if the same work is spread more evenly and fewer frames miss the VBL. W1 R13
averages 61% of the budget and redraws 1.9 sprites on a typical frame; the loss
was entirely the two consecutive frames (one per screen page) where all 16 slime
change frame at once. 2 of every 16 frames is 12.5%, and the capture shows ~13%
of frames taking two VBLs.

The same switch measured slightly *negative* in W0 R11 (43.9 -> 43.6 FPS, work
+1.6%): that room averages 81% of the budget with the load spread evenly across
its 16 sprites, so there is no peak to flatten and the extra work just costs.

Enabled in normal builds from 2026-09-16 (`-dSTAGGER_SLIME` in `PFLAGS`) on the
strength of the W1 R13 result. It shifts odd slime one tick out of phase with
the original 8-bit animation; that was accepted deliberately. Validated with
`python3 verify_gameplay.py --stagger` (all 13 checks).
