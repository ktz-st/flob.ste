procedure VerifyGameplay;
var output: text;
    a, b: TSteSpriteFrame;
    ma, mb: array[0..23] of word;
    expected: PWord;
    test, i, j, x, y, n, total: word;
    bx, by: smallint;
    ref, actual, visible: boolean;
    solid: array[0..3199] of byte;
    tile: TSteTile;
    savedCollision: PByte;
    spr: PQueuedSprite;

    procedure Fail(const labelText: string; testNo: word);
    begin
        Writeln(output, 'FAIL ', labelText, ' test=', testNo);
        Close(output);
        Halt(1);
    end;

    function ReferenceOverlap: boolean;
    var px, py: smallint;
    begin
        Result := false;
        for py := 0 to a.heightPx-1 do
            for px := 0 to a.widthPx-1 do
                if GeneratedSpriteOpaqueAt(@a, @ma[0], px, py) and
                   GeneratedSpriteOpaqueAt(@b, @mb[0], px-bx, py-by) then exit(true);
    end;

    function ReferenceDanger(frame: PSteSpriteFrame): boolean;
    var px, py, sy, cx, cy: smallint;
    begin
        Result := false;
        for py := 0 to frame^.heightPx-1 do begin
            sy := FLOB_RENDER_OFFSET_Y + smallint(flobY)*2 + py;
            if (sy < BG_IMAGE_OFFSET_Y) or (sy >= BG_IMAGE_OFFSET_Y+160) then continue;
            cy := (sy-BG_IMAGE_OFFSET_Y) div 2;
            for px := 0 to frame^.widthPx-1 do begin
                cx := smallint(flobX) + px div 2;
                if (cx < 160) and IsDynamicDangerPix(cx,cy) and
                    GeneratedSpriteOpaqueAt(frame,@SPR_FLOB_WORDS[0],px,py) then exit(true);
            end;
        end;
    end;

begin
    Assign(output, 'GAMEPLAY.TXT');
    Rewrite(output);
    RandSeed := 12345;
    FillChar(a,SizeOf(a),0);
    FillChar(b,SizeOf(b),0);
    for test := 0 to 3999 do begin
        a.widthPx := 1+Random(48); b.widthPx := 1+Random(48);
        a.rowWords := (a.widthPx+15) shr 4; b.rowWords := (b.widthPx+15) shr 4;
        a.heightPx := 1+Random(8); b.heightPx := 1+Random(8);
        bx := Random(97)-48; by := Random(19)-9;
        for i := 0 to 23 do begin
            ma[i] := not (word(1) shl Random(16));
            mb[i] := not (word(1) shl Random(16));
            if (test and 3)=0 then begin ma[i] := Random(65536); mb[i] := Random(65536); end;
        end;
        ref := ReferenceOverlap;
        actual := GeneratedSpritesOverlap(@a,@ma[0],0,0,@b,@mb[0],bx,by);
        if ref <> actual then Fail('mask overlap',test);
    end;
    Writeln(output,'PASS 4000 mask comparisons, widths 1..48'); Flush(output);

    for test := 0 to 1999 do begin
        if (test mod 100)=0 then
            for i := 0 to High(dynamicTileDanger) do
                if (test mod 200)=0 then dynamicTileDanger[i] := 0
                else dynamicTileDanger[i] := byte(1 shl Random(8));
        flobX := Random(170); flobY := Random(100);
        flipped := (test and 1)<>0;
        i := test mod (High(SPR_FLOB_FRAMES)+1);
        ref := ReferenceDanger(@SPR_FLOB_FRAMES[i]);
        actual := NarrowFlobDynamicDanger(@SPR_FLOB_FRAMES[i]);
        if ref <> actual then Fail('dynamic danger',test);
    end;
    Writeln(output,'PASS 2000 dynamic danger comparisons, both flips and edges'); Flush(output);

    LoadWorld(0);
    currentCollisionData := @collisionDataBuffer[0];
    FillChar(dynamicTileDanger,SizeOf(dynamicTileDanger),0);
    dynamicTileDangerCount := 0;
    dynamicTileDangerActive := false;
    for test := 0 to 99 do begin
        i := test mod currentWorldTileCount;
        ApplyTileCollision(test mod 30,test mod 50,currentWorldTiles+i,test and 1);
        total := 0;
        for j := 0 to High(dynamicTileDanger) do
            for n := 0 to 7 do
                if (dynamicTileDanger[j] and (1 shl n))<>0 then Inc(total);
        if (total<>dynamicTileDangerCount) or (dynamicTileDangerActive<>(total<>0)) then
            Fail('danger count',test);
    end;
    tile := currentWorldTiles^;
    tile.widthPx := 320; tile.heightPx := 160; tile.collisionOffset := 0;
    FillChar(solid,SizeOf(solid),$AA);
    savedCollision := currentWorldTileCollision;
    currentWorldTileCollision := @solid[0];
    ApplyTileCollision(0,0,@tile,0);
    currentWorldTileCollision := savedCollision;
    if (dynamicTileDangerCount<>0) or dynamicTileDangerActive then Fail('danger cleared',0);
    Writeln(output,'PASS tile danger accounting and last-hazard removal'); Flush(output);

    GetMem(expected,SCREEN_BYTES);
    FillChar(renderedSpriteCount,SizeOf(renderedSpriteCount),0);
    for i := 0 to 15999 do SCREEN_BKG[i] := word(longword(i)*157) xor $5AA5;
    BlitterCopyData16(SCREEN_BKG,SCREEN_LOG,SCREEN_BYTES);
    BlitterCopyData16(SCREEN_BKG,SCREEN_PHY,SCREEN_BYTES);
    for test := 0 to 79 do begin
        queuedSpriteCount[screenLogIndex] := 0;
        for i := 0 to 3 do begin
            visible := true;
            if test>=2 then visible := not ((i=1) and ((test mod 8)>=2));
            if not visible then continue;
            x := 32+i*64; y := 40;
            if test>=8 then begin x := x+(test mod 5)*2; y := 40+(i*3); end;
            if test>=32 then begin x := 80+i*4+(test mod 5)*2; y := 40+i; end;
            QueueGeneratedSprite(x,y,@SPR_SLIME_FRAMES[(test div 8) and 1],
                @SPR_SLIME_WORDS[0],nil,0,i);
        end;
        BlitterCopyData16(SCREEN_BKG,expected,SCREEN_BYTES);
        for i := 0 to queuedSpriteCount[screenLogIndex]-1 do begin
            spr := @queuedSprites[screenLogIndex,i];
            DrawGeneratedSpriteFrameBlitter(expected,spr^.x,spr^.y,spr^.frame,spr^.wordsBase);
        end;
        RenderQueuedSprites;
        if ((test=2) or (test=3)) and (verifyRestoreCount<>1) then Fail('stable ID restore count',test);
        for i := 0 to 15999 do
            if SCREEN_LOG[i]<>expected[i] then Fail('dirty framebuffer',test);
        SwapScreen;
    end;
    FreeMem(expected,SCREEN_BYTES);
    Writeln(output,'PASS 80 dirty-render frames on both buffers'); Flush(output);

    ResetJoystickState;
    gameplayInputInstalled := true;
    RawIkbdJoyStatus := 0;
    PByte(@RawIkbdKeyStates)[KEY_LEFT_CODE] := $FF;
    PByte(@RawIkbdKeyStates)[KEY_RIGHT_CODE] := 0;
    PollJoystickState;
    if (stick0 and $0C)<>$08 then Fail('left arrow',0);
    PollJoystickState;
    if (stick0 and $0C)<>$08 then Fail('left held',0);
    PByte(@RawIkbdKeyStates)[KEY_RIGHT_CODE] := $FF;
    PollJoystickState;
    if (stick0 and $0C)<>$0C then Fail('opposing arrows',0);
    PByte(@RawIkbdKeyStates)[KEY_LEFT_CODE] := 0;
    PollJoystickState;
    if (stick0 and $0C)<>$04 then Fail('right arrow',0);
    PByte(@RawIkbdKeyStates)[KEY_RIGHT_CODE] := 0;
    PollJoystickState;
    if (stick0 and $0C)<>$0C then Fail('arrow release',0);
    RawIkbdJoyStatus := $08;
    PByte(@RawIkbdKeyStates)[KEY_LEFT_CODE] := $FF;
    PollJoystickState;
    if ((stick0 and $0C)<>$0C) or (joyStatus<>$08) then Fail('opposed sources',0);
    PByte(@RawIkbdKeyStates)[KEY_LEFT_CODE] := 0;
    PollJoystickState;
    if (stick0 and $0C)<>$04 then Fail('joystick after arrow release',0);
    Writeln(output,'PASS held arrows, release and opposing sources');
    RawIkbdJoyStatus := 0;
    PByte(@RawIkbdKeyStates)[KEY_SPACE_CODE] := 0;
    PollJoystickState;
    if CRT_FirePressedEdge or (strig0=0) then Fail('idle input',0);
    PByte(@RawIkbdKeyStates)[KEY_SPACE_CODE] := $FF;
    PollJoystickState;
    if not CRT_FirePressedEdge or (strig0<>0) then Fail('space press',0);
    PollJoystickState;
    if CRT_FirePressedEdge then Fail('space held',0);
    RawIkbdJoyStatus := $80;
    PollJoystickState;
    if CRT_FirePressedEdge then Fail('second source',0);
    PByte(@RawIkbdKeyStates)[KEY_SPACE_CODE] := 0;
    PollJoystickState;
    if CRT_FirePressedEdge or (strig0<>0) then Fail('release one source',0);
    RawIkbdJoyStatus := 0;
    PollJoystickState;
    if CRT_FirePressedEdge or (strig0=0) then Fail('release all',0);
    RawIkbdJoyStatus := $80;
    PollJoystickState;
    if not CRT_FirePressedEdge then Fail('new press',0);
    gameplayInputInstalled := false;
    kbcode := KEY_SPACE_CODE;
    if not CRT_StartPressed or CRT_SelectPressed then Fail('menu space',0);
    Writeln(output,'PASS space/fire shared edge and menu alias');
    Writeln(output,'DONE'); Close(output);
end;
