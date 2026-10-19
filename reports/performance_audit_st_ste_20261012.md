# Flob ST / STE performance audit, 2026-10-12

Analysis only. Production Pascal, assembly, assets, PRGs and save were not
modified. Measurements compiled temporary copies of the current source.

## New measurements

Used `benchmark_slime.inc`, 512 iterations per phase, on headless Hatari:
68000, 8 MHz, 4 MB, PAL 50 Hz, configured TOS (no override), music callback
enabled, host audio disabled. ST explicitly disables the blitter; STE uses
the detected blitter. Build flags include SAFE_FLIP_VBL and STAGGER_SLIME.
The temporary benchmark changes W0's room from 6 to 11; W1 uses its existing
BENCH_W1_R13 fixture. Both display pages are warmed before counting.

This is a controlled renderer workload: moving Flob traverses logical X=90..121
at fixed Y/frame, and slime animation follows sysframe. Physics, pickup,
moving NPC logic, room triggers and messages are excluded. These numbers
must not be described as whole-game FPS. The basic benchmark has counters;
the separate BENCH_PROFILE build additionally times render stages.

| Moving Flob + animated slime | ST | STE |
| --- | ---: | ---: |
| W0 R11, FPS | 42.74 | 50.00 |
| W0 R11, two-VBL iterations / 512 | 87 | 0 |
| W1 R13, FPS | 42.17 | 50.00 |
| W1 R13, two-VBL iterations / 512 | 95 | 0 |

No iteration in this phase took three VBLs. Baseline and instrumented runs
had identical FPS and sprite/restore counts in each machine/room pair.
Each configuration was measured once per build, not a statistical series.

W1 R13 stage timings, accumulated over 512 iterations, in 200 Hz ticks:

| Stage | ST | STE |
| --- | ---: | ---: |
| Queue construction, including normal per-frame setup | 325 | 285 |
| Dirty bookkeeping / overlap propagation | 421 | 430 |
| Restore | 139 | 62 |
| Sprite drawing, including wrappers and Flob occlusion | 758 | 359 |
| History exchange | 1 | 6 |

One tick is 5 ms. Fine-grained stage boundaries are quantized; compare large
aggregates, not individual tiny counters. Within the four timed render stages,
ST spends about 57% drawing, 32% bookkeeping, 11% restoring; STE about 42%,
50%, 7%. Queue construction is additional to those percentages.

Even the no-slime, moving-Flob phase spends 476 ST vs 230 STE ticks drawing
over 512 frames in W1 R13. Optimizing slime alone misses a large part of
the CPU rendering cost.

The separate no-contact collision microbenchmark takes 730/733 ticks for
4096 CheckSlimeCollision calls on ST/STE, about 0.89 ms/call. It exercises
bounding-box rejection, not overlapping masks or pickup. Slime row selection
could remove most of this scan before its narrow collision test.

## Ranked candidates

1. **ST: specialize DrawSpriteCPU for one source word (Flob and slime).**
   `asm/render_cpu.s:256` supports arbitrary widths, so every destination
   group/plane repeats source-boundary tests, previous-word construction and
   shifts. Dispatch once to aligned, one-destination-word and two-word cases;
   unroll the four planes, hoist row increments, and skip zero-opacity groups.
   The generic path stays for wide objects. This should reduce the dominant
   ST cost with little data growth. No speedup is claimed before A/B testing.

2. **Both: move Flob foreground-mask preparation into a small ASM kernel.**
   `flob.pas:2070`, DrawOccludedFlob, walks each row and destination word in
   Pascal, computing `(plane0 xor plane1) and not (plane2 or plane3)` and
   intersecting the EMS mask. Row clipping and one/two-word selection can be
   resolved outside the hot loop. Preserve exact indices 1/2, explicit opacity
   and screen-edge behavior. Its 800-byte stack array can also be reduced for
   the known 16-row format, but that is mainly stack saving, not proven FPS.

3. **Both, especially STE: reduce per-frame slime queue/bookkeeping work.**
   DrawSlimes recomputes positions and writes descriptors for every active
   slime; RenderQueuedSprites then rematches them and compares page history.
   Cache room/orientation-derived positions and batch descriptor generation,
   then consider stable-ID indexing or a smaller comparison record. Palette
   fields palBase/palSlot remain compared despite being invariant in normal
   queue construction. Preserve complete per-page live lists: simply omitting
   unchanged sprites would be interpreted as deletion. Preserve overlap-chain
   propagation and Flob foreground ordering. Historical SIMPLE_RESTORE trials
   are not evidence that restoring/redrawing everything is faster.

4. **STE: use the already-tested MirrorPlayfieldCPU for BKG reversal.**
   `flob.pas:894` selects that kernel only when useBlitter=false; STE still
   performs three Move calls per row pair. Earlier forced-CPU STE measurements
   were 1886 -> 236 ticks for 64 mirrors, approximately 8x for this operation.
   Applying the same kernel to STE is a small, concrete candidate, with proper
   synchronization against any outstanding blit. It improves transitions,
   not ordinary gameplay. The final flip also recopies the full physical
   playfield although the last expansion frame has already drawn it; a
   narrowly scoped rebuild option could avoid that redundant copy.

5. **ST: revisit the existing preshifted slime experiment.**
   `generated/slime_cpu.s` has straight-line AND/OR code and ~7240 bytes of
   code/data/table. The earlier STE experiment measured ~30% lower isolated
   draw time than EMS but no room-FPS gain. That does not establish its benefit
   over today's generic ST renderer. It currently reads the blitter busy
   register, and the ST dispatcher exits before SLIME_CPU dispatch: enabling
   its flag alone is insufficient and unsafe on a machine without a blitter.
   Adapt and benchmark after the narrow CPU path; avoid adding large Flob
   preshift tables until the smaller specialization has been measured.

## Smaller candidates / lower priority

- CheckSlimeCollision scans all 20 row slots. Slime Y is derived from its slot,
  so Flob's vertical bounds can select only the few potentially overlapping
  rows, accounting for flip and crop offsets. Preserve the pixel mask test.
- ShowSprites regenerates sprite palette entries on every frame, even when
  frames/invulnerability are unchanged; PresentQueuedSprites reads registers
  4..12 after every swap. Cache the inputs and update affected colors on change,
  invalidating correctly after fades, reveal, room load and invulnerability.
  This is a smaller candidate; the renderer benchmark omits the main-loop
  PresentQueuedSprites palette tail and cannot quantify its saving.
- CPU RestoreRectsCPU has a generic row copier. Specialized 8/16-byte row
  widths could help small rectangles, but current restore is only ~11% of ST
  render stages and ~7% of STE. It is behind sprites and bookkeeping.
- Full-copy fallback currently copies all 32000 bytes. Restricting it to the
  playfield needs proof that the dirty list contains no out-of-playfield
  effects; HUD/message correctness takes precedence over this rare saving.
- HUD and message are already cached/event driven. FindSteTile is mainly a
  room-load/tile-update cost. Broad replacement of every division is not a
  priority: many are constants or occur outside gameplay hot paths.
- The active sound path is PSG assembly. Optimizing the dormant DMA synthesis
  fallback would not improve the current game.

## Follow-up measurement

Fresh measurements above are renderer-only. Existing whole-loop hrdb captures
from September support the bookkeeping priority on STE but must remain labeled
historical. Before new ST/STE whole-loop comparisons, profile_room.py needs an
explicit machine selection, optional TOS (currently forced EmuTOS), render_cpu.o
build dependency and production defines. profile_report.py's hardcoded TEXT_END
also needs replacing with the measured binary's text size to attribute new CPU
assembly safely. Do not attach an old map to a new binary.

Recommended first implementation: narrow ST CPU sprite kernel, shared Flob
occlusion kernel, then STE mirror reuse. Next, optimize slime bookkeeping and
collision candidate selection while retaining both-page framebuffer tests.

## Artifacts

- `audit_20261012_render_baseline.json`: baseline counters/FPS, both rooms/machines.
- `audit_20261012_render.json`: separate instrumented runs.
- `audit_20261012_{st,ste}_w{0,1}_r{11,13}_*.csv` and matching logs/collision text.
- Temporary runner `/tmp/flob_audit_20261012.py`; no emulator control socket or
  user save was used. It copies source/includes into a temporary directory,
  compiles there, runs without a TOS override, and retains output in reports.
