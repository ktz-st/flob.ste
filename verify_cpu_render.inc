type TIMSTestSprite = record
    frames: PSteSpriteFrame;
    words: PWord;
    count: word;
end;
{$i generated/ims_test_catalog.inc}

procedure CpuSpriteReference(scr: PWord; x, y: word;
    frame: PSteSpriteFrame; data: PWord);
var row, col, plane, bit, value, offset: word;
    opacity, mask, gfx: PWord;
begin
    if (x + frame^.widthPx > 320) or (y + frame^.heightPx > 200) then exit;
    mask := data + frame^.maskOffset;
    gfx := data + frame^.dataOffset;
    for row := 0 to frame^.heightPx - 1 do
        for col := 0 to frame^.widthPx - 1 do begin
            opacity := mask + row * frame^.rowWords + (col shr 4);
            bit := word($8000 shr (col and 15));
            if (opacity^ and bit) <> 0 then continue;
            value := 0;
            for plane := 0 to 3 do
                if (gfx[row * frame^.rowWords * 4 + (col shr 4) * 4 + plane] and bit) <> 0 then
                    value := value or (1 shl plane);
            offset := (y + row) * 80 + ((x + col) shr 4) * 4;
            bit := word($8000 shr ((x + col) and 15));
            for plane := 0 to 3 do
                if (value and (1 shl plane)) <> 0 then
                    scr[offset + plane] := scr[offset + plane] or bit
                else scr[offset + plane] := scr[offset + plane] and not bit;
        end;
end;

procedure VerifyCpuRender;
var output: text;
    hardware: boolean;
    s, f, shift, x, y, i, row, n, length, col: word;
    frame: PSteSpriteFrame;
    data: PWord;
    comparisons: longword;
    rows: TCpuRows;
    restore: TCpuRestore;
    rects: TDirtyRectArray;
    guards: array[0..32127] of byte;
begin
    Assign(output, 'CPU.TXT');
    Rewrite(output);
    hardware := useBlitter;
    Writeln(output, 'hardware_blitter=', hardware, ' ste_hardware=', hasSteHardware);
    Flush(output);
    useBlitter := false;
    // Byte guards, tails and exact full-screen bounds.
    for length in [0, 1, 2, 3, 4, 7, 8, 15, 16, 17, 31, 32, 33, 63, 64, 65] do begin
        FillChar(guards, SizeOf(guards), $A5);
        ClearDataCPU(@guards[64], length);
        for i := 0 to 96 + length do
            if ((i >= 64) and (i < 64 + length) and (guards[i] <> 0)) or
               (((i < 64) or (i >= 64 + length)) and (guards[i] <> $A5)) then begin
                Writeln(output, 'FAIL clear length=', length, ' byte=', i);
                Close(output); exit;
            end;
        FillChar(guards, SizeOf(guards), $A5);
        FillChar(SCREEN_BKG^, SCREEN_BYTES, $39);
        CopyDataCPU(SCREEN_BKG, @guards[64], length);
        for i := 0 to 96 + length do
            if ((i >= 64) and (i < 64 + length) and (guards[i] <> $39)) or
               (((i < 64) or (i >= 64 + length)) and (guards[i] <> $A5)) then begin
                Writeln(output, 'FAIL copy length=', length, ' byte=', i);
                Close(output); exit;
            end;
    end;
    FillChar(guards, SizeOf(guards), $A5);
    ClearDataCPU(@guards[64], SCREEN_BYTES);
    for i := 0 to High(guards) do
        if ((i >= 64) and (i < 32064) and (guards[i] <> 0)) or
           (((i < 64) or (i >= 32064)) and (guards[i] <> $A5)) then begin
            Writeln(output, 'FAIL full clear byte=', i);
            Close(output); exit;
        end;
    Writeln(output, 'PASS copy/clear tails and full-screen guards'); Flush(output);

    for i := 0 to 15999 do
        SCREEN_BKG[i] := word(longword(i) * 29) xor $A55A;
    // Independent row strides, every aligned width, top/bottom and clear.
    for n := 1 to 20 do begin
        FillChar(SCREEN_LOG^, SCREEN_BYTES, $A5);
        FillChar(SCREEN_PHY^, SCREEN_BYTES, $A5);
        rows.src := SCREEN_BKG + 80;
        rows.dst := SCREEN_LOG + 80;
        rows.rowBytes := n * 8;
        rows.height := 17;
        rows.srcStride := 160;
        rows.dstStride := 160;
        CopyRowsCPU(@rows);
        for row := 1 to 17 do
            Move(SCREEN_BKG[row * 80], SCREEN_PHY[row * 80], rows.rowBytes);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                Writeln(output, 'FAIL rows width=', n, ' word=', i); Close(output); exit;
            end;
        rows.dst := SCREEN_LOG + 14480;
        rows.height := 19;
        ClearRowsCPU(@rows);
        for row := 181 to 199 do
            FillChar(SCREEN_PHY[row * 80], rows.rowBytes, 0);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                Writeln(output, 'FAIL clear rows width=', n, ' word=', i); Close(output); exit;
            end;
    end;
    rows.src := SCREEN_BKG;
    rows.dst := SCREEN_LOG;
    rows.rowBytes := 48;
    rows.height := 40;
    rows.srcStride := 48;
    rows.dstStride := 160;
    FillChar(SCREEN_LOG^, SCREEN_BYTES, 0);
    CopyRowsCPU(@rows);
    for row := 0 to 39 do
        for col := 0 to 23 do
            if SCREEN_LOG[row*80+col] <> SCREEN_BKG[row*24+col] then begin
                Writeln(output, 'FAIL independent stride'); Close(output); exit;
            end;
    Writeln(output, 'PASS rows and independent strides'); Flush(output);

    for n := 1 to 20 do begin
        FillChar(SCREEN_LOG^, SCREEN_BYTES, $A5);
        FillChar(SCREEN_PHY^, SCREEN_BYTES, $A5);
        rects[0].x := 320 - n*16;
        rects[0].y := 183;
        rects[0].widthPx := n*16;
        rects[0].heightPx := 17;
        rects[1].x := 0;
        rects[1].y := 0;
        rects[1].widthPx := 16;
        rects[1].heightPx := 3;
        restore.src := SCREEN_BKG;
        restore.dst := SCREEN_LOG;
        restore.rects := @rects[0];
        restore.count := 2;
        RestoreRectsCPU(@restore);
        for f := 0 to 1 do
            for row := rects[f].y to rects[f].y + rects[f].heightPx - 1 do
                Move(SCREEN_BKG[row*80+rects[f].x div 4],
                     SCREEN_PHY[row*80+rects[f].x div 4], rects[f].widthPx div 2);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                Writeln(output, 'FAIL restore width=', n, ' word=', i); Close(output); exit;
            end;
    end;
    Writeln(output, 'PASS batched restore'); Flush(output);

    comparisons := 0;
    for i := 0 to 15999 do begin
        SCREEN_LOG[i] := SCREEN_BKG[i];
        SCREEN_PHY[i] := SCREEN_BKG[i];
    end;
    for s := 0 to High(IMSTestSprites) do begin
        Writeln(output, 'sprite=', s); Flush(output);
        for f := 0 to IMSTestSprites[s].count - 1 do begin
            frame := IMSTestSprites[s].frames + f;
            data := IMSTestSprites[s].words;
            for shift := 0 to 19 do begin
                x := 16 + shift;
                y := 0;
                if (f and 1) <> 0 then y := 200 - frame^.heightPx;
                if shift >= 16 then begin
                    x := 320 - frame^.widthPx;
                    y := 200 - frame^.heightPx;
                    if (shift and 1) <> 0 then Inc(x);
                    if shift >= 18 then Inc(y);
                end;
                if hardware then begin
                    useBlitter := true;
                    DrawGeneratedSpriteFrameBlitter(SCREEN_PHY, x, y, frame, data);
                    useBlitter := false;
                end else CpuSpriteReference(SCREEN_PHY, x, y, frame, data);
                DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, x, y, frame, data);
                row := y;
                if row > 0 then Dec(row);
                while (row < 200) and (row <= y + frame^.heightPx) do begin
                    for i := row*80 to row*80+79 do
                        if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                            Writeln(output, 'FAIL sprite=', s, ' frame=', f, ' x=', x,
                                ' y=', y, ' word=', i, ' cpu=', SCREEN_LOG[i],
                                ' reference=', SCREEN_PHY[i]);
                            Close(output); exit;
                        end;
                    Inc(row);
                end;
                Inc(comparisons);
            end;
        end;
    end;
    // Flob's separately computed foreground end masks must work on CPU too.
    for f := 0 to High(SPR_FLOB_FRAMES) do
        for shift := 0 to 15 do begin
            Move(SCREEN_BKG^, SCREEN_LOG^, SCREEN_BYTES);
            Move(SCREEN_BKG^, SCREEN_PHY^, SCREEN_BYTES);
            useBlitter := hardware;
            if hardware then DrawOccludedFlob(SCREEN_PHY, 64+shift, 40, @SPR_FLOB_FRAMES[f]);
            useBlitter := false;
            DrawOccludedFlob(SCREEN_LOG, 64+shift, 40, @SPR_FLOB_FRAMES[f]);
            if hardware then
                for i := 0 to 15999 do
                    if SCREEN_LOG[i] <> SCREEN_PHY[i] then begin
                        Writeln(output, 'FAIL occlusion frame=', f, ' shift=', shift,
                            ' word=', i); Close(output); exit;
                    end;
        end;
    useBlitter := hardware;
    Writeln(output, 'PASS sprites comparisons=', comparisons);
    if hardware then Writeln(output, 'PASS 512 foreground mask comparisons')
    else Writeln(output, 'Foreground masks exercised; independent oracle in --gameplay suite');
    Writeln(output, 'DONE');
    Close(output);
end;
