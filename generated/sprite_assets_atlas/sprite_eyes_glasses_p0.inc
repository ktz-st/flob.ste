const SPR_SPRITE_EYES_GLASSES_P0_FRAME_COUNT = 6;
const SPR_SPRITE_EYES_GLASSES_P0_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:0; dataOffset:2; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:10; dataOffset:12; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:20; dataOffset:22; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:30; dataOffset:32; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:40; dataOffset:42; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:2; rowWords:1; maskOffset:50; dataOffset:52; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_EYES_GLASSES_P0_WORDS : array[0..59] of word=(
  $CF3F,$CF3F,$30C0,$0000,$30C0,$30C0,$30C0,$0000,
  $30C0,$30C0,$3CFF,$3CFF,$C300,$0000,$C300,$C300,
  $C300,$0000,$C300,$C300,$0C3F,$0C3F,$0000,$F3C0,
  $0000,$F3C0,$0000,$F3C0,$0000,$F3C0,$CF3F,$CF3F,
  $30C0,$0000,$30C0,$30C0,$30C0,$0000,$30C0,$30C0,
  $3CFF,$3CFF,$C300,$0000,$C300,$C300,$C300,$0000,
  $C300,$C300,$0C3F,$0C3F,$0000,$F3C0,$0000,$F3C0,
  $0000,$F3C0,$0000,$F3C0
);
