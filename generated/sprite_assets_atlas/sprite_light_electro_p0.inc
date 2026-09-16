const SPR_SPRITE_LIGHT_ELECTRO_P0_FRAME_COUNT = 4;
const SPR_SPRITE_LIGHT_ELECTRO_P0_FRAMES : array[0..3] of TSteSpriteFrame = (
    (widthPx:32; heightPx:2; rowWords:2; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:32; heightPx:2; rowWords:2; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:32; heightPx:2; rowWords:2; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:32; heightPx:2; rowWords:2; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_LIGHT_ELECTRO_P0_WORDS : array[0..79] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$00FF,$0000,$00FF,
  $0000,$FFFF,$0000,$FFFF,$0000,$FF00,$0000,$FF00,
  $0000,$FFFF,$0000,$FFFF,$0000,$FF00,$0000,$FF00,
  $FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$00FF,$0000,$00FF,
  $0000,$FFFF,$0000,$FFFF,$0000,$FF00,$0000,$FF00,
  $0000,$FFFF,$0000,$FFFF,$0000,$FF00,$0000,$FF00
);
