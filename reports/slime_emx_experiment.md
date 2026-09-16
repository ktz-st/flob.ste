# Slime EMX experiment

2026-09-11. Opt-in SLIME_EMX; disabled in normal builds.

## Scope

EMX-style generated 68000 programs, not the AGTools EMX binary format or its
full optimizer. Inspired by AGT's emxgen.inl / b_emxg_spr.s: specialize mask
updates and draw operations per frame/shift rather than interpret masks in a
row loop. Existing colour words, palette slots, clipping and background restore
remain unchanged. The canonical PNG pipeline is not replaced or re-imported.

generate_slime_emx.py consumes generated/sprite_assets_atlas/slime.inc.
Four 6x6 frame variants produce 64 dispatch entries and 32 shared programs.
The live DrawSlimes path uses frames 0/1; all four are generated and tested.
Identical mask shapes share code while source colour data stays frame-specific.
The table uses the existing paletteOffset (EMS mask offset) plus shift*4.

Each program unrolls six rows and writes end masks only when they change.
It retains six hardware starts, HOG and completion checks. It does not implement
AGT's source-line reordering or general metaprogram optimizer. NFSR is enabled
only when the shifted destination spans two words, matching our EMS renderer.
The first prototype used NFSR for every nonzero shift; framebuffer tests caught
that error at x=1, and the final measurements below use the corrected code.

## Correctness

python3 verify_ems.py --emx passes 2304 framebuffer comparisons, all frames,
all 16 X shifts, top/bottom and right-edge guards. Flob remains EMS; slime uses
EMX. The reference path is the independent legacy four-plane masked renderer.
There are 1304 valid accelerated draws; other calls exercise clipping rejection.

python3 verify_gameplay.py --emx --simple-restore passes the collision/input
regressions and 80 full-buffer comparisons including overlapping, removed,
moving and animated sprites on both buffers.

## Isolated draw timing

One run, forced PAL, HZ200 clock, 16384 direct calls per backend, four frames
and all shifts equally represented. This excludes Pascal queue preparation,
restore, collision and the generic draw wrapper. Music is not started in this
verification harness. Results include call/argument and loop overhead.

| Backend | HZ200 ticks | Total | Mean / sprite |
|---|---:|---:|---:|
| EMS | 737 | 3685 ms | 0.225 ms |
| Generated EMX | 572 | 2860 ms | 0.175 ms |

Approximately 22.4% less time per direct call. This corresponds to roughly
0.81 ms saved for 16 draws with the test's shift distribution, before dispatch
overhead in the gameplay wrapper. HZ200 sampling granularity is 5 ms; these are
aggregate estimates, not exact instruction-cycle counts.

## W1 R13 renderer workload

STE 8 MHz, PAL 50 Hz, Hatari. Music callback active, host audio off.
512 iterations per phase, warm both buffers, no physics/collision/events/text.
Both EMX variants were repeated three times with identical FPS and histograms.

| Animated 16 slime + moving Flob | EMS | Generated EMX |
|---|---:|---:|
| Existing dirty renderer | 40 FPS | 40 FPS |
| SIMPLE_RESTORE redraw-all | 25 FPS | 25 FPS |

Dirty renderer still has 448 one-VBL and 64 three-VBL frames. Simple renderer
still has 512 two-VBL frames. EMX improves the low-level draw operation but
does not cross a VBL deadline in either workload. Do not interpret unchanged
FPS as identical execution cost, or these renderer tests as full gameplay FPS.

## Memory

slime_emx.o text: 7016 bytes, including 640 bytes of dispatch table.
Normal vs SLIME_EMX release builds:

| | EMS | EMX | Delta |
|---|---:|---:|---:|
| PRG file | 1094125 | 1101296 | +7171 bytes |
| TOS text segment | 79372 | 86452 | +7080 bytes |
| Data | 1005736 | 1005736 | 0 |
| BSS | 88268 | 88268 | 0 |

Existing EMS masks remain present for fallback/testing, so this is additive.
The normal PRG does not link slime_emx.o unless SLIME_EMX is defined.

## Reproduction

```sh
python3 verify_ems.py --emx
python3 verify_gameplay.py --emx
python3 verify_gameplay.py --emx --simple-restore
python3 run_slime_benchmark.py --w1-r13 --emx --runs 3
python3 run_slime_benchmark.py --w1-r13 --emx --simple-restore --runs 3
```

The runners rebuild the generated object before compiling temporary PRGs.
Reports use emx or _emx suffixes. Historical ems_calls counters include both
EMS and EMX accelerated calls; they do not count individual blitter starts.

## Decision

Keep as an optional experiment: the additional ~7 KB currently brings no FPS
gain in the problem room. Optimize CPU queue/dirty bookkeeping and slime
broad-phase collision next. EMX can be reconsidered when that work makes its
saved fraction of a millisecond enough to cross the 20 ms boundary.
