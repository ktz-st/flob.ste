const SPR_MONN_FRAME_COUNT = 1;
const SPR_MONN_FRAMES : array[0..0] of TSteSpriteFrame = (
    (widthPx:16; heightPx:16; rowWords:1; maskOffset:0; dataOffset:16; paletteOffset:0; paletteCount:1)
);

const SPR_MONN_WORDS : array[0..79] of word=(
  $F3FF,$F3FF,$CFFF,$CFFF,$0FFF,$0FFF,$0FFF,$0FFF,
  $03FF,$03FF,$00FC,$00FC,$C003,$C003,$F00F,$F00F,
  $0C00,$0000,$0000,$0000,$0C00,$0000,$0000,$0000,
  $3000,$0000,$0000,$0000,$3000,$0000,$0000,$0000,
  $F000,$0000,$0000,$0000,$F000,$0000,$0000,$0000,
  $F000,$0000,$0000,$0000,$F000,$0000,$0000,$0000,
  $FC00,$0000,$0000,$0000,$FC00,$0000,$0000,$0000,
  $FF03,$0000,$0000,$0000,$FF03,$0000,$0000,$0000,
  $3FFC,$0000,$0000,$0000,$3FFC,$0000,$0000,$0000,
  $0FF0,$0000,$0000,$0000,$0FF0,$0000,$0000,$0000
);

const SPR_MONN_PALS : array[0..0] of word=(
  $0631
);
