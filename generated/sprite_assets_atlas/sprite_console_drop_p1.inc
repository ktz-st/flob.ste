const SPR_SPRITE_CONSOLE_DROP_P1_FRAME_COUNT = 6;
const SPR_SPRITE_CONSOLE_DROP_P1_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_CONSOLE_DROP_P1_WORDS : array[0..119] of word=(
  $CFFF,$CFFF,$CFFF,$CFFF,$3000,$3000,$0000,$3000,
  $3000,$3000,$0000,$3000,$3000,$3000,$0000,$3000,
  $3000,$3000,$0000,$3000,$33FF,$33FF,$CFFF,$CFFF,
  $CC00,$CC00,$0000,$CC00,$CC00,$CC00,$0000,$CC00,
  $3000,$3000,$0000,$3000,$3000,$3000,$0000,$3000,
  $FFFF,$FFFF,$33FF,$33FF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$CC00,$CC00,$0000,$CC00,
  $CC00,$CC00,$0000,$CC00,$CFFF,$CFFF,$CFFF,$CFFF,
  $3000,$3000,$0000,$3000,$3000,$3000,$0000,$3000,
  $3000,$3000,$0000,$3000,$3000,$3000,$0000,$3000,
  $CFFF,$CFFF,$33FF,$33FF,$3000,$3000,$0000,$3000,
  $3000,$3000,$0000,$3000,$CC00,$CC00,$0000,$CC00,
  $CC00,$CC00,$0000,$CC00,$33FF,$33FF,$FFFF,$FFFF,
  $CC00,$CC00,$0000,$CC00,$CC00,$CC00,$0000,$CC00,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
);
