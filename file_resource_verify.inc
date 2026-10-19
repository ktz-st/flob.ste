{ Target-side transitions, rendered frames and allocation ownership tests. }
procedure VerifyResourceLifetime;
var report: text;
    pass, w, bank, slide, slideCount, frame, track, j: word;
    baseFree, used, readsBefore: longword;
    musicCopy: array[0..63] of byte;

    procedure Check(ok: boolean; const reason: string);
    begin
        if ok then exit;
        Writeln(report, 'FAIL ', reason); Flush(report); Close(report);
        FileCleanup;
        Halt(1);
    end;

    procedure CheckBindings;
    var i, g, j: word;
    begin
        for i := 0 to High(FILE_LINKS) do
            Check(FILE_LINKS[i].dst^ = FILE_LINKS[i].src^, 'pointer table');
        for g := 0 to FILE_GROUP_COUNT-1 do begin
            if fileBlocks[g] = nil then continue;
            if FILE_LENGTH[g] = 0 then continue;
            for j := FILE_FIRST[g] to FILE_FIRST[g] + FILE_LENGTH[g]-1 do
                Check(FILE_BINDINGS[j].slot^ = pointer(PtrUInt(fileBlocks[g]) + FILE_BINDINGS[j].offset), 'group binding');
        end;
    end;
begin
    Assign(report, 'LIFETIME.TXT'); Rewrite(report);
    baseFree := PtrUInt(gemdos_malloc($FFFFFFFF));
    for pass := 0 to 1 do begin
        used := fileBytes;
        readsBefore := fileReads;
        for w := 0 to WORLD_COUNT-1 do begin
            FileWorldInfo(w);
            GetWorldStats(w);
            RenderWorldSelector(false);
        end;
        CheckAchievements;
        Check((fileBytes = used) and (fileReads = readsBefore), 'menu should not load worlds');
        InitTitle;
        BlackAll;
        Writeln(report, 'PASS resident selector and title, cycle=', pass); Flush(report);
        for w := 0 to WORLD_COUNT-1 do begin
            worldCurrent := w;
            BlackAll;
            LoadWorld(w);
            InitWorld;
            InitLevelScreen;
            LoadLevel(levelNum);
            SetLevelColors;
            music_track := w mod 5;
            PlaySong(MUSIC_LEVEL);
            FadeIn;
            for frame := 0 to 7 do begin
                BeginQueuedSpritesFrame;
                ShowSprites;
                DrawFlob;
                PresentQueuedSprites;
            end;
            { A song switch while visible must fade out before opening a file. }
            for track := 0 to 4 do begin
                music_track := track;
                PlaySong(MUSIC_LEVEL);
            end;
            BlackAll;
            CheckBindings;
            FileReleaseWorld;
            PlaySong(MUSIC_SILENT);
            Check(fileWorld = -1, 'world not released');
            Check(fileBytes = used, 'world/music bytes not reclaimed');
            Writeln(report, 'PASS world ', w, ' render, music switch, release'); Flush(report);
        end;
        for bank := 0 to 2 do begin
            BlackAll;
            case bank of
                0: begin slideCount := 6; FileBeginScene(INTRO_BANK); PlaySong(MUSIC_INTRO); end;
                1: begin slideCount := 3; FileBeginScene(OUTRO_BANK); PlaySong(MUSIC_OUTRO); end;
                2: begin slideCount := 7; FileBeginScene(CREDITS_BANK); end;
            end;
            for slide := 0 to slideCount-1 do begin
                case bank of
                    0: LoadCutsceneSlide(slide, INTRO_BANK);
                    1: LoadCutsceneSlide(slide, OUTRO_BANK);
                    2: LoadCutsceneSlide(slide, CREDITS_BANK);
                end;
                BlitterCopyData16(SCREEN_BKG, SCREEN_LOG, SCREEN_BYTES);
                SwapScreen;
            end;
            CheckBindings;
            Move(musicBuffer[0], musicCopy[0], SizeOf(musicCopy));
            case bank of
                0: FileEndScene(INTRO_BANK);
                1: FileEndScene(OUTRO_BANK);
                2: FileEndScene(CREDITS_BANK);
            end;
            for j := 0 to High(musicCopy) do
                Check(musicCopy[j] = musicBuffer[j], 'scene release modified playing music');
            Check(fileBytes = used, 'scene/music bytes not reclaimed');
            Writeln(report, 'PASS scene bank ', bank, ' draw and release'); Flush(report);
        end;
        StopSong;
        Check(PtrUInt(gemdos_malloc($FFFFFFFF)) = baseFree, 'allocation leak or fragmentation');
    end;
    Writeln(report, 'peak resource bytes=', filePeak, ' resident=', fileBytes);
    Writeln(report, 'peak with packed input=', filePeakWithPacked);
    Writeln(report, 'largest free with resident assets=', baseFree);
    Writeln(report, 'DONE'); Close(report);
    FileCleanup;
    Halt;
end;
