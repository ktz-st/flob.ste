# W1 R13 performance investigation

2026-09-11. No gameplay optimization applied in this investigation.

## Reproduction

```sh
python3 run_slime_benchmark.py --w1-r13 --runs 3
python3 run_slime_benchmark.py --w1-r13 --profile --runs 1
```

Hatari headless, STE 68000 at 8 MHz, 4 MB, forced PAL 50 Hz, EmuTOS.
Temporary PRGs and save directories; the user's flob.sav is not used.
World 1 music callback runs, host audio output is disabled. Emulated VBL/HZ200
timing, not host wall-clock speed. Each phase measures 512 iterations after
warming both screen buffers. W1 R13 has 16 small slime and no world sprites.

This is a controlled renderer workload, NOT a full gameplay FPS measurement.
Flob moves through X=90..121 with fixed Y/frame. Gravity, collision, pickups,
messages and events are excluded from the six rendering phases. A separate
collision microbenchmark is described below. Flip animation is not measured.

## Results

All three baseline runs agree:

| Workload | Render throughput | Frames lasting 3 VBL / 512 |
|---|---:|---:|
| No slime, stationary or moving Flob | 50 FPS | 0 |
| 16 static slime, stationary or moving Flob | 50 FPS | 0 |
| 16 animated slime, stationary Flob | 40 FPS | 64 |
| 16 animated slime, moving Flob | 40 FPS | 64 |

Animated phases take 640 VBL for 512 iterations: 448 frames take one VBL;
the remaining 64 each take three. All slime change frame simultaneously every
16 game iterations. Each animation change needs repainting on both buffers.
Thus there are two expensive frames per change, not constant low throughput.
Iteration-driven motion and animation both slow down when those deadlines slip.

Stationary animated phase: 1024 sprite draws, all EMS; 1024 restored rectangles,
129024 restored pixels over the entire test. This is only 2016 restored pixels
per expensive update. There is no full-screen-restore fallback in this workload.
Moving animated phase: 1679 sprite draws, all EMS; 1495 rectangles, 413184 pixels.

## Cost breakdown

Separate instrumented build, phase 5, totals across 512 iterations:

| Section | HZ200 ticks | Approximate mean per iteration |
|---|---:|---:|
| Match sprite IDs, compare records, build/merge dirty rectangles | 808 | 7.89 ms |
| Restore background, including benchmark restore counters | 94 | 0.92 ms |
| Test dirty intersections and draw sprites | 455 | 4.44 ms |
| Store per-buffer sprite history | 161 | 1.57 ms |

The baseline queue/frame-preparation section costs 685 ticks, approximately
6.69 ms per iteration. This includes GameplayFrameTick, DrawSlimes, DrawFlob,
and ShowSprites, not just QueueGeneratedSprite. These are aggregate estimates:
HZ200 samples have 5 ms resolution, added instrumentation has overhead and
VBL callbacks can run during a timed section. Do not sum these figures from
different runs into an exact frame budget. The draw section includes CPU
intersection tests, so it is not an isolated measurement of EMS blitter speed.

Separate 4096-call CheckSlimeCollision test with Flob at (0,0), 16 slime,
no overlap or pickup: 2842 HZ200 ticks, approximately 3.47 ms per call.
This measures all distant candidates rejected by bounding boxes, not narrow
mask collisions or the cost of collecting a slime. Collision is already costly
even before actual overlap and is additional to the rendering phases above.

## Recommended next changes

1. Avoid adding the same old/new rectangle twice for animation-only changes.
   AddDirtySpriteRect currently inserts the old bounds and then identical new
   bounds, searching/merging the accumulated list and restarting the scan.
   Sixteen simultaneous changes amplify this CPU work.
2. Remember which stable IDs changed and redraw those directly. Only unchanged
   objects need SpriteIntersectsDirty searches to repair overlap. Preserve draw
   order and per-buffer history, and keep the full-render comparison tests.
3. Cache invariant slime queue data/positions per room and orientation instead
   of rebuilding all fields every iteration. Invalidate on flip and pickup.
4. Reject slime by vertical range (their positions come from fixed row slots)
   and X before calling the generic eight-argument GeneratedSpritesOverlap.
   Retain the existing exact mask intersection for nearby candidates.

Prioritize CPU bookkeeping and broad-phase collision, not another background
copy implementation. Do not change the shared slime animation phase merely to
spread load; that would alter the original presentation rather than optimize it.

Raw baseline data: slime_w1_r13_ems_run1.csv through run3.csv.
Instrumented data: slime_w1_r13_ems_profile_run1_profile.csv and
slime_w1_r13_ems_profile_run1_coll.txt. Instrumentation is conditional on
BENCH_PROFILE and absent from normal builds.
