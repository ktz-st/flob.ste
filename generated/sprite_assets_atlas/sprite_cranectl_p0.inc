const SPR_SPRITE_CRANECTL_P0_FRAME_COUNT = 4;
const SPR_SPRITE_CRANECTL_P0_FRAMES : array[0..3] of TSteSpriteFrame = (
    (widthPx:16; heightPx:8; rowWords:1; maskOffset:0; dataOffset:8; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:8; rowWords:1; maskOffset:40; dataOffset:48; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:8; rowWords:1; maskOffset:80; dataOffset:88; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:8; rowWords:1; maskOffset:120; dataOffset:128; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_CRANECTL_P0_WORDS : array[0..159] of word=(
  $FFFF,$FFFF,$F3FF,$F3FF,$F3FF,$F3FF,$F3FF,$F3FF,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $FFFF,$FFFF,$F3FF,$F3FF,$F3FF,$F3FF,$F3FF,$F3FF,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $F3FF,$F3FF,$F3FF,$F3FF,$F3FF,$F3FF,$FFFF,$FFFF,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $F3FF,$F3FF,$F3FF,$F3FF,$F3FF,$F3FF,$FFFF,$FFFF,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0C00,$0C00,$0C00,$0000,$0C00,$0C00,$0C00,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
);
