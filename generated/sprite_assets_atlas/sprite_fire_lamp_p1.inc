const SPR_SPRITE_FIRE_LAMP_P1_FRAME_COUNT = 4;
const SPR_SPRITE_FIRE_LAMP_P1_FRAMES : array[0..3] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_FIRE_LAMP_P1_WORDS : array[0..79] of word=(
  $0FFF,$0FFF,$0FFF,$0FFF,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0FFF,$0FFF,$0FFF,$0FFF,
  $F000,$0000,$F000,$0000,$F000,$0000,$F000,$0000,
  $F000,$0000,$F000,$0000,$F000,$0000,$F000,$0000,
  $0FFF,$0FFF,$0FFF,$0FFF,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0000,$F000,$F000,$F000,
  $0000,$F000,$F000,$F000,$0FFF,$0FFF,$0FFF,$0FFF,
  $F000,$0000,$F000,$0000,$F000,$0000,$F000,$0000,
  $F000,$0000,$F000,$0000,$F000,$0000,$F000,$0000
);
