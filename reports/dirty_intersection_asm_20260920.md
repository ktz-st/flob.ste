# Dirty intersection ASM, 2026-09-20

SpriteIntersectsDirty now uses inline 68000 assembly. It keeps sprite edges
in registers and walks eight-byte dirty rectangles without stack-local loop
variables. The existing new-suffix expansion algorithm is unchanged.

ABI: cdecl, sprite pointer, const-array address, 32-bit count and first index;
boolean result in D0. D2-D7 are preserved. Coordinates and dimensions are
unsigned words but edge sums/comparisons use longs, preserving Pascal behavior
when sums exceed 65535. Callers supply count <= MAX_DIRTY_RECTS (96).
The production routine is 124 bytes in the inspected disassembly.

PASCAL_DIRTY_INTERSECTIONS selects the previous implementation for benchmark
controls. VERIFY_GAMEPLAY instead keeps it as a reference and tests ASM.
These two test modes are used separately.

## Validation

- Production make succeeds; git diff --check passes.
- VERIFY_GAMEPLAY with SAFE_FLIP_VBL and STAGGER_SLIME passes all tests.
- Added 4,000 ASM/Pascal intersection comparisons, using 125 random rectangle
  lists and differing sprites/ranges. Includes nil sprites, empty/exhausted
  ranges, zero dimensions, screen and full-word coordinates and overflowing
  word-sized edge sums. Existing full-framebuffer comparisons cover both pages,
  reversed overlap chains, disappearance, full queues and Flob foreground order.
- Initial test regenerated a full random list for every probe and exhausted
  the harness's 90,000 VBL run cap before reporting. Reusing each list for 32
  probes reduced RNG overhead; all 4,000 comparisons and the full suite passed.

## Measurements

STE 68000 8 MHz, PAL, production SAFE_FLIP_VBL + STAGGER_SLIME, alternating
LEFT/RIGHT, requested 10 seconds. Same death suppression as previous room
profiles. Single windows with wall-clock input, not deterministic frame replay.

| Scenario | Pascal FPS | ASM FPS | Pascal work/frame | ASM work/frame |
|---|---:|---:|---:|---:|
| W0 R11, previous moving fixture | 45.46 | 46.61 | 127,475 | 124,924 |
| W1 R13, X=80 after room load | 49.18 | 49.59 | 84,534 | 86,536 |

Work excludes VSync instructions, not interrupts or blitter stalls.
W0 R11 saves about 2.0% work and gains 2.5% FPS in these windows.
Intersection cost: 14,285 -> 10,182 cycles/frame (-28.7%). RenderQueuedSprites
exclusive cost rises from 26,481 to 27,803; cdecl call setup/register allocation
offsets some of the isolated function saving.

W1 R13 is not a demonstrated whole-loop win: intersection cost falls from
2,346 to 1,481 cycles/frame, but total work rises 2.4%. RenderQueuedSprites
cost rises from 21,006 to 22,397. Counts/animation phases also differ: 594 vs
601 iterations, 319 vs 326 FlobMove calls, 1,108 vs 1,230 intersection calls.
The slight FPS gain alone is insufficient to claim a net improvement there.

Two original-start ASM trials left W1 R13 and were rejected. A new --start-x
fixture was added; setting X before room load also proved unreliable for the
Pascal control. The final paired runs set X=80 AFTER loading and settling the
room. They must not be compared to the older W1 R13 moving captures.
One successful earlier ASM capture with X set before load is retained as
profile_20260920_w1_r13_move_center_asm.json, but excluded from the paired table.

profile_room.py now records defines, start_x and start_x_phase in its JSON.
Failed room assertions do not emit a capture. All runs use separate temporary
PRGs and saves; the user's game save was not modified.

## Artifacts

- Before R11: profile_20260919_w0_r11_move_suffix.json
- After R11: profile_20260920_w0_r11_move_asm.json
- Paired R13: profile_20260920_w1_r13_move_center_loaded_pascal.json and
  profile_20260920_w1_r13_move_center_loaded_asm.json
- Tests: gameplay_dirty_asm_verification.txt
- Screenshots: profile_shots/grab0034.png, grab0036.png, grab0037.png

Next experiment: avoid cdecl stack argument setup using a verified FPC register
ABI, then repeat matched movement scenarios. Do not assume isolated routine
savings translate directly into FPS. No commit made.
