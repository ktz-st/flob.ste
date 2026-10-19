# Flob ST/STE: instructions for AI agents

Read README.md, BUILDING.md, FILE_VERSION.md and TODO.md before editing.
This repository is canonical. ../flob is the MadPascal/A8 behavioral reference;
../flob-files/src is generated and must never be edited as the source of a fix.

## Build

- BUILDING.md describes Free Pascal installation from ../atari-st-builder,
  dependencies, packaging tool sources and compilation, and release commands.
- `make`: embedded edition; `make st`: forced CPU renderer for testing.
- `make files`: packed external-resource HDD edition.
- `make files-floppy`: also builds ../flob-files/FLOB720.ST, standard 720 KiB.
- Current Python build/test scripts hardcode /opt/fpc/lib/fpc/3.3.1/ppcross68k.
  The Makefile PPC override does not change those scripts.
- Never run concurrent FPC builds in the same source/output directory.

## Preserve data and behavior

- Inspect git status before edits; preserve user changes and saves.
- Edited artwork in game_rooms, game_tiles, game_title, game_cutscenes,
  game_world_icons, game_endworld_icons and images/sprite_atlas/game_sprites.png
  is canonical. Original-A8 imports are not ordinary builds.
- `make sprite-atlas-assets-only` compiles the existing sprite sheet. Do not
  regenerate artist PNGs or palettes without explicit approval.
- Keep file-edition 64 KiB stack/heap budgets and explicit group ownership.
  All resource reads must occur with the hardware palette black.
- FLOB.PRG automatically selects CPU on ST or blitter on STE. FLOBST.PRG is
  a test alternative only. Default audio is PSG, not optional DMA synthesis.
- Never distribute flob.sav or use a user's emulator session for automated tests.

## Verification and handoff

- `python3 -m unittest test_file_bundle.py test_file_sprite_groups.py`
- `python3 verify_file_version.py --gameplay --lifetime`
- `python3 verify_floppy.py --no-build` after building the floppy edition.
- Use hatari-debugging for runtime bugs/profile evidence. Test ST without
  blitter and STE, 1 MiB, 68000/8 MHz. Keep configured TOS (currently 2.06),
  do not override the user's ROM. Use private images/saves.
- Real floppy loading is slow; black screens during reads are expected.
  Do not mistake a short screenshot timeout for a hang.
- Distinguish build/host tests, automated target regressions, manual playthroughs
  and physical-hardware verification in reports.
- Follow BUILDING.md for ZIP packaging including TESTERZY.TXT, excluding saves.
- Update notes and TODO when formats/budgets change. Inspect staged changes;
  do not accidentally commit binaries, save states or temporary profiling dumps.
