const SPR_FLOB_PARTICLE_P0_FRAME_COUNT = 2;
const SPR_FLOB_PARTICLE_P0_FRAMES : array[0..1] of TSteSpriteFrame = (
    (widthPx:2; heightPx:2; rowWords:1; maskOffset:0; dataOffset:2; paletteOffset:0; paletteCount:0),
    (widthPx:2; heightPx:2; rowWords:1; maskOffset:10; dataOffset:12; paletteOffset:0; paletteCount:0)
);

const SPR_FLOB_PARTICLE_P0_WORDS : array[0..19] of word=(
  $3FFF,$7FFF,$0000,$0000,$C000,$0000,$0000,$0000,
  $8000,$0000,$7FFF,$3FFF,$0000,$0000,$8000,$0000,
  $0000,$0000,$C000,$0000
);
