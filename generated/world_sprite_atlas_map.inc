procedure ClearWorldSpriteAtlas;
begin
    FillChar(spriteAtlasFrames, SizeOf(spriteAtlasFrames), 0);
    FillChar(spriteAtlasWords, SizeOf(spriteAtlasWords), 0);
    FillChar(spriteAtlasFrameCount, SizeOf(spriteAtlasFrameCount), 0);
end;

procedure SetupWorldSpriteAtlas(worldNum: byte; addr: word);
begin
    ClearWorldSpriteAtlas;
    case worldNum of
        0: case addr of
            $A000: begin // sprite_cagedoor
            spriteAtlasFrames[0] := @SPR_SPRITE_CAGEDOOR_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CAGEDOOR_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CAGEDOOR_P0_FRAME_COUNT;
            end;
            $A0B4: begin // sprite_xvdial
            spriteAtlasFrames[0] := @SPR_SPRITE_XVDIAL_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_XVDIAL_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_XVDIAL_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_XVDIAL_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_XVDIAL_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_XVDIAL_P1_FRAME_COUNT;
            end;
            $A0F2: begin // sprite_flame
            spriteAtlasFrames[0] := @SPR_SPRITE_FLAME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FLAME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FLAME_MERGED_FRAME_COUNT;
            end;
            $A190: begin // sprite_fly
            spriteAtlasFrames[0] := @SPR_SPRITE_FLY_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FLY_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FLY_P0_FRAME_COUNT;
            end;
            $A1A0: begin // sprite_fireext
            spriteAtlasFrames[0] := @SPR_SPRITE_FIREEXT_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FIREEXT_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FIREEXT_MERGED_FRAME_COUNT;
            end;
            $A228: begin // sprite_sprays
            spriteAtlasFrames[0] := @SPR_SPRITE_SPRAYS_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_SPRAYS_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_SPRAYS_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_SPRAYS_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_SPRAYS_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_SPRAYS_P1_FRAME_COUNT;
            end;
            $A250: begin // sprite_phone
            spriteAtlasFrames[0] := @SPR_SPRITE_PHONE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_PHONE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_PHONE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_PHONE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_PHONE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_PHONE_P1_FRAME_COUNT;
            end;
            $A2F6: begin // sprite_screen_lever
            spriteAtlasFrames[0] := @SPR_SPRITE_SCREEN_LEVER_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_SCREEN_LEVER_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_SCREEN_LEVER_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_SCREEN_LEVER_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_SCREEN_LEVER_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_SCREEN_LEVER_P1_FRAME_COUNT;
            end;
            $A367: begin // sprite_map
            spriteAtlasFrames[0] := @SPR_SPRITE_MAP_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_MAP_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_MAP_MERGED_FRAME_COUNT;
            end;
            $A37D: begin // sprite_exit
            spriteAtlasFrames[0] := @SPR_SPRITE_EXIT_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EXIT_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EXIT_P0_FRAME_COUNT;
            end;
            $A3AD: begin // sprite_bench_portal
            spriteAtlasFrames[0] := @SPR_SPRITE_BENCH_PORTAL_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BENCH_PORTAL_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BENCH_PORTAL_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BENCH_PORTAL_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BENCH_PORTAL_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BENCH_PORTAL_P1_FRAME_COUNT;
            end;
            $A3B9: begin // sprite_stats_portal
            spriteAtlasFrames[0] := @SPR_SPRITE_STATS_PORTAL_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_STATS_PORTAL_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_STATS_PORTAL_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_STATS_PORTAL_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_STATS_PORTAL_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_STATS_PORTAL_P1_FRAME_COUNT;
            end;
            $A3ED: begin // sprite_bigslime
            spriteAtlasFrames[0] := @SPR_SPRITE_BIGSLIME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIGSLIME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIGSLIME_MERGED_FRAME_COUNT;
            end;
            $A461: begin // sprite_bell_flame
            spriteAtlasFrames[0] := @SPR_SPRITE_BELL_FLAME_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BELL_FLAME_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BELL_FLAME_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BELL_FLAME_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BELL_FLAME_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BELL_FLAME_P1_FRAME_COUNT;
            end;
            $A4E5: begin // sprite_drop_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_DROP_EYES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_DROP_EYES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_DROP_EYES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_DROP_EYES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_DROP_EYES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_DROP_EYES_P1_FRAME_COUNT;
            end;
        end;
        1: case addr of
            $A6B8: begin // sprite_valve_thunder
            spriteAtlasFrames[0] := @SPR_SPRITE_VALVE_THUNDER_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VALVE_THUNDER_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VALVE_THUNDER_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_VALVE_THUNDER_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_VALVE_THUNDER_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_VALVE_THUNDER_P1_FRAME_COUNT;
            end;
            $A767: begin // sprite_vial
            spriteAtlasFrames[0] := @SPR_SPRITE_VIAL_W01_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VIAL_W01_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VIAL_W01_MERGED_FRAME_COUNT;
            end;
            $A81B: begin // sprite_exit_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_EXIT_DROP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EXIT_DROP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EXIT_DROP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EXIT_DROP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EXIT_DROP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EXIT_DROP_P1_FRAME_COUNT;
            end;
            $A847: begin // sprite_electro2
            spriteAtlasFrames[0] := @SPR_SPRITE_ELECTRO2_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_ELECTRO2_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_ELECTRO2_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_ELECTRO2_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_ELECTRO2_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_ELECTRO2_P1_FRAME_COUNT;
            end;
            $A8D8: begin // sprite_electro3
            spriteAtlasFrames[0] := @SPR_SPRITE_ELECTRO3_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_ELECTRO3_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_ELECTRO3_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_ELECTRO3_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_ELECTRO3_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_ELECTRO3_P1_FRAME_COUNT;
            end;
            $A912: begin // sprite_lever2
            spriteAtlasFrames[0] := @SPR_SPRITE_LEVER2_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LEVER2_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LEVER2_MERGED_FRAME_COUNT;
            end;
            $AA1E: begin // sprite_bigslime
            spriteAtlasFrames[0] := @SPR_SPRITE_BIGSLIME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIGSLIME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIGSLIME_MERGED_FRAME_COUNT;
            end;
            $AA92: begin // sprite_stone_drops
            spriteAtlasFrames[0] := @SPR_SPRITE_STONE_DROPS_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_STONE_DROPS_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_STONE_DROPS_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_STONE_DROPS_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_STONE_DROPS_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_STONE_DROPS_P1_FRAME_COUNT;
            end;
            $AAA6: begin // sprite_mice_console
            spriteAtlasFrames[0] := @SPR_SPRITE_MICE_CONSOLE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_MICE_CONSOLE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_MICE_CONSOLE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_MICE_CONSOLE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_MICE_CONSOLE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_MICE_CONSOLE_P1_FRAME_COUNT;
            end;
            $AB06: begin // sprite_fly_console
            spriteAtlasFrames[0] := @SPR_SPRITE_FLY_CONSOLE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FLY_CONSOLE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FLY_CONSOLE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_FLY_CONSOLE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_FLY_CONSOLE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_FLY_CONSOLE_P1_FRAME_COUNT;
            end;
            $AB22: begin // sprite_valve_drops
            spriteAtlasFrames[0] := @SPR_SPRITE_VALVE_DROPS_W01_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VALVE_DROPS_W01_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VALVE_DROPS_W01_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_VALVE_DROPS_W01_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_VALVE_DROPS_W01_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_VALVE_DROPS_W01_P1_FRAME_COUNT;
            end;
            $AB77: begin // sprite_vent_fly
            spriteAtlasFrames[0] := @SPR_SPRITE_VENT_FLY_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VENT_FLY_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VENT_FLY_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_VENT_FLY_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_VENT_FLY_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_VENT_FLY_P1_FRAME_COUNT;
            end;
            $ABB3: begin // sprite_eyes_tail
            spriteAtlasFrames[0] := @SPR_SPRITE_EYES_TAIL_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EYES_TAIL_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EYES_TAIL_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EYES_TAIL_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EYES_TAIL_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EYES_TAIL_P1_FRAME_COUNT;
            end;
            $ABE8: begin // sprite_drop1
            spriteAtlasFrames[0] := @SPR_SPRITE_DROP1_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_DROP1_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_DROP1_P0_FRAME_COUNT;
            end;
            $ABF5: begin // sprite_bubbles
            spriteAtlasFrames[0] := @SPR_SPRITE_BUBBLES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BUBBLES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BUBBLES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BUBBLES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BUBBLES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BUBBLES_P1_FRAME_COUNT;
            end;
        end;
        2: case addr of
            $A000: begin // sprite_hole1
            spriteAtlasFrames[0] := @SPR_SPRITE_HOLE1_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_HOLE1_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_HOLE1_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_HOLE1_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_HOLE1_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_HOLE1_P1_FRAME_COUNT;
            end;
            $A03C: begin // sprite_hole2
            spriteAtlasFrames[0] := @SPR_SPRITE_HOLE2_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_HOLE2_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_HOLE2_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_HOLE2_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_HOLE2_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_HOLE2_P1_FRAME_COUNT;
            end;
            $A094: begin // sprite_vial
            spriteAtlasFrames[0] := @SPR_SPRITE_VIAL_W02_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VIAL_W02_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VIAL_W02_MERGED_FRAME_COUNT;
            end;
            $A148: begin // sprite_light_electro
            spriteAtlasFrames[0] := @SPR_SPRITE_LIGHT_ELECTRO_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LIGHT_ELECTRO_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LIGHT_ELECTRO_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_LIGHT_ELECTRO_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_LIGHT_ELECTRO_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_LIGHT_ELECTRO_P1_FRAME_COUNT;
            end;
            $A1B3: begin // sprite_bigslime
            spriteAtlasFrames[0] := @SPR_SPRITE_BIGSLIME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIGSLIME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIGSLIME_MERGED_FRAME_COUNT;
            end;
            $A227: begin // sprite_lamp_fuse
            spriteAtlasFrames[0] := @SPR_SPRITE_LAMP_FUSE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LAMP_FUSE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LAMP_FUSE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_LAMP_FUSE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_LAMP_FUSE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_LAMP_FUSE_P1_FRAME_COUNT;
            end;
            $A254: begin // sprite_ekey
            spriteAtlasFrames[0] := @SPR_SPRITE_EKEY_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EKEY_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EKEY_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EKEY_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EKEY_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EKEY_P1_FRAME_COUNT;
            end;
            $A2F8: begin // sprite_birdpoop
            spriteAtlasFrames[0] := @SPR_SPRITE_BIRDPOOP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIRDPOOP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIRDPOOP_P0_FRAME_COUNT;
            end;
            $A308: begin // sprite_electro_button
            spriteAtlasFrames[0] := @SPR_SPRITE_ELECTRO_BUTTON_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_ELECTRO_BUTTON_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_ELECTRO_BUTTON_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_ELECTRO_BUTTON_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_ELECTRO_BUTTON_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_ELECTRO_BUTTON_P1_FRAME_COUNT;
            end;
            $A378: begin // sprite_jan_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_JAN_DROP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_JAN_DROP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_JAN_DROP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_JAN_DROP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_JAN_DROP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_JAN_DROP_P1_FRAME_COUNT;
            end;
            $A3D6: begin // sprite_cranectl
            spriteAtlasFrames[0] := @SPR_SPRITE_CRANECTL_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CRANECTL_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CRANECTL_P0_FRAME_COUNT;
            end;
            $A3E4: begin // sprite_craneconsole
            spriteAtlasFrames[0] := @SPR_SPRITE_CRANECONSOLE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CRANECONSOLE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CRANECONSOLE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CRANECONSOLE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CRANECONSOLE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CRANECONSOLE_P1_FRAME_COUNT;
            end;
            $A427: begin // sprite_cross_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_CROSS_EYES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CROSS_EYES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CROSS_EYES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CROSS_EYES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CROSS_EYES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CROSS_EYES_P1_FRAME_COUNT;
            end;
            $A441: begin // sprite_2flies
            spriteAtlasFrames[0] := @SPR_SPRITE_2FLIES_W02_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_2FLIES_W02_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_2FLIES_W02_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_2FLIES_W02_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_2FLIES_W02_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_2FLIES_W02_P1_FRAME_COUNT;
            end;
            $A45D: begin // sprite_window_star
            spriteAtlasFrames[0] := @SPR_SPRITE_WINDOW_STAR_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_WINDOW_STAR_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_WINDOW_STAR_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_WINDOW_STAR_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_WINDOW_STAR_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_WINDOW_STAR_P1_FRAME_COUNT;
            end;
            $A477: begin // sprite_fire_lamp
            spriteAtlasFrames[0] := @SPR_SPRITE_FIRE_LAMP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FIRE_LAMP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FIRE_LAMP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_FIRE_LAMP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_FIRE_LAMP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_FIRE_LAMP_P1_FRAME_COUNT;
            end;
            $A4B1: begin // sprite_lantern
            spriteAtlasFrames[0] := @SPR_SPRITE_LANTERN_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LANTERN_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LANTERN_P0_FRAME_COUNT;
            end;
        end;
        3: case addr of
            $A1BE: begin // sprite_lever
            spriteAtlasFrames[0] := @SPR_SPRITE_LEVER_W03_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LEVER_W03_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LEVER_W03_MERGED_FRAME_COUNT;
            end;
            $A278: begin // sprite_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_EYES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EYES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EYES_P0_FRAME_COUNT;
            end;
            $A29C: begin // sprite_bat
            spriteAtlasFrames[0] := @SPR_SPRITE_BAT_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BAT_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BAT_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BAT_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BAT_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BAT_P1_FRAME_COUNT;
            end;
            $A2D8: begin // sprite_valve
            spriteAtlasFrames[0] := @SPR_SPRITE_VALVE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VALVE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VALVE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_VALVE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_VALVE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_VALVE_P1_FRAME_COUNT;
            end;
            $A338: begin // sprite_button
            spriteAtlasFrames[0] := @SPR_SPRITE_BUTTON_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BUTTON_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BUTTON_MERGED_FRAME_COUNT;
            end;
            $A3BA: begin // sprite_gear
            spriteAtlasFrames[0] := @SPR_SPRITE_GEAR_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_GEAR_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_GEAR_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_GEAR_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_GEAR_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_GEAR_P1_FRAME_COUNT;
            end;
            $A48A: begin // sprite_bigslime
            spriteAtlasFrames[0] := @SPR_SPRITE_BIGSLIME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIGSLIME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIGSLIME_MERGED_FRAME_COUNT;
            end;
            $A4FE: begin // sprite_vial
            spriteAtlasFrames[0] := @SPR_SPRITE_VIAL_W03_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VIAL_W03_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VIAL_W03_MERGED_FRAME_COUNT;
            end;
            $A5B2: begin // sprite_exit_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_EXIT_EYES_W03_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EXIT_EYES_W03_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EXIT_EYES_W03_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EXIT_EYES_W03_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EXIT_EYES_W03_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EXIT_EYES_W03_P1_FRAME_COUNT;
            end;
            $A5D7: begin // sprite_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_DROP_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_DROP_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_DROP_MERGED_FRAME_COUNT;
            end;
            $A677: begin // sprite_spiderjump
            spriteAtlasFrames[0] := @SPR_SPRITE_SPIDERJUMP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_SPIDERJUMP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_SPIDERJUMP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_SPIDERJUMP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_SPIDERJUMP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_SPIDERJUMP_P1_FRAME_COUNT;
            end;
            $A6A3: begin // sprite_eye
            spriteAtlasFrames[0] := @SPR_SPRITE_EYE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EYE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EYE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EYE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EYE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EYE_P1_FRAME_COUNT;
            end;
            $A741: begin // sprite_hole_fly
            spriteAtlasFrames[0] := @SPR_SPRITE_HOLE_FLY_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_HOLE_FLY_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_HOLE_FLY_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_HOLE_FLY_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_HOLE_FLY_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_HOLE_FLY_P1_FRAME_COUNT;
            end;
            $A771: begin // sprite_hole
            spriteAtlasFrames[0] := @SPR_SPRITE_HOLE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_HOLE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_HOLE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_HOLE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_HOLE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_HOLE_P1_FRAME_COUNT;
            end;
        end;
        4: case addr of
            $A000: begin // sprite_bigslime
            spriteAtlasFrames[0] := @SPR_SPRITE_BIGSLIME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIGSLIME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIGSLIME_MERGED_FRAME_COUNT;
            end;
            $A074: begin // sprite_bat
            spriteAtlasFrames[0] := @SPR_SPRITE_BAT_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BAT_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BAT_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BAT_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BAT_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BAT_P1_FRAME_COUNT;
            end;
            $A0B0: begin // sprite_exit_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_EXIT_EYES_W04_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EXIT_EYES_W04_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EXIT_EYES_W04_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EXIT_EYES_W04_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EXIT_EYES_W04_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EXIT_EYES_W04_P1_FRAME_COUNT;
            end;
            $A0D6: begin // sprite_lights
            spriteAtlasFrames[0] := @SPR_SPRITE_LIGHTS_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LIGHTS_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LIGHTS_P0_FRAME_COUNT;
            end;
            $A0EE: begin // sprite_birdpoop
            spriteAtlasFrames[0] := @SPR_SPRITE_BIRDPOOP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIRDPOOP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIRDPOOP_P0_FRAME_COUNT;
            end;
            $A0FE: begin // sprite_fire_console
            spriteAtlasFrames[0] := @SPR_SPRITE_FIRE_CONSOLE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FIRE_CONSOLE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FIRE_CONSOLE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_FIRE_CONSOLE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_FIRE_CONSOLE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_FIRE_CONSOLE_P1_FRAME_COUNT;
            end;
            $A14F: begin // sprite_2flies
            spriteAtlasFrames[0] := @SPR_SPRITE_2FLIES_W04_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_2FLIES_W04_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_2FLIES_W04_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_2FLIES_W04_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_2FLIES_W04_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_2FLIES_W04_P1_FRAME_COUNT;
            end;
            $A16B: begin // sprite_console
            spriteAtlasFrames[0] := @SPR_SPRITE_CONSOLE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CONSOLE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CONSOLE_P0_FRAME_COUNT;
            end;
            $A1A7: begin // sprite_console2
            spriteAtlasFrames[0] := @SPR_SPRITE_CONSOLE2_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CONSOLE2_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CONSOLE2_P0_FRAME_COUNT;
            end;
            $A1C9: begin // sprite_valve_drops
            spriteAtlasFrames[0] := @SPR_SPRITE_VALVE_DROPS_W04_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VALVE_DROPS_W04_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VALVE_DROPS_W04_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_VALVE_DROPS_W04_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_VALVE_DROPS_W04_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_VALVE_DROPS_W04_P1_FRAME_COUNT;
            end;
            $A21E: begin // sprite_vial
            spriteAtlasFrames[0] := @SPR_SPRITE_VIAL_W04_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_VIAL_W04_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_VIAL_W04_MERGED_FRAME_COUNT;
            end;
            $A2D2: begin // sprite_rat
            spriteAtlasFrames[0] := @SPR_SPRITE_RAT_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_RAT_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_RAT_P0_FRAME_COUNT;
            end;
            $A326: begin // sprite_console_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_CONSOLE_DROP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CONSOLE_DROP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CONSOLE_DROP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CONSOLE_DROP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CONSOLE_DROP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CONSOLE_DROP_P1_FRAME_COUNT;
            end;
            $A379: begin // sprite_box_fly
            spriteAtlasFrames[0] := @SPR_SPRITE_BOX_FLY_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BOX_FLY_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BOX_FLY_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BOX_FLY_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BOX_FLY_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BOX_FLY_P1_FRAME_COUNT;
            end;
            $A3A7: begin // sprite_lamp
            spriteAtlasFrames[0] := @SPR_SPRITE_LAMP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LAMP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LAMP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_LAMP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_LAMP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_LAMP_P1_FRAME_COUNT;
            end;
            $A3F0: begin // sprite_lamp_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_LAMP_DROP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LAMP_DROP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LAMP_DROP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_LAMP_DROP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_LAMP_DROP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_LAMP_DROP_P1_FRAME_COUNT;
            end;
            $A403: begin // sprite_button_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_BUTTON_EYES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BUTTON_EYES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BUTTON_EYES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BUTTON_EYES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BUTTON_EYES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BUTTON_EYES_P1_FRAME_COUNT;
            end;
            $A427: begin // sprite_switch
            spriteAtlasFrames[0] := @SPR_SPRITE_SWITCH_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_SWITCH_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_SWITCH_P0_FRAME_COUNT;
            end;
            $A440: begin // sprite_lever
            spriteAtlasFrames[0] := @SPR_SPRITE_LEVER_W04_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_LEVER_W04_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_LEVER_W04_P0_FRAME_COUNT;
            end;
            $A4BB: begin // sprite_eyes_eyes
            spriteAtlasFrames[0] := @SPR_SPRITE_EYES_EYES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EYES_EYES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EYES_EYES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EYES_EYES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EYES_EYES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EYES_EYES_P1_FRAME_COUNT;
            end;
        end;
        5: case addr of
            $A000: begin // sprite_bigslime
            spriteAtlasFrames[0] := @SPR_SPRITE_BIGSLIME_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BIGSLIME_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BIGSLIME_MERGED_FRAME_COUNT;
            end;
            $A074: begin // sprite_button_valve
            spriteAtlasFrames[0] := @SPR_SPRITE_BUTTON_VALVE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_BUTTON_VALVE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_BUTTON_VALVE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_BUTTON_VALVE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_BUTTON_VALVE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_BUTTON_VALVE_P1_FRAME_COUNT;
            end;
            $A089: begin // sprite_2consolas
            spriteAtlasFrames[0] := @SPR_SPRITE_2CONSOLAS_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_2CONSOLAS_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_2CONSOLAS_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_2CONSOLAS_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_2CONSOLAS_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_2CONSOLAS_P1_FRAME_COUNT;
            end;
            $A11D: begin // sprite_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_DROP_MERGED_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_DROP_MERGED_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_DROP_MERGED_FRAME_COUNT;
            end;
            $A1BD: begin // sprite_2flames
            spriteAtlasFrames[0] := @SPR_SPRITE_2FLAMES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_2FLAMES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_2FLAMES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_2FLAMES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_2FLAMES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_2FLAMES_P1_FRAME_COUNT;
            end;
            $A209: begin // sprite_exit_heart
            spriteAtlasFrames[0] := @SPR_SPRITE_EXIT_HEART_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EXIT_HEART_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EXIT_HEART_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EXIT_HEART_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EXIT_HEART_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EXIT_HEART_P1_FRAME_COUNT;
            end;
            $A234: begin // sprite_fly_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_FLY_DROP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_FLY_DROP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_FLY_DROP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_FLY_DROP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_FLY_DROP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_FLY_DROP_P1_FRAME_COUNT;
            end;
            $A24D: begin // sprite_card_spray
            spriteAtlasFrames[0] := @SPR_SPRITE_CARD_SPRAY_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CARD_SPRAY_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CARD_SPRAY_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CARD_SPRAY_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CARD_SPRAY_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CARD_SPRAY_P1_FRAME_COUNT;
            end;
            $A28B: begin // sprite_console_dot
            spriteAtlasFrames[0] := @SPR_SPRITE_CONSOLE_DOT_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CONSOLE_DOT_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CONSOLE_DOT_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CONSOLE_DOT_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CONSOLE_DOT_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CONSOLE_DOT_P1_FRAME_COUNT;
            end;
            $A2F7: begin // sprite_card_meteor
            spriteAtlasFrames[0] := @SPR_SPRITE_CARD_METEOR_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CARD_METEOR_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CARD_METEOR_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CARD_METEOR_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CARD_METEOR_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CARD_METEOR_P1_FRAME_COUNT;
            end;
            $A350: begin // sprite_key_lamp
            spriteAtlasFrames[0] := @SPR_SPRITE_KEY_LAMP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_KEY_LAMP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_KEY_LAMP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_KEY_LAMP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_KEY_LAMP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_KEY_LAMP_P1_FRAME_COUNT;
            end;
            $A3A4: begin // sprite_eyes_glasses
            spriteAtlasFrames[0] := @SPR_SPRITE_EYES_GLASSES_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EYES_GLASSES_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EYES_GLASSES_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EYES_GLASSES_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EYES_GLASSES_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EYES_GLASSES_P1_FRAME_COUNT;
            end;
            $A3B1: begin // sprite_card
            spriteAtlasFrames[0] := @SPR_SPRITE_CARD_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CARD_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CARD_P0_FRAME_COUNT;
            end;
            $A3DD: begin // sprite_card2
            spriteAtlasFrames[0] := @SPR_SPRITE_CARD2_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CARD2_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CARD2_P0_FRAME_COUNT;
            end;
            $A409: begin // sprite_card_recipe
            spriteAtlasFrames[0] := @SPR_SPRITE_CARD_RECIPE_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_CARD_RECIPE_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_CARD_RECIPE_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_CARD_RECIPE_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_CARD_RECIPE_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_CARD_RECIPE_P1_FRAME_COUNT;
            end;
            $A475: begin // sprite_eyes_drop
            spriteAtlasFrames[0] := @SPR_SPRITE_EYES_DROP_P0_FRAMES[0];
            spriteAtlasWords[0] := @SPR_SPRITE_EYES_DROP_P0_WORDS[0];
            spriteAtlasFrameCount[0] := SPR_SPRITE_EYES_DROP_P0_FRAME_COUNT;
            spriteAtlasFrames[1] := @SPR_SPRITE_EYES_DROP_P1_FRAMES[0];
            spriteAtlasWords[1] := @SPR_SPRITE_EYES_DROP_P1_WORDS[0];
            spriteAtlasFrameCount[1] := SPR_SPRITE_EYES_DROP_P1_FRAME_COUNT;
            end;
        end;
    end;
end;
