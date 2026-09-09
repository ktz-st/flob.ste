const SPR_SPRITE_LAMP_FUSE_P0_FRAME_COUNT = 6;
const SPR_SPRITE_LAMP_FUSE_P0_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_LAMP_FUSE_P0_WORDS : array[0..119] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0FFF,$0FFF,$0FFF,$0FFF,
  $F000,$F000,$F000,$0000,$F000,$F000,$F000,$0000,
  $F000,$F000,$F000,$0000,$F000,$F000,$F000,$0000,
  $0FFF,$0FFF,$0FFF,$0FFF,$F000,$0000,$0000,$F000,
  $F000,$0000,$0000,$F000,$F000,$0000,$0000,$F000,
  $F000,$0000,$0000,$F000,$FFFF,$FFFF,$FFFF,$FFFF,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0FFF,$0FFF,$0FFF,$0FFF,$F000,$F000,$F000,$0000,
  $F000,$F000,$F000,$0000,$F000,$F000,$F000,$0000,
  $F000,$F000,$F000,$0000,$0FFF,$0FFF,$0FFF,$0FFF,
  $F000,$0000,$0000,$F000,$F000,$0000,$0000,$F000,
  $F000,$0000,$0000,$F000,$F000,$0000,$0000,$F000
);
