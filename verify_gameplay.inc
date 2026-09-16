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

    procedure ReferenceOccludedFlob(dst: PWord; sx, sy: word; frame: PSteSpriteFrame);
    var lx, ly, plane, offset, sourceOffset, color: word;
        bit, sourceBit: word;
    begin
        if (sx >= 320) or (sy >= 200) or (sx + frame^.widthPx > 320) or
           (sy + frame^.heightPx > 200) then exit;
        for ly := 0 to frame^.heightPx-1 do
            for lx := 0 to frame^.widthPx-1 do begin
                if not GeneratedSpriteOpaqueAt(frame,@SPR_FLOB_WORDS[0],lx,ly) then continue;
                offset := (sy+ly)*80 + ((sx+lx) shr 4)*4;
                bit := word($8000) shr ((sx+lx) and 15);
                color := 0;
                for plane := 0 to 3 do
                    if (SCREEN_BKG[offset+plane] and bit) <> 0 then
                        color := color or (1 shl plane);
                if (sy+ly >= BG_IMAGE_OFFSET_Y) and
                   (sy+ly < BG_IMAGE_OFFSET_Y+PLAYFIELD_HEIGHT) and
                   ((color=1) or (color=2)) then continue;
                sourceOffset := frame^.dataOffset + ly*frame^.rowWords*4 + (lx shr 4)*4;
                sourceBit := word($8000) shr (lx and 15);
                for plane := 0 to 3 do begin
                    dst[offset+plane] := dst[offset+plane] and not bit;
                    if (SPR_FLOB_WORDS[sourceOffset+plane] and sourceBit) <> 0 then
                        dst[offset+plane] := dst[offset+plane] or bit;
                end;
            end;
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
            spr := @queuedSprites[screenLogIndex]^[i];
            DrawGeneratedSpriteFrameBlitter(expected,spr^.x,spr^.y,spr^.frame,spr^.wordsBase);
        end;
        RenderQueuedSprites;
{$ifndef SIMPLE_RESTORE}
        if ((test=2) or (test=3)) and (verifyRestoreCount<>1) then Fail('stable ID restore count',test);
{$else}
        if ((test=2) or (test=3)) and (verifyRestoreCount<>4) then Fail('simple restore count',test);
{$endif}
        for i := 0 to 15999 do
            if SCREEN_LOG[i]<>expected[i] then Fail('dirty framebuffer',test);
        SwapScreen;
    end;
    // Wide overlapping sprites form chains: redraw must propagate beyond the
    // first dirty rectangle. Also exercise queue capacity and an empty frame.
    for test := 0 to 95 do begin
        queuedSpriteCount[screenLogIndex] := 0;
        for i := 0 to MAX_QUEUED_SPRITES - 1 do begin
            if (test mod 16) = 15 then continue;
            if (test >= 16) and (i >= 12) then continue;
            if (test >= 16) and (i = (test div 2) mod 12) and ((test mod 4) >= 2) then continue;
            x := (i mod 16)*18 + ((test div 4) and 1)*2;
            y := 20+(i div 16)*40;
            if test >= 16 then begin
                x := 48+i*4;
                y := 40+(i mod 3)*3;
                if i = 0 then Inc(x, ((test div 2) mod 5)*2);
            end;
            if (i mod 3) = 0 then
                QueueGeneratedSprite(x,y,@SPR_FLOB_FRAMES[0],@SPR_FLOB_WORDS[0],nil,0,i)
            else
                QueueGeneratedSprite(x,y,@SPR_SLIME_FRAMES[(test div 16) and 1],
                    @SPR_SLIME_WORDS[0],nil,0,i);
        end;
        BlitterCopyData16(SCREEN_BKG,expected,SCREEN_BYTES);
        if queuedSpriteCount[screenLogIndex] > 0 then
            for i := 0 to queuedSpriteCount[screenLogIndex]-1 do begin
                spr := @queuedSprites[screenLogIndex]^[i];
                DrawGeneratedSpriteFrameBlitter(expected,spr^.x,spr^.y,spr^.frame,spr^.wordsBase);
            end;
        RenderQueuedSprites;
        for i := 0 to 15999 do
            if SCREEN_LOG[i]<>expected[i] then Fail('overlap-chain framebuffer',test);
        SwapScreen;
    end;
    worldCurrent := 0;
    LoadWorld(worldCurrent);
    InitWorld;
    LoadLevel(13);
    FillChar(renderedSpriteCount,SizeOf(renderedSpriteCount),0);
    BlitterCopyData16(SCREEN_BKG,SCREEN_LOG,SCREEN_BYTES);
    BlitterCopyData16(SCREEN_BKG,SCREEN_PHY,SCREEN_BYTES);
    if (sprites.state <> SPRITE_TWO) or (sprites.stype[0] <> STYPE_KEY) or
       (sprites.stype[1] <> STYPE_KEY) then Fail('W0 R13 setup',0);
    for n := 0 to 1 do begin
        flipped := n <> 0;
        for j := 0 to 1 do begin
            if spriteAtlasFrames[j] = nil then Fail('W0 R13 atlas',j);
            for test := 0 to 31 do begin
                BeginQueuedSpritesFrame;
                spriteFrame[j] := (test div 4) mod spriteData.frameCount[j];
                ShowSprites;
                spr := @queuedSprites[screenLogIndex]^[j];
                flobX := (spr^.x div 2) + (test div 8);
                flobY := (smallint(spr^.y) - FLOB_RENDER_OFFSET_Y) div 2;
                flobFrame := FRAME_STAND;
                flobDir := DIR_RIGHT;
                BeginQueuedSpritesFrame;
                // Room-entry and gameplay calls enqueue Flob in opposite order.
                if (test mod 8) < 2 then begin ShowSprites; DrawFlob; end
                else begin DrawFlob; ShowSprites; end;
                BlitterCopyData16(SCREEN_BKG,expected,SCREEN_BYTES);
                for i := 0 to queuedSpriteCount[screenLogIndex]-1 do begin
                    spr := @queuedSprites[screenLogIndex]^[i];
                    if spr^.stableId = 20 then continue;
                    DrawGeneratedSpriteFrameBlitter(expected,spr^.x,spr^.y,spr^.frame,spr^.wordsBase);
                end;
                for i := 0 to queuedSpriteCount[screenLogIndex]-1 do begin
                    spr := @queuedSprites[screenLogIndex]^[i];
                    if spr^.stableId <> 20 then continue;
                    ReferenceOccludedFlob(expected,spr^.x,spr^.y,spr^.frame);
                end;
                RenderQueuedSprites;
                for i := 0 to 15999 do
                    if SCREEN_LOG[i]<>expected[i] then Fail('W0 R13 Flob priority',n*64+j*32+test);
                SwapScreen;
            end;
        end;
    end;
    for test := 0 to 127 do begin
        for i := 0 to 15999 do begin
            SCREEN_BKG[i] := word(longword(i)*157) xor $5AA5;
            SCREEN_LOG[i] := $A55A;
            expected[i] := $A55A;
        end;
        x := test and 15;
        if test >= 112 then Inc(x,304);
        case (test shr 5) of
            0: y := 12;
            1: y := 20;
            2: y := 172;
            3: y := 184;
        end;
        ReferenceOccludedFlob(expected,x,y,@SPR_FLOB_FRAMES[(test shr 1) mod SPR_FLOB_FRAME_COUNT]);
        DrawOccludedFlob(SCREEN_LOG,x,y,@SPR_FLOB_FRAMES[(test shr 1) mod SPR_FLOB_FRAME_COUNT]);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> expected[i] then Fail('Flob background occlusion',test);
    end;
    Writeln(output,'PASS 128 Flob occlusion comparisons, all shifts, frames and playfield edges'); Flush(output);
    for test := 0 to FLIP_STEPS-1 do begin
        for i := 0 to 15999 do SCREEN_LOG[i] := $A55A;
        DrawSquashedPlayfieldCpu(SCREEN_BKG,FLIP_H[test]);
        Move(SCREEN_LOG^,expected^,SCREEN_BYTES);
        for i := 0 to 15999 do SCREEN_LOG[i] := $A55A;
        DrawSquashedPlayfieldBlitter(SCREEN_BKG,FLIP_H[test]);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> expected[i] then Fail('precomputed flip parameters',test);
    end;
    Writeln(output,'PASS flip table against CPU sampling, all nonzero FLIP_H heights'); Flush(output);
    FreeMem(expected,SCREEN_BYTES);
    Writeln(output,'PASS 80 dirty-render frames on both buffers'); Flush(output);
    Writeln(output,'PASS 96 overlap-chain, full-queue and empty-frame comparisons'); Flush(output);
    Writeln(output,'PASS 128 W0 R13 switch overlaps, both buffers/orientations and queue orders'); Flush(output);

    // Check queued animation, collision-frame selection and both page histories.
    GetMem(expected,SCREEN_BYTES);
    for n := 0 to 1 do begin
        flipped := n <> 0;
        FillChar(slimeX,SizeOf(slimeX),80);
        FillChar(renderedSpriteCount,SizeOf(renderedSpriteCount),0);
        Move(SCREEN_BKG^,SCREEN_LOG^,SCREEN_BYTES);
        Move(SCREEN_BKG^,SCREEN_PHY^,SCREEN_BYTES);
        for test := 0 to 63 do begin
            sysframe := byte((240 + test) and 255);
            BeginQueuedSpritesFrame;
            DrawSlimes;
            Move(SCREEN_BKG^,expected^,SCREEN_BYTES);
            for i := 0 to queuedSpriteCount[screenLogIndex]-1 do begin
                spr := @queuedSprites[screenLogIndex]^[i];
                j := sysframe;
{$ifdef STAGGER_SLIME}
                j := (j + 256 - (spr^.stableId and 1)) and 255;
{$endif}
                j := (j shr 4) and 1;
                if (spr^.frame <> @SPR_SLIME_FRAMES[j]) or
                   (slimeDrawFrame[spr^.stableId] <> j) then Fail('slime phase',test);
                DrawGeneratedSpriteFrameBlitter(expected,spr^.x,spr^.y,spr^.frame,spr^.wordsBase);
            end;
            RenderQueuedSprites;
            for i := 0 to 15999 do
                if SCREEN_LOG[i] <> expected[i] then Fail('slime stagger pages',test);
            SwapScreen;
        end;
    end;
    FreeMem(expected,SCREEN_BYTES);
    Writeln(output,'PASS 128 slime animation frames, counter wrap, collision frames and both pages'); Flush(output);

    // A flip alone must not activate a key; falling into it must.
    worldCurrent := 1;
    LoadWorld(worldCurrent);
    for n := 0 to 1 do begin
        flipped := false;
        LoadLevel(7);
        if (sprites.stype[0]<>STYPE_KEY) or (sprites.goal[0]<>4) or
           (spriteAtlasFrames[0]=nil) then Fail('W1 R07 setup',n);
        flipped := n <> 0;
        goals[4] := 1;
        spriteFrame[0] := 0;
        spriteTargetFrame[0] := 0;
        savedCollision := currentCollisionData;
        currentCollisionData := nil; // isolate sprite contact from room floors
        flobX := 78;
        flobY := 20;
        flobDir := DIR_RIGHT;
        flobFrame := FRAME_STAND;
        flobFalling := 0;
        spriteCollisionMovePending := true;
        FlobFootUpdate;
        for test := 0 to 40 do begin
            FlobFall;
            CheckSpriteCollisions;
            if goals[4] = 0 then break;
        end;
        currentCollisionData := savedCollision;
        if goals[4] <> 0 then Fail('W1 R07 falling lever contact',n);
        goals[4] := 1;
        spriteCollisionMovePending := true;
        CheckSpriteCollisions;
        if goals[4] <> 1 then Fail('stationary lever after flip',n);
        FillChar(solid,SizeOf(solid),GROUND_COLLISION_COLOR*$55);
        currentCollisionData := @solid[0];
        y := flobY;
        FlobFall;
        if (flobY<>y) or not spriteCollisionMovePending then
            Fail('blocked fall releases flip guard',n);
        currentCollisionData := savedCollision;
    end;
    Writeln(output,'PASS W1 R07 falling lever contact in both orientations'); Flush(output);

    worldCurrent := 4;
    LoadWorld(worldCurrent);
    for n := 0 to 1 do begin
        InitWorld;
        flipped := false;
        levelNum := 11;
        LoadLevel(levelNum);
        flipped := n <> 0;
        mainGoalReached := false;
        msgDisplayCounter := 0;
        spriteCollisionMovePending := false;
        flobDir := DIR_RIGHT;
        flobFrame := FRAME_STAND;
        // Touch from the left, outside the message's x=126..134 point test.
        for x := 119 to 125 do begin
            for y := 0 to 79 do begin
                flobX := x; flobY := y;
                CheckSpriteCollisions;
                if mainGoalReached then break;
            end;
            if mainGoalReached then break;
        end;
        if not mainGoalReached then Fail('W4 R11 edge pickup',n);
        if (msgDisplayCounter <> 250) or (triggers[4] <> 0) then
            Fail('W4 R11 pickup message',n);
        msgDisplayCounter := 42;
        ShowCollectedGoalMessage(0);
        if msgDisplayCounter <> 42 then Fail('W4 R11 message repeated',n);
    end;
    Writeln(output,'PASS W4 R11 edge pickup message, both flips, once only'); Flush(output);

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
