# Batched slime queue and STE mirror, 2026-10-12

Implements the concrete batch-generation and mirror candidates from audit
items 3/4, on top of the narrow CPU sprite / shared occlusion changes (opt12).

## Implementation

- QueueSlimesCPU takes one packed 36-byte descriptor through A0 and returns
  the appended count in D0, preserving nonvolatile FPC registers. Six pointers
  are followed by capacity, X scale, X offset, initial Y, Y step and two frame
  indices. Queue slots retain their existing 32-byte layout.
- Pascal resolves orientation and even/odd animation once. ASM advances Y
  incrementally across all 20 slots and appends descriptors directly. No cached
  position can become stale on room load, pickup or flip. The normal 2x X scale
  uses addition, not multiplication; a descriptor fallback retains other scales.
- Active slime collision frames update even with negative coordinates or a full
  queue. Inactive IDs retain their previous frame. Right/bottom clipping remains
  with the renderer, matching the old path. No palette/padding fields are changed.
- Matching, dirty rectangles, overlap-chain propagation, final Flob ordering
  and both complete page histories are unchanged. More invasive history/indexing
  changes are deferred rather than folded into this optimization.
- STE now uses MirrorPlayfieldCPU instead of three Move calls per row pair.
  It first waits for the blitter. HUD/message rows and final page rebuild remain
  intact; no physical-page copy was removed.

## Matched renderer measurement

Same workload as opt12: Hatari 68000 8 MHz, 4 MB, PAL, configured TOS, ST
without blitter / STE with blitter, music callback enabled, host audio disabled.
512 moving-Flob + animated-slime iterations in each room; fixed Y/frame,
logical X=90..121. This excludes gameplay physics, pickup and world animation.
These are renderer measurements, not whole-game FPS.

200 Hz aggregate ticks, before = opt12, after = opt34 basic-counter builds:

| Machine / room | Queue before / after | Queue reduction | Queue + render before / after |
| --- | ---: | ---: | ---: |
| ST W0 R11 | 298 / 187 | 37.2% | 1219 / 1087 |
| STE W0 R11 | 313 / 197 | 37.1% | 1109 / 990 |
| ST W1 R13 | 303 / 141 | 53.5% | 1202 / 1030 |
| STE W1 R13 | 284 / 150 | 47.2% | 1048 / 898 |

Combined measured work drops about 11-14%. The clock has 5 ms resolution;
phase boundaries and music interrupts affect attribution, so do not infer
an additional draw/restore optimization from small render-counter changes.
Each configuration was measured once per build, not a statistical series.
Separate stage-instrumented runs confirm the same FPS and work counts.

FPS remains ST 47.1455 (481 one-VBL + 31 two-VBL iterations), STE 50 (512
one-VBL iterations). The saving adds headroom but does not remove the remaining
animation-update VBL misses on ST. All six phases have identical sprite,
restore-rectangle, restored-pixel and EMS-call counts versus opt12.

## STE mirror timing

Native STE gameplay regression confirms renderer_blitter=TRUE. For 64 BKG
reversals without VSync, the independent three-Move reference costs 1887 ticks
and the production FlipGameplayAreaInPlace costs 236: about 8.0x faster,
147.4 -> 18.4 ms per reversal. This measures only the central BKG reversal,
not the full card-flip animation, its held frames or final page copies.
ST regression reports 1880 -> 235 ticks; its dispatch was already optimized.

## Verification and reproduction

- Added 512 independent old-Pascal vs batch-ASM comparisons: every byte of
  the queue including prefix/unused guards, all four lists, inactive IDs,
  negative/offscreen X, full capacity, both orientations, animation rollover,
  and separate collision-frame arrays.
- Existing tests compare both framebuffer histories against full redraws,
  overlap chains, W0 R13 switch layering, slime animation, foreground occlusion,
  flip sampling and full-screen mirror identity (including HUD/message guards).
- `python3 verify_cpu_render.py --gameplay --machine st`
- `python3 verify_cpu_render.py --native-gameplay --machine ste`
- `python3 reports/benchmark_st_ste_20261012.py --baseline --label _opt34`
- `python3 reports/benchmark_st_ste_20261012.py --label _opt34`
- `make all` and `make st`

Both regression runs passed, including the 512 added queue comparisons and
the existing framebuffer/logic suites; both production builds succeeded.
No physical-hardware playtest was performed.

Measurement artifacts: audit_20261012_render[_baseline]_opt34.json and matching
room CSVs/logs. Prior opt12 artifacts are retained for direct comparison.
