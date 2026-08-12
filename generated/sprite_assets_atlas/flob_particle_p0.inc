const SPR_FLOB_PARTICLE_P0_FRAME_COUNT = 2;
const SPR_FLOB_PARTICLE_P0_FRAMES : array[0..1] of TSteSpriteFrame = (
    (widthPx:2; heightPx:2; rowWords:1; maskOffset:0; dataOffset:2; paletteOffset:0; paletteCount:0),
    (widthPx:2; heightPx:2; rowWords:1; maskOffset:10; dataOffset:12; paletteOffset:0; paletteCount:0)
);

const SPR_FLOB_PARTICLE_P0_WORDS : array[0..19] of word=(
  $3FFF,$3FFF,$C000,$C000,$0000,$C000,$C000,$C000,
  $0000,$C000,$3FFF,$3FFF,$C000,$C000,$0000,$C000,
  $C000,$C000,$0000,$C000
);
