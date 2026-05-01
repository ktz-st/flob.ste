// Sprite data – replaced absolute 8-bit addresses with regular arrays.
// Will be populated from converted asset files.
var
    flobFrames0: array [0..15] of word;
    flobFrames1: array [0..15] of word;
    larrow:     array [0..29] of byte;
    rarrow:     array [0..29] of byte;
    ach_cursor: array [0..4, 0..11] of byte;
    ach_off:    array [0..31] of byte;
    ach_on:     array [0..31] of byte;
    ach_new:    array [0..31] of byte;
