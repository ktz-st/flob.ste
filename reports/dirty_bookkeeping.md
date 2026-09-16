# Simplified dirty sprite bookkeeping

2026-09-11. Enabled in the normal build, using EMS and geometric restore
records with the line-offset table. EMX, SIMPLE_RESTORE and PREPARED_RESTORE
remain optional, disabled by default.

## Changes

- Append independent dirty rectangles instead of repeated global merge scans.
- For animation-only changes with identical bounds, restore one rectangle,
  not separately inserted old and new rectangles.
- Mark changed queue entries while matching stable IDs. Draw them without
  searching for intersections that are already known to exist.
- Propagate redraw through unchanged overlapping sprites. Each selected sprite
  contributes its entire bounds to restoration; repeat until no new sprite
  is selected. This preserves layering when a redraw extends outside the
  initial dirty region. Original draw order is unchanged.
- Address each queue record once when filling its fields.
- Copy the compact per-buffer history with one Move instead of one operation
  per sprite. The three buffers and their ownership are unchanged.

Only rectangle insertion is linear; overlap propagation still scans candidates
and is not claimed to be a linear-time algorithm in the worst case. The number
of records remains bounded by oldCount+newCount (at most 96), including removed,
moved and newly included unchanged sprites. Existing full-copy thresholds stay.
Moving sprites may now require separate old/new copies rather than a merged
copy; this trades some blitter work for lower CPU cost on animation bursts.

## Results

Hatari STE 68000 8 MHz, PAL 50 Hz, 512 renderer iterations per phase, both
buffers warmed, music callback active, host sound off. Physics, collision,
events, pickups and messages are excluded: NOT whole-game FPS.

| Workload | Previous bookkeeping | New default |
|---|---:|---:|
| W1 R13: 16 animated slime, stationary Flob | 40 FPS | 44.44 FPS |
| W1 R13: 16 animated slime, moving Flob | 40 FPS | 44.44 FPS |
| W1 R13: static slime / no slime | 50 FPS | 50 FPS |
| W0 R06: all six benchmark phases | 50 FPS previously | 50 FPS |

W1 R13 new path: three identical runs. Each animated phase takes 576 VBL
instead of 640: 448 frames take one VBL and 64 take two, not three. Thus the
long frames fall from 60 to 40 ms and throughput rises about 11.1%.
Still below 50 FPS; no movement or animation constants were altered.

A fresh --legacy-dirty comparison still gives 40 FPS; it retains the old
matching/merge/history algorithm but shares the new queue pointer writes.
W0 R06 was rerun once on the new path. Sprite draw counts in W1 R13 remain
1024 (stationary animated phase) and 1679 (moving animated phase); this is
not the slower redraw-everything experiment.

## Verification

python3 verify_gameplay.py passes:

- 4000 sprite-mask comparisons and 2000 dynamic hazard comparisons.
- Dynamic hazard accounting and removal.
- 80 full-buffer comparisons for moving, animated and removed sprites.
- 96 additional full-buffer comparisons with wide overlapping sprite chains,
  full 48-entry queues, empty frames and full-copy fallback.
- Falling-lever contact in both orientations and input regressions.

Every renderer comparison checks against a clean-background full redraw,
including pixels outside sprites, on alternating screen buffers.

```sh
python3 run_slime_benchmark.py --w1-r13 --runs 3
python3 run_slime_benchmark.py --w1-r13 --legacy-dirty --runs 1
python3 run_slime_benchmark.py --runs 1
python3 verify_gameplay.py
```

Raw benchmark reports end in _geometric_linear or _geometric_legacydirty.
The regression result is reports/gameplay_verification.txt.
