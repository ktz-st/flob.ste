const SPR_SPRITE_BUTTON_VALVE_P0_FRAME_COUNT = 4;
const SPR_SPRITE_BUTTON_VALVE_P0_FRAMES : array[0..3] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:60; dataOffset:66; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:90; dataOffset:96; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_BUTTON_VALVE_P0_WORDS : array[0..119] of word=(
  $CFFF,$CFFF,$03FF,$03FF,$CFFF,$CFFF,$0000,$0000,
  $0000,$3000,$0000,$0000,$0000,$3000,$0000,$0000,
  $0000,$FC00,$0000,$0000,$0000,$FC00,$0000,$0000,
  $0000,$3000,$0000,$0000,$0000,$3000,$CFFF,$CFFF,
  $03FF,$03FF,$CFFF,$CFFF,$0000,$3000,$3000,$3000,
  $0000,$3000,$3000,$3000,$0000,$FC00,$FC00,$FC00,
  $0000,$FC00,$FC00,$FC00,$0000,$3000,$3000,$3000,
  $0000,$3000,$3000,$3000,$CFFF,$CFFF,$03FF,$03FF,
  $CFFF,$CFFF,$0000,$0000,$0000,$3000,$0000,$0000,
  $0000,$3000,$0000,$0000,$0000,$FC00,$0000,$0000,
  $0000,$FC00,$0000,$0000,$0000,$3000,$0000,$0000,
  $0000,$3000,$CFFF,$CFFF,$03FF,$03FF,$CFFF,$CFFF,
  $0000,$3000,$3000,$3000,$0000,$3000,$3000,$3000,
  $0000,$FC00,$FC00,$FC00,$0000,$FC00,$FC00,$FC00,
  $0000,$3000,$3000,$3000,$0000,$3000,$3000,$3000
);
