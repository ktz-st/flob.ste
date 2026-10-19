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
    intersectionSprite: TQueuedSprite;
    intersectionRects: TDirtyRectArray;
    intersectionCount, intersectionFirst: byte;
    equalityA, equalityB: TQueuedSprite;
    savedPage: byte;
    swapSlots: PQueuedSpriteSlots;
    startTick, referenceTicks, fastTicks: longword;
    flipHeight: word;
    referenceQueue: TQueuedSpriteSlots;
    referenceFrames: array[0..19] of byte;
    referenceCount, prefixCount, frameIndex: byte;

    procedure ReferenceSquash(src, dst: PWord; height: word);
    var row, sourceY, destY: word;
    begin
        if (height = 0) or (height > PLAYFIELD_HEIGHT) then exit;
        destY := BG_IMAGE_OFFSET_Y + (PLAYFIELD_HEIGHT - height) div 2;
        for row := 0 to height - 1 do begin
            sourceY := BG_IMAGE_OFFSET_Y + word((longword(row) * PLAYFIELD_HEIGHT) div height);
            Move(PByte(longword(src) + longword(sourceY) * SCREEN_LINE_BYTES)^,
                 PByte(longword(dst) + longword(destY + row) * SCREEN_LINE_BYTES)^,
                 SCREEN_LINE_BYTES);
        end;
    end;

    procedure ReferenceMirror(buf: PWord);
    var row: word;
        top, bottom: PByte;
        temp: array[0..SCREEN_LINE_BYTES-1] of byte;
    begin
        for row := 0 to PLAYFIELD_HEIGHT div 2 - 1 do begin
            top := PByte(longword(buf) + longword(BG_IMAGE_OFFSET_Y + row) * SCREEN_LINE_BYTES);
            bottom := PByte(longword(buf) + longword(BG_IMAGE_OFFSET_Y + PLAYFIELD_HEIGHT - 1 - row) * SCREEN_LINE_BYTES);
            Move(top^, temp[0], SCREEN_LINE_BYTES);
            Move(bottom^, top^, SCREEN_LINE_BYTES);
            Move(temp[0], bottom^, SCREEN_LINE_BYTES);
        end;
    end;

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
    Writeln(output,'renderer_blitter=',useBlitter); Flush(output);
    if (SizeOf(TQueuedSprite) <> 32) or
       (PtrUInt(@equalityA.y)-PtrUInt(@equalityA) <> 2) or
       (PtrUInt(@equalityA.widthPx)-PtrUInt(@equalityA) <> 4) or
       (PtrUInt(@equalityA.heightPx)-PtrUInt(@equalityA) <> 6) or
       (PtrUInt(@equalityA.palSlot)-PtrUInt(@equalityA) <> 20) or
       (PtrUInt(@equalityA.stableId)-PtrUInt(@equalityA) <> 21) then
        Fail('sprite equality layout',0);
    // Every bit of every byte, including deliberately ignored ID/padding.
    // Pointer bit patterns are compared only, never dereferenced.
    for test := 0 to 15 do begin
        FillChar(equalityA,SizeOf(equalityA),byte(test*17));
        equalityB := equalityA;
        if not QueuedSpritesEqual(@equalityA,@equalityB) then Fail('equal sprite',test);
        for i := 0 to SizeOf(TQueuedSprite)-1 do
            for j := 0 to 7 do begin
                PByte(@equalityB)[i] := PByte(@equalityA)[i] xor byte(1 shl j);
                actual := QueuedSpritesEqual(@equalityA,@equalityB);
                ref := ReferenceQueuedSpritesEqual(@equalityA,@equalityB);
                if (actual <> ref) or (actual <> (i >= 21)) then
                    Fail('paired sprite equality',test*256+i*8+j);
                PByte(@equalityB)[i] := PByte(@equalityA)[i];
            end;
    end;
    Writeln(output,'PASS 4096 paired sprite equality comparisons, ID and padding ignored'); Flush(output);
    if PtrUInt(@a.heightPx)-PtrUInt(@a) <> 2 then Fail('queue frame layout',0);
    savedPage := screenLogIndex;
    FillChar(a,SizeOf(a),0);
    FillChar(b,SizeOf(b),0);
    b.widthPx := 7; b.heightPx := 9;
    for test := 0 to 7 do begin
        screenLogIndex := test and 1;
        queuedSpriteCount[screenLogIndex] := 0;
        QueueGeneratedSprite(0,0,nil,@ma[0]);
        if queuedSpriteCount[screenLogIndex] <> 0 then Fail('nil queue frame',test);
        for i := 0 to MAX_QUEUED_SPRITES-1 do begin
            // Reuse a frame address while changing dimensions, not just its ID.
            a.widthPx := i+1; a.heightPx := test+1;
            QueueGeneratedSprite(i*6,20+test,@a,@ma[0],byte(i));
            spr := @queuedSprites[screenLogIndex]^[i];
            if (spr^.widthPx <> i+1) or (spr^.heightPx <> test+1) or
               (spr^.x <> i*6) or (spr^.y <> 20+test) or
               (spr^.frame <> @a) or (spr^.wordsBase <> @ma[0]) or
               (spr^.palBase <> nil) or (spr^.palSlot <> 0) then
                Fail('queue metadata',test*48+i);
            if i < 32 then n := i else n := 32+i;
            if spr^.stableId <> n then Fail('queue stable ID',test*48+i);
        end;
        QueueGeneratedSprite(999,999,@b,@mb[0]);
        if (queuedSpriteCount[screenLogIndex] <> MAX_QUEUED_SPRITES) or
           (queuedSprites[screenLogIndex]^[47].x <> 282) then
            Fail('queue capacity',test);
        queuedSpriteCount[screenLogIndex] := 0;
        QueueGeneratedSprite(5,6,@b,@mb[0]);
        spr := @queuedSprites[screenLogIndex]^[0];
        if (spr^.frame <> @b) or (spr^.wordsBase <> @mb[0]) or
           (spr^.widthPx <> 7) or (spr^.heightPx <> 9) or
           (spr^.stableId <> 32) or (spr^.palBase <> nil) or (spr^.palSlot <> 0) then
            Fail('queue slot reused by sprite',test);
        swapSlots := queuedSprites[screenLogIndex];
        queuedSprites[screenLogIndex] := renderedSprites[screenLogIndex];
        renderedSprites[screenLogIndex] := swapSlots;
    end;
    // Eight passes swap each page's lists four times, restoring original roles.
    screenLogIndex := savedPage;
    FillChar(queuedSpriteCount,SizeOf(queuedSpriteCount),0);
    FillChar(spriteSlots,SizeOf(spriteSlots),0);
    Writeln(output,'PASS queue reuse across four lists, dimensions, IDs, nil and full queue'); Flush(output);
    // Independent old Pascal enqueue path, including clipping, full queues and
    // inactive IDs whose last collision-animation frame must remain untouched.
    for test := 0 to 511 do begin
        screenLogIndex := test and 1;
        if (test and 2) <> 0 then begin
            swapSlots := queuedSprites[screenLogIndex];
            queuedSprites[screenLogIndex] := renderedSprites[screenLogIndex];
            renderedSprites[screenLogIndex] := swapSlots;
        end;
        flipped := (test and 4) <> 0;
        sysframe := byte(test);
        prefixCount := (test shr 3) mod (MAX_QUEUED_SPRITES+1);
        FillChar(queuedSprites[screenLogIndex]^,SizeOf(referenceQueue),$A5);
        FillChar(slimeDrawFrame,SizeOf(slimeDrawFrame),$5A);
        queuedSpriteCount[screenLogIndex] := prefixCount;
        for i := 0 to 19 do begin
            slimeX[i] := byte(test*13+i*31);
            if ((i+test) mod 5) = 0 then slimeX[i] := 0;
            if slimeX[i] = 0 then continue;
            frameIndex := (sysframe shr 4) and 1;
{$ifdef STAGGER_SLIME}
            if ((i and 1) <> 0) and ((sysframe and 15) = 0) then
                frameIndex := frameIndex xor 1;
{$endif}
            slimeDrawFrame[i] := frameIndex;
            SlimeScreenPosition(i,bx,by);
            if (bx < 0) or (by < 0) then continue;
            QueueGeneratedSprite(word(bx),word(by),@SPR_SLIME_FRAMES[frameIndex],
                @SPR_SLIME_WORDS[0],i);
        end;
        referenceQueue := queuedSprites[screenLogIndex]^;
        Move(slimeDrawFrame,referenceFrames,SizeOf(referenceFrames));
        referenceCount := queuedSpriteCount[screenLogIndex];
        FillChar(queuedSprites[screenLogIndex]^,SizeOf(referenceQueue),$A5);
        FillChar(slimeDrawFrame,SizeOf(slimeDrawFrame),$5A);
        queuedSpriteCount[screenLogIndex] := prefixCount;
        DrawSlimes;
        if queuedSpriteCount[screenLogIndex] <> referenceCount then Fail('batch slime count',test);
        for i := 0 to SizeOf(referenceQueue)-1 do
            if PByte(queuedSprites[screenLogIndex])[i] <> PByte(@referenceQueue)[i] then
                Fail('batch slime descriptors and guards',test);
        for i := 0 to 19 do
            if slimeDrawFrame[i] <> referenceFrames[i] then Fail('batch collision frame',test);
    end;
    screenLogIndex := savedPage;
    FillChar(queuedSpriteCount,SizeOf(queuedSpriteCount),0);
    FillChar(spriteSlots,SizeOf(spriteSlots),0);
    Writeln(output,'PASS 512 batch slime queues, four lists, clipping, capacity and collision frames'); Flush(output);
    if (SizeOf(TDirtyRect) <> 8) or
       (PtrUInt(@intersectionSprite.heightPx)-PtrUInt(@intersectionSprite) <> 6) then
        Fail('dirty intersection ASM layout',0);
    RandSeed := 67890;
    for test := 0 to 3999 do begin
        intersectionCount := Random(MAX_DIRTY_RECTS+1);
        intersectionFirst := Random(MAX_DIRTY_RECTS+2);
        intersectionSprite.x := Random(65536);
        intersectionSprite.y := Random(65536);
        intersectionSprite.widthPx := Random(65536);
        intersectionSprite.heightPx := Random(65536);
        if (test and 1) = 0 then begin
            intersectionSprite.x := Random(340);
            intersectionSprite.y := Random(220);
            intersectionSprite.widthPx := Random(49);
            intersectionSprite.heightPx := Random(49);
        end;
        // Reuse each random list for 32 different sprite/range probes; RNG
        // on the target is much more expensive than the intersection itself.
        if (test and 31) = 0 then
        for i := 0 to MAX_DIRTY_RECTS-1 do begin
            intersectionRects[i].x := Random(320);
            intersectionRects[i].y := Random(200);
            intersectionRects[i].widthPx := Random(49);
            intersectionRects[i].heightPx := Random(49);
            if (test and 32) <> 0 then begin
                intersectionRects[i].x := Random(65536);
                intersectionRects[i].y := Random(65536);
                intersectionRects[i].widthPx := Random(65536);
                intersectionRects[i].heightPx := Random(65536);
            end;
        end;
        spr := @intersectionSprite;
        if (test mod 19) = 0 then spr := nil;
        ref := ReferenceSpriteIntersectsDirty(spr,intersectionRects,intersectionCount,intersectionFirst);
        actual := SpriteIntersectsDirty(spr,intersectionRects,intersectionCount,intersectionFirst);
        if ref <> actual then Fail('dirty intersection ASM',test);
    end;
    Writeln(output,'PASS 4000 dirty intersection ASM/Pascal comparisons'); Flush(output);
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
                @SPR_SLIME_WORDS[0],i);
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
                // Reverse spatial order too: propagation must revisit earlier
                // queue entries after discovering dirty bounds later in a pass.
                if (test and 16) <> 0 then x := 48+(11-i)*4;
                y := 40+(i mod 3)*3;
                if i = 0 then Inc(x, ((test div 2) mod 5)*2);
            end;
            if (i mod 3) = 0 then
                QueueGeneratedSprite(x,y,@SPR_FLOB_FRAMES[0],@SPR_FLOB_WORDS[0],i)
            else
                QueueGeneratedSprite(x,y,@SPR_SLIME_FRAMES[(test div 16) and 1],
                    @SPR_SLIME_WORDS[0],i);
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
    for test := 0 to FLIP_STEPS+2 do begin
        if test < FLIP_STEPS then flipHeight := FLIP_H[test]
        else case test-FLIP_STEPS of
            0: flipHeight := 73;
            1: flipHeight := 0;
            2: flipHeight := PLAYFIELD_HEIGHT+1;
        end;
        for i := 0 to 15999 do expected[i] := $A55A;
        ReferenceSquash(SCREEN_BKG,expected,flipHeight);
        for i := 0 to 15999 do SCREEN_LOG[i] := $A55A;
        DrawSquashedPlayfieldCpu(SCREEN_BKG,flipHeight);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> expected[i] then Fail('CPU flip rows',test);
        for i := 0 to 15999 do SCREEN_LOG[i] := $A55A;
        DrawSquashedPlayfieldBlitter(SCREEN_BKG,flipHeight);
        for i := 0 to 15999 do
            if SCREEN_LOG[i] <> expected[i] then Fail('precomputed flip parameters',test);
    end;
    Writeln(output,'PASS flip rows against independent sampling, fixed heights, fallback and bounds'); Flush(output);
    Move(SCREEN_BKG^,expected^,SCREEN_BYTES);
    ReferenceMirror(expected);
    FlipGameplayAreaInPlace(SCREEN_BKG);
    for i := 0 to 15999 do
        if SCREEN_BKG[i] <> expected[i] then Fail('CPU playfield mirror',i);
    ReferenceMirror(expected);
    FlipGameplayAreaInPlace(SCREEN_BKG);
    for i := 0 to 15999 do
        if SCREEN_BKG[i] <> expected[i] then Fail('CPU playfield mirror twice',i);
    Writeln(output,'PASS in-place playfield mirror, both directions and untouched HUD/message'); Flush(output);
    // Target 200 Hz clock, no VSync: compare rendering work, not fixed frame holds.
    startTick := PLongWord(pointer(longword($4BA)))^;
    for n := 0 to 63 do
        for test := 0 to FLIP_STEPS-1 do
            ReferenceSquash(SCREEN_BKG,SCREEN_LOG,FLIP_H[test]);
    referenceTicks := PLongWord(pointer(longword($4BA)))^ - startTick;
    startTick := PLongWord(pointer(longword($4BA)))^;
    for n := 0 to 63 do
        for test := 0 to FLIP_STEPS-1 do
            DrawSquashedPlayfieldCpu(SCREEN_BKG,FLIP_H[test]);
    fastTicks := PLongWord(pointer(longword($4BA)))^ - startTick;
    Writeln(output,'BENCH squash 64x all heights: old_ticks=',referenceTicks,' new_ticks=',fastTicks); Flush(output);
    startTick := PLongWord(pointer(longword($4BA)))^;
    for n := 0 to 63 do ReferenceMirror(SCREEN_BKG);
    referenceTicks := PLongWord(pointer(longword($4BA)))^ - startTick;
    startTick := PLongWord(pointer(longword($4BA)))^;
    for n := 0 to 63 do FlipGameplayAreaInPlace(SCREEN_BKG);
    fastTicks := PLongWord(pointer(longword($4BA)))^ - startTick;
    Writeln(output,'BENCH mirror 64x: old_ticks=',referenceTicks,' new_ticks=',fastTicks); Flush(output);
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
