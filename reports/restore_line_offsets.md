# Restore line offset lookup

2026-09-11. Enabled in the normal RestoreRectsASM backend.

Replaced per-rectangle MULU #160 with a PC-relative table lookup. The table
contains 200 word offsets, assembled once. X/2 is added to the selected offset
and ADDA.W applies it to source and destination addresses. No blitter settings,
wait loop, dirty rectangle policy, ABI or gameplay logic changed.

The caller already supplies clipped 320x200 rectangles with 16-pixel-aligned
X/width. The largest start offset is 199*160 + 304/2 = 31992, safely positive
as a signed word. This table is specific to 160-byte lines and 200 rows; a
future stride/height change must revisit these bounds.

## Verification

- Disassembled restore.o: the rectangle loop contains no MULU.
- Object text size: 148 -> 548 bytes, an increase of 400 bytes.
- python3 verify_restore.py: 400 complete framebuffer comparisons pass,
  against the independent Pascal/blitter reference, including empty batches
  and varied clipped rectangles.

## Timing

Same isolated benchmark before and after the edit: 32000 small rectangles,
Hatari STE at 8 MHz, HZ200 clock, one run per version.

| Version | HZ200 ticks | Total |
|---|---:|---:|
| ASM with MULU | 1071 | 5355 ms |
| ASM with line table | 1038 | 5190 ms |

The restore workload takes approximately 3.1% less time (165 ms saved across
32000 rectangles, about 5.2 microseconds per rectangle). The unchanged Pascal
reference takes 3533 ticks in both runs. These are aggregate emulated timings,
not host time or whole-game FPS.

W1 R13 renderer benchmark, three runs after the change: animated slime phases
remain at 40 FPS, with 448 one-VBL and 64 three-VBL frames per 512 iterations.
No missed deadline is recovered by this small optimization alone.

Before data: restore_mulu_baseline.txt and
slime_w1_r13_benchmark_ems_mulu.json. After data: restore_verification.txt and
slime_w1_r13_benchmark_ems.json.
