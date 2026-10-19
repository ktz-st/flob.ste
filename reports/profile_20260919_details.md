# Room CPU Cycle Profile

hatari-hrdb cycle profile of the real gameplay loop. STE 68000 8 MHz, 4 MB,
EmuTOS 1024k, forced PAL 50 Hz. Unlike run_slime_benchmark.py this is not a
controlled renderer workload: physics, hazards, collisions, input and music
are included. Frame counts are SwapScreen entry executions; a PAL frame at
8 MHz is 160,000 cycles.

| Capture | Frames | FPS | Cycles/frame | Work/frame (excl. VSync) | vs budget |
|---|---:|---:|---:|---:|---:|
| W0 R06, idle | 532 | 49.9 | 160,256 | 62,285 | 39% |
| W0 R11, idle | 496 | 46.5 | 171,887 | 116,675 | 73% |
| W0 R11, moving | 536 | 44.2 | 180,886 | 133,217 | 83% |
| W1 R13, idle | 530 | 49.7 | 160,861 | 82,128 | 51% |

## W0 R06, idle

| Routine | cyc/frame | % work | calls/frame | cyc/call |
|---|---:|---:|---:|---:|
| `renderqueuedsprites` | 9,747 | 15.6 | 1.0 | 9,747 |
| `narrowflobdynamicdanger` | 6,639 | 10.7 | 1.0 | 6,639 |
| `drawslimes` | 5,328 | 8.6 | 1.0 | 5,328 |
| `checkslimecollision` | 4,424 | 7.1 | 1.0 | 4,424 |
| `queuegeneratedsprite` | 4,205 | 6.8 | 7.0 | 601 |
| `fpc_mul_dword` | 4,190 | 6.7 | 9.2 | 458 |
| `[TOS ROM]` | 3,592 | 5.8 | – | – |
| `System.fillchar` | 2,800 | 4.5 | 3.0 | 933 |
| `applyroomspriteatlaspalette` | 2,695 | 4.3 | 1.0 | 2,695 |
| `getpix` | 2,204 | 3.5 | 4.0 | 551 |
| `_main` | 1,521 | 2.4 | – | – |
| `presentqueuedsprites` | 1,466 | 2.4 | 1.0 | 1,466 |
| `[asm] psgsound.o` | 1,209 | 1.9 | – | – |
| `[asm] ems.o` | 1,148 | 1.8 | 0.8 | 1,512 |
| `drawgeneratedspriteframeblitter` | 1,061 | 1.7 | 0.7 | 1,426 |
| `flobtouchesdangercolor` | 833 | 1.3 | 1.0 | 833 |
| `spritecollisionrect` | 665 | 1.1 | 2.0 | 333 |
| `polljoystickstate` | 664 | 1.1 | 1.0 | 664 |
| `checkspritecollisions` | 592 | 1.0 | 1.0 | 592 |
| `fpc_mul_longint` | 577 | 0.9 | 9.0 | 64 |
| `checkevents` | 557 | 0.9 | 1.0 | 557 |
| `crt_gameplaykeypressed` | 545 | 0.9 | 4.0 | 136 |
| `adddirtyspriterect` | 541 | 0.9 | 0.8 | 713 |
| `spriteintersectsdirty` | 510 | 0.8 | 0.6 | 855 |
| `drawflob` | 436 | 0.7 | 1.0 | 436 |
| `[asm] restore.o` | 409 | 0.7 | 0.2 | 2,113 |

## W0 R11, idle

| Routine | cyc/frame | % work | calls/frame | cyc/call |
|---|---:|---:|---:|---:|
| `renderqueuedsprites` | 26,032 | 22.3 | 1.0 | 26,032 |
| `spriteintersectsdirty` | 15,419 | 13.2 | 18.7 | 825 |
| `queuegeneratedsprite` | 9,614 | 8.2 | 16.0 | 601 |
| `drawslimes` | 9,172 | 7.9 | 1.0 | 9,172 |
| `checkslimecollision` | 7,370 | 6.3 | 1.0 | 7,370 |
| `drawgeneratedspriteframeblitter` | 5,071 | 4.3 | 3.4 | 1,503 |
| `[TOS ROM]` | 3,853 | 3.3 | – | – |
| `[asm] ims.o` | 3,600 | 3.1 | 1.2 | 2,922 |
| `showsprite` | 3,565 | 3.1 | 2.0 | 1,783 |
| `[asm] ems.o` | 3,186 | 2.7 | 2.2 | 1,478 |
| `applyroomspriteatlaspalette` | 2,987 | 2.6 | 1.0 | 2,987 |
| `System.fillchar` | 2,813 | 2.4 | 3.1 | 914 |
| `spritecollisionrect` | 2,681 | 2.3 | 2.0 | 1,340 |
| `adddirtyspriterect` | 2,441 | 2.1 | 3.4 | 713 |
| `[asm] restore.o` | 2,298 | 2.0 | 0.9 | 2,510 |
| `getpix` | 2,203 | 1.9 | 4.0 | 551 |
| `_main` | 1,563 | 1.3 | – | – |
| `presentqueuedsprites` | 1,556 | 1.3 | 1.0 | 1,556 |
| `[asm] psgsound.o` | 1,498 | 1.3 | – | – |
| `animatesprite` | 1,446 | 1.2 | 2.0 | 723 |
| `checkspritecollisions` | 937 | 0.8 | 1.0 | 937 |
| `rectsoverlap` | 800 | 0.7 | 2.0 | 400 |
| `polljoystickstate` | 665 | 0.6 | 1.0 | 665 |
| `crt_gameplaykeypressed` | 544 | 0.5 | 4.0 | 136 |
| `flobtouchesdangercolor` | 536 | 0.5 | 1.0 | 536 |
| `drawflob` | 437 | 0.4 | 1.0 | 437 |
| `mulword` | 357 | 0.3 | 5.6 | 64 |
| `checkevents` | 356 | 0.3 | 1.0 | 356 |

## W0 R11, moving

| Routine | cyc/frame | % work | calls/frame | cyc/call |
|---|---:|---:|---:|---:|
| `renderqueuedsprites` | 26,371 | 19.8 | 1.0 | 26,371 |
| `spriteintersectsdirty` | 18,876 | 14.2 | 18.3 | 1,030 |
| `queuegeneratedsprite` | 9,615 | 7.2 | 16.0 | 601 |
| `drawslimes` | 9,173 | 6.9 | 1.0 | 9,173 |
| `drawoccludedflob` | 7,298 | 5.5 | 0.6 | 12,579 |
| `checkslimecollision` | 7,165 | 5.4 | 1.0 | 7,165 |
| `[asm] ems.o` | 5,277 | 4.0 | 2.7 | 1,939 |
| `drawgeneratedspriteframeblitter` | 5,017 | 3.8 | 3.3 | 1,501 |
| `[TOS ROM]` | 4,056 | 3.0 | – | – |
| `[asm] restore.o` | 3,602 | 2.7 | 0.9 | 3,853 |
| `showsprite` | 3,565 | 2.7 | 2.0 | 1,782 |
| `[asm] ims.o` | 3,513 | 2.6 | 1.2 | 2,929 |
| `adddirtyspriterect` | 3,190 | 2.4 | 4.5 | 713 |
| `getpix` | 3,065 | 2.3 | 5.6 | 551 |
| `applyroomspriteatlaspalette` | 2,988 | 2.2 | 1.0 | 2,988 |
| `System.fillchar` | 2,811 | 2.1 | 3.1 | 914 |
| `spritecollisionrect` | 2,680 | 2.0 | 2.0 | 1,340 |
| `_main` | 1,613 | 1.2 | – | – |
| `[asm] psgsound.o` | 1,563 | 1.2 | – | – |
| `presentqueuedsprites` | 1,554 | 1.2 | 1.0 | 1,554 |
| `animatesprite` | 1,445 | 1.1 | 2.0 | 723 |
| `checkspritecollisions` | 937 | 0.7 | 1.0 | 937 |
| `rectsoverlap` | 782 | 0.6 | 2.0 | 391 |
| `polljoystickstate` | 679 | 0.5 | 1.0 | 679 |
| `crt_gameplaykeypressed` | 545 | 0.4 | 4.0 | 136 |
| `flobtouchesdangercolor` | 536 | 0.4 | 1.0 | 536 |
| `mulword` | 455 | 0.3 | 7.2 | 63 |
| `drawflob` | 437 | 0.3 | 1.0 | 437 |
| `checkevents` | 356 | 0.3 | 1.0 | 356 |
| `fpc_mul_qword` | 305 | 0.2 | 0.0 | 9,608 |

## W1 R13, idle

| Routine | cyc/frame | % work | calls/frame | cyc/call |
|---|---:|---:|---:|---:|
| `renderqueuedsprites` | 20,785 | 25.3 | 1.0 | 20,785 |
| `drawslimes` | 10,267 | 12.5 | 1.0 | 10,267 |
| `queuegeneratedsprite` | 9,613 | 11.7 | 16.0 | 601 |
| `checkslimecollision` | 7,674 | 9.3 | 1.0 | 7,674 |
| `[TOS ROM]` | 3,805 | 4.6 | – | – |
| `applyroomspriteatlaspalette` | 2,988 | 3.6 | 1.0 | 2,988 |
| `[asm] ems.o` | 2,890 | 3.5 | 1.9 | 1,535 |
| `System.fillchar` | 2,801 | 3.4 | 3.0 | 934 |
| `drawgeneratedspriteframeblitter` | 2,671 | 3.3 | 1.9 | 1,430 |
| `getpix` | 2,204 | 2.7 | 4.0 | 551 |
| `spriteintersectsdirty` | 2,134 | 2.6 | 1.2 | 1,740 |
| `_main` | 1,521 | 1.9 | – | – |
| `presentqueuedsprites` | 1,467 | 1.8 | 1.0 | 1,467 |
| `adddirtyspriterect` | 1,343 | 1.6 | 1.9 | 713 |
| `[asm] psgsound.o` | 1,037 | 1.3 | – | – |
| `[asm] restore.o` | 1,000 | 1.2 | 0.2 | 5,147 |
| `spritecollisionrect` | 665 | 0.8 | 2.0 | 333 |
| `polljoystickstate` | 665 | 0.8 | 1.0 | 665 |
| `checkspritecollisions` | 593 | 0.7 | 1.0 | 593 |
| `checkevents` | 557 | 0.7 | 1.0 | 557 |
| `crt_gameplaykeypressed` | 545 | 0.7 | 4.0 | 136 |
| `flobtouchesdangercolor` | 536 | 0.7 | 1.0 | 536 |
| `drawflob` | 436 | 0.5 | 1.0 | 436 |
