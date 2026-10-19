# Paired sprite equality, 2026-09-20

QueuedSpritesEqual remains Pascal inline. It compares adjacent x/y and
widthPx/heightPx words as two LongWords, then the same three pointers and
palSlot as before. stableId and reserved bytes remain excluded. No whole-record
memcmp and no new assembler call overhead. Word alignment is sufficient for
68000 long accesses; the test asserts the required record offsets.

Disassembly confirms two long comparisons instead of four word comparisons.
FPC still emits address setup for the dimension pair; this is a small change,
not a wholesale equality/renderer rewrite. RenderQueuedSprites code shrinks
another 12 bytes (1026 -> 1014).

## Validation

VERIFY_GAMEPLAY adds 4,096 comparisons against the original Pascal function:
16 base byte patterns, every bit of every record byte toggled independently.
All significant fields must make the records unequal; ID/padding differences
must not. Pointer bit patterns are only compared, never dereferenced. Identical
records are checked too. The complete existing regression suite also passes.
See gameplay_paired_equal_verification.txt. Production build and diff check pass.

## Moving profiles

Same isolated emulator/port 56011, production SAFE_FLIP_VBL + STAGGER_SLIME,
PAL 68000 8 MHz, requested 10-second alternating movement. W1 R13 uses X=80
after room load. No Flip calls or room transitions; debugger PID verified.

| Scenario | FPS before | FPS after | Work/frame before | Work/frame after |
|---|---:|---:|---:|---:|
| W0 R11 | 47.77 | 47.94 | 119,100 | 118,847 |
| W1 R13 | 49.67 | 49.92 | 82,927 | 79,073 |

R11: RenderQueuedSprites 23,030 -> 22,676 cycles/frame, about 354 fewer;
total work excluding VSync is about 0.21% lower. A small saving, with single
window FPS differences subject to input/animation phase variation.

R13 is NOT a matched active-sprite workload: QueueGeneratedSprite executes
10,217 times / 601 frames (~17 per frame) before, 9,664 / 604 (16 per frame)
after. DrawSlimes, CheckSlimeCollision and EMS work also fall. Do not attribute
the 4.65% total work reduction to equality alone. The run confirms near-50 Hz
operation but does not establish a controlled whole-loop speedup.

Before captures: profile_20260920_w0_r11_move_queue_pointers.json and
profile_20260920_w1_r13_move_queue_pointers.json. After:

- profile_20260920_w0_r11_move_paired_equal.json
- profile_20260920_w1_r13_move_paired_equal.json
- profile_shots/grab0046.png and grab0047.png

Production flob.prg is current. No commit made. Next larger benchmark claims
should preserve the same collectible/active-sprite state as well as position,
orientation and inputs.
