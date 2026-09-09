const SPR_SPRITE_CONSOLE_DOT_P1_FRAME_COUNT = 4;
const SPR_SPRITE_CONSOLE_DOT_P1_FRAMES : array[0..3] of TSteSpriteFrame = (
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:0; dataOffset:2; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:10; dataOffset:12; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:20; dataOffset:22; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:30; dataOffset:32; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_CONSOLE_DOT_P1_WORDS : array[0..39] of word=(
  $3FFF,$3FFF,$0000,$0000,$0000,$C000,$0000,$0000,
  $0000,$C000,$3FFF,$3FFF,$C000,$C000,$0000,$C000,
  $C000,$C000,$0000,$C000,$3FFF,$3FFF,$0000,$0000,
  $0000,$C000,$0000,$0000,$0000,$C000,$3FFF,$3FFF,
  $C000,$C000,$0000,$C000,$C000,$C000,$0000,$C000
);
