PPC    = /opt/fpc/lib/fpc/3.3.1/ppcross68k
AS     = vasmm68k_mot
HATARI = hatari

TARGET = flob.prg
MAIN   = flob.pas
TILE_GEN = generate_world_tiles.py
LSY_SHEET_GEN = export_lsy_sheets.py
SPRITE_ASSET_GEN = generate_sprite_assets.py
FLOB_SHEET_GEN = export_flob_sheet.py
ATLAS_SPRITE_ASSET_GEN = generate_sprite_assets_from_atlas.py
TILE_OUT = \
	worlds/world_tiles.inc \
	worlds/world_00_tiles.inc worlds/world_01_tiles.inc worlds/world_02_tiles.inc \
	worlds/world_03_tiles.inc worlds/world_04_tiles.inc worlds/world_05_tiles.inc
PFLAGS = -Tatari -O2 -Si -Xs -dSTE

SOURCES = \
	$(MAIN) \
	const.inc \
	vnumber.inc \
	types.inc \
	interrupts.inc \
	saving_routines.inc \
	bank_0_files.inc \
	assets/sprites.inc \
	worlds/worlds.inc \
	worlds/world_00.inc worlds/world_01.inc worlds/world_02.inc \
	worlds/world_03.inc worlds/world_04.inc worlds/world_05.inc \
	worlds/world_00_assets.inc worlds/world_01_assets.inc worlds/world_02_assets.inc \
	worlds/world_03_assets.inc worlds/world_04_assets.inc worlds/world_05_assets.inc \
	$(TILE_GEN) \
	$(TILE_OUT) \
	images/images.inc

.PHONY: all clean run sprite-sheets sprite-assets flob-sheet sprite-atlas-assets

all: unapl.o $(TARGET)

$(TILE_OUT): $(TILE_GEN)
	python3 $(TILE_GEN)

unapl.o: unapl.s
	$(AS) -quiet -Faout -o unapl.o unapl.s

font.o: asm/font.s
	$(AS) -quiet -Faout -o font.o asm/font.s

$(TARGET): unapl.o font.o $(SOURCES) Makefile
	$(PPC) $(PFLAGS) -o$(TARGET) $(MAIN)

clean:
	rm -f $(TARGET) flob.o flob.s unapl.o font.o *.ppu *.map

run: $(TARGET)
	$(HATARI) -w --monitor rgb --machine ste $(TARGET) &

sprite-sheets: $(LSY_SHEET_GEN)
	python3 $(LSY_SHEET_GEN)

sprite-assets: $(LSY_SHEET_GEN) $(SPRITE_ASSET_GEN)
	python3 $(LSY_SHEET_GEN)
	python3 $(SPRITE_ASSET_GEN)

flob-sheet: $(FLOB_SHEET_GEN)
	python3 $(FLOB_SHEET_GEN)

sprite-atlas-assets: $(ATLAS_SPRITE_ASSET_GEN)
	python3 $(ATLAS_SPRITE_ASSET_GEN)
