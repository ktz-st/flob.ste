# TODO

## Current Focus

- Latest update: 2026-09-09. All five items from the latest CPU/render audit are implemented; remaining work is validation, not reimplementation.
- Verify all worlds end-to-end on STE.
- Fix gameplay regressions found during real playtesting.
- Keep the game responsive: avoid per-frame redraws of HUD/message/palette unless data changes.
- Keep `VSync` as the last operation in `SwapScreen` to avoid sprite tearing.

## Completed Optimization Batch

- [x] ASM IMS driver for remaining masked sprites, EMS for Flob/small slime, and one ASM call for the background-restore list.
- [x] Score-only update: draw 40x8 digits, copy aligned 48x8 to LOG/PHY without touching message areas; keep full HUD refresh on room entry/stats return.
- [x] Select EMS before computing IMS-only boundary masks and mask pointer.
- [x] Compare wide-sprite collision masks in 16-bit windows; retain the one-word fast path.
- [x] Compare dynamic hazard masks by rows, preserving the odd Flob Y offset and flip coordinates; track active hazard bits accurately.
- [x] Match compact sprite queues by stable IDs, so a removed slime does not invalidate unrelated later entries.
- [x] Space aliases FIRE through raw IKBD, with shared held/edge state; menus use space to confirm rather than legacy SELECT.
- [x] Automated target checks: 4000 sprite-mask comparisons, 2000 danger comparisons, hazard counter/removal, 80 dirty-render frames, shared FIRE state, and 12 score transitions.
- [x] Existing EMS (2304), IMS (32720) and restore (400) comparison suites passed for their respective backend changes.

## Next Playtest

- [ ] W0 R06: move while slime animate, collect several in quick succession, inspect both buffers for trails and one-frame remnants.
- [ ] W0 R04: cables on/off, passage to R24, clearance in both orientations.
- [ ] W0 R10: barrier/extinguisher interaction, floor contact, bell/reveal return and palette restoration.
- [ ] W0 R11: gas visible/absent, correct deaths and safe passage after it disappears.
- [ ] Wide objects phone/gear/spiderjump/bat: exact visible contact at both horizontal edges and after flip.
- [ ] Score changes: 99 to 100, point decay, pickup bonus, death/respawn and stats return; messages and world/room labels must stay unchanged unless deliberately updated.
- [ ] Space/FIRE: hold, release, alternate sources, press both together, and resume after pause or room transitions without an accidental extra flip.
- [ ] Overlapping sprites, flip, teleport, reveal and explosion particles: no stale pixels or layering regression.
- Report a problem with world/room (W/R), orientation, action and screenshot when useful; distinguish a steady slowdown from an occasional long frame.

## Further Performance Work

- [ ] Profile full gameplay only where playtesting finds a remaining slowdown; include physics, hazards, pickup, messages, NPCs and audio.
- Controlled W0 R06 rendering remains 50 FPS with no missed VBL deadlines, but excludes physics, pickup, NPC animation and messages. It is not proof of full-game performance.
- Isolated restore measured 69.7% less time; isolated IMS measured 10.8% less time. Neither figure is a whole-game FPS gain.
- Do not remove the pickup `WaitFrame` blindly: it exists in the original A8 flow.
- Keep `FindSteTile` lookup and further cropping/EMS expansion low priority unless measurements justify them. Memory reduction for 1 MB is a separate task.

## Gameplay / Rendering

- Verify the STE `Reveal` effect for `doorReveal` / key reveal flow in every world.
  - The port now stores the revealed playfield in a temporary buffer and flashes it against the normal `SCREEN_BKG`, including each state's room palette.
  - The world 0 phone path has been verified, including room colors and palette restoration after returning.
- Verify the new dirty-sprite renderer in all rooms.
  - Gameplay restores merged old/new rectangles with batched `RestoreRectsASM`; `NO_RESTORE_ASM` retains the Pascal `BlitterCopyBitmap4` reference.
  - Each LOG/PHY page retains unchanged sprites and redraws only sprites intersecting a dirty rectangle.
  - A full-screen copy remains as an adaptive fallback for large dirty areas.
  - Check moving/animated/removed sprites, overlaps, flip, death, teleport, and reveal paths.
- Keep copy/clear blitter operations without HOG; keep HOG only for sprite/tile blits unless testing shows otherwise.
- Continue verifying flip-specific collision and sprite positions in all rooms.
- Verify dynamic tile collision in every room using animated hazards or blockers.
  - `PUT_TILE` now updates room collision data when a tile changes state.
  - Dangerous dynamic pixels use a compact 1bpp mask and exact Flob-mask tests.
  - Confirm gas, cables, gates and other on/off tiles in both orientations.
- Verify the STE Flob death animation on floors, platforms, flipped rooms and screen edges.
  - `poof3`/`poof4` are generated as separate atlas layers; their 2x2 particles fall independently against room collision data.

## UI / Screens

- Verify the STE stats screen values and navigation after long play sessions.
  - Six per-world pages and one global page are rendered with STE-native text and support joystick or keyboard navigation.
- Polish the world selector.
  - Icons are implemented with STE-native world icon rendering.
  - Selector icons now come from canonical Scale2x `game_world_icons/world_XX.png` files; verify all six visually after the migration.
  - Later: improve full-screen layout, text style, locked/playable state presentation, and preview animation.
- Polish game-over/end-world screens.
  - Current flow is functional.
  - Four end-world icons now come from canonical Scale2x `game_endworld_icons/*.png` files.
  - Verify map, vial, formula and skull placement/palette in every summary variant.
  - Later: match final art direction and fade timing.
- Revisit HUD rendering after final font decisions.
  - HUD is functional.
  - Message rendering should remain cached/event-driven, not per-frame.
- Verify title, cutscenes, achievements, selector, stats, game-over, and credits palette order.
  - Draw to LOG first, swap, then fade into target palette.
  - Normal title from canonical Scale2x `game_title/title.png` is visually verified; verify the crowned achievement variant separately.
  - Intro/outro slides now come from canonical Scale2x `game_cutscenes/*.png`; verify all nine slides, text placement and transitions in Hatari.
- Verify gameplay pause with `P`, Enter and FIRE resume.
  - Check restoring an active message and ensure FIRE resume does not trigger an immediate flip.

## Assets / Palette

- Verify final shared room palette and sprite atlas palette workflow.
- Keep room screens using level colors from original data mapped through `STE_PAL`.
- Use atlas palette only during gameplay rooms, not title/cutscene/menu screens unless intended.
- Replace temporary/converted graphics with final 16-color STE artwork where available.
- Polish canonical `game_rooms/world_XX/room_XX.png` backgrounds at 320x160.
  - Initial artwork is Scale2x and remains restricted to palette indices 0..3.
  - Canonical `room_XX_collision.png` maps remain 160x80 and use semantic indices 0..3.
  - Original room GIFs are reference/import inputs only; normal builds use `game_rooms` exclusively.
- Verify all canonical Scale2x `game_tiles/world_XX/*.png` overlays in-game.
  - Normal builds use only the indexed PNG files and `game_tiles/manifest.json`; original `.gfx/.asm` files are reference/import inputs.
  - Tiles now use one unshifted mask + 4-plane payload and Blitter skew, reducing their planar data from about 145.7 KiB to 65.4 KiB.
  - Check transparent contours and seams for doors, bridges, cables, water, smoke and paired on/off states.
- Verify the new merged `SPRITE_COMBINED` color overlays in all listed rooms.
  - All 26 `gap=0` uses now render one generated `*_merged` asset instead of separate P0/P1 blits.
  - All 7 `gap>0` uses now render generated 20/30/32 px `*_compound` assets with full-width pixel collision.
  - Check colors, animation, vertical flip and collision against `SPRITE_COMBINED_REPORT.md`.
  - `phone` is visually verified; verify `gear`, `spiderjump` and `bat` in the rooms listed in the report.
- Rebuild sprite assets after any edited `images/sprite_atlas/game_sprites.png` palette/art changes.
  - Use `make sprite-atlas-assets-only && make clean && make`.
  - `make used-sprite-atlas` only regenerates the reference export and never overwrites artist work.
  - Do not apply Scale2x automatically to the whole production atlas: the preview distorted several small sprites. Smooth selected sprites manually.
- Reduce the generated planar sprite atlas footprint for the 1 MB build.
  - World data and collision maps are Apultra-compressed, with shared 8192-byte world and 3200-byte collision buffers. The old 971 KiB PRG figure is historical; the 2026-09-09 build is 1,106,170 bytes, before accounting for BSS/buffers/system RAM.
  - Runtime world loading and per-room collision decompression are verified in gameplay.
  - The earlier atlas estimate was about 220.5 KiB including metadata. Latest bounds audit counts 204,160 bytes of base masks/graphics; EMS additionally uses 34,304 mask bytes and 72 offset-table bytes. Re-measure the complete linked layout before a 1 MB redesign.
  - The generator stores 1636 frames because every source frame receives an unconditional vertical-flip copy.
  - Earlier deduplication audit found 575 duplicate frame blobs and about 71 KiB potential savings; recheck after current atlas changes, including EMS offsets.
  - Current bounds audit suggests 2,040 bytes saved by common crops or 35,640 by per-frame crops/empty omission before anchor metadata. These estimates overlap other savings and must not simply be added to deduplication/flip savings.
  - Generate vertical copies only for sprites that need them, or investigate negative Blitter source increments for runtime vertical flip; the theoretical footprint is close to 110 KiB.

## Input / Timing

- Continue testing gameplay-only raw IKBD joystick handler.
  - Menu/title/cutscenes keep keyboard support.
  - Gameplay uses raw IKBD joystick and keyboard state/events, including space-FIRE and pause/dev keys; do not restore BIOS/GEMDOS polling in the game loop.
- Watch for remaining tearing or joy state sticking under blitter load.
- Keep input behavior predictable after room transitions, teleport, cutscenes, stats, and achievements.

## Save / Progression

- Review save/progress/statistics flow.
  - World unlock state.
  - Best score/time/slime.
  - Secrets found.
  - Achievements.
- Verify achievements unlock and persistence after completing worlds, finding secrets, speed runs, and global milestones.

## Audio

- Core SFX are implemented from original POKEY register streams.
  - Default playback uses one PSG channel and a lightweight TOS VBL callback.
  - PSG period/noise/mixer/volume conversion is done during asset generation, not in VBL.
  - An alternate STE DMA software-synth backend remains available for comparison.
  - Verify final volume, pitch and distortion for every effect during full playthroughs.
- Music playback is implemented for title/menu, all worlds, cutscenes and end screens.
  - World 00/05 loops from frame 896 after its intro.
  - World 02 loops from frame 448 after its intro.
  - Other looping tracks restart at frame 0; intro remains non-looping in the STE flow.
- Verify gameplay sound effects already connected through `Sfx` / `FSfx`:
  - `SFX_FLIP`
  - `SFX_SLIMEPICK`
  - `SFX_DEAD`
  - `SFX_PICKALL`
  - `SFX_PICKGOAL`
  - `SFX_REVEAL`
  - `SFX_BIGSLIME`
  - `SFX_CONSOLE`
  - `SFX_WATERDROP`
  - `SFX_LEVER`
  - `SFX_SIREN`
  - `SFX_CIRCUIT`
  - `SFX_GEAR`
  - `SFX_VALVE`
  - `SFX_BELL`
  - `SFX_GAS`
  - `SFX_INSECT`
  - aliases currently mapped in constants: `SFX_BEEP`, `SFX_TELEPORT`
- Implement or deliberately map the remaining `SFX_SCRAPE` effect if its gameplay path is used.
- Decide whether the alternate DMA backend should remain in the final release.
- Audit original `Sfx` / `FSfx` delay and priority behavior during final audio polish.

## Cleanup

- Remove dead migration leftovers as soon as they are replaced.
- Slime editor/dev flow from the original A8 version is intentionally not planned for this port.
- Review unused constants only after asset/world conversion is stable.
- Keep original A8 naming only where it still helps map world data or converted assets.

## Dev / Cheat Mode

- Keep and polish `CheckDiags` as the STE startup cheat/dev entry.
  - Current STE behavior: hold `H` during startup to enable `cheatmode`.
  - Cheat mode currently gives max starting slime and unlocks worlds in the selector.
  - Decide whether to add an explicit visual indicator on title/selector when cheat mode is active.
  - Decide whether to port original save-clear diagnostic combo or leave save reset as an external/dev action.
- Do not port the original slime editor unless it becomes useful for STE-specific tooling.

## Validation Helpers

- Existing automated checks: `python3 verify_gameplay.py`, `python3 verify_score.py`, `python3 verify_ems.py`, `python3 verify_ims.py`, `python3 verify_restore.py`.
- Renderer-only measurement: `python3 run_slime_benchmark.py --runs 3`; results in `reports/slime_r06_benchmark_ems.md`. Temporary test PRGs do not replace the release PRG or game save.
- Host checks: `python3 -m unittest test_sprite_palette_roles`; sprite size report: `python3 audit_sprite_bounds.py`.
- Add a room smoke-test mode.
  - Iterate through every room in the current world.
  - Load room, draw background, sprites, slimes, and Flob once.
  - Useful for catching broken assets, bad sprite maps, bad palettes, and missing rooms quickly.
- Add optional debug overlays for development builds.
  - Current room, world, flip state, joy state.
  - Number of queued sprites and restored rectangles.
  - Collision sample points and sprite bounds.
- Build a small visual regression workflow.
  - Capture screenshots of key rooms in Hatari.
  - Keep reference screenshots for known-good states.
  - Compare manually at first; automate later if useful.

## First Playable Milestone

- Title screen.
- World selector.
- Intro cutscene.
- One full world playable from first room to goal.
- Death/restart loop.
- Game over/end-world screen.
- Achievements and save/progression check.
- Audio is optional for this milestone.

## Final Polish

- All worlds verified.
- Final 16-color sprite atlas.
- Final title/cutscene/menu palettes.
- Stable joystick under gameplay blitter load.
- No visible tearing in gameplay/cutscenes.
- No debug text or fallback graphics left.
- Music and core SFX verified.
