const SPR_SPRITE_ELECTRO_BUTTON_P1_FRAME_COUNT = 6;
const SPR_SPRITE_ELECTRO_BUTTON_P1_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_ELECTRO_BUTTON_P1_WORDS : array[0..119] of word=(
  $0FFF,$0FFF,$0FFF,$0FFF,$F000,$F000,$F000,$0000,
  $F000,$F000,$F000,$0000,$F000,$F000,$F000,$0000,
  $F000,$F000,$F000,$0000,$C3FF,$C3FF,$C3FF,$C3FF,
  $3C00,$3C00,$3C00,$0000,$3C00,$3C00,$3C00,$0000,
  $3C00,$3C00,$3C00,$0000,$3C00,$3C00,$3C00,$0000,
  $0FFF,$0FFF,$0FFF,$0FFF,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0FFF,$0FFF,$0FFF,$0FFF,
  $F000,$F000,$F000,$0000,$F000,$F000,$F000,$0000,
  $F000,$F000,$F000,$0000,$F000,$F000,$F000,$0000,
  $C3FF,$C3FF,$C3FF,$C3FF,$3C00,$3C00,$3C00,$0000,
  $3C00,$3C00,$3C00,$0000,$3C00,$3C00,$3C00,$0000,
  $3C00,$3C00,$3C00,$0000,$0FFF,$0FFF,$0FFF,$0FFF,
  $0000,$F000,$F000,$F000,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0000,$F000,$F000,$F000
);
