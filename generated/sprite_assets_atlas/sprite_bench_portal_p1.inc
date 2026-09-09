const SPR_SPRITE_BENCH_PORTAL_P1_FRAME_COUNT = 2;
const SPR_SPRITE_BENCH_PORTAL_P1_FRAMES : array[0..1] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_BENCH_PORTAL_P1_WORDS : array[0..59] of word=(
  $C000,$C000,$C000,$C000,$C000,$C000,$3FFF,$3FFF,
  $0000,$3FFF,$3FFF,$3FFF,$0000,$3FFF,$3FFF,$3FFF,
  $0000,$3FFF,$3FFF,$3FFF,$0000,$3FFF,$3FFF,$3FFF,
  $0000,$3FFF,$3FFF,$3FFF,$0000,$3FFF,$C000,$C000,
  $C000,$C000,$C000,$C000,$3FFF,$3FFF,$0000,$3FFF,
  $3FFF,$3FFF,$0000,$3FFF,$3FFF,$3FFF,$0000,$3FFF,
  $3FFF,$3FFF,$0000,$3FFF,$3FFF,$3FFF,$0000,$3FFF,
  $3FFF,$3FFF,$0000,$3FFF
);
