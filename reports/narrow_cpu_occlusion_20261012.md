# Narrow CPU sprites and shared Flob occlusion, 2026-10-12

Implements items 1 and 2 from performance_audit_st_ste_20261012.md.

## Changes

- DrawSpriteCPU selects DrawNarrowSpriteCPU when source rowWords=1.
  The narrow kernel handles one/two destination words, unrolls all four
  planes, and forms both shifted destination words from one source rotation.
  No per-plane source-boundary tests or previous-word loads are necessary.
  Zero-opacity rows skip framebuffer reads/writes. Optional preshifted opacity
  from Flob's foreground mask, opaque zero pixels, and unaligned X still work.
  Wider sprites retain the existing generic kernel.
- BuildFlobOpacityCPU computes the EMS opacity intersected with the inverse
  of exact background indices 1/2. Pascal calculates the visible row interval
  once; the assembly loop copies both mask words and applies one/two groups
  only within the playfield. This path is shared by CPU and blitter rendering.
- Both routines preserve nonvolatile registers and use the existing FPC
  register ABI. The opacity descriptor is packed: three pointers followed by
  height, dstWords, firstVisible, endVisible words (20 bytes).
- Atlas data, EMS mask data, motion, collision rules, page history and sprite
  layering remain unchanged. The 200-row-capable temporary mask allocation
  is retained, preserving the existing helper's height contract.

## Matched renderer measurements

Same current-source benchmark as the audit: ST without blitter vs STE with
blitter, 68000 8 MHz, 4 MB, PAL, configured TOS without override, music callback
enabled and host audio disabled. SAFE_FLIP_VBL + STAGGER_SLIME.
Each phase runs 512 iterations. Moving Flob follows logical X=90..121,
fixed Y/frame, with animated slime. World object animation, physics, input,
triggers and pickup are excluded: this measures the renderer, not whole-game FPS.

Baseline counters were retained. Each after run has exactly the same draw
counts, restore rectangle counts and restored pixel counts as its baseline.
Separate instrumented runs confirm the same FPS and two-VBL counts.

| Machine / room | FPS before | FPS after | Gain | Two-VBL frames before / after |
| --- | ---: | ---: | ---: | ---: |
| ST W0 R11 | 42.74 | 47.15 | 10.3% | 87 / 31 |
| ST W1 R13 | 42.17 | 47.15 | 11.8% | 95 / 31 |
| STE W0 R11 | 50.00 | 50.00 | PAL limit | 0 / 0 |
| STE W1 R13 | 50.00 | 50.00 | PAL limit | 0 / 0 |

Baseline-build aggregate render ticks (200 Hz, 5 ms/tick), over 512 frames:

| Machine / room | Before | After | Reduction |
| --- | ---: | ---: | ---: |
| ST W0 R11 | 1322 | 921 | 30.3% |
| ST W1 R13 | 1319 | 899 | 31.8% |
| STE W0 R11 | 895 | 796 | 11.1% |
| STE W1 R13 | 860 | 764 | 11.2% |

Separately instrumented sprite-draw stage (includes Flob mask preparation):
W0 R11 ST 742 -> 312 ticks, STE 355 -> 255; W1 R13 ST 758 -> 338,
STE 359 -> 264. This is roughly 55-58% less drawing time on ST and 26-28%
on STE. Other stages are subject to 5 ms clock quantization and different
interrupt phase; do not attribute their small changes to new algorithms.

These are single deterministic-workload batches per configuration, with a
separate stage-instrumented batch, not confidence intervals or a real-hardware
test. The remaining ~6% two-VBL frames on ST are a further optimization target.

## Reproduction and artifacts

Build the current assembly objects first (`make render_cpu.o ems.o ims.o restore.o`).
`python3 reports/benchmark_st_ste_20261012.py --baseline --label _opt12`
produces the after baseline counters; omit --baseline for stage instrumentation.
Use a fresh label to retain an earlier measurement. The script compiles a
temporary PRG and copies its benchmark include to select W0 R11, leaving the
production PRGs and save alone.

- Before: audit_20261012_render_baseline.json and audit_20261012_render.json.
- After: audit_20261012_render_baseline_opt12.json and audit_20261012_render_opt12.json.
- Matching audit_20261012_*_opt12 CSVs and logs contain all six phases.
- Verification: verify_cpu_render.py (both machines), then
  verify_cpu_render.py --gameplay --machine st. The gameplay suite has an
  independent per-pixel Flob occlusion oracle, playfield edges and both-page
  dirty rendering; atlas tests compare narrow and wide sprites at all shifts.

All checks passed: 32720 atlas comparisons per machine, 512 CPU/blitter
foreground comparisons on STE, and the ST gameplay suite including 128
independent per-pixel Flob foreground comparisons.
