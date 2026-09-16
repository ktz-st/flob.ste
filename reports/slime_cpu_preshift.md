# Slime CPU Preshift Comparison

2026-09-12. Optional `SLIME_CPU`; production remains EMS.

## Implementation

`generate_slime_cpu.py` reads the existing generated slime asset, not the artist's
PNG directly. It prepares four frames times sixteen horizontal shifts, with
four-plane graphics and preserve masks. No runtime bit shifting is required.
Six rows are unrolled in assembly, with separate one/two-word-span routines.
Longword AND/OR pairs draw two planes at a time. The routine waits for outstanding
blitter work before touching destination memory. Existing wrapper bounds checks,
dirty regions, frame IDs, palette handling and Flob EMS rendering are unchanged.

The object is 7240 bytes: 6176 bytes of variant data, 640 bytes of dispatch table,
424 bytes of code. Existing EMS assets remain for comparison/fallback. This is
not yet a plain-ST backend: that would also need to remove the blitter-register
wait and port other graphics operations.

## Measurements

Hatari STE, 68000 at 8 MHz, PAL 50 Hz, 4 MB. Emulated HZ200/VBL timing,
not host execution time. Music callback active in room benchmark; microbenchmark
does not start music. HZ200 has 5 ms granularity.

| Test | EMS | Preshifted CPU |
|---|---:|---:|
| 16384 isolated draws, all frames/shifts | 3675 ms | 2585 ms |
| Average isolated draw | 0.224 ms | 0.158 ms |
| W1 R13 animated slime, stationary Flob | 44.44 FPS | 44.44 FPS |
| W1 R13 animated slime, moving Flob | 44.44 FPS | 44.44 FPS |

The microbenchmark takes 29.7% less time with CPU. It includes backend dispatch
and calling overhead, excludes the generic sprite wrapper/queue/background.
It is one aggregate measurement, not a claim about every individual shift.

Room measurements repeat three times per backend with identical FPS results.
Each animated phase has 448 one-VBL and 64 two-VBL iterations out of 512. Other
phases stay at 50 FPS. Physics, collisions, pickup, NPC logic and messages are
excluded: these are controlled render workloads, not whole-game FPS.

First-run moving/animated aggregate render timing is 1346 HZ200 ticks for EMS
versus 1325 for CPU. This is a modest reduction across the workload, not enough
to cross the next VBL deadline. Do not present the isolated 30% as game speedup.

## Verification And Reproduction

2304 framebuffer comparisons pass against the reference renderer, including all
frames, shifts, top/bottom positions and right-edge rejection. Gameplay regression
passes: both-page restore, overlapping sprites, W0 R13 Flob foreground, collision
and input checks. Normal release build succeeds and does not link this experiment.

```sh
python3 verify_ems.py --cpu
python3 verify_gameplay.py --cpu
python3 run_slime_benchmark.py --w1-r13 --runs 3
python3 run_slime_benchmark.py --w1-r13 --cpu --runs 3
```

Raw results: `cpu_verification.txt`, `gameplay_cpu_verification.txt`, and
`slime_w1_r13_ems[_cpu]_geometric_linear_run*.csv` in this directory.

Recommendation: keep EMS as the default for now. Preserve this measured optional
CPU path for future combined optimizations and the planned plain-ST port.
