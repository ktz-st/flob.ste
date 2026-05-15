const SPR_SPRITE_EXIT_DROP_P1_FRAME_COUNT = 8;
const SPR_SPRITE_EXIT_DROP_P1_FRAMES : array[0..7] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:60; dataOffset:66; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:90; dataOffset:96; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:120; dataOffset:126; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:150; dataOffset:156; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:180; dataOffset:186; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:210; dataOffset:216; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_EXIT_DROP_P1_WORDS : array[0..239] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$FC3F,$FC3F,
  $FFFF,$FFFF,$FFFF,$FFFF,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$FC3F,$FC3F,$FC3F,$FC3F,
  $FFFF,$FFFF,$03C0,$0000,$0000,$03C0,$03C0,$0000,
  $0000,$03C0,$03C0,$0000,$0000,$03C0,$03C0,$0000,
  $0000,$03C0,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$FCFF,$FCFF,$FC3F,$FC3F,$FC3F,$FC3F,
  $0300,$0000,$0000,$0300,$0300,$0000,$0000,$0300,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$FFFF,$FFFF,
  $FFFF,$FFFF,$FC3F,$FC3F,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$FFFF,$FFFF,$FC3F,$FC3F,
  $FC3F,$FC3F,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$03C0,$0000,$0000,$03C0,$03C0,$0000,
  $0000,$03C0,$03C0,$0000,$0000,$03C0,$03C0,$0000,
  $0000,$03C0,$FC3F,$FC3F,$FC3F,$FC3F,$FCFF,$FCFF,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $03C0,$0000,$0000,$03C0,$03C0,$0000,$0000,$03C0,
  $0300,$0000,$0000,$0300,$0300,$0000,$0000,$0300
);
