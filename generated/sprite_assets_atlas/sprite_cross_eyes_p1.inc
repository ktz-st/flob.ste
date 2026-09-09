const SPR_SPRITE_CROSS_EYES_P1_FRAME_COUNT = 8;
const SPR_SPRITE_CROSS_EYES_P1_FRAMES : array[0..7] of TSteSpriteFrame = (
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:0; dataOffset:2; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:10; dataOffset:12; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:20; dataOffset:22; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:30; dataOffset:32; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:40; dataOffset:42; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:50; dataOffset:52; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:60; dataOffset:62; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:70; dataOffset:72; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_CROSS_EYES_P1_WORDS : array[0..79] of word=(
  $FFFF,$FFFF,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$33FF,$33FF,$CC00,$CC00,$0000,$CC00,
  $CC00,$CC00,$0000,$CC00,$33FF,$33FF,$CC00,$CC00,
  $0000,$CC00,$CC00,$CC00,$0000,$CC00,$33FF,$33FF,
  $CC00,$CC00,$0000,$CC00,$CC00,$CC00,$0000,$CC00,
  $FFFF,$FFFF,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$33FF,$33FF,$CC00,$CC00,$0000,$CC00,
  $CC00,$CC00,$0000,$CC00,$33FF,$33FF,$CC00,$CC00,
  $0000,$CC00,$CC00,$CC00,$0000,$CC00,$33FF,$33FF,
  $CC00,$CC00,$0000,$CC00,$CC00,$CC00,$0000,$CC00
);
