// Runs real blitter hardware emulation, comparing destination AND untouched pixels.
procedure VerifyEMS;
var kind, f, shift, edge, vertical, count, x, y, firstRow, lastRow, i: word;
    frame: PSteSpriteFrame;
    wordsBase: PWord;
    pattern: word;
    output: text;
{$if defined(SLIME_EMX) or defined(SLIME_CPU)}
    mode, repeatDraw, dstCount, skewValue: word;
    gfx, dst, masks: PWord;
    started, elapsed, dispatch: longword;
{$endif}
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
{$if defined(SLIME_EMX) or defined(SLIME_CPU)}
    PByte(pointer(longword($FFFF820A)))^ := 2;
    VSync;
    for mode := 0 to 1 do begin
        elapsed := 0;
        for f := 0 to High(SPR_SLIME_FRAMES) do begin
            frame := @SPR_SLIME_FRAMES[f];
            gfx := @SPR_SLIME_WORDS[frame^.dataOffset];
            dst := SCREEN_LOG;
            for shift := 0 to 15 do begin
                dstCount := (shift + frame^.widthPx + 15) shr 4;
                skewValue := shift;
                if dstCount > 1 then skewValue := skewValue or BLITTER_SKEW_NFSR;
                masks := @SPR_SLIME_EMS_MASKS[frame^.paletteOffset + shift * frame^.heightPx * 2];
                dispatch := frame^.paletteOffset + shift * 4;
                started := PLongWord(pointer(longword($4BA)))^;
                if mode = 0 then
                    for repeatDraw := 1 to 256 do
                        DrawSpriteEMS(gfx, dst, masks, frame^.heightPx, dstCount, skewValue)
                else
                    for repeatDraw := 1 to 256 do
{$ifdef SLIME_CPU}
                        DrawSlimeCPU(dst, dispatch);
{$else}
                        DrawSlimeEMX(gfx, dst, dispatch);
{$endif}
                Inc(elapsed, PLongWord(pointer(longword($4BA)))^ - started);
            end;
        end;
        Writeln(output, 'MICRO mode=', mode, ' (0=EMS 1=experimental), 16384 calls, HZ200 ticks=', elapsed);
        Flush(output);
    end;
{$endif}
    Writeln(output, 'PASS ', count, ' framebuffer comparisons, all frames/orientations/shifts, top/bottom/right-edge guards');
    Writeln(output, 'EMS calls: ', emsDrawCounter);
    Close(output);
end;
