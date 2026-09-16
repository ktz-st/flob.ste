# W0 R11 CPU Cycle Profile

Whole-game cycle profile of the real gameplay loop sitting in W0 R11, measured with
hatari-hrdb's remote debug profiler (TCP 56001). STE 68000 8 MHz, 4 MB, EmuTOS 1024k,
forced PAL 50 Hz ($FFFF820A := 2), host sound output off (the emulated PSG player still
runs and is measured). Unlike `run_slime_benchmark.py` this is not a controlled renderer
workload: physics, hazards, pickup, collisions, input, music and messages are all included.

Method: boot with cheatmode (H at boot), enter gameplay, patch `Explode`'s entry with an
`RTS` so hazard contact does not end the measurement window, then poke `levelNum := 11`
and `room_changed := 1`. Every detection path (`FlobTouchesDangerColor`,
`CheckSpriteCollisions`, `CheckSlimeCollision`) still runs and is still counted; only the
death sequence is suppressed. Symbols come from an unstripped `-Xm` build whose text
segment is byte-identical to the production `flob.prg` (both `0x13b90`).

Frame counts are `SwapScreen` entry executions; a PAL frame at 8 MHz is 160,000 cycles.

## Headline

| Capture | Frames | FPS | Cycles/frame | Work/frame (excl. VSync) | vs 160,000 budget |
|---|---:|---:|---:|---:|---:|
| W0 R06, idle | 532 | 49.9 | 160,255 | 84,537 | 53% |
| W0 R11, idle | 340 | 31.9 | 250,753 | 170,996 | **107%** |
| W0 R11, moving | 442 | 29.5 | 271,202 | 185,855 | **116%** |

**R11 runs at ~30–32 FPS, not 50.** Its per-frame work is 2.0–2.2x R06's and exceeds one
PAL frame, so `VSync` lands on the second VBL for most frames (1.57–1.70 VBL per frame).
The existing R06 benchmark reporting a clean 50 FPS is therefore not evidence about R11 —
R06 uses only 53% of the budget and has ~7 queued sprites, R11 has **16**.

To reach a stable 50 Hz, ~11,000 cycles/frame must go when standing still and
~26,000 when moving.

## Where the cycles go (R11, idle / moving)

| Routine | idle cyc/frame | %work | moving cyc/frame | calls/frame | cyc/call |
|---|---:|---:|---:|---:|---:|
| `RenderQueuedSprites` | 41,910 | 24.5 | 39,732 | 1.0 | ~40,500 |
| `GeneratedSpritesOverlap` | 14,469 | 8.5 | 12,995 | 12–13 | 1,110 |
| `QueueGeneratedSprite` | 13,460 | 7.9 | 12,397 | 15–16 | 841 |
| `SpriteIntersectsDirty` | 13,255 | 7.8 | 15,531 | 17 | 766–929 |
| `System.Move` | 10,959 | 6.4 | 12,394 | 1.1–1.6 | 7,700–10,150 |
| `CheckSlimeCollision` | 9,904 | 5.8 | 8,883 | 1.0 | ~9,500 |
| `DrawSlimes` | 9,223 | 5.4 | 8,272 | 1.0 | ~8,800 |
| `DrawGeneratedSpriteFrameBlitter` | 6,103 | 3.6 | 5,913 | 3.2 | 1,855 |
| `fpc_mul_dword` | 5,983 | 3.5 | 7,717 | 12–15 | ~510 |
| TOS ROM | 5,520 | 3.2 | 6,014 | – | – |
| `DrawOccludedFlob` | 305 | 0.2 | 8,259 | 0.6 | 13,230 |
| asm `ems.o` / `ims.o` / `restore.o` | 3,070 / 3,681 / 2,282 | 5.3 | 5,277 / 3,462 / 3,643 | – | – |
| asm `psgsound.o` (music) | 2,131 | 1.2 | 2,395 | – | – |

`restore.o` runs at 29.4 cycles/instruction and `ims.o` at 28.7 — those are blitter
stalls, i.e. the CPU halted waiting, not code to tighten.

## What changed between R06 and R11

| Routine | R06 cyc/frame | R11 cyc/frame | delta |
|---|---:|---:|---:|
| `RenderQueuedSprites` | 15,764 | 41,910 | +26,146 |
| `SpriteIntersectsDirty` | 193 | 13,255 | **+13,062 (69x)** |
| `GeneratedSpritesOverlap` | 6,655 | 14,469 | +7,814 |
| `QueueGeneratedSprite` | 5,887 | 13,460 | +7,573 |
| `System.Move` | 4,875 | 10,959 | +6,085 |
| `CheckSlimeCollision` | 5,697 | 9,904 | +4,207 |

Everything that scales with queued-sprite count doubles, but the dirty-rectangle matching
grows 69x: it is O(sprites x dirty rects) and both factors grow together.

## Ranked optimisation candidates

1. **`Move` of the sprite history — ~10,000–12,400 cycles/frame (6–7% of the work).**
   `RenderQueuedSprites` (flob.pas:1892) copies `queuedSprites` into `renderedSprites`
   with `Move(..., word(newCount) * SizeOf(TQueuedSprite))`. `TQueuedSprite` is 22 bytes,
   so 16 sprites is 352 bytes — and the measurement is ~29 cycles per byte with about two
   instructions per byte, i.e. FPC's generic byte-wise `Move`. Padding the record to 24
   bytes and copying longs, or better swapping two history buffers by pointer instead of
   copying at all, should recover most of it.

2. **32-bit multiply helper — 6,000–7,700 cycles/frame (3.5–4.2%).** `fpc_mul_dword` is
   called 12–15 times per frame at ~510 cycles each, from expressions whose operands are
   already 16-bit: flob.pas:1466, 1499, 1711, 1714, 1733, 1838, 2211, 2307, 2308
   (`longword(y) * 80`, `word(top - ay) * frameA^.rowWords`, ...). A `MULU.W` with a
   32-bit result is 70 cycles. Keep both operands 16-bit and let the widening multiply do
   the work; a power-of-two stride removes the multiply entirely.

3. **Call overhead on hot leaf routines — ~6,000 cycles/frame (3%).** Per-address split
   shows `movem.l` prologue/epilogue pairs: `QueueGeneratedSprite` +0x004/+0x0c4 at 84/88
   cycles (20% of its 841-cycle call), `GeneratedSpritesOverlap` +0x004/+0x4a2 at 92/96
   (17% of 1,104), `SpriteIntersectsDirty` +0x004/+0x0ac at 44/48 (10% of 929). These are
   short routines called 12–17 times per frame; inlining them or cutting their register
   pressure is a direct saving.

4. **`SpriteIntersectsDirty` does not scale.** A linear rect scan per sprite per buffer.
   Sorting or bucketing dirty rectangles by Y band, or testing a merged bounding box
   first, removes most of the comparisons in a 16-sprite room.

5. **`RenderQueuedSprites` itself is flat** — 488 hot addresses, no single hotspot above
   0.15%, mostly 16–22 cycle memory operands. There is no cheap win inside it; the wins
   are in what it calls and in how many sprites reach it.

## Caveats

- Cycle counts land on the instruction that was executing, so a blitter burst is charged
  to the register write that started it.
- `Explode` was patched to `RTS` for the window; the death/respawn path is not measured.
- These are CPU cycles. The FPS and budget figures above are derived from `SwapScreen`
  entry counts and emulated time, not from the cycle shares.

## Applied: zero-copy sprite history and 16-bit multiplies

Two of the ranked candidates are implemented. Measurements are fresh captures
under the same conditions; `reports/profile_w0_r11_*_step2.json` hold the raw data.

| Capture | FPS before | FPS after | Work/frame before | after | vs budget |
|---|---:|---:|---:|---:|---:|
| W0 R11, idle | 32.9 | **41.9** | 168,547 | 147,765 | 105% -> **92%** |
| W0 R11, moving | 29.5 | **34.4** | 185,855 | 167,354 | 116% -> **105%** |

**1. Sprite history is swapped, not copied.** `queuedSprites` and
`renderedSprites` are now two `PQueuedSpriteSlots` pointers into `spriteSlots`,
exchanged at the end of `RenderQueuedSprites`. The rendered list was already
read-only there and the queued list is refilled from index 0 every frame, so the
`Move` of 16 x 22 bytes had no purpose. It measured ~29 cycles per byte —
roughly two instructions per byte, FPC's generic byte-wise `Move`. Removing it
took `System.Move` out of the profile entirely (10,959 cycles/frame) and also cut
`RenderQueuedSprites` by ~4,900, since the role pointer replaces a 2-D index
whose row stride is 22.

**2. `fpc_mul_dword` is gone from every per-frame path.** FPC's m68k back end
emits no `MULU.W` anywhere — 0 occurrences in the whole 3.9 MB listing — so even
`word * word` assigned to a `word` becomes the 510-cycle helper. Two fixes:
constant strides became shift pairs (`y * 80` -> `(y shl 6) + (y shl 4)`, frame
stride 13 -> `shl 3 + shl 2 + 1`), and a two-instruction `MulWord` assembler
function (`MULU.W`, `nostackframe`) covers the variable products in
`DrawGeneratedSpriteFrameBlitter`, `DrawOccludedFlob`, `RenderQueuedSprites` and
`GeneratedSpritesOverlap`. Call sites fell from 28 to 18, and the 18 that remain
are room-load, flip, score BCD and synth paths that do not run per frame.

Verified with `verify_gameplay.py` (all 13 checks, including 80 dirty-render
frames on both buffers and 96 overlap-chain/full-queue/empty-frame comparisons),
`verify_ems.py`, `verify_ims.py`, `verify_restore.py`, `verify_score.py` and
`test_sprite_palette_roles`.

Moving is still 5% over budget and idle at 92% is too close to the edge for a
stable 50 Hz. The next candidates are unchanged: the `movem.l` prologues on
`QueueGeneratedSprite` / `GeneratedSpritesOverlap` / `SpriteIntersectsDirty`
(~6,000 cycles/frame), then the O(sprites x rects) dirty matching
(13,476 cycles/frame, still the third largest item).

## Second round: frame record padding and hoisted list bases

| Capture | FPS start | after round 1 | after round 2 | Work/frame | vs budget |
|---|---:|---:|---:|---:|---:|
| W0 R11, idle | 32.9 | 41.9 | **43.9** | 168,547 -> 129,858 | 105% -> **81%** |
| W0 R11, moving | 29.5 | 34.4 | **36.4** | 185,855 -> 146,546 | 116% -> **92%** |

**3. `TSteSpriteFrame` is padded, not byte-packed (-6,000 cycles/frame).**
types.inc sets `{$PACKRECORDS 1}` so record layouts match the original 8-bit
data, but the sprite frame tables are emitted as Pascal source by the asset
tools and never mapped onto packed binary. At 13 bytes every second frame sat on
an odd address, and FPC then copied every `word` field through a `move.b`/`dbra`
loop — `QueueGeneratedSprite` alone paid ~100 cycles a call for two of those.
`{$PACKRECORDS 4}` around that one record makes it 14 bytes with every field
aligned; the field offsets are unchanged, so the generated tables still match.
`QueueGeneratedSprite` fell from 789 to 649 cycles a call,
`GeneratedSpritesOverlap` from 1,161 to 973.

A trap worth recording: `{$PACKRECORDS 4}` pads to a multiple of the largest
field *alignment* (2 here), not to 4, so the record is **14** bytes, not 16. A
hand-written `frameIdx shl 4` stride therefore broke the flipped frame set and
`verify_gameplay.py` caught it as `FAIL W1 R07 falling lever contact`. Both
sites now use `Inc(frame, frameIdx)` and let the compiler scale by `SizeOf`.

**4. Hold the sprite lists in locals (-7,300 cycles/frame).** Every
`queuedSprites[screenLogIndex]^[i]` in `RenderQueuedSprites` reloaded
`screenLogIndex` and the list pointer from absolute globals — about 50 cycles
before the element address was even computed, on a routine that walks 16 sprites
several times. Two locals loaded once cut the routine from 37,225 to 29,901
cycles a frame.

### Measured and reverted

Three changes looked right and were not:

* **Narrowing the expansion pass** to rectangles added since the previous pass:
  13,476 -> 14,403 cycles. The `repeat` loop almost always runs once, so there
  is no second pass to save.
* **`inline` on `SpriteIntersectsDirty` and `AddDirtySpriteRect`** to remove the
  `movem.l` prologues: work/frame 147,765 -> 151,489, FPS 41.9 -> 37.7. FPC
  inlined them into `RenderQueuedSprites` and lost more to register pressure
  than the prologues cost.
* **Caching the sprite's edges and walking rectangles by pointer** inside
  `SpriteIntersectsDirty`: 906 -> 1,241 cycles a call. More locals, more spills.

The pattern is consistent on this target: adding locals to a small hot routine
usually costs more in spills than it saves in memory operands, while removing
work from an *outer* routine (a reloaded global, a byte-wise copy) pays.

**5. `TQueuedSprite` padded to 32 bytes (-5,300 cycles/frame).** Annotating the
disassembly with the profiler's cycles (`profile_disasm.py`) showed
`RenderQueuedSprites` spending its four hottest instructions on `lsl.l #3` /
`sub.l` / `lsl.l #2` / `add.l` — the stride for a 24-byte record, about 56
cycles at every `list^[i]`. A power of two makes it one `lsl.l #5`. Costs
192 x 8 bytes of RAM.

That same annotation answers the question of whether to rewrite the queue and
render path in assembler: **stack-frame traffic is 0.0% of the routine's
cycles**, so there are no register spills to recover, which is the usual reason
assembler wins here. The cost was the data layout, and it was cheaper to fix in
Pascal.

### Where the remaining cycles are (moving)

`RenderQueuedSprites` 30,534 (20.2%), `SpriteIntersectsDirty` 17,220 (11.4%),
`GeneratedSpritesOverlap` 12,622 (8.3%), `QueueGeneratedSprite` 10,363 (6.8%),
`CheckSlimeCollision` 9,677, `DrawSlimes` 9,099. All of them scale with the 16
sprites this room queues; none has a hot spot left to cut. Getting under budget
with margin needs either fewer queued sprites or an assembler rewrite of the
queue/render path.

## Third round: reject slime collisions by bounding box

`CheckSlimeCollision` called `GeneratedSpritesOverlap` once for every live
slime — fifteen full pixel-mask calls a frame with no cheap rejection first.
Annotating that routine's disassembly showed its most expensive instructions all
executing exactly **once per call**: entry checks and setup, not loop work. It
does make the same bounding-box test, but only after eight arguments, a `jsr`
and its prologue — 966 cycles to answer "they do not touch" fourteen times out
of fifteen. Doing that test inline in the caller skips the call entirely.

| Capture | before | after | Work/frame | vs budget |
|---|---:|---:|---:|---:|
| W1 R13, idle | 46.7 | **49.7** | 100,199 -> 81,926 | 63% -> **51%** |
| W0 R11, idle | 43.6 | **46.8** | 131,993 -> 116,036 | 82% -> **73%** |
| W0 R11, moving | 36.4 | **44.2** | 146,546 -> 133,227 | 92% -> **83%** |

This is the largest single gain of the whole exercise, and it is not a faster
routine — it is the same routine called two times a frame instead of fifteen.

### Full-session summary

| Room | at start | now | vs budget |
|---|---:|---:|---:|
| W1 R13, idle | 44.4 | **49.7** | 72% -> 51% |
| W0 R11, idle | 32.9 | **46.8** | 105% -> 73% |
| W0 R11, moving | 29.5 | **44.2** | 116% -> 83% |

Not one of these came from drawing sprites faster. `DrawGeneratedSpriteFrameBlitter`
— the code that actually puts pixels on screen — was never touched and is 3% of
the frame. The cost was in deciding what to draw and what had been hit: a
byte-wise `Move` of a 22-byte record, a software multiply where the operands
were 16-bit, an odd-sized record forcing byte-by-byte field copies, a global
pointer reloaded on every array access, a stride that was not a power of two,
and a collision test invoked fifteen times when two would do.
