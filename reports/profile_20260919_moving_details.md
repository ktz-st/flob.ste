# Room CPU Cycle Profile

hatari-hrdb cycle profile of the real gameplay loop. STE 68000 8 MHz, 4 MB,
EmuTOS 1024k, forced PAL 50 Hz. Unlike run_slime_benchmark.py this is not a
controlled renderer workload: physics, hazards, collisions, input and music
are included. Frame counts are SwapScreen entry executions; a PAL frame at
8 MHz is 160,000 cycles.

| Capture | Frames | FPS | Cycles/frame | Work/frame (excl. VSync) | vs budget |
|---|---:|---:|---:|---:|---:|
| W0 R11, moving | 539 | 44.5 | 179,879 | 132,823 | 83% |
| W1 R13, moving | 578 | 47.8 | 167,465 | 101,348 | 63% |

## W0 R11, moving

| Routine | cyc/frame | % work | calls/frame | cyc/call |
|---|---:|---:|---:|---:|
| `renderqueuedsprites` | 26,337 | 19.8 | 1.0 | 26,337 |
| `spriteintersectsdirty` | 18,640 | 14.0 | 18.2 | 1,025 |
| `queuegeneratedsprite` | 9,613 | 7.2 | 16.0 | 601 |
| `drawslimes` | 9,168 | 6.9 | 1.0 | 9,168 |
| `drawoccludedflob` | 7,288 | 5.5 | 0.6 | 12,392 |
| `checkslimecollision` | 7,125 | 5.4 | 1.0 | 7,125 |
| `[asm] ems.o` | 5,304 | 4.0 | 2.7 | 1,938 |
| `drawgeneratedspriteframeblitter` | 5,004 | 3.8 | 3.3 | 1,501 |
| `[TOS ROM]` | 4,034 | 3.0 | – | – |
| `[asm] restore.o` | 3,588 | 2.7 | 0.9 | 3,837 |
| `showsprite` | 3,566 | 2.7 | 2.0 | 1,783 |
| `[asm] ims.o` | 3,472 | 2.6 | 1.2 | 2,929 |
| `adddirtyspriterect` | 3,192 | 2.4 | 4.5 | 713 |
| `getpix` | 3,073 | 2.3 | 5.6 | 551 |
| `applyroomspriteatlaspalette` | 2,989 | 2.3 | 1.0 | 2,989 |
| `System.fillchar` | 2,810 | 2.1 | 3.1 | 914 |
| `spritecollisionrect` | 2,678 | 2.0 | 2.0 | 1,339 |
| `_main` | 1,614 | 1.2 | – | – |
| `[asm] psgsound.o` | 1,554 | 1.2 | – | – |
| `presentqueuedsprites` | 1,554 | 1.2 | 1.0 | 1,554 |
| `animatesprite` | 1,445 | 1.1 | 2.0 | 722 |
| `checkspritecollisions` | 937 | 0.7 | 1.0 | 937 |
| `rectsoverlap` | 777 | 0.6 | 2.0 | 389 |
| `polljoystickstate` | 679 | 0.5 | 1.0 | 679 |
| `crt_gameplaykeypressed` | 545 | 0.4 | 4.0 | 136 |
| `flobtouchesdangercolor` | 537 | 0.4 | 1.0 | 537 |
| `mulword` | 455 | 0.3 | 7.2 | 63 |
| `drawflob` | 437 | 0.3 | 1.0 | 437 |
| `checkevents` | 357 | 0.3 | 1.0 | 357 |
| `fpc_mul_qword` | 303 | 0.2 | 0.0 | 9,605 |

## W1 R13, moving

| Routine | cyc/frame | % work | calls/frame | cyc/call |
|---|---:|---:|---:|---:|
| `renderqueuedsprites` | 22,788 | 22.5 | 1.0 | 22,788 |
| `drawslimes` | 10,269 | 10.1 | 1.0 | 10,269 |
| `queuegeneratedsprite` | 9,614 | 9.5 | 16.0 | 601 |
| `checkslimecollision` | 7,798 | 7.7 | 1.0 | 7,798 |
| `drawoccludedflob` | 7,151 | 7.1 | 0.6 | 12,450 |
| `spriteintersectsdirty` | 6,337 | 6.3 | 7.8 | 812 |
| `[asm] ems.o` | 4,941 | 4.9 | 2.4 | 2,023 |
| `[TOS ROM]` | 3,961 | 3.9 | – | – |
| `getpix` | 3,084 | 3.0 | 5.6 | 551 |
| `applyroomspriteatlaspalette` | 2,987 | 2.9 | 1.0 | 2,987 |
| `System.fillchar` | 2,800 | 2.8 | 3.0 | 933 |
| `drawgeneratedspriteframeblitter` | 2,673 | 2.6 | 1.9 | 1,430 |
| `[asm] restore.o` | 2,432 | 2.4 | 0.6 | 3,799 |
| `adddirtyspriterect` | 2,108 | 2.1 | 3.0 | 713 |
| `_main` | 1,568 | 1.5 | – | – |
| `presentqueuedsprites` | 1,466 | 1.4 | 1.0 | 1,466 |
| `[asm] psgsound.o` | 1,083 | 1.1 | – | – |
| `polljoystickstate` | 679 | 0.7 | 1.0 | 679 |
| `spritecollisionrect` | 665 | 0.7 | 2.0 | 333 |
| `checkspritecollisions` | 593 | 0.6 | 1.0 | 593 |
| `checkevents` | 557 | 0.5 | 1.0 | 557 |
| `crt_gameplaykeypressed` | 545 | 0.5 | 4.0 | 136 |
| `flobtouchesdangercolor` | 537 | 0.5 | 1.0 | 537 |
| `drawflob` | 436 | 0.4 | 1.0 | 436 |
| `mulword` | 340 | 0.3 | 5.4 | 63 |
