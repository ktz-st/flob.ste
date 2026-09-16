# TODO

## Current Focus

- Latest update: 2026-09-09. All five items from the latest CPU/render audit are implemented; remaining work is validation, not reimplementation.
- Verify all worlds end-to-end on STE.
- Fix gameplay regressions found during real playtesting.
- Keep the game responsive: avoid per-frame redraws of HUD/message/palette unless data changes.
- Keep `VSync` as the last operation in `SwapScreen` to avoid sprite tearing.

## Planned Atari ST Version

- [ ] Prepare a plain Atari ST build with preshifted sprite graphics and masks, rendered by the 68000 without requiring a blitter.
- [ ] Generate preshift variants from the same canonical sprite atlas; measure their RAM cost and choose shifts according to actual movement/alignment requirements.
- [ ] Provide CPU background restore/copy/clear paths and audit STE-only hardware dependencies, while preserving the existing STE backend.

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

## W0 R11 Frame Budget

- Measured with `profile_room.py`: R11 was 32.9 FPS idle / 29.5 moving, against R06's 49.9.
  Per-frame work was 105%/116% of the 160,000-cycle PAL budget; R11 queues 16 sprites, R06 ~7.
- [x] Swap the queued/rendered sprite lists by pointer instead of copying them with `Move`.
- [x] Remove `fpc_mul_dword` from every per-frame path (shift pairs for constant strides,
      `MulWord` assembler helper for variable products). FPC's m68k back end never emits MULU.W.
- Now 41.9 FPS idle (92% of budget) / 34.4 moving (105%). See `reports/profile_w0_r11.md`.
- [x] Pad `TSteSpriteFrame` (`{$PACKRECORDS 4}`): at 13 bytes FPC copied its word fields
      through byte loops. Use `Inc(frame, idx)`, never a hand-written stride — the record is
      14 bytes, not 16, and `shl 4` broke the flipped frame set.
- [x] Hold the queued/rendered lists in locals in `RenderQueuedSprites` instead of indexing
      through `screenLogIndex` and a global pointer on every access.
- Measured worse and reverted: narrowing the expansion pass, `inline` on the dirty-rect
  leaves, caching sprite edges in `SpriteIntersectsDirty`. Adding locals to small hot
  routines costs more in spills than it saves here.
- [x] Pad `TQueuedSprite` to 32 bytes: a 24-byte stride was four instructions at every
      `list^[i]`, and the annotated disassembly charged RenderQueuedSprites' four hottest
      instructions to exactly that. Costs 1,536 bytes of RAM.
- Assembler rewrite of the queue/render path is NOT indicated: stack-frame traffic in
  `RenderQueuedSprites` measures 0.0%, so there are no spills to recover. Use
  `profile_disasm.py <capture> <symbol>` before considering it again.
- [x] `STAGGER_SLIME` enabled: W1 R13's losses were periodic spikes, not steady load.
      Note the controlled render benchmark says the opposite — it has no slack to exploit.
- Two rooms, two different problems: W1 R13 is spike-bound (61% mean, 2-in-16 frames redraw
  all 16 slime), W0 R11 is mean-bound (81%, load spread evenly). Diagnose before optimising.
- [x] Reject slime collisions by bounding box in `CheckSlimeCollision` before calling
      `GeneratedSpritesOverlap`: 15 full mask calls a frame became ~2. Largest single gain
      of the exercise (W0 R11 moving 36.4 -> 44.2 FPS).
- Now: W1 R13 49.7 FPS (51% of budget), W0 R11 46.8 idle / 44.2 moving (73%/83%).
- [ ] Confirm in play that both rooms feel right; W0 R11 moving is the remaining gap to 50 Hz. Everything left scales with the 16 queued
      sprites; needs fewer sprites per frame or an assembler queue/render path, not another
      micro-optimisation.
- [ ] Re-profile the other heavy rooms before assuming R11 was the worst case.

## Double-Buffer Page Flip

- [x] Program the shifter from the TOS VBL queue (`SAFE_FLIP_VBL`, on by default): the
      three-byte video base write could be split by the shifter's address reload, showing
      one frame from a mixed address. Proven 75-for-75 with a widened window; see
      `reports/double_buffer_blink.md`.
- [x] Write the video counter ($FFFF8205/07/09) as well as the base, or the VBL write
      lands one frame late — the AGTools STE display service does the same.
- [ ] Confirm in real play that the occasional blink is gone. The natural 28-cycle window
      was never caught firing in ~9,400 recorded frames, so the link to the reported
      symptom is strong but not proven.

## Ending Sequence

- [x] Latch the skip request before `FadeOut` in `ShowCutScene`, as the 8-bit original does.
      The port tested `IsStartingButtonDown` again *after* the fade, by which time a transient
      press had evaporated: the slide had already been cut short by it but the skip never
      fired, so every stray key shortened one slide instead of skipping the cutscene. A held
      key with auto-repeat did that repeatedly and the whole outro flew past.
- [x] `FlushBufferedKeys` at the start of `ShowCutScene`, so a press meant for the end-world
      summary cannot skip an outro the player has not seen yet. `ShowCredits` has always had
      the equivalent `WaitForStartKeyUp`, which is why the credits behaved correctly.
- Measured with `-dTEST_ENDING` (enters the completion path directly): untouched, the outro
  runs 8.6 / 16.3 / 8.6 s; with a key held it now skips cleanly instead of flying past.
- [x] Start each cutscene slide at `slideDelay := 50`, as the original does; the port used 18
      in both branches of a two-way test whose arms were identical. Outro slides measured
      8.94 / 16.84 / 8.82 s against 8.64 / 16.34 / 8.62 s before — the right direction, though
      the brightness-threshold measurement resolves to about ±0.3 s, so the constant matching
      the original is the real guarantee, not the pixel timing.

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

## Fixed-Step Gameplay Timing (Deferred, 2026-09-12)

- User priority: Flob must not crawl more slowly when rendering takes longer in rooms with many slime. Implementation is deferred; discuss before changing gameplay timing.
- Investigate separating gameplay updates from presentation using a 50 Hz fixed timestep driven by elapsed VBLs. If rendering takes two VBLs, run two normal simulation steps before presenting the next image, rather than doubling movement distance in one collision step.
- Check collisions and interactions at every simulation step. Preserve held-direction input, but consume a FIRE press edge only once so catch-up cannot trigger duplicate flips.
- Define timing consistently for gravity, NPCs, animations and gameplay timers; avoid advancing only Flob while interactions remain tied to render FPS. Preserve the original update order.
- Bound catch-up work to avoid a backlog spiral. Reset/rebase timing after pause, room transitions, reveal and blocking flip effects so they do not produce unintended catch-up movement.
- This maintains movement speed only while simulation can keep up; it does not guarantee 50 displayed FPS. Validate travel distance over elapsed time, collisions, input latency and room transitions in W1 R13 and a fast room.
- Merely evaluating slime animation at 25 Hz is unlikely to solve this: it already changes frame once per 16 gameplay updates. Preshifted CPU drawing did not improve room FPS; one-tick staggering was slower with two page histories. See `reports/slime_cpu_preshift.md` and `reports/slime_stagger.md`.

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
