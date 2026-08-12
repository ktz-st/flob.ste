# TODO

## Current Focus

- Verify all worlds end-to-end on STE.
- Fix gameplay regressions found during real playtesting.
- Keep the game responsive: avoid per-frame redraws of HUD/message/palette unless data changes.
- Keep `VSync` as the last operation in `SwapScreen` to avoid sprite tearing.

## Gameplay / Rendering

- Port the original `Reveal` effect for `doorReveal` / key reveal flow.
  - Original A8 version stores the "before" room in `REVEAL_BUFFER`, loads the "after" room, then flashes between both buffers/display lists.
  - Current STE version loads both states but still needs the visible flash/alternate-buffer effect.
- Verify the new dirty-sprite renderer in all rooms.
  - Gameplay now restores merged old/new sprite rectangles from `SCREEN_BKG` with `BlitterCopyBitmap4`.
  - Each LOG/PHY page retains unchanged sprites and redraws only sprites intersecting a dirty rectangle.
  - A full-screen copy remains as an adaptive fallback for large dirty areas.
  - Check moving/animated/removed sprites, overlaps, flip, death, teleport, and reveal paths.
- Keep copy/clear blitter operations without HOG; keep HOG only for sprite/tile blits unless testing shows otherwise.
- Continue verifying flip-specific collision and sprite positions in all rooms.

## UI / Screens

- Finish the stats screen.
  - `ShowStats` currently has navigation/data selection but still needs real STE text/layout rendering.
  - Implement `ShowInt` / `ShowTime` equivalents or replace the whole screen with an STE-native layout.
- Polish the world selector.
  - Icons are implemented with STE-native world icon rendering.
  - Later: improve full-screen layout, text style, locked/playable state presentation, and preview animation.
- Polish game-over/end-world screens.
  - Current flow is functional.
  - Later: match final art direction and fade timing.
- Revisit HUD rendering after final font decisions.
  - HUD is functional.
  - Message rendering should remain cached/event-driven, not per-frame.
- Verify title, cutscenes, achievements, selector, stats, game-over, and credits palette order.
  - Draw to LOG first, swap, then fade into target palette.

## Assets / Palette

- Verify final shared room palette and sprite atlas palette workflow.
- Keep room screens using level colors from original data mapped through `STE_PAL`.
- Use atlas palette only during gameplay rooms, not title/cutscene/menu screens unless intended.
- Replace temporary/converted graphics with final 16-color STE artwork where available.
- Classify every `SPRITE_COMBINED` use before merging P0/P1 atlas rows.
  - Merge offline only true PMG color overlays with compatible position, dimensions, frames, and animation.
  - Keep independently animated, offset, or differently sized P0/P1 data as compound objects.
  - Do not merge all `_p0`/`_p1` rows mechanically; several pairs have different frame counts.
- Rebuild sprite assets after any edited `images/sprite_atlas/used_sprites.png` palette/art changes.
  - Use `make sprite-atlas-assets-only && make clean && make`.
  - `make used-sprite-atlas` regenerates the PNG/JSON from source data and overwrites manual edits.

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

## Audio (Final Stage)

- Audio will be implemented near the end, after gameplay and rendering stabilize.
- Implement music playback on STE.
  - Title/menu music.
  - In-game world music.
  - Cutscene music.
  - End/game-over music if present in original assets.
- Implement gameplay sound effects:
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
  - `SFX_SCRAPE`
  - aliases currently mapped in constants: `SFX_BEEP`, `SFX_TELEPORT`
- Decide final audio format/player for STE.
- Audit original `Sfx` / `FSfx` delay behavior when implementing audio.

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
- Music and core SFX implemented.
