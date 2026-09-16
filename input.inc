// STE input: joystick via IKBD joyvec + keyboard via BIOS bconin.
// Joystick: maps IKBD active-high bits to Atari 8-bit active-low stick0/strig0.
// Keyboard: stores raw ST scan code in kbcode; KEY_*_CODE constants are full scan codes.

var
    prevFireDown: boolean = false;
    firePressedEdge: boolean = false;
    old_joyvec: pointer;
    old_ikbdvec: pointer;
    oldConterm: byte;
    joy_on: byte = $14;        // IKBD command: enable joystick event reporting
    raw_joy_on: array[0..2] of byte = ($11, $14, $12); // resume, joystick events, mouse off
    mouse_on: byte = $08;      // IKBD command: disable joy, restore mouse
    keyboardInputEnabled: boolean = true;
    gameplayInputInstalled: boolean = false;
    gameplayKeyPressed: array[0..127] of boolean;
    gameplayKeyEventTail: byte = 0;

// Called from IKBD interrupt; A0 points to 3-byte joy packet, byte 2 = joy1.
procedure ReadJoyStatus(); assembler;
asm
    move.b  2(A0), joyStatus
    rts
end;

procedure ResetJoystickState;
begin
    joyStatus := 0;
    stick0 := $FF;
    strig0 := 1;
    prevFireDown := false;
    firePressedEdge := false;
    FillChar(gameplayKeyPressed, SizeOf(gameplayKeyPressed), 0);
    gameplayKeyEventTail := 0;
end;

procedure InstallInput;
var vt: PKBDVECS;
begin
    oldConterm := PByte(pointer(longword($00000484)))^;
    PByte(pointer(longword($00000484)))^ := oldConterm and $FE;
    xbios_ikbdws(0, @joy_on);
    vt := xbios_kbdvbase();
    old_joyvec := vt^.joyvec;
    vt^.joyvec := @ReadJoyStatus;
end;

procedure UnInstallInput;
var vt: PKBDVECS;
begin
    if gameplayInputInstalled then
        UnInstallGameplayInput;
    xbios_ikbdws(0, @mouse_on);
    vt := xbios_kbdvbase();
    vt^.joyvec := old_joyvec;
    PByte(pointer(longword($00000484)))^ := oldConterm;
end;

procedure InstallGameplayInput;
begin
    if gameplayInputInstalled then exit;
    ResetJoystickState;
    RawIkbdJoyStatus := 0;
    RawIkbdState := 0;
    RawIkbdKeyEventHead := 0;
    FillChar(RawIkbdKeyStates, 128, 0);
    FillChar(RawIkbdKeyEventRing, 256, 0);
    gameplayKeyEventTail := 0;
    old_ikbdvec := pointer(PLongWord(pointer(longword($00000118)))^);
    PLongWord(pointer(longword($00000118)))^ := longword(@RawIkbdHandler);
    xbios_ikbdws(2, @raw_joy_on);
    gameplayInputInstalled := true;
end;

procedure UnInstallGameplayInput;
begin
    if not gameplayInputInstalled then exit;
    PLongWord(pointer(longword($00000118)))^ := longword(old_ikbdvec);
    xbios_ikbdws(0, @joy_on);
    RawIkbdState := 0;
    RawIkbdKeyEventHead := 0;
    FillChar(RawIkbdKeyStates, 128, 0);
    gameplayKeyEventTail := 0;
    gameplayInputInstalled := false;
    ResetJoystickState;
end;

procedure PollJoystickState;
var rawJoy, eventHead, keyEvent: byte;
begin
    if gameplayInputInstalled then
        joyStatus := RawIkbdJoyStatus;

    rawJoy := joyStatus and $8F; // keep only directions and fire, ignore any packet noise
    if gameplayInputInstalled then begin
        if PByte(@RawIkbdKeyStates)[KEY_LEFT_CODE] <> 0 then
            rawJoy := rawJoy or $04;
        if PByte(@RawIkbdKeyStates)[KEY_RIGHT_CODE] <> 0 then
            rawJoy := rawJoy or $08;
        // Opposing directions cancel, including keyboard versus joystick.
        if (rawJoy and $0C) = $0C then rawJoy := rawJoy and $F3;
    end;
    // Shared held state: pressing the other source while held creates no edge.
    if gameplayInputInstalled and
       (PByte(@RawIkbdKeyStates)[KEY_SPACE_CODE] <> 0) then
        rawJoy := rawJoy or $80;

    // Joystick: IKBD byte active-high → invert to get 8-bit active-low stick0
    // IKBD bit layout: 0=up 1=down 2=left 3=right 7=fire
    stick0 := byte((not rawJoy) or $F0);  // invert bits 0-3; upper nibble = inactive
    if (rawJoy and $80) <> 0 then strig0 := 0   // fire pressed
    else strig0 := 1;

    firePressedEdge := ((rawJoy and $80) <> 0) and (not prevFireDown);
    prevFireDown := (rawJoy and $80) <> 0;

    FillChar(gameplayKeyPressed, SizeOf(gameplayKeyPressed), 0);
    eventHead := RawIkbdKeyEventHead;
    while gameplayKeyEventTail <> eventHead do begin
        keyEvent := PByte(@RawIkbdKeyEventRing)[gameplayKeyEventTail];
        Inc(gameplayKeyEventTail);
        if keyEvent < $80 then gameplayKeyPressed[keyEvent] := true;
    end;
end;

// Poll keyboard and joystick; call once per frame (from WaitFrame).
// bconin(2) returns (scancode << 16) | ascii  — same format as GEMDOS Cconin.
// Use shortint local (like fuji-tetris) to read only D0.B and avoid
// false positives from garbage in upper bits of D0 after the trap.
procedure ReadInput;
var raw: longint;
    stat: shortint;
begin
    if keyboardInputEnabled then begin
        stat := bios_bconstat(2);
        if stat <> 0 then begin
            raw    := bios_bconin(2);
            kbcode := byte(raw shr 16);   // raw ST scan code in bits 23-16
            skstat := skstat and $FB;     // clear bit 2 → "key pressed"
        end else begin
            kbcode := $FF;
            skstat := skstat or $04;      // set bit 2 → "no key"
        end;
    end else begin
        kbcode := $FF;
        skstat := skstat or $04;
    end;

    PollJoystickState;
end;

function IsStartingButtonDown: boolean;
begin
    Result := (strig0 = 0) or (kbcode = KEY_ENTER_CODE) or (kbcode = KEY_SPACE_CODE);
end;

procedure WaitForStartKeyUp;
begin
    repeat ReadInput; VSync; until not IsStartingButtonDown;
end;

// Drop keystrokes buffered while nobody was reading input. FadeOut and the
// room loaders never call ReadInput, so a press during them survives in the
// BIOS buffer and the next IsStartingButtonDown consumes it -- which inside
// ShowCutScene skips every remaining slide, not just the current one. The 8-bit
// original reads the hardware directly and has nothing to flush.
procedure FlushBufferedKeys;
var stat: shortint;   // D0.B only: the trap leaves garbage in the upper bytes,
                      // and comparing the full result never reads as empty
    guard: byte;
begin
    guard := 0;
    repeat
        stat := bios_bconstat(2);
        if stat = 0 then break;
        bios_bconin(2);
        Inc(guard);
    until guard = 64;
    kbcode := $FF;
    skstat := skstat or $04;
end;

function CRT_StartPressed:  boolean;
begin Result := IsStartingButtonDown; end;

function CRT_FirePressedEdge: boolean;
begin Result := firePressedEdge; end;

function CRT_GameplayKeyPressed(code: byte): boolean;
begin
    Result := (code < 128) and gameplayKeyPressed[code];
end;

function CRT_SelectPressed: boolean;
begin Result := false; end; // Space is FIRE, no longer the legacy SELECT alias.

function CRT_HelpPressed: boolean;
begin Result := (kbcode = KEY_H_CODE); end;

function CRT_OptionPressed: boolean;
begin Result := (kbcode = KEY_M_CODE); end;

function CRT_Keypressed: boolean;
begin Result := (skstat and $04) = 0; end;  // bit 2 clear = key available
