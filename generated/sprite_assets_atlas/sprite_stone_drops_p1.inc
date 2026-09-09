const SPR_SPRITE_STONE_DROPS_P1_FRAME_COUNT = 6;
const SPR_SPRITE_STONE_DROPS_P1_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_STONE_DROPS_P1_WORDS : array[0..119] of word=(
  $FFFF,$FFFF,$F3FF,$F3FF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0C00,$0C00,$0000,$0C00,
  $0C00,$0C00,$0000,$0C00,$CCFF,$CCFF,$F3FF,$F3FF,
  $3300,$3300,$0000,$3300,$3300,$3300,$0000,$3300,
  $0C00,$0C00,$0000,$0C00,$0C00,$0C00,$0000,$0C00,
  $FFFF,$FFFF,$0C3F,$0C3F,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$F3C0,$F3C0,$0000,$F3C0,
  $F3C0,$F3C0,$0000,$F3C0,$F3FF,$F3FF,$FFFF,$FFFF,
  $0C00,$0C00,$0000,$0C00,$0C00,$0C00,$0000,$0C00,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $F3FF,$F3FF,$CCFF,$CCFF,$0C00,$0C00,$0000,$0C00,
  $0C00,$0C00,$0000,$0C00,$3300,$3300,$0000,$3300,
  $3300,$3300,$0000,$3300,$0C3F,$0C3F,$FFFF,$FFFF,
  $F3C0,$F3C0,$0000,$F3C0,$F3C0,$F3C0,$0000,$F3C0,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
);
