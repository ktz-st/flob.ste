procedure VerifyScore;
const scores: array[0..11] of cardinal =
    ($00000,$00001,$00009,$00010,$00099,$00100,
     $00999,$01000,$09999,$10000,$99999,$00000);
var expected: PWord;
    test, i: word;
    output: text;
begin
    Assign(output, 'SCORE.TXT');
    Rewrite(output);
    LoadWorld(0);
    GetMem(expected, SCREEN_BYTES);
    // Unchanged artwork/message pixels are deliberately nonzero.
    for i := 0 to 15999 do SCREEN_BKG[i] := word(longword(i)*157) xor $5AA5;
    mySlime := 0;
    DrawHudTo(SCREEN_BKG);
    BlitterCopyData16(SCREEN_BKG, SCREEN_LOG, SCREEN_BYTES);
    BlitterCopyData16(SCREEN_BKG, SCREEN_PHY, SCREEN_BYTES);
    BlitterCopyData16(SCREEN_BKG, expected, SCREEN_BYTES);
    messageCacheDirty := true;
    for test := 0 to High(scores) do begin
        mySlime := scores[test];
        DrawHudTo(expected);
        RefreshScore;
        for i := 0 to 15999 do
            if (SCREEN_BKG[i] <> expected[i]) or
               (SCREEN_LOG[i] <> expected[i]) or
               (SCREEN_PHY[i] <> expected[i]) then begin
                Writeln(output, 'FAIL test=',test,' word=',i);
                FreeMem(expected, SCREEN_BYTES);
                Close(output);
                exit;
            end;
        if not messageCacheDirty then begin
            Writeln(output, 'FAIL score consumed message update');
            FreeMem(expected, SCREEN_BYTES);
            Close(output);
            exit;
        end;
    end;
    FreeMem(expected, SCREEN_BYTES);
    Writeln(output, 'PASS 12 score changes, all three buffers and message state');
    Close(output);
end;
