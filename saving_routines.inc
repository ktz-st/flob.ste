// Save/load using gemdos file I/O instead of flash cartridge sectors.

const
    SAVE_FILENAME = 'flob.sav';

var
    worldStats: TWorldStats;
    achievements: array [0..ACHIEVEMENTS_MAX] of byte;
    gameRuns: word;
    lastSave: byte;

procedure SetWorldStats(worldNum: byte);
var addr: word;
begin
    addr := worldNum * WORLD_STATS_SIZE;
    Move(worldStats, saveBuffer[addr], SizeOf(TWorldStats));
end;

procedure ClearWorldStats;
var worldNum: byte;
begin
    FillChar(worldStats, SizeOf(TWorldStats), 0);
    worldStats.minDeaths := $ffff;
    worldStats.bestTime  := $ffff;
    for worldNum := 0 to WORLD_COUNT - 1 do SetWorldStats(worldNum);
end;

procedure GetWorldStats(worldNum: byte);
var addr: word;
begin
    addr := worldNum * WORLD_STATS_SIZE;
    Move(saveBuffer[addr], worldStats, SizeOf(TWorldStats));
end;

procedure InitGameStats;
begin
    FillChar(saveBuffer, SizeOf(saveBuffer), 0);
    ClearWorldStats;
    FillChar(achievements, SizeOf(achievements), 0);
    gameRuns := 0;
    lastSave := 0;
end;

procedure StoreStats;
var handle: longint;
    i: word;
begin
    // pack achievements and gameRuns at end of saveBuffer
    Move(achievements[0], saveBuffer[WORLD_COUNT * WORLD_STATS_SIZE], ACHIEVEMENTS_COUNT);
    Move(gameRuns, saveBuffer[WORLD_COUNT * WORLD_STATS_SIZE + ACHIEVEMENTS_COUNT], 2);
    handle := gemdos_fcreate(SAVE_FILENAME, 0);
    if handle > 0 then begin
        gemdos_fwrite(handle, SAVE_SIZE, @saveBuffer[0]);
        gemdos_fclose(handle);
    end;
end;

procedure RestoreWorldStats;
var handle: longint;
begin
    handle := gemdos_fopen(SAVE_FILENAME, 0);
    if handle > 0 then begin
        gemdos_fread(handle, SAVE_SIZE, @saveBuffer[0]);
        gemdos_fclose(handle);
        Move(saveBuffer[WORLD_COUNT * WORLD_STATS_SIZE], achievements[0], ACHIEVEMENTS_COUNT);
        Move(saveBuffer[WORLD_COUNT * WORLD_STATS_SIZE + ACHIEVEMENTS_COUNT], gameRuns, 2);
    end else begin
        InitGameStats;
    end;
    Inc(gameRuns);
    StoreStats;
end;
