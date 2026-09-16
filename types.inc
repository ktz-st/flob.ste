type
    TString = string[32];

// All records use {$PACKRECORDS 1} so their in-memory layout matches the
// packed binary data produced by the original 8-bit Atari game.
// The 6502 never needed alignment; the 68000 FPC would otherwise insert
// padding before word/longword fields at odd offsets, breaking all
// Move(..., SizeOf(...)) data reads.

{$PACKRECORDS 1}

type TWorld = record
    levelNum: byte;
    state: byte;
    name: TString;
    flobx, floby, start: byte;
    startingSlime: word;
    totalSlimeCount: byte;
    secretsCount: byte;
    timeTreshold: word;
    scoreTreshold: word;
    goalcolor1: byte;
    goalcolor2: byte;
    bank: byte;
    assetBank: byte;
    imgBank: byte;
    iconPtr: word;
    rmtPtr: word;
    iconFlobX: byte;
    iconFlobY: byte;
    iconFlobFrame: byte;
    lvlPtr: array [0..32] of word;
end;

type TWorldStats = record
    attempts: word;
    winCount: word;
    failCount: word;
    flawlessCount: word;
    mastersCount: word;
    pickAllCount: word;
    secretAllCount: word;
    speedRunsCount: word;
    maxSlimes: byte;
    maxSecrets: byte;
    minDeaths: word;
    maxDeaths: word;
    bestTime: word;
    totalSlimes: cardinal;
    totalDeaths: cardinal;
    totalTime: cardinal;
    bestScore: word;
    totalScore: cardinal;
end;

type TGlobalStats = record
    attempts: cardinal;
    winCount: cardinal;
    failCount: cardinal;
    totalScore: cardinal;
    totalTime: cardinal;
    totalSlimes: cardinal;
    totalDeaths: cardinal;
    flawlessWorlds: byte;
    allSlimesWorlds: byte;
    allSecretsWorlds: byte;
    mastersWorlds: byte;
    speedRunsWorlds: cardinal;
    flawlessCount: cardinal;
    allSlimesCount: cardinal;
    allSecretsCount: cardinal;
    goalsCount: byte;
end;

type TAchievement = record
    name: string[20];
    desc: string[20];
    value: byte;
    oper: byte;
    treshold: cardinal;
end;

type TLevel = record
    colors: array [0..3] of byte;
    room_top: byte;
    room_right: byte;
    room_bottom: byte;
    room_left: byte;
end;

type TSprites = record
    state: byte;
    gap: byte;
    spriteWidth: array[0..1] of byte;
    stype: array[0..1] of byte;
    flipable: array[0..1] of byte;
    x: array[0..1] of byte;
    y: array[0..1] of byte;
    goal: array[0..1] of byte;
    frameOn: array[0..1] of byte;
    frameOff: array[0..1] of byte;
    frameSpeed: array[0..1] of byte;
    moves: array[0..1] of byte;
    param1: array[0..1] of byte;
    param2: array[0..1] of byte;
end;

type TSpriteData = record
    frameCount: array[0..1] of byte;
    height: array[0..1] of byte;
    bank: byte;
    colors: array[0..1] of word;
    frames: array[0..1, 0..15] of word;
end;

type TAnimationStep = record
    times: byte;
    deltaX: byte;
    deltaY: byte;
    deltaFrame: byte;
end;

type TImage = record
    start: word;
    len: word;
    bank: byte;
end;

type TSteTile = record
    sourceAddr: word;
    widthPx: word;
    heightPx: word;
    rowWords: word;
    dataOffset: word;
    collisionOffset: word;
end;

type PSteTile = ^TSteTile;

// Not original 8-bit data: these tables are emitted as Pascal source by the
// asset tools, so they need not be byte-packed. At 13 bytes every second frame
// landed on an odd address, and FPC then copied every word field through a
// byte loop -- two of those cost ~100 cycles in each QueueGeneratedSprite call.
// 16 bytes keeps every field aligned and makes the frame index a single shift.
{$PACKRECORDS 4}
type TSteSpriteFrame = record
    widthPx: word;
    heightPx: word;
    rowWords: word;
    maskOffset: word;
    dataOffset: word;
    paletteOffset: word; // Flob/slime with paletteCount=0: EMS mask word offset.
    paletteCount: byte;
end;

{$PACKRECORDS 1}

type PSteSpriteFrame = ^TSteSpriteFrame;

type TLastLanded = record
    lvl: byte;
    x: byte;
    y: byte;
    flipped: boolean;
end;

{$PACKRECORDS DEFAULT}

type TLevelDataArray = array[0..MAX_LEVEL_DATA-1] of byte;
