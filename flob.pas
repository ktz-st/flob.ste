{$APPTYPE GUI}
{$mode objfpc}

program FloB;
uses xbios, gemdos, bios;

{$i palette.inc}

const
{$i const.inc}
{$i vnumber.inc}
    LEVEL_SCALE_X = 2;
    LEVEL_SCALE_Y = 2;
    LEVEL_OFFSET_Y = 16;
    BG_IMAGE_OFFSET_Y = 20;
    PLAYFIELD_HEIGHT = 160;
    SPAWN_Y_ADJUST = 10;
    GROUND_COLLISION_COLOR = 2;
    DANGER_COLLISION_COLOR = 3;
    FLOB_RENDER_OFFSET_Y = 5;
    WORLD_SPRITE_OFFSET_X = -2;
    WORLD_SPRITE_OFFSET_Y = 4;
    WORLD_SPRITE_MOVE_STEP = 1;
    FLOB_MOVE_STEP = 2;
    FLOB_FALL_STEP = 2;
    HUD_HEIGHT = 8;
    MESSAGE_TEXT_COLOR = 15;
    CUTSCENE_TEXT_COLOR = 14;
    CUTSCENE_FADE_COLOR = 15;
    CUTSCENE_TEXT_FADE_FRAMES = 15;
    CUTSCENE_TEXT_WHITE = $FFF;
    DYNAMIC_DANGER_BYTES = 160 * 80 div 8;
    PSG_SFX_DEFAULT = true;
    SFX_SAMPLES_PER_FRAME = 250;
    SFX_BUFFER_HALVES = 4;
    SFX_SAMPLE_RATE = 12517;
    SFX_POKEY_BASE_DIV = 28;
    SFX_AMPLITUDE_STEP = 3;
    FLIP_STEPS = 4;
    SLIME_RENDER_OFFSET_X = -50 * LEVEL_SCALE_X;
    SLIME_RENDER_OFFSET_Y = 16;
    FLIP_H: array[0..FLIP_STEPS] of word = (160, 80, 32, 8, 0);
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
{$i assets/achievements.inc} // generated achievement definitions
{$i assets/endworld_icons.inc} // generated 32x40 bitmap4 end-world icons
{$i assets/world_icons.inc} // canonical 192x80 world selector icons
{$i assets/selector_ui.inc} // Scale2x font masks and palette-isolated sprites
{$i assets/achievement_ui.inc}
{$i assets/stats_header.inc}
{$i bank_0_files.inc} // starts with: type ... var
{$i assets/sprites.inc} // starts with: var
{$i worlds/worlds.inc} // all world + asset const byte arrays
{$i worlds/world_tiles.inc} // generated STE tile data
{$i images/images.inc} // per-world room backgrounds + global screens (aplib compressed)
{$i generated/sprite_assets_atlas.inc} // generated unified atlas -> masked sprite data
{$i generated/sprite_atlas_palette.inc}
{$i assets/sfx_synth.inc} // generated 50 Hz POKEY register streams
{$i assets/music_theme.inc} // converted title music, FYM1 register deltas

{$L unapl.o}
{$L font.o}
{$L ikbd.o}
{$L dmasound.o}
{$L sfxsynth.o}
{$L psgsound.o}
procedure UnApl(src, dst: pointer); external;
procedure DrawChar(screen, font: pointer; x, y, ch, fg, bg: longword); cdecl; external;
procedure RawIkbdHandler; external;
procedure DmaSoundInit; external;
procedure DmaSoundDone; external;
procedure DmaSoundStop; external;
procedure DmaPlayRaw(sample: pointer; length: cardinal); external;
procedure DmaPlayLoop(sample: pointer; length: cardinal); external;
procedure SfxRenderBlockAsm(dst: pointer; count: cardinal; state: pointer); cdecl; external;
procedure PsgSoundInit; external;
procedure PsgSoundDone; external;
procedure PsgSoundStop; external;
procedure PsgSoundPlay(data: pointer; dataSize: cardinal); cdecl; external;
procedure PsgMusicPlay(data: pointer); cdecl; external;
procedure PsgMusicStop; external;
var FlobFont: byte; external name 'FlobFont';
var RawIkbdJoyStatus: byte; external name 'RawIkbdJoyStatus';
var RawIkbdState: byte; external name 'RawIkbdState';
var RawIkbdKeyStates: byte; external name 'RawIkbdKeyStates';
var RawIkbdKeyEventHead: byte; external name 'RawIkbdKeyEventHead';
var RawIkbdKeyEventRing: byte; external name 'RawIkbdKeyEventRing';

procedure ClearScreen(buf: pword); forward;
procedure SwapScreen; forward;
procedure DrawStr(x, y, fg: word; const str: string); forward;
procedure DrawStrCentered(y, fg: word; const str: string); forward;
procedure DrawTextTo(scr: pword; x, y, fg, bg: word; const str: string); forward;
procedure DrawHudTo(scr: pword); forward;
procedure RefreshHudCache; forward;
procedure CopyHudArea(src, dst: pword); forward;
procedure CopyMessageArea(src, dst: pword); forward;
procedure DrawMessageTo(scr: pword); forward;
procedure RefreshMessageCache; forward;
procedure RefreshOverlayBuffers; forward;
procedure RebuildDisplayBuffersFromBackground; forward;
procedure BlitterCopyData16(src, dst: pointer; size: longword); forward;
procedure BlitterCopyBitmap4(src, dst: pointer; width, height, srcX, srcY, dstX,
    dstY, srcWidth, dstWidth: word); forward;
procedure DrawSquashedPlayfieldBlitter(src: pword; destH: word); forward;
procedure BuildDisplayPalette(dst: PWord); forward;
procedure UpdateDisplayPaletteIfNeeded(force: boolean); forward;
procedure FillRect16(scr: pword; x, y, cellw, cellh, color: word); forward;
procedure Collided(pnum: byte); forward;
procedure DrawGeneratedSpriteFrameBlitter(scr: pword; dstX, dstY: word;
    frame: PSteSpriteFrame; wordsBase: PWord); forward;

type
    TSfxSynthAsmState = packed record
        phase: longword;
        threshold: longword;
        noise: longword;
        poly4Pos: word;
        poly5Pos: word;
        stride4: word;
        stride5: word;
        positiveSample: byte;
        negativeSample: byte;
        flags: byte;
        output: byte;
    end;

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
    PQueuedSprite = ^TQueuedSprite;

    TDirtyRect = record
        x: word;
        y: word;
        widthPx: word;
        heightPx: word;
    end;

const
    MAX_QUEUED_SPRITES = 48;
    MAX_DIRTY_RECTS = MAX_QUEUED_SPRITES * 2;
    DIRTY_FULL_COPY_PIXELS = 48000;
    DIRTY_FULL_COPY_RECTS = 40;

type
    TDirtyRectArray = array[0..MAX_DIRTY_RECTS - 1] of TDirtyRect;

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
    b, joy, joyRaw: byte;
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
    topBarForeground: byte;

    flobX, flobY, flobFoot, flobFace, flobDir, flobFrame, flobFalling: byte;
    flobFrameDelay: byte;


    isStereo: boolean;

    flipped: boolean;
    colorCollision, mainGoalReached, room_changed, game_over,
    room_landed, first_landed, exploded, teleported: boolean;
    landedTime: byte;
    triggerGrace: byte;   // frames to skip CheckEvents after teleport (prevents instant exit re-trigger)
    spriteCollisionMovePending: boolean;
    teleportTriggerReleasePending: boolean;
    teleportPortalReleasePending: boolean;
    cheatmode, statsOn: boolean;

    levelNum: byte;
    lastLanded: TLastLanded;
    lastSafeLanded: TLastLanded;
    doorReveal: array[0..1] of byte;

    // 8-bit-style input state, updated by the STE IKBD layer.
    stick0: byte;
    strig0: byte;
    joyStatus: byte;
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
    worldDataBuffer: array[0..WORLD_DATA_BYTES - 1] of byte;
    collisionDataBuffer: array[0..COLLISION_DATA_BYTES - 1] of byte;
    dynamicTileDanger: array[0..DYNAMIC_DANGER_BYTES - 1] of byte;
    dynamicTileDangerActive: boolean;
    currentWorldData: PByte;
    currentWorldImgPtrs: ^pointer;
    currentWorldPalPtrs: ^pointer;
    currentWorldColAplPtrs: ^pointer;
    currentWorldImgCount: byte;
    currentWorldAssets: PByte;
    currentWorldAssetsSize: word;
    currentWorldTiles: PSteTile;
    currentWorldTileWords: PWord;
    currentWorldTileCollision: PByte;
    currentWorldTileCount: word;
    spriteColorsRaw: array[0..1] of PByte;
    spriteFramesRaw: array[0..1, 0..15] of PByte;
    spriteAtlasFrames: array[0..1] of PSteSpriteFrame;
    spriteAtlasWords: array[0..1] of PWord;
    spriteAtlasFrameCount: array[0..1] of byte;
    spriteBgValid: array[0..1] of boolean;
    spriteBgX: array[0..1] of word;
    spriteBgY: array[0..1] of word;
    spriteBgW: array[0..1] of word;
    spriteBgH: array[0..1] of word;
    spriteBgPixels: array[0..1, 0..8191] of byte;
    queuedSprites: array[0..1, 0..MAX_QUEUED_SPRITES - 1] of TQueuedSprite;
    queuedSpriteCount: array[0..1] of byte;
    renderedSprites: array[0..1, 0..MAX_QUEUED_SPRITES - 1] of TQueuedSprite;
    renderedSpriteCount: array[0..1] of byte;

    roomTriggers: array[0..3, 0..9] of byte;
    triggerCount: byte;
    msgDisplayCounter: byte;
    msgDisplayType: byte;
    messageCacheDirty: boolean;
    messages: array[0..3] of word;
    messageTypes: array[0..3] of byte;
    currentMessageLines: array[0..1] of string;
    currentMessageAddr: word;
    sceneImg: array[0..1] of byte;
    sceneMsg: array[0..1] of word;
    sceneCol0, sceneCol1, sceneCol2: array[0..1] of byte;
    msgCount: byte;
    sceneCount: byte;

    music_on: byte;
    lastSfxCh: byte;
    music_ingame: boolean;
    music_track: byte;
    musicBuffer: array[0..MUSIC_BUFFER_BYTES - 1] of byte;
    escPressed: byte;
    soundReady: boolean;
    usePsgSfx: boolean;
    sfxSynthActive: boolean;
    sfxSynthData: PByte;
    sfxSynthDataSize: word;
    sfxSynthOffset: word;
    sfxSynthRunFrames: byte;
    sfxSynthAudf: byte;
    sfxSynthAudc: byte;
    sfxSynthOutput: byte;
    sfxSynthPoly4Pos: word;
    sfxSynthPoly5Pos: word;
    sfxSynthPhase: longword;
    sfxSynthNoise: longword;
    sfxSynthStreaming: boolean;
    sfxSynthBufferIndex: byte;
    sfxSynthSilentHalves: byte;
    sfxSynthLastVbl: longword;
    sfxSynthBuffer: array[0..SFX_BUFFER_HALVES - 1, 0..SFX_SAMPLES_PER_FRAME - 1] of byte;

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
    DEBUG_LOADLEVEL: boolean = false;


    vramLineOffset: array[0..99] of word; // unused on STE, kept for compatibility

{$i generated/world_sprite_atlas_map.inc}

// *** Forward declarations (same as original) ***
procedure ReadInput; forward;
procedure PollJoystickState; forward;
procedure InstallInput; forward;
procedure UnInstallInput; forward;
procedure InstallGameplayInput; forward;
procedure UnInstallGameplayInput; forward;
procedure ResetJoystickState; forward;
function CRT_FirePressedEdge: boolean; forward;
procedure LoadLevel(lvl: byte); forward;
procedure CheckAchievements; forward;
procedure EndWorld; forward;
procedure ShowAchievements; forward;
procedure DrawSelectorShadow(const text: string; y: word; color, shade: byte); forward;
procedure DrawSelectorText(const text: string; y: word; color: byte); forward;
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
procedure SfxSynthFrame; forward;

// ***************************************************
// *** COMPATIBILITY LAYER (replaces 8-bit builtins)
// ***************************************************

procedure VSync;
var vbl: longword;
begin
    vbl := PLongWord(pointer(longword($00000466)))^;
    while PLongWord(pointer(longword($00000466)))^ = vbl do ;
    SfxSynthFrame;
end;

procedure WaitFrame;
begin
    ReadInput;
    VSync;
    Inc(sysframe);
end;

procedure WaitFrames(count: word);
var i: word;
begin
    for i := 0 to count - 1 do WaitFrame;
end;

procedure GameplayFrameTick;
begin
    PollJoystickState;
    Inc(sysframe);
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
  Result := '';
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

// ***************************************************
// *** SCREEN / PALETTE INIT (like fuji-tetris)
// ***************************************************

procedure BlitterClearBitmap4(dst: pointer; width, height, dstX, dstY, dstWidth: word); forward;

procedure AlignScreenBuffer(rawScreen: pword; var screen: pword);
var addr: longint;
begin
    addr := longint(rawScreen);
    addr := (addr + 255) and (not 255);
    screen := pword(addr);
end;

procedure ClearScreen(buf: pword);
begin
    BlitterClearBitmap4(buf, 320, 200, 0, 0, 320);
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
    FillChar(renderedSpriteCount, SizeOf(renderedSpriteCount), 0);
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

procedure SetPhysicalScreen(screen: pword);
var addr: longword;
begin
    if screen = nil then exit;
    addr := longword(screen);
    PByte(pointer(longword($FFFF8201)))^ := byte(addr shr 16);
    PByte(pointer(longword($FFFF8203)))^ := byte(addr shr 8);
    PByte(pointer(longword($FFFF820D)))^ := byte(addr);
end;

procedure SwapScreen;
var tmp: pword;
    tmpIndex: byte;
begin
    tmp := SCREEN_LOG;
    SCREEN_LOG := SCREEN_PHY;
    SCREEN_PHY := tmp;
    tmpIndex := screenLogIndex;
    screenLogIndex := screenPhyIndex;
    screenPhyIndex := tmpIndex;
    SetPhysicalScreen(SCREEN_PHY);
    VSync;
end;

// ***************************************************
// *** GRAPHICS STUBS (display routines to implement)
// ***************************************************


procedure FlipGameplayAreaInPlace(buf: pword);
var yTop, yBottom: word;
    topPtr, bottomPtr: PByte;
    tmp: array[0..SCREEN_LINE_BYTES-1] of byte;
begin
    if buf = nil then exit;
    FillChar(tmp, SizeOf(tmp), 0);
    yTop := BG_IMAGE_OFFSET_Y;
    yBottom := BG_IMAGE_OFFSET_Y + PLAYFIELD_HEIGHT - 1;
    while yTop < yBottom do begin
        topPtr := PByte(longword(buf) + longword(yTop) * SCREEN_LINE_BYTES);
        bottomPtr := PByte(longword(buf) + longword(yBottom) * SCREEN_LINE_BYTES);
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
    srcPtr := PByte(longword(src) + longword(BG_IMAGE_OFFSET_Y) * SCREEN_LINE_BYTES);
    dstPtr := PByte(longword(dst) + longword(BG_IMAGE_OFFSET_Y) * SCREEN_LINE_BYTES);
    BlitterCopyData16(srcPtr, dstPtr, longword(PLAYFIELD_HEIGHT) * SCREEN_LINE_BYTES);
end;

procedure CopyHudArea(src, dst: pword);
begin
    if (src = nil) or (dst = nil) then exit;
    BlitterCopyData16(src, dst, 20 * SCREEN_LINE_BYTES);
end;

procedure CopyMessageArea(src, dst: pword);
var srcPtr, dstPtr: PByte;
begin
    if (src = nil) or (dst = nil) then exit;
    srcPtr := PByte(longword(src) + 180 * SCREEN_LINE_BYTES);
    dstPtr := PByte(longword(dst) + 180 * SCREEN_LINE_BYTES);
    BlitterCopyData16(srcPtr, dstPtr, 20 * SCREEN_LINE_BYTES);
end;

procedure ClearPlayfieldLog;
begin
    if SCREEN_LOG = nil then exit;
    BlitterClearBitmap4(SCREEN_LOG, 320, PLAYFIELD_HEIGHT, 0, BG_IMAGE_OFFSET_Y, 320);
end;

procedure DrawSquashedPlayfieldCpu(src: pword; destH: word);
var i, srcY, yDst: word;
    srcLine, dstLine: PByte;
begin
    if (src = nil) or (SCREEN_LOG = nil) then exit;
    if (destH = 0) or (destH > PLAYFIELD_HEIGHT) then exit;

    yDst := BG_IMAGE_OFFSET_Y + (PLAYFIELD_HEIGHT - destH) div 2;
    for i := 0 to destH - 1 do begin
        srcY := BG_IMAGE_OFFSET_Y + word((longword(i) * PLAYFIELD_HEIGHT) div destH);
        srcLine := PByte(longword(src) + longword(srcY) * SCREEN_LINE_BYTES);
        dstLine := PByte(longword(SCREEN_LOG) + longword(yDst + i) * SCREEN_LINE_BYTES);
        Move(srcLine^, dstLine^, SCREEN_LINE_BYTES);
    end;
end;

procedure ClearFlipFrameBorders(previousH, destH: word);
var previousTop, destTop, stripH: word;
begin
    if SCREEN_LOG = nil then exit;
    if previousH > PLAYFIELD_HEIGHT then previousH := PLAYFIELD_HEIGHT;
    if destH >= previousH then exit;

    previousTop := BG_IMAGE_OFFSET_Y + (PLAYFIELD_HEIGHT - previousH) div 2;
    destTop := BG_IMAGE_OFFSET_Y + (PLAYFIELD_HEIGHT - destH) div 2;
    stripH := destTop - previousTop;
    if stripH = 0 then exit;
    BlitterClearBitmap4(SCREEN_LOG, 320, stripH,
        0, previousTop, 320);
    BlitterClearBitmap4(SCREEN_LOG, 320, stripH,
        0, destTop + destH, 320);
end;

procedure DrawFlipPlayfieldFrame(src: pword; previousH, destH: word;
    clearBorders: boolean);
begin
    if clearBorders then ClearFlipFrameBorders(previousH, destH);
    DrawSquashedPlayfieldBlitter(src, destH);
    SwapScreen;
end;

procedure FlipGameplayEffect(wantFlipped: boolean);
var step: integer;
    bufferHeight: array[0..1] of word;
    bufferIndex: byte;
begin
    if SCREEN_BKG = nil then exit;

    RefreshOverlayBuffers;
    bufferHeight[0] := PLAYFIELD_HEIGHT;
    bufferHeight[1] := PLAYFIELD_HEIGHT;
    for step := 1 to FLIP_STEPS do begin
        bufferIndex := screenLogIndex;
        DrawFlipPlayfieldFrame(SCREEN_BKG, bufferHeight[bufferIndex],
            FLIP_H[step], true);
        bufferHeight[bufferIndex] := FLIP_H[step];
    end;

    if displayFlipped <> wantFlipped then begin
        FlipGameplayAreaInPlace(SCREEN_BKG);
        displayFlipped := wantFlipped;
    end;

    for step := FLIP_STEPS - 1 downto 0 do begin
        bufferIndex := screenLogIndex;
        DrawFlipPlayfieldFrame(SCREEN_BKG, bufferHeight[bufferIndex],
            FLIP_H[step], false);
        bufferHeight[bufferIndex] := FLIP_H[step];
    end;

    RebuildDisplayBuffersFromBackground;
end;

procedure RebuildDisplayBuffersFromBackground;
begin
    if SCREEN_BKG = nil then exit;
    RefreshMessageCache;
    CopyPlayfieldArea(SCREEN_BKG, SCREEN_LOG);
    CopyPlayfieldArea(SCREEN_BKG, SCREEN_PHY);
    CopyHudArea(SCREEN_BKG, SCREEN_LOG);
    CopyMessageArea(SCREEN_BKG, SCREEN_LOG);
    CopyHudArea(SCREEN_BKG, SCREEN_PHY);
    CopyMessageArea(SCREEN_BKG, SCREEN_PHY);
    FillChar(queuedSpriteCount, SizeOf(queuedSpriteCount), 0);
    FillChar(renderedSpriteCount, SizeOf(renderedSpriteCount), 0);
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

procedure ClearTxt2;
begin
    currentMessageLines[0] := '';
    currentMessageLines[1] := '';
    currentMessageAddr := $FFFF;
    messageCacheDirty := true;
end;

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
    BLITTER_MODE_HOG = $40;
    BLITTER_START_COPY_MODE = BLITTER_MODE_BUSY;
    BLITTER_START_SPRITE_MODE = BLITTER_MODE_BUSY or BLITTER_MODE_HOG;
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

procedure DrawSquashedPlayfieldBlitter(src: pword; destH: word);
var srcStep, yDst: word;
    srcIncY: word;
    srcPtr, dstPtr: PByte;
begin
    if (src = nil) or (SCREEN_LOG = nil) then exit;
    if (destH = 0) or (destH > PLAYFIELD_HEIGHT) then exit;
    if (PLAYFIELD_HEIGHT mod destH) <> 0 then begin
        DrawSquashedPlayfieldCpu(src, destH);
        exit;
    end;

    srcStep := PLAYFIELD_HEIGHT div destH;
    yDst := BG_IMAGE_OFFSET_Y + (PLAYFIELD_HEIGHT - destH) div 2;
    srcPtr := PByte(longword(src) + longword(BG_IMAGE_OFFSET_Y) * SCREEN_LINE_BYTES);
    dstPtr := PByte(longword(SCREEN_LOG) + longword(yDst) * SCREEN_LINE_BYTES);

    // After the 80th word, advance directly to the next sampled source line.
    srcIncY := srcStep * SCREEN_LINE_BYTES - (SCREEN_LINE_BYTES - 2);

    BlitterWait;
    BlitterWriteByte(BLITTER_SKEW, 0);
    BlitterWriteWord(BLITTER_SRC_INC_X, 2);
    BlitterWriteWord(BLITTER_SRC_INC_Y, srcIncY);
    BlitterWritePtr(BLITTER_SRC_ADDR, srcPtr);
    BlitterWriteWord(BLITTER_ENDMASK1, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK2, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK3, $FFFF);
    BlitterWriteWord(BLITTER_DST_INC_X, 2);
    BlitterWriteWord(BLITTER_DST_INC_Y, 2);
    BlitterWritePtr(BLITTER_DST_ADDR, dstPtr);
    BlitterWriteWord(BLITTER_COUNT_X, SCREEN_LINE_BYTES div 2);
    BlitterWriteWord(BLITTER_COUNT_Y, destH);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC);
    BlitterWriteByte(BLITTER_MODE, BLITTER_START_COPY_MODE);
    BlitterWait;
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
    BlitterWriteByte(BLITTER_MODE, BLITTER_START_COPY_MODE);
    BlitterWait;
end;

procedure BlitterCopyBitmap4(src, dst: pointer; width, height, srcX, srcY, dstX,
    dstY, srcWidth, dstWidth: word);
var countX, srcIncY, dstIncY: word;
    srcBytes, dstBytes: PByte;
begin
    if (src = nil) or (dst = nil) or (width = 0) or (height = 0) then exit;
    if (srcWidth = 0) or (dstWidth = 0) then exit;
    if (srcX >= srcWidth) or (dstX >= dstWidth) then exit;

    srcX := srcX and $FFF0;
    dstX := dstX and $FFF0;
    width := width and $FFF0;
    if width = 0 then exit;

    if (srcX + width) > srcWidth then
        width := (srcWidth - srcX) and $FFF0;
    if (dstX + width) > dstWidth then
        width := (dstWidth - dstX) and $FFF0;
    if width = 0 then exit;

    countX := width shr 2;
    srcIncY := ((srcWidth - width) shr 1) + 2;
    dstIncY := ((dstWidth - width) shr 1) + 2;

    srcBytes := PByte(src);
    Inc(srcBytes, ((longword(srcY) * srcWidth + srcX) shr 1));
    dstBytes := PByte(dst);
    Inc(dstBytes, ((longword(dstY) * dstWidth + dstX) shr 1));

    BlitterWait;
    BlitterWriteByte(BLITTER_SKEW, 0);
    BlitterWriteWord(BLITTER_SRC_INC_X, 2);
    BlitterWriteWord(BLITTER_SRC_INC_Y, srcIncY);
    BlitterWritePtr(BLITTER_SRC_ADDR, srcBytes);
    BlitterWriteWord(BLITTER_ENDMASK1, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK2, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK3, $FFFF);
    BlitterWriteWord(BLITTER_DST_INC_X, 2);
    BlitterWriteWord(BLITTER_DST_INC_Y, dstIncY);
    BlitterWritePtr(BLITTER_DST_ADDR, dstBytes);
    BlitterWriteWord(BLITTER_COUNT_X, countX);
    BlitterWriteWord(BLITTER_COUNT_Y, height);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_LOP, BLITTER_LOP_SRC);
    BlitterWriteByte(BLITTER_MODE, BLITTER_START_COPY_MODE);
    BlitterWait;
end;

procedure BlitterClearBitmap4(dst: pointer; width, height, dstX, dstY, dstWidth: word);
var countX, lineAdvanceBytes: word;
    dstAddr: pointer;
    dstBytes: PByte;
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

    countX := width shr 2;
    if countX = 0 then exit;
    lineAdvanceBytes := ((dstWidth - width) shr 1) + 2;
    dstBytes := PByte(dst);
    Inc(dstBytes, ((longword(dstY) * dstWidth + dstX) shr 1));
    dstAddr := dstBytes;

    BlitterWait;
    BlitterWriteByte(BLITTER_SKEW, 0);
    BlitterWriteWord(BLITTER_ENDMASK1, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK2, $FFFF);
    BlitterWriteWord(BLITTER_ENDMASK3, $FFFF);
    BlitterWriteWord(BLITTER_DST_INC_X, 2);
    BlitterWriteWord(BLITTER_DST_INC_Y, lineAdvanceBytes);
    BlitterWritePtr(BLITTER_DST_ADDR, dstAddr);
    BlitterWriteWord(BLITTER_COUNT_X, countX);
    BlitterWriteWord(BLITTER_COUNT_Y, height);
    BlitterWriteByte(BLITTER_HOP, BLITTER_HOP_SRC);
    BlitterWriteByte(BLITTER_LOP, 0);
    BlitterWriteByte(BLITTER_MODE, BLITTER_START_COPY_MODE);
    BlitterWait;
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
    tilePtr := currentWorldTiles;
    for i := 0 to currentWorldTileCount - 1 do begin
        if tilePtr^.sourceAddr = src then begin
            Result := tilePtr;
            exit;
        end;
        Inc(tilePtr);
    end;
end;

procedure BeginQueuedSpritesFrame;
var messageWasDirty: boolean;
begin
    UpdateDisplayPaletteIfNeeded(false);
    queuedSpriteCount[screenLogIndex] := 0;
    messageWasDirty := messageCacheDirty;
    RefreshMessageCache;
    if messageWasDirty then begin
        CopyMessageArea(SCREEN_BKG, SCREEN_LOG);
        CopyMessageArea(SCREEN_BKG, SCREEN_PHY);
    end;
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

procedure DrawSteTile(scr: pword; dstX, dstY: word; tile: PSteTile; flip: byte);
var frame: TSteSpriteFrame;
begin
    if tile = nil then exit;
    if flip <> 0 then exit;
    frame.widthPx := tile^.widthPx;
    frame.heightPx := tile^.heightPx;
    frame.rowWords := tile^.rowWords;
    frame.maskOffset := tile^.dataOffset;
    frame.dataOffset := tile^.dataOffset + tile^.heightPx * tile^.rowWords;
    frame.paletteOffset := 0;
    frame.paletteCount := 0;
    DrawGeneratedSpriteFrameBlitter(scr, dstX, dstY, @frame, currentWorldTileWords);
end;

procedure ApplyTileCollision(x, y: byte; tile: PSteTile; flip: byte);
var srcData: PByte;
    srcWidth, srcHeight, srcRowBytes: word;
    srcX, srcY, readY, dstX, dstY: word;
    packedByte, srcColor, shift, mask, dangerMask: byte;
    dstOffset, dangerOffset: word;
begin
    if (tile = nil) or (currentWorldTileCollision = nil) or
       (currentCollisionData = nil) then exit;

    srcWidth := tile^.widthPx shr 1;
    srcHeight := tile^.heightPx shr 1;
    srcRowBytes := srcWidth shr 2;
    srcData := currentWorldTileCollision;
    Inc(srcData, tile^.collisionOffset);

    for srcY := 0 to srcHeight - 1 do begin
        if flip <> 0 then readY := srcHeight - 1 - srcY
        else readY := srcY;
        dstY := word(y) + srcY;
        if dstY >= 80 then continue;

        for srcX := 0 to srcWidth - 1 do begin
            dstX := word(x) * 4 + srcX;
            if dstX >= 160 then continue;
            packedByte := srcData[readY * srcRowBytes + (srcX shr 2)];
            shift := 6 - ((srcX and 3) shl 1);
            srcColor := (packedByte shr shift) and 3;
            if srcColor = 0 then continue;

            dstOffset := dstY * 40 + (dstX shr 2);
            shift := 6 - ((dstX and 3) shl 1);
            mask := byte(3 shl shift);
            currentCollisionData[dstOffset] :=
                (currentCollisionData[dstOffset] and not mask) or
                (srcColor shl shift);

            dangerOffset := dstY * 20 + (dstX shr 3);
            dangerMask := byte($80 shr (dstX and 7));
            if srcColor = DANGER_COLLISION_COLOR then begin
                dynamicTileDanger[dangerOffset] :=
                    dynamicTileDanger[dangerOffset] or dangerMask;
                dynamicTileDangerActive := true;
            end else
                dynamicTileDanger[dangerOffset] :=
                    dynamicTileDanger[dangerOffset] and not dangerMask;
        end;
    end;
end;

procedure PutTile(x, y: byte; src: word; flip: byte);
var tile: PSteTile;
    dstX, dstY: word;
begin
    tile := FindSteTile(src);
    if tile <> nil then begin
        dstX := word(x) * 4 * LEVEL_SCALE_X;
        dstY := BG_IMAGE_OFFSET_Y + word(y) * LEVEL_SCALE_Y;
        DrawSteTile(SCREEN_LOG, dstX, dstY, tile, flip);
        ApplyTileCollision(x, y, tile, flip);
        exit;
    end;
end;

{$i fade.inc}
{$i text.inc}

procedure LoadImage(imgNum: byte);
var imgPtr, palPtr, colAplPtr: pointer;
begin
    if currentWorldImgPtrs = nil then exit;
    if imgNum >= currentWorldImgCount then exit;
    imgPtr := PPointer(currentWorldImgPtrs)[imgNum];
    palPtr := PPointer(currentWorldPalPtrs)[imgNum];
    currentCollisionData := nil;
    FillChar(dynamicTileDanger[0], SizeOf(dynamicTileDanger), 0);
    dynamicTileDangerActive := false;
    if currentWorldColAplPtrs <> nil then begin
        colAplPtr := PPointer(currentWorldColAplPtrs)[imgNum];
        UnApl(colAplPtr, @collisionDataBuffer[0]);
        currentCollisionData := @collisionDataBuffer[0];
    end;
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

procedure DrawCutsceneSlideTo(dst: pword);
var srcPtr: PByte;
begin
    if (SCREEN_BKG = nil) or (dst = nil) then exit;
    ClearScreen(dst);
    srcPtr := PByte(SCREEN_BKG);
    Inc(srcPtr, 8 * SCREEN_LINE_BYTES);
    BlitterCopyData16(srcPtr, dst, 168 * SCREEN_LINE_BYTES);
    BlitterClearBitmap4(dst, 320, 32, 0, 168, 320);
end;

procedure PresentCutsceneSlide;
begin
    DrawCutsceneSlideTo(SCREEN_LOG);
    DrawCutsceneSlideTo(SCREEN_PHY);
    SwapScreen;
end;

procedure FadeIn;   begin FadeToPalette(pword(currentPal), FADE_FRAMES); end;
procedure FadeOut;  begin FadeToBlack(FADE_FRAMES); xbios_setpalette(@ALL_BLACK[0]); end;
procedure BlackAll; begin xbios_setpalette(@ALL_BLACK[0]); end;

procedure SetPaletteRegister(index: byte; color: word);
var palRegs: PWord;
begin
    if index > 15 then exit;
    palRegs := PWord(pointer(longword($FFFF8240)));
    palRegs[index] := color;
end;

function CurrentPaletteRegisterColor(index: byte): word;
var pal: PWord;
begin
    Result := 0;
    if index > 15 then exit;
    if currentPal = nil then exit;
    pal := PWord(currentPal);
    Result := pal[index];
end;

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

    roomPalette[1] := STE_PAL[levelRawColors[1]];
    roomPalette[2] := STE_PAL[levelRawColors[0]];
    roomPalette[3] := STE_PAL[levelRawColors[2]];
    roomPalette[0] := STE_PAL[levelRawColors[3]];
    ApplyRoomSpriteAtlasPalette(@roomPalette[0]);
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
    roomPalette[15] := $eee;
    roomSpritePaletteActive := false;
    currentPal := @roomPalette[0];
end;

procedure RebuildTitlePalette;
begin
    if currentBasePal <> nil then
        Move(currentBasePal^, titlePalette[0], 32)
    else
        FillChar(titlePalette[0], SizeOf(titlePalette), 0);

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

    if (not force) and (not displayPaletteDirty) then begin
        if lastPaletteMsgSource <> msgSource then begin
            if msgSource >= 0 then
                SetPaletteRegister(MESSAGE_TEXT_COLOR, STE_PAL[byte(msgSource)])
            else
                SetPaletteRegister(MESSAGE_TEXT_COLOR, CurrentPaletteRegisterColor(MESSAGE_TEXT_COLOR));
            lastPaletteMsgSource := msgSource;
        end;
        exit;
    end;

    BuildDisplayPalette(@spriteTestPal[0]);
    xbios_setpalette(@spriteTestPal[0]);

    lastPaletteMsgSource := msgSource;
    displayPaletteDirty := false;
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

    skew := byte(dstX and 15);
    // NFSR reduces source reads by one. It is needed when skew makes the
    // destination span one word more than the packed source, but would clip
    // the second source word of a 20 px sprite such as the phone.
    if (skew <> 0) and (rowWords < lXcount) then
        skew := skew or BLITTER_SKEW_NFSR;

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

    dstWords := scr;
    Inc(dstWords, (longword(dstY) * SCREEN_LINE_BYTES + longword(dstX shr 4) * 8) shr 1);
    maskBase := wordsBase;
    Inc(maskBase, frame^.maskOffset);
    gfxBase := wordsBase;
    Inc(gfxBase, frame^.dataOffset);

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
        BlitterWriteByte(BLITTER_MODE, BLITTER_START_SPRITE_MODE);
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
        BlitterWriteByte(BLITTER_MODE, BLITTER_START_SPRITE_MODE);
    end;
    BlitterWait;
end;

function QueuedSpritesEqual(a, b: PQueuedSprite): boolean; inline;
begin
    Result :=
        (a^.x = b^.x) and
        (a^.y = b^.y) and
        (a^.widthPx = b^.widthPx) and
        (a^.heightPx = b^.heightPx) and
        (a^.frame = b^.frame) and
        (a^.wordsBase = b^.wordsBase) and
        (a^.palBase = b^.palBase) and
        (a^.palSlot = b^.palSlot);
end;

function DirtyRectsTouch(const a, b: TDirtyRect): boolean; inline;
begin
    Result :=
        (a.x <= b.x + b.widthPx) and
        (b.x <= a.x + a.widthPx) and
        (a.y <= b.y + b.heightPx) and
        (b.y <= a.y + a.heightPx);
end;

procedure MergeDirtyRect(var dst: TDirtyRect; const src: TDirtyRect);
var right, bottom, srcRight, srcBottom: word;
begin
    right := dst.x + dst.widthPx;
    bottom := dst.y + dst.heightPx;
    srcRight := src.x + src.widthPx;
    srcBottom := src.y + src.heightPx;
    if src.x < dst.x then dst.x := src.x;
    if src.y < dst.y then dst.y := src.y;
    if srcRight > right then right := srcRight;
    if srcBottom > bottom then bottom := srcBottom;
    dst.widthPx := right - dst.x;
    dst.heightPx := bottom - dst.y;
end;

procedure AddDirtySpriteRect(var rects: TDirtyRectArray; var count: byte;
    spr: PQueuedSprite);
var candidate: TDirtyRect;
    right, bottom: longword;
    i: byte;
begin
    if (spr = nil) or (spr^.widthPx = 0) or (spr^.heightPx = 0) then exit;
    if (spr^.x >= 320) or (spr^.y >= 200) then exit;

    candidate.x := spr^.x and $FFF0;
    right := (longword(spr^.x) + spr^.widthPx + 15) and longword($FFFFFFF0);
    if right > 320 then right := 320;
    candidate.widthPx := word(right) - candidate.x;
    candidate.y := spr^.y;
    bottom := longword(spr^.y) + spr^.heightPx;
    if bottom > 200 then bottom := 200;
    candidate.heightPx := word(bottom) - candidate.y;
    if (candidate.widthPx = 0) or (candidate.heightPx = 0) then exit;

    i := 0;
    while i < count do begin
        if DirtyRectsTouch(candidate, rects[i]) then begin
            MergeDirtyRect(candidate, rects[i]);
            Dec(count);
            rects[i] := rects[count];
            i := 0;
        end else
            Inc(i);
    end;

    if count >= MAX_DIRTY_RECTS then exit;
    rects[count] := candidate;
    Inc(count);
end;

function SpriteIntersectsDirty(spr: PQueuedSprite;
    const rects: TDirtyRectArray; count: byte): boolean;
var i: byte;
begin
    Result := false;
    if (spr = nil) or (count = 0) then exit;
    for i := 0 to count - 1 do
        if (spr^.x < rects[i].x + rects[i].widthPx) and
           (rects[i].x < spr^.x + spr^.widthPx) and
           (spr^.y < rects[i].y + rects[i].heightPx) and
           (rects[i].y < spr^.y + spr^.heightPx) then begin
            Result := true;
            exit;
        end;
end;

procedure RestoreDirtyRects(const rects: TDirtyRectArray; count: byte;
    forceFullCopy: boolean);
var i: byte;
begin
    if forceFullCopy then begin
        BlitterCopyData16(SCREEN_BKG, SCREEN_LOG, SCREEN_BYTES);
        exit;
    end;
    if count = 0 then exit;
    for i := 0 to count - 1 do
        BlitterCopyBitmap4(
            SCREEN_BKG, SCREEN_LOG,
            rects[i].widthPx, rects[i].heightPx,
            rects[i].x, rects[i].y,
            rects[i].x, rects[i].y,
            320, 320
        );
end;

procedure RenderQueuedSprites;
var rects: TDirtyRectArray;
    dirtyCount, oldCount, newCount, compareCount: byte;
    i: byte;
    dirtyPixels: longword;
    forceFullCopy: boolean;
    spr: PQueuedSprite;
begin
    dirtyCount := 0;
    oldCount := renderedSpriteCount[screenLogIndex];
    newCount := queuedSpriteCount[screenLogIndex];
    compareCount := oldCount;
    if newCount > compareCount then compareCount := newCount;

    if compareCount > 0 then
        for i := 0 to compareCount - 1 do begin
            if (i < oldCount) and (i < newCount) and
               QueuedSpritesEqual(
                   @renderedSprites[screenLogIndex, i],
                   @queuedSprites[screenLogIndex, i]
               ) then
                continue;
            if i < oldCount then
                AddDirtySpriteRect(rects, dirtyCount,
                    @renderedSprites[screenLogIndex, i]);
            if i < newCount then
                AddDirtySpriteRect(rects, dirtyCount,
                    @queuedSprites[screenLogIndex, i]);
        end;

    dirtyPixels := 0;
    if dirtyCount > 0 then
        for i := 0 to dirtyCount - 1 do
            Inc(dirtyPixels, longword(rects[i].widthPx) * rects[i].heightPx);
    forceFullCopy := (dirtyCount >= DIRTY_FULL_COPY_RECTS) or
        (dirtyPixels >= DIRTY_FULL_COPY_PIXELS);
    RestoreDirtyRects(rects, dirtyCount, forceFullCopy);

    if newCount > 0 then
        for i := 0 to newCount - 1 do begin
            spr := @queuedSprites[screenLogIndex, i];
            if spr^.frame = nil then continue;
            if forceFullCopy or SpriteIntersectsDirty(spr, rects, dirtyCount) then
                DrawGeneratedSpriteFrameBlitter(
                    SCREEN_LOG,
                    spr^.x,
                    spr^.y,
                    spr^.frame,
                    spr^.wordsBase
                );
        end;

    renderedSpriteCount[screenLogIndex] := newCount;
    if newCount > 0 then
        for i := 0 to newCount - 1 do
            renderedSprites[screenLogIndex, i] := queuedSprites[screenLogIndex, i];
    queuedSpriteCount[screenLogIndex] := 0;
end;

procedure FlushQueuedSprites;
begin
    RenderQueuedSprites;
end;

procedure PresentQueuedSprites;
begin
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

function ResolveWorldTextPtr(addr: word): PByte;
var ofs: word;
    dataPtr, assetPtr: PByte;
begin
    Result := nil;
    if addr < $A000 then exit;
    ofs := addr - $A000;

    dataPtr := nil;
    if (currentWorldData <> nil) and (ofs + 79 < WORLD_DATA_BYTES) then
        dataPtr := PByte(longword(currentWorldData) + ofs);

    assetPtr := nil;
    if (currentWorldAssets <> nil) and (ofs + 79 < currentWorldAssetsSize) then
        assetPtr := PByte(longword(currentWorldAssets) + ofs);

    // Message/scene text labels live in the asset bank in the original worlds.
    // Prefer that bank here and only fall back to world data if needed.
    if assetPtr <> nil then
        Result := assetPtr
    else
        Result := dataPtr;
end;

function DecodeWorldTextLine(addr: word; line: byte): string;
var p: PByte;
    q: PByte;
    i: integer;
    b: byte;
    raw: AnsiString;
begin
    Result := '';
    raw := '';
    p := ResolveWorldTextPtr(addr);
    if p = nil then exit;
    SetLength(raw, 40);
    q := p;
    Inc(q, word(line) * 40);
    for i := 0 to 39 do begin
        b := q^;
        raw[i + 1] := Chr(b and $7F);
        Inc(q);
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
var scoreStr, roomStr: string;
    scoreX, roomX: word;
begin
    BlitterClearBitmap4(scr, 320, 20, 0, 0, 320);
    // FillRect16(scr, 0, HUD_HEIGHT, 320, 2, 1);
    DrawTextTo(scr, 8, 0, 1, 0, Antic2Ascii(world.name));
    scoreStr := PackedBcdToScore5(mySlime);
    scoreX := 320 - 8 - Length(scoreStr) * 8;
    DrawTextTo(scr, scoreX, 0, 1, 0, scoreStr);
    roomStr := 'W' + ByteToStr(worldCurrent) + ' R';
    if levelNum < 10 then roomStr := roomStr + '0';
    roomStr := roomStr + ByteToStr(levelNum);
    roomX := scoreX - 8 - Length(roomStr) * 8;
    DrawTextTo(scr, roomX, 0, 2, 0, roomStr);
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

procedure RefreshMessageCache;
begin
    if (not messageCacheDirty) or (SCREEN_BKG = nil) then exit;
    DrawMessageTo(SCREEN_BKG);
    messageCacheDirty := false;
end;

procedure RefreshOverlayBuffers;
begin
    RefreshMessageCache;
    if SCREEN_LOG <> nil then begin
        CopyHudArea(SCREEN_BKG, SCREEN_LOG);
        CopyMessageArea(SCREEN_BKG, SCREEN_LOG);
    end;
    if SCREEN_PHY <> nil then begin
        CopyHudArea(SCREEN_BKG, SCREEN_PHY);
        CopyMessageArea(SCREEN_BKG, SCREEN_PHY);
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
    Result := PByte(longword(currentWorldAssets) + ofs);
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

procedure ClearSprite(num: byte);
begin
    // RestoreSpriteBackground(num);
    // spritePtr[num] := 0;
end;

procedure ClearSprites;
begin
    // if sprites.state = SPRITE_NONE then exit;
    // if sprites.state > SPRITE_NONE then ClearSprite(0);
    // if sprites.state > SPRITE_SINGLE then ClearSprite(1);
end;

procedure ShowSprite(num: byte);
var x, y, h, frameCount, frameIdx: byte;
    frame: PSteSpriteFrame;
    dstX, dstY: word;
    drawX, drawY: smallint;
begin
    spritePtr[num] := 0;
    if spriteAtlasFrames[num] = nil then exit;
    if spriteAtlasWords[num] = nil then exit;
    frameCount := spriteData.frameCount[num];
    if frameCount = 0 then frameCount := spriteAtlasFrameCount[num];
    if frameCount = 0 then exit;

    if (sprites.stype[num] = STYPE_EXIT) and not mainGoalReached then exit;
    if ((sprites.stype[num] = STYPE_DECOR) or (sprites.stype[num] = STYPE_GOAL)) and
        (sprites.goal[num] <> NONE) and (goals[sprites.goal[num]] = 0) then exit;
    if (sprites.stype[num] = STYPE_DIAL) and
        (sprites.param2[num] <> $ff) and (goals[sprites.param2[num]] > 0) then exit;

    h := spriteData.height[num];
    frameIdx := spriteFrame[num];
    if frameIdx >= frameCount then frameIdx := 0;
    if flipped and (sprites.flipable[num] = 1) and
        (spriteAtlasFrameCount[num] >= frameCount + frameCount) then
        Inc(frameIdx, frameCount);
    frame := PSteSpriteFrame(longword(spriteAtlasFrames[num]) + longword(frameIdx) * SizeOf(TSteSpriteFrame));

    x := sprites.x[num];
    y := sprites.y[num];
    if flipped and (sprites.flipable[num] = 1) then
        y := 80 - (h + y);
    if (num = 1) and (sprites.state = SPRITE_COMBINED) then
        x := x + sprites.gap;

    drawX := smallint(x) * LEVEL_SCALE_X + WORLD_SPRITE_OFFSET_X;
    drawY := LEVEL_OFFSET_Y + smallint(y) * LEVEL_SCALE_Y + WORLD_SPRITE_OFFSET_Y;
    if drawX < 0 then drawX := 0;
    if drawY < 0 then drawY := 0;
    dstX := word(drawX);
    dstY := word(drawY);

    QueueGeneratedSprite(dstX, dstY, frame, spriteAtlasWords[num], nil, 0);
    spritePtr[num] := 1;
end;

procedure ShowSprites;
begin
    if sprites.state = SPRITE_NONE then exit;
    if sprites.state > SPRITE_NONE then ShowSprite(0);
    if sprites.state > SPRITE_SINGLE then ShowSprite(1);
end;

function GeneratedSpriteOpaqueAt(frame: PSteSpriteFrame; wordsBase: PWord; px, py: smallint): boolean;
var maskBase: PWord;
    maskWord: word;
begin
    Result := false;
    if frame = nil then exit;
    if wordsBase = nil then exit;
    if (px < 0) or (py < 0) then exit;
    if (word(px) >= frame^.widthPx) or (word(py) >= frame^.heightPx) then exit;

    maskBase := wordsBase;
    Inc(maskBase, frame^.maskOffset);
    Inc(maskBase, word(py) * frame^.rowWords + word(px shr 4));
    maskWord := maskBase^;
    Result := (maskWord and (word($8000) shr (px and 15))) = 0;
end;

function GeneratedSpritesOverlap(frameA: PSteSpriteFrame; wordsA: PWord; ax, ay: smallint;
    frameB: PSteSpriteFrame; wordsB: PWord; bx, by: smallint): boolean;
var left, top, right, bottom: smallint;
    x, y: smallint;
begin
    Result := false;
    if (frameA = nil) or (frameB = nil) then exit;
    if (wordsA = nil) or (wordsB = nil) then exit;

    left := ax;
    if bx > left then left := bx;
    top := ay;
    if by > top then top := by;
    right := ax + smallint(frameA^.widthPx);
    if bx + smallint(frameB^.widthPx) < right then right := bx + smallint(frameB^.widthPx);
    bottom := ay + smallint(frameA^.heightPx);
    if by + smallint(frameB^.heightPx) < bottom then bottom := by + smallint(frameB^.heightPx);
    if (left >= right) or (top >= bottom) then exit;

    for y := top to bottom - 1 do
        for x := left to right - 1 do
            if GeneratedSpriteOpaqueAt(frameA, wordsA, x - ax, y - ay) and
               GeneratedSpriteOpaqueAt(frameB, wordsB, x - bx, y - by) then begin
                Result := true;
                exit;
            end;
end;

procedure ShowLevelName;
begin
    RefreshOverlayBuffers;
end;

procedure InitLevelScreen;
begin
    ShowLevelName;
end;

// ***************************************************
// *** SOUND
// ***************************************************

procedure PlaySong(p: byte);
var packedMusic: pointer;
begin
    if not soundReady then exit;
    packedMusic := nil;
    case p of
        MUSIC_THEME:   packedMusic := @MUSIC_THEME_FYM_APL[0];
        MUSIC_LEVEL: begin
            case music_track of
                0: packedMusic := @MUSIC_WORLD_00_FYM_APL[0];
                1: packedMusic := @MUSIC_WORLD_01_FYM_APL[0];
                2: packedMusic := @MUSIC_WORLD_02_FYM_APL[0];
                3: packedMusic := @MUSIC_WORLD_03_FYM_APL[0];
                4: packedMusic := @MUSIC_WORLD_04_FYM_APL[0];
            end;
        end;
        MUSIC_INTRO:   packedMusic := @MUSIC_INTRO_FYM_APL[0];
        MUSIC_OUTRO:   packedMusic := @MUSIC_OUTRO_FYM_APL[0];
        MUSIC_ENDGAME: packedMusic := @MUSIC_ENDGAME_FYM_APL[0];
    end;

    PsgMusicStop;
    music_on := 0;
    if packedMusic = nil then exit;
    UnApl(packedMusic, @musicBuffer[0]);
    PsgMusicPlay(@musicBuffer[0]);
    music_on := 1;
end;

procedure StopSong;
begin
    if soundReady then PsgMusicStop;
    music_on := 0;
end;

procedure InitSound;
begin
    soundReady := false;
    usePsgSfx := PSG_SFX_DEFAULT;
    sfxSynthActive := false;
    DmaSoundInit;
    PsgSoundInit;
    soundReady := true;
end;

procedure DoneSound;
begin
    if soundReady then begin
        PsgSoundDone;
        DmaSoundDone;
    end;
    soundReady := false;
end;

procedure StartSynthSfx(data: PByte; dataSize: word);
begin
    if soundReady then DmaSoundStop;
    sfxSynthData := data;
    sfxSynthDataSize := dataSize;
    sfxSynthOffset := 0;
    sfxSynthRunFrames := 0;
    sfxSynthAudf := 0;
    sfxSynthAudc := 0;
    sfxSynthOutput := 0;
    sfxSynthPoly4Pos := 0;
    sfxSynthPoly5Pos := 0;
    sfxSynthPhase := 0;
    sfxSynthNoise := $13579BDF;
    sfxSynthStreaming := false;
    sfxSynthBufferIndex := 0;
    sfxSynthSilentHalves := 0;
    sfxSynthActive := (data <> nil) and (dataSize >= 3);
end;

function RenderSynthBlock(dst: PByte): boolean;
const
    SFX_ASM_GATE_POLY5 = 1;
    SFX_ASM_PURE = 2;
    SFX_ASM_POLY4 = 4;
    SFX_ASM_NOISE = 8;
var
    divider: word;
    volume: byte;
    gateWithPoly5, usePure, usePoly4, useNoise: boolean;
    state: TSfxSynthAsmState;
begin
    if sfxSynthRunFrames = 0 then begin
        if sfxSynthOffset + 2 >= sfxSynthDataSize then begin
            FillChar(dst^, SFX_SAMPLES_PER_FRAME, 0);
            exit(false);
        end;
        sfxSynthRunFrames := sfxSynthData[sfxSynthOffset];
        sfxSynthAudf := sfxSynthData[sfxSynthOffset + 1];
        sfxSynthAudc := sfxSynthData[sfxSynthOffset + 2];
        Inc(sfxSynthOffset, 3);
    end;

    volume := sfxSynthAudc and 15;
    if volume = 0 then
        FillChar(dst^, SFX_SAMPLES_PER_FRAME, 0)
    else begin
        divider := (word(sfxSynthAudf) + 1) * SFX_POKEY_BASE_DIV;
        gateWithPoly5 := (sfxSynthAudc and $80) = 0;
        usePure := (sfxSynthAudc and $20) <> 0;
        usePoly4 := (not usePure) and ((sfxSynthAudc and $40) <> 0);
        useNoise := (not usePure) and (not usePoly4);

        state.phase := sfxSynthPhase;
        state.threshold := longword(divider) * SFX_SAMPLE_RATE;
        state.noise := sfxSynthNoise;
        state.poly4Pos := sfxSynthPoly4Pos;
        state.poly5Pos := sfxSynthPoly5Pos;
        state.stride4 := divider mod 15;
        state.stride5 := divider mod 31;
        state.positiveSample := volume * SFX_AMPLITUDE_STEP;
        state.negativeSample := byte(-shortint(state.positiveSample));
        state.flags := 0;
        if gateWithPoly5 then state.flags := state.flags or SFX_ASM_GATE_POLY5;
        if usePure then state.flags := state.flags or SFX_ASM_PURE;
        if usePoly4 then state.flags := state.flags or SFX_ASM_POLY4;
        if useNoise then state.flags := state.flags or SFX_ASM_NOISE;
        state.output := sfxSynthOutput;

        SfxRenderBlockAsm(dst, SFX_SAMPLES_PER_FRAME, @state);
        sfxSynthPhase := state.phase;
        sfxSynthNoise := state.noise;
        sfxSynthPoly4Pos := state.poly4Pos;
        sfxSynthPoly5Pos := state.poly5Pos;
        sfxSynthOutput := state.output;
    end;

    Dec(sfxSynthRunFrames);
    Result := true;
end;

procedure SfxSynthFrame;
var
    rendered: boolean;
    currentVbl, elapsedVbl: longword;
    blocks, i: byte;
begin
    if (not soundReady) or (not sfxSynthActive) then exit;

    if not sfxSynthStreaming then begin
        for i := 0 to SFX_BUFFER_HALVES - 1 do begin
            rendered := RenderSynthBlock(@sfxSynthBuffer[i, 0]);
            if rendered then sfxSynthSilentHalves := 0
            else Inc(sfxSynthSilentHalves);
        end;

        if sfxSynthSilentHalves >= SFX_BUFFER_HALVES then begin
            sfxSynthActive := false;
            exit;
        end;
        DmaPlayLoop(@sfxSynthBuffer[0, 0], SizeOf(sfxSynthBuffer));
        sfxSynthStreaming := true;
        sfxSynthBufferIndex := 0;
        sfxSynthLastVbl := PLongWord(pointer(longword($00000466)))^;
        exit;
    end;

    currentVbl := PLongWord(pointer(longword($00000466)))^;
    elapsedVbl := currentVbl - sfxSynthLastVbl;
    if elapsedVbl = 0 then exit;
    sfxSynthLastVbl := currentVbl;

    if elapsedVbl > SFX_BUFFER_HALVES then blocks := SFX_BUFFER_HALVES
    else blocks := byte(elapsedVbl);
    for i := 1 to blocks do begin
        rendered := RenderSynthBlock(
            @sfxSynthBuffer[sfxSynthBufferIndex, 0]
        );
        if rendered then sfxSynthSilentHalves := 0
        else Inc(sfxSynthSilentHalves);
        Inc(sfxSynthBufferIndex);
        if sfxSynthBufferIndex >= SFX_BUFFER_HALVES then
            sfxSynthBufferIndex := 0;
    end;

    if sfxSynthSilentHalves >= SFX_BUFFER_HALVES then begin
        DmaSoundStop;
        sfxSynthStreaming := false;
        sfxSynthActive := false;
    end;
end;

procedure FSfx(patch: byte);
var
    synthData: PByte;
    synthDataSize: word;
    psgData: PByte;
    psgDataSize: word;
begin
    synthData := nil;
    synthDataSize := 0;
    psgData := nil;
    psgDataSize := 0;
    case patch of
        SFX_FLIP: begin
            synthData := @SFX_FLIP_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_FLIP_SYNTH_DATA);
            psgData := @SFX_FLIP_PSG_DATA[0]; psgDataSize := SizeOf(SFX_FLIP_PSG_DATA);
        end;
        SFX_SLIMEPICK: begin
            synthData := @SFX_SLIME_PICK_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_SLIME_PICK_SYNTH_DATA);
            psgData := @SFX_SLIME_PICK_PSG_DATA[0]; psgDataSize := SizeOf(SFX_SLIME_PICK_PSG_DATA);
        end;
        SFX_DEAD: begin
            synthData := @SFX_DEAD_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_DEAD_SYNTH_DATA);
            psgData := @SFX_DEAD_PSG_DATA[0]; psgDataSize := SizeOf(SFX_DEAD_PSG_DATA);
        end;
        SFX_PICKALL: begin
            synthData := @SFX_PICK_ALL_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_PICK_ALL_SYNTH_DATA);
            psgData := @SFX_PICK_ALL_PSG_DATA[0]; psgDataSize := SizeOf(SFX_PICK_ALL_PSG_DATA);
        end;
        SFX_PICKGOAL: begin
            synthData := @SFX_PICK_GOAL_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_PICK_GOAL_SYNTH_DATA);
            psgData := @SFX_PICK_GOAL_PSG_DATA[0]; psgDataSize := SizeOf(SFX_PICK_GOAL_PSG_DATA);
        end;
        SFX_REVEAL: begin
            synthData := @SFX_REVEAL_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_REVEAL_SYNTH_DATA);
            psgData := @SFX_REVEAL_PSG_DATA[0]; psgDataSize := SizeOf(SFX_REVEAL_PSG_DATA);
        end;
        SFX_BIGSLIME: begin
            synthData := @SFX_BIG_SLIME_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_BIG_SLIME_SYNTH_DATA);
            psgData := @SFX_BIG_SLIME_PSG_DATA[0]; psgDataSize := SizeOf(SFX_BIG_SLIME_PSG_DATA);
        end;
        SFX_CONSOLE: begin
            synthData := @SFX_CONSOLE_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_CONSOLE_SYNTH_DATA);
            psgData := @SFX_CONSOLE_PSG_DATA[0]; psgDataSize := SizeOf(SFX_CONSOLE_PSG_DATA);
        end;
        SFX_WATERDROP: begin
            synthData := @SFX_WATER_DROP_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_WATER_DROP_SYNTH_DATA);
            psgData := @SFX_WATER_DROP_PSG_DATA[0]; psgDataSize := SizeOf(SFX_WATER_DROP_PSG_DATA);
        end;
        SFX_LEVER: begin
            synthData := @SFX_LEVER_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_LEVER_SYNTH_DATA);
            psgData := @SFX_LEVER_PSG_DATA[0]; psgDataSize := SizeOf(SFX_LEVER_PSG_DATA);
        end;
        SFX_SIREN: begin
            synthData := @SFX_SIREN_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_SIREN_SYNTH_DATA);
            psgData := @SFX_SIREN_PSG_DATA[0]; psgDataSize := SizeOf(SFX_SIREN_PSG_DATA);
        end;
        SFX_CIRCUIT: begin
            synthData := @SFX_CIRCUIT_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_CIRCUIT_SYNTH_DATA);
            psgData := @SFX_CIRCUIT_PSG_DATA[0]; psgDataSize := SizeOf(SFX_CIRCUIT_PSG_DATA);
        end;
        SFX_GEAR: begin
            synthData := @SFX_GEAR_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_GEAR_SYNTH_DATA);
            psgData := @SFX_GEAR_PSG_DATA[0]; psgDataSize := SizeOf(SFX_GEAR_PSG_DATA);
        end;
        SFX_VALVE: begin
            synthData := @SFX_VALVE_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_VALVE_SYNTH_DATA);
            psgData := @SFX_VALVE_PSG_DATA[0]; psgDataSize := SizeOf(SFX_VALVE_PSG_DATA);
        end;
        SFX_BELL: begin
            synthData := @SFX_BELL_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_BELL_SYNTH_DATA);
            psgData := @SFX_BELL_PSG_DATA[0]; psgDataSize := SizeOf(SFX_BELL_PSG_DATA);
        end;
        SFX_GAS: begin
            synthData := @SFX_GAS_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_GAS_SYNTH_DATA);
            psgData := @SFX_GAS_PSG_DATA[0]; psgDataSize := SizeOf(SFX_GAS_PSG_DATA);
        end;
        SFX_INSECT: begin
            synthData := @SFX_INSECT_SYNTH_DATA[0]; synthDataSize := SizeOf(SFX_INSECT_SYNTH_DATA);
            psgData := @SFX_INSECT_PSG_DATA[0]; psgDataSize := SizeOf(SFX_INSECT_PSG_DATA);
        end;
    end;

    if soundReady and (synthData <> nil) then begin
        if usePsgSfx then begin
            DmaSoundStop;
            sfxSynthActive := false;
            PsgSoundPlay(psgData, psgDataSize);
        end else begin
            PsgSoundStop;
            StartSynthSfx(synthData, synthDataSize);
        end;
    end;
    sfxDelay := FORCE_SFX_DELAY;
end;

procedure Sfx(patch: byte);
begin
    if (not music_ingame) or (sfxDelay = 0) then begin
        FSfx(patch);
        sfxDelay := DEFAULT_SFX_DELAY;
    end;
end;

{$i input.inc}

// ***************************************************
// *** HELPERS (from original flob.pas)
// ***************************************************

function IsStereoPresent: boolean;
begin
    Result := false; // stub
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

    if csbank = CREDITS_BANK then begin
        case slide of
            0: begin c0 := $3f; c1 := $34; c2 := $38; bg := $00; end;
            1: begin c0 := $98; c1 := $9f; c2 := $94; bg := $00; end;
            2: begin c0 := $18; c1 := $1f; c2 := $14; bg := $00; end;
            3: begin c0 := $b8; c1 := $bf; c2 := $b4; bg := $00; end;
            4: begin c0 := $78; c1 := $7f; c2 := $74; bg := $00; end;
            5: begin c0 := $28; c1 := $2f; c2 := $24; bg := $00; end;
            6: begin c0 := $e8; c1 := $ef; c2 := $e4; bg := $00; end;
            7: begin c0 := $0a; c1 := $0f; c2 := $04; bg := $00; end;
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
    // FillRect16(scr, 0, 168, 320, 32, bg);
    BlitterClearBitmap4(scr, 320, 32, 0, 168, 320);
end;

procedure DrawCutsceneLine(scr: pword; const l0, l1, l2, l3: string;
    line, color: byte);
begin
    case line of
        1: DrawTextCenteredTo(scr, 168, color, 0, l0);
        2: DrawTextCenteredTo(scr, 176, color, 0, l1);
        3: DrawTextCenteredTo(scr, 184, color, 0, l2);
        4: DrawTextCenteredTo(scr, 192, color, 0, l3);
    end;
end;

procedure RenderCutsceneText(scr: pword; const l0, l1, l2, l3: string;
    visibleLines: byte);
var line, color: byte;
begin
    DrawCutsceneTextBlock(scr, 0);
    for line := 1 to visibleLines do begin
        color := CUTSCENE_TEXT_COLOR;
        if line = visibleLines then color := CUTSCENE_FADE_COLOR;
        DrawCutsceneLine(scr, l0, l1, l2, l3, line, color);
    end;
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

procedure LoadAchievement(achNum: byte);
begin
    if achNum < ACHIEVEMENT_DEF_COUNT then
        achievement := ACHIEVEMENT_DEFS[achNum]
    else
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

procedure PlaySoundFx(patch: byte);
begin
    Sfx(patch);
end;

procedure DrawEndWorldIcon(iconData: pointer);
// Icon is END_ICON_WIDTH x END_ICON_HEIGHT (64x80 at 2x scale).
// Centre horizontally: (320 - 64) / 2 = 128, which is a multiple of 16. ✓
const ICON_DST_X = 128;
      ICON_DST_Y = 32;
begin
    if iconData = nil then exit;
    BlitterCopyBitmap4(
        iconData,
        SCREEN_LOG,
        END_ICON_WIDTH,
        END_ICON_HEIGHT,
        0,
        0,
        ICON_DST_X,
        ICON_DST_Y,
        END_ICON_WIDTH,
        320
    );
end;

procedure ShowEndWorldScreen(sec, score: word);
var iconData: pointer;
    timeStr, scoreStr, pickedStr, totalStr: string[20];
    line: string[40];
    iconC0, iconC1, iconC2: byte;
begin
    BlackAll;
    ClearScreen(SCREEN_LOG);
    FillChar(titlePalette, SizeOf(titlePalette), 0);

    // Flatten dliselect's separate title, icon and statistics colour bands.
    if mainGoalReached then begin
        DrawSelectorShadow('Congratulations!', 8, 4, 5);
        iconC0 := $82;
        iconC1 := world.goalcolor1;
        iconC2 := world.goalcolor2;
        titlePalette[4] := STE_PAL[$18];
        titlePalette[5] := STE_PAL[$14];
        if worldCurrent = 0 then begin
            iconData := @END_ICON_BIGMAP[0];
            iconC1 := $BA;
            iconC2 := $26;
        end else if worldCurrent = 5 then
            iconData := @END_ICON_BIGFORMULA[0]
        else
            iconData := @END_ICON_BIGVIAL[0];
    end else begin
        DrawSelectorShadow('Game Over', 8, 4, 5);
        iconData := @END_ICON_SKULL[0];
        iconC0 := $38;
        iconC1 := $3F;
        iconC2 := $34;
        titlePalette[4] := STE_PAL[$98];
        titlePalette[5] := STE_PAL[$94];
    end;
    // Canonical GIF/PNG indices 0,1,2,3 encode A8 selectors 0,3,1,2.
    titlePalette[1] := STE_PAL[iconC2];
    titlePalette[2] := STE_PAL[iconC0];
    titlePalette[3] := STE_PAL[iconC1];
    titlePalette[6] := STE_PAL[world.goalcolor2];
    titlePalette[7] := STE_PAL[$9A];
    titlePalette[8] := STE_PAL[$94];

    DrawEndWorldIcon(iconData);

    // A8 source rows 60,71,81 doubled, plus the centred 8-line margin.
    Sec2TimeInS1(sec);
    timeStr := s1;
    Str(score, scoreStr);
    Str(pickedSlimeCount, pickedStr);
    Str(world.totalSlimeCount, totalStr);

    line := 'Game Time ' + timeStr;
    DrawSelectorText(line, 128, 6);
    line := 'Score ' + scoreStr;
    DrawSelectorShadow(line, 150, 7, 8);
    line := 'Slimes ' + pickedStr + ' of ' + totalStr;
    DrawSelectorShadow(line, 170, 7, 8);

    currentPal := @titlePalette[0];
    roomSpritePaletteActive := false;
    SwapScreen;
    FadeIn;
end;

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
    byteOfs := (word(sampleY) shl 5) + (word(sampleY) shl 3) + word(x shr 2);
    packedByte := currentCollisionData[byteOfs];
    shift := 6 - ((x and 3) shl 1);
    Result := (packedByte shr shift) and 3;
end;

function IsSolidPix(p: byte): boolean; inline;
begin
    Result := p = GROUND_COLLISION_COLOR;
end;

function IsDynamicDangerPix(x, y: byte): boolean; inline;
var sampleY: byte;
    offset: word;
    mask: byte;
begin
    Result := false;
    if (x >= 160) or (y >= 80) then exit;
    if flipped then sampleY := 79 - y
    else sampleY := y;
    offset := word(sampleY) * 20 + word(x shr 3);
    mask := byte($80 shr (x and 7));
    Result := (dynamicTileDanger[offset] and mask) <> 0;
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
var packedWorldData: pointer;
begin
    packedWorldData := nil;
    currentWorldData := @worldDataBuffer[0];
    case w of
        0: begin
            packedWorldData := @WORLD_00_DATA_APL[0];
            currentWorldAssets  := @WORLD_00_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_00_ASSETS) + 1;
            currentWorldImgPtrs := @W00_IMG_PTRS[0];
            currentWorldPalPtrs := @W00_PAL_PTRS[0];
            currentWorldColAplPtrs := @W00_COL_APL_PTRS[0];
            currentWorldImgCount := W00_IMG_COUNT;
            currentWorldTiles := @W00_TILES[0];
            currentWorldTileWords := @W00_TILE_WORDS[0];
            currentWorldTileCollision := @W00_TILE_COLLISION[0];
            currentWorldTileCount := W00_TILE_COUNT;
        end;
        1: begin
            packedWorldData := @WORLD_01_DATA_APL[0];
            currentWorldAssets  := @WORLD_01_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_01_ASSETS) + 1;
            currentWorldImgPtrs := @W01_IMG_PTRS[0];
            currentWorldPalPtrs := @W01_PAL_PTRS[0];
            currentWorldColAplPtrs := @W01_COL_APL_PTRS[0];
            currentWorldImgCount := W01_IMG_COUNT;
            currentWorldTiles := @W01_TILES[0];
            currentWorldTileWords := @W01_TILE_WORDS[0];
            currentWorldTileCollision := @W01_TILE_COLLISION[0];
            currentWorldTileCount := W01_TILE_COUNT;
        end;
        2: begin
            packedWorldData := @WORLD_02_DATA_APL[0];
            currentWorldAssets  := @WORLD_02_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_02_ASSETS) + 1;
            currentWorldImgPtrs := @W02_IMG_PTRS[0];
            currentWorldPalPtrs := @W02_PAL_PTRS[0];
            currentWorldColAplPtrs := @W02_COL_APL_PTRS[0];
            currentWorldImgCount := W02_IMG_COUNT;
            currentWorldTiles := @W02_TILES[0];
            currentWorldTileWords := @W02_TILE_WORDS[0];
            currentWorldTileCollision := @W02_TILE_COLLISION[0];
            currentWorldTileCount := W02_TILE_COUNT;
        end;
        3: begin
            packedWorldData := @WORLD_03_DATA_APL[0];
            currentWorldAssets  := @WORLD_03_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_03_ASSETS) + 1;
            currentWorldImgPtrs := @W03_IMG_PTRS[0];
            currentWorldPalPtrs := @W03_PAL_PTRS[0];
            currentWorldColAplPtrs := @W03_COL_APL_PTRS[0];
            currentWorldImgCount := W03_IMG_COUNT;
            currentWorldTiles := @W03_TILES[0];
            currentWorldTileWords := @W03_TILE_WORDS[0];
            currentWorldTileCollision := @W03_TILE_COLLISION[0];
            currentWorldTileCount := W03_TILE_COUNT;
        end;
        4: begin
            packedWorldData := @WORLD_04_DATA_APL[0];
            currentWorldAssets  := @WORLD_04_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_04_ASSETS) + 1;
            currentWorldImgPtrs := @W04_IMG_PTRS[0];
            currentWorldPalPtrs := @W04_PAL_PTRS[0];
            currentWorldColAplPtrs := @W04_COL_APL_PTRS[0];
            currentWorldImgCount := W04_IMG_COUNT;
            currentWorldTiles := @W04_TILES[0];
            currentWorldTileWords := @W04_TILE_WORDS[0];
            currentWorldTileCollision := @W04_TILE_COLLISION[0];
            currentWorldTileCount := W04_TILE_COUNT;
        end;
        5: begin
            packedWorldData := @WORLD_05_DATA_APL[0];
            currentWorldAssets  := @WORLD_05_ASSETS[0];
            currentWorldAssetsSize := High(WORLD_05_ASSETS) + 1;
            currentWorldImgPtrs := @W05_IMG_PTRS[0];
            currentWorldPalPtrs := @W05_PAL_PTRS[0];
            currentWorldColAplPtrs := @W05_COL_APL_PTRS[0];
            currentWorldImgCount := W05_IMG_COUNT;
            currentWorldTiles := @W05_TILES[0];
            currentWorldTileWords := @W05_TILE_WORDS[0];
            currentWorldTileCollision := @W05_TILE_COLLISION[0];
            currentWorldTileCount := W05_TILE_COUNT;
        end;
    end;
    if packedWorldData = nil then exit;
    UnApl(packedWorldData, currentWorldData);
    Move(currentWorldData[0], world, SizeOf(TWorld));
    FixWorldEndian(world);
end;

procedure InitWorld;
begin
    levelNum := world.start;
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
    ClearTxt2;
    SetLanded;
    SetLandingSafe;
    room_landed := false;
    first_landed := false;
    teleported := false;
    landedTime := 0;
    triggerGrace := 0;
    spriteCollisionMovePending := false;
    teleportTriggerReleasePending := false;
    teleportPortalReleasePending := false;
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
    SetupWorldSpriteAtlas(worldCurrent, addr);
    base := SpriteAssetPtr(addr);
    if base = nil then exit;

    spriteData.bank := bank;
    for p := 0 to 1 do spriteData.frameCount[p] := base[p];
    for p := 0 to 1 do spriteData.height[p] := base[2 + p];

    Inc(base, 4);
    for p := 0 to 1 do begin
        frameCount := spriteData.frameCount[p];
        h := spriteData.height[p];
        if frameCount > 0 then spriteColorsRaw[p] := base
        else spriteColorsRaw[p] := nil;
        Inc(base, frameCount);
        if frameCount > 0 then
            for f := 0 to frameCount - 1 do
                spriteFramesRaw[p, f] := @base[word(f) * word(h)];
        Inc(base, word(frameCount) * word(h));
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
    if spriteAtlasFrames[num] = nil then exit;
    if spriteAtlasWords[num] = nil then exit;
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
    w := (spriteAtlasFrames[num]^.widthPx + LEVEL_SCALE_X - 1) div LEVEL_SCALE_X;
    Result := true;
end;

function RectsOverlap(ax, ay, aw, ah, bx, by, bw, bh: byte): boolean;
begin
    Result := (ax < bx + bw) and (bx < ax + aw) and
              (ay < by + bh) and (by < ay + ah);
end;

function WorldSpritePixelCollision(num: byte): boolean;
var frameIdx: byte;
    frame: PSteSpriteFrame;
    frameCount: byte;
    x, y, h: byte;
    flobFrameIdx: byte;
    flobFramePtr: PSteSpriteFrame;
    flobScreenX, flobScreenY: smallint;
    spriteScreenX, spriteScreenY: smallint;
begin
    Result := false;
    if num > 1 then exit;
    if spriteAtlasFrames[num] = nil then exit;
    if spriteAtlasWords[num] = nil then exit;
    frameCount := spriteData.frameCount[num];
    if frameCount = 0 then frameCount := spriteAtlasFrameCount[num];
    if frameCount = 0 then exit;

    frameIdx := spriteFrame[num];
    if frameIdx >= frameCount then frameIdx := 0;
    if flipped and (sprites.flipable[num] = 1) and
        (spriteAtlasFrameCount[num] >= frameCount + frameCount) then
        Inc(frameIdx, frameCount);
    frame := PSteSpriteFrame(longword(spriteAtlasFrames[num]) + longword(frameIdx) * SizeOf(TSteSpriteFrame));

    x := sprites.x[num];
    y := sprites.y[num];
    h := spriteData.height[num];
    if flipped and (sprites.flipable[num] = 1) then
        y := 80 - (h + y);
    if (num = 1) and (sprites.state = SPRITE_COMBINED) then
        x := x + sprites.gap;

    flobFrameIdx := flobFrame + flobDir;
    if flobFrameIdx > High(SPR_FLOB_FRAMES) then exit;
    flobFramePtr := @SPR_FLOB_FRAMES[flobFrameIdx];
    flobScreenX := smallint(flobX) * LEVEL_SCALE_X;
    flobScreenY := FLOB_RENDER_OFFSET_Y + smallint(flobY) * LEVEL_SCALE_Y;
    spriteScreenX := smallint(x) * LEVEL_SCALE_X + WORLD_SPRITE_OFFSET_X;
    spriteScreenY := LEVEL_OFFSET_Y + smallint(y) * LEVEL_SCALE_Y + WORLD_SPRITE_OFFSET_Y;

    Result := GeneratedSpritesOverlap(
        flobFramePtr,
        @SPR_FLOB_WORDS[0],
        flobScreenX,
        flobScreenY,
        frame,
        spriteAtlasWords[num],
        spriteScreenX,
        spriteScreenY
    );
end;

procedure CheckSpriteCollisions;
// Flob renders at screen_Y = FLOB_RENDER_OFFSET_Y + flobY * LEVEL_SCALE_Y.
// Sprites render at screen_Y = LEVEL_OFFSET_Y + sprites.y * LEVEL_SCALE_Y + WORLD_SPRITE_OFFSET_Y = 20 + y*2
const FLOB_TO_SPRITE_Y =
    (LEVEL_OFFSET_Y + WORLD_SPRITE_OFFSET_Y - FLOB_RENDER_OFFSET_Y) div LEVEL_SCALE_Y;
var fx, fy, fw, fh: byte;
    sx, sy, sw, sh: byte;
    p: byte;
    waitingForPortalRelease: boolean;
begin
    fx := flobX;
    if flobY >= FLOB_TO_SPRITE_Y then
        fy := flobY - FLOB_TO_SPRITE_Y
    else
        fy := 0;
    fw := 8;
    fh := 8;
    waitingForPortalRelease := false;
    for p := 0 to 1 do begin
        if not SpriteCollisionRect(p, sx, sy, sw, sh) then
            continue;
        if RectsOverlap(fx, fy, fw, fh, sx, sy, sw, sh) then begin
            // Interactive objects wait for deliberate movement after a flip,
            // but moving enemies must remain lethal while Flob stands still.
            if spriteCollisionMovePending and
               (sprites.stype[p] <> STYPE_ENEMY) then
                continue;
            if not WorldSpritePixelCollision(p) then
                continue;
            if teleportPortalReleasePending and (sprites.stype[p] = STYPE_PORTAL) then begin
                waitingForPortalRelease := true;
                continue;
            end;
            Collided(p);
            exit;
        end;
    end;
    if teleportPortalReleasePending and not waitingForPortalRelease and (triggerGrace = 0) then
        teleportPortalReleasePending := false;
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
var frameIdx: byte;
    frame: PSteSpriteFrame;
    frameLeft, frameTop, frameRight, frameBottom: smallint;
    leftCell, topCell, rightCell, bottomCell: smallint;
    cellX, cellY: smallint;
    localX0, localY0, localX1, localY1: smallint;
    px, py: smallint;
begin
    Result :=
        (GetPix(flobFoot, flobY - 1) = DANGER_COLLISION_COLOR) or
        (GetPix(flobFace, flobY - 2) = DANGER_COLLISION_COLOR) or
        (GetPix(flobFace, flobY - 3) = DANGER_COLLISION_COLOR);
    if Result or (not dynamicTileDangerActive) then exit;
    if currentCollisionData = nil then exit;
    frameIdx := flobFrame + flobDir;
    if frameIdx > High(SPR_FLOB_FRAMES) then exit;
    frame := @SPR_FLOB_FRAMES[frameIdx];

    frameLeft := smallint(flobX) * LEVEL_SCALE_X;
    frameTop := FLOB_RENDER_OFFSET_Y + smallint(flobY) * LEVEL_SCALE_Y;
    frameRight := frameLeft + smallint(frame^.widthPx) - 1;
    frameBottom := frameTop + smallint(frame^.heightPx) - 1;

    leftCell := frameLeft div LEVEL_SCALE_X;
    rightCell := frameRight div LEVEL_SCALE_X;
    if frameTop < BG_IMAGE_OFFSET_Y then topCell := 0
    else topCell := (frameTop - BG_IMAGE_OFFSET_Y) div LEVEL_SCALE_Y;
    if frameBottom < BG_IMAGE_OFFSET_Y then exit;
    bottomCell := (frameBottom - BG_IMAGE_OFFSET_Y) div LEVEL_SCALE_Y;
    if rightCell >= 160 then rightCell := 159;
    if bottomCell >= 80 then bottomCell := 79;

    for cellY := topCell to bottomCell do
        for cellX := leftCell to rightCell do begin
            if not IsDynamicDangerPix(byte(cellX), byte(cellY)) then
                continue;

            localX0 := cellX * LEVEL_SCALE_X - frameLeft;
            localY0 := BG_IMAGE_OFFSET_Y + cellY * LEVEL_SCALE_Y - frameTop;
            localX1 := localX0 + LEVEL_SCALE_X - 1;
            localY1 := localY0 + LEVEL_SCALE_Y - 1;
            if localX0 < 0 then localX0 := 0;
            if localY0 < 0 then localY0 := 0;
            if localX1 >= frame^.widthPx then localX1 := frame^.widthPx - 1;
            if localY1 >= frame^.heightPx then localY1 := frame^.heightPx - 1;

            for py := localY0 to localY1 do
                for px := localX0 to localX1 do
                    if GeneratedSpriteOpaqueAt(
                        frame, @SPR_FLOB_WORDS[0], px, py
                    ) then begin
                        Result := true;
                        exit;
                    end;
        end;
end;

// ***************************************************
// *** EXPLOSION / DEATH (1:1 from original)
// ***************************************************

procedure Explode;
const
    PARTICLE_MAX = 20;
    PARTICLE_FALL_LIMIT = 90;
    EXPLODE_P0: array[0..7] of byte = ($10, $82, $20, $08, $81, $10, $44, $00);
    EXPLODE_P1: array[0..7] of byte = ($22, $08, $81, $10, $04, $41, $08, $00);
type
    TDeathParticle = record
        x, y: smallint;
        layer: byte;
        active: boolean;
    end;
var particles: array[0..PARTICLE_MAX - 1] of TDeathParticle;
    particleCount: byte;
    baseX, baseY: smallint;
    step, fallFrames: byte;
    moved: boolean;

    function ClampSpriteX(x: smallint; width: word): word;
    begin
        if x < 0 then Result := 0
        else if x + width > 320 then Result := 320 - width
        else Result := word(x);
    end;

    procedure QueueDeathBackdrop;
    begin
        DrawSlimes;
        ShowSprites;
    end;

    procedure PresentDeathFlob(frame: byte);
    begin
        flobFrame := frame;
        BeginQueuedSpritesFrame;
        DrawSlimes;
        DrawFlob;
        ShowSprites;
        PresentQueuedSprites;
    end;

    procedure PresentExplosionLayers(spreadStep: byte);
    var frameIndex: byte;
        leftX, rightX, drawY: smallint;
    begin
        frameIndex := 0;
        if flipped then frameIndex := 1;
        leftX := baseX - smallint((spreadStep div 2) * 2);
        rightX := baseX + smallint(((spreadStep + 1) div 2) * 2);
        drawY := baseY + smallint((spreadStep + 1) * 2);

        BeginQueuedSpritesFrame;
        DrawSlimes;
        QueueGeneratedSprite(ClampSpriteX(leftX, 16), word(drawY),
            @SPR_FLOB_EXPLODE_P0_FRAMES[frameIndex],
            @SPR_FLOB_EXPLODE_P0_WORDS[0], nil, 0);
        QueueGeneratedSprite(ClampSpriteX(rightX, 16), word(drawY),
            @SPR_FLOB_EXPLODE_P1_FRAMES[frameIndex],
            @SPR_FLOB_EXPLODE_P1_WORDS[0], nil, 0);
        ShowSprites;
        PresentQueuedSprites;
    end;

    procedure AddParticle(x, y: smallint; layer: byte);
    begin
        if particleCount >= PARTICLE_MAX then exit;
        if (x < 0) or (x > 318) then exit;
        particles[particleCount].x := x;
        particles[particleCount].y := y;
        particles[particleCount].layer := layer;
        particles[particleCount].active := true;
        Inc(particleCount);
    end;

    procedure BuildParticles;
    var row, bit: byte;
        mask: byte;
        particleY: smallint;
    begin
        particleCount := 0;
        for row := 0 to 7 do begin
            if flipped then particleY := baseY + 10 + smallint(7 - row) * 2
            else particleY := baseY + 10 + smallint(row) * 2;
            mask := $80;
            for bit := 0 to 7 do begin
                if (EXPLODE_P0[row] and mask) <> 0 then
                    AddParticle(baseX - 4 + smallint(bit) * 2, particleY, 0);
                if (EXPLODE_P1[row] and mask) <> 0 then
                    AddParticle(baseX + 4 + smallint(bit) * 2, particleY, 1);
                mask := mask shr 1;
            end;
        end;
    end;

    procedure QueueParticles;
    var i, frameIndex: byte;
    begin
        frameIndex := 0;
        if flipped then frameIndex := 1;
        if particleCount > 0 then
            for i := 0 to particleCount - 1 do
                if particles[i].active then begin
                    if particles[i].layer = 0 then
                        QueueGeneratedSprite(word(particles[i].x), word(particles[i].y),
                            @SPR_FLOB_PARTICLE_P0_FRAMES[frameIndex],
                            @SPR_FLOB_PARTICLE_P0_WORDS[0], nil, 0)
                    else
                        QueueGeneratedSprite(word(particles[i].x), word(particles[i].y),
                            @SPR_FLOB_PARTICLE_P1_FRAMES[frameIndex],
                            @SPR_FLOB_PARTICLE_P1_WORDS[0], nil, 0);
                end;
    end;

    procedure PresentParticles;
    begin
        BeginQueuedSpritesFrame;
        QueueDeathBackdrop;
        QueueParticles;
        PresentQueuedSprites;
    end;

    procedure DropParticles;
    var i: byte;
        gameX, gameY: smallint;
    begin
        moved := false;
        if particleCount > 0 then
            for i := 0 to particleCount - 1 do
                if particles[i].active then begin
                    gameX := (particles[i].x + 1) div LEVEL_SCALE_X;
                    gameY := (particles[i].y + 2 - LEVEL_OFFSET_Y) div LEVEL_SCALE_Y;
                    if (gameY > 79) or (gameX < 0) or (gameX > 159) then begin
                        particles[i].active := false;
                        moved := true;
                    end else if not IsSolidPix(GetPix(byte(gameX), byte(gameY))) then begin
                        Inc(particles[i].y, LEVEL_SCALE_Y);
                        moved := true;
                    end;
                end;
    end;
begin
    FSfx(SFX_DEAD);
    sfxDelay := 0;

    PresentDeathFlob(FRAME_POOF1);
    WaitFrames(5);
    PresentDeathFlob(FRAME_POOF2);
    WaitFrames(5);

    flobFrame := FRAME_XPLODE;
    baseX := smallint(flobX) * LEVEL_SCALE_X;
    baseY := FLOB_RENDER_OFFSET_Y + smallint(flobY) * LEVEL_SCALE_Y;
    for step := 0 to 4 do PresentExplosionLayers(step);

    BuildParticles;
    fallFrames := 0;
    repeat
        DropParticles;
        PresentParticles;
        Inc(fallFrames);
    until (not moved) or (fallFrames >= PARTICLE_FALL_LIMIT);

    // Synchronise both display pages at the final particle positions.
    PresentParticles;
    PresentParticles;
    SubSlime($70);
    SubSlime($80);
    WaitFrames(50);
    exploded := true;
    Inc(deadCount);

    // The caller presents once more before leaving the room loop.
    BeginQueuedSpritesFrame;
    QueueDeathBackdrop;
    QueueParticles;
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
var textAddr: word;
begin
    msgDisplayCounter := count;
    msgDisplayType := mtype;
    textAddr := $FFFF;
    if msg <= High(messages) then textAddr := messages[msg];

    // Conditional triggers may fire every frame. Preserve their original timer
    // refresh without decoding and drawing the same 80-byte message repeatedly.
    if (textAddr <> $FFFF) and (currentMessageAddr = textAddr) and
        (not messageCacheDirty) then exit;

    ClearTxt2;
    if msg <= High(messages) then begin
        currentMessageLines[0] := DecodeWorldTextLine(textAddr, 0);
        currentMessageLines[1] := DecodeWorldTextLine(textAddr, 1);
        currentMessageAddr := textAddr;
    end;
    messageCacheDirty := true;
    RefreshOverlayBuffers;
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

function FlobInsideTrigger(t: byte): boolean;
var fy: byte;
begin
    fy := flobY;
    if flipped then fy := 82 - fy;
    Result :=
        (flobX >= roomTriggers[t, 1]) and
        (fy    >= roomTriggers[t, 2]) and
        (flobX <= roomTriggers[t, 3]) and
        (fy    <= roomTriggers[t, 4]);
end;

procedure CheckEvents;
var t: byte;
    waitingForTeleportTriggerRelease: boolean;
begin
    if doorReveal[0] > 0 then RevealCountdown(0);
    if doorReveal[1] > 0 then RevealCountdown(1);

    waitingForTeleportTriggerRelease := false;
    if triggerGrace > 0 then
        Dec(triggerGrace)
    else begin
        t := triggerCount;
        while t > 0 do begin
            Dec(t);
            if triggers[roomTriggers[t, 0]] > 0 then begin
                if teleportTriggerReleasePending and
                    (roomTriggers[t, 7] = TELEPORT_ME) and
                    FlobInsideTrigger(t) then
                    waitingForTeleportTriggerRelease := true
                else
                    CheckTrigger(t);
            end;
        end;
        if teleportTriggerReleasePending and not waitingForTeleportTriggerRelease then
            teleportTriggerReleasePending := false;
    end;

    if msgDisplayCounter > 0 then begin
        Dec(msgDisplayCounter);
        topBarForeground := sysframe shr 1;
        if msgDisplayType = MSG_INFO then
            topBarForeground := ((topBarForeground shr 1) and 7) + 8;
        if msgDisplayCounter = 0 then begin
            ClearTxt2;
            RefreshOverlayBuffers;
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
                InitLevelScreen;
                LoadLevel(levelNum);
                SetLevelColors;
                DrawSlimes;
                ShowSlime;
                ShowSprites;
                if flipped then EnsureDisplayOrientation(true);
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
    EnsureDisplayOrientation(false);
    room_changed := true;
    teleported := true;
    triggerGrace := 100;   // ~0.5 s at 50 Hz; prevents exit trigger firing at spawn
    teleportTriggerReleasePending := true;
    teleportPortalReleasePending := true;
end;

procedure SpriteTeleport(pnum: byte);
begin
    Teleport(sprites.goal[pnum], sprites.frameOn[pnum], sprites.frameOff[pnum]);
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
        cmd := leveldata[lvlptr];
        case cmd of
            IMAGE_LZ4: begin
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
                if sceneCount <= High(sceneImg) then begin
                sceneImg[sceneCount]  := leveldata[lvlptr + 1];
                sceneMsg[sceneCount]  := leveldata[lvlptr + 2] + (word(leveldata[lvlptr + 3]) shl 8);
                sceneCol0[sceneCount] := leveldata[lvlptr + 4];
                sceneCol1[sceneCount] := leveldata[lvlptr + 5];
                sceneCol2[sceneCount] := leveldata[lvlptr + 6];
                Inc(sceneCount);
                end;
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
            exit;
        end;
    until cmd = LEVEL_END;
end;

procedure SetLevelColors;
begin
    Move(levelRawColors[0], levelColors[0], 4);
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
    fileOffset := world.lvlPtr[lvl] - $A000;
    Move(currentWorldData[fileOffset], level, SizeOf(TLevel));
    Move(level.colors[0], levelRawColors[0], 4);
    cmdBytes := MAX_LEVEL_DATA;
    if fileOffset + SizeOf(TLevel) + cmdBytes > WORLD_DATA_BYTES then
        cmdBytes := WORLD_DATA_BYTES - fileOffset - SizeOf(TLevel);
    Move(currentWorldData[fileOffset + SizeOf(TLevel)], leveldata[0], cmdBytes);

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
    displayFlipped := false;  // DrawLevel always writes normal orientation; force re-flip if needed
    if flipped then EnsureDisplayOrientation(true)
    else EnsureDisplayOrientation(false);
    FillChar(queuedSpriteCount, SizeOf(queuedSpriteCount), 0);
    FillChar(renderedSpriteCount, SizeOf(renderedSpriteCount), 0);
    if room_changed and not teleported then AdjustFlobPosition;  // teleport: designer chose spawn, no adjust
    room_changed := false;
    room_landed := false;
    first_landed := false;
    landedTime := 0;
end;

// ***************************************************
// *** FLIP (1:1 from original)
// ***************************************************

procedure Flip;
var targetFlipped: boolean;
begin
    Sfx(SFX_FLIP);
    WaitFrame;
    targetFlipped := not flipped;
    FlipGameplayEffect(targetFlipped);
    flipped := targetFlipped;
    flobY := 84 - flobY;
    spriteCollisionMovePending := true;
    BeginQueuedSpritesFrame;
    ShowSprites;
    DrawFlob;
    PresentQueuedSprites;
    if flobFalling > 0 then flobFalling := 1;
    SubSlime(5);
end;

procedure BackToLevel;
begin
    BlackAll;               // palette black before image swap → no colour flash
    LoadLevel(levelNum);    // decompresses to SCREEN_LOG, SwapScreen; palette stays black
    SetLevelColors;         // Reveal leaves currentPal set to the preview room palette
    BlackAll;               // SetLevelColors updates hardware; keep it black until FadeIn
    BeginQueuedSpritesFrame;
    ShowSprites;
    DrawFlob;
    PresentQueuedSprites;
    WaitFrame;
    ShowLevelName;
    if flipped then EnsureDisplayOrientation(true)
    else EnsureDisplayOrientation(false);
    ClearTxt2;
    FadeIn;                 // reads black palette, fades to currentPal ✓
end;

procedure Reveal(rgoal, room: byte);
var times: byte;
    wasflipped: boolean;
    revealRaw, revealBuffer: pword;
    revealPalette, normalPalette: array[0..15] of word;

    procedure PresentRevealFrame(src: pword; palette: PWord);
    begin
        CopyPlayfieldArea(src, SCREEN_LOG);
        SwapScreen;
        xbios_setpalette(palette);
    end;

    procedure DrawRevealSprites(dst: pword);
    var i: byte;
        queued: PQueuedSprite;
    begin
        queuedSpriteCount[screenLogIndex] := 0;
        ShowSprites;
        if queuedSpriteCount[screenLogIndex] > 0 then
            for i := 0 to queuedSpriteCount[screenLogIndex] - 1 do begin
                queued := @queuedSprites[screenLogIndex, i];
                if queued^.frame <> nil then
                    DrawGeneratedSpriteFrameBlitter(dst, queued^.x, queued^.y,
                        queued^.frame, queued^.wordsBase);
            end;
        queuedSpriteCount[screenLogIndex] := 0;
    end;
begin
    revealRaw := gemdos_malloc(SCREEN_ALLOC);
    if revealRaw = nil then exit;
    AlignScreenBuffer(revealRaw, revealBuffer);

    FadeOut;
    WaitFrame;
    wasflipped := flipped;
    flipped := false;
    EnsureDisplayOrientation(false);

    // Build and retain the room after the goal has been revealed.
    goals[rgoal] := 0;
    LoadLevel(room);
    RebuildRoomPalette;
    CopyPlayfieldArea(SCREEN_BKG, revealBuffer);
    BuildDisplayPalette(@revealPalette[0]);

    // Keep the normal room in SCREEN_BKG while the revealed state remains
    // in the temporary buffer, matching the two display lists on A8.
    goals[rgoal] := 1;
    LoadLevel(room);
    RebuildRoomPalette;
    BuildDisplayPalette(@normalPalette[0]);
    goals[rgoal] := 0;
    DrawRevealSprites(SCREEN_BKG);
    DrawRevealSprites(revealBuffer);
    CopyPlayfieldArea(SCREEN_BKG, SCREEN_LOG);
    CopyPlayfieldArea(SCREEN_BKG, SCREEN_PHY);
    BlackAll;
    topBarForeground := 0;
    WaitFrame;
    FSfx(SFX_REVEAL);
    sfxDelay := 0;
    FadeIn;
    times := 3;
    repeat
        PresentRevealFrame(SCREEN_BKG, @normalPalette[0]);
        WaitFrames(20);
        PresentRevealFrame(revealBuffer, @revealPalette[0]);
        WaitFrames(20);
        Dec(times);
    until times = 0;
    WaitFrames(50);
    FadeOut;
    WaitFrame;
    gemdos_mfree(revealRaw);
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

function HandleCheatRoomNavigation: boolean;
var targetRoom: byte;
begin
    Result := false;
    if not cheatmode then exit;

    targetRoom := levelNum;
    if CRT_GameplayKeyPressed(KEY_LBRACKET_CODE) then begin
        if targetRoom = 0 then targetRoom := world.levelNum - 1
        else Dec(targetRoom);
    end else if CRT_GameplayKeyPressed(KEY_RBRACKET_CODE) then begin
        Inc(targetRoom);
        if targetRoom >= world.levelNum then targetRoom := 0;
    end else
        exit;

    levelNum := targetRoom;
    room_changed := true;
    teleported := false;
    triggerGrace := 0;
    teleportTriggerReleasePending := false;
    teleportPortalReleasePending := false;
    Result := true;
end;

// ***************************************************
// *** STATS SCREEN
// ***************************************************

procedure ShowStats;
const
    STATS_TEXT_COLOR = 4;
    ENTRY_TOP = 74;
    ENTRY_STEP = 12;
    LEFT_X = 8;
    RIGHT_X = 168;
    VALUE_OFFSET = 72;
var page, key, delay: byte;
    update, firstDraw, exitRequested: boolean;
    savedWorld: byte;

    function NumberText(value: cardinal): string;
    begin
        Str(value, Result);
    end;

    function TwoDigits(value: cardinal): string;
    begin
        Str(value, Result);
        if value < 10 then Result := '0' + Result;
    end;

    function TimeText(seconds: cardinal): string;
    var hours, minutes, secs: cardinal;
    begin
        if seconds = $FFFF then begin
            Result := '--:--';
            exit;
        end;
        hours := seconds div 3600;
        minutes := (seconds div 60) mod 60;
        secs := seconds mod 60;
        if hours > 0 then
            Result := NumberText(hours) + ':' + TwoDigits(minutes) + ':' + TwoDigits(secs)
        else
            Result := NumberText(minutes) + ':' + TwoDigits(secs);
    end;

    function OptionalNumber(value: word): string;
    begin
        if value = $FFFF then Result := '--'
        else Result := NumberText(value);
    end;

    procedure DrawEntry(x, row: word; const labelText, valueText: string);
    var y: word;
    begin
        y := ENTRY_TOP + row * ENTRY_STEP;
        DrawTextTo(SCREEN_LOG, x, y, STATS_TEXT_COLOR, 0, labelText);
        DrawTextTo(SCREEN_LOG, x + VALUE_OFFSET, y, STATS_TEXT_COLOR, 0, valueText);
    end;

    procedure DrawWorldStats;
    begin
        DrawEntry(LEFT_X,  0, 'Attempts',   NumberText(worldStats.attempts));
        DrawEntry(LEFT_X,  1, 'Wins',       NumberText(worldStats.winCount));
        DrawEntry(LEFT_X,  2, 'Failures',   NumberText(worldStats.failCount));
        DrawEntry(LEFT_X,  3, 'Best scr',   NumberText(worldStats.bestScore));
        DrawEntry(LEFT_X,  4, 'Best time',  TimeText(worldStats.bestTime));
        DrawEntry(LEFT_X,  5, 'Max slime',  NumberText(worldStats.maxSlimes));
        DrawEntry(LEFT_X,  6, 'Secrets',    NumberText(worldStats.maxSecrets));
        DrawEntry(LEFT_X,  7, 'Min death',  OptionalNumber(worldStats.minDeaths));
        DrawEntry(LEFT_X,  8, 'Max death',  NumberText(worldStats.maxDeaths));

        DrawEntry(RIGHT_X, 0, 'All slime',  NumberText(worldStats.totalSlimes));
        DrawEntry(RIGHT_X, 1, 'Deaths',     NumberText(worldStats.totalDeaths));
        DrawEntry(RIGHT_X, 2, 'Tot time',   TimeText(worldStats.totalTime));
        DrawEntry(RIGHT_X, 3, 'All score',  NumberText(worldStats.totalScore));
        DrawEntry(RIGHT_X, 4, 'Flawless',   NumberText(worldStats.flawlessCount));
        DrawEntry(RIGHT_X, 5, 'Mastered',   NumberText(worldStats.mastersCount));
        DrawEntry(RIGHT_X, 6, 'Pick all',   NumberText(worldStats.pickAllCount));
        DrawEntry(RIGHT_X, 7, 'Secrets',    NumberText(worldStats.secretAllCount));
        DrawEntry(RIGHT_X, 8, 'Speedrun',   NumberText(worldStats.speedRunsCount));
    end;

    procedure DrawGlobalStats;
    begin
        DrawEntry(LEFT_X,  0, 'Attempts',   NumberText(globalStats.attempts));
        DrawEntry(LEFT_X,  1, 'Wins',       NumberText(globalStats.winCount));
        DrawEntry(LEFT_X,  2, 'Failures',   NumberText(globalStats.failCount));
        DrawEntry(LEFT_X,  3, 'All score',  NumberText(globalStats.totalScore));
        DrawEntry(LEFT_X,  4, 'Tot time',   TimeText(globalStats.totalTime));
        DrawEntry(LEFT_X,  5, 'All slime',  NumberText(globalStats.totalSlimes));
        DrawEntry(LEFT_X,  6, 'Deaths',     NumberText(globalStats.totalDeaths));
        DrawEntry(LEFT_X,  7, 'Goals',      NumberText(globalStats.goalsCount));
        DrawEntry(LEFT_X,  8, 'Achieved',   NumberText(achivementsCount));

        DrawEntry(RIGHT_X, 0, 'Flaw W',     NumberText(globalStats.flawlessWorlds));
        DrawEntry(RIGHT_X, 1, 'Slime W',    NumberText(globalStats.allSlimesWorlds));
        DrawEntry(RIGHT_X, 2, 'Secret W',   NumberText(globalStats.allSecretsWorlds));
        DrawEntry(RIGHT_X, 3, 'Master W',   NumberText(globalStats.mastersWorlds));
        DrawEntry(RIGHT_X, 4, 'Speed W',    NumberText(globalStats.speedRunsWorlds));
        DrawEntry(RIGHT_X, 5, 'Flawless',   NumberText(globalStats.flawlessCount));
        DrawEntry(RIGHT_X, 6, 'Pick all',   NumberText(globalStats.allSlimesCount));
        DrawEntry(RIGHT_X, 7, 'Secrets',    NumberText(globalStats.allSecretsCount));
        DrawEntry(RIGHT_X, 8, 'Game runs',  NumberText(gameRuns));
    end;

    procedure RenderStatsPage;
    begin
        ClearScreen(SCREEN_LOG);
        BlitterCopyBitmap4(@STATS_HEADER_WORDS[0], SCREEN_LOG,
            320, 42, 0, 0, 0, 0, 320, 320);
        if page < WORLD_COUNT then begin
            statBestsBack := STAT_ON + 4;
            statGlobalBack := STAT_OFF;
            LoadWorld(page);
            GetWorldStats(page);
            DrawTextCenteredTo(SCREEN_LOG, 46, STATS_TEXT_COLOR, 0, Antic2Ascii(world.name));
            DrawWorldStats;
        end else begin
            statBestsBack := STAT_OFF;
            statGlobalBack := STAT_ON + 4;
            DrawTextCenteredTo(SCREEN_LOG, 46, STATS_TEXT_COLOR, 0, 'Total Game Stats');
            DrawGlobalStats;
        end;
        DrawTextCenteredTo(SCREEN_LOG, 58, STATS_TEXT_COLOR, 0,
            '<  Page ' + NumberText(page + 1) + ' / ' + NumberText(WORLD_COUNT + 1) + '  >');
        FillRect16(SCREEN_LOG, 0, 68, 320, 2, 5);
        FillRect16(SCREEN_LOG, 0, 184, 320, 2, 5);
        DrawTextCenteredTo(SCREEN_LOG, 190, STATS_TEXT_COLOR, 0, 'LEFT/RIGHT   FIRE: BACK');
        SwapScreen;
    end;
begin
    savedWorld := worldCurrent;
    page := worldCurrent;
    update := true;
    firstDraw := true;
    exitRequested := false;
    delay := 0;
    CountGlobalStats;
    FillChar(titlePalette, SizeOf(titlePalette), 0);
    titlePalette[1] := STE_PAL[$38];
    titlePalette[2] := STE_PAL[$3C];
    titlePalette[3] := STE_PAL[$34];
    titlePalette[STATS_TEXT_COLOR] := $FFF;
    titlePalette[5] := STE_PAL[$04];
    roomSpritePaletteActive := false;
    currentPal := @titlePalette[0];
    BlackAll;

    repeat
        WaitFrame;
        key := NONE;
        if (skstat and 4) = 0 then key := kbcode;

        exitRequested := CRT_FirePressedEdge or
            CRT_GameplayKeyPressed(KEY_ENTER_CODE) or
            CRT_GameplayKeyPressed(KEY_ESC_CODE) or
            (key = KEY_ENTER_CODE) or (key = KEY_ESC_CODE);

        if delay > 0 then Dec(delay)
        else begin
            if ((stick0 and %0100) = 0) or (key = KEY_LEFT_CODE) or
                CRT_GameplayKeyPressed(KEY_LEFT_CODE) then begin
                if page = 0 then page := WORLD_COUNT else Dec(page);
                update := true;
                delay := 8;
            end else if ((stick0 and %1000) = 0) or (key = KEY_RIGHT_CODE) or
                CRT_GameplayKeyPressed(KEY_RIGHT_CODE) then begin
                if page = WORLD_COUNT then page := 0 else Inc(page);
                update := true;
                delay := 8;
            end;
        end;

        if update then begin
            RenderStatsPage;
            if firstDraw then begin
                FadeIn;
                firstDraw := false;
            end;
            update := false;
        end;
    until exitRequested;

    FadeOut;
    LoadWorld(savedWorld);
    WaitForStartKeyUp;
end;

procedure PauseGame;
var savedLines: array[0..1] of string;
    savedCounter, savedType, savedForeground: byte;

    function CenterMessage(const text: string): string;
    var leftPad: byte;
    begin
        if Length(text) >= 40 then begin
            Result := Copy(text, 1, 40);
            exit;
        end;
        leftPad := (40 - Length(text)) div 2;
        Result := StringOfChar(' ', leftPad) + text;
        while Length(Result) < 40 do Result := Result + ' ';
    end;
begin
    savedLines[0] := currentMessageLines[0];
    savedLines[1] := currentMessageLines[1];
    savedCounter := msgDisplayCounter;
    savedType := msgDisplayType;
    savedForeground := topBarForeground;

    currentMessageLines[0] := CenterMessage('GAME PAUSED');
    currentMessageLines[1] := CenterMessage('P / ENTER / FIRE TO RESUME');
    msgDisplayCounter := $FF;
    msgDisplayType := MSG_INFO;
    topBarForeground := 15;
    messageCacheDirty := true;
    RefreshOverlayBuffers;
    UpdateDisplayPaletteIfNeeded(false);

    repeat
        WaitFrame;
        topBarForeground := ((sysframe shr 2) and 7) + 8;
        UpdateDisplayPaletteIfNeeded(false);
    until CRT_FirePressedEdge or
        CRT_GameplayKeyPressed(KEY_P_CODE) or
        CRT_GameplayKeyPressed(KEY_ENTER_CODE) or
        CRT_GameplayKeyPressed(KEY_ESC_CODE);

    currentMessageLines[0] := savedLines[0];
    currentMessageLines[1] := savedLines[1];
    msgDisplayCounter := savedCounter;
    msgDisplayType := savedType;
    topBarForeground := savedForeground;
    messageCacheDirty := true;
    RefreshOverlayBuffers;
    UpdateDisplayPaletteIfNeeded(false);
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
    gameplayInputWasInstalled: boolean;
begin
    FadeOut;
    StopSong;
    gameplayInputWasInstalled := gameplayInputInstalled;
    if gameplayInputWasInstalled then begin
        UnInstallGameplayInput;
        keyboardInputEnabled := true;
    end;
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

    ShowEndWorldScreen(sec, score);
    PlaySong(MUSIC_ENDGAME);
    repeat WaitFrame until IsStartingButtonDown;
    WaitForStartKeyUp;
    FadeOut;

    if (worldCurrent = 5) and mainGoalReached then begin
        ShowCutScene(OUTRO_BANK, OUTRO_IMAGE_COUNT);
        ShowCredits;
    end;
    if newAchivements > 0 then ShowAchievements;

    if gameplayInputWasInstalled then begin
        keyboardInputEnabled := false;
        InstallGameplayInput;
    end;
    game_over := true;
    StopSong;
end;

// ***************************************************
// *** CUTSCENE / CREDITS (1:1 from original, stubs)
// ***************************************************

function CutsceneLineDelay(const line: string): word;
var i: byte;
begin
    i := Length(line);
    while (i > 0) and (line[i] = ' ') do Dec(i);
    if (i > 0) and (line[i] = '!') then
        CutsceneLineDelay := 250
    else if (i > 0) and (line[i] = '.') then
        CutsceneLineDelay := 150
    else
        CutsceneLineDelay := 55;
end;

procedure ShowCutScene(csbank, cscount: byte);
var slide: byte;
    slideDelay: word;
    visibleLines: byte;
    textFadeStep: byte;
    textFadeStart: word;
    cutsceneHold: boolean;
    syncMusicTiming: boolean;
    c0, c1, c2, bg: byte;
    l0, l1, l2, l3: string;
begin
    WaitFrame;
    StopSong;
    BlackAll;
    ClearScreen(SCREEN_LOG);
    ClearScreen(SCREEN_PHY);
    slide := 0;
    WaitFrame;
    if csbank = INTRO_BANK then PlaySong(MUSIC_INTRO)
    else if csbank = OUTRO_BANK then PlaySong(MUSIC_OUTRO);
    syncMusicTiming := (csbank = INTRO_BANK) or (csbank = OUTRO_BANK);
    repeat
        FillChar(messageTypes, SizeOf(messageTypes), 0);
        LoadCutsceneSlide(slide, csbank);
        PresentCutsceneSlide;
        GetCutsceneText(csbank, slide, c0, c1, c2, bg, l0, l1, l2, l3);
        RebuildCutscenePalette(c0, c1, c2, bg);
        roomPalette[CUTSCENE_TEXT_COLOR] := CUTSCENE_TEXT_WHITE;
        textFadeStart := roomPalette[0];
        roomPalette[CUTSCENE_FADE_COLOR] := textFadeStart;
        FadeIn;
        visibleLines := 0;
        textFadeStep := CUTSCENE_TEXT_FADE_FRAMES;
        if syncMusicTiming then slideDelay := 18
        else slideDelay := 18;
        cutsceneHold := false;
        repeat
            if slideDelay = 0 then begin
                if visibleLines < 4 then begin
                    Inc(visibleLines);
                    textFadeStep := 0;
                    roomPalette[CUTSCENE_FADE_COLOR] := textFadeStart;
                    SetPaletteRegister(CUTSCENE_FADE_COLOR, textFadeStart);
                    RenderCutsceneText(SCREEN_LOG, l0, l1, l2, l3, visibleLines);
                    SwapScreen;
                    if syncMusicTiming then begin
                        case visibleLines of
                            1: slideDelay := CutsceneLineDelay(l0);
                            2: slideDelay := CutsceneLineDelay(l1);
                            3: slideDelay := CutsceneLineDelay(l2);
                            4: slideDelay := CutsceneLineDelay(l3);
                        end;
                    end else
                        slideDelay := 22;
                end else if not cutsceneHold then begin
                    cutsceneHold := true;
                    if syncMusicTiming then slideDelay := 55
                    else slideDelay := 300;
                end;
            end;
            if slideDelay > 0 then
                Dec(slideDelay);
            WaitFrame;
            // Fade within the existing line delay, without adding music time.
            if textFadeStep < CUTSCENE_TEXT_FADE_FRAMES then begin
                Inc(textFadeStep);
                roomPalette[CUTSCENE_FADE_COLOR] :=
                    (FadeNibble(textFadeStart shr 8, CUTSCENE_TEXT_WHITE shr 8,
                        textFadeStep, CUTSCENE_TEXT_FADE_FRAMES) shl 8) or
                    (FadeNibble(textFadeStart shr 4, CUTSCENE_TEXT_WHITE shr 4,
                        textFadeStep, CUTSCENE_TEXT_FADE_FRAMES) shl 4) or
                    FadeNibble(textFadeStart, CUTSCENE_TEXT_WHITE,
                        textFadeStep, CUTSCENE_TEXT_FADE_FRAMES);
                SetPaletteRegister(CUTSCENE_FADE_COLOR, roomPalette[CUTSCENE_FADE_COLOR]);
                if textFadeStep = CUTSCENE_TEXT_FADE_FRAMES then begin
                    // Both indices now have the same RGB value. Retain the line
                    // on both pages before reusing index 15 for the next one.
                    DrawCutsceneLine(SCREEN_LOG, l0, l1, l2, l3,
                        visibleLines, CUTSCENE_TEXT_COLOR);
                    DrawCutsceneLine(SCREEN_PHY, l0, l1, l2, l3,
                        visibleLines, CUTSCENE_TEXT_COLOR);
                end;
            end;
        until (cutsceneHold and (slideDelay = 0)) or IsStartingButtonDown;
        FadeOut;
        if IsStartingButtonDown then break;
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
var img: byte;
    offset: longword;
    textPtr: PByte;
    raw: AnsiString;
    line, col: integer;
begin
    if (scene > High(sceneImg)) or (scene >= sceneCount) then exit;
    img := sceneImg[scene];
    if (currentWorldImgPtrs = nil) or (currentWorldPalPtrs = nil) or
        (img >= currentWorldImgCount) then exit;
    // Scene strings are four ANTIC rows in the original world asset bank.
    if (sceneMsg[scene] < $A000) or (currentWorldAssets = nil) then exit;
    offset := longword(sceneMsg[scene]) - $A000;
    if offset + 160 > currentWorldAssetsSize then exit;
    textPtr := currentWorldAssets + offset;
    WaitFrame;
    FadeOut;
    BlackAll;
    // Reuse the canonical room-image container, but present as a cutscene.
    // Do not call LoadImage: it swaps early and changes collision state.
    UnApl(PPointer(currentWorldImgPtrs)[img], SCREEN_BKG);
    ClearScreen(SCREEN_LOG);
    BlitterCopyBitmap4(SCREEN_BKG, SCREEN_LOG, 320, PLAYFIELD_HEIGHT,
        0, BG_IMAGE_OFFSET_Y, 0, 8, 320, 320);
    currentBasePal := PPointer(currentWorldPalPtrs)[img];
    RebuildCutscenePalette(sceneCol0[scene], sceneCol1[scene], sceneCol2[scene], 0);
    roomPalette[15] := STE_PAL[$0A]; // dliintro2 uses constant luminance 10
    SetLength(raw, 40);
    for line := 0 to 3 do begin
        for col := 0 to 39 do raw[col + 1] := Chr(textPtr[line * 40 + col] and $7F);
        DrawTextTo(SCREEN_LOG, 0, 168 + word(line) * 8, 15, 0, Antic2Ascii(raw));
    end;
    SwapScreen;
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
    ACH_COLORS: array[0..15] of byte =
        (0,$08,$0C,$02,$16,$1A,$12,$94,$98,$9A,$04,$0C,$84,0,0,$0C);
    GRID_LEFT  = 16;
    GRID_TOP   = 26;
    CELL_W     = 24;
    ROW_STRIDE = 22;
    SEP_Y      = 180;
    INFO_Y     = 184;
    WORLD_NAMES: array[0..6] of string[22] = (
        'Escape from the Lab',
        'Abominable Sewers',
        'Suburbian Parkour',
        'Hazardous Mudlands',
        'Silver Dust Mines',
        'Return to the Lab',
        'Global'
    );
var
    w, a, aid: byte;
    cx, cy:    word;
    col:       byte;
    curW, curA: byte;
    update:    boolean;
    firstDraw: boolean;
    key:       byte;
    delay:     byte;
    displayedState: array[0..ACHIEVEMENTS_COUNT-1] of byte;
begin
    FadeOut;

    curW   := 0;
    curA   := 0;
    update := true;
    firstDraw := true;
    delay  := 0;

    for a := 0 to 15 do titlePalette[a] := STE_PAL[ACH_COLORS[a]];
    roomSpritePaletteActive := false;
    currentPal := @titlePalette[0];
    for aid := 0 to ACHIEVEMENTS_COUNT-1 do begin
        displayedState[aid] := achievements[aid];
        if achievements[aid] = 2 then achievements[aid] := 1;
    end;
    BlackAll;

    repeat
        WaitFrame;
        joy := stick0;
        key := NONE;
        if skstat and 4 = 0 then key := kbcode;

        if delay > 0 then Dec(delay)
        else begin
            if (joy and %0100 = 0) or (key = KEY_LEFT_CODE) then begin
                if curA = 0 then curA := 11 else Dec(curA);
                update := true; delay := 6;
            end;
            if (joy and %1000 = 0) or (key = KEY_RIGHT_CODE) then begin
                if curA = 11 then curA := 0 else Inc(curA);
                update := true; delay := 6;
            end;
            if (joy and %0001 = 0) or (key = KEY_UP_CODE) then begin
                if curW = 0 then curW := WORLD_COUNT else Dec(curW);
                update := true; delay := 6;
            end;
            if (joy and %0010 = 0) or (key = KEY_DOWN_CODE) then begin
                if curW = WORLD_COUNT then curW := 0 else Inc(curW);
                update := true; delay := 6;
            end;
        end;

        if update then begin
            ClearScreen(SCREEN_LOG);

            // Title (blue/cyan like original)
            Str(achivementsCount, s1);
            Str(ACHIEVEMENTS_COUNT, s);
            s := 'Achievements ' + s1 + ' / ' + s;
            DrawSelectorShadow(s, 0, 8, 7);

            // Blue separator under title
            FillRect16(SCREEN_LOG, 0, 20, 320, 2, 12);

            // Achievement grid — no row labels, trophies fill full width
            aid := 0;
            for w := 0 to WORLD_COUNT do begin
                cy := GRID_TOP + word(w) * ROW_STRIDE;
                for a := 0 to 11 do begin
                    cx := GRID_LEFT + word(a) * CELL_W;
                    col := displayedState[aid];
                    if col > 2 then col := 1;
                    if w = WORLD_COUNT then Inc(col, 3);
                    DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, cx, cy,
                        @ACH_UI_FRAMES[col], @ACH_UI_WORDS[0]);
                    Inc(aid);
                end;
            end;

            // Blue separator above info panel
            FillRect16(SCREEN_LOG, 0, SEP_Y, 320, 2, 12);
            // Keep the selected trophy's state visible inside a pulsing frame.
            cx := GRID_LEFT + word(curA) * CELL_W;
            cy := GRID_TOP + word(curW) * ROW_STRIDE;
            DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, cx, cy,
                @ACH_UI_FRAMES[6], @ACH_UI_WORDS[0]);

            // Info panel
            aid := curW * 12 + curA;
            if aid < ACHIEVEMENTS_COUNT then begin
                if curW < WORLD_COUNT then
                    achievement := ACHIEVEMENT_DEFS[curA]
                else
                    achievement := ACHIEVEMENT_DEFS[12 + curA];

                // Line 1 (dim): "WorldName Achievement"
                s := WORLD_NAMES[curW] + ' Achievement';
                DrawStrCentered(INFO_Y, 10, Copy(s, 1, 40));

                // Line 2 (bright): "Name : Desc"  (strip trailing spaces from name)
                s := achievement.name;
                while (Length(s) > 0) and (s[Length(s)] = ' ') do
                    SetLength(s, Length(s) - 1);
                s1 := achievement.desc;
                while (Length(s1) > 0) and (s1[Length(s1)] = ' ') do
                    SetLength(s1, Length(s1) - 1);
                s := s + ': ' + s1;
                DrawStrCentered(INFO_Y + 8, 11, Copy(s, 1, 40));
            end;

            SwapScreen;
            if firstDraw then begin
                FadeIn;
                firstDraw := false;
            end;
            update := false;
        end;
        SetPaletteRegister(15, STE_PAL[8 + ((sysframe shr 2) and 3)]);

    until IsStartingButtonDown or CRT_SelectPressed or (kbcode = KEY_ESC_CODE) or (kbcode = KEY_A_CODE);
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

procedure DrawSelectorText(const text: string; y: word; color: byte);
var glyph: TSteSpriteFrame;
    data: array[0..79] of word;
    x, i, row, plane, code, bits, count: word;
begin
    count := Length(text);
    if count > 20 then count := 20;
    x := (320 - count * 16) div 2;
    FillChar(glyph, SizeOf(glyph), 0);
    glyph.widthPx := 16;
    glyph.heightPx := 16;
    glyph.rowWords := 1;
    glyph.dataOffset := 16;
    for i := 1 to count do begin
        code := Ord(text[i]);
        if (code < 32) or (code > 127) then code := 32;
        for row := 0 to 15 do begin
            bits := SELECTOR_FONT_MASKS[(code - 32) * 16 + row];
            data[row] := not bits;
            for plane := 0 to 3 do
                if (color and (1 shl plane)) <> 0 then
                    data[16 + row * 4 + plane] := bits
                else data[16 + row * 4 + plane] := 0;
        end;
        DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, x, y, @glyph, @data[0]);
        BlitterWait; // the next glyph reuses this temporary source
        Inc(x, 16);
    end;
end;

procedure DrawSelectorShadow(const text: string; y: word; color, shade: byte);
begin
    DrawSelectorText(text, y + 2, shade);
    DrawSelectorText(text, y, color);
end;

procedure DrawWorldSelectorIcon;
begin
    if worldCurrent > High(WORLD_ICON_PTRS) then exit;

    BlitterCopyBitmap4(
        WORLD_ICON_PTRS[worldCurrent],
        SCREEN_LOG,
        WORLD_ICON_WIDTH,
        WORLD_ICON_HEIGHT,
        0,
        0,
        64,
        34,
        WORLD_ICON_WIDTH,
        320
    );
end;

procedure RenderWorldSelector(locked: boolean);
var i, selector: byte;
    iconColOfs: word;
    colPtr: PByte;
    px, py: integer;
begin
    ClearScreen(SCREEN_LOG);
    FillChar(titlePalette[0], SizeOf(titlePalette), 0);

    colPtr := nil;
    if world.iconPtr >= $A000 then begin
        iconColOfs := world.iconPtr - $A000;
        if (currentWorldData <> nil) and (iconColOfs + 2 < WORLD_DATA_BYTES) then
            colPtr := PByte(currentWorldData) + iconColOfs;
    end;
    // Canonical PNG luminance order differs from A8's pixel selectors.
    for i := 1 to 3 do begin
        selector := SELECTOR_ICON_MAP[worldCurrent, i];
        if locked or (colPtr = nil) then begin
            case selector of
                1: titlePalette[i] := STE_PAL[6];
                2: titlePalette[i] := STE_PAL[10];
                3: titlePalette[i] := STE_PAL[2];
            end;
        end else titlePalette[i] := STE_PAL[colPtr[selector - 1]];
    end;
    titlePalette[4] := STE_PAL[$84]; // heading shadow and rules
    titlePalette[5] := STE_PAL[$0F]; // heading
    titlePalette[6] := STE_PAL[world.goalcolor1];
    titlePalette[7] := STE_PAL[world.goalcolor2];
    titlePalette[8] := STE_PAL[$1A]; // stats
    titlePalette[9] := STE_PAL[$26]; // locked label
    titlePalette[10] := STE_PAL[$98];
    titlePalette[12] := STE_PAL[FLOB_COL0];
    titlePalette[13] := STE_PAL[FLOB_COL1];
    titlePalette[14] := STE_PAL[FLOB_COL0 or FLOB_COL1];
    if locked then begin
        titlePalette[12] := STE_PAL[4];
        titlePalette[13] := STE_PAL[8];
        titlePalette[14] := STE_PAL[12];
    end;
    titlePalette[15] := STE_PAL[$24];
    roomSpritePaletteActive := false;
    currentPal := @titlePalette[0];
    // NOTE: palette is applied by the caller (FadeIn on first render, xbios_setpalette otherwise)

    FillRect16(SCREEN_LOG, 0, 28, 320, 2, 4);
    FillRect16(SCREEN_LOG, 0, 118, 320, 2, 4);
    DrawSelectorShadow('Select World:', 8, 5, 4);
    DrawWorldSelectorIcon;
    DrawSelectorShadow(Antic2Ascii(world.name), 128, 6, 7);
    if worldCurrent > 0 then
        DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, 0, 44,
            @SELECTOR_SPRITE_FRAMES[16], @SELECTOR_SPRITE_WORDS[0]);
    if worldCurrent < WORLD_COUNT - 1 then
        DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, 304, 44,
            @SELECTOR_SPRITE_FRAMES[17], @SELECTOR_SPRITE_WORDS[0]);
    if world.iconFlobFrame < 16 then begin
        px := (integer(world.iconFlobX) - 1) * 2;
        py := integer(world.iconFlobY) * 2;
        if (px >= 0) and (px <= 304) and (py >= 0) and (py <= 184) then
            DrawGeneratedSpriteFrameBlitter(SCREEN_LOG, px, py,
                @SELECTOR_SPRITE_FRAMES[world.iconFlobFrame], @SELECTOR_SPRITE_WORDS[0]);
    end;
    if locked then DrawSelectorShadow('LOCKED', 160, 9, 8)
    else DrawSelectorText(s, 168, 8);
    SwapScreen;
end;

function ShowWorldSelector: boolean;
var update, locked: boolean;
    key, delay: byte;
    firstRender: boolean;
begin
    Result := true;
    WaitFrame;
    update := true;
    delay := 0;
    locked := false;
    firstRender := true;

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
            if firstRender then begin
                FadeIn;        // SwapScreen already done inside RenderWorldSelector
                firstRender := false;
            end else
                xbios_setpalette(pword(currentPal));
            update := false;
            delay := WORLD_SELECTION_DELAY;
        end;

        if (not locked) and (statCount > 0) then begin
            Dec(statCount);
            if statCount = 0 then begin
                ShowNextStat;
                RenderWorldSelector(locked);
                xbios_setpalette(pword(currentPal));
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

procedure LoadTitleTo(dst: pword);
begin
    if achievements[12 * 5] > 0 then begin
        UnApl(@IMG_TITLE_CROWN[0], dst);
        currentBasePal := @IMG_TITLE_CROWN_PAL[0];
    end else begin
        UnApl(@IMG_TITLE[0], dst);
        currentBasePal := @IMG_TITLE_PAL[0];
    end;
end;

procedure InitTitle;
begin
    BlackAll;
    LoadTitleTo(SCREEN_LOG);
    RebuildTitlePalette;
    SwapScreen;
    FadeIn;
end;

procedure ShowTitleScreen;
begin

    // Show title image
    PlaySong(MUSIC_THEME);
    InitTitle;
    repeat
        WaitFrame;
        if kbcode = KEY_A_CODE then begin ShowAchievements; InitTitle; end;
        if (kbcode = KEY_C_CODE) or (kbcode = KEY_HELP_CODE) then begin
            ShowCredits; InitTitle;
        end;
    until IsStartingButtonDown;
    WaitForStartKeyUp;
    FadeOut;
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
    gemdos_super(pointer(0));
    ScreenInit;
    InitSound;
    InstallInput;
    sysframe := 0;

    spriteAnimations[0] := @spriteAnimation0;
    spriteAnimations[1] := @spriteAnimation1;

    leveldata[0] := LEVEL_END;
    statBestsBack  := STAT_OFF;
    statGlobalBack := STAT_OFF;
    music_ingame := true;
    escPressed := 0;

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
            keyboardInputEnabled := false;
            InstallGameplayInput;
            InitWorld;
            music_track := worldCurrent;
            if music_track > 4 then music_track := 0;
            if music_ingame then PlaySong(MUSIC_LEVEL)
            else PlaySong(MUSIC_SILENT);
            InitLevelScreen;

            BlackAll;   // ensure screen is black before first FadeIn
            repeat
                if exploded then begin
                    // LoadLevel expects SCREEN_BKG and displayFlipped to agree before it
                    // rebuilds the respawn room. Hide that technical orientation change;
                    // otherwise the completed death frame visibly flips for one frame.
                    BlackAll;
                    if lastSafeLanded.flipped then EnsureDisplayOrientation(true)
                    else EnsureDisplayOrientation(false);
                    flipped  := lastSafeLanded.flipped;
                    flobX    := lastSafeLanded.x;
                    flobY    := lastSafeLanded.y;
                    levelNum := lastSafeLanded.lvl;
                    flobFalling := 0;
                    if flobX < 80 then flobDir := DIR_RIGHT else flobDir := DIR_LEFT;
                    invulnerability := INVULNERABILTY_TIME;
                end else if not teleported then
                    FadeOut;  // normal room transition: fade out before swapping room

                LoadLevel(levelNum);
                ShowSlime;
                WaitFrame;

                SetLevelColors;
                if not exploded then begin
                    FadeIn;                    // all non-explosion transitions fade in
                    displayPaletteDirty := true;
                end;
                if teleported then begin
                    teleported := false;
                end;

                repeat
                    GameplayFrameTick;
                    if CRT_GameplayKeyPressed(KEY_P_CODE) or
                        CRT_GameplayKeyPressed(KEY_ENTER_CODE) then
                        PauseGame;
                    BeginQueuedSpritesFrame;

                    if flobFrame <> 0 then
                        if flobFrameDelay > 0 then Dec(flobFrameDelay)
                        else if flobFrameDelay = 0 then flobFrame := FRAME_STAND;

                    FlobFootUpdate;

                    joyRaw := joyStatus and $8F;
                    if not HandleCheatRoomNavigation then begin
                        if (joyRaw and %0100) <> 0 then begin
                            spriteCollisionMovePending := false;
                            FlobMove(DIR_LEFT);
                        end;
                        if (joyRaw and %1000) <> 0 then begin
                            spriteCollisionMovePending := false;
                            FlobMove(DIR_RIGHT);
                        end;
                        if CRT_FirePressedEdge then Flip;
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
                        if invulnerability > 0 then
                            Dec(invulnerability)
                        else if colorCollision and FlobTouchesDangerColor then
                            Explode
                        else
                            CheckSpriteCollisions;

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
                            PlaySong(MUSIC_LEVEL);
                            actionDelay := 20;
                        end;
                    end;

                    PresentQueuedSprites;
                until game_over or room_changed or exploded;

                WaitFrame;

            until game_over;

            UnInstallGameplayInput;
            keyboardInputEnabled := true;
            FadeOut;
            StopSong;
        end;

    until false;

    UnInstallInput;
    DoneSound;
    ScreenDone;
end.
