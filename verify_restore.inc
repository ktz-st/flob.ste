procedure VerifyRestore;
var rects: TDirtyRectArray;
    test, i, r, phase, pass: word;
    count: byte;
    ticks: array[0..1] of longword;
    startTick: longword;
    output: text;
begin
    Assign(output, 'RESTORE.TXT');
    Rewrite(output);
    if SizeOf(TDirtyRect) <> 8 then begin
        Writeln(output, 'FAIL record ABI');
        Close(output);
        exit;
    end;
    for i := 0 to 15999 do
        SCREEN_BKG[i] := word(longword(i)*157) xor $5AA5;
    for test := 0 to 399 do begin
        count := test mod (MAX_DIRTY_RECTS+1);
        for i := 0 to 15999 do begin
            SCREEN_LOG[i] := word(longword(i)*29+test) xor $A55A;
            SCREEN_PHY[i] := SCREEN_LOG[i];
        end;
        if count > 0 then
            for r := 0 to count-1 do begin
                rects[r].x := ((test+r*7) mod 20)*16;
                rects[r].y := (test*13+r*23) mod 200;
                rects[r].widthPx := (1+((test+r*3) mod ((320-rects[r].x) div 16)))*16;
                rects[r].heightPx := 1+((test*7+r*11) mod (200-rects[r].y));
            end;
        RestoreDirtyRects(rects, count, false);
        RestoreRectsASM(SCREEN_BKG, SCREEN_PHY, @rects[0], count);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                Writeln(output, 'FAIL test=',test,' word=',i);
                Close(output);
                exit;
            end;
    end;
    Writeln(output, 'PASS comparisons=400');
    Flush(output);
    // Small sprite-sized dirty regions, no VSync in the timing loop.
    for r := 0 to 15 do begin
        rects[r].x := (r mod 10)*32;
        rects[r].y := (r div 10)*80+20;
        rects[r].widthPx := 16+(r mod 2)*16;
        rects[r].heightPx := 6+(r mod 3)*5;
    end;
    for phase := 0 to 1 do begin
        startTick := PLongWord(pointer(longword($4BA)))^;
        for pass := 0 to 1999 do
            if phase = 0 then RestoreDirtyRects(rects, 16, false)
            else RestoreRectsASM(SCREEN_BKG, SCREEN_LOG, @rects[0], 16);
        ticks[phase] := PLongWord(pointer(longword($4BA)))^ - startTick;
    end;
    Writeln(output, 'BENCH rects=32000 pascal_ticks=',ticks[0],' asm_ticks=',ticks[1]);
    Close(output);
end;
