procedure VerifyRestore;
var rects: TDirtyRectArray;
    test, i, r, phase, pass: word;
    count: byte;
    ticks: array[0..4] of longword;
    startTick: longword;
    output: text;
    cache: TRestoreCache;
begin
    Assign(output, 'RESTORE.TXT');
    Rewrite(output);
    if (SizeOf(TDirtyRect) <> 8) or (SizeOf(TPreparedRestoreRect) <> 22) or
        (SizeOf(TRestoreCache) <> 8 + MAX_DIRTY_RECTS * 22) then begin
        Writeln(output, 'FAIL record ABI');
        Close(output);
        exit;
    end;
    FillChar(cache, SizeOf(cache), 0);
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
        for i := 0 to 15999 do
            SCREEN_PHY[i] := word(longword(i)*29+test) xor $A55A;
        PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_PHY, @rects[0], count, @cache);
        RestorePreparedASM(@cache.entries[0], count);
        // A second identical batch exercises cache hits as well as changed entries.
        PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_PHY, @rects[0], count, @cache);
        RestorePreparedASM(@cache.entries[0], count);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                Writeln(output, 'FAIL prepared test=',test,' word=',i);
                Close(output);
                exit;
            end;
    end;
    Writeln(output, 'PASS comparisons=400');
    rects[0].x := 0; rects[0].y := 0;
    rects[0].widthPx := 320; rects[0].heightPx := 200;
    PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_PHY, @rects[0], 1, @cache);
    RestorePreparedASM(@cache.entries[0], 1);
    FillChar(SCREEN_LOG^, SCREEN_BYTES, 0);
    PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_LOG, @rects[0], 1, @cache);
    RestorePreparedASM(@cache.entries[0], 1);
    for i := 0 to 15999 do
        if SCREEN_LOG[i] <> SCREEN_BKG[i] then begin
            Writeln(output, 'FAIL destination base invalidation'); Close(output); exit;
        end;
    for i := 0 to 15999 do SCREEN_PHY[i] := not SCREEN_BKG[i];
    PrepareRestoreRectsASM(SCREEN_PHY, SCREEN_LOG, @rects[0], 1, @cache);
    RestorePreparedASM(@cache.entries[0], 1);
    for i := 0 to 15999 do
        if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
            Writeln(output, 'FAIL source base invalidation'); Close(output); exit;
        end;
    Writeln(output, 'PASS prepared records, cache hits, changed rectangles and buffer bases');
    Flush(output);
    // Small sprite-sized dirty regions, no VSync in the timing loop.
    for r := 0 to 15 do begin
        rects[r].x := (r mod 10)*32;
        rects[r].y := (r div 10)*80+20;
        rects[r].widthPx := 16+(r mod 2)*16;
        rects[r].heightPx := 6+(r mod 3)*5;
    end;
    PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_LOG, @rects[0], 16, @cache);
    for phase := 0 to 4 do begin
        startTick := PLongWord(pointer(longword($4BA)))^;
        for pass := 0 to 1999 do begin
            case phase of
                0: RestoreDirtyRects(rects, 16, false);
                1: RestoreRectsASM(SCREEN_BKG, SCREEN_LOG, @rects[0], 16);
                2: RestorePreparedASM(@cache.entries[0], 16);
                3: begin
                    PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_LOG, @rects[0], 16, @cache);
                    RestorePreparedASM(@cache.entries[0], 16);
                end;
                4: begin
                    // Force every entry to miss without changing the blit workload.
                    cache.srcBase := nil;
                    PrepareRestoreRectsASM(SCREEN_BKG, SCREEN_LOG, @rects[0], 16, @cache);
                    RestorePreparedASM(@cache.entries[0], 16);
                end;
            end;
        end;
        ticks[phase] := PLongWord(pointer(longword($4BA)))^ - startTick;
    end;
    Writeln(output, 'BENCH rects=32000 pascal_ticks=',ticks[0],' asm_ticks=',ticks[1],
        ' prepared_only_ticks=',ticks[2], ' cached_total_ticks=',ticks[3],
        ' cold_total_ticks=',ticks[4]);
    Close(output);
end;
