// Legacy Line-A text helpers are kept here, but the main string rendering
// path now uses the custom 8x8 font renderer through DrawTextTo().

var
    pParamblk: pointer = nil;
    pFnthdr:   pointer = nil;
    pFktadr:   pointer = nil;

const CHAR_W = 8;   // pixel advance per glyph (ST system font ~8px wide)
      CHAR_H = 16;  // system font height in pixels

// ---------------------------------------------------------------------------
// LineA_Init – call once before any text drawing.
// ---------------------------------------------------------------------------
procedure LineA_Init;
begin
    asm
        movem.l D0-D2/A0-A2,-(A7)
        dc.w    $A000
        move.l  A0, pParamblk
        move.l  A1, pFnthdr
        move.l  A2, pFktadr
        movem.l (A7)+,D0-D2/A0-A2
    end;
end;

// ---------------------------------------------------------------------------
// TextBlt – render one character at pixel (x,y).
//   fg/bg  : palette index 0-15
//   mode 0 : replace (bg pixels written in bg_color)
//   mode 1 : transparent (bg pixels left unchanged)
// ---------------------------------------------------------------------------
procedure TextBlt(x, y, fg_color, bg_color, mode: word; ch: char);
begin
    asm
        movem.l D0-D2/A0-A2,-(A7)
        move.l  pParamblk, A0
        move.l  pFnthdr,   A1
        move.l  4(A1),     A1        // second font in chain
        move.l  76(A1),    84(A0)    // font data pointer
        move.w  80(A1),    88(A0)    // max char width
        move.w  82(A1),    82(A0)    // char height
        move.w  mode,      36(A0)    // write mode
        move.w  #0,        54(A0)
        move.w  #0,        56(A0)
        move.w  #0,        58(A0)
        move.w  #126,      60(A0)    // clip right
        move.w  #200,      62(A0)    // clip bottom
        move.w  #$8000,    64(A0)
        move.w  #1,        70(A0)
        move.l  72(A1),    A3        // char offset table
        clr.l   D0
        move.b  ch,        D0
        sub.w   36(A1),    D0        // subtract first char index
        lsl.w   #1,        D0
        move.w  0(A3,D0),  72(A0)    // char x offset
        move.w  2(A3,D0),  D0
        sub.w   72(A0),    D0
        move.w  D0,        80(A0)    // char width
        move.w  #0,        74(A0)
        move.w  x,         76(A0)    // DESTX
        move.w  y,         78(A0)    // DESTY
        move.w  #0,        90(A0)
        move.w  #0,        102(A0)
        move.w  #0,        104(A0)
        move.w  fg_color,  106(A0)   // foreground color
        move.w  bg_color,  114(A0)   // background color
        dc.w    $A008                // TextBlt opcode
        movem.l (A7)+,D0-D2/A0-A2
    end;
end;

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
        pw := pword(longint(scr) + longint(row) * 160 + (x shr 4) * 8);
        for grp := 1 to ngroups do begin
            pw^ := b[0]; Inc(pw);
            pw^ := b[1]; Inc(pw);
            pw^ := b[2]; Inc(pw);
            pw^ := b[3]; Inc(pw);
        end;
    end;
end;

// ---------------------------------------------------------------------------
// putCenteredS – legacy stub: draw global string s centered at pixel row y.
//   c  = foreground palette index
//   cs = ignored (was charset on 8-bit)
// ---------------------------------------------------------------------------
procedure putCenteredS(y, c, cs: byte);
begin
    DrawStrCentered(y, c, s);
end;
