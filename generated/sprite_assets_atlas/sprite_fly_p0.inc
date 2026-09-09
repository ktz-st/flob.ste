const SPR_SPRITE_FLY_P0_FRAME_COUNT = 6;
const SPR_SPRITE_FLY_P0_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:60; dataOffset:66; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:90; dataOffset:96; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:120; dataOffset:126; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:150; dataOffset:156; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_FLY_P0_WORDS : array[0..179] of word=(
  $F3CF,$F3CF,$FC3F,$FC3F,$FC3F,$FC3F,$0000,$0C30,
  $0000,$0C30,$0000,$0C30,$0000,$0C30,$0000,$03C0,
  $0000,$03C0,$0000,$03C0,$0000,$03C0,$0000,$03C0,
  $0000,$03C0,$0000,$03C0,$0000,$03C0,$FFFF,$FFFF,
  $F00F,$F00F,$FC3F,$FC3F,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0FF0,$0000,$0FF0,
  $0000,$0FF0,$0000,$0FF0,$0000,$03C0,$0000,$03C0,
  $0000,$03C0,$0000,$03C0,$FC3F,$FC3F,$F00F,$F00F,
  $FFFF,$FFFF,$0000,$03C0,$0000,$03C0,$0000,$03C0,
  $0000,$03C0,$0000,$0FF0,$0000,$0FF0,$0000,$0FF0,
  $0000,$0FF0,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$FC3F,$FC3F,$FC3F,$FC3F,$F3CF,$F3CF,
  $0000,$03C0,$0000,$03C0,$0000,$03C0,$0000,$03C0,
  $0000,$03C0,$0000,$03C0,$0000,$03C0,$0000,$03C0,
  $0000,$0C30,$0000,$0C30,$0000,$0C30,$0000,$0C30,
  $FC3F,$FC3F,$F00F,$F00F,$FFFF,$FFFF,$0000,$03C0,
  $0000,$03C0,$0000,$03C0,$0000,$03C0,$0000,$0FF0,
  $0000,$0FF0,$0000,$0FF0,$0000,$0FF0,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$FFFF,$FFFF,
  $F00F,$F00F,$FC3F,$FC3F,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0FF0,$0000,$0FF0,
  $0000,$0FF0,$0000,$0FF0,$0000,$03C0,$0000,$03C0,
  $0000,$03C0,$0000,$03C0
);
