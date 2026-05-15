const SPR_SPRITE_KEY_LAMP_P1_FRAME_COUNT = 4;
const SPR_SPRITE_KEY_LAMP_P1_FRAMES : array[0..3] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:60; dataOffset:66; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:90; dataOffset:96; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_KEY_LAMP_P1_WORDS : array[0..119] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$03FF,$03FF,
  $03FF,$03FF,$03FF,$03FF,$FC00,$FC00,$0000,$FC00,
  $FC00,$FC00,$0000,$FC00,$FC00,$FC00,$0000,$FC00,
  $FC00,$FC00,$0000,$FC00,$FC00,$FC00,$0000,$FC00,
  $FC00,$FC00,$0000,$FC00,$FFFF,$FFFF,$FFFF,$FFFF,
  $FFFF,$FFFF,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,
  $FC00,$FC00,$0000,$FC00,$FC00,$FC00,$0000,$FC00,
  $FC00,$FC00,$0000,$FC00,$FC00,$FC00,$0000,$FC00,
  $FC00,$FC00,$0000,$FC00,$FC00,$FC00,$0000,$FC00
);
