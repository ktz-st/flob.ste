const SPR_SPRITE_CRANECONSOLE_P1_FRAME_COUNT = 6;
const SPR_SPRITE_CRANECONSOLE_P1_FRAMES : array[0..5] of TSteSpriteFrame = (
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:0; dataOffset:4; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:20; dataOffset:24; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:40; dataOffset:44; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:60; dataOffset:64; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:80; dataOffset:84; paletteOffset:0; paletteCount:0),
    (widthPx:16; heightPx:4; rowWords:1; maskOffset:100; dataOffset:104; paletteOffset:0; paletteCount:0)
);

const SPR_SPRITE_CRANECONSOLE_P1_WORDS : array[0..119] of word=(
  $FFFF,$FFFF,$FFFF,$FFFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$3CFF,$3CFF,$FFFF,$FFFF,
  $0000,$C300,$C300,$C300,$0000,$C300,$C300,$C300,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $3CFF,$3CFF,$3CFF,$3CFF,$0000,$C300,$C300,$C300,
  $0000,$C300,$C300,$C300,$0000,$C300,$C300,$C300,
  $0000,$C300,$C300,$C300,$FFFF,$FFFF,$FFFF,$FFFF,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $FFFF,$FFFF,$3CFF,$3CFF,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$C300,$C300,$C300,
  $0000,$C300,$C300,$C300,$3CFF,$3CFF,$3CFF,$3CFF,
  $0000,$C300,$C300,$C300,$0000,$C300,$C300,$C300,
  $0000,$C300,$C300,$C300,$0000,$C300,$C300,$C300
);
