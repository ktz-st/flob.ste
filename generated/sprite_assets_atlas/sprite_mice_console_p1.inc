const SPR_SPRITE_MICE_CONSOLE_P1_FRAME_COUNT = 6;
const SPR_SPRITE_MICE_CONSOLE_P1_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:60; dataOffset:66; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:90; dataOffset:96; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:120; dataOffset:126; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:150; dataOffset:156; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_MICE_CONSOLE_P1_WORDS : array[0..179] of word=(
  $C30F,$C30F,$F0C3,$F0C3,$030F,$030F,$0000,$0000,
  $0000,$3CF0,$0000,$0000,$0000,$3CF0,$0000,$0000,
  $0000,$0F3C,$0000,$0000,$0000,$0F3C,$0000,$0000,
  $0000,$FCF0,$0000,$0000,$0000,$FCF0,$F03F,$F03F,
  $FC0F,$FC0F,$303F,$303F,$0000,$0000,$0000,$0FC0,
  $0000,$0000,$0000,$0FC0,$0000,$0000,$0000,$03F0,
  $0000,$0000,$0000,$03F0,$0000,$0000,$0000,$CFC0,
  $0000,$0000,$0000,$CFC0,$0FC3,$0FC3,$C3F0,$C3F0,
  $0FC3,$0FC3,$0000,$0000,$0000,$F03C,$0000,$0000,
  $0000,$F03C,$0000,$0000,$0000,$3C0F,$0000,$0000,
  $0000,$3C0F,$0000,$0000,$0000,$F03C,$0000,$0000,
  $0000,$F03C,$030F,$030F,$F0C3,$F0C3,$C30F,$C30F,
  $0000,$0000,$0000,$FCF0,$0000,$0000,$0000,$FCF0,
  $0000,$0000,$0000,$0F3C,$0000,$0000,$0000,$0F3C,
  $0000,$0000,$0000,$3CF0,$0000,$0000,$0000,$3CF0,
  $303F,$303F,$FC0F,$FC0F,$F03F,$F03F,$0000,$0000,
  $0000,$CFC0,$0000,$0000,$0000,$CFC0,$0000,$0000,
  $0000,$03F0,$0000,$0000,$0000,$03F0,$0000,$0000,
  $0000,$0FC0,$0000,$0000,$0000,$0FC0,$0FC3,$0FC3,
  $C3F0,$C3F0,$0FC3,$0FC3,$0000,$0000,$0000,$F03C,
  $0000,$0000,$0000,$F03C,$0000,$0000,$0000,$3C0F,
  $0000,$0000,$0000,$3C0F,$0000,$0000,$0000,$F03C,
  $0000,$0000,$0000,$F03C
);
