# Packed Sprite Bounds

152 generated sprites: 204160 bytes; conservative union crops: 202120 bytes; potential saving 2040 bytes.
Individual frame crops (including dropping empty frames): 168520 bytes, saving 35640 bytes.

Includes masks, four planes and both orientations. Excludes frame metadata.
No artwork changed. Savings are data/row-transfer estimates, NOT measured FPS.
A common crop preserves animation anchors; flipped frames require mirrored crop offsets.

| Sprite | Frames | Packed | Visible Union | Offset | Saving B |
|---|---:|---|---|---|---:|
| sprite_eye_p1 | 13 | 16x12 | 16x8 | 0,2 | 1040 |
| sprite_eye_p0 | 7 | 16x16 | 8x12 | 4,2 | 560 |
| sprite_lever_w03_merged | 7 | 16x24 | 16x22 | 0,0 | 280 |
| sprite_cranectl_p0 | 2 | 16x8 | 2x6 | 4,2 | 80 |
| flob_explode_p0 | 1 | 16x16 | 16x14 | 0,0 | 40 |
| flob_explode_p1 | 1 | 16x16 | 16x14 | 0,0 | 40 |
| flob | 16 | 16x16 | 16x16 | 0,0 | 0 |
| flob_particle_p0 | 1 | 2x2 | 2x2 | 0,0 | 0 |
| flob_particle_p1 | 1 | 2x2 | 2x2 | 0,0 | 0 |
| slime | 2 | 6x6 | 6x6 | 0,0 | 0 |
| sprite_2consolas_p0 | 8 | 16x18 | 16x18 | 0,0 | 0 |
| sprite_2consolas_p1 | 8 | 16x14 | 12x14 | 2,0 | 0 |
| sprite_2flames_p0 | 6 | 16x10 | 2x10 | 0,0 | 0 |
| sprite_2flames_p1 | 6 | 16x10 | 2x10 | 0,0 | 0 |
| sprite_2flies_w02_p0 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_2flies_w02_p1 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_2flies_w04_p0 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_2flies_w04_p1 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_bat_compound | 4 | 32x12 | 32x12 | 0,0 | 0 |
| sprite_bell_flame_p0 | 9 | 16x14 | 14x14 | 0,0 | 0 |
| sprite_bell_flame_p1 | 7 | 16x14 | 10x14 | 0,0 | 0 |
| sprite_bench_portal_p0 | 1 | 16x6 | 6x6 | 2,0 | 0 |
| sprite_bench_portal_p1 | 1 | 16x6 | 14x6 | 2,0 | 0 |
| sprite_bigslime_merged | 8 | 16x12 | 12x12 | 2,0 | 0 |
| sprite_birdpoop_p0 | 4 | 16x4 | 6x4 | 2,0 | 0 |
| sprite_box_fly_p0 | 6 | 16x8 | 6x8 | 0,0 | 0 |
| sprite_box_fly_p1 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_bubbles_p0 | 8 | 16x8 | 10x8 | 2,0 | 0 |
| sprite_bubbles_p1 | 8 | 16x12 | 10x12 | 0,0 | 0 |
| sprite_button_eyes_p0 | 7 | 16x6 | 6x6 | 0,0 | 0 |
| sprite_button_eyes_p1 | 2 | 16x2 | 6x2 | 0,0 | 0 |
| sprite_button_merged | 7 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_button_valve_p0 | 2 | 16x6 | 6x6 | 0,0 | 0 |
| sprite_button_valve_p1 | 1 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_cagedoor_p0 | 11 | 16x30 | 16x30 | 0,0 | 0 |
| sprite_card2_p0 | 8 | 16x8 | 12x8 | 0,0 | 0 |
| sprite_card_meteor_p0 | 8 | 16x8 | 12x8 | 0,0 | 0 |
| sprite_card_meteor_p1 | 9 | 16x8 | 16x8 | 0,0 | 0 |
| sprite_card_p0 | 8 | 16x8 | 12x8 | 0,0 | 0 |
| sprite_card_recipe_p0 | 8 | 16x8 | 12x8 | 0,0 | 0 |
| sprite_card_recipe_p1 | 8 | 16x14 | 14x14 | 0,0 | 0 |
| sprite_card_spray_p0 | 8 | 16x8 | 12x8 | 0,0 | 0 |
| sprite_card_spray_p1 | 3 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_console2_p0 | 6 | 16x8 | 6x8 | 0,0 | 0 |
| sprite_console_dot_p0 | 10 | 16x18 | 12x18 | 0,0 | 0 |
| sprite_console_dot_p1 | 2 | 16x2 | 2x2 | 0,0 | 0 |
| sprite_console_drop_p0 | 7 | 16x18 | 12x18 | 0,0 | 0 |
| sprite_console_drop_p1 | 3 | 16x4 | 6x4 | 0,0 | 0 |
| sprite_console_p0 | 7 | 16x14 | 10x14 | 0,0 | 0 |
| sprite_craneconsole_p0 | 9 | 16x10 | 14x10 | 0,0 | 0 |
| sprite_craneconsole_p1 | 3 | 16x4 | 8x4 | 0,0 | 0 |
| sprite_cross_eyes_p0 | 2 | 16x12 | 12x12 | 0,0 | 0 |
| sprite_cross_eyes_p1 | 4 | 16x2 | 6x2 | 0,0 | 0 |
| sprite_drop1_p0 | 3 | 16x4 | 10x4 | 0,0 | 0 |
| sprite_drop_eyes_p0 | 6 | 16x12 | 14x12 | 0,0 | 0 |
| sprite_drop_eyes_p1 | 3 | 16x4 | 6x4 | 4,0 | 0 |
| sprite_drop_merged | 13 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_ekey_p0 | 12 | 16x18 | 10x18 | 0,0 | 0 |
| sprite_ekey_p1 | 8 | 16x8 | 12x8 | 0,0 | 0 |
| sprite_electro2_p0 | 7 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_electro2_p1 | 11 | 16x16 | 10x16 | 2,0 | 0 |
| sprite_electro3_p0 | 7 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_electro3_p1 | 3 | 16x6 | 16x6 | 0,0 | 0 |
| sprite_electro_button_p0 | 11 | 16x16 | 10x16 | 2,0 | 0 |
| sprite_electro_button_p1 | 3 | 16x4 | 6x4 | 0,0 | 0 |
| sprite_exit_drop_p0 | 4 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_exit_drop_p1 | 4 | 16x6 | 4x6 | 6,0 | 0 |
| sprite_exit_eyes_w03_p0 | 4 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_exit_eyes_w03_p1 | 3 | 16x4 | 8x4 | 4,0 | 0 |
| sprite_exit_eyes_w04_p0 | 4 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_exit_eyes_w04_p1 | 5 | 16x2 | 6x2 | 4,0 | 0 |
| sprite_exit_heart_p0 | 4 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_exit_heart_p1 | 3 | 16x8 | 10x8 | 0,0 | 0 |
| sprite_exit_p0 | 4 | 16x20 | 16x20 | 0,0 | 0 |
| sprite_eyes_drop_p0 | 4 | 16x2 | 8x2 | 0,0 | 0 |
| sprite_eyes_drop_p1 | 3 | 16x4 | 10x4 | 0,0 | 0 |
| sprite_eyes_eyes_p0 | 3 | 16x4 | 6x4 | 0,0 | 0 |
| sprite_eyes_eyes_p1 | 4 | 16x2 | 12x2 | 0,0 | 0 |
| sprite_eyes_glasses_p0 | 3 | 16x2 | 10x2 | 0,0 | 0 |
| sprite_eyes_glasses_p1 | 1 | 16x4 | 12x4 | 0,0 | 0 |
| sprite_eyes_p0 | 16 | 16x2 | 6x2 | 2,0 | 0 |
| sprite_eyes_tail_p0 | 3 | 16x4 | 8x4 | 4,0 | 0 |
| sprite_eyes_tail_p1 | 4 | 16x18 | 12x18 | 2,0 | 0 |
| sprite_fire_console_p0 | 7 | 16x4 | 16x4 | 0,0 | 0 |
| sprite_fire_console_p1 | 7 | 16x14 | 10x14 | 0,0 | 0 |
| sprite_fire_lamp_p0 | 12 | 16x6 | 14x6 | 0,0 | 0 |
| sprite_fire_lamp_p1 | 2 | 16x4 | 4x4 | 0,0 | 0 |
| sprite_fireext_merged | 6 | 16x20 | 12x20 | 2,0 | 0 |
| sprite_flame_merged | 7 | 16x20 | 16x20 | 0,0 | 0 |
| sprite_fly_console_p0 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_fly_console_p1 | 3 | 16x6 | 16x6 | 0,0 | 0 |
| sprite_fly_drop_p0 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_fly_drop_p1 | 3 | 16x4 | 10x4 | 0,0 | 0 |
| sprite_fly_p0 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_gear_compound | 6 | 32x32 | 32x32 | 0,0 | 0 |
| sprite_hole1_p0 | 4 | 16x14 | 8x14 | 2,0 | 0 |
| sprite_hole1_p1 | 4 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_hole2_p0 | 4 | 16x16 | 10x16 | 0,0 | 0 |
| sprite_hole2_p1 | 8 | 16x10 | 10x10 | 0,0 | 0 |
| sprite_hole_fly_p0 | 4 | 16x14 | 10x14 | 2,0 | 0 |
| sprite_hole_fly_p1 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_hole_p0 | 1 | 16x16 | 8x16 | 0,0 | 0 |
| sprite_hole_p1 | 3 | 16x22 | 16x22 | 0,0 | 0 |
| sprite_jan_drop_p0 | 3 | 16x46 | 16x46 | 0,0 | 0 |
| sprite_jan_drop_p1 | 6 | 16x4 | 6x4 | 2,0 | 0 |
| sprite_key_lamp_p0 | 9 | 16x14 | 6x14 | 0,0 | 0 |
| sprite_key_lamp_p1 | 2 | 16x6 | 6x6 | 0,0 | 0 |
| sprite_lamp_drop_p0 | 2 | 16x4 | 4x4 | 0,0 | 0 |
| sprite_lamp_drop_p1 | 3 | 16x4 | 6x4 | 0,0 | 0 |
| sprite_lamp_fuse_p0 | 3 | 16x4 | 4x4 | 0,0 | 0 |
| sprite_lamp_fuse_p1 | 2 | 16x30 | 16x30 | 0,0 | 0 |
| sprite_lamp_p0 | 2 | 16x4 | 4x4 | 0,0 | 0 |
| sprite_lamp_p1 | 7 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_lantern_p0 | 3 | 16x4 | 16x4 | 0,0 | 0 |
| sprite_lever2_merged | 11 | 16x22 | 12x22 | 2,0 | 0 |
| sprite_lever_w04_p0 | 7 | 16x32 | 14x32 | 0,0 | 0 |
| sprite_light_electro_p0 | 2 | 16x2 | 12x2 | 0,0 | 0 |
| sprite_light_electro_p1 | 11 | 16x16 | 10x16 | 2,0 | 0 |
| sprite_lights_p0 | 10 | 16x2 | 10x2 | 0,0 | 0 |
| sprite_map_merged | 1 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_mice_console_p0 | 16 | 16x8 | 16x8 | 0,0 | 0 |
| sprite_mice_console_p1 | 3 | 16x6 | 16x6 | 0,0 | 0 |
| sprite_phone_compound | 9 | 20x16 | 20x16 | 0,0 | 0 |
| sprite_rat_p0 | 16 | 16x8 | 16x8 | 0,0 | 0 |
| sprite_screen_lever_p0 | 1 | 16x12 | 16x12 | 0,0 | 0 |
| sprite_screen_lever_p1 | 6 | 16x32 | 16x32 | 0,0 | 0 |
| sprite_spiderjump_compound | 2 | 30x18 | 30x18 | 0,0 | 0 |
| sprite_sprays_p0 | 3 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_sprays_p1 | 3 | 16x10 | 16x10 | 0,0 | 0 |
| sprite_stats_portal_p0 | 2 | 16x18 | 12x18 | 2,0 | 0 |
| sprite_stats_portal_p1 | 4 | 16x12 | 10x12 | 0,0 | 0 |
| sprite_stone_drops_p0 | 1 | 16x12 | 16x12 | 0,0 | 0 |
| sprite_stone_drops_p1 | 3 | 16x4 | 10x4 | 0,0 | 0 |
| sprite_switch_p0 | 7 | 16x4 | 6x4 | 0,0 | 0 |
| sprite_valve_drops_w01_p0 | 8 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_valve_drops_w01_p1 | 3 | 16x4 | 8x4 | 4,0 | 0 |
| sprite_valve_drops_w04_p0 | 8 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_valve_drops_w04_p1 | 3 | 16x4 | 8x4 | 4,0 | 0 |
| sprite_valve_p0 | 8 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_valve_p1 | 5 | 16x6 | 4x6 | 6,0 | 0 |
| sprite_valve_thunder_p0 | 8 | 16x16 | 16x16 | 0,0 | 0 |
| sprite_valve_thunder_p1 | 11 | 16x16 | 10x16 | 2,0 | 0 |
| sprite_vent_fly_p0 | 4 | 16x20 | 12x20 | 2,0 | 0 |
| sprite_vent_fly_p1 | 3 | 16x6 | 8x6 | 4,0 | 0 |
| sprite_vial_w01_merged | 8 | 16x20 | 16x20 | 0,0 | 0 |
| sprite_vial_w02_merged | 8 | 16x20 | 16x20 | 0,0 | 0 |
| sprite_vial_w03_merged | 8 | 16x20 | 16x20 | 0,0 | 0 |
| sprite_vial_w04_merged | 8 | 16x20 | 16x20 | 0,0 | 0 |
| sprite_window_star_p0 | 2 | 16x4 | 4x4 | 0,0 | 0 |
| sprite_window_star_p1 | 4 | 16x6 | 6x6 | 10,0 | 0 |
| sprite_xvdial_p0 | 7 | 16x12 | 14x12 | 0,0 | 0 |
| sprite_xvdial_p1 | 3 | 16x4 | 10x4 | 0,0 | 0 |

## Individual Frame Crops

Requires per-frame anchor offsets in rendering AND collision, including flip handling.
A smaller width still occupies whole 16-pixel planar words; data savings may be zero
while destination spans/background restore rectangles become smaller.
There are 59 empty source frames.

| Sprite | Potential saving B | Empty frames |
|---|---:|---|
| sprite_cagedoor_p0 | 3800 | [] |
| sprite_lever_w04_p0 | 3200 | [] |
| sprite_eye_p1 | 1800 | [12] |
| sprite_drop_merged | 1440 | [12] |
| flob | 1360 | [] |
| sprite_lamp_p1 | 1280 | [6] |
| sprite_console_p0 | 960 | [4] |
| sprite_fire_console_p1 | 960 | [4] |
| sprite_jan_drop_p0 | 920 | [0] |
| sprite_card_meteor_p1 | 640 | [0] |
| sprite_2flames_p0 | 600 | [] |
| sprite_2flames_p1 | 600 | [] |
| sprite_screen_lever_p1 | 600 | [] |
| sprite_eye_p0 | 560 | [] |
| sprite_card2_p0 | 520 | [7] |
| sprite_card_meteor_p0 | 520 | [7] |
| sprite_card_p0 | 520 | [7] |
| sprite_card_recipe_p0 | 520 | [7] |
| sprite_card_spray_p0 | 520 | [7] |
| sprite_drop_eyes_p0 | 520 | [] |
| sprite_ekey_p1 | 520 | [7] |
| sprite_fire_lamp_p0 | 520 | [] |
| sprite_electro2_p0 | 480 | [0] |
| sprite_electro3_p0 | 480 | [0] |
| sprite_lever_w03_merged | 440 | [] |
| sprite_bubbles_p0 | 400 | [] |
| sprite_console_dot_p0 | 400 | [] |
| sprite_fireext_merged | 400 | [5] |
| sprite_phone_compound | 400 | [] |
| sprite_console_drop_p0 | 360 | [] |
| sprite_ekey_p0 | 360 | [11] |
| sprite_eyes_p0 | 360 | [7, 8, 9, 10, 11, 12, 13, 14, 15] |
| sprite_hole2_p1 | 360 | [] |
| sprite_console2_p0 | 320 | [] |
| sprite_electro2_p1 | 320 | [0] |
| sprite_electro_button_p0 | 320 | [0] |
| sprite_exit_p0 | 320 | [] |
| sprite_light_electro_p1 | 320 | [0] |
| sprite_valve_thunder_p1 | 320 | [0] |
| sprite_key_lamp_p0 | 280 | [8] |
| sprite_craneconsole_p0 | 240 | [] |
| sprite_exit_drop_p1 | 240 | [0] |
| sprite_valve_p1 | 240 | [0] |
| sprite_window_star_p1 | 240 | [0] |
| sprite_2consolas_p1 | 200 | [] |
| sprite_bell_flame_p0 | 200 | [] |
| sprite_card_spray_p1 | 200 | [2] |
| sprite_sprays_p0 | 200 | [2] |
| sprite_sprays_p1 | 200 | [2] |
| sprite_bat_compound | 160 | [] |
| sprite_bigslime_merged | 160 | [] |
| sprite_birdpoop_p0 | 160 | [0] |
| sprite_bubbles_p1 | 160 | [] |
| sprite_jan_drop_p1 | 160 | [0] |
| sprite_lights_p0 | 160 | [0, 4, 5, 9] |
| sprite_craneconsole_p1 | 120 | [0] |
| sprite_drop_eyes_p1 | 120 | [0] |
| sprite_exit_eyes_w03_p1 | 120 | [0] |
| sprite_eyes_eyes_p0 | 120 | [0] |
| sprite_eyes_tail_p0 | 120 | [0] |
| sprite_flame_merged | 120 | [] |
| sprite_key_lamp_p1 | 120 | [0] |
| sprite_xvdial_p0 | 120 | [] |
| sprite_2flies_w02_p0 | 80 | [] |
| sprite_2flies_w02_p1 | 80 | [] |
| sprite_2flies_w04_p0 | 80 | [] |
| sprite_2flies_w04_p1 | 80 | [] |
| sprite_box_fly_p0 | 80 | [] |
| sprite_box_fly_p1 | 80 | [] |
| sprite_cranectl_p0 | 80 | [] |
| sprite_drop1_p0 | 80 | [] |
| sprite_eyes_drop_p1 | 80 | [] |
| sprite_fly_console_p0 | 80 | [] |
| sprite_fly_drop_p0 | 80 | [] |
| sprite_fly_drop_p1 | 80 | [] |
| sprite_fly_p0 | 80 | [] |
| sprite_hole_fly_p1 | 80 | [] |
| sprite_lamp_drop_p0 | 80 | [0] |
| sprite_lamp_fuse_p0 | 80 | [0] |
| sprite_lamp_p0 | 80 | [0] |
| sprite_lantern_p0 | 80 | [0] |
| sprite_spiderjump_compound | 80 | [] |
| sprite_stone_drops_p1 | 80 | [] |
| sprite_vent_fly_p1 | 80 | [] |
| sprite_xvdial_p1 | 80 | [] |
| flob_explode_p0 | 40 | [] |
| flob_explode_p1 | 40 | [] |
| sprite_button_eyes_p1 | 40 | [0] |
| sprite_console_drop_p1 | 40 | [] |
| sprite_cross_eyes_p1 | 40 | [0] |
| sprite_exit_eyes_w04_p1 | 40 | [0] |
| sprite_eyes_drop_p0 | 40 | [0] |
| sprite_eyes_eyes_p1 | 40 | [0] |
| sprite_lamp_drop_p1 | 40 | [] |
| sprite_light_electro_p0 | 40 | [0] |
| sprite_valve_drops_w01_p1 | 40 | [] |
| sprite_valve_drops_w04_p1 | 40 | [] |
