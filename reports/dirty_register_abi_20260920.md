# Dirty intersection register ABI, 2026-09-20

Production SpriteIntersectsDirty now uses FPC register calling convention:
A0=sprite, A1=rectangle array, D0=count, D1=first. The intersection arithmetic
is unchanged. D2-D7 are preserved. Disassembly confirms register arguments in
the caller and a 112-byte routine, versus 124 bytes for the earlier cdecl
implementation. DIRTY_STACK_ABI retains the stack variant for A/B checks.

VERIFY_GAMEPLAY passes, including 4,000 ASM/Pascal intersection comparisons
and the complete collision, dirty-framebuffer, occlusion, animation and input
suite. Production build succeeds. No commit made.

## Valid isolated measurements

Production defines SAFE_FLIP_VBL and STAGGER_SLIME; 68000 8 MHz PAL;
alternating LEFT/RIGHT, same requested 10-second windows and death suppression
as previous reports. Both variants use the same locally built emulator.

| W0 R11 moving | Frames | FPS | Work/frame excluding VSync |
|---|---:|---:|---:|
| Stack ABI | 564 | 46.54 | 125,175 |
| Register ABI | 566 | 46.63 | 123,488 |

About 1.35% less work, not a significant FPS jump in single windows.
Intersection cost falls 10,252 -> 9,186 cycles/frame; caller RenderQueuedSprites
falls 27,854 -> 26,939. Wall-clock input and animation phases still vary.

W1 R13 register ABI, X=80 after room load: 600 frames, 49.59 FPS,
86,097 work cycles/frame. The attempted paired stack control executed Flip
twice and includes 16 animation swaps, so its 47.24 FPS is NOT a comparable
baseline and is excluded from speedup claims. No whole-loop gain claimed in R13.

Raw captures: profile_20260920_w0_r11_move_{stack,register}_isolated.json and
profile_20260920_w1_r13_move_register_isolated.json.
Tests: gameplay_dirty_register_verification.txt.

## Measurement isolation fix

Another Hatari process was listening on default port 56001. The initial
register attempts controlled the temporary test emulator but connected the
profiler to the other process. They briefly paused/resumed profiling there;
RAM writes and input still went only through the test emulator's control socket.
These two captures are INVALID and must not be used:

- profile_20260920_w0_r11_move_register.json
- profile_20260920_w0_r11_move_register_serial.json

One contains only a single executed address, the other no SwapScreen entries.
This was a debugger connection error, not evidence of a game crash.

profile_room.py now refuses occupied ports before launching, verifies that the
debugger listener belongs to the spawned PID using lsof, and requires multiple
SwapScreen calls. It also rejects Flip calls in movement-only captures after
the mixed R13 control exposed that additional fixture issue.

Local hrdb-mcp/src/debug/remotedebug.c gains HATARI_RDB_PORT (validated 1..65535,
default remains 56001). No installed emulator was replaced. The test build is
/tmp/flob-hrdb-port-build/src/hatari, used with --rdb-port 56011. It was built
out of source after the existing in-tree build hit permission errors.

Rebuild commands:

```sh
cmake -S /Users/kriss/GCC.ELF/hrdb-mcp -B /tmp/flob-hrdb-port-build -DENABLE_OSX_BUNDLE=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build /tmp/flob-hrdb-port-build --target hatari -j 6
install_name_tool -add_rpath /Library/Frameworks /tmp/flob-hrdb-port-build/src/hatari
codesign --force --sign - /tmp/flob-hrdb-port-build/src/hatari
```

Do not run verification and profile compiles concurrently: they share flob.o
and flob.s even when output PRGs have distinct paths. Future larger optimization
claims need reproducible initial state and input, not repeated wall-clock runs.
