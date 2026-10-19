{ File distribution only: each bundle owns a single GEMDOS allocation. }
{$i file_resource_tables.inc}
var
    fileBlocks: array[0..FILE_GROUP_COUNT-1] of pointer;
    fileWorld: smallint = -1;
    fileMusic: smallint = -1;
    fileInfoBuffer: array[0..WORLD_DATA_BYTES-1] of byte;
    fileBytes, filePeak, fileReads: longword;
    filePackedBlock: pointer;
    filePeakWithPacked: longword;
    assetFile: file;
    assetPath: string;
    assetOpen: boolean;

procedure FileRefreshLinks;
var i: word;
begin
    for i := 0 to High(FILE_LINKS) do
        FILE_LINKS[i].dst^ := FILE_LINKS[i].src^;
end;

procedure FileFreeGroup(g: word);
var i: word;
    address: pointer;
begin
    if fileBlocks[g] = nil then exit;
    if FILE_LENGTH[g] > 0 then
        for i := FILE_FIRST[g] to FILE_FIRST[g] + FILE_LENGTH[g] - 1 do begin
            address := pointer(PtrUInt(fileBlocks[g]) + FILE_BINDINGS[i].offset);
            if FILE_BINDINGS[i].slot^ = address then FILE_BINDINGS[i].slot^ := nil;
        end;
    gemdos_mfree(fileBlocks[g]);
    fileBlocks[g] := nil;
    Dec(fileBytes, FILE_SIZES[g]);
    FileRefreshLinks;
end;

procedure FileCleanup;
var g: word;
begin
    if fileInputReady then begin
        UnInstallInput;
        fileInputReady := false;
    end;
    if soundReady then DoneSound;
    if filePackedBlock <> nil then begin
        gemdos_mfree(filePackedBlock);
        filePackedBlock := nil;
    end;
    for g := 0 to FILE_GROUP_COUNT - 1 do FileFreeGroup(g);
    if fileVideoReady then begin
        ScreenDone;
        fileVideoReady := false;
    end;
end;

procedure AssetFailure(const reason: string);
{$if defined(VERIFY_FILE_ASSETS) or defined(VERIFY_FILE_IO_ERRORS)}
var report: text;
{$endif}
begin
    if assetOpen then begin
        {$I-} Close(assetFile); {$I+}
        if IOResult <> 0 then;
        assetOpen := false;
    end;
    FileCleanup;
{$if defined(VERIFY_FILE_ASSETS) or defined(VERIFY_FILE_IO_ERRORS)}
    Assign(report, 'FILE.ERR'); Rewrite(report);
    Writeln(report, assetPath, ': ', reason); Close(report);
{$endif}
    Writeln('Flob resource error: ', assetPath);
    Writeln(reason);
    Halt(1);
end;

procedure FileAssertBlack;
var i: byte;
    mask: word;
begin
    { Setscreen/Setpalette changes are latched by TOS at the next VBL. }
    VSync;
    if hasSteHardware then mask := $FFF else mask := $777;
    for i := 0 to 15 do
        if (PWord(pointer(PtrUInt($FF8240)))[i] and mask) <> 0 then
            AssetFailure('Disk read with visible palette');
end;

procedure ReadAssetBytes(dst: pointer; count: longint);
var got: longint;
    status: word;
begin
    FileAssertBlack;
    Inc(fileReads);
    {$I-} BlockRead(assetFile, PByte(dst)^, count, got); {$I+}
    status := IOResult;
    if (status <> 0) or (got <> count) then AssetFailure('Read failed or truncated file');
end;

function FileDarken(var saved: TFilePalette): boolean;
var i: byte;
    mask: word;
begin
    VSync;
    if hasSteHardware then mask := $FFF else mask := $777;
    Result := false;
    for i := 0 to 15 do begin
        saved[i] := PWord(pointer(PtrUInt($FF8240)))[i] and mask;
        if saved[i] <> 0 then Result := true;
    end;
    if Result then FadeToBlack(FADE_FRAMES);
end;

function FileCRC(data: PByte; count: longword): longword;
var crc: longword;
begin
    crc := $FFFFFFFF;
    while count <> 0 do begin
        crc := (crc shr 8) xor FILE_CRC_TABLE[byte(crc xor data^)];
        Inc(data);
        Dec(count);
    end;
    Result := crc xor $FFFFFFFF;
end;

procedure FileLoadGroup(g: word);
var header: packed record
        magic: array[0..3] of char;
        version, count: word;
        bytes, crc, storedBytes, storedCrc: longword;
    end;
    size: longint;
    i, status: word;
    savedMode: byte;
    stored: pointer;
    inFlight: longword;
begin
    if fileBlocks[g] <> nil then exit;
    assetPath := FILE_PATHS[g];
    FileAssertBlack;
    savedMode := FileMode;
    FileMode := 0;
    Assign(assetFile, assetPath);
    {$I-} Reset(assetFile, 1); {$I+}
    status := IOResult;
    FileMode := savedMode;
    if status <> 0 then AssetFailure('Cannot open file');
    assetOpen := true;
    {$I-} size := FileSize(assetFile); {$I+}
    status := IOResult;
    if (status <> 0) or (size <> FILE_STORED_SIZES[g] + SizeOf(header)) then AssetFailure('Wrong file size');
    ReadAssetBytes(@header, SizeOf(header));
    if (header.magic[0] <> 'F') or (header.magic[1] <> 'L') or
       (header.magic[2] <> 'B') or (header.magic[3] <> '2') or
       (header.version <> 2) or (header.count <> FILE_COUNTS[g]) or
       (header.bytes <> longword(FILE_SIZES[g])) or (header.crc <> FILE_CRCS[g]) or
       (header.storedBytes <> longword(FILE_STORED_SIZES[g])) or
       (header.storedCrc <> FILE_STORED_CRCS[g]) then
        AssetFailure('Wrong resource version; rebuild complete disk folder');
    fileBlocks[g] := gemdos_malloc(FILE_SIZES[g]);
    if (fileBlocks[g] = nil) or (PtrUInt(fileBlocks[g]) >= $FFFF0000) then begin
        fileBlocks[g] := nil;
        AssetFailure('Not enough RAM for resource group');
    end;
    Inc(fileBytes, FILE_SIZES[g]);
    if fileBytes > filePeak then filePeak := fileBytes;
    stored := fileBlocks[g];
    inFlight := fileBytes;
    if FILE_STORED_SIZES[g] < FILE_SIZES[g] then begin
        filePackedBlock := gemdos_malloc(FILE_STORED_SIZES[g]);
        if (filePackedBlock = nil) or (PtrUInt(filePackedBlock) >= $FFFF0000) then begin
            filePackedBlock := nil;
            AssetFailure('Not enough RAM for packed input');
        end;
        stored := filePackedBlock;
        Inc(inFlight, FILE_STORED_SIZES[g]);
    end;
    if inFlight > filePeakWithPacked then filePeakWithPacked := inFlight;
    ReadAssetBytes(stored, FILE_STORED_SIZES[g]);
    {$I-} Close(assetFile); {$I+}
    status := IOResult;
    assetOpen := false;
    if status <> 0 then AssetFailure('Close failed');
    { Validate before handing a stream to the unbounded 68000 decoder. }
    if FileCRC(stored, FILE_STORED_SIZES[g]) <> FILE_STORED_CRCS[g] then
        AssetFailure('Payload checksum mismatch');
    if filePackedBlock <> nil then begin
        UnApl(filePackedBlock, fileBlocks[g]);
        gemdos_mfree(filePackedBlock);
        filePackedBlock := nil;
        if FileCRC(fileBlocks[g], FILE_SIZES[g]) <> FILE_CRCS[g] then
            AssetFailure('Unpacked checksum mismatch');
    end;
    if FILE_LENGTH[g] > 0 then
        for i := FILE_FIRST[g] to FILE_FIRST[g] + FILE_LENGTH[g] - 1 do
            FILE_BINDINGS[i].slot^ := pointer(PtrUInt(fileBlocks[g]) + FILE_BINDINGS[i].offset);
    if g = FILE_COMMON_FONT then Move(PByte(fileBlocks[g])^, FlobFont, FILE_FONT_BYTES);
    FileRefreshLinks;
end;

procedure LoadFileAssets;
var g: word;
begin
    for g := 0 to FILE_GROUP_COUNT - 1 do
        if FILE_RESIDENT[g] then FileLoadGroup(g);
end;

procedure FileReleaseWorld;
var i: byte;
begin
    if fileWorld < 0 then exit;
    BlitterWait;
    FillChar(spriteSlots, SizeOf(spriteSlots), 0);
    FillChar(queuedSpriteCount, SizeOf(queuedSpriteCount), 0);
    FillChar(renderedSpriteCount, SizeOf(renderedSpriteCount), 0);
    FillChar(spriteFramesRaw, SizeOf(spriteFramesRaw), 0);
    FillChar(spriteColorsRaw, SizeOf(spriteColorsRaw), 0);
    ClearWorldSpriteAtlas;
    currentWorldData := nil;
    currentWorldAssets := nil;
    currentWorldAssetsSize := 0;
    currentWorldImgPtrs := nil;
    currentWorldPalPtrs := nil;
    currentWorldColAplPtrs := nil;
    currentWorldImgCount := 0;
    currentWorldTiles := nil;
    currentWorldTileWords := nil;
    currentWorldTileCollision := nil;
    currentWorldTileCount := 0;
    currentPal := @ALL_BLACK[0];
    currentBasePal := @ALL_BLACK[0];
    for i := 0 to 2 do FileFreeGroup(FILE_WORLD_GROUPS[fileWorld, i]);
    fileWorld := -1;
end;

procedure FileEnsureWorld(w: byte);
var i: byte;
    palette: TFilePalette;
    restore: boolean;
begin
    if fileWorld = w then exit;
    if w >= WORLD_COUNT then AssetFailure('Invalid world');
    restore := FileDarken(palette);
    FileReleaseWorld;
    for i := 0 to 2 do FileLoadGroup(FILE_WORLD_GROUPS[w, i]);
    fileWorld := w;
    if restore then begin
        FadeToPalette(@palette[0], FADE_FRAMES);
        VSync;
    end;
end;

procedure FileWorldInfo(w: byte);
var packedData: pointer;
begin
    packedData := nil;
    case w of
{ WORLD_INFO_CASES }
    end;
    if packedData = nil then AssetFailure('Invalid world info');
    UnApl(packedData, @fileInfoBuffer[0]);
    currentWorldData := @fileInfoBuffer[0];
    Move(fileInfoBuffer[0], world, SizeOf(TWorld));
    FixWorldEndian(world);
end;

function FileSceneGroup(bank: byte): word;
begin
    case bank of
        INTRO_BANK: Result := FILE_INTRO_GFX;
        OUTRO_BANK: Result := FILE_OUTRO_GFX;
        CREDITS_BANK: Result := FILE_CREDITS_GFX;
        else begin AssetFailure('Invalid scene bank'); Result := 0; end;
    end;
end;

procedure FileBeginScene(bank: byte);
begin
    FileAssertBlack;
    FileReleaseWorld;
    FileLoadGroup(FileSceneGroup(bank));
end;

procedure FileEndScene(bank: byte);
begin
    BlitterWait;
    currentPal := @ALL_BLACK[0];
    currentBasePal := @ALL_BLACK[0];
    FileFreeGroup(FileSceneGroup(bank));
    { PSG reads musicBuffer, not the compressed source. Outro can continue
      through credits after its packed music has been freed. }
    if (fileMusic >= 0) and not FILE_RESIDENT[fileMusic] then begin
        FileFreeGroup(fileMusic);
        fileMusic := -1;
    end;
end;

procedure FileEnsureMusic(song: byte);
var g: smallint;
    palette: TFilePalette;
    restore: boolean;
begin
    g := -1;
    case song of
        MUSIC_THEME: g := FILE_TITLE_MSX;
        MUSIC_INTRO: g := FILE_INTRO_MSX;
        MUSIC_OUTRO: g := FILE_OUTRO_MSX;
        MUSIC_ENDGAME: g := FILE_ENDING_MSX;
        MUSIC_LEVEL: if music_track <= 4 then g := FILE_WORLD_MUSIC[music_track];
    end;
    if g = fileMusic then exit;
    if (fileMusic >= 0) and not FILE_RESIDENT[fileMusic] then FileFreeGroup(fileMusic);
    fileMusic := g;
    if g < 0 then exit;
    if fileBlocks[g] <> nil then exit;
    restore := FileDarken(palette);
    FileLoadGroup(g);
    if restore then begin
        FadeToPalette(@palette[0], FADE_FRAMES);
        VSync;
    end;
end;

procedure VerifyFileResources;
{$ifdef VERIFY_FILE_ASSETS}
var g, w, pass: word;
    baseline, freeRam: longint;
    report: text;
begin
    baseline := PtrUInt(gemdos_malloc($FFFFFFFF));
    for pass := 0 to 1 do begin
        for g := 0 to FILE_GROUP_COUNT-1 do begin
            FileLoadGroup(g);
            if not FILE_RESIDENT[g] then FileFreeGroup(g);
        end;
        for w := 0 to WORLD_COUNT-1 do begin
            FileEnsureWorld(w);
            LoadWorld(w);
            FileWorldInfo(w);
            FileReleaseWorld;
        end;
        freeRam := PtrUInt(gemdos_malloc($FFFFFFFF));
        if freeRam <> baseline then AssetFailure('Resource lifetime leak');
    end;
    Assign(report, 'LOAD.OK'); Rewrite(report);
    Writeln(report, 'PASS CRC32 all bundles, two lifetime cycles, black palette for every read');
    Writeln(report, 'resident bytes=', fileBytes, ' peak resource bytes=', filePeak);
    Writeln(report, 'largest free after resident=', baseline, ' reads=', fileReads);
    Close(report);
    FileCleanup;
    Halt;
end;
{$else}
begin
end;
{$endif}
