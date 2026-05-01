{$APPTYPE GUI}
{$mode objfpc}

program FloB;
uses xbios, gemdos, bios;

const
{$i const.inc}
{$i vnumber.inc}
    DEBUG_LOADLEVEL = false;
    DEBUG_DRAWLEVEL = false;
    DEBUG_TILE_PLACEHOLDER = false;
    DEBUG_TILE_HUD = false;
    DEBUG_TILE_FORCE_VISIBLE = false;
    USE_TILE_BLITTER = true;
    DEBUG_TEST_BIGSLIME = false;
    USE_DEBUG_FORCE_LEVEL = false;
    DEBUG_FORCE_WORLD = 0;
    DEBUG_FORCE_LEVEL = 4;
    LEVEL_SCALE_X = 2;
    LEVEL_SCALE_Y = 2;
    LEVEL_OFFSET_Y = 16;
    BG_IMAGE_OFFSET_Y = 20;
    PLAYFIELD_HEIGHT = 160;
    SPAWN_Y_ADJUST = 10;
    GROUND_COLLISION_COLOR = 2;
    FLOB_RENDER_OFFSET_Y = 2;
    WORLD_SPRITE_OFFSET_X = -2;
    WORLD_SPRITE_OFFSET_Y = 4;
    WORLD_SPRITE_MOVE_STEP = 2;
    FLOB_MOVE_STEP = 2;
    FLOB_FALL_STEP = 2;
    HUD_HEIGHT = 8;
    MESSAGE_TEXT_COLOR = 15;
    SLIME_RENDER_OFFSET_X = -PMG_X_OFFSET * LEVEL_SCALE_X;
    SLIME_RENDER_OFFSET_Y = 12;
    STE_PAL: array[0..255] of word = (
        $000,$888,$111,$999,$222,$AAA,$333,$BBB,$444,$CCC,$555,$DDD,$666,$EEE,$777,$FFF,
        $800,$180,$910,$290,$A20,$3A0,$B30,$4B8,$C41,$DC9,$D52,$6DA,$E63,$FEB,$F74,$FFC,
        $900,$200,$A80,$310,$B90,$420,$CA8,$531,$DB9,$642,$ECA,$753,$FDB,$F64,$FEC,$F75,
        $200,$A00,$300,$B80,$418,$C91,$529,$DA2,$63A,$EB3,$74B,$FC4,$F5C,$FD5,$F66,$FEE,
        $200,$A08,$301,$B89,$412,$C9A,$523,$DAB,$634,$EBC,$745,$FCD,$F56,$FDE,$F67,$FE7,
        $909,$202,$A02,$38A,$B13,$49B,$C24,$5AC,$D35,$6BD,$E46,$7CE,$F5E,$FD7,$F67,$FE7,
        $10A,$903,$20B,$A84,$31C,$B95,$42D,$CA6,$53E,$DB7,$647,$EC7,$757,$FD7,$F67,$FEF,
        $00B,$80B,$184,$91C,$295,$A2D,$3A6,$B3E,$4B7,$C4F,$5CF,$D5F,$6DF,$E6F,$7EF,$F7F,
        $003,$08B,$014,$89C,$125,$9AD,$236,$ABE,$347,$BCF,$45F,$CDF,$56F,$DEF,$67F,$EFF,
        $08A,$013,$09B,$024,$8AC,$135,$9BD,$246,$ACE,$357,$BDF,$46F,$CEF,$57F,$DFF,$6FF,
        $011,$092,$02A,$0A3,$03B,$8B4,$14C,$9C5,$25D,$AD6,$36E,$BE7,$47F,$CFF,$5FF,$DFF,
        $018,$098,$021,$0A9,$03A,$8B3,$14B,$9C4,$25C,$AD5,$36D,$BE6,$47E,$CFE,$5F7,$DFF,
        $018,$098,$028,$0A1,$831,$1B9,$942,$2CA,$A53,$3DB,$B64,$4EC,$C75,$5FD,$DFD,$6F6,
        $018,$098,$028,$8A8,$138,$9B8,$248,$AC1,$359,$BD2,$46A,$CE3,$57B,$DF4,$6FC,$EF5,
        $080,$810,$190,$920,$2A0,$A30,$3B0,$B48,$4C1,$C59,$5D2,$D6A,$6E3,$E7B,$7F4,$FF4,
        $100,$980,$210,$A90,$320,$B30,$4B0,$C48,$5C1,$5C9,$6D2,$E6A,$7E3,$7EB,$FF4,$FFC
    );
    MAIN_TITLE_COLORS: array[0..6] of byte = ($00,$3F,$34,$38,$98,$32,$94);
    SELECTOR_COLORS: array[0..9] of byte = ($00,$38,$3C,$34,$84,$78,$0F,$98,$1A,$26);

    DEBUG_HEX_FONT: array[0..15, 0..4] of byte = (
        (7, 5, 5, 5, 7), // 0
        (2, 6, 2, 2, 7), // 1
        (7, 1, 7, 4, 7), // 2
        (7, 1, 7, 1, 7), // 3
        (5, 5, 7, 1, 1), // 4
        (7, 4, 7, 1, 7), // 5
        (7, 4, 7, 5, 7), // 6
        (7, 1, 1, 1, 1), // 7
        (7, 5, 7, 5, 7), // 8
        (7, 5, 7, 1, 7), // 9
        (7, 5, 7, 5, 5), // A
        (6, 5, 6, 5, 6), // B
        (7, 4, 4, 4, 7), // C
        (6, 5, 5, 5, 6), // D
        (7, 4, 7, 4, 7), // E
        (7, 4, 7, 4, 4)  // F
    );

    FLOB_FRAME_P0: array[0..15, 0..7] of byte = (
        ($00,$00,$04,$2A,$00,$00,$42,$00),
        ($00,$00,$20,$54,$00,$00,$42,$00),
        ($00,$00,$04,$2A,$28,$00,$42,$00),
        ($00,$00,$20,$54,$14,$00,$42,$00),
        ($38,$6C,$44,$00,$28,$00,$44,$00),
        ($1C,$36,$22,$00,$14,$00,$22,$00),
        ($00,$00,$00,$7E,$83,$C5,$00,$00),
        ($00,$00,$00,$7E,$C1,$A3,$00,$00),
        ($00,$00,$0C,$02,$51,$01,$81,$7E),
        ($00,$00,$30,$40,$8A,$80,$81,$7E),
        ($00,$3C,$42,$66,$42,$42,$66,$00),
        ($00,$3C,$42,$66,$42,$42,$66,$00),
        ($3C,$42,$E7,$A5,$DB,$A5,$5A,$00),
        ($3C,$42,$E7,$A5,$DB,$A5,$5A,$00),
        ($10,$82,$20,$08,$81,$10,$44,$00),
        ($10,$82,$20,$08,$81,$10,$44,$00)
    );

    FLOB_FRAME_P1: array[0..15, 0..7] of byte = (
        ($00,$00,$38,$7C,$56,$7E,$3C,$00),
        ($00,$00,$1C,$3E,$6A,$7E,$3C,$00),
        ($00,$00,$38,$7C,$7E,$7E,$3C,$00),
        ($00,$00,$1C,$3E,$7E,$7E,$3C,$00),
        ($00,$10,$38,$7C,$7C,$54,$38,$00),
        ($00,$08,$1C,$3E,$3E,$2A,$1C,$00),
        ($00,$00,$00,$00,$7C,$56,$FF,$00),
        ($00,$00,$00,$00,$3E,$6A,$FF,$00),
        ($00,$00,$70,$FC,$FE,$AE,$7E,$00),
        ($00,$00,$0E,$3F,$7F,$75,$7E,$00),
        ($00,$00,$3C,$7E,$5A,$3C,$18,$00),
        ($00,$00,$3C,$7E,$5A,$3C,$18,$00),
        ($00,$3C,$5A,$BD,$66,$42,$24,$00),
        ($00,$3C,$5A,$BD,$66,$42,$24,$00),
        ($22,$08,$81,$10,$04,$41,$08,$00),
        ($22,$08,$81,$10,$04,$41,$08,$00)
    );

// *** STE screen constants ***
    SCREEN_LINE_BYTES = 160;
    SCREEN_BYTES      = 32000;
    SCREEN_ALIGN      = 256;
    SCREEN_ALLOC      = SCREEN_BYTES + SCREEN_ALIGN;

{$i types.inc}        // starts with: type
{$i bank_0_files.inc} // starts with: type ... var
{$i assets/sprites.inc} // starts with: var
{$i interrupts.inc}   // procedure stubs, no section headers needed
{$i worlds/worlds.inc} // all world + asset const byte arrays
{$i worlds/world_tiles.inc} // generated STE tile data
{$i images/images.inc} // per-world room backgrounds + global screens (aplib compressed)
{$i generated/sprite_assets_atlas.inc} // generated unified atlas -> masked sprite data
{$i generated/sprite_atlas_palette.inc}

{$L unapl.o}
{$L font.o}
procedure UnApl(src, dst: pointer); external;
procedure DrawChar(screen, font: pointer; x, y, ch, fg, bg: longword); cdecl; external;
var FlobFont: byte; external name 'FlobFont';

procedure ClearScreen(buf: pword); forward;
procedure SwapScreen; forward;
procedure DrawStr(x, y, fg: word; const str: string); forward;
procedure DrawStrCentered(y, fg: word; const str: string); forward;
procedure DrawTextTo(scr: pword; x, y, fg, bg: word; const str: string); forward;
procedure DrawHudTo(scr: pword); forward;
procedure RefreshHudCache; forward;
procedure CopyHudArea(src, dst: pword); forward;
procedure DrawMessageTo(scr: pword); forward;
procedure DrawSlimesTo(scr: pword); forward;
procedure RefreshOverlayBuffers; forward;
procedure BlitterCopyData16(src, dst: pointer; size: longword); forward;
procedure BuildDisplayPalette(dst: PWord); forward;
procedure UpdateDisplayPaletteIfNeeded(force: boolean); forward;
procedure FillRect16(scr: pword; x, y, cellw, cellh, color: word); forward;
procedure PutPixel4(scr: pword; x, y: word; color: byte); forward;
procedure Collided(pnum: byte); forward;

type
    TQueuedSprite = record
        x: word;
        y: word;
        widthPx: word;
        heightPx: word;
        frame: PSteSpriteFrame;
        wordsBase: PWord;
        palBase: PWord;
        palSlot: byte;
    end;

var
// --- ST screen management ---
    SCREEN_LOG, SCREEN_PHY: pword;
    SCREEN_LOG_RAW, SCREEN_PHY_RAW: pword;
    SCREEN_BKG: pword;
    SCREEN_BKG_RAW: pword;
    oldScreen: pword;
    oldPalette: array[0..15] of word;
    oldRez: word;
    screenLogIndex: byte;
    screenPhyIndex: byte;
    displayFlipped: boolean;

// --- save buffer (used by saving_routines.inc) ---
    saveBuffer: array[0..SAVE_SIZE-1] of byte;

// --- game timing ---
    sysframe: byte;

// --- game variables ---
    gametime: cardinal;
    s, s1: string[40];
    s2: string[1];
    b, joy: byte;
    world: TWorld;
    level: TLevel;
    image: TImage;
    sprites: TSprites;
    spriteData: TSpriteData;
    spritePtr: array[0..1] of word;
    spriteFrame: array[0..1] of byte;
    spriteTargetFrame: array[0..1] of byte;
    spriteStep: array[0..1] of byte;
    spriteAnimation0: TAnimationStep;
    spriteAnimation1: TAnimationStep;
    spriteAnimations: array[0..1] of pointer;
    leveldata: TLevelDataArray;

    actionDelay: byte;
    sfxDelay: byte;
    levelColors: array[0..3] of byte;
    levelRawColors: array[0..3] of byte;
    revealColors: array[0..3] of byte;
    pmgColors: array[0..3] of byte;
    topBarForeground: byte;

    flobX, flobY, flobFoot, flobFace, flobDir, flobFrame, flobFalling: byte;
    flobFrameDelay: byte;


    isStereo: boolean;

    flipped: boolean;
    colorCollision, mainGoalReached, room_changed, game_over,
    room_landed, first_landed, exploded, teleported: boolean;
    landedTime: byte;
    cheatmode, statsOn: boolean;

    levelNum: byte;
    lastLanded: TLastLanded;
    lastSafeLanded: TLastLanded;
    doorReveal: array[0..1] of byte;

    // hardware register stubs (no absolute address on STE)
    stick0: byte;
    strig0: byte;
    skstat: byte;
    kbcode: byte;
    invulnerability: byte;

    slimeX: array[0..19] of byte;
    slimeGoal: array[0..19] of byte;
    dxslime0, dxslime1, dlrow: byte;
    scoreadd: word;
    mySlime: cardinal;
    pickedSlimeCount: byte;
    secretsFound: byte;
    deadCount: word;

    worldsBanks: array[0..WORLD_COUNT-1] of byte = (8, 16, 24, 32, 40, 48);
    worldCurrent: byte;
    currentWorldData: PByte;
    currentWorldImgPtrs: ^pointer;
    currentWorldPalPtrs: ^pointer;
    currentWorldColPtrs: ^pointer;
    currentWorldImgCount: byte;
    currentWorldAssets: PByte;
    currentWorldAssetsSize: word;
    currentWorldTiles: PSteTile;
    currentWorldTileWords: PWord;
    currentWorldTileCount: word;
    spriteColorsRaw: array[0..1] of PByte;
    spriteFramesRaw: array[0..1, 0..15] of PByte;
    spriteBgValid: array[0..1] of boolean;
    spriteBgX: array[0..1] of word;
    spriteBgY: array[0..1] of word;
    spriteBgW: array[0..1] of word;
    spriteBgH: array[0..1] of word;
    spriteBgPixels: array[0..1, 0..8191] of byte;
    queuedSprites: array[0..1, 0..31] of TQueuedSprite;
    queuedSpriteCount: array[0..1] of byte;

    roomTriggers: array[0..3, 0..9] of byte;
    triggerCount: byte;
    msgDisplayCounter: byte;
    msgDisplayType: byte;
    messages: array[0..3] of word;
    messageTypes: array[0..3] of byte;
    currentMessageLines: array[0..1] of string;
    sceneImg: array[0..1] of byte;
    sceneMsg: array[0..1] of word;
    sceneCol0, sceneCol1, sceneCol2: array[0..1] of byte;
    msgCount: byte;
    sceneCount: byte;

    music_on: byte;
    lastSfxCh: byte;
    music_ingame: boolean;
    music_track: byte;
    escPressed: byte;

    globalStats: TGlobalStats;
    achievement: TAchievement;
    newAchivements: byte;
    achivementsCount: byte;
    statCount, statPage: byte;
    goals:    array[0..GOALS_MAX] of byte;
    triggers: array[0..TRIGGERS_MAX] of byte;
    slimes:   array[0..SLIMES_MAX] of byte;

    statBestsBack: byte;
    statGlobalBack: byte;

    PMG_p0pl, PMG_p1pl: byte;
    PMG_hposm0, PMG_hposm1: byte;
    PMG_sizep0, PMG_sizep1: byte;
    PMG_hpos: array[0..3] of byte;
    PMG_sizep: array[0..3] of byte;
    PMG_hitclr: byte;

    colbk: byte;
    currentPal: pointer;  // target palette for FadeIn, set by LoadImage/LoadCutsceneSlide
    currentBasePal: pointer;
    roomSpritePaletteActive: boolean;
    currentCollisionData: PByte;
    roomPalette: array[0..15] of word;
    titlePalette: array[0..15] of word;
    spriteTestPal: array[0..15] of word;
    displayPaletteDirty: boolean;
    lastPaletteFlobFrame: shortint;
    lastPaletteSlimeFrame: shortint;
    lastPaletteMsgSource: shortint;


    vramLineOffset: array[0..99] of word; // unused on STE, kept for compatibility

// *** Forward declarations (same as original) ***
procedure ReadInput; forward;
procedure InstallInput; forward;
procedure UnInstallInput; forward;
procedure LoadLevel(lvl: byte); forward;
procedure CheckAchievements; forward;
procedure EndWorld; forward;
procedure ShowAchievements; forward;
procedure PutTile(x, y: byte; src: word; flip: byte); forward;
procedure BackToLevel; forward;
procedure ShowCutScene(csbank, cscount: byte); forward;
procedure ShowCredits; forward;
procedure LoadWorld(w: byte); forward;
procedure Teleport(lvl, x, y: byte); forward;
procedure SpriteTeleport(pnum: byte); forward;
procedure RevealCountdown(pnum: byte); forward;
procedure ShowStats; forward;
procedure SetLevelColors; forward;
procedure ShowScene(scene: byte); forward;
procedure SetLanded; forward;
procedure SetLandingSafe; forward;

// ***************************************************
// *** COMPATIBILITY LAYER (replaces 8-bit builtins)
// ***************************************************

function peek(addr: word): byte; inline;
begin
    Result := 0; // stub – 8-bit VRAM/hardware access
end;

procedure poke(addr: word; val: byte); inline;
begin
    // stub
end;

procedure dpoke(addr: word; val: word); inline;
begin
    // stub
end;

procedure WaitFrame;
begin
    ReadInput;
    xbios_vsync;
    Inc(sysframe);
end;

procedure WaitFrames(count: word);
var i: word;
begin
    for i := 0 to count - 1 do WaitFrame;
end;

function Atascii2Antic(const s: string): string;
begin
    Result := s; // stub – character conversion not needed on STE
end;

function Antic2Ascii(const Data: AnsiString): AnsiString;
const
  AnticToAscii: array[0..63] of Char = (
    ' ', '!', '"', '#', '$', '%', '&', '''',
    '(', ')', '*', '+', ',', '-', '.', '/',
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', ':', ';', '<', '=', '>', '?',
    '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
    'X', 'Y', 'Z', '[', '\', ']', '^', '_'
  );
var
  I: Integer;
  Code: Byte;
begin
  SetLength(Result, Length(Data));

  for I := 1 to Length(Data) do
  begin
    Code := Ord(Data[I]);

    if Code = 0 then
      Result[I] := ' '
    else if Code < 64 then
      Result[I] := AnticToAscii[Code]
    else
      Result[I] := Data[I]; // zostaw bez zmian
  end;
end;

function HexDigit(v: byte): char;
begin
    v := v and $0F;
    if v < 10 then Result := char(ord('0') + v)
    else Result := char(ord('A') + v - 10);
end;

function HexByte(v: byte): string;
begin
    Result := '$';
    Result := Result + HexDigit(v shr 4);
    Result := Result + HexDigit(v);
end;

function HexWord(v: word): string;
begin
    Result := '$';
    Result := Result + HexDigit(byte(v shr 12));
    Result := Result + HexDigit(byte(v shr 8));
    Result := Result + HexDigit(byte(v shr 4));
    Result := Result + HexDigit(byte(v));
end;

function ByteToStr(v: byte): string;
begin
    Str(v, Result);
end;

function WordToStr(v: word): string;
begin
    Str(v, Result);
end;

function SwapWord(v: word): word;
begin
    Result := (v shr 8) or (v shl 8);
end;

procedure FixWorldEndian(var w: TWorld);
var i: byte;
begin
    w.startingSlime := SwapWord(w.startingSlime);
    w.timeTreshold := SwapWord(w.timeTreshold);
    w.scoreTreshold := SwapWord(w.scoreTreshold);
    w.iconPtr := SwapWord(w.iconPtr);
    w.rmtPtr := SwapWord(w.rmtPtr);
    for i := 0 to High(w.lvlPtr) do
        w.lvlPtr[i] := SwapWord(w.lvlPtr[i]);
end;

procedure DebugShowOverlay(const title, line1, line2, line3, line4: string);
begin
    ClearScreen(SCREEN_LOG);
    DrawStr(8, 8, 15, title);
    DrawStr(8, 32, 15, line1);
    DrawStr(8, 48, 15, line2);
    DrawStr(8, 64, 15, line3);
    DrawStr(8, 80, 15, line4);
    SwapScreen;
end;

procedure DrawDebugHexDigit(scr: pword; x, y: word; digit: byte; fg, bg: word);
var row, col: byte;
begin
    for row := 0 to 4 do
        for col := 0 to 2 do
            if (DEBUG_HEX_FONT[digit and $0F][row] and (1 shl (2 - col))) <> 0 then
                FillRect16(scr, x + word(col) * 16, y + word(row) * 4, 16, 4, fg)
            else if bg <> fg then
                FillRect16(scr, x + word(col) * 16, y + word(row) * 4, 16, 4, bg);
end;

procedure DrawDebugHexWord(scr: pword; x, y, fg, bg, v: word);
begin
    DrawDebugHexDigit(scr, x + 0,   y, byte(v shr 12), fg, bg);
    DrawDebugHexDigit(scr, x + 64,  y, byte(v shr 8),  fg, bg);
    DrawDebugHexDigit(scr, x + 128, y, byte(v shr 4),  fg, bg);
    DrawDebugHexDigit(scr, x + 192, y, byte(v),        fg, bg);
end;

procedure DrawDebugRect(scr: pword; x, y, w, h: word; color: byte);
var i: word;
begin
    if (w = 0) or (h = 0) then exit;

    for i := 0 to w - 1 do begin
        PutPixel4(scr, x + i, y, color);
        PutPixel4(scr, x + i, y + h - 1, color);
    end;

    for i := 0 to h - 1 do begin
        PutPixel4(scr, x, y + i, color);
        PutPixel4(scr, x + w - 1, y + i, color);
    end;
end;

procedure DrawTileLookupDebug(src: word; found: boolean);
var line: string;
    firstAddr: word;
begin
    FillRect16(SCREEN_LOG, 0, 0, 320, 40, 0);

    if currentWorldTiles <> nil then
        firstAddr := currentWorldTiles^.sourceAddr
    else
        firstAddr := 0;

    line := 'src=' + HexWord(src) + ' cnt=' + WordToStr(currentWorldTileCount) +
        ' first=' + HexWord(firstAddr);
    if found then
        line := line + ' HIT'
    else
        line := line + ' MISS';
    DrawStr(8, 8, 1, line);
end;

// ***************************************************
// *** SCREEN / PALETTE INIT (like fuji-tetris)
// ***************************************************

procedure AlignScreenBuffer(rawScreen: pword; var screen: pword);
var addr: longint;
begin
    addr := longint(rawScreen);
    addr := (addr + 255) and (not 255);
    screen := pword(addr);
end;

procedure ClearScreen(buf: pword);
begin
    FillChar(buf^, SCREEN_BYTES, 0);
end;

procedure ScreenInit;
begin
    oldRez := xbios_getrez;
    // TODO: save palette – needs external SavePalette from screen.s
    FillChar(oldPalette, SizeOf(oldPalette), 0);
    oldScreen := xbios_logbase;
    SCREEN_LOG_RAW := gemdos_malloc(SCREEN_ALLOC);
    SCREEN_PHY_RAW := gemdos_malloc(SCREEN_ALLOC);
    SCREEN_BKG_RAW := gemdos_malloc(SCREEN_ALLOC);
    AlignScreenBuffer(SCREEN_LOG_RAW, SCREEN_LOG);
    AlignScreenBuffer(SCREEN_PHY_RAW, SCREEN_PHY);
    AlignScreenBuffer(SCREEN_BKG_RAW, SCREEN_BKG);
    ClearScreen(SCREEN_LOG);
    ClearScreen(SCREEN_PHY);
    ClearScreen(SCREEN_BKG);
    screenLogIndex := 0;
    screenPhyIndex := 1;
    displayFlipped := false;
    displayPaletteDirty := true;
    lastPaletteFlobFrame := -1;
    lastPaletteSlimeFrame := -1;
    lastPaletteMsgSource := -1;
    FillChar(queuedSpriteCount, SizeOf(queuedSpriteCount), 0);
    xbios_setscreen(SCREEN_LOG, SCREEN_PHY, 0); // ST Low: 320x200x16
end;

procedure ScreenDone;
begin
    xbios_setscreen(oldScreen, oldScreen, oldRez);
    xbios_setpalette(@oldPalette[0]);
    gemdos_mfree(SCREEN_LOG_RAW);
    gemdos_mfree(SCREEN_PHY_RAW);
    gemdos_mfree(SCREEN_BKG_RAW);
    gemdos_super(pointer(1));
end;

procedure SwapScreen;
var tmp: pword;
    tmpIndex: byte;
begin
    xbios_vsync;
    tmp := SCREEN_LOG;
    SCREEN_LOG := SCREEN_PHY;
    SCREEN_PHY := tmp;
    tmpIndex := screenLogIndex;
    screenLogIndex := screenPhyIndex;
    screenPhyIndex := tmpIndex;
    xbios_setscreen(SCREEN_LOG, SCREEN_PHY, -1);
end;

// ***************************************************
// *** GRAPHICS STUBS (display routines to implement)
// ***************************************************


procedure PMG_Init(base: word); begin end;
procedure PMG_Clear; begin end;

procedure EnableVBLI(proc: pointer); begin end;
procedure EnableDLI(proc: pointer);  begin end;

procedure InitScreen(dladdr: word; dliptr: pointer); begin end;
procedure FlipGameplayAreaInPlace(buf: pword);
var yTop, yBottom: word;
    topPtr, bottomPtr: PByte;
    tmp: array[0..SCREEN_LINE_BYTES-1] of byte;
begin
    if buf = nil then exit;
    yTop := BG_IMAGE_OFFSET_Y;
    yBottom := BG_IMAGE_OFFSET_Y + PLAYFIELD_HEIGHT - 1;
    while yTop < yBottom do begin
        topPtr := PByte(longint(buf) + longint(yTop) * SCREEN_LINE_BYTES);
        bottomPtr := PByte(longint(buf) + longint(yBottom) * SCREEN_LINE_BYTES);
        Move(topPtr^, tmp[0], SCREEN_LINE_BYTES);
        Move(bottomPtr^, topPtr^, SCREEN_LINE_BYTES);
        Move(tmp[0], bottomPtr^, SCREEN_LINE_BYTES);
        Inc(yTop);
        Dec(yBottom);
    end;
end;

procedure CopyPlayfieldArea(src, dst: pword);
var srcPtr, dstPtr: PByte;
begin
    if (src = nil) or (dst = nil) then exit;
    srcPtr := PByte(longint(src) + longint(BG_IMAGE_OFFSET_Y) * SCREEN_LINE_BYTES);
    dstPtr := PByte(longint(dst) + longint(BG_IMAGE_OFFSET_Y) * SCREEN_LINE_BYTES);
    BlitterCopyData16(srcPtr, dstPtr, longword(PLAYFIELD_HEIGHT) * SCREEN_LINE_BYTES);
end;

procedure CopyHudArea(src, dst: pword);
begin
    if (src = nil) or (dst = nil) then exit;
    BlitterCopyData16(src, dst, 20 * SCREEN_LINE_BYTES);
end;

procedure RebuildDisplayBuffersFromBackground;
begin
    if SCREEN_BKG = nil then exit;
    CopyPlayfieldArea(SCREEN_BKG, SCREEN_LOG);
    CopyPlayfieldArea(SCREEN_BKG, SCREEN_PHY);
    CopyHudArea(SCREEN_BKG, SCREEN_LOG);
    CopyHudArea(SCREEN_BKG, SCREEN_PHY);
    FillChar(queuedSpriteCount, SizeOf(queuedSpriteCount), 0);
end;

procedure EnsureDisplayOrientation(wantFlipped: boolean);
begin
    if displayFlipped <> wantFlipped then begin
        FlipGameplayAreaInPlace(SCREEN_BKG);
        RebuildDisplayBuffersFromBackground;
        displayFlipped := wantFlipped;
    end;
    RefreshOverlayBuffers;
end;

procedure OrderDlist;
begin
    EnsureDisplayOrientation(false);
end;

procedure ReverseDlist;
begin
    EnsureDisplayOrientation(true);
end;

procedure ClearVram; begin end;
procedure ClearTxt1; begin end;
procedure ClearTxt2;
begin
    currentMessageLines[0] := '';
    currentMessageLines[1] := '';
end;

procedure HRLine1(y: byte); begin end;

procedure PutChar(c: char; dest: word; color: byte); begin end;

procedure PutString(var s: string; dest: word; color: byte); begin end;

procedure PutCString(var s: string; dest: word; color: byte; w: byte); begin end;

const
    BLITTER_BASE = $FFFF8A00;
    BLITTER_SRC_INC_X = $20;
    BLITTER_SRC_INC_Y = $22;
    BLITTER_SRC_ADDR = $24;
    BLITTER_ENDMASK1 = $28;
    BLITTER_ENDMASK2 = $2A;
    BLITTER_ENDMASK3 = $2C;
    BLITTER_DST_INC_X = $2E;
    BLITTER_DST_INC_Y = $30;
    BLITTER_DST_ADDR = $32;
    BLITTER_COUNT_X = $36;
    BLITTER_COUNT_Y = $38;
    BLITTER_HOP = $3A;
    BLITTER_LOP = $3B;
    BLITTER_MODE = $3C;
    BLITTER_SKEW = $3D;
    BLITTER_HOP_SRC = 2;
    BLITTER_LOP_SRC = 3;
    BLITTER_LOP_SRC_AND_DST = 1;
    BLITTER_LOP_SRC_OR_DST = 7;
    BLITTER_MODE_BUSY = $80;
    BLITTER_SKEW_NFSR = $40;
    BLITTER_START_MASKS: array[0..15] of word = (
        $FFFF, $7FFF, $3FFF, $1FFF, $0FFF, $07FF, $03FF, $01FF,
        $00FF, $007F, $003F, $001F, $000F, $0007, $0003, $0001
    );
    BLITTER_END_MASKS: array[0..15] of word = (
        $8000, $C000, $E000, $F000, $F800, $FC00, $FE00, $FF00,
        $FF80, $FFC0, $FFE0, $FFF0, $FFF8, $FFFC, $FFFE, $FFFF
    );

procedure BlitterWait; inline;
begin
    while (PByte(pointer(longword(BLITTER_BASE + BLITTER_MODE)))^ and BLITTER_MODE_BUSY) <> 0 do ;
end;

procedure BlitterWriteWord(offset, value: word); inline;
begin
    PWord(pointer(longword(BLITTER_BASE + offset)))^ := value;
end;

procedure BlitterWriteByte(offset: word; value: byte); inline;
begin
    PByte(pointer(longword(BLITTER_BASE + offset)))^ := value;
end;

procedure BlitterWritePtr(offset: word; p: pointer); inline;
begin
    PLongWord(pointer(longword(BLITTER_BASE + offset)))^ := longword(p);
end;

procedure BlitterCopyData16(src, dst: pointer; size: longword);
begin
    if (src = nil) or (dst = nil) or (size = 0) then exit;
    if (size and 15) <> 0 then begin
        Move(src^, dst^, size);
        exit;
    end;

    BlitterWait;
    BlitterWriteByte(BLITTER_SKEW, 0);
    BlitterWriteWord(BLITTER_SRC_INC_X, 2);
    BlitterWriteWord(BLITTER_SRC_INC_Y, 2);
    BlitterWritePtr(BLITTER_SRC_ADDR, src);
    BlitterWriteWord(BLITTER_ENDMASK1, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK2, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK3, $FFFF);
    BlitterWriteWord(BLITTER_DST_INC_X, 2);
    BlitterWriteWord(BLITTER_DST_INC_Y, 2);
    BlitterWritePtr(BLITTER_DST_ADDR, dst);
    BlitterWriteWord(BLITTER_COUNT_X, 8);
    BlitterWriteWord(BLITTER_COUNT_Y, size shr 4);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC);
    BlitterWriteByte(BLITTER_MODE, $C0);
    BlitterWait;
end;

procedure BlitterClearBitmap4(dst: pointer; width, height, dstX, dstY, dstWidth: word);
var lineAdvanceBytes: word;
    dstAddr: pointer;
begin
    if (dst = nil) or (width = 0) or (height = 0) then exit;
    if (dstX >= dstWidth) or (dstY >= 200) then exit;
    width := width and $FFF0;
    dstX := dstX and $FFF0;
    if width = 0 then exit;
    if (dstX + width) > dstWidth then
        width := (dstWidth - dstX) and $FFF0;
    if width = 0 then exit;
    if (dstY + height) > 200 then
        height := 200 - dstY;
    if height = 0 then exit;

    lineAdvanceBytes := ((dstWidth - width) shr 1) + 2;
    dstAddr := pointer(longint(dst) + ((longint(dstY) * dstWidth + dstX) shr 1));

    BlitterWait;
    BlitterWriteByte(BLITTER_SKEW, 0);
    BlitterWriteWord(BLITTER_ENDMASK1, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK2, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK3, $FFFF);
    BlitterWriteWord(BLITTER_DST_INC_X, 2);
    BlitterWriteWord(BLITTER_DST_INC_Y, lineAdvanceBytes);
    BlitterWritePtr(BLITTER_DST_ADDR, dstAddr);
    BlitterWriteWord(BLITTER_COUNT_X, width shr 2);
    BlitterWriteWord(BLITTER_COUNT_Y, height);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_LOP, 0);
    BlitterWriteByte(BLITTER_MODE, $C0);
    BlitterWait;
end;

procedure ApplySpritePaletteSlots(startSlot: byte; palData: PWord; palCount: byte);
var i: byte;
begin
    if palCount = 0 then begin
        exit;
    end;
    for i := 0 to palCount - 1 do
        if (startSlot + i) <= 15 then
            spriteTestPal[startSlot + i] := palData[i];
end;

procedure ApplyRoomSpriteAtlasPalette(dst: PWord);
var i: byte;
begin
    if dst = nil then exit;
    for i := 4 to 14 do
        dst[i] := SPRITE_ATLAS_PAL[i];
end;

function FindSteTile(src: word): PSteTile;
var i: word;
    tilePtr: PSteTile;
begin
    Result := nil;
    if currentWorldTiles = nil then exit;
    for i := 0 to currentWorldTileCount - 1 do begin
        tilePtr := PSteTile(longint(currentWorldTiles) + longint(i) * SizeOf(TSteTile));
        if tilePtr^.sourceAddr = src then begin
            Result := tilePtr;
            exit;
        end;
    end;
end;

procedure PutPixel4(scr: pword; x, y: word; color: byte);
var pw: pword;
    mask: word;
begin
    if x >= 320 then exit;
    if y >= 200 then exit;

    pw := pword(longint(scr) + longint(y) * SCREEN_LINE_BYTES + longint(x shr 4) * 8);
    mask := word(1) shl (15 - (x and 15));

    pw[0] := pw[0] and (not mask);
    pw[1] := pw[1] and (not mask);
    pw[2] := pw[2] and (not mask);
    pw[3] := pw[3] and (not mask);

    if (color and 1) <> 0 then pw[0] := pw[0] or mask;
    if (color and 2) <> 0 then pw[1] := pw[1] or mask;
    if (color and 4) <> 0 then pw[2] := pw[2] or mask;
    if (color and 8) <> 0 then pw[3] := pw[3] or mask;
end;

function GetPixel4(scr: pword; x, y: word): byte;
var pw: pword;
    mask: word;
begin
    if x >= 320 then exit(0);
    if y >= 200 then exit(0);
    pw := pword(longint(scr) + longint(y) * SCREEN_LINE_BYTES + longint(x shr 4) * 8);
    mask := word(1) shl (15 - (x and 15));
    Result := 0;
    if (pw[0] and mask) <> 0 then Result := Result or 1;
    if (pw[1] and mask) <> 0 then Result := Result or 2;
    if (pw[2] and mask) <> 0 then Result := Result or 4;
    if (pw[3] and mask) <> 0 then Result := Result or 8;
end;

procedure RestoreBackgroundRect(dst: pword; x, y, w, h: word);
var x2: word;
    spanWords: word;
    endMask1, endMask2, endMask3: word;
    srcWords, dstWords: pword;
    plane: word;
    clipTop, clipBottom: word;
begin
    if dst = nil then exit;
    if SCREEN_BKG = nil then exit;
    if (w = 0) or (h = 0) then exit;
    if x >= 320 then exit;
    if y >= 200 then exit;
    clipTop := BG_IMAGE_OFFSET_Y;
    clipBottom := BG_IMAGE_OFFSET_Y + PLAYFIELD_HEIGHT;
    if y < clipTop then begin
        if (y + h) <= clipTop then exit;
        h := h - (clipTop - y);
        y := clipTop;
    end;
    if y >= clipBottom then exit;
    if (x + w) > 320 then w := 320 - x;
    if (y + h) > clipBottom then h := clipBottom - y;
    if (w = 0) or (h = 0) then exit;

    x2 := x + w - 1;
    spanWords := ((x2 shr 4) - (x shr 4)) + 1;

    if spanWords > 2 then begin
        endMask1 := BLITTER_START_MASKS[x and 15];
        endMask2 := $FFFF;
        endMask3 := BLITTER_END_MASKS[x2 and 15];
    end else if spanWords > 1 then begin
        endMask1 := BLITTER_START_MASKS[x and 15];
        endMask2 := BLITTER_END_MASKS[x2 and 15];
        endMask3 := BLITTER_END_MASKS[x2 and 15];
    end else begin
        endMask1 := BLITTER_START_MASKS[x and 15] and BLITTER_END_MASKS[x2 and 15];
        endMask2 := endMask1;
        endMask3 := endMask1;
    end;

    srcWords := pword(longint(SCREEN_BKG) + longint(y) * SCREEN_LINE_BYTES + longint(x shr 4) * 8);
    dstWords := pword(longint(dst) + longint(y) * SCREEN_LINE_BYTES + longint(x shr 4) * 8);

    BlitterWait;
    BlitterWriteWord(BLITTER_ENDMASK1, endMask1);
    BlitterWriteWord(BLITTER_ENDMASK2, endMask2);
    BlitterWriteWord(BLITTER_ENDMASK3, endMask3);
    BlitterWriteWord(BLITTER_SRC_INC_X, 8);
    BlitterWriteWord(BLITTER_DST_INC_X, 8);
    BlitterWriteWord(BLITTER_SRC_INC_Y, SCREEN_LINE_BYTES - ((spanWords - 1) shl 3));
    BlitterWriteWord(BLITTER_DST_INC_Y, SCREEN_LINE_BYTES - ((spanWords - 1) shl 3));
    BlitterWriteWord(BLITTER_COUNT_X, spanWords);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC);
    BlitterWriteByte(BLITTER_SKEW, 0);
    for plane := 0 to 3 do begin
        BlitterWait;
        BlitterWritePtr(BLITTER_SRC_ADDR, srcWords + plane);
        BlitterWritePtr(BLITTER_DST_ADDR, dstWords + plane);
        BlitterWriteWord(BLITTER_COUNT_Y, h);
        BlitterWriteByte(BLITTER_MODE, BLITTER_MODE_BUSY);
    end;
    BlitterWait;
end;

procedure BeginQueuedSpritesFrame;
var i: byte;
    spr: ^TQueuedSprite;
begin
    UpdateDisplayPaletteIfNeeded(false);
    if queuedSpriteCount[screenLogIndex] > 0 then begin
        for i := 0 to queuedSpriteCount[screenLogIndex] - 1 do begin
            spr := @queuedSprites[screenLogIndex, i];
            RestoreBackgroundRect(SCREEN_LOG, spr^.x, spr^.y, spr^.widthPx, spr^.heightPx);
        end;
        queuedSpriteCount[screenLogIndex] := 0;
    end;
    CopyHudArea(SCREEN_BKG, SCREEN_LOG);
    DrawMessageTo(SCREEN_LOG);
end;

procedure QueueGeneratedSprite(dstX, dstY: word; frame: PSteSpriteFrame;
    wordsBase, palBase: PWord; palSlot: byte);
var idx: byte;
begin
    if frame = nil then exit;
    idx := queuedSpriteCount[screenLogIndex];
    if idx > High(queuedSprites[0]) then exit;
    queuedSprites[screenLogIndex, idx].x := dstX;
    queuedSprites[screenLogIndex, idx].y := dstY;
    queuedSprites[screenLogIndex, idx].widthPx := frame^.widthPx;
    queuedSprites[screenLogIndex, idx].heightPx := frame^.heightPx;
    queuedSprites[screenLogIndex, idx].frame := frame;
    queuedSprites[screenLogIndex, idx].wordsBase := wordsBase;
    queuedSprites[screenLogIndex, idx].palBase := palBase;
    queuedSprites[screenLogIndex, idx].palSlot := palSlot;
    Inc(queuedSpriteCount[screenLogIndex]);
end;

procedure QueueSpriteRect(dstX, dstY, widthPx, heightPx: word);
var idx: byte;
begin
    idx := queuedSpriteCount[screenLogIndex];
    if idx > High(queuedSprites[0]) then exit;
    queuedSprites[screenLogIndex, idx].x := dstX;
    queuedSprites[screenLogIndex, idx].y := dstY;
    queuedSprites[screenLogIndex, idx].widthPx := widthPx;
    queuedSprites[screenLogIndex, idx].heightPx := heightPx;
    queuedSprites[screenLogIndex, idx].frame := nil;
    queuedSprites[screenLogIndex, idx].wordsBase := nil;
    queuedSprites[screenLogIndex, idx].palBase := nil;
    queuedSprites[screenLogIndex, idx].palSlot := 0;
    Inc(queuedSpriteCount[screenLogIndex]);
end;

procedure SaveSpriteBackground(num: byte; x, y, w, h: word);
var px, py: word;
    idx: word;
begin
    if (w = 0) or (h = 0) then exit;
    if (w > 64) or (h > 128) then exit;
    spriteBgValid[num] := true;
    spriteBgX[num] := x;
    spriteBgY[num] := y;
    spriteBgW[num] := w;
    spriteBgH[num] := h;
    idx := 0;
    for py := 0 to h - 1 do
        for px := 0 to w - 1 do begin
            spriteBgPixels[num, idx] := GetPixel4(SCREEN_LOG, x + px, y + py);
            Inc(idx);
        end;
end;

procedure RestoreSpriteBackground(num: byte);
var px, py: word;
    idx: word;
begin
    if not spriteBgValid[num] then exit;
    idx := 0;
    for py := 0 to spriteBgH[num] - 1 do
        for px := 0 to spriteBgW[num] - 1 do begin
            PutPixel4(SCREEN_LOG, spriteBgX[num] + px, spriteBgY[num] + py, spriteBgPixels[num, idx]);
            Inc(idx);
        end;
    spriteBgValid[num] := false;
end;

procedure DrawSteTile(scr: pword; dstX, dstY: word; tile: PSteTile; flip: byte);
var y, xw: word;
    rowWords: word;
    dataOffset: word;
    dstWords: pword;
    maskBase, gfxBase: PWord;
    plane: word;
    dstPlane: pword;
    srcPlane: PWord;
    maskRow: PWord;
    gfxRow: PWord;
    maskWord: word;
begin
    if tile = nil then exit;
    if flip <> 0 then exit;

    if (dstX and 15) = 0 then begin
        rowWords := tile^.widthWords0;
        dataOffset := tile^.dataOffset0;
    end else if (dstX and 15) = 8 then begin
        rowWords := tile^.widthWords8;
        dataOffset := tile^.dataOffset8;
    end else
        exit;

    maskBase := PWord(longint(currentWorldTileWords) + longint(dataOffset) * SizeOf(word));
    gfxBase := PWord(longint(maskBase) + longint(tile^.heightPx) * longint(rowWords) * SizeOf(word));

    if not USE_TILE_BLITTER then begin
        for y := 0 to tile^.heightPx - 1 do begin
            maskRow := PWord(longint(maskBase) + longint(y) * longint(rowWords) * SizeOf(word));
            gfxRow := PWord(longint(gfxBase) + longint(y) * longint(rowWords) * 4 * SizeOf(word));
            dstWords := pword(longint(scr) + longint(dstY + y) * SCREEN_LINE_BYTES + longint(dstX shr 4) * 8);
            for xw := 0 to rowWords - 1 do begin
                maskWord := maskRow^;
                dstWords[0] := (dstWords[0] and maskWord) or gfxRow[0];
                dstWords[1] := (dstWords[1] and maskWord) or gfxRow[1];
                dstWords[2] := (dstWords[2] and maskWord) or gfxRow[2];
                dstWords[3] := (dstWords[3] and maskWord) or gfxRow[3];
                Inc(maskRow);
                Inc(gfxRow, 4);
                Inc(dstWords, 4);
            end;
        end;
        exit;
    end;

    BlitterWait;
    BlitterWriteWord(BLITTER_COUNT_X, rowWords);
    BlitterWriteWord(BLITTER_DST_INC_X, 8);
    BlitterWriteWord(BLITTER_DST_INC_Y, (SCREEN_LINE_BYTES + 8) - (rowWords shl 3));
    BlitterWriteWord(BLITTER_ENDMASK1, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK2, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK3, $FFFF);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_SKEW, 0);

    dstWords := pword(longint(scr) + longint(dstY) * SCREEN_LINE_BYTES + longint(dstX shr 4) * 8);

    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC_AND_DST);
    BlitterWriteWord(BLITTER_SRC_INC_X, 2);
    BlitterWriteWord(BLITTER_SRC_INC_Y, 2);
    for plane := 0 to 3 do begin
        BlitterWait;
        BlitterWritePtr(BLITTER_DST_ADDR, dstWords + plane);
        BlitterWritePtr(BLITTER_SRC_ADDR, maskBase);
        BlitterWriteWord(BLITTER_COUNT_Y, tile^.heightPx);
        BlitterWriteByte(BLITTER_MODE, BLITTER_MODE_BUSY);
    end;

    BlitterWait;
    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC_OR_DST);
    BlitterWriteWord(BLITTER_SRC_INC_X, 8);
    BlitterWriteWord(BLITTER_SRC_INC_Y, 8);
    for plane := 0 to 3 do begin
        BlitterWait;
        dstPlane := dstWords + plane;
        srcPlane := gfxBase + plane;
        BlitterWritePtr(BLITTER_DST_ADDR, dstPlane);
        BlitterWritePtr(BLITTER_SRC_ADDR, srcPlane);
        BlitterWriteWord(BLITTER_COUNT_Y, tile^.heightPx);
        BlitterWriteByte(BLITTER_MODE, BLITTER_MODE_BUSY);
    end;

    BlitterWait;
    exit;
end;

procedure PutTile(x, y: byte; src: word; flip: byte);
var tile: PSteTile;
    dstX, dstY: word;
    px: word;
    color: word;
begin
    tile := FindSteTile(src);
    if tile <> nil then begin
        dstX := word(x) * 4 * LEVEL_SCALE_X;
        dstY := LEVEL_OFFSET_Y + word(y) * LEVEL_SCALE_Y;
        DrawSteTile(SCREEN_LOG, dstX, dstY, tile, flip);
        if DEBUG_TILE_HUD then begin
            DrawDebugRect(SCREEN_LOG, dstX, dstY, tile^.widthPx, tile^.heightPx, 3);
            DrawTileLookupDebug(src, true);
        end;
        exit;
    end;

    if DEBUG_TILE_PLACEHOLDER then begin
        px := word(x) * 4 * LEVEL_SCALE_X;
        px := px and $FFF0;
        color := 2 + (src and 3);
        if flip <> 0 then color := 6 + (src and 1);

        FillRect16(SCREEN_LOG, px, y, 16, 8, color);
        if DEBUG_TILE_HUD then begin
            DrawTileLookupDebug(src, false);
        end;
    end;
end;
procedure PutIcon(icon: word; locked: boolean); begin end;

procedure ClearVram_range(addr: word; count: word); begin end;

{$i fade.inc}
{$i text.inc}

procedure LoadImage(imgNum: byte);
var imgPtr, palPtr: pointer;
begin
    if currentWorldImgPtrs = nil then exit;
    if imgNum >= currentWorldImgCount then exit;
    imgPtr := PPointer(currentWorldImgPtrs)[imgNum];
    palPtr := PPointer(currentWorldPalPtrs)[imgNum];
    currentCollisionData := nil;
    if currentWorldColPtrs <> nil then
        currentCollisionData := PByte(PPointer(currentWorldColPtrs)[imgNum]);
    ClearScreen(SCREEN_LOG);
    UnApl(imgPtr, SCREEN_LOG);
    currentBasePal := palPtr;
    currentPal := palPtr;
    SwapScreen;
end;

procedure LoadCutsceneSlide(slide, csbank: byte);
// Maps csbank (8-bit bank constant) + slide index to our global image arrays.
var imgPtr, palPtr: pointer;
begin
    imgPtr := nil;
    palPtr := nil;
    case csbank of
        INTRO_BANK: case slide of
            0: begin imgPtr := @IMG_INTRO_00[0]; palPtr := @IMG_INTRO_00_PAL[0]; end;
            1: begin imgPtr := @IMG_INTRO_01[0]; palPtr := @IMG_INTRO_01_PAL[0]; end;
            2: begin imgPtr := @IMG_INTRO_02[0]; palPtr := @IMG_INTRO_02_PAL[0]; end;
            3: begin imgPtr := @IMG_INTRO_03[0]; palPtr := @IMG_INTRO_03_PAL[0]; end;
            4: begin imgPtr := @IMG_INTRO_04[0]; palPtr := @IMG_INTRO_04_PAL[0]; end;
            5: begin imgPtr := @IMG_INTRO_05[0]; palPtr := @IMG_INTRO_05_PAL[0]; end;
        end;
        OUTRO_BANK: case slide of
            0: begin imgPtr := @IMG_OUTRO_00[0]; palPtr := @IMG_OUTRO_00_PAL[0]; end;
            1: begin imgPtr := @IMG_OUTRO_01[0]; palPtr := @IMG_OUTRO_01_PAL[0]; end;
            2: begin imgPtr := @IMG_OUTRO_02[0]; palPtr := @IMG_OUTRO_02_PAL[0]; end;
        end;
        CREDITS_BANK: case slide of
            0: begin imgPtr := @IMG_CREDITS_01[0]; palPtr := @IMG_CREDITS_01_PAL[0]; end;
            1: begin imgPtr := @IMG_CREDITS_02[0]; palPtr := @IMG_CREDITS_02_PAL[0]; end;
            2: begin imgPtr := @IMG_CREDITS_03[0]; palPtr := @IMG_CREDITS_03_PAL[0]; end;
            3: begin imgPtr := @IMG_CREDITS_04[0]; palPtr := @IMG_CREDITS_04_PAL[0]; end;
            4: begin imgPtr := @IMG_CREDITS_05[0]; palPtr := @IMG_CREDITS_05_PAL[0]; end;
            5: begin imgPtr := @IMG_CREDITS_06[0]; palPtr := @IMG_CREDITS_06_PAL[0]; end;
            6: begin imgPtr := @IMG_CREDITS_07[0]; palPtr := @IMG_CREDITS_07_PAL[0]; end;
            7: begin imgPtr := @IMG_CREDITS_08[0]; palPtr := @IMG_CREDITS_08_PAL[0]; end;
        end;
    end;
    if imgPtr = nil then exit;
    ClearScreen(SCREEN_BKG);
    UnApl(imgPtr, SCREEN_BKG);
    currentBasePal := palPtr;
    currentPal := palPtr;
end;

procedure PresentCutsceneSlide;
var srcPtr: PByte;
begin
    if (SCREEN_BKG = nil) or (SCREEN_LOG = nil) then exit;
    ClearScreen(SCREEN_LOG);
    srcPtr := PByte(longint(SCREEN_BKG) + 8 * SCREEN_LINE_BYTES);
    BlitterCopyData16(srcPtr, SCREEN_LOG, 168 * SCREEN_LINE_BYTES);
    BlitterClearBitmap4(SCREEN_LOG, 320, 32, 0, 168, 320);
    SwapScreen;
end;

procedure FadeIn;   begin FadeToPalette(pword(currentPal), FADE_FRAMES); end;
procedure FadeOut;  begin FadeToBlack(FADE_FRAMES); xbios_setpalette(@ALL_BLACK[0]); end;
procedure BlackAll; begin xbios_setpalette(@ALL_BLACK[0]); end;

procedure BuildDisplayPalette(dst: PWord);
begin
    if dst = nil then exit;
    if currentPal <> nil then
        Move(currentPal^, dst^, 32)
    else
        FillChar(dst^, 32, 0);

    if roomSpritePaletteActive then
        ApplyRoomSpriteAtlasPalette(dst);

    if msgDisplayCounter > 0 then
        dst[MESSAGE_TEXT_COLOR] := STE_PAL[topBarForeground];
end;

procedure RebuildRoomPalette;
begin
    if currentBasePal <> nil then
        Move(currentBasePal^, roomPalette[0], 32)
    else
        FillChar(roomPalette[0], SizeOf(roomPalette), 0);

    roomPalette[2] := STE_PAL[levelRawColors[0]];
    roomPalette[3] := STE_PAL[levelRawColors[2]];
    roomPalette[0] := STE_PAL[levelRawColors[3]];
    roomSpritePaletteActive := true;
    currentPal := @roomPalette[0];
end;

procedure RebuildCutscenePalette(c0, c1, c2, bg: byte);
begin
    if currentBasePal <> nil then
        Move(currentBasePal^, roomPalette[0], 32)
    else
        FillChar(roomPalette[0], SizeOf(roomPalette), 0);

    roomPalette[2] := STE_PAL[c0];
    roomPalette[1] := STE_PAL[c1];
    roomPalette[3] := STE_PAL[c2];
    roomPalette[0] := STE_PAL[bg];
    roomPalette[15] := $EEE;
    roomSpritePaletteActive := false;
    currentPal := @roomPalette[0];
end;

procedure RebuildTitlePalette(const colors: array of byte);
var i: integer;
begin
    if currentBasePal <> nil then
        Move(currentBasePal^, titlePalette[0], 32)
    else
        FillChar(titlePalette[0], SizeOf(titlePalette), 0);

    for i := 0 to High(colors) do
        if i <= 15 then
            titlePalette[i] := STE_PAL[colors[i]];

    roomSpritePaletteActive := false;
    currentPal := @titlePalette[0];
end;

procedure UpdateDisplayPaletteIfNeeded(force: boolean);
var msgSource: shortint;
begin
    if msgDisplayCounter > 0 then begin
        msgSource := topBarForeground;
    end else
        msgSource := -1;

    if (not force) and (not displayPaletteDirty) and
       (lastPaletteMsgSource = msgSource) then
        exit;

    BuildDisplayPalette(@spriteTestPal[0]);
    xbios_setpalette(@spriteTestPal[0]);

    lastPaletteMsgSource := msgSource;
    displayPaletteDirty := false;
end;

procedure ApplyFlobPalette;
begin
end;

procedure SaveFlobBackground(x, y, w, h: word);
begin
end;

procedure RestoreFlobBackground;
begin
end;

procedure ClearFlob;
begin
    RestoreFlobBackground;
end;

procedure DrawGeneratedSpriteFrameBlitter(scr: pword; dstX, dstY: word;
    frame: PSteSpriteFrame; wordsBase: PWord);
var rowWords: word;
    lX2, lXcount: word;
    skew: byte;
    endMask1, endMask2, endMask3: word;
    dstWords: pword;
    maskBase, gfxBase: PWord;
    plane: word;
begin
    if frame = nil then exit;
    if dstX >= 320 then exit;
    if dstY >= 200 then exit;
    if (dstX + frame^.widthPx) > 320 then exit;
    if (dstY + frame^.heightPx) > 200 then exit;

    rowWords := frame^.rowWords;
    lX2 := (dstX + frame^.widthPx) - 1;
    lXcount := (((lX2 and $FFF0) - (dstX and $FFF0)) shr 4) + 1;

    if (dstX and 15) <> 0 then
        skew := BLITTER_SKEW_NFSR or byte(dstX and 15)
    else
        skew := 0;

    if lXcount > 2 then begin
        endMask1 := BLITTER_START_MASKS[dstX and 15];
        endMask2 := $FFFF;
        endMask3 := BLITTER_END_MASKS[lX2 and 15];
    end else if lXcount > 1 then begin
        endMask1 := BLITTER_START_MASKS[dstX and 15];
        endMask2 := BLITTER_END_MASKS[lX2 and 15];
        endMask3 := BLITTER_END_MASKS[lX2 and 15];
    end else begin
        endMask1 := BLITTER_START_MASKS[dstX and 15] and BLITTER_END_MASKS[lX2 and 15];
        endMask2 := endMask1;
        endMask3 := endMask1;
    end;

    dstWords := pword(longint(scr) + longint(dstY) * SCREEN_LINE_BYTES + longint(dstX shr 4) * 8);
    maskBase := PWord(longint(wordsBase) + longint(frame^.maskOffset) * SizeOf(word));
    gfxBase := PWord(longint(wordsBase) + longint(frame^.dataOffset) * SizeOf(word));

    BlitterWait;
    BlitterWriteWord(BLITTER_COUNT_X, lXcount);
    BlitterWriteWord(BLITTER_DST_INC_X, 8);
    BlitterWriteWord(BLITTER_DST_INC_Y, (SCREEN_LINE_BYTES + 8) - (lXcount shl 3));
    BlitterWriteWord(BLITTER_ENDMASK1, endMask1);
    BlitterWriteWord(BLITTER_ENDMASK2, endMask2);
    BlitterWriteWord(BLITTER_ENDMASK3, endMask3);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_SKEW, skew);

    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC_AND_DST);
    BlitterWriteWord(BLITTER_SRC_INC_X, 2);
    BlitterWriteWord(BLITTER_SRC_INC_Y, 2);
    for plane := 0 to 3 do begin
        BlitterWait;
        BlitterWritePtr(BLITTER_DST_ADDR, dstWords + plane);
        BlitterWritePtr(BLITTER_SRC_ADDR, maskBase);
        BlitterWriteWord(BLITTER_COUNT_Y, frame^.heightPx);
        BlitterWriteByte(BLITTER_MODE, BLITTER_MODE_BUSY);
    end;

    BlitterWait;
    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC_OR_DST);
    BlitterWriteWord(BLITTER_SRC_INC_X, 8);
    BlitterWriteWord(BLITTER_SRC_INC_Y, 8);
    for plane := 0 to 3 do begin
        BlitterWait;
        BlitterWritePtr(BLITTER_DST_ADDR, dstWords + plane);
        BlitterWritePtr(BLITTER_SRC_ADDR, gfxBase + plane);
        BlitterWriteWord(BLITTER_COUNT_Y, frame^.heightPx);
        BlitterWriteByte(BLITTER_MODE, BLITTER_MODE_BUSY);
    end;
    BlitterWait;
end;

procedure FlushQueuedSprites;
var i: byte;
    spr: ^TQueuedSprite;
begin
    if queuedSpriteCount[screenLogIndex] = 0 then exit;
    for i := 0 to queuedSpriteCount[screenLogIndex] - 1 do begin
        spr := @queuedSprites[screenLogIndex, i];
        if spr^.frame = nil then
            continue;
        DrawGeneratedSpriteFrameBlitter(
            SCREEN_LOG,
            spr^.x,
            spr^.y,
            spr^.frame,
            spr^.wordsBase
        );
    end;
end;

procedure PresentQueuedSprites;
begin
    if queuedSpriteCount[screenLogIndex] > 0 then
        FlushQueuedSprites;
    SwapScreen;
end;

procedure DrawFlob;
var frameIdx: byte;
    dstX, dstY: word;
begin
    frameIdx := flobFrame + flobDir;
    if frameIdx > High(SPR_FLOB_FRAMES) then exit;
    dstX := word(flobX) * LEVEL_SCALE_X;
    dstY := FLOB_RENDER_OFFSET_Y + word(flobY) * LEVEL_SCALE_Y;
    QueueGeneratedSprite(
        dstX,
        dstY,
        @SPR_FLOB_FRAMES[frameIdx],
        @SPR_FLOB_WORDS[0],
        nil,
        0
    );
end;

function PackedBcdToScore5(value: cardinal): string;
var i: integer;
    digit: char;
begin
    Result := '00000';
    for i := 4 downto 0 do begin
        digit := Chr(Ord('0') + (value and $F));
        Result[i + 1] := digit;
        value := value shr 4;
    end;
end;

function PackedBcdToInt(value: cardinal): cardinal;
var mul: cardinal;
    digit: cardinal;
begin
    Result := 0;
    mul := 1;
    while value <> 0 do begin
        digit := value and $F;
        if digit > 9 then
            digit := 0;
        Result := Result + digit * mul;
        mul := mul * 10;
        value := value shr 4;
    end;
end;

function IntToPackedBcd(value: cardinal): cardinal;
var digit: cardinal;
    shift: cardinal;
begin
    Result := 0;
    shift := 0;
    while value > 0 do begin
        digit := value mod 10;
        Result := Result or (digit shl shift);
        value := value div 10;
        Inc(shift, 4);
    end;
end;

function ScoreTextBytes(p: PByte; len: word): integer;
var i: word;
    b: byte;
begin
    Result := -1;
    if p = nil then exit;
    Result := 0;
    for i := 0 to len - 1 do begin
        b := PByte(longint(p) + i)^;
        if b = 0 then
            Inc(Result, 1)
        else if (b >= 32) and (b <= 95) then
            Inc(Result, 2)
        else if b < 64 then
            Inc(Result, 1)
        else
            Dec(Result, 4);
    end;
end;

function ResolveWorldTextPtr(addr: word): PByte;
var ofs: word;
    dataPtr, assetPtr: PByte;
begin
    Result := nil;
    if addr < $A000 then exit;
    ofs := addr - $A000;

    dataPtr := nil;
    if (currentWorldData <> nil) and (ofs + 79 < 8192) then
        dataPtr := PByte(longint(currentWorldData) + ofs);

    assetPtr := nil;
    if (currentWorldAssets <> nil) and (ofs + 79 < currentWorldAssetsSize) then
        assetPtr := PByte(longint(currentWorldAssets) + ofs);

    // Message/scene text labels live in the asset bank in the original worlds.
    // Prefer that bank here and only fall back to world data if needed.
    if assetPtr <> nil then
        Result := assetPtr
    else
        Result := dataPtr;
end;

function DecodeWorldTextLine(addr: word; line: byte): string;
var p: PByte;
    i: integer;
    b: byte;
    raw: AnsiString;
begin
    Result := '';
    p := ResolveWorldTextPtr(addr);
    if p = nil then exit;
    SetLength(raw, 40);
    for i := 0 to 39 do begin
        b := PByte(longint(p) + word(line) * 40 + i)^;
        raw[i + 1] := Chr(b and $7F);
    end;
    Result := Antic2Ascii(raw);
end;

procedure DrawTextTo(scr: pword; x, y, fg, bg: word; const str: string);
var i: integer;
begin
    for i := 1 to Length(str) do begin
        DrawChar(scr, @FlobFont, x, y, Ord(str[i]), fg, bg);
        Inc(x, 8);
    end;
end;

procedure DrawTextCenteredTo(scr: pword; y, fg, bg: word; const str: string);
var x: word;
begin
    x := (320 - word(Length(str)) * 8) div 2;
    DrawTextTo(scr, x, y, fg, bg, str);
end;

procedure DrawHudTo(scr: pword);
var scoreStr: string;
begin
    BlitterClearBitmap4(scr, 320, 20, 0, 0, 320);
    FillRect16(scr, 0, HUD_HEIGHT, 320, 2, 1);
    DrawTextTo(scr, 8, 0, 1, 0, Antic2Ascii(world.name));
    scoreStr := PackedBcdToScore5(mySlime);
    DrawTextTo(scr, 320 - 8 - Length(scoreStr) * 8, 0, 1, 0, scoreStr);
end;

procedure RefreshHudCache;
begin
    if SCREEN_BKG <> nil then
        DrawHudTo(SCREEN_BKG);
end;

procedure DrawMessageTo(scr: pword);
begin
    BlitterClearBitmap4(scr, 320, 20, 0, 180, 320);
    if msgDisplayCounter > 0 then begin
        DrawTextTo(scr, 0, 180, MESSAGE_TEXT_COLOR, 0, currentMessageLines[0]);
        DrawTextTo(scr, 0, 188, MESSAGE_TEXT_COLOR, 0, currentMessageLines[1]);
    end;
end;

procedure DrawOneSlime(scr: pword; px, py: smallint);
begin
    if (px < 1) or (py < 1) then exit;
    PutPixel4(scr, px + 1, py + 0, 10);
    PutPixel4(scr, px + 0, py + 1, 10);
    PutPixel4(scr, px + 1, py + 1, 11);
    PutPixel4(scr, px + 2, py + 1, 10);
    PutPixel4(scr, px + 1, py + 2, 10);
end;

procedure DrawSlimesTo(scr: pword);
var i: byte;
    px, py, rowY: smallint;
begin
    for i := 0 to 19 do begin
        if slimeX[i] = 0 then
            continue;
        px := smallint(slimeX[i]) * LEVEL_SCALE_X + SLIME_RENDER_OFFSET_X;
        rowY := smallint(i shl 2);
        if flipped then
            rowY := 76 - rowY;
        py := rowY * LEVEL_SCALE_Y + SLIME_RENDER_OFFSET_Y;
        DrawOneSlime(scr, px, py);
    end;
end;

procedure RefreshOverlayBuffers;
begin
    if SCREEN_LOG <> nil then begin
        CopyHudArea(SCREEN_BKG, SCREEN_LOG);
        DrawMessageTo(SCREEN_LOG);
    end;
    if SCREEN_PHY <> nil then begin
        CopyHudArea(SCREEN_BKG, SCREEN_PHY);
        DrawMessageTo(SCREEN_PHY);
    end;
end;

procedure DrawSlimes;
var i: byte;
    px, py, rowY: smallint;
    frameIdx: byte;
begin
    frameIdx := (sysframe shr 4) and 1;
    for i := 0 to 19 do begin
        if slimeX[i] = 0 then
            continue;
        px := smallint(slimeX[i]) * LEVEL_SCALE_X + SLIME_RENDER_OFFSET_X;
        rowY := smallint(i shl 2);
        if flipped then
            rowY := 76 - rowY;
        py := rowY * LEVEL_SCALE_Y + SLIME_RENDER_OFFSET_Y;
        if (px < 0) or (py < 0) then
            continue;
        QueueGeneratedSprite(
            word(px),
            word(py),
            @SPR_SLIME_FRAMES[frameIdx],
            @SPR_SLIME_WORDS[0],
            nil,
            0
        );
    end;
end;

procedure ClearSlimes;
begin
end;

procedure ShowSlime;
begin
    RefreshHudCache;
    RefreshOverlayBuffers;
end;

function SpriteAssetPtr(addr: word): PByte;
var ofs: word;
begin
    Result := nil;
    if currentWorldAssets = nil then exit;
    if addr < $A000 then exit;
    ofs := addr - $A000;
    if ofs >= currentWorldAssetsSize then exit;
    Result := PByte(longint(currentWorldAssets) + ofs);
end;

function LoadAnimationStepFromAsset(addr: word; var step: TAnimationStep): boolean;
var p: PByte;
begin
    Result := false;
    FillChar(step, SizeOf(step), 0);
    p := SpriteAssetPtr(addr);
    if p = nil then exit;
    Move(p^, step, SizeOf(TAnimationStep));
    Result := true;
end;

function MapSpriteColorRaw(c: byte; channel: byte): byte;
var lum: byte;
begin
    if c = 0 then exit(0);
    lum := c and $0F;
    if lum >= 8 then Result := 1
    else if lum >= 4 then Result := 2
    else Result := 3;
    if (channel = 1) and (Result = 1) then Result := 2;
end;

procedure ClearSprite(num: byte);
begin
    RestoreSpriteBackground(num);
    spritePtr[num] := 0;
end;

procedure ClearSprites;
begin
    if sprites.state = SPRITE_NONE then exit;
    if sprites.state > SPRITE_NONE then ClearSprite(0);
    if sprites.state > SPRITE_SINGLE then ClearSprite(1);
end;

procedure ShowSprite(num: byte);
var src, rowPtr: PByte;
    x, y, h, frameCount, frameIdx: byte;
    upside: boolean;
    dstX, dstY: word;
    drawW, drawH: word;
    rawRow, rowByte: byte;
    py, dy, dx, bit: byte;
    color: byte;
    drawX, drawY: smallint;
begin
    spritePtr[num] := 0;
    if (sprites.stype[num] = STYPE_EXIT) and not mainGoalReached then exit;
    if ((sprites.stype[num] = STYPE_DECOR) or (sprites.stype[num] = STYPE_GOAL)) and
        (sprites.goal[num] <> NONE) and (goals[sprites.goal[num]] = 0) then exit;
    if (sprites.stype[num] = STYPE_DIAL) and
        (sprites.param2[num] <> $ff) and (goals[sprites.param2[num]] > 0) then exit;

    frameCount := spriteData.frameCount[num];
    h := spriteData.height[num];
    if frameCount = 0 then exit;
    frameIdx := spriteFrame[num];
    if frameIdx >= frameCount then frameIdx := 0;
    src := spriteFramesRaw[num, frameIdx];
    if src = nil then exit;

    x := sprites.x[num];
    y := sprites.y[num];
    upside := false;
    if flipped and (sprites.flipable[num] = 1) then begin
        y := 80 - (h + y);
        upside := true;
    end;

    if (num = 1) and (sprites.state = SPRITE_COMBINED) then
        x := x + sprites.gap;

    drawX := smallint(x) * LEVEL_SCALE_X + WORLD_SPRITE_OFFSET_X;
    drawY := LEVEL_OFFSET_Y + smallint(y) * LEVEL_SCALE_Y + WORLD_SPRITE_OFFSET_Y;
    if drawX < 0 then drawX := 0;
    if drawY < 0 then drawY := 0;
    dstX := word(drawX);
    dstY := word(drawY);
    drawW := 8 * LEVEL_SCALE_X;
    drawH := word(h) * LEVEL_SCALE_Y;
    if (drawW = 0) or (drawH = 0) then exit;
    color := MapSpriteColorRaw(spriteColorsRaw[num][frameIdx], num);

    for rawRow := 0 to h - 1 do begin
        if upside then
            rowPtr := PByte(longint(src) + longint(h - 1 - rawRow))
        else
            rowPtr := PByte(longint(src) + longint(rawRow));
        rowByte := rowPtr^;
        for py := 0 to LEVEL_SCALE_Y - 1 do begin
            dy := rawRow * LEVEL_SCALE_Y + py;
            for bit := 0 to 7 do
                if (rowByte and (byte($80) shr bit)) <> 0 then
                    for dx := 0 to LEVEL_SCALE_X - 1 do
                        PutPixel4(SCREEN_LOG, dstX + word(bit) * LEVEL_SCALE_X + dx, dstY + dy, color);
        end;
    end;
    QueueSpriteRect(dstX, dstY, drawW, drawH);
    spritePtr[num] := 1;
end;

procedure ShowSprites;
begin
    if sprites.state = SPRITE_NONE then exit;
    if sprites.state > SPRITE_NONE then ShowSprite(0);
    if sprites.state > SPRITE_SINGLE then ShowSprite(1);
end;

procedure ApplyTestSpritePalette(palData: PWord; palCount: byte);
var i: byte;
begin
    if currentPal <> nil then
        Move(currentPal^, spriteTestPal[0], 32)
    else
        Move(ALL_BLACK[0], spriteTestPal[0], 32);
    for i := 0 to palCount - 1 do
        if (12 + i) <= 15 then
            spriteTestPal[12 + i] := palData[i];
    xbios_setpalette(@spriteTestPal[0]);
end;

procedure DrawGeneratedSpriteFrame(scr: pword; dstX, dstY: word;
    frame: PSteSpriteFrame; wordsBase, palBase: PWord);
var y, x, wordIdx: word;
    maskWord: word;
    planes: array[0..3] of word;
    bitMask: word;
    color: byte;
    maskRow, dataRow, palData: PWord;
begin
    if frame = nil then exit;
    if (palBase <> nil) and (frame^.paletteCount > 0) then begin
        palData := PWord(longint(palBase) + longint(frame^.paletteOffset) * SizeOf(word));
        ApplyTestSpritePalette(palData, frame^.paletteCount);
    end;

    for y := 0 to frame^.heightPx - 1 do begin
        maskRow := PWord(longint(wordsBase) + longint(frame^.maskOffset + y * frame^.rowWords) * SizeOf(word));
        dataRow := PWord(longint(wordsBase) + longint(frame^.dataOffset + y * frame^.rowWords * 4) * SizeOf(word));
        for wordIdx := 0 to frame^.rowWords - 1 do begin
            maskWord := maskRow^;
            planes[0] := dataRow[0];
            planes[1] := dataRow[1];
            planes[2] := dataRow[2];
            planes[3] := dataRow[3];
            for x := 0 to 15 do begin
                bitMask := word(1) shl (15 - x);
                if (maskWord and bitMask) = 0 then begin
                    color := 0;
                    if (planes[0] and bitMask) <> 0 then color := color or 1;
                    if (planes[1] and bitMask) <> 0 then color := color or 2;
                    if (planes[2] and bitMask) <> 0 then color := color or 4;
                    if (planes[3] and bitMask) <> 0 then color := color or 8;
                    if color > 0 then
                        PutPixel4(scr, dstX + wordIdx * 16 + x, dstY + y, 11 + color);
                end;
            end;
            Inc(maskRow);
            Inc(dataRow, 4);
        end;
    end;
end;

procedure DrawTestBigSlime;
begin
    if not DEBUG_TEST_BIGSLIME then exit;
    DrawGeneratedSpriteFrame(
        SCREEN_LOG,
        152,
        108,
        @SPR_BIGSLIME_FRAMES[0],
        @SPR_BIGSLIME_WORDS[0],
        nil
    );
end;

procedure ShowLevelName;
begin
    RefreshOverlayBuffers;
end;

procedure InitLevelScreen;
begin
    ShowLevelName;
end;

procedure GetImageInfo(imgBank, imgNum: byte);
begin
    // No-op on STE: image.start was an 8-bit address; use LoadImage/LoadCutsceneSlide instead.
end;

// ***************************************************
// *** SOUND STUBS
// ***************************************************

procedure PlaySong(p: byte); begin end;
procedure StopSong;          begin end;
procedure FSfx(patch: byte); begin end;
procedure Sfx(patch: byte);  begin end;

{$i input.inc}

// ***************************************************
// *** BANK SWITCHING STUBS (no cartridge on STE)
// ***************************************************

procedure SetBank0; begin end; // no-op on STE with flat RAM
procedure SetBank(bank: byte); begin end;

// ***************************************************
// *** ASSET DECOMPRESSION STUBS
// ***************************************************

// unApl is declared external (unapl.o) above
procedure ExpandLZ4(src, dst: word); begin end;

// ***************************************************
// *** HELPERS (from original flob.pas)
// ***************************************************

function IsStereoPresent: boolean;
begin
    Result := false; // stub
end;

function MapColor(c: byte): byte;
begin
    Result := c; // stub – on STE we'll use real ST palette values
end;

procedure Sec2TimeInS1(seconds: word);
var min, sec: word;
begin
    min := seconds div 60;
    sec := seconds - (min * 60);
    Str(min, s1);
    Str(sec, s);
    s2 := ':';
    if Length(s) = 1 then s1 := s1 + ':0'
    else s1 := s1 + s2;
    s1 := s1 + s;
end;

procedure GetCutsceneText(csbank, slide: byte; out c0, c1, c2, bg: byte;
    out l0, l1, l2, l3: string);
begin
    c0 := 15;
    c1 := 15;
    c2 := 15;
    bg := 0;
    l0 := '';
    l1 := '';
    l2 := '';
    l3 := '';

    if csbank = INTRO_BANK then begin
        case slide of
            0: begin
                c0 := $92; c1 := $0d; c2 := $36; bg := $00;
                l0 := '          Your name is Flob.            ';
                l1 := '            You came to be              ';
                l2 := '       from a tiny drop of slime        ';
                l3 := '       invented by Dr Sven Torff.       ';
            end;
            1: begin
                c0 := $d2; c1 := $1d; c2 := $36; bg := $00;
                l0 := '      Defenceless and vulnerable,       ';
                l1 := '        you die within minutes          ';
                l2 := '    without regular doses of slime.     ';
                l3 := '   But things aren''t as they seem...    ';
            end;
            2: begin
                c0 := $d2; c1 := $1d; c2 := $36; bg := $00;
                l0 := '       You can turn excess slime        ';
                l1 := '    into a huge gravitational wave      ';
                l2 := '   which turns the world upside down.   ';
                l3 := '               Verbatim.                ';
            end;
            3: begin
                c0 := $14; c1 := $ed; c2 := $62; bg := $00;
                l0 := '   When Dr Torff realised your power,   ';
                l1 := '  he decided to hide the slime formula  ';
                l2 := '   and its secret ingredients in four   ';
                l3 := '     remote spots around the world.     ';
            end;
            4: begin
                c0 := $82; c1 := $1d; c2 := $36; bg := $00;
                l0 := ' Your only clues about the whereabouts  ';
                l1 := ' of the ingredients, are drops of slime ';
                l2 := '         left by Doctor Torff.          ';
                l3 := '      Collect them to regenerate.       ';
            end;
            5: begin
                c0 := $32; c1 := $3d; c2 := $36; bg := $00;
                l0 := '      Find all secret ingredients       ';
                l1 := '         and the slime formula.         ';
                l2 := '            Become immortal             ';
                l3 := '          and rule the world!           ';
            end;
        end;
        exit;
    end;

    if csbank = OUTRO_BANK then begin
        case slide of
            0: begin
                c0 := $02; c1 := $1d; c2 := $36; bg := $00;
                l0 := '      You have found the formula,       ';
                l1 := '      and all secret ingredients,       ';
                l2 := '  but turned this beautiful world into  ';
                l3 := '  wasteland, full of ruins and ashes.   ';
            end;
            1: begin
                c0 := $32; c1 := $3d; c2 := $36; bg := $30;
                l0 := '       But who cares? You Rule!!!       ';
                l1 := '        Now you are invincible.         ';
                l2 := '              Unbeatable.               ';
                l3 := '               Forever.                 ';
            end;
            2: begin
                c0 := $e2; c1 := $1d; c2 := $34; bg := $00;
                l0 := '                                        ';
                l1 := '                                        ';
                l2 := '                                        ';
                l3 := '           to be continued...           ';
            end;
        end;
    end;
end;

procedure DrawCutsceneTextBlock(scr: pword; bg: word);
begin
    FillRect16(scr, 0, 168, 320, 32, bg);
end;

procedure RenderCutsceneText(scr: pword; const l0, l1, l2, l3: string;
    visibleLines: byte);
begin
    DrawCutsceneTextBlock(scr, 0);
    if visibleLines > 0 then DrawTextCenteredTo(scr, 167, 15, 0, l0);
    if visibleLines > 1 then DrawTextCenteredTo(scr, 175, 15, 0, l1);
    if visibleLines > 2 then DrawTextCenteredTo(scr, 183, 15, 0, l2);
    if visibleLines > 3 then DrawTextCenteredTo(scr, 191, 15, 0, l3);
end;

procedure PrepareCutscenePalette(csbank, slide: byte);
var c0, c1, c2, bg: byte;
    l0, l1, l2, l3: string;
begin
    GetCutsceneText(csbank, slide, c0, c1, c2, bg, l0, l1, l2, l3);
    RebuildCutscenePalette(c0, c1, c2, bg);
end;

{$i saving_routines.inc}

// ***************************************************
// *** STATS / ACHIEVEMENTS
// ***************************************************

procedure CountGlobalStats;
var worldNum: byte;
begin
    FillChar(globalStats, SizeOf(TGlobalStats), 0);
    for worldNum := 0 to WORLD_COUNT - 1 do begin
        GetWorldStats(worldNum);
        globalStats.attempts     := globalStats.attempts     + worldStats.attempts;
        globalStats.winCount     := globalStats.winCount     + worldStats.winCount;
        globalStats.failCount    := globalStats.failCount    + worldStats.failCount;
        globalStats.totalScore   := globalStats.totalScore   + worldStats.totalScore;
        globalStats.totalTime    := globalStats.totalTime    + worldStats.totalTime;
        globalStats.totalSlimes  := globalStats.totalSlimes  + worldStats.totalSlimes;
        globalStats.totalDeaths  := globalStats.totalDeaths  + worldStats.totalDeaths;
        globalStats.flawlessCount  := globalStats.flawlessCount  + worldStats.flawlessCount;
        globalStats.allSecretsCount := globalStats.allSecretsCount + worldStats.secretAllCount;
        globalStats.allSlimesCount  := globalStats.allSlimesCount  + worldStats.pickAllCount;
        if worldStats.flawlessCount  > 0 then Inc(globalStats.flawlessWorlds);
        if worldStats.pickAllCount   > 0 then Inc(globalStats.allSlimesWorlds);
        if worldStats.secretAllCount > 0 then Inc(globalStats.allSecretsWorlds);
        if worldStats.mastersCount   > 0 then Inc(globalStats.mastersWorlds);
        if worldStats.winCount       > 0 then Inc(globalStats.goalsCount);
        if worldStats.speedRunsCount > 0 then Inc(globalStats.speedRunsWorlds);
    end;
end;

// Achievement data is loaded from world banks on 8-bit;
// on STE we stub these with empty records for now.
procedure LoadAchievement(achNum: byte);
begin
    FillChar(achievement, SizeOf(TAchievement), 0);
end;

function isAchivementReached: boolean;
var val: cardinal;
begin
    Result := false;
    val := 0;
    case achievement.value of
        1:  val := worldStats.winCount;
        4:  val := worldStats.totalSlimes;
        5:  val := worldStats.flawlessCount;
        6:  val := worldStats.pickAllCount;
        7:  val := worldStats.secretAllCount;
        8:  val := worldStats.bestScore;
        9:  val := worldStats.bestTime;
        10: val := worldStats.totalTime;
        11: val := worldStats.mastersCount;
        $10: val := globalStats.goalsCount;
        $11: val := globalStats.allSecretsWorlds;
        $12: val := globalStats.allSlimesWorlds;
        $13: val := globalStats.totalSlimes;
        $14: val := globalStats.winCount;
        $15: val := globalStats.totalScore;
        $16: val := globalStats.flawlessCount;
        $17: val := globalStats.totalDeaths;
        $18: val := achivementsCount;
        $1A: val := globalStats.totalTime;
        $1B: val := globalStats.mastersWorlds;
        $1C: val := globalStats.speedRunsWorlds;
    end;
    if achievement.oper = IS_GREATER then
        Result := val > achievement.treshold;
    if achievement.oper = IS_LESSER then
        Result := val < achievement.treshold;
    if achievement.oper = TRESHOLD_TIME_REACHED then
        Result := word(val) < world.timeTreshold;
    if achievement.oper = TRESHOLD_SCORE_REACHED then
        Result := word(val) > world.scoreTreshold;
end;

procedure CheckAchievements;
var w, achNum, i: byte;
    procedure CheckAchievement(a: byte);
    begin
        LoadAchievement(a);
        if isAchivementReached then begin
            if achievements[achNum] = 0 then begin
                Inc(newAchivements);
                achievements[achNum] := 2;
            end;
            Inc(achivementsCount);
        end else begin
            if achievements[achNum] <> 0 then achievements[achNum] := 0;
        end;
        Inc(achNum);
    end;
begin
    newAchivements  := 0;
    achivementsCount := 0;
    achNum := 0;
    CountGlobalStats;
    for w := 0 to WORLD_COUNT - 1 do begin
        LoadWorld(w);
        GetWorldStats(w);
        for i := 0 to 11 do CheckAchievement(i);
    end;
    for i := 12 to 23 do CheckAchievement(i);
end;

procedure PlaySoundFx(patch: byte); begin end; // internal alias used below

// ***************************************************
// *** SCORE
// ***************************************************

procedure AddSlime(val: word); overload;
begin
    mySlime := IntToPackedBcd(PackedBcdToInt(mySlime) + val);
    ShowSlime;
end;

procedure AddSlime(val: byte); overload;
begin
    mySlime := IntToPackedBcd(PackedBcdToInt(mySlime) + val);
    ShowSlime;
end;

procedure SubSlime(val: byte);
var current: cardinal;
begin
    current := PackedBcdToInt(mySlime);
    if val < current then begin
        mySlime := IntToPackedBcd(current - val);
        ShowSlime;
    end else begin
        mySlime := 0;
        ShowSlime;
        mainGoalReached := false;
        if not game_over then EndWorld;
    end;
end;

// ***************************************************
// *** HELPERS
// ***************************************************

function GetPix(x, y: byte): byte;
var sampleY: byte;
    byteOfs: word;
    packedByte: byte;
    shift: byte;
begin
    if y > 79 then exit(0);
    if currentCollisionData = nil then exit(0);
    if flipped then sampleY := 79 - y
    else sampleY := y;
    byteOfs := word(sampleY) * 40 + (x shr 2);
    packedByte := currentCollisionData[byteOfs];
    shift := 6 - ((x and 3) shl 1);
    Result := (packedByte shr shift) and 3;
end;

function IsSolidPix(p: byte): boolean; inline;
begin
    Result := p = GROUND_COLLISION_COLOR;
end;

procedure ArmTrigger(ptr: word);
begin
    Move(leveldata[ptr], roomTriggers[triggerCount][0], 10);
    Inc(triggerCount);
end;

// ***************************************************
// *** WORLD / LEVEL LOADING
// ***************************************************

procedure LoadWorld(w: byte);
begin
    case w of
        0: begin
            Move(WORLD_00_DATA[0], world, SizeOf(TWorld));
            currentWorldData    := @WORLD_00_DATA[0];
            currentWorldAssets  := @WORLD_00_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_00_ASSETS) + 1;
            currentWorldImgPtrs := @W00_IMG_PTRS[0];
            currentWorldPalPtrs := @W00_PAL_PTRS[0];
            currentWorldColPtrs := @W00_COL_PTRS[0];
            currentWorldImgCount := W00_IMG_COUNT;
            currentWorldTiles := @W00_TILES[0];
            currentWorldTileWords := @W00_TILE_WORDS[0];
            currentWorldTileCount := W00_TILE_COUNT;
        end;
        1: begin
            Move(WORLD_01_DATA[0], world, SizeOf(TWorld));
            currentWorldData    := @WORLD_01_DATA[0];
            currentWorldAssets  := @WORLD_01_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_01_ASSETS) + 1;
            currentWorldImgPtrs := @W01_IMG_PTRS[0];
            currentWorldPalPtrs := @W01_PAL_PTRS[0];
            currentWorldColPtrs := @W01_COL_PTRS[0];
            currentWorldImgCount := W01_IMG_COUNT;
            currentWorldTiles := @W01_TILES[0];
            currentWorldTileWords := @W01_TILE_WORDS[0];
            currentWorldTileCount := W01_TILE_COUNT;
        end;
        2: begin
            Move(WORLD_02_DATA[0], world, SizeOf(TWorld));
            currentWorldData    := @WORLD_02_DATA[0];
            currentWorldAssets  := @WORLD_02_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_02_ASSETS) + 1;
            currentWorldImgPtrs := @W02_IMG_PTRS[0];
            currentWorldPalPtrs := @W02_PAL_PTRS[0];
            currentWorldColPtrs := @W02_COL_PTRS[0];
            currentWorldImgCount := W02_IMG_COUNT;
            currentWorldTiles := @W02_TILES[0];
            currentWorldTileWords := @W02_TILE_WORDS[0];
            currentWorldTileCount := W02_TILE_COUNT;
        end;
        3: begin
            Move(WORLD_03_DATA[0], world, SizeOf(TWorld));
            currentWorldData    := @WORLD_03_DATA[0];
            currentWorldAssets  := @WORLD_03_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_03_ASSETS) + 1;
            currentWorldImgPtrs := @W03_IMG_PTRS[0];
            currentWorldPalPtrs := @W03_PAL_PTRS[0];
            currentWorldColPtrs := @W03_COL_PTRS[0];
            currentWorldImgCount := W03_IMG_COUNT;
            currentWorldTiles := @W03_TILES[0];
            currentWorldTileWords := @W03_TILE_WORDS[0];
            currentWorldTileCount := W03_TILE_COUNT;
        end;
        4: begin
            Move(WORLD_04_DATA[0], world, SizeOf(TWorld));
            currentWorldData    := @WORLD_04_DATA[0];
            currentWorldAssets  := @WORLD_04_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_04_ASSETS) + 1;
            currentWorldImgPtrs := @W04_IMG_PTRS[0];
            currentWorldPalPtrs := @W04_PAL_PTRS[0];
            currentWorldColPtrs := @W04_COL_PTRS[0];
            currentWorldImgCount := W04_IMG_COUNT;
            currentWorldTiles := @W04_TILES[0];
            currentWorldTileWords := @W04_TILE_WORDS[0];
            currentWorldTileCount := W04_TILE_COUNT;
        end;
        5: begin
            Move(WORLD_05_DATA[0], world, SizeOf(TWorld));
            currentWorldData    := @WORLD_05_DATA[0];
            currentWorldAssets  := @WORLD_05_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_05_ASSETS) + 1;
            currentWorldImgPtrs := @W05_IMG_PTRS[0];
            currentWorldPalPtrs := @W05_PAL_PTRS[0];
            currentWorldColPtrs := @W05_COL_PTRS[0];
            currentWorldImgCount := W05_IMG_COUNT;
            currentWorldTiles := @W05_TILES[0];
            currentWorldTileWords := @W05_TILE_WORDS[0];
            currentWorldTileCount := W05_TILE_COUNT;
        end;
    end;
    FixWorldEndian(world);
end;

procedure InitWorld;
begin
    levelNum := world.start;
    if USE_DEBUG_FORCE_LEVEL and (worldCurrent = DEBUG_FORCE_WORLD) then
        levelNum := DEBUG_FORCE_LEVEL;
    flobX := world.flobx;
    if world.floby > SPAWN_Y_ADJUST then
        flobY := world.floby - SPAWN_Y_ADJUST
    else
        flobY := 0;
    flipped := false;
    if cheatmode then mySlime := $9999
        else mySlime := world.startingSlime;
    pickedSlimeCount := 0;
    gametime := 0;
    deadCount := 0;
    secretsFound := 0;
    mainGoalReached := false;
    msgDisplayCounter := 0;
    SetLanded;
    SetLandingSafe;
    room_landed := false;
    first_landed := false;
    teleported := false;
    landedTime := 0;
    doorReveal[0] := 0;
    doorReveal[1] := 0;
    FillChar(slimes,   SizeOf(slimes),   1);
    FillChar(goals,    SizeOf(goals),    1);
    FillChar(triggers, SizeOf(triggers), 1);
    // music load stub (sound not implemented yet)
end;

// ***************************************************
// *** FLOB MOVEMENT / PHYSICS (1:1 from original)
// ***************************************************

procedure FlobFootUpdate;
begin
    if flobDir = DIR_LEFT then begin
        flobFoot := flobX + 2;
        flobFace := flobX + 1;
    end;
    if flobDir = DIR_RIGHT then begin
        flobFoot := flobX + 3;
        flobFace := flobX + 4;
    end;
end;

procedure FlobAnimate(frame: byte);
begin
    flobFrame := frame;
    flobFrameDelay := ANIMATION_DELAY;
end;

procedure SetLanded;
begin
    lastLanded.lvl := levelNum;
    lastLanded.x := flobX;
    lastLanded.y := flobY;
    lastLanded.flipped := flipped;
end;

procedure SetLandingSafe;
begin
    Move(lastLanded, lastSafeLanded, SizeOf(TLastLanded));
end;

procedure FlobTurn(dir: byte);
begin
    flobDir := dir;
    flobFrame := 0;
    FlobFootUpdate;
    if IsSolidPix(GetPix(flobFoot, flobY)) then
        if not IsSolidPix(GetPix(flobFoot, flobY - 1)) then Dec(flobY);
end;

function CanMove(dir: byte): boolean;
begin
    Result := true;
    if flobY < 1 then begin Result := false; exit; end;
    if dir = DIR_LEFT then
        if flobX = LEFT_EDGE then begin Result := false; exit; end;
    if dir = DIR_RIGHT then
        if flobX = RIGHT_EDGE then begin Result := false; exit; end;
    if IsSolidPix(GetPix(flobFace, flobY - 3)) then begin Result := false; exit; end;
    if IsSolidPix(GetPix(flobFoot, flobY - 2)) then begin Result := false; exit; end;
    if IsSolidPix(GetPix(flobFoot, flobY - 1)) then
        if flobY > 1 then Dec(flobY)
        else begin Result := false; exit; end;
end;

procedure FlobMove(dir: byte);
var step: byte;
begin
    if flobDir <> dir then begin
        FlobTurn(dir);
        exit;
    end;
    for step := 1 to FLOB_MOVE_STEP do begin
        if not CanMove(dir) then
            break;
        if dir = DIR_LEFT then Dec(flobX) else Inc(flobX);
        FlobFootUpdate;
        flobFrame := FRAME_MOVE;
    end;
end;

procedure FlobFall;
var drop: byte;
    step: byte;
begin
    if flobFalling < $ff then Inc(flobFalling);
    if flobFalling > 4 then begin
        flobFrame := FRAME_FALL;
        drop := flobFalling shr 2;
        if drop > 4 then drop := 4;
        while drop > 0 do begin
            for step := 1 to FLOB_FALL_STEP do begin
                if (not IsSolidPix(GetPix(flobFoot, flobY))) or (flobY > 79) then
                    Inc(flobY)
                else
                    break;
            end;
            Dec(drop);
        end;
    end else begin
        for step := 1 to FLOB_FALL_STEP do begin
            if (not IsSolidPix(GetPix(flobFoot, flobY))) or (flobY > 79) then
                Inc(flobY)
            else
                break;
        end;
    end;
end;

// ***************************************************
// *** SPRITE LOGIC (1:1 from original)
// ***************************************************

procedure LoadSpritesData(bank: byte; addr: word);
var base: PByte;
    p: byte;
    frameCount: byte;
    h: byte;
    f: byte;
begin
    FillChar(spriteData, SizeOf(TSpriteData), 0);
    FillChar(spriteColorsRaw, SizeOf(spriteColorsRaw), 0);
    FillChar(spriteFramesRaw, SizeOf(spriteFramesRaw), 0);
    spriteStep[0] := 0;
    spriteStep[1] := 0;
    base := SpriteAssetPtr(addr);
    if base = nil then exit;

    spriteData.bank := bank;
    for p := 0 to 1 do spriteData.frameCount[p] := PByte(longint(base) + p)^;
    for p := 0 to 1 do spriteData.height[p] := PByte(longint(base) + 2 + p)^;

    base := PByte(longint(base) + 4);
    for p := 0 to 1 do begin
        frameCount := spriteData.frameCount[p];
        h := spriteData.height[p];
        if frameCount > 0 then spriteColorsRaw[p] := base
        else spriteColorsRaw[p] := nil;
        base := PByte(longint(base) + frameCount);
        if frameCount > 0 then
            for f := 0 to frameCount - 1 do
                spriteFramesRaw[p, f] := PByte(longint(base) + longint(f) * h);
        base := PByte(longint(base) + longint(frameCount) * h);
    end;
end;

procedure AnimateSprite(pnum: byte);
var stepPtr: word;
    anim: ^TAnimationStep;
    sx, sy, sf: byte;
    changed: boolean;
begin
    if (sysframe and sprites.frameSpeed[pnum]) = 0 then begin
        changed := false;
        anim := spriteAnimations[pnum];
        sf := spriteFrame[pnum];
        sx := sprites.x[pnum];
        sy := sprites.y[pnum];

        if sprites.moves[pnum] = MOVE_ANIMATE then begin
            Inc(sf);
            if sf >= spriteData.frameCount[pnum] then sf := 0;
            changed := true;
        end;

        if sprites.moves[pnum] = MOVE_ONPATH then begin
            if (spriteStep[pnum] = 0) or (anim^.times = 0) then begin
                stepPtr := sprites.param2[pnum] shl 8 + sprites.param1[pnum];
                stepPtr := stepPtr + word(spriteStep[pnum] shl 2);
                if LoadAnimationStepFromAsset(stepPtr, anim^) then begin
                    if anim^.times = 0 then
                        spriteStep[pnum] := 0
                    else
                        Inc(spriteStep[pnum]);
                end else begin
                    anim^.times := 0;
                    spriteStep[pnum] := 0;
                end;
            end;
            if anim^.times > 0 then begin
                if anim^.times = $ff then begin
                    Sfx(anim^.deltax);
                    anim^.times := 0;
                end else begin
                    Dec(anim^.times);
                    sx := sx + anim^.deltaX * WORLD_SPRITE_MOVE_STEP;
                    sy := sy + anim^.deltaY * WORLD_SPRITE_MOVE_STEP;
                    if (anim^.deltaFrame and $f0) = $70 then sf := anim^.deltaFrame and $0f
                        else sf := sf + anim^.deltaFrame;
                    if sf = spriteData.frameCount[pnum] then sf := 0;
                    if sf = $ff then sf := spriteData.frameCount[pnum] - 1;
                    changed := true;
                end;
            end;
        end;

        if sprites.moves[pnum] = MOVE_NONE then begin
            if spriteTargetFrame[pnum] < sf then begin
                Dec(sf);
                changed := true;
            end;
            if spriteTargetFrame[pnum] > sf then begin
                Inc(sf);
                changed := true;
            end;
        end;

        if changed then begin
            spriteFrame[pnum] := sf;
            sprites.x[pnum] := sx;
            sprites.y[pnum] := sy;
        end;
    end;
end;

// ***************************************************
// *** SLIMES / PICKUPS (1:1 from original)
// ***************************************************

procedure PickedAllSlimes;
begin
    AddSlime(word($2000));
end;

procedure PickSlime(pick: byte);
begin
    if pick > 19 then exit;
    if slimeX[pick] = 0 then exit;
    Sfx(SFX_SLIMEPICK);
    sfxDelay := 0;
    slimeX[pick] := 0;
    WaitFrame;
    PMG_hitclr := $ff;
    slimes[slimeGoal[pick]] := 0;
    AddSlime(byte($50));
    Inc(pickedSlimeCount);
    if pickedSlimeCount = world.totalSlimeCount then PickedAllSlimes;
end;

function SpriteCollisionRect(num: byte; out x, y, w, h: byte): boolean;
var frameCount: byte;
    yy: byte;
begin
    Result := false;
    x := 0; y := 0; w := 0; h := 0;
    if num > 1 then exit;
    if sprites.state = SPRITE_NONE then exit;
    if (num = 1) and (sprites.state <= SPRITE_SINGLE) then exit;
    if (sprites.stype[num] = STYPE_EXIT) and not mainGoalReached then exit;
    if ((sprites.stype[num] = STYPE_DECOR) or (sprites.stype[num] = STYPE_GOAL)) and
        (sprites.goal[num] <> NONE) and (goals[sprites.goal[num]] = 0) then exit;
    if (sprites.stype[num] = STYPE_DIAL) and
        (sprites.param2[num] <> $ff) and (goals[sprites.param2[num]] > 0) then exit;

    frameCount := spriteData.frameCount[num];
    if frameCount = 0 then exit;

    x := sprites.x[num];
    if (num = 1) and (sprites.state = SPRITE_COMBINED) then
        x := x + sprites.gap;
    yy := sprites.y[num];
    h := spriteData.height[num];
    if flipped and (sprites.flipable[num] = 1) then
        yy := 80 - (h + yy);
    y := yy;
    w := 8;
    Result := true;
end;

function RectsOverlap(ax, ay, aw, ah, bx, by, bw, bh: byte): boolean;
begin
    Result := (ax < bx + bw) and (bx < ax + aw) and
              (ay < by + bh) and (by < ay + ah);
end;

procedure CheckSpriteCollisions;
var fx, fy, fw, fh: byte;
    sx, sy, sw, sh: byte;
    p: byte;
begin
    fx := flobX;
    fy := flobY;
    fw := 8;
    fh := 8;
    for p := 0 to 1 do begin
        if not SpriteCollisionRect(p, sx, sy, sw, sh) then
            continue;
        if RectsOverlap(fx, fy, fw, fh, sx, sy, sw, sh) then begin
            Collided(p);
            exit;
        end;
    end;
end;

procedure CheckSlimeCollision;
var i: byte;
    flobScreenX, flobScreenY: integer;
    slimeScreenX, slimeScreenY: integer;
    rowY: integer;
begin
    flobScreenX := integer(flobX) * LEVEL_SCALE_X + 8;
    flobScreenY := integer(flobY) * LEVEL_SCALE_Y + FLOB_RENDER_OFFSET_Y;
    for i := 0 to 19 do begin
        if slimeX[i] = 0 then
            continue;

        rowY := i shl 2;
        if flipped then
            rowY := 76 - rowY;

        slimeScreenX := integer(slimeX[i]) * LEVEL_SCALE_X + SLIME_RENDER_OFFSET_X;
        slimeScreenY := rowY * LEVEL_SCALE_Y + SLIME_RENDER_OFFSET_Y;

        if (abs(slimeScreenX - flobScreenX) <= 8) and
           (abs(slimeScreenY - flobScreenY) <= 10) then begin
            PickSlime(i);
            exit;
        end;
    end;
end;

function FlobTouchesDangerColor: boolean;
begin
    Result := false;
end;

// ***************************************************
// *** EXPLOSION / DEATH (1:1 from original)
// ***************************************************

procedure Explode;
begin
    FSfx(SFX_DEAD);
    sfxDelay := 0;
    ClearFlob;
    flobFrame := FRAME_POOF1;
    BeginQueuedSpritesFrame;
    DrawFlob;
    PresentQueuedSprites;
    WaitFrames(5);
    ClearFlob;
    flobFrame := FRAME_POOF2;
    BeginQueuedSpritesFrame;
    DrawFlob;
    PresentQueuedSprites;
    WaitFrames(5);
    flobFrame := FRAME_XPLODE;
    WaitFrames(30);
    SubSlime($70);
    SubSlime($80);
    WaitFrames(50);
    PMG_Clear;
    exploded := true;
    Inc(deadCount);
end;

// ***************************************************
// *** KEY / DIAL / SPRITE INTERACTION (1:1 from original)
// ***************************************************

procedure KeyTaken(pnum: byte);
begin
    if sprites.moves[pnum] <> MOVE_ONPATH then begin
        spriteTargetFrame[pnum] := spriteData.frameCount[pnum] - 1;
        if sprites.param1[pnum] <> NONE then doorReveal[pnum] := 30;
    end else begin
        if sprites.frameOn[pnum] <> NONE then doorReveal[pnum] := 30;
    end;
    goals[sprites.goal[pnum]] := 0;
end;

procedure TurnDial(pnum: byte);
var g, dg: byte;
begin
    if actionDelay > 0 then exit;
    dg := 1;
    g := goals[sprites.goal[pnum]] + 1;
    if g > sprites.frameOff[pnum] then g := sprites.frameOn[pnum];
    if g = sprites.frameSpeed[pnum] then dg := 0;
    spriteTargetFrame[pnum] := g;
    goals[sprites.goal[pnum]] := g;
    goals[sprites.param1[pnum]] := dg;
    Sfx(SFX_BEEP);
    actionDelay := DIAL_DELAY;
end;

// ***************************************************
// *** TRIGGERS / CONDITIONS / EVENTS (1:1 from original)
// ***************************************************

function GoalsUpTo(topgoal: byte): boolean;
var goal: byte;
begin
    Result := true;
    for goal := 0 to topgoal do if goals[goal] > 0 then Result := false;
end;

function CheckCondition(condition, param: byte): boolean;
begin
    Result := false;
    case condition of
        ALWAYS:             Result := true;
        ON_GOAL:            Result := goals[param] = 0;
        ON_NO_GOAL:         Result := goals[param] > 0;
        ON_GOALS_UP_TO:     Result := GoalsUpTo(param);
        ON_NO_GOALS_UP_TO:  Result := not GoalsUpTo(param);
        ON_ACHIEVEMENT:     Result := achievements[param] > 0;
        ON_NO_ACHIEVEMENT:  Result := achievements[param] = 0;
    end;
end;

function ConditionTrigger(id, condition, param: byte): boolean;
begin
    if condition = ONCE then begin
        Result := triggers[id] > 0;
        triggers[id] := 0;
    end else Result := CheckCondition(condition, param);
end;

procedure ShowMessage(msg, mtype, count: byte);
begin
    msgDisplayCounter := count;
    msgDisplayType := mtype;
    displayPaletteDirty := true;
    ClearTxt2;
    if msg <= High(messages) then begin
        currentMessageLines[0] := DecodeWorldTextLine(messages[msg], 0);
        currentMessageLines[1] := DecodeWorldTextLine(messages[msg], 1);
    end;
end;

procedure LaunchTrigger(id, action, target, actparam, param: byte);
begin
    case action of
        SHOW_MSG:   ShowMessage(target, messageTypes[target], actparam);
        REACH_GOAL: begin
            if goals[target] > 0 then goals[target] := 0;
            if target > SECRETS_OFFSET then Inc(secretsFound);
        end;
        CLEAR_GOAL: begin
            if goals[target] = 0 then goals[target] := 1;
        end;
        TELEPORT_ME: Teleport(param, target, actparam);
        SHOW_SCENE:  ShowScene(target);
    end;
end;

procedure CheckTrigger(t: byte);
var fy: byte;
begin
    fy := flobY;
    if flipped then fy := 82 - fy;
    if flobX < roomTriggers[t, 1] then exit;
    if fy   < roomTriggers[t, 2] then exit;
    if flobX > roomTriggers[t, 3] then exit;
    if fy   > roomTriggers[t, 4] then exit;
    if not ConditionTrigger(roomTriggers[t, 0], roomTriggers[t, 5], roomTriggers[t, 6]) then exit;
    LaunchTrigger(roomTriggers[t, 0], roomTriggers[t, 7], roomTriggers[t, 8], roomTriggers[t, 9], roomTriggers[t, 6]);
end;

procedure CheckEvents;
var t: byte;
begin
    if doorReveal[0] > 0 then RevealCountdown(0);
    if doorReveal[1] > 0 then RevealCountdown(1);

    t := triggerCount;
    while t > 0 do begin
        Dec(t);
        if triggers[roomTriggers[t, 0]] > 0 then CheckTrigger(t);
    end;

    if msgDisplayCounter > 0 then begin
        Dec(msgDisplayCounter);
        topBarForeground := sysframe shr 1;
        if msgDisplayType = MSG_INFO then
            topBarForeground := ((topBarForeground shr 1) and 7) + 8;
        displayPaletteDirty := true;
        if msgDisplayCounter = 0 then begin
            ClearTxt2;
            displayPaletteDirty := true;
        end;
    end;

    if gametime and $7f = 0 then SubSlime(1);
end;

// ***************************************************
// *** SPRITE COLLISION (1:1 from original)
// ***************************************************

procedure Collided(pnum: byte);
var goal: byte;
    stype: byte;
begin
    if sprites.state = SPRITE_COMBINED then pnum := 0;
    stype := sprites.stype[pnum];
    goal  := goals[sprites.goal[pnum]];

    case stype of
        STYPE_ENEMY: begin Explode; exit; end;
        STYPE_DIAL:  begin TurnDial(pnum); exit; end;
        STYPE_PORTAL: begin SpriteTeleport(pnum); exit; end;
        STYPE_STATS:  begin
            if actionDelay = 0 then begin
                FadeOut;
                ShowStats;
                PMG_Clear;
                InitLevelScreen;
                LoadLevel(levelNum);
                SetLevelColors;
                DrawSlimes;
                ShowSlime;
                ShowSprites;
                if flipped then ReverseDlist;
                BlackAll;
                WaitFrame;
                FadeIn;
                statsOn := true;
            end;
            actionDelay := 150;
        end;
        STYPE_KEY: begin
            if goal > 0 then begin
                if (sprites.param2[pnum] <> NONE) and (sprites.moves[pnum] <> MOVE_ONPATH) then
                    FSfx(sprites.param2[pnum]);
                KeyTaken(pnum);
            end;
        end;
        STYPE_SLIME: begin
            if goal > 0 then begin
                FSfx(SFX_BIGSLIME);
                AddSlime(word(word(sprites.param2[pnum] shl 8) + word(sprites.param1[pnum])));
                ClearSprites;
                sprites.state := SPRITE_NONE;
            end;
        end;
        STYPE_GOAL: begin
            if goal > 0 then begin
                FSfx(SFX_PICKGOAL);
                mainGoalReached := true;
                if sprites.state = SPRITE_COMBINED then ClearSprites
                else ClearSprite(pnum);
            end;
        end;
        STYPE_EXIT: begin
            if mainGoalReached then EndWorld;
        end;
    end;

    if goal > 0 then begin
        Dec(goal);
        goals[sprites.goal[pnum]] := goal;
    end;
end;

// ***************************************************
// *** TELEPORT (1:1 from original)
// ***************************************************

procedure Teleport(lvl, x, y: byte);
begin
    Sfx(SFX_TELEPORT);
    FadeOut;
    levelNum := lvl;
    flobX := x;
    flobY := y;
    flipped := false;
    OrderDlist;
    room_changed := true;
    teleported := true;
end;

procedure SpriteTeleport(pnum: byte);
begin
    Teleport(sprites.goal[pnum], sprites.frameOn[pnum], sprites.frameOff[pnum]);
end;

procedure InitFlobPMG;
begin
    PMG_Clear;
    pmgColors[0] := MapColor(FLOB_COL0);
    pmgColors[1] := MapColor(FLOB_COL1);
    PMG_sizep0 := 0;
    PMG_sizep1 := 0;
end;

// ***************************************************
// *** LEVEL DRAW (1:1 from original)
// ***************************************************

procedure DrawLevel;
var lvlptr: byte;
    id, p, goal, goalv: byte;
    cmd, x, y: byte;
    addr: word;
    cmdCount: word;
begin
    FillChar(slimeX,   SizeOf(slimeX),   0);
    FillChar(slimeGoal, SizeOf(slimeGoal), 0);
    FillChar(messages, SizeOf(messages), 0);
    FillChar(messageTypes, SizeOf(messageTypes), 0);
    lvlptr := 0;
    cmdCount := 0;
    triggerCount := 0;
    msgCount := 0;
    sceneCount := 0;
    colorCollision := true;
    repeat
        Inc(cmdCount);
        if DEBUG_DRAWLEVEL and (cmdCount > 255) then begin
            DebugShowOverlay(
                'DrawLevel watchdog',
                'Too many commands',
                'lvlptr=' + ByteToStr(lvlptr),
                'first=' + HexByte(leveldata[0]) + ' ' + HexByte(leveldata[1]) + ' ' +
                    HexByte(leveldata[2]) + ' ' + HexByte(leveldata[3]),
                'possible loop in stream');
            exit;
        end;
        cmd := leveldata[lvlptr];
        case cmd of
            IMAGE_LZ4: begin
                if DEBUG_DRAWLEVEL then
                    DebugShowOverlay(
                        'DrawLevel IMAGE_LZ4',
                        'lvlptr=' + ByteToStr(lvlptr),
                        'img=' + ByteToStr(leveldata[lvlptr + 1]),
                        'cmd=' + HexByte(cmd),
                        'before LoadImage');
                LoadImage(leveldata[lvlptr + 1]);
                CopyPlayfieldArea(SCREEN_PHY, SCREEN_LOG);
                Inc(lvlptr, 2);
            end;
            COLOR_COLLISION_OFF: begin
                colorCollision := false;
                Inc(lvlptr);
            end;
            PUT_SLIME: begin
                goal := slimes[leveldata[lvlptr + 3]];
                if goal > 0 then begin
                    slimeX[leveldata[lvlptr + 2]]    := leveldata[lvlptr + 1];
                    slimeGoal[leveldata[lvlptr + 2]]  := leveldata[lvlptr + 3];
                end;
                Inc(lvlptr, 4);
            end;
            PUT_SPRITES: begin
                LoadSpritesData(world.assetBank,
                    leveldata[lvlptr + 1] + (word(leveldata[lvlptr + 2]) shl 8));
                Move(leveldata[lvlptr + 3], sprites, SizeOf(TSprites));
                for p := 0 to 1 do begin
                    spriteFrame[p] := sprites.frameOn[p];
                    if sprites.stype[p] = STYPE_PORTAL then spriteFrame[p] := 0;
                    if sprites.stype[p] = STYPE_KEY then begin
                        if sprites.moves[p] = MOVE_ONPATH then spriteFrame[p] := 0;
                        if goals[sprites.goal[p]] = 0 then spriteFrame[p] := sprites.frameOff[p];
                    end;
                    if sprites.stype[p] = STYPE_DIAL then
                        spriteFrame[p] := goals[sprites.goal[p]];
                    spriteTargetFrame[p] := spriteFrame[p];
                end;
                if sprites.stype[0] = STYPE_SLIME then
                    if goals[sprites.goal[0]] = 0 then sprites.state := SPRITE_NONE;
                Inc(lvlptr, SizeOf(TSprites) + 3);
            end;
            PUT_TILE: begin
                goalv := leveldata[lvlptr + 1];
                goal  := leveldata[lvlptr + 2];
                if CheckCondition(goalv, goal) then begin
                    x    := leveldata[lvlptr + 3];
                    y    := leveldata[lvlptr + 4];
                    addr := leveldata[lvlptr + 5] + (word(leveldata[lvlptr + 6]) shl 8);
                    PutTile(x, y, addr, 0);
                end;
                Inc(lvlptr, 7);
            end;
            SET_TRIGGER: begin
                id := leveldata[lvlptr + 1];
                if triggers[id] > 0 then ArmTrigger(lvlptr + 1);
                Inc(lvlptr, 11);
            end;
            SET_MESSAGE: begin
                messageTypes[msgCount] := leveldata[lvlptr + 1];
                messages[msgCount] := leveldata[lvlptr + 2] + (word(leveldata[lvlptr + 3]) shl 8);
                Inc(msgCount);
                Inc(lvlptr, 4);
            end;
            SET_SCENE: begin
                sceneImg[sceneCount]  := leveldata[lvlptr + 1];
                sceneMsg[sceneCount]  := leveldata[lvlptr + 2] + (word(leveldata[lvlptr + 3]) shl 8);
                sceneCol0[sceneCount] := leveldata[lvlptr + 4];
                sceneCol1[sceneCount] := leveldata[lvlptr + 5];
                sceneCol2[sceneCount] := leveldata[lvlptr + 6];
                Inc(sceneCount);
                Inc(lvlptr, 7);
            end;
            SET_COLORS: begin
                goalv := leveldata[lvlptr + 1];
                goal  := leveldata[lvlptr + 2];
                if CheckCondition(goalv, goal) then begin
                    level.colors[0] := leveldata[lvlptr + 3];
                    level.colors[1] := leveldata[lvlptr + 4];
                    level.colors[2] := leveldata[lvlptr + 5];
                    level.colors[3] := leveldata[lvlptr + 6];
                    Move(level.colors[0], levelRawColors[0], 4);
                    RebuildRoomPalette;
                end;
                Inc(lvlptr, 7);
            end;
            LEVEL_END: ;
        else
            if DEBUG_DRAWLEVEL then
                DebugShowOverlay(
                    'DrawLevel bad cmd',
                    'cmd=' + HexByte(cmd),
                    'lvlptr=' + ByteToStr(lvlptr),
                    'bytes=' + HexByte(leveldata[lvlptr]) + ' ' +
                        HexByte(leveldata[lvlptr + 1]) + ' ' +
                        HexByte(leveldata[lvlptr + 2]) + ' ' +
                        HexByte(leveldata[lvlptr + 3]),
                    'stream invalid');
            exit;
        end;
    until cmd = LEVEL_END;
    DrawTestBigSlime;
end;

procedure SetLevelColors;
begin
    Move(levelRawColors[0], levelColors[0], 4);
    pmgColors[0] := MapColor(FLOB_COL0);
    pmgColors[1] := MapColor(FLOB_COL1);
    RebuildRoomPalette;
    // Apply the level image palette to the STE hardware immediately.
    // BackToLevel and Teleport manage their own BlackAll/FadeIn sequence;
    // this path is for normal room changes where the level should snap in.
    displayPaletteDirty := true;
    UpdateDisplayPaletteIfNeeded(true);
end;

procedure AdjustFlobPosition;
var sx, sy, checkDist, pix: byte;
begin
    sx := flobX;
    sy := flobY;
    checkDist := 0;
    repeat
        pix := GetPix(flobFoot, flobY - 1);
        if not IsSolidPix(pix) then exit;
        if flobY > 3 then Dec(flobY);
        Inc(checkDist);
        FlobFootUpdate;
    until checkDist > 10;

    flobY := sy;
    checkDist := 1;
    repeat
        flobX := sx - checkDist;
        FlobFootUpdate;
        pix := GetPix(flobFoot, flobY - 1);
        if (not IsSolidPix(pix)) and (flobX > LEFT_EDGE) then exit;
        flobX := sx + checkDist;
        FlobFootUpdate;
        pix := GetPix(flobFoot, flobY - 1);
        if (not IsSolidPix(pix)) and (flobX < RIGHT_EDGE) then exit;
        Inc(checkDist);
    until checkDist = 10;

    flobX := sx;
    FlobFootUpdate;
end;

procedure LoadLevel(lvl: byte);
var fileOffset: word;
    cmdBytes: word;
begin
    WaitFrame;
    if currentWorldData = nil then begin
        if DEBUG_LOADLEVEL then
            DebugShowOverlay(
                'LoadLevel error',
                'currentWorldData=nil',
                'world=' + ByteToStr(worldCurrent),
                'lvl=' + ByteToStr(lvl),
                'LoadWorld missing');
        exit;
    end;
    fileOffset := world.lvlPtr[lvl] - $A000;
    if DEBUG_LOADLEVEL then
        DebugShowOverlay(
            'LoadLevel start',
            'world=' + ByteToStr(worldCurrent) + ' lvl=' + ByteToStr(lvl),
            'ptr=' + HexWord(world.lvlPtr[lvl]) + ' off=' + WordToStr(fileOffset),
            'start=' + ByteToStr(world.start) + ' state=' + ByteToStr(world.state),
            'name=' + Antic2Ascii(world.name));
    if (world.lvlPtr[lvl] < $A000) or (fileOffset >= 8192) then begin
        if DEBUG_LOADLEVEL then
            DebugShowOverlay(
                'LoadLevel bad ptr',
                'ptr=' + HexWord(world.lvlPtr[lvl]),
                'off=' + WordToStr(fileOffset),
                'world=' + ByteToStr(worldCurrent),
                'lvl=' + ByteToStr(lvl));
        exit;
    end;
    Move(currentWorldData[fileOffset], level, SizeOf(TLevel));
    Move(level.colors[0], levelRawColors[0], 4);
    cmdBytes := MAX_LEVEL_DATA;
    if fileOffset + SizeOf(TLevel) + cmdBytes > 8192 then
        cmdBytes := 8192 - fileOffset - SizeOf(TLevel);
    Move(currentWorldData[fileOffset + SizeOf(TLevel)], leveldata[0], cmdBytes);
    if DEBUG_LOADLEVEL then
        DebugShowOverlay(
            'LoadLevel header',
            'colors=' + HexByte(level.colors[0]) + ' ' + HexByte(level.colors[1]) + ' ' +
                HexByte(level.colors[2]) + ' ' + HexByte(level.colors[3]),
            'exits=' + HexByte(level.room_top) + ' ' + HexByte(level.room_right) + ' ' +
                HexByte(level.room_bottom) + ' ' + HexByte(level.room_left),
            'cmd=' + HexByte(leveldata[0]) + ' ' + HexByte(leveldata[1]) + ' ' +
                HexByte(leveldata[2]) + ' ' + HexByte(leveldata[3]),
            'bytes=' + WordToStr(cmdBytes));

    sprites.state := SPRITE_NONE;
    if room_changed then begin
        doorReveal[0] := 0;
        doorReveal[1] := 0;
        if flobX = RIGHT_EDGE then flobX := LEFT_EDGE + START_EDGE_OFFSET
        else if flobX = LEFT_EDGE then flobX := RIGHT_EDGE - START_EDGE_OFFSET;
        if flobY >= BOTTOM_EDGE then flobY := TOP_EDGE;
    end;
    FlobFootUpdate;
    game_over := false;
    exploded := false;
    actionDelay := 0;
    spritePtr[0] := 0;
    spritePtr[1] := 0;
    DrawLevel;
    SwapScreen;
    CopyPlayfieldArea(SCREEN_PHY, SCREEN_LOG);
    CopyPlayfieldArea(SCREEN_PHY, SCREEN_BKG);
    RefreshHudCache;
    if flipped then ReverseDlist
    else OrderDlist;
    FillChar(queuedSpriteCount, SizeOf(queuedSpriteCount), 0);
    if room_changed then AdjustFlobPosition;
    room_changed := false;
    room_landed := false;
    first_landed := false;
    landedTime := 0;
end;

// ***************************************************
// *** FLIP (1:1 from original)
// ***************************************************

procedure Flip;
var stepPauses: array[0..5] of byte;
    step: byte;
    upside: boolean;
begin
    stepPauses[0] := 1; stepPauses[1] := 1; stepPauses[2] := 1;
    stepPauses[3] := 1; stepPauses[4] := 2; stepPauses[5] := 3;
    Sfx(SFX_FLIP);
    step := 0;
    upside := false;
    WaitFrame;
    ClearFlob;
    ClearSlimes;
    repeat
        // stub: Display List row reordering happens here
        if not upside then Inc(step);
        if step = 6 then begin
            flipped := not flipped;
            if flipped then ReverseDlist
            else OrderDlist;
            upside := true;
        end;
        if upside then Dec(step);
        ClearSprites;
        if step < 6 then WaitFrames(stepPauses[step]);
    until step = $ff;
    WaitFrame;
    ShowSprites;
    flobY := 84 - flobY;
    BeginQueuedSpritesFrame;
    DrawFlob;
    PresentQueuedSprites;
    if flobFalling > 0 then flobFalling := 1;
    SubSlime(5);
end;

procedure BackToLevel;
begin
    BlackAll;               // palette black before image swap → no colour flash
    LoadLevel(levelNum);    // decompresses to SCREEN_LOG, SwapScreen; palette stays black
    ShowSprites;
    BeginQueuedSpritesFrame;
    DrawFlob;
    PresentQueuedSprites;
    WaitFrame;
    ShowLevelName;
    if flipped then ReverseDlist
    else OrderDlist;
    ClearTxt2;
    PMG_hitclr := $ff;
    FadeIn;                 // reads black palette, fades to currentPal ✓
end;

procedure Reveal(rgoal, room: byte);
var times: byte;
    wasflipped: boolean;
begin
    FadeOut;
    WaitFrame;
    PMG_Clear;
    wasflipped := flipped;
    flipped := false;
    OrderDlist;
    goals[rgoal] := 0;
    LoadLevel(room);
    goals[rgoal] := 1;
    LoadLevel(room);
    goals[rgoal] := 0;
    ShowSprites;
    BlackAll;
    topBarForeground := 0;
    WaitFrame;
    FSfx(SFX_REVEAL);
    sfxDelay := 0;
    FadeIn;
    times := 3;
    repeat
        WaitFrames(20);
        WaitFrames(20);
        Dec(times);
    until times = 0;
    WaitFrames(50);
    FadeOut;
    WaitFrame;
    PMG_Clear;
    flipped := wasflipped;
    BackToLevel;
end;

procedure RevealCountdown(pnum: byte);
begin
    if sprites.stype[pnum] <> STYPE_KEY then exit;
    if sprites.moves[pnum] <> MOVE_ONPATH then begin
        if spriteTargetFrame[pnum] = spriteFrame[pnum] then begin
            Dec(doorReveal[pnum]);
            if doorReveal[pnum] = 0 then Reveal(sprites.goal[pnum], sprites.param1[pnum]);
        end;
    end else begin
        Dec(doorReveal[pnum]);
        if doorReveal[pnum] = 0 then Reveal(sprites.goal[pnum], sprites.frameOn[pnum]);
    end;
end;

// ***************************************************
// *** WORLD / LEVEL NAVIGATION (1:1 from original)
// ***************************************************

procedure NextLevel(dir: byte);
var nextRoom: byte;
begin
    nextRoom := ROOM_NONE;
    case dir of
        DIR_TOP:    nextRoom := level.room_top;
        DIR_RIGHT:  nextRoom := level.room_right;
        DIR_BOTTOM: nextRoom := level.room_bottom;
        DIR_LEFT:   nextRoom := level.room_left;
    end;
    if nextRoom = ROOM_ENTRANCE then exit;
    if nextRoom = ROOM_NONE then exit;
    levelNum := nextRoom;
    room_changed := true;
end;

// ***************************************************
// *** STATS SCREEN (1:1 from original, display stubs)
// ***************************************************

procedure ShowStats;
var page, key: byte;
    update: boolean;
    off: byte;

    procedure ShowInt(i: cardinal); begin end; // stub – real impl writes to screen
    procedure ShowTime(i: cardinal); begin end; // stub
begin
    page := worldCurrent;
    update := true;
    CountGlobalStats;
    repeat
        joy := stick0;
        key := NONE;
        if (skstat and 4 = 0) then key := kbcode;

        if page > 0 then
            if (key = KEY_LEFT_CODE) then begin Dec(page); update := true; end;
        if page < WORLD_COUNT then
            if (key = KEY_RIGHT_CODE) then begin Inc(page); update := true; end;

        if update then begin
            if page < WORLD_COUNT then begin
                statBestsBack := STAT_ON + 4;
                statGlobalBack := STAT_OFF;
                LoadWorld(page);
                GetWorldStats(page);
                s1 := world.name;
            end else begin
                statBestsBack  := STAT_OFF;
                statGlobalBack := STAT_ON + 4;
                s1 := 'Total Game Stats';
            end;
            update := false;
        end;
        WaitFrame;
    until IsStartingButtonDown;
    LoadWorld(worldCurrent);
    WaitForStartKeyUp;
end;

// ***************************************************
// *** END WORLD (1:1 from original, display stubs)
// ***************************************************

procedure EndWorld;
var sec, score: word;
    n, shift: byte;
    mul, mask: cardinal;
    mastered: boolean;
begin
    FadeOut;
    StopSong;
    GetWorldStats(worldCurrent);
    worldStats.attempts := worldStats.attempts + 1;
    mastered := true;

    if mainGoalReached then begin
        s := 'Congratulations!';
        worldStats.winCount := worldStats.winCount + 1;
    end else begin
        s := 'Game Over';
        worldStats.failCount := worldStats.failCount + 1;
    end;

    sec := gametime div 50;
    if mainGoalReached then begin
        if sec < worldStats.bestTime then worldStats.bestTime := sec;
        if sec < world.timeTreshold  then Inc(worldStats.speedRunsCount);
    end;
    worldStats.totalTime := worldStats.totalTime + sec;

    mul := 10000000;
    score := 0;
    mask := $F0000000;
    shift := 8;
    repeat
        Dec(shift);
        n := (mySlime and mask) shr (shift shl 2);
        score := score + word(n * mul);
        mul := mul div 10;
        mask := mask shr 4;
    until shift = 0;

    if score > worldStats.bestScore then worldStats.bestScore := score;
    worldStats.totalScore := worldStats.totalScore + score;

    if pickedSlimeCount > worldStats.maxSlimes then worldStats.maxSlimes := pickedSlimeCount;
    worldStats.totalSlimes := worldStats.totalSlimes + pickedSlimeCount;

    if deadCount > worldStats.maxDeaths then worldStats.maxDeaths := deadCount;
    if mainGoalReached then
        if deadCount < worldStats.minDeaths then worldStats.minDeaths := deadCount;
    worldStats.totalDeaths := worldStats.totalDeaths + deadCount;

    if secretsFound > worldStats.maxSecrets then worldStats.maxSecrets := secretsFound;
    if secretsFound = world.secretsCount then worldStats.secretAllCount := worldStats.secretAllCount + 1
    else mastered := false;

    if mainGoalReached then begin
        if deadCount = 0 then worldStats.flawlessCount := worldStats.flawlessCount + 1
        else mastered := false;
        if pickedSlimeCount = world.totalSlimeCount then Inc(worldStats.pickAllCount)
        else mastered := false;
    end else mastered := false;

    if mastered then Inc(worldStats.mastersCount);

    SetWorldStats(worldCurrent);
    if not cheatmode then begin
        CheckAchievements;
        StoreStats;
    end;

    PlaySong(MUSIC_ENDGAME);
    repeat until IsStartingButtonDown;
    WaitForStartKeyUp;

    if (worldCurrent = 5) and mainGoalReached then begin
        ShowCutScene(OUTRO_BANK, OUTRO_IMAGE_COUNT);
        ShowCredits;
    end;
    if newAchivements > 0 then ShowAchievements;

    game_over := true;
    StopSong;
end;

// ***************************************************
// *** CUTSCENE / CREDITS (1:1 from original, stubs)
// ***************************************************

procedure ShowCutScene(csbank, cscount: byte);
var slide: byte;
    slideDelay: word;
    visibleLines: byte;
    cutsceneHold: boolean;
    c0, c1, c2, bg: byte;
    l0, l1, l2, l3: string;
begin
    WaitFrame;
    StopSong;
    BlackAll;
    slide := 0;
    WaitFrame;
    PlaySong(0);
    repeat
        FillChar(messageTypes, SizeOf(messageTypes), 0);
        LoadCutsceneSlide(slide, csbank);
        PresentCutsceneSlide;
        GetCutsceneText(csbank, slide, c0, c1, c2, bg, l0, l1, l2, l3);
        RebuildCutscenePalette(c0, c1, c2, bg);
        FadeIn;
        visibleLines := 0;
        slideDelay := 18;
        cutsceneHold := false;
        repeat
            if slideDelay = 0 then begin
                if visibleLines < 4 then begin
                    Inc(visibleLines);
                    RenderCutsceneText(SCREEN_PHY, l0, l1, l2, l3, visibleLines);
                    slideDelay := 22;
                end else if not cutsceneHold then begin
                    cutsceneHold := true;
                    slideDelay := 300;
                end;
            end;
            if slideDelay > 0 then
                Dec(slideDelay);
            WaitFrame;
        until (cutsceneHold and (slideDelay = 0)) or IsStartingButtonDown;
        if IsStartingButtonDown then break;
        FadeOut;
        Inc(slide);
    until (slide = cscount) or IsStartingButtonDown;
    WaitForStartKeyUp;
    WaitFrame;
end;

procedure ShowCredits;
begin
    ShowCutScene(CREDITS_BANK, 8);
end;

procedure ShowScene(scene: byte);
begin
    WaitFrame;
    FadeOut;
    FillChar(messageTypes, SizeOf(messageTypes), $0a);
    level.colors[0] := sceneCol0[scene];
    level.colors[1] := sceneCol1[scene];
    level.colors[2] := sceneCol2[scene];
    Move(level.colors[0], levelRawColors[0], 3);
    FillChar(levelColors, 3, 0);
    RebuildRoomPalette;
    LoadImage(sceneImg[scene]);
    WaitFrame;
    FadeIn;
    repeat
        WaitFrame;
    until IsStartingButtonDown;
    WaitForStartKeyUp;
    WaitFrame;
    FadeOut;
    BackToLevel;
end;

// ***************************************************
// *** ACHIEVEMENTS SCREEN
// ***************************************************

procedure ShowAchievements;
const
    // ST palette: $0RGB, each component 0-7 (standard 3-bit ST format)
    ACH_PAL: array[0..15] of word = (
        $000,  //  0 – black background
        $777,  //  1 – white  (title text)
        $050,  //  2 – green  (achievement earned)
        $222,  //  3 – dark   (achievement locked)
        $440,  //  4 – yellow (newly earned flash – cleared to 2 below)
        $444,  //  5 – medium gray (world-row label text)
        $333,  //  6 – dark separator bar color
        $555,  //  7 – light gray  (footer text)
        $000, $000, $000, $000, $000, $000, $000, $000
    );
    // Grid geometry – all x coords are multiples of 16 (one bitplane group)
    GRID_LEFT  = 64;   // pixels from left edge; leaves 64px for row labels
    GRID_TOP   = 36;   // first row top pixel
    CELL_W     = 16;   // width per achievement cell (= one bitplane group)
    CELL_H     = 14;   // fill height inside row
    ROW_STRIDE = 16;   // CELL_H + 2px black gap between rows
    // Row labels (7 strings, max 7 chars each to fit in 64px at 8px/char)
    ROW_LABELS: array[0..6] of string[7] = (
        'WORLD 1', 'WORLD 2', 'WORLD 3',
        'WORLD 4', 'WORLD 5', 'WORLD 6',
        'GLOBAL '
    );
var
    w, a, aid: byte;
    cx, cy:    word;
    col:       word;
begin
    FadeOut;

    // ---- build back buffer ------------------------------------------------
    ClearScreen(SCREEN_LOG);

    // Title line
    Str(achivementsCount, s1);
    Str(ACHIEVEMENTS_COUNT, s);
    s := 'ACHIEVEMENTS  ' + s1 + ' / ' + s;
    DrawStrCentered(6, 1, s);

    // Thin separator under title
    FillRect16(SCREEN_LOG, 0, 26, 320, 2, 6);

    // Achievement grid
    aid := 0;
    for w := 0 to WORLD_COUNT do begin
        cy := GRID_TOP + word(w) * ROW_STRIDE;

        // Row label on the left (truncated to 7 chars so it stays < 64px)
        DrawStr(2, cy, 5, ROW_LABELS[w]);

        for a := 0 to 11 do begin
            cx := GRID_LEFT + word(a) * CELL_W;

            // Mark newly earned → earned, pick display color
            if achievements[aid] = 2 then begin
                achievements[aid] := 1;
                col := 4;   // yellow flash for newly earned
            end else if achievements[aid] = 1 then
                col := 2    // green
            else
                col := 3;   // dark gray (locked)

            FillRect16(SCREEN_LOG, cx, cy, CELL_W, CELL_H, col);
            Inc(aid);
        end;
    end;

    // Footer
    DrawStrCentered(186, 7, 'FIRE  /  SPACE  to close');

    // ---- show with fade-in ------------------------------------------------
    currentPal := @ACH_PAL[0];
    SwapScreen;
    FadeIn;

    // ---- wait for dismiss -------------------------------------------------
    WaitFrame;
    repeat
        joy := stick0;
        WaitFrame;
    until IsStartingButtonDown or CRT_SelectPressed;
    repeat WaitFrame; until not IsStartingButtonDown and not CRT_SelectPressed;

    FadeOut;
end;

// ***************************************************
// *** TITLE / WORLD SELECTOR (1:1 from original)
// ***************************************************

procedure ShowNextStat;
begin
    statCount := STAT_CHANGE_DELAY;
    case statPage of
        0: begin
            Str(world.totalSlimeCount, s);
            Str(worldStats.maxSlimes, s1);
            s := 'SLIMES ' + s1 + ' of ' + s;
        end;
        1: begin
            if worldStats.bestTime <> $ffff then Sec2TimeInS1(worldStats.bestTime)
            else s1 := '--:--';
            s := 'BEST TIME ' + s1;
        end;
        2: begin
            Str(world.secretsCount, s);
            Str(worldStats.maxSecrets, s1);
            s := 'SECRETS ' + s1 + ' of ' + s;
        end;
        3: begin
            if worldStats.speedRunsCount > 0 then s1 := 'YES'
            else s1 := 'NO';
            s := 'SPEED RUN ' + s1;
        end;
    end;
    Inc(statPage);
    if statPage = 4 then statPage := 0;
end;

procedure RenderWorldSelector(locked: boolean);
begin
    UnApl(@IMG_TITLE[0], SCREEN_LOG);
    currentBasePal := @IMG_TITLE_PAL[0];
    RebuildTitlePalette(SELECTOR_COLORS);

    FillRect16(SCREEN_LOG, 0, 120, 320, 80, 0);
    FillRect16(SCREEN_LOG, 0, 118, 320, 2, 1);

    DrawStrCentered(124, 1, 'SELECT WORLD');
    DrawStrCentered(144, 1, Antic2Ascii(world.name));

    if worldCurrent > 0 then DrawStr(8, 144, 1, '<');
    if worldCurrent < WORLD_COUNT - 1 then DrawStr(304, 144, 1, '>');

    if locked then
        DrawStrCentered(160, 2, 'LOCKED')
    else
        DrawStrCentered(160, 1, s);

    DrawStrCentered(176, 1, 'FIRE/ENTER START');
    DrawStrCentered(184, 1, 'LEFT/RIGHT CHANGE  ESC BACK');
    SwapScreen;
end;

function ShowWorldSelector: boolean;
var update, locked: boolean;
    key, delay: byte;
begin
    Result := true;
    InitFlobPMG;
    WaitFrame;
    update := true;
    delay := 0;
    locked := false;

    repeat
        joy := stick0;
        key := NONE;
        if (skstat and 4 = 0) then key := kbcode;

        if worldCurrent > 0 then
            if (delay = 0) and ((joy and %0100 = 0) or (key = KEY_LEFT_CODE)) then begin
                Dec(worldCurrent); update := true;
            end;
        if worldCurrent < WORLD_COUNT - 1 then
            if (delay = 0) and ((joy and %1000 = 0) or (key = KEY_RIGHT_CODE)) then begin
                Inc(worldCurrent); update := true;
            end;

        if update then begin
            WaitFrame;
            ClearFlob;
            LoadWorld(worldCurrent);
            GetWorldStats(worldCurrent);
            locked := false;
            if worldCurrent > 0 then locked := achievements[(worldCurrent - 1) * 12] = 0;
            if cheatmode then locked := false;
            flobX := world.iconFlobX;
            flobY := world.iconFlobY;
            flobDir := 0;
            flobFrame := world.iconFlobFrame;
            if locked then begin
                s := 'LOCKED';
            end else begin
                statPage := 0;
                ShowNextStat;
            end;
            RenderWorldSelector(locked);
            update := false;
            delay := WORLD_SELECTION_DELAY;
        end;

        if (not locked) and (statCount > 0) then begin
            Dec(statCount);
            if statCount = 0 then begin
                ShowNextStat;
                RenderWorldSelector(locked);
            end;
        end;
        WaitFrame;
        if delay > 0 then Dec(delay);
        if CRT_Keypressed and (kbcode = KEY_ESC_CODE) then begin
            Result := false;
            exit;
        end;
        if CRT_Keypressed and (kbcode = KEY_ENTER_CODE) and (not locked) and (world.state <> WORLD_LOCKED) then begin
            WaitForStartKeyUp;
            exit;
        end;

    until IsStartingButtonDown and not locked and (world.state <> WORLD_LOCKED);
    WaitForStartKeyUp;
end;

procedure InitTitle;
begin
    UnApl(@IMG_TITLE[0], SCREEN_LOG);
    currentBasePal := @IMG_TITLE_PAL[0];
    RebuildTitlePalette(MAIN_TITLE_COLORS);
    SwapScreen;
    FadeIn;
end;

procedure ShowTitleScreen;
begin

    // Show title image
    UnApl(@IMG_TITLE[0], SCREEN_LOG);
    currentBasePal := @IMG_TITLE_PAL[0];
    RebuildTitlePalette(MAIN_TITLE_COLORS);
    xbios_setpalette(pword(currentPal));
    SwapScreen;
    PlaySong(MUSIC_THEME);
    repeat
        WaitFrame;
        if CRT_SelectPressed then begin ShowAchievements; InitTitle; end;
        if CRT_HelpPressed then begin ShowCredits; InitTitle; end;
    until IsStartingButtonDown;
    WaitForStartKeyUp;
end;

// ***************************************************
// *** GAME INIT
// ***************************************************

procedure InitGame;
begin
    WaitFrame;
    FillChar(slimeX, SizeOf(slimeX), 0);
    worldCurrent := 0;
    music_on := 0;
    statsOn := false;
    WaitFrame;
    RestoreWorldStats;
    CheckAchievements;
end;

procedure CheckDiags;
begin
    // stub – on 8-bit this checked for special key combos at boot
    kbcode := $ff;
    WaitFrame;
    if CRT_HelpPressed then begin
        cheatmode := true;
        repeat WaitFrame; until not CRT_HelpPressed;
    end else
        cheatmode := false;
end;

// ***************************************************
// *** MAIN
// ***************************************************

begin
    ScreenInit;
    gemdos_super(pointer(0));
    sysframe := 0;

    spriteAnimations[0] := @spriteAnimation0;
    spriteAnimations[1] := @spriteAnimation1;

    leveldata[0] := LEVEL_END;
    statBestsBack  := STAT_OFF;
    statGlobalBack := STAT_OFF;
    music_ingame := true;

    InstallInput;
    CheckDiags;
    isStereo := IsStereoPresent;
    InitGame;

    worldCurrent := 0;

    repeat
        ShowTitleScreen;

        if ShowWorldSelector then begin
            StopSong;
            if worldCurrent = 0 then ShowCutScene(INTRO_BANK, INTRO_IMAGE_COUNT);
            StopSong;
            InitWorld;
            music_track := worldCurrent;
            if music_track > 4 then music_track := 0;
            if music_ingame then PlaySong(MUSIC_LEVEL)
            else PlaySong(MUSIC_SILENT);
            InitLevelScreen;
            InitFlobPMG;

            repeat
                PMG_Clear;
                if exploded then begin
                    if lastSafeLanded.flipped then ReverseDlist else OrderDlist;
                    flipped  := lastSafeLanded.flipped;
                    flobX    := lastSafeLanded.x;
                    flobY    := lastSafeLanded.y;
                    levelNum := lastSafeLanded.lvl;
                    flobFalling := 0;
                    if flobX < 80 then flobDir := DIR_RIGHT else flobDir := DIR_LEFT;
                    invulnerability := INVULNERABILTY_TIME;
                end;

                LoadLevel(levelNum);
                ShowSlime;
                WaitFrame;

                if teleported then begin
                    FadeIn;
                    teleported := false;
                end else begin
                    SetLevelColors;
                end;

                repeat
                    PMG_hitclr := $ff;
                    WaitFrame;
                    BeginQueuedSpritesFrame;

                    ClearFlob;

                    if flobFrame <> 0 then
                        if flobFrameDelay > 0 then Dec(flobFrameDelay)
                        else if flobFrameDelay = 0 then flobFrame := FRAME_STAND;

                    FlobFootUpdate;

                    joy := stick0;
                    if joy and %0100 = 0 then FlobMove(DIR_LEFT);
                    if joy and %1000 = 0 then FlobMove(DIR_RIGHT);
                    if strig0 = 0 then Flip;

                    if skstat and 4 = 0 then begin
                        if kbcode = KEY_LEFT_CODE  then FlobMove(DIR_LEFT);
                        if kbcode = KEY_RIGHT_CODE then FlobMove(DIR_RIGHT);
                        if kbcode = KEY_UP_CODE    then Flip;
                    end;

                    if (not IsSolidPix(GetPix(flobFoot, flobY))) or (flobY > 80) then FlobFall
                    else begin
                        if flobFalling > 16 then FlobAnimate(FRAME_SPLAT);
                        if not room_landed then begin
                            first_landed := true;
                            landedTime := 0;
                            room_landed := true;
                        end;
                        flobFalling := 0;
                    end;

                    if (sysframe and 31 = 0) and (flobFrame = 0) and (Random(10) < 3) then
                        FlobAnimate(FRAME_BLINK);

                    DrawSlimes;
                    DrawFlob;

                    if sprites.state > SPRITE_NONE then AnimateSprite(0);
                    if sprites.state = SPRITE_TWO  then AnimateSprite(1);
                    ShowSprites;

                    Inc(gametime);
                    if actionDelay > 0 then Dec(actionDelay);
                    if sfxDelay    > 0 then Dec(sfxDelay);
                    CheckEvents;

                    if not game_over and not room_changed then begin
                        if flobX = RIGHT_EDGE then NextLevel(DIR_RIGHT);
                        if flobX = LEFT_EDGE  then NextLevel(DIR_LEFT);
                        if flobY > 80 then
                            if flipped then NextLevel(DIR_TOP)
                            else NextLevel(DIR_BOTTOM);

                        CheckSlimeCollision;
                        if colorCollision and FlobTouchesDangerColor then
                            Explode
                        else
                            CheckSpriteCollisions;

                        if invulnerability > 0 then Dec(invulnerability);

                        if first_landed then begin
                            if landedTime = 0 then begin SetLanded; room_landed := true; end;
                            Inc(landedTime);
                            if (landedTime > 7) and (invulnerability = 0) then begin
                                SetLandingSafe;
                                first_landed := false;
                                landedTime := 0;
                            end;
                        end;

                        if CRT_Keypressed and (kbcode = KEY_ENTER_CODE) then begin
                            Inc(escPressed);
                            if escPressed = ESC_PRESS_TIME then begin
                                if (flobX = lastSafeLanded.x) and (flobY = lastSafeLanded.y) then begin
                                    mainGoalReached := false;
                                    game_over := true;
                                end else Explode;
                                escPressed := 0;
                            end;
                        end else escPressed := 0;

                        if CRT_StartPressed then begin
                            repeat WaitFrame; until not CRT_StartPressed;
                            repeat WaitFrame; until IsStartingButtonDown;
                            WaitForStartKeyUp;
                        end;

                        if CRT_OptionPressed and (actionDelay = 0) then begin
                            music_ingame := not music_ingame;
                            StopSong;
                            if music_ingame then PlaySong(MUSIC_LEVEL)
                            else PlaySong(MUSIC_SILENT);
                            actionDelay := 20;
                        end;

                        if CRT_SelectPressed and music_ingame and (actionDelay = 0) then begin
                            Inc(music_track);
                            if music_track > 4 then music_track := 0;
                            StopSong;
                            LoadWorld(music_track);
                            LoadWorld(worldCurrent);
                            PlaySong(MUSIC_LEVEL);
                            actionDelay := 20;
                        end;
                    end;

                    PresentQueuedSprites;
                until game_over or room_changed or exploded;

                WaitFrame;

            until game_over;

            FadeOut;
            StopSong;
        end;

    until false;

    UnInstallInput;
    ScreenDone;
end.
