# RenderQueuedSprites pointer reuse, 2026-09-20

Cache the current queue entry and matching history entry once per comparison.
Reuse spr/oldSpr for stable-ID lookup, equality, bounds comparison and dirty
rectangle insertion. The removed-sprite loop also reuses its history pointer.
No changes to equality semantics, dirty propagation, full-copy thresholds,
draw order, page history or sprite formats. SIMPLE_RESTORE is unchanged;
oldSpr is declared outside the legacy bookkeeping conditional because the
legacy comparison path also uses it.

Disassembly confirms the intended effect: queue/history bases stay in A3/A2,
current/history entries in A4/A5. Repeated index shifts and reloads disappear.
RenderQueuedSprites shrinks from 1164 to 1026 bytes; its stack frame shrinks
from 944 to 940 bytes. No assembler rewrite was needed for this change.

## Validation

Production make and git diff --check pass. VERIFY_GAMEPLAY passes all checks,
including 4,000 ASM/Pascal intersections, 4,000 masks, 2,000 dynamic dangers,
both-buffer dirty rendering, overlap chains in reversed spatial order, queue
capacity/empty frames, Flob foreground/occlusion, animation and input.
See gameplay_queue_pointers_verification.txt.

## Moving profiles

Same isolated emulator /tmp/flob-hrdb-port-build/src/hatari and port 56011
as the preceding register-ABI captures. SAFE_FLIP_VBL + STAGGER_SLIME,
68000 8 MHz PAL, 10-second requested alternating LEFT/RIGHT windows.
W1 R13 starts at X=80 after room load. Existing test-only death suppression
remains active. No room transitions or Flip calls; debugger PID verified.

| Scenario | FPS before | FPS after | Work/frame before | Work/frame after |
|---|---:|---:|---:|---:|
| W0 R11 moving | 46.63 | 47.77 | 123,488 | 119,100 |
| W1 R13 moving | 49.59 | 49.67 | 86,097 | 82,927 |

Work excludes VSync instructions. Savings are about 3.55% / 3.68%.
Exclusive RenderQueuedSprites cost: 26,939 -> 23,030 cycles/frame in R11
and 22,247 -> 18,828 in R13 (about 14.5% / 15.4% lower).
R13 stays near the PAL limit, so most savings are headroom rather than FPS.

These are single windows, not deterministic frame replay or confidence
intervals. R11: 566 -> 578 frames. R13: 600 -> 601 frames, 325 -> 324
FlobMove calls. Phase variation remains possible, but disassembly and both
routine-level profiles support the intended reduction in bookkeeping cost.

Before: profile_20260920_w{0,1}_r{11,13}_move_register_isolated.json
(corresponding room/world pair). After:

- profile_20260920_w0_r11_move_queue_pointers.json
- profile_20260920_w1_r13_move_queue_pointers.json
- profile_shots/grab0044.png and grab0045.png

Production flob.prg is current. No commit made; user save/assets untouched.
