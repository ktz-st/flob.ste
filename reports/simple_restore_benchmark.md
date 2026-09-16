# Independent restore rectangles: measured alternative

2026-09-11. Implemented as the opt-in Free Pascal define SIMPLE_RESTORE.
Normal builds retain the merged dirty renderer because this alternative is
slower in W1 R13. This is an AGT-inspired scheduling experiment, not a port
of AGT's entire assembly entity/draw chain.

## Implementation

- Read previous sprite bounds belonging to the current backbuffer.
- Align/clip each restore rectangle independently, with no merge searches.
- Restore from SCREEN_BKG using the existing RestoreRectsASM batch.
- Redraw all current sprites in their existing queue order, without dirty
  intersection searches or old/new sprite equality tests.
- Retain per-buffer history, removal handling and explicit rectangle requests.
- Retain the existing full-copy safety threshold for large restore workloads.

Rectangles are still derived from Pascal sprite history each frame; this does
not implement AGT's precomputed low-level restore records or batched entity
drawing ABI. Therefore the result does not establish that AGT itself would be
slower. It tests the simpler scheduling strategy with our existing backend.

## Results

STE 8 MHz, PAL 50 Hz, Hatari, 512 iterations per phase, music callback running.
Controlled rendering workload, excluding physics, collision, events and text.
No gameplay speed or animation timing constants changed.

| Room / workload | Existing dirty renderer | Simple restore + redraw all |
|---|---:|---:|
| W1 R13, animated 16 slime + moving Flob | 40 FPS | 25 FPS |
| W1 R13, animated 16 slime + stationary Flob | 40 FPS | 25 FPS |
| W1 R13, static 16 slime | 50 FPS | 25 FPS |
| W0 R06, animated 6 slime + moving Flob | 50 FPS | 50 FPS |
| Either room, no slime | 50 FPS | 50 FPS |

W1 R13 simple mode: three identical runs. Every measured frame with slime
takes two VBL (40 ms), instead of the dirty renderer's 448 one-VBL and 64
three-VBL frames. The stalls are smoother but throughput is worse.

For W1 R13 moving/animated, sprite calls increase from 1679 to 8704 per 512
iterations (5.18x). For stationary/animated they increase from 1024 to 8704.
Every call uses EMS. W0 R06 moving/animated increases from 895 to 3584 calls,
but still fits the 50 Hz deadline. W0 R06 results are one run per renderer.

## Verification and reproduction

```sh
python3 run_slime_benchmark.py --w1-r13 --simple-restore --runs 3
python3 run_slime_benchmark.py --simple-restore --runs 1
python3 run_slime_benchmark.py --runs 1
python3 verify_gameplay.py --simple-restore
```

The simple-mode target regression passes 80 full-frame comparisons against
clean-background rendering across both buffers, including moving, animated,
overlapping and removed sprites. It also checks that removal restores all
four previous rectangles rather than the dirty renderer's one changed object.
The existing collision/input/falling-lever regressions pass as well.

Raw results: slime_w1_r13_ems_simple_run{1,2,3}.csv and
slime_r06_ems_simple_run1.csv. Reference results use the same names without
the _simple suffix. Tests use temporary PRGs and do not touch flob.sav.

## Decision

Keep SIMPLE_RESTORE available for experiments but disabled in the normal PRG.
Next candidate: retain change detection and skip unchanged slime, eliminate
duplicate old/new rectangles for animation-only changes, and draw changed
IDs without searching their dirty intersections. Test that hybrid separately;
do not assume it reaches 50 FPS before measuring it.
