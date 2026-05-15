const SPR_SPRITE_VALVE_DROPS_W01_P1_FRAME_COUNT = 6;
const SPR_SPRITE_VALVE_DROPS_W01_P1_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_VALVE_DROPS_W01_P1_WORDS : array[0..119] of word=(
  $FC3F,$FC3F,$FC3F,$FC3F,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$F3CF,$F3CF,$FC3F,$FC3F,
  $0C30,$0000,$0000,$0C30,$0C30,$0000,$0000,$0C30,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $FFFF,$FFFF,$F00F,$F00F,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0FF0,$0000,$0FF0,$0FF0,
  $0FF0,$0000,$0FF0,$0FF0,$FC3F,$FC3F,$FC3F,$FC3F,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $FC3F,$FC3F,$F3CF,$F3CF,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$0C30,$0000,$0000,$0C30,
  $0C30,$0000,$0000,$0C30,$F00F,$F00F,$FFFF,$FFFF,
  $0FF0,$0000,$0FF0,$0FF0,$0FF0,$0000,$0FF0,$0FF0,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
);
