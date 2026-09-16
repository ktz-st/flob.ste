// Controlled renderer workload, not an automated gameplay/physics test.
procedure RunSlimeBenchmark;
const Frames = 512;
{$ifdef BENCH_W1_R13}
      BenchWorld = 1;
      BenchRoom = 13;
{$else}
      BenchWorld = 0;
      BenchRoom = 6;
{$endif}
var phase, i: word;
    t0, t1, t2, startTick, startVbl, queueTicks, renderTicks, frameVbl, span: longword;
    ticks, vbls, blits, rects, pixels, queues, renders: array[0..5] of longword;
    emsCalls: array[0..5] of longword;
    histogram: array[0..5,0..3] of longword;
    output: text;
{$ifdef BENCH_PROFILE}
    profileOutput: text;
{$endif}
begin
{$ifdef BENCH_PROFILE}
    Assign(profileOutput, 'PROFILE.CSV');
    Rewrite(profileOutput);
    Writeln(profileOutput, 'phase,build_ticks,copy_ticks,draw_ticks,history_ticks');
{$endif}
    // Force PAL even when the EmuTOS default country boots in 60 Hz.
    PByte(pointer(longword($FFFF820A)))^ := 2;
    VSync;
    FillChar(histogram, SizeOf(histogram), 0);
    keyboardInputEnabled := false;
    InstallGameplayInput;
    worldCurrent := BenchWorld;
    LoadWorld(worldCurrent);
    InitWorld;
    levelNum := BenchRoom;
    music_track := BenchWorld;
    PlaySong(MUSIC_LEVEL);
    for phase := 0 to 5 do begin
        BlackAll;
        flipped := false;
        room_changed := false;
        LoadLevel(BenchRoom);
        SetLevelColors;
        msgDisplayCounter := 0;
        ClearTxt2;
        flobX := 90;
        flobY := 50;
        flobDir := 0;
        flobFrame := 0;
        invulnerability := 0;
        if phase < 2 then FillChar(slimeX, SizeOf(slimeX), 0);
        // Warm both buffers; exclude initial room loading and first paint.
        sysframe := 0;
        for i := 0 to 3 do begin
            BeginQueuedSpritesFrame;
            DrawSlimes;
            DrawFlob;
            ShowSprites;
            PresentQueuedSprites;
        end;
        benchBlits := 0;
        emsDrawCounter := 0;
        benchRestoreRects := 0;
        benchRestorePixels := 0;
        queueTicks := 0;
        renderTicks := 0;
{$ifdef BENCH_PROFILE}
        benchBuildTicks := 0;
        benchCopyTicks := 0;
        benchDrawTicks := 0;
        benchHistoryTicks := 0;
{$endif}
        startTick := PLongWord(pointer(longword($4BA)))^;
        startVbl := PLongWord(pointer(longword($466)))^;
        for i := 0 to Frames - 1 do begin
            frameVbl := PLongWord(pointer(longword($466)))^;
            t0 := PLongWord(pointer(longword($4BA)))^;
            GameplayFrameTick;
            if (phase = 2) or (phase = 4) then sysframe := 0;
            if (phase = 1) or (phase = 4) or (phase = 5) then begin
                if (i and 63) < 32 then flobX := 90 + byte(i and 31)
                else flobX := 121 - byte(i and 31);
            end;
            BeginQueuedSpritesFrame;
            DrawSlimes;
            DrawFlob;
            ShowSprites;
            t1 := PLongWord(pointer(longword($4BA)))^;
            FlushQueuedSprites;
            t2 := PLongWord(pointer(longword($4BA)))^;
            Inc(queueTicks, t1 - t0);
            Inc(renderTicks, t2 - t1);
            SwapScreen;
            span := PLongWord(pointer(longword($466)))^ - frameVbl;
            if span > 3 then span := 3;
            Inc(histogram[phase,span]);
        end;
        ticks[phase] := PLongWord(pointer(longword($4BA)))^ - startTick;
        vbls[phase] := PLongWord(pointer(longword($466)))^ - startVbl;
        queues[phase] := queueTicks;
        renders[phase] := renderTicks;
        blits[phase] := benchBlits;
        rects[phase] := benchRestoreRects;
        pixels[phase] := benchRestorePixels;
        emsCalls[phase] := emsDrawCounter;
{$ifdef BENCH_PROFILE}
        Writeln(profileOutput, phase, ',', benchBuildTicks, ',', benchCopyTicks, ',',
            benchDrawTicks, ',', benchHistoryTicks);
{$endif}
    end;
{$ifdef BENCH_PROFILE}
    Close(profileOutput);
    LoadLevel(BenchRoom);
    flobX := 0;
    flobY := 0;
    flobFrame := 0;
    flobDir := 0;
    startTick := PLongWord(pointer(longword($4BA)))^;
    for i := 1 to 4096 do CheckSlimeCollision;
    startTick := PLongWord(pointer(longword($4BA)))^ - startTick;
    Assign(profileOutput, 'COLL.TXT');
    Rewrite(profileOutput);
    Writeln(profileOutput, '4096 CheckSlimeCollision calls, Flob at 0,0 (no pickup): ', startTick, ' HZ200 ticks');
    Close(profileOutput);
{$endif}
    StopSong;
    Assign(output, 'BENCH.CSV');
    Rewrite(output);
    Writeln(output, 'phase,frames,hz200_ticks,vbls,queue_ticks,render_ticks,blits,restore_rects,restore_pixels,frames_1vbl,frames_2vbl,frames_3plus_vbl,ems_calls');
    for phase := 0 to 5 do
        Writeln(output, phase, ',', Frames, ',', ticks[phase], ',', vbls[phase], ',',
            queues[phase], ',', renders[phase], ',', blits[phase], ',', rects[phase], ',', pixels[phase], ',',
            histogram[phase,1], ',', histogram[phase,2], ',', histogram[phase,3], ',', emsCalls[phase]);
    Close(output);
end;
