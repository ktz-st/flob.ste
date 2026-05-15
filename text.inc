// Legacy Line-A text helpers are kept here, but the main string rendering
// path now uses the custom 8x8 font renderer through DrawTextTo().

var
    pParamblk: pointer = nil;
    pFnthdr:   pointer = nil;
    pFktadr:   pointer = nil;

const CHAR_W = 8;   // pixel advance per glyph (ST system font ~8px wide)


// ---------------------------------------------------------------------------
// DrawStr – draw string left-to-right starting at (x,y).
// ---------------------------------------------------------------------------
procedure DrawStr(x, y, fg: word; const str: string);
begin
    DrawTextTo(SCREEN_LOG, x, y, fg, 0, str);
end;

// ---------------------------------------------------------------------------
// DrawStrCentered – center string horizontally on a 320-pixel wide screen.
// ---------------------------------------------------------------------------
procedure DrawStrCentered(y, fg: word; const str: string);
var x: word;
begin
    x := (320 - word(Length(str)) * CHAR_W) div 2;
    DrawTextTo(SCREEN_LOG, x, y, fg, 0, str);
end;

// ---------------------------------------------------------------------------
// FillRect16 – fill aligned rectangle in ST Low bitplane format.
//   x     : must be a multiple of 16
//   cellw : must be a multiple of 16
//   Rows y .. y+cellh-1 are filled.
// ---------------------------------------------------------------------------
procedure FillRect16(scr: pword; x, y, cellw, cellh, color: word);
var row, grp: word;
    pw:       pword;
    b:        array[0..3] of word;
    ngroups:  word;
begin
    b[0] := 0; if color and 1 <> 0 then b[0] := $FFFF;
    b[1] := 0; if color and 2 <> 0 then b[1] := $FFFF;
    b[2] := 0; if color and 4 <> 0 then b[2] := $FFFF;
    b[3] := 0; if color and 8 <> 0 then b[3] := $FFFF;
    ngroups := cellw shr 4;
    for row := y to y + cellh - 1 do begin
        pw := pword(longword(scr) + longword(row) * 160 + (x shr 4) * 8);
        for grp := 1 to ngroups do begin
            pw^ := b[0]; Inc(pw);
            pw^ := b[1]; Inc(pw);
            pw^ := b[2]; Inc(pw);
            pw^ := b[3]; Inc(pw);
        end;
    end;
end;
