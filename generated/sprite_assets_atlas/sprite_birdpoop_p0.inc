const SPR_SPRITE_BIRDPOOP_P0_FRAME_COUNT = 8;
const SPR_SPRITE_BIRDPOOP_P0_FRAMES : array[0..7] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:120; dataOffset:124; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:140; dataOffset:144; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_BIRDPOOP_P0_WORDS : array[0..159] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$F3FF,$F3FF,$FFFF,$FFFF,
  $0000,$0C00,$0000,$0C00,$0000,$0C00,$0000,$0C00,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $F3FF,$F3FF,$F3FF,$F3FF,$0000,$0C00,$0000,$0C00,
  $0000,$0C00,$0000,$0C00,$0000,$0C00,$0000,$0C00,
  $0000,$0C00,$0000,$0C00,$FFFF,$FFFF,$C0FF,$C0FF,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$3F00,$0000,$3F00,$0000,$3F00,$0000,$3F00,
  $FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$FFFF,$FFFF,$F3FF,$F3FF,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0C00,$0000,$0C00,$0000,$0C00,$0000,$0C00,
  $F3FF,$F3FF,$F3FF,$F3FF,$0000,$0C00,$0000,$0C00,
  $0000,$0C00,$0000,$0C00,$0000,$0C00,$0000,$0C00,
  $0000,$0C00,$0000,$0C00,$C0FF,$C0FF,$FFFF,$FFFF,
  $0000,$3F00,$0000,$3F00,$0000,$3F00,$0000,$3F00,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
);
