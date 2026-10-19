# Sprite queue construction, 2026-09-20

QueueGeneratedSprite no longer takes or rewrites palette arguments: every
caller used nil/zero. InitVideo clears all four sprite lists, so the legacy
palette fields stay zero. Their layout and equality semantics remain intact.
Position, frame, graphics pointer and stable ID are still written every time.
Width/height are copied together as one longword; the queue count address is
computed once. No conditional per-slot metadata cache was introduced.

The routine shrinks from 176 to 136 bytes. All gameplay, world object, death
particle and verification call sites use the reduced signature.

## Verification

The complete VERIFY_GAMEPLAY suite passes, including new tests for all four
list buffers, changing dimensions behind the same frame pointer, replacement
after QueueSpriteRect, stable/default IDs, nil frames and queue capacity.
See gameplay_queue_static_verification.txt.

## Moving W0 R11 profile

Production SAFE_FLIP_VBL + STAGGER_SLIME, isolated Hatari on port 56011,
68000 at 8 MHz, PAL. Both captures enqueue exactly 16 sprites per frame.

| Metric | Before | After |
|---|---:|---:|
| FPS | 47.94 | 48.10 |
| Work cycles/frame excluding VSync | 118,847 | 116,711 |
| QueueGeneratedSprite cycles/call | 600.8 | 496.6 |

Queue cost drops about 17.3%; whole-loop work drops about 1.8% in this sample.
Single-window FPS still depends on input and animation phase.

Before: profile_20260920_w0_r11_move_paired_equal.json.
After: profile_20260920_w0_r11_move_queue_static.json, grab0048.png.

## Rejected W1 R13 captures

profile_20260920_w1_r13_move_queue_static.json is INVALID: it profiled the
world selector, not gameplay (grab0049.png). Do not use its timing numbers.
The harness now also requires RenderQueuedSprites calls, rather than only
SwapScreen and a matching room variable. It explicitly enables cheat mode
in the isolated test process to avoid a missed boot key leaving worlds locked.

The retry reached a workload with Flip calls and was rejected before saving.
There is no valid matched W1 R13 performance comparison for this change.
