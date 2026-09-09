const SPR_FLOB_PARTICLE_P1_FRAME_COUNT = 2;
const SPR_FLOB_PARTICLE_P1_FRAMES : array[0..1] of TSteSpriteFrame = (
    (widthPx:2; heightPx:2; rowWords:1; maskOffset:0; dataOffset:2; paletteOffset:0; paletteCount:0),
    (widthPx:2; heightPx:2; rowWords:1; maskOffset:10; dataOffset:12; paletteOffset:0; paletteCount:0)
);

const SPR_FLOB_PARTICLE_P1_WORDS : array[0..19] of word=(
  $3FFF,$BFFF,$C000,$0000,$C000,$0000,$4000,$0000,
  $4000,$0000,$BFFF,$3FFF,$4000,$0000,$4000,$0000,
  $C000,$0000,$C000,$0000
);
