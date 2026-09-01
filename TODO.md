# TODO

## Current Focus

- Verify all worlds end-to-end on STE.
- Fix gameplay regressions found during real playtesting.
- Keep the game responsive: avoid per-frame redraws of HUD/message/palette unless data changes.
- Keep `VSync` as the last operation in `SwapScreen` to avoid sprite tearing.

## Gameplay / Rendering

- Verify the STE `Reveal` effect for `doorReveal` / key reveal flow in every world.
  - The port now stores the revealed playfield in a temporary buffer and flashes it against the normal `SCREEN_BKG`, including each state's room palette.
  - The world 0 phone path has been verified, including room colors and palette restoration after returning.
- Verify the new dirty-sprite renderer in all rooms.
  - Gameplay now restores merged old/new sprite rectangles from `SCREEN_BKG` with `BlitterCopyBitmap4`.
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
  - World data and collision maps are now Apultra-compressed. The current PRG is about 971 KiB, while runtime uses shared 8192-byte world and 3200-byte collision buffers.
  - Runtime world loading and per-room collision decompression are verified in gameplay.
  - Current atlas is about 220.5 KiB: 159.8 KiB graphics, 40.0 KiB masks and 20.8 KiB frame metadata.
  - The generator stores 1636 frames because every source frame receives an unconditional vertical-flip copy.
  - 575 frame blobs are already byte-identical to another frame in the same asset; sharing their offsets would save about 71 KiB without changing the Blitter renderer.
  - Generate vertical copies only for sprites that need them, or investigate negative Blitter source increments for runtime vertical flip; the theoretical footprint is close to 110 KiB.

## Input / Timing

- Continue testing gameplay-only raw IKBD joystick handler.
  - Menu/title/cutscenes keep keyboard support.
  - Gameplay should use raw joystick mode only.
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
  - An alternate STE DMA software-synth backend remains available for comparison.
  - Verify final volume, pitch and distortion for every effect during full playthroughs.
- Implement music playback on STE.
  - Title/menu music.
  - In-game world music.
  - Cutscene music.
  - End/game-over music if present in original assets.
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
