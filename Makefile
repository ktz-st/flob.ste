PPC    = /opt/fpc/lib/fpc/3.3.1/ppcross68k
AS     = vasmm68k_mot
HATARI = hatari

TARGET = flob.prg
MAIN   = flob.pas
PALETTE_GEN = generate_palette.py
PALETTE_INC = palette.inc
PALETTE_SOURCE = assets/a8_pal_rgb.hex
PALETTE_RGB = generated/a8-pal-rgb.pal
TILE_GEN = generate_world_tiles.py
GAME_TILE_GEN = create_game_tiles.py
LSY_SHEET_GEN = export_lsy_sheets.py
SPRITE_ASSET_GEN = generate_sprite_assets.py
FLOB_SHEET_GEN = export_flob_sheet.py
FULL_ATLAS_SPRITE_GEN = build_full_sprite_atlas.py
USED_ATLAS_SPRITE_GEN = build_used_sprite_atlas.py
GAME_SPRITE_SHEET_GEN = create_game_sprite_sheet.py
GAME_ROOM_GEN = create_game_rooms.py
GAME_ROOM_IMAGES = $(shell find game_rooms -type f -name 'room_??.png' 2>/dev/null)
GAME_TILE_IMAGES = $(shell find game_tiles -type f -name '*.png' 2>/dev/null)
ATLAS_SPRITE_ASSET_GEN = generate_sprite_assets_from_atlas.py
WORLD_SPRITE_ATLAS_MAP_GEN = generate_world_sprite_atlas_map.py
SPRITE_COMBINED_CONFIG = sprite_combined_config.py
ACHIEVEMENT_GEN = generate_achievements.py
ENDWORLD_ICON_GEN = generate_endworld_icons.py
GAME_ENDWORLD_ICON_GEN = create_game_endworld_icons.py
GAME_ENDWORLD_ICON_IMAGES = $(shell find game_endworld_icons -type f -name '*.png' 2>/dev/null)
WORLD_ICON_GEN = generate_world_icons.py
GAME_WORLD_ICON_GEN = create_game_world_icons.py
GAME_WORLD_ICON_IMAGES = $(shell find game_world_icons -type f -name '*.png' 2>/dev/null)
GAME_CUTSCENE_GEN = create_game_cutscenes.py
GAME_CUTSCENE_IMAGES = $(shell find game_cutscenes -type f -name '*.png' 2>/dev/null)
GAME_TITLE_GEN = create_game_title.py
GAME_TITLE_IMAGES = $(shell find game_title -type f -name '*.png' 2>/dev/null)
SFX_WAV_GEN = extract_a8_sfx.py
SFX_INC_GEN = generate_sfx_include.py
SFX_INC = assets/sfx_raw.inc
SFX_SYNTH_GEN = generate_sfx_synth.py
SFX_SYNTH_INC = assets/sfx_synth.inc
MUSIC_INC_GEN = generate_music_include.py
MUSIC_LOOP_GEN = retarget_music_loops.py
MUSIC_THEME_INC = assets/music_theme.inc
MUSIC_FYM = \
	audio/ym_music/flob_theme.fym audio/ym_music/flob_world_00.fym \
	audio/ym_music/flob_world_01.fym audio/ym_music/flob_world_02.fym \
	audio/ym_music/flob_world_03.fym audio/ym_music/flob_world_04.fym \
	audio/ym_music/flob_intro.fym audio/ym_music/flob_outro.fym \
	audio/ym_music/flob_endgame.fym
MUSIC_FYM_APL = $(addsuffix .apl,$(MUSIC_FYM))
SFX_RAW = \
	audio/ste_sfx_wav/flip.raw audio/ste_sfx_wav/slime_pick.raw \
	audio/ste_sfx_wav/dead.raw audio/ste_sfx_wav/pick_all.raw \
	audio/ste_sfx_wav/pick_goal.raw audio/ste_sfx_wav/reveal.raw \
	audio/ste_sfx_wav/big_slime.raw audio/ste_sfx_wav/console.raw \
	audio/ste_sfx_wav/water_drop.raw audio/ste_sfx_wav/lever.raw \
	audio/ste_sfx_wav/siren.raw audio/ste_sfx_wav/circuit.raw \
	audio/ste_sfx_wav/gear.raw audio/ste_sfx_wav/valve.raw \
	audio/ste_sfx_wav/bell.raw audio/ste_sfx_wav/gas.raw \
	audio/ste_sfx_wav/insect.raw
WORLD_DATA_GEN = generate_world_data.py
WORLD_BIN_FILES = $(shell find ../flob/worlds -type f -name 'world_??.bin' 2>/dev/null)
WORLD_COLLISION_IMAGES = $(shell find game_rooms -type f -name 'room_??_collision.png' 2>/dev/null)
TILE_OUT = \
	worlds/world_tiles.inc \
	worlds/world_00_tiles.inc worlds/world_01_tiles.inc worlds/world_02_tiles.inc \
	worlds/world_03_tiles.inc worlds/world_04_tiles.inc worlds/world_05_tiles.inc
PFLAGS = -Tatari -O2 -Si -Xs -dSTE -vw -vm -vi

SOURCES = \
	$(MAIN) \
	$(PALETTE_INC) \
	const.inc \
	vnumber.inc \
	types.inc \
	input.inc \
	saving_routines.inc \
	bank_0_files.inc \
	assets/sprites.inc \
	assets/achievements.inc \
	assets/endworld_icons.inc \
	assets/world_icons.inc \
	assets/selector_ui.inc \
	assets/achievement_ui.inc \
	assets/stats_header.inc \
	worlds/worlds.inc \
	worlds/world_00.inc worlds/world_01.inc worlds/world_02.inc \
	worlds/world_03.inc worlds/world_04.inc worlds/world_05.inc \
	worlds/world_00_assets.inc worlds/world_01_assets.inc worlds/world_02_assets.inc \
	worlds/world_03_assets.inc worlds/world_04_assets.inc worlds/world_05_assets.inc \
	worlds/world_collisions.inc \
	generated/sprite_assets_atlas.inc \
	generated/sprite_atlas_palette.inc \
	generated/world_sprite_atlas_map.inc \
	$(SFX_SYNTH_INC) \
	$(MUSIC_THEME_INC) \
	$(TILE_GEN) \
	$(ACHIEVEMENT_GEN) \
	$(ENDWORLD_ICON_GEN) \
	$(WORLD_ICON_GEN) \
	$(TILE_OUT) \
	images/images.inc \
	images/global/IMG_TITLE_CROWN.inc

.PHONY: all clean run sprite-sheets sprite-assets flob-sheet used-sprite-atlas game-sprite-sheet-init game-sprite-guide sprite-atlas-assets sprite-atlas-assets-only game-rooms-init room-assets game-tiles-init game-world-icons-init game-endworld-icons-init game-cutscenes-init game-title-init sfx-wav sfx-psg music-loops

all: unapl.o $(TARGET)

$(PALETTE_INC) $(PALETTE_RGB): $(PALETTE_GEN) $(PALETTE_SOURCE)
	python3 $(PALETTE_GEN)

$(SFX_INC): $(SFX_INC_GEN) $(SFX_RAW)
	python3 $(SFX_INC_GEN)

$(SFX_SYNTH_INC): $(SFX_SYNTH_GEN) $(SFX_WAV_GEN) ../flob/flob.xex $(shell find ../flob/worlds -name '_flob_ingame.rmt')
	python3 $(SFX_SYNTH_GEN)

$(MUSIC_THEME_INC): $(MUSIC_INC_GEN) $(MUSIC_FYM) $(MUSIC_FYM_APL)
	python3 $(MUSIC_INC_GEN)

worlds/world_collisions.inc: $(WORLD_DATA_GEN) game_rooms/manifest.json $(WORLD_BIN_FILES) $(WORLD_COLLISION_IMAGES)
	python3 $(WORLD_DATA_GEN)

$(TILE_OUT): $(TILE_GEN) game_tiles/manifest.json $(GAME_TILE_IMAGES)
	python3 $(TILE_GEN)

assets/achievements.inc: $(ACHIEVEMENT_GEN) ../flob/assets/achievements.asm
	python3 $(ACHIEVEMENT_GEN)

assets/endworld_icons.inc: $(ENDWORLD_ICON_GEN) game_endworld_icons/manifest.json $(GAME_ENDWORLD_ICON_IMAGES)
	python3 $(ENDWORLD_ICON_GEN)

assets/world_icons.inc: $(WORLD_ICON_GEN) game_world_icons/manifest.json $(GAME_WORLD_ICON_IMAGES)
	python3 $(WORLD_ICON_GEN)

assets/stats_header.inc: generate_stats_header.py generate_selector_assets.py generate_world_icons.py ../flob/assets/stats_header.gfx assets/a8_pal_rgb.hex
	python3 generate_stats_header.py

assets/achievement_ui.inc: generate_achievement_ui.py generate_selector_assets.py generate_world_icons.py generate_achievements.py render_title_dli.py ../flob/assets/sprites.asm ../flob/assets/achievements.asm ../flob/assets/flob.fnt assets/a8_pal_rgb.hex
	python3 generate_achievement_ui.py

assets/selector_ui.inc: generate_selector_assets.py export_flob_sheet.py create_game_world_icons.py generate_world_icons.py render_title_dli.py ../flob/assets/flob.fnt ../flob/assets/sprites.asm ../flob/const.inc $(GAME_WORLD_ICON_IMAGES) $(wildcard ../flob/worlds/*/world_??.asm) $(wildcard ../flob/worlds/*/icon.gfx)
	python3 generate_selector_assets.py

images/images.inc: convert_images.py $(GAME_ROOM_IMAGES) game_cutscenes/manifest.json $(GAME_CUTSCENE_IMAGES) game_title/manifest.json $(GAME_TITLE_IMAGES)
	python3 convert_images.py

images/global/IMG_TITLE_CROWN.inc: images/images.inc

unapl.o: unapl.s
	$(AS) -quiet -Faout -o unapl.o unapl.s

font.o: asm/font.s
	$(AS) -quiet -Faout -o font.o asm/font.s

ikbd.o: asm/ikbd.s
	$(AS) -quiet -Faout -o ikbd.o asm/ikbd.s

dmasound.o: dmasound.s
	$(AS) -quiet -Faout -o dmasound.o dmasound.s

sfxsynth.o: asm/sfxsynth.s
	$(AS) -quiet -Faout -o sfxsynth.o asm/sfxsynth.s

psgsound.o: asm/psgsound.s
	$(AS) -quiet -Faout -o psgsound.o asm/psgsound.s

$(TARGET): unapl.o font.o ikbd.o dmasound.o sfxsynth.o psgsound.o $(SOURCES) Makefile
	$(PPC) $(PFLAGS) -o$(TARGET) $(MAIN)

clean:
	rm -f $(TARGET) flob.o flob.s unapl.o font.o ikbd.o dmasound.o sfxsynth.o psgsound.o *.ppu *.map

run: $(TARGET)
	$(HATARI) -w --monitor rgb --machine ste --fast-boot true $(TARGET) &

sprite-sheets: $(LSY_SHEET_GEN)
	python3 $(LSY_SHEET_GEN)

sprite-assets: $(LSY_SHEET_GEN) $(SPRITE_ASSET_GEN)
	python3 $(LSY_SHEET_GEN)
	python3 $(SPRITE_ASSET_GEN)

flob-sheet: $(FLOB_SHEET_GEN)
	python3 $(FLOB_SHEET_GEN)

used-sprite-atlas: $(USED_ATLAS_SPRITE_GEN)
	python3 $(USED_ATLAS_SPRITE_GEN)

game-sprite-sheet-init: $(GAME_SPRITE_SHEET_GEN)
	python3 $(GAME_SPRITE_SHEET_GEN)

game-sprite-guide: $(GAME_SPRITE_SHEET_GEN)
	python3 $(GAME_SPRITE_SHEET_GEN) --guide-only

game-rooms-init: $(GAME_ROOM_GEN)
	python3 $(GAME_ROOM_GEN)

room-assets: images/images.inc

game-tiles-init: $(GAME_TILE_GEN)
	python3 $(GAME_TILE_GEN)

game-world-icons-init: $(GAME_WORLD_ICON_GEN)
	python3 $(GAME_WORLD_ICON_GEN)

game-endworld-icons-init: $(GAME_ENDWORLD_ICON_GEN)
	python3 $(GAME_ENDWORLD_ICON_GEN)

game-cutscenes-init: $(GAME_CUTSCENE_GEN)
	python3 $(GAME_CUTSCENE_GEN)

game-title-init: $(GAME_TITLE_GEN)
	python3 $(GAME_TITLE_GEN)

sfx-wav: $(SFX_WAV_GEN)
	python3 $(SFX_WAV_GEN)

sfx-psg: $(SFX_SYNTH_GEN) $(SFX_WAV_GEN)
	python3 $(SFX_SYNTH_GEN)

music-loops: $(MUSIC_LOOP_GEN) $(MUSIC_INC_GEN)
	python3 $(MUSIC_LOOP_GEN)
	python3 $(MUSIC_INC_GEN)

sprite-atlas-assets: $(ATLAS_SPRITE_ASSET_GEN) $(WORLD_SPRITE_ATLAS_MAP_GEN) $(SPRITE_COMBINED_CONFIG)
	python3 $(ATLAS_SPRITE_ASSET_GEN)
	python3 $(WORLD_SPRITE_ATLAS_MAP_GEN)

sprite-atlas-assets-only: $(ATLAS_SPRITE_ASSET_GEN) $(WORLD_SPRITE_ATLAS_MAP_GEN) $(SPRITE_COMBINED_CONFIG)
	python3 $(ATLAS_SPRITE_ASSET_GEN)
	python3 $(WORLD_SPRITE_ATLAS_MAP_GEN)
