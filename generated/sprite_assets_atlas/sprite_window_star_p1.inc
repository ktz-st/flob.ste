const SPR_SPRITE_WINDOW_STAR_P1_FRAME_COUNT = 8;
const SPR_SPRITE_WINDOW_STAR_P1_FRAMES : array[0..7] of TSteSpriteFrame = (
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:0; dataOffset:6; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:30; dataOffset:36; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:60; dataOffset:66; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:90; dataOffset:96; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:120; dataOffset:126; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:150; dataOffset:156; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:180; dataOffset:186; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:6; rowWords:1; maskOffset:210; dataOffset:216; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_WINDOW_STAR_P1_WORDS : array[0..239] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$FFFC,$FFFC,
  $FFFF,$FFFF,$FFFF,$FFFF,$0003,$0003,$0000,$0003,
  $0003,$0003,$0000,$0003,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$FFFC,$FFFC,$FFF3,$FFF3,
  $FFFF,$FFFF,$0003,$0003,$0000,$0003,$0003,$0003,
  $0000,$0003,$000C,$000C,$0000,$000C,$000C,$000C,
  $0000,$000C,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$FFFC,$FFFC,$FFF3,$FFF3,$FFCF,$FFCF,
  $0003,$0003,$0000,$0003,$0003,$0003,$0000,$0003,
  $000C,$000C,$0000,$000C,$000C,$000C,$0000,$000C,
  $0030,$0030,$0000,$0030,$0030,$0030,$0000,$0030,
  $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$FFFF,$FFFF,
  $FFFF,$FFFF,$FFFC,$FFFC,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0003,$0003,$0000,$0003,
  $0003,$0003,$0000,$0003,$FFFF,$FFFF,$FFF3,$FFF3,
  $FFFC,$FFFC,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$000C,$000C,$0000,$000C,$000C,$000C,
  $0000,$000C,$0003,$0003,$0000,$0003,$0003,$0003,
  $0000,$0003,$FFCF,$FFCF,$FFF3,$FFF3,$FFFC,$FFFC,
  $0030,$0030,$0000,$0030,$0030,$0030,$0000,$0030,
  $000C,$000C,$0000,$000C,$000C,$000C,$0000,$000C,
  $0003,$0003,$0000,$0003,$0003,$0003,$0000,$0003
);
