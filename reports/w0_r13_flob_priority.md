# W0 R13 Flob / switch priority

2026-09-11. Fixed in the default renderer.

Room 13 has two STYPE_KEY objects from sprite_screen_lever. Room entry queues
world sprites before Flob, while the regular gameplay loop queues Flob before
world sprites. Rendering in queue order therefore makes a switch overwrite
Flob when a redraw occurs, although the previous page can still show the older
foreground composition. Animation-only redraws can make this look like flicker.

RenderQueuedSprites now defers the actual Flob (stableId=20 and Flob wordsBase)
until after other selected sprites. Generic effects using Flob graphics are
not affected. Other sprites retain their existing ordering. No queue sort or
unconditional Flob redraw was added. Existing overlap propagation ensures
stationary Flob is repainted when a switch behind him animates.

Regression: load actual W0 R13 assets and overlap Flob with both objects, move
and hold him, change switch frames, alternate room-entry/gameplay queue order,
test both sprite orientations and both screen pages. Compare the entire buffer
against independent full redraw with Flob in front.

Before the fix this failed at test 36 (second object, animation change). After
the fix all 128 room-specific comparisons pass, along with the previous 176
renderer comparisons and collision/input regressions. This is a scripted
renderer reproduction, not a claim to have ruled out every possible source
of flicker during manual gameplay.

W1 R13 renderer benchmark rerun after the fix: 44.44 FPS with animated slime,
unchanged. Build remains EMS, without SIMPLE_RESTORE/PREPARED_RESTORE/SLIME_EMX.
