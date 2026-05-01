const SPR_MAP_FRAME_COUNT = 1;
const SPR_MAP_FRAMES : array[0..0] of TSteSpriteFrame = (
    (widthPx:16; heightPx:16; rowWords:1; maskOffset:0; dataOffset:16; paletteOffset:0; paletteCount:3)
);

const SPR_MAP_WORDS : array[0..79] of word=(
  $C00F,$C00F,$0003,$0003,$0000,$0000,$0000,$0000,
  $00CC,$00CC,$0030,$0030,$00CC,$00CC,$C000,$C000,
  $3FF0,$0000,$0000,$0000,$3FF0,$0000,$0000,$0000,
  $C03C,$3FC0,$0000,$0000,$C03C,$3FC0,$0000,$0000,
  $CC3F,$3FC0,$0000,$0000,$CC3F,$3FC0,$0000,$0000,
  $CFC3,$3FFC,$0000,$0000,$CFC3,$3FFC,$0000,$0000,
  $CF33,$3F30,$0000,$0000,$CF33,$3F30,$0000,$0000,
  $CFCF,$3FCC,$0000,$0000,$CFCF,$3FCC,$0000,$0000,
  $C303,$3F30,$0000,$0000,$C303,$3F30,$0000,$0000,
  $3F03,$00FC,$0000,$0000,$3F03,$00FC,$0000,$0000
);

const SPR_MAP_PALS : array[0..2] of word=(
  $0310,$0314,$0423
);
