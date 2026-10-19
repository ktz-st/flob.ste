# Flob STE: production-configuration profiling, 2026-09-19

Baseline source: commit `7d61b80`. The follow-up optimization is recorded below.
Read the current renderer, VBL swap, collision rejection, documentation and
previous measurement reports before running these captures.

## Method and limitations

- `profile_room.py`, separate temporary unstripped PRG and game save directory.
- Explicit `--define SAFE_FLIP_VBL --define STAGGER_SLIME`: the script does NOT
  inherit these production defaults from Makefile. Omitting them tests another build.
- STE, 68000 at 8 MHz, 4 MB, EmuTOS, PAL 50 Hz; host audio output disabled.
  Game PSG/VBL processing remains active and appears in the profile.
- Raw hrdb protocol: break -> profile 1 -> run -> break. Nonempty cycle captures
  include their own build's symbol table; no stale-map attribution.
- Four single windows, requested duration 10 s. Actual profiled emulated duration
  is 10.657 s idle and 12.119 s moving, calculated from cycles. Control-command
  overhead means the requested wall-clock duration is not the measured duration.
- FPS = SwapScreen entry count / (total cycles / 8,000,000). Work excludes only
  VSync's own instructions, NOT interrupts, ROM or blitter stalls. It is not a
  distribution of individual frame times or proof of hardware performance.
- Explode is replaced with RTS in the temporary test PRG to keep the capture
  inside the requested room. Physics, input, hazard and pickup checks still run.
  This does not measure death sequences or natural entry into every room.
- Moving W0 R11 executes FlobMove 286 times; its idle control executes it zero
  times. Both runs remain in the requested room. Keyboard input is supported by
  this game; this is not an assumption about keyboard-to-joystick translation.
- One initial W0 R11 capture without the two release defines is retained as
  `profile_20260919_w0_r11_idle.json`, but excluded from production results.

## Results

| Scenario | Frames | FPS | Work cycles/frame | PAL work budget | Previous optimized FPS |
|---|---:|---:|---:|---:|---:|
| W0 R06, idle | 532 | 49.9 | 62,285 | 39% | n/a |
| W0 R11, idle | 496 | 46.5 | 116,675 | 73% | 46.8 |
| W0 R11, moving | 536 | 44.2 | 133,217 | 83% | 44.2 |
| W1 R13, idle | 530 | 49.7 | 82,128 | 51% | 49.7 |

Previous optimized numbers are the historical `*_aabb.json` captures, not the
earlier files named `*_final.json`. No old revision was rebuilt this session.
Compared with the historical pre-optimization captures, W0 R11 goes from
32.9 -> 46.5 FPS idle and 29.5 -> 44.2 moving; W1 R13 from 44.4 -> 49.7.
That corresponds to about 28-31% less work per game iteration in these scenarios.
These fresh results reproduce the previously recorded gains, not a new speedup.

## Where the time goes

W0 R11 moving, percentages of work excluding VSync (exclusive per-symbol costs):

| Area | Cycles/frame | Work share |
|---|---:|---:|
| RenderQueuedSprites | 26,371 | 19.8% |
| SpriteIntersectsDirty | 18,876 | 14.2% |
| QueueGeneratedSprite | 9,615 | 7.2% |
| DrawSlimes | 9,173 | 6.9% |
| DrawOccludedFlob | 7,298 | 5.5% |
| CheckSlimeCollision | 7,165 | 5.4% |
| restore.o | 3,602 | 2.7% |

The dirty-rectangle decision/queue cost is still the first target, not another
background-copy rewrite. DrawOccludedFlob contains mask preparation and its
called EMS work is attributed separately. Similarly, Pascal sprite dispatch
does not include all of the EMS/IMS assembler cost. Blitter HOG stalls are
charged to the instruction starting the blit; they are not pure CPU work.

Disassembly/cycle inspection of RenderQueuedSprites points to repeated index
masking, slot indexing, loads and intersection dispatch in the expansion pass.
Previously rejected inline/local-cache variants must not be assumed faster.

New concrete candidate: W0 R06 calls fpc_mul_longint about nine times per frame
from NarrowFlobDynamicDanger's `sourceY * 20`. The helper delegates to
fpc_mul_dword, which costs about 4,190 cycles/frame (6.7% of work, 2.6% of the
PAL budget, including occasional other callers). NarrowFlobDynamicDanger's own
exclusive cost is 6,639 cycles/frame. Confirmed in `flob.o` disassembly at
routine offset +$10A. A shift/add or incremental row pointer is worth an A/B
test, with existing per-pixel danger regression checks. R06 already meets 50 Hz,
so savings there may increase headroom rather than FPS.

## Artifacts

- `profile_20260919_details.md`: full per-symbol tables for all four scenarios.
- `profile_20260919_*_release.json`: raw captures and per-build symbols.
- `profile_shots/grab0025.png` through `grab0028.png`: room snapshots.
- `flobsym.map`: refreshed linker map from the measurement build.

## Follow-up: dynamic danger row addressing

Replaced `sourceY * 20` in `NarrowFlobDynamicDanger` with
`(sourceY shl 4) + (sourceY shl 2)`. Row indices are 0..79, so the
calculation is exact and stays within a word. No collision geometry changed.
Disassembly confirms two shifts/addition instead of `fpc_mul_longint` and its
software multiplication helper. The function also needs four fewer stack bytes.

Same production defines and W0 R06 idle procedure as the baseline:

| Measurement | Before | After |
|---|---:|---:|
| Frames | 532 | 532 |
| FPS | 49.92 | 49.92 |
| Work cycles/frame excluding VSync | 62,285 | 57,737 |
| NarrowFlobDynamicDanger, exclusive cycles/frame | 6,639 | 6,866 |
| fpc_mul_longint, cycles/frame | 577 | 0 |
| fpc_mul_dword, cycles/frame, all callers | 4,190 | 56 |

Net saving: 4,549 work cycles/frame, 7.3% of previous work or about
0.57 ms at 8 MHz. The routine's exclusive cost rises slightly because the
arithmetic is now inline; the removed helper cost more than compensates.
R06 was already at the PAL limit, so this improves headroom, not measured FPS.
These are single measurement windows, not a universal game-wide speedup.

Validation: production build succeeds; `VERIFY_GAMEPLAY` with SAFE_FLIP_VBL
and STAGGER_SLIME passes all checks, including 2,000 dynamic danger comparisons
in both orientations and at edges, 4,000 mask comparisons, dirty rendering,
Flob occlusion, slime animation, lever contact, pickups and input checks.

Artifacts: `profile_20260919_w0_r06_idle_shift.json`,
`profile_shots/grab0029.png`, `gameplay_shift_verification.txt`.
Production `flob.prg` rebuilt. No commit was made.

## Follow-up: W0 R11 and W1 R13 moving

Measured the shift/add build with both production defines, using the same
`--move --seconds 10` alternating LEFT/RIGHT input as the earlier R11 control.
Actual capture durations were 12.119 s and 12.099 s. Each is a single window;
death suppression and the other methodology limitations above still apply.
Room assertions passed. FlobMove executed 290 times in W0 R11 and 308 in
W1 R13, confirming that these are moving rather than idle captures.

| Room | Frames | FPS | Work cycles/frame, excluding VSync |
|---|---:|---:|---:|
| W0 R11 moving, before shift/add | 536 | 44.23 | 133,217 |
| W0 R11 moving, after shift/add | 539 | 44.47 | 132,823 |
| W1 R13 moving, after shift/add | 578 | 47.77 | 101,348 |

NarrowFlobDynamicDanger was not executed in either new capture. The small R11
difference must therefore not be credited to the arithmetic change; input
timing and animation phase can vary between runs. W1 R13 has no fresh moving
pre-change control; the 49.7 FPS / 82,128 cycles idle result is a different
workload, not an optimization baseline.

RenderQueuedSprites + SpriteIntersectsDirty + QueueGeneratedSprite account
for about 41.1% of work in moving R11 and 38.2% in moving R13 (exclusive
symbol costs). Background restoration is only 2.7% / 2.4%, respectively.
These captures support prioritizing queue/dirty-region bookkeeping next.

Raw profiles: `profile_20260919_w0_r11_move_shift.json` and
`profile_20260919_w1_r13_move_shift.json`. Full tables:
`profile_20260919_moving_details.md`. Screenshots: `grab0030.png`, `grab0031.png`
in `profile_shots`. No further game code changes were made for these runs.

## Optimization: scan only newly appended dirty rectangles

The overlap-expansion loop now remembers the dirty-rectangle prefix checked
in the previous pass. Unchanged sprites rejected that prefix already, and
rectangles only append in this non-legacy path. Further passes therefore scan
only the new suffix. Rectangles appended during the current pass remain visible
to subsequent sprites, and another pass propagates them to earlier sprites.
Changed sprites, rendering order and the restore implementation are unchanged.
The legacy path retains a default first rectangle of zero.

Production flags, same alternating movement procedure, single windows:

| Room | FPS before | FPS after | Work/frame before | Work/frame after |
|---|---:|---:|---:|---:|
| W0 R11 | 44.47 | 45.46 | 132,823 | 127,475 |
| W1 R13 | 47.77 | 47.70 | 101,348 | 101,095 |

R11 work drops about 4.0%; SpriteIntersectsDirty drops from 18,640 to
14,285 cycles/frame (23.4%). R13 is effectively unchanged: intersection cost
6,337 -> 6,378 cycles/frame. Small differences are not significant given the
wall-clock input delivery and animation phases; this is not an exact replay.
After captures contain 550 / 580 game iterations respectively.

VERIFY_GAMEPLAY passes all tests. The overlap-chain test now also reverses
spatial order relative to queue order to exercise propagation back to earlier
entries. It compares complete framebuffers against full redraw on both pages,
including empty frames and full queues. Production build and diff check pass.

Artifacts: `profile_20260919_w0_r11_move_suffix.json`,
`profile_20260919_w1_r13_move_suffix.json`,
`gameplay_dirty_suffix_verification.txt`, and screenshots
`profile_shots/grab0032.png` / `grab0033.png`.
