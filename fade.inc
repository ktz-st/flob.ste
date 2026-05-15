const
    FADE_FRAMES = 16;
    ALL_BLACK: array[0..15] of word = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
    FADE_TABLE_FROM_STE: array[0..15] of byte = (
        $0, $2, $4, $6, $8, $a, $c, $e,
        $1, $3, $5, $7, $9, $b, $d, $f
    );
    FADE_TABLE_TO_STE: array[0..15] of byte = (
        $0, $8, $1, $9, $2, $a, $3, $b,
        $4, $c, $5, $d, $6, $e, $7, $f
    );

var
    fadeTmpPal: array[0..15] of word;

function FadeNibble(src, target, step, frames: word): word;
var
    a, b, v: longint;
begin
    a := FADE_TABLE_FROM_STE[src and $f];
    b := FADE_TABLE_FROM_STE[target and $f];
    v := a + (((b - a) * longint(step)) div longint(frames));
    if v < 0 then v := 0;
    if v > 15 then v := 15;
    FadeNibble := FADE_TABLE_TO_STE[byte(v)];
end;

procedure FadePalSTE(src, target, dst: pword; step, frames: word);
var
    i: byte;
    s, t, r, g, b: word;
begin
    for i := 0 to 15 do begin
        s := src[i];
        t := target[i];
        r := FadeNibble((s shr 8) and $f, (t shr 8) and $f, step, frames);
        g := FadeNibble((s shr 4) and $f, (t shr 4) and $f, step, frames);
        b := FadeNibble(s and $f, t and $f, step, frames);
        dst[i] := (r shl 8) or (g shl 4) or b;
    end;
end;

procedure FadeToPalette(target: pword; frames: byte);
var
    srcPal: array[0..15] of word;
    i, step: byte;
begin
    if frames = 0 then begin
        xbios_setpalette(target);
        exit;
    end;
    for i := 0 to 15 do
        srcPal[i] := xbios_setcolor(i, -1);
    for step := 0 to frames do begin
        FadePalSTE(@srcPal[0], target, @fadeTmpPal[0], step, frames);
        xbios_setpalette(@fadeTmpPal[0]);
        VSync;
    end;
    xbios_setpalette(target);
end;

procedure FadeToBlack(frames: byte);
begin
    FadeToPalette(@ALL_BLACK[0], frames);
end;
