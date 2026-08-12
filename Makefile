PPC    = /opt/fpc/lib/fpc/3.3.1/ppcross68k
AS     = vasmm68k_mot
HATARI = hatari

TARGET = flob.prg
MAIN   = flob.pas
TILE_GEN = generate_world_tiles.py
LSY_SHEET_GEN = export_lsy_sheets.py
SPRITE_ASSET_GEN = generate_sprite_assets.py
FLOB_SHEET_GEN = export_flob_sheet.py
FULL_ATLAS_SPRITE_GEN = build_full_sprite_atlas.py
USED_ATLAS_SPRITE_GEN = build_used_sprite_atlas.py
ATLAS_SPRITE_ASSET_GEN = generate_sprite_assets_from_atlas.py
WORLD_SPRITE_ATLAS_MAP_GEN = generate_world_sprite_atlas_map.py
SPRITE_COMBINED_CONFIG = sprite_combined_config.py
ACHIEVEMENT_GEN = generate_achievements.py
ENDWORLD_ICON_GEN = generate_endworld_icons.py
WORLD_ICON_GEN = generate_world_icons.py
TILE_OUT = \
	worlds/world_tiles.inc \
	worlds/world_00_tiles.inc worlds/world_01_tiles.inc worlds/world_02_tiles.inc \
	worlds/world_03_tiles.inc worlds/world_04_tiles.inc worlds/world_05_tiles.inc
PFLAGS = -Tatari -O2 -Si -Xs -dSTE -vw -vm -vi

SOURCES = \
	$(MAIN) \
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
	worlds/worlds.inc \
	worlds/world_00.inc worlds/world_01.inc worlds/world_02.inc \
	worlds/world_03.inc worlds/world_04.inc worlds/world_05.inc \
	worlds/world_00_assets.inc worlds/world_01_assets.inc worlds/world_02_assets.inc \
	worlds/world_03_assets.inc worlds/world_04_assets.inc worlds/world_05_assets.inc \
	generated/sprite_assets_atlas.inc \
	generated/sprite_atlas_palette.inc \
	generated/world_sprite_atlas_map.inc \
	$(TILE_GEN) \
	$(ACHIEVEMENT_GEN) \
	$(ENDWORLD_ICON_GEN) \
	$(WORLD_ICON_GEN) \
	$(TILE_OUT) \
	images/images.inc \
	images/global/IMG_TITLE_CROWN.inc

.PHONY: all clean run sprite-sheets sprite-assets flob-sheet used-sprite-atlas sprite-atlas-assets sprite-atlas-assets-only

all: unapl.o $(TARGET)

$(TILE_OUT): $(TILE_GEN)
	python3 $(TILE_GEN)

assets/achievements.inc: $(ACHIEVEMENT_GEN) ../flob/assets/achievements.asm
	python3 $(ACHIEVEMENT_GEN)

assets/endworld_icons.inc: $(ENDWORLD_ICON_GEN) ../flob/assets/bigmap.gif ../flob/assets/bigvial.gif ../flob/assets/bigformula.gif ../flob/assets/skull.gif
	python3 $(ENDWORLD_ICON_GEN)

assets/world_icons.inc: $(WORLD_ICON_GEN) ../flob/worlds/00_Escape_From_The_Lab/images/icon.gif ../flob/worlds/01_Abominable_Sewers/images/icon.gif ../flob/worlds/02_Suburbian_Parkour/images/icon.gif ../flob/worlds/03_Hazardous_Mudlands/images/icon.gif ../flob/worlds/04_Silver_Dust_Mines/images/icon.gif ../flob/worlds/05_Return_To_The_Lab/images/icon.gif
	python3 $(WORLD_ICON_GEN)

images/global/IMG_TITLE_CROWN.inc: convert_images.py ../flob/assets/flob_title.gif ../flob/assets/crown2.gif
	python3 convert_images.py

unapl.o: unapl.s
	$(AS) -quiet -Faout -o unapl.o unapl.s

font.o: asm/font.s
	$(AS) -quiet -Faout -o font.o asm/font.s

ikbd.o: asm/ikbd.s
	$(AS) -quiet -Faout -o ikbd.o asm/ikbd.s

$(TARGET): unapl.o font.o ikbd.o $(SOURCES) Makefile
	$(PPC) $(PFLAGS) -o$(TARGET) $(MAIN)

clean:
	rm -f $(TARGET) flob.o flob.s unapl.o font.o ikbd.o *.ppu *.map

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

sprite-atlas-assets: $(USED_ATLAS_SPRITE_GEN) $(ATLAS_SPRITE_ASSET_GEN) $(WORLD_SPRITE_ATLAS_MAP_GEN) $(SPRITE_COMBINED_CONFIG)
	python3 $(USED_ATLAS_SPRITE_GEN)
	python3 $(ATLAS_SPRITE_ASSET_GEN)
	python3 $(WORLD_SPRITE_ATLAS_MAP_GEN)

sprite-atlas-assets-only: $(ATLAS_SPRITE_ASSET_GEN) $(WORLD_SPRITE_ATLAS_MAP_GEN) $(SPRITE_COMBINED_CONFIG)
	python3 $(ATLAS_SPRITE_ASSET_GEN)
	python3 $(WORLD_SPRITE_ATLAS_MAP_GEN)
