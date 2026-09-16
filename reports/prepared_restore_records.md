# Prepared background restore records

2026-09-11. Implemented and tested, opt-in PREPARED_RESTORE.
Not enabled by default: checking the cached merged rectangles costs more than
the saved address/parameter arithmetic in the measured workload.

## Implementation

Each packed entry is 22 bytes: original rectangle (8 bytes), source address,
destination address, Y increment, X count, Y count. A cache has an eight-byte
source/destination base header and 96 entries. Two independent caches are
associated with the two screen indices (4240 bytes total).

PrepareRestoreRectsASM compares final merged geometry against each saved slot.
It reuses unchanged entries and rebuilds changed ones using the line-offset
table, not MULU. A changed source or destination base invalidates all entries
being used. Geometry/content changes in BKG require no address invalidation:
the copy always reads live pixels from the cached source address.

RestorePreparedASM only loads precomputed register values and starts each
blit. Count zero is a no-op. Source/destination addresses are never modified
in the cache by the blitter. All longword fields are at even addresses, valid
for 68000. Existing full-copy fallback bypasses the cache safely.

No dirty merging, sprite draw order, palette, movement or collision behavior
was changed. The prior geometric restore path remains the default, including
the line-offset table optimization from the previous change.

## Target validation

verify_restore.py passes 400 whole-screen comparisons against the independent
Pascal/blitter reference, for both the geometric and prepared routines.
It exercises zero/max counts, changed rectangles, repeated cache hits, and
explicit source and destination base changes with identical geometry.

Gameplay verification passes 80 full-frame comparisons on both buffers,
including overlapping, moving, animated and removed sprites. Both dirty and
SIMPLE_RESTORE variants were tested with the prepared path. Existing collision,
input and falling-lever regression tests pass as well.

## Timing

One target run: 32000 small rectangles, Hatari STE 8 MHz, HZ200 ticks.

| Path | Ticks | Total |
|---|---:|---:|
| Geometric ASM with line table | 1040 | 5200 ms |
| Prepared copy only (preparation outside timing) | 977 | 4885 ms |
| Prepared, including cache checks on every batch | 1110 | 5550 ms |
| Prepared, including rebuilding all entries every batch | 1202 | 6010 ms |

The copy loop alone takes 6.1% less time. Including checks, unchanged batches
take 6.7% more time; rebuilding all entries takes 15.6% more. Do not report the
copy-only result as a gameplay optimization. The benchmark includes its loop
and call overhead; 5 ms clock resolution makes figures approximate.

W1 R13, one run per path: both have 40 FPS for animated slime, 448 one-VBL
frames and 64 three-VBL frames per 512 iterations. W0 R06 prepared path stays
at 50 FPS. These are controlled render tests, excluding gameplay physics,
collision, events and messages.

## Reproduction

```sh
python3 verify_restore.py
python3 verify_gameplay.py --prepared-restore
python3 verify_gameplay.py --prepared-restore --simple-restore
python3 run_slime_benchmark.py --w1-r13 --prepared-restore --runs 1
python3 run_slime_benchmark.py --w1-r13 --runs 1
```

Records are built after merging because merged bounds differ from individual
sprite bounds. To get the benefit without the measured checking overhead,
future work should produce/invalidate prepared records directly where geometry
changes become known. Caching another copy of the final list is not enough.
