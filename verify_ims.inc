type TIMSTestSprite = record
    frames: PSteSpriteFrame;
    words: PWord;
    count: word;
end;
{$i generated/ims_test_catalog.inc}

procedure VerifyIMS;
var s, f, shift, x, y, row, i, phase, pass: word;
    frame: PSteSpriteFrame;
    tests, startTick, draws: longword;
    ticks: array[0..1] of longword;
    output: text;
begin
    Assign(output, 'IMS.TXT');
    Rewrite(output);
    tests := 0;
    imsDrawCounter := 0;
    for i := 0 to 15999 do begin
        SCREEN_LOG[i] := word(longword(i)*29) xor $A55A;
        SCREEN_PHY[i] := SCREEN_LOG[i];
    end;
    for s := 0 to High(IMSTestSprites) do begin
        Writeln(output, 'Testing sprite ', s);
        Flush(output);
        for f := 0 to IMSTestSprites[s].count - 1 do begin
            frame := IMSTestSprites[s].frames + f;
            for shift := 0 to 19 do begin
                x := 16 + shift;
                y := 0;
                if (f and 1) <> 0 then y := 200 - frame^.heightPx;
                if shift >= 16 then begin
                    x := 320 - frame^.widthPx;
                    if (shift and 1) <> 0 then Inc(x);
                    y := 200 - frame^.heightPx;
                    if shift >= 18 then Inc(y);
                end;
                imsReference := true;
                DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, x, y, frame, IMSTestSprites[s].words);
                imsReference := false;
                DrawGeneratedSpriteFrameBlitter(SCREEN_PHY, x, y, frame, IMSTestSprites[s].words);
                // Compare all columns of touched rows and a vertical guard.
                row := y;
                if row > 0 then Dec(row);
                while (row < 200) and (row <= y + frame^.heightPx) do begin
                    for i := row*80 to row*80+79 do
                        if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                            Writeln(output, 'FAIL sprite=',s,' frame=',f,' x=',x,' y=',y,
                                ' word=',i,' ref=',SCREEN_LOG[i],' asm=',SCREEN_PHY[i]);
                            Close(output);
                            exit;
                        end;
                    Inc(row);
                end;
                Inc(tests);
            end;
        end;
    end;
    Writeln(output, 'PASS comparisons=',tests,' actual_ims_calls=',imsDrawCounter);
    Flush(output);
    // Same all-frame/all-shift workload, no VSync or screen restore in timing.
    for phase := 0 to 1 do begin
        imsReference := phase = 0;
        draws := 0;
        startTick := PLongWord(pointer(longword($4BA)))^;
        for pass := 0 to 1 do
            for s := 0 to High(IMSTestSprites) do
                for f := 0 to IMSTestSprites[s].count - 1 do begin
                    frame := IMSTestSprites[s].frames + f;
                    for shift := 0 to 15 do begin
                        DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, 64+shift, 40, frame, IMSTestSprites[s].words);
                        Inc(draws);
                    end;
                end;
        ticks[phase] := PLongWord(pointer(longword($4BA)))^ - startTick;
    end;
    Writeln(output, 'BENCH draws=',draws,' pascal_ticks=',ticks[0],' asm_ticks=',ticks[1]);
    Close(output);
end;
