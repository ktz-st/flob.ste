// Runs real blitter hardware emulation, comparing destination AND untouched pixels.
procedure VerifyEMS;
var kind, f, shift, edge, vertical, count, x, y, firstRow, lastRow, i: word;
    frame: PSteSpriteFrame;
    wordsBase: PWord;
    pattern: word;
    output: text;
begin
    Assign(output, 'EMS.TXT');
    Rewrite(output);
    count := 0;
    emsDrawCounter := 0;
    for kind := 0 to 1 do begin
        if kind = 0 then f := High(SPR_FLOB_FRAMES)
        else f := High(SPR_SLIME_FRAMES);
        repeat
            Writeln(output, 'Testing kind=', kind, ' frame=', f);
            Flush(output);
            if kind = 0 then begin
                frame := @SPR_FLOB_FRAMES[f];
                wordsBase := @SPR_FLOB_WORDS[0];
            end else begin
                frame := @SPR_SLIME_FRAMES[f];
                wordsBase := @SPR_SLIME_WORDS[0];
            end;
            for shift := 0 to 15 do
                for edge := 0 to 1 do
                    for vertical := 0 to 1 do begin
                        x := shift;
                        if edge = 1 then x := 304 + shift;
                        y := 0;
                        if vertical = 1 then y := 200 - frame^.heightPx;
                        firstRow := y;
                        if firstRow > 0 then Dec(firstRow);
                        lastRow := y + frame^.heightPx;
                        if lastRow > 199 then lastRow := 199;
                        for i := firstRow * 80 to (lastRow + 1) * 80 - 1 do begin
                            pattern := word(longword(i) * 29 + count) xor $A55A;
                            SCREEN_LOG[i] := pattern;
                            SCREEN_PHY[i] := pattern;
                        end;
                        emsReference := true;
                        DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, x, y, frame, wordsBase);
                        emsReference := false;
                        DrawGeneratedSpriteFrameBlitter(SCREEN_PHY, x, y, frame, wordsBase);
                        for i := firstRow * 80 to (lastRow + 1) * 80 - 1 do
                            if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                                Writeln(output, 'FAIL kind=',kind,' frame=',f,' x=',x,' y=',y,
                                    ' word=',i,' reference=',SCREEN_LOG[i],' ems=',SCREEN_PHY[i]);
                                Close(output);
                                exit;
                            end;
                        Inc(count);
                    end;
            if f = 0 then break;
            Dec(f);
        until false;
    end;
    Writeln(output, 'PASS ', count, ' framebuffer comparisons, all frames/orientations/shifts, top/bottom/right-edge guards');
    Writeln(output, 'EMS calls: ', emsDrawCounter);
    Close(output);
end;
