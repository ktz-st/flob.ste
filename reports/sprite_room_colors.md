# Sprite / Room Colour Audit

Exact A8 register-value matches only, not visual similarity. No atlas changes.
All nonempty source frames are considered; animation reachability is not simulated.
Stable means a source-plane-colour can use the same nonzero STE room slot in every known usage/state.
This does not establish artistic intent. PMG overlap colours and priority effects require a separate pixel-level audit.
Index 0 is reported but is not a safe sprite binding with the current transparency convention.

| World/room | Sprite | Plane | A8 | Frames | STE slots | Conditional slots | Classification |
|---|---|---|---|---|---|---|---|
| W0 R00 | sprite_cagedoor | P0 | $E6 | 0,1,2,3,4,5,6,7,8,9,10 | [2] | [] | stable source-colour binding |
| W0 R01 | sprite_bench_portal | P0 | $86 | 0 | [2] | [] | stable source-colour binding |
| W0 R01 | sprite_bench_portal | P1 | $00 | 0 | [0] | [] | room/state dependent |
| W0 R02 | sprite_drop_eyes | P1 | $12 | 1,2 | [3] | [] | stable source-colour binding |
| W0 R10 | sprite_fireext | P0 | $00 | 4 | [0] | [] | room/state dependent |
| W0 R11 | sprite_sprays | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W0 R11 | sprite_sprays | P1 | $00 | 0 | [0] | [] | room/state dependent |
| W0 R22 | sprite_stats_portal | P1 | $00 | 3 | [0] | [] | room/state dependent |
| W1 R01 | sprite_valve_thunder | P1 | $72 | 5 | [3] | [] | stable source-colour binding |
| W1 R03 | sprite_vent_fly | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W1 R04 | sprite_bubbles | P1 | $CD | 0,1,2,3,4,5,6,7 | [1] | [] | stable source-colour binding |
| W1 R10 | sprite_stone_drops | P0 | $DC | 0 | [1] | [] | stable source-colour binding |
| W1 R18 | sprite_vent_fly | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W1 R19 | sprite_eyes_tail | P0 | $00 | 1,2 | [3] | [] | stable source-colour binding |
| W1 R19 | sprite_eyes_tail | P1 | $00 | 0,1,2,3 | [3] | [] | stable source-colour binding |
| W2 R00 | sprite_hole1 | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W2 R00 | sprite_hole1 | P0 | $02 | 1,3 | [3] | [] | stable source-colour binding |
| W2 R02 | sprite_hole2 | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W2 R03 | sprite_cross_eyes | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W2 R06 | sprite_window_star | P0 | $00 | 1 | [0] | [] | room/state dependent |
| W2 R14 | sprite_fire_lamp | P1 | $00 | 0 | [0] | [] | room/state dependent |
| W2 R19 | sprite_cranectl | P0 | $00 | 0,1 | [0] | [] | room/state dependent |
| W2 R23 | sprite_craneconsole | P1 | $B2 | 1,2 | [3] | [] | stable source-colour binding |
| W3 R01 | sprite_drop | P0 | $74 | 0,1,2,3,4,5,6,7,8,9,10,11 | [] | [] | room/state dependent |
| W3 R06 | sprite_drop | P0 | $74 | 0,1,2,3,4,5,6,7,8,9,10,11 | [] | [] | room/state dependent |
| W3 R13 | sprite_exit_eyes | P1 | $00 | 1,2 | [3] | [] | stable source-colour binding |
| W3 R15 | sprite_hole | P0 | $E4 | 0 | [2] | [] | stable source-colour binding |
| W3 R21 | sprite_hole_fly | P0 | $00 | 0 | [0] | [] | room/state dependent |
| W4 R06 | sprite_fire_console | P0 | $16 | 2 | [2] | [] | stable source-colour binding |
| W4 R22 | sprite_button_eyes | P1 | $CA | 1 | [1] | [] | stable source-colour binding |
| W4 R26 | sprite_eyes_eyes | P0 | $02 | 1,2 | [3] | [] | stable source-colour binding |
| W5 R07 | sprite_card_spray | P1 | $00 | 0 | [0] | [] | room/state dependent |
| W5 R09 | sprite_console_dot | P1 | $00 | 1 | [0] | [] | room/state dependent |
| W5 R12 | sprite_drop | P0 | $74 | 0,1,2,3,4,5,6,7,8,9,10,11 | [2] | [] | room/state dependent |
| W5 R13 | sprite_drop | P0 | $74 | 0,1,2,3,4,5,6,7,8,9,10,11 | [] | [] | room/state dependent |
| W5 R14 | sprite_key_lamp | P1 | $CE | 1 | [1] | [] | stable source-colour binding |
