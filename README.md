# Flob STE Port Notes

Port gry **Flob** z Atari 8-bit / MadPascal do Atari STE / Free Pascal.

Oryginalne zrodla sa w `../flob`. Port STE jest w tym katalogu (`flob-ste`).

## Status

Gra kompiluje sie do `flob.prg` i ma juz dzialajacy glowny przeplyw:

- title screen, cutscenes, credits,
- world selector,
- ekrany miedzy swiatami / end-world / game-over,
- achievements screen,
- ladowanie swiata i pokoju,
- render tla 320x160 w playfieldzie,
- HUD i message cache,
- Flob, slime i world sprite'y renderowane blitterem z atlasu,
- flip screen z wizualnym efektem card-flip,
- joystick w trybie gry przez raw IKBD handler,
- klawiatura w menu / title / ekranach pomocniczych,
- podstawowe kolizje, teleporty, sprite keys, portals, slimes, enemies, exits,
- wspolna paleta sprite atlasu dla pokojow gry,
- level colors mapowane z danych A8 przez `STE_PAL`.

Najwazniejsze braki sa w `TODO.md`. Na dzis glowne otwarte obszary to audio, pelny/polerowany stats screen, reveal effect, dalsza optymalizacja restore tła pod sprite'ami oraz pelna weryfikacja wszystkich swiatow.

## Build

Wymagane narzedzia:

- Free Pascal cross compiler: `/opt/fpc/lib/fpc/3.3.1/ppcross68k`
- `vasmm68k_mot`
- Python 3 z Pillow
- opcjonalnie Hatari do uruchamiania

Podstawowe komendy:

```sh
make
make run
make clean
```

`make run` uruchamia:

```sh
hatari -w --monitor rgb --machine ste --fast-boot true flob.prg
```

Uwaga: Makefile nie sledzi jeszcze wszystkich wygenerowanych `generated/sprite_assets_atlas/*.inc`. Po zmianach w atlasie lub generatorze najbezpieczniej robic:

```sh
make sprite-atlas-assets-only
make clean
make
```

## Struktura

Najwazniejsze pliki:

- `flob.pas` - glowny kod portu STE.
- `const.inc` - stale gry, kody komend leveli, SFX, klawisze, tryby sprite'ow.
- `types.inc` - rekordy danych oryginalu i struktury STE (`TSteSpriteFrame`, `TSteTile` itd.).
- `input.inc` - obsluga wejscia wysokiego poziomu.
- `saving_routines.inc` - save/progress.
- `asm/font.s` - assemblerowa procedura `DrawChar`.
- `asm/ikbd.s` - raw IKBD joystick handler dla trybu gry.
- `unapl.s` - dekompresja Apultra.
- `worlds/*.inc` - skonwertowane dane swiatow i pokojow.
- `images/*.inc` - skonwertowane tla, title/cutscene/menu assets.
- `generated/*.inc` - wygenerowane assety STE.

Wazne generatory:

- `generate_world_tiles.py` - konwersja kafli/tile'i do formatu STE.
- `export_flob_sheet.py` - eksport Floba z oryginalnych dwoch warstw PMG do edytowalnego PNG.
- `export_lsy_sheets.py` - eksport LSY/PMG sprite sheets.
- `build_full_sprite_atlas.py` - atlas wszystkich wyciagnietych sprite'ow.
- `build_used_sprite_atlas.py` - atlas tylko sprite'ow uzywanych przez port STE.
- `generate_sprite_assets_from_atlas.py` - konwersja atlasu PNG do blitterowych masek/danych `.inc`.
- `generate_world_sprite_atlas_map.py` - mapowanie oryginalnych adresow sprite'ow ze swiata na atlasowe dane STE.
- `generate_achievements.py`, `generate_endworld_icons.py`, `generate_world_icons.py` - konwersja UI assets.

## Rendering

Ekran STE low-res: 320x200, 4 bitplanes.

Bufory:

- `SCREEN_LOG` - bufor logiczny, do ktorego rysujemy aktualna klatke.
- `SCREEN_PHY` - bufor fizyczny wyswietlany przez STE.
- `SCREEN_BKG` - trzeci bufor z tlem pokoju/playfieldu.

`SwapScreen` ustawia logiczny i fizyczny ekran bezposrednio przez rejestry STE oraz aktualizuje Line-A base, a `VSync` jest ostatnia operacja, zeby ograniczyc tearing sprite'ow.

Playfield pokoju ma 320x160 i zaczyna sie od `LEVEL_OFFSET_Y` / `BG_IMAGE_OFFSET_Y`. HUD i message sa poza playfieldem i maja cache, zeby nie przepisywac ich co klatke.

## Blitter

Port ma wlasne procedury blitterowe:

- `BlitterCopyData16`
- `BlitterCopyBitmap4`
- `BlitterClearBitmap4`
- `DrawGeneratedSpriteFrameBlitter`

Sprite blit:

1. maska: `SRC_AND_DST`
2. grafika: `SRC_OR_DST`

Sprite'y sa rysowane do `SCREEN_LOG`, potem nastepuje swap.

Gameplay przechowuje osobna liste narysowanych sprite'ow dla obu stron ekranu. Przy ponownym uzyciu bufora przywracane sa z `SCREEN_BKG` tylko scalone prostokaty starych i nowych pozycji, a przerysowywane sa sprite'y przecinajace te obszary. Niezmienione sprite'y pozostaja w buforze bez kolejnych blitow. Dla bardzo duzego lub rozdrobnionego obszaru renderer automatycznie wraca do pelnej kopii ekranu.

## Sprite Atlas

Glowne edytowalne zrodlo sprite'ow dla gry to:

```text
images/sprite_atlas/used_sprites.png
images/sprite_atlas/used_sprites.json
```

`used_sprites.png` zawiera:

- `flob`,
- `slime`,
- wszystkie world sprite'y faktycznie referencjonowane przez `PUT_SPRITES` w portowanych swiatach.

Pelny atlas `all_sprites.png/json` zostaje jako referencja, ale gra domyslnie generuje assety z `used_sprites`.

Po recznej zmianie grafiki lub palety w `used_sprites.png`:

```sh
make sprite-atlas-assets-only
make clean
make
```

Jesli trzeba wygenerowac atlas od zera z oryginalnych zrodel:

```sh
make used-sprite-atlas
make sprite-atlas-assets-only
make clean
make
```

Uwaga: `make used-sprite-atlas` nadpisze reczne zmiany w `used_sprites.png`.

### Paleta Sprite'ow

Sprite atlas jest 4bpp, ale praktycznie:

- indeks `0` = transparent,
- indeksy `1..3` sa zarezerwowane dla kolorow pokoju/tla,
- indeksy `4..14` sa dla sprite'ow,
- indeks `15` jest uzywany m.in. pod message/text special color.

Generator czyta palete bezposrednio z aktualnego PNG, nie z JSON-a. Jesli PNG uzyje indeksu `>15`, generator przerwie z bledem, bo STE sprite'y sa pakowane jako 4 bitplanes.

### Flob i PMG Overlap

Oryginalny Flob sklada sie z dwoch playerow PMG (`flobFrames0` + `flobFrames1`) nakladanych na siebie. W overlayu P0+P1 powstaje trzeci kolor, u nas bialy kolor oczu.

`export_flob_sheet.py` eksportuje Floba jako splaszczony sprite 4bpp:

- P0 = kolor bazowy,
- P1 = drugi kolor,
- P0+P1 = bialy overlap.

Mruganie oczu nie jest osobnym sprite'em. To ramka `FRAME_BLINK = 2`, wybierana losowo gdy Flob stoi.

### SPRITE_COMBINED i warstwy P0/P1

W `used_sprites.png/json` nazwy zakonczone `_p0` i `_p1` oznaczaja osobne dane dwoch playerow PMG z oryginalu. Nie nalezy jednak zakladac, ze kazda taka para jest tylko sposobem A8 na uzyskanie dodatkowego koloru.

Port zachowuje dla obu czesci osobne:

- `spriteFrame[0..1]` i liczby klatek,
- wysokosci, typy ruchu i animacje,
- pozycje, z dodatkowym przesunieciem drugiej czesci przez `sprites.gap`,
- maski kolizji i warunki widocznosci.

Dlatego `SPRITE_COMBINED` pozostaje elementem logiki gry. Bezpieczna optymalizacja polega na scalaniu offline tylko prawdziwych nakladek PMG: zgodna pozycja, rozmiar, przebieg animacji i zerowy gap. Obiekty z przesunieciem lub niezaleznymi klatkami sa obiektami zlozonymi i nadal wymagaja osobnych czesci albo specjalnie wygenerowanych kombinacji.

Aktualny atlas zawiera:

- `flob` i `slime` jako pojedyncze sprite'y,
- 73 pary `_p0` + `_p1`,
- 16 sprite'ow majacych tylko `_p0`.

Nie nalezy automatycznie splaszczac wszystkich par klatka-do-klatki: w danych wystepuja pary o roznej liczbie klatek, np. `9+7`, `2+4` i `7+3`. Raport klasyfikacji uzyc `SPRITE_COMBINED` powinien wskazac, ktore przypadki sa nakladka kolorow, a ktore obiektem zlozonym.

### Vertical Flip Sprite'ow

Oryginal A8 przy flip screen czytal dane PMG sprite'a od konca, czyli pionowo odwracal sprite. STE atlas generuje druga polowe klatek jako vertical-flip. `ShowSprite` i pikselowa kolizja wybieraja te flipped-klatki gdy:

```pascal
flipped and (sprites.flipable[num] = 1)
```

To jest wazne np. dla bramki klatki w pierwszym pokoju, gdzie bez vertical-flip wygladala jak otwierana/zamykana samym flipem.

## Gameplay Loop

Glowny loop gry robi w uproszczeniu:

1. `GameplayFrameTick`
2. `BeginQueuedSpritesFrame`
3. wejscie joysticka
4. flip / ruch / grawitacja / animacja Floba
5. `DrawSlimes`
6. `DrawFlob`
7. `AnimateSprite`
8. `ShowSprites`
9. `CheckEvents`
10. kolizje / przejscia pokojow / death / achievements
11. `PresentQueuedSprites`

W trybie gry klawiatura nie jest czytana do sterowania. Joystick idzie przez raw IKBD handler. Menu/title/cutscenes nadal korzystaja z klawiatury.

## Kolizje

Oryginal A8 uzywal:

- kolizji PMG z playfieldem/PMG,
- kolorow tla do kolizji podlogi/zagrozen,
- sprite hardware collision.

Port STE:

- podloga/zagrozenia sa sprawdzane przez `GetPix` z danych tla,
- slime collision jest osobna logika ekranowa,
- world sprite collision ma najpierw szybki rect check, a potem pikselowa kolizje maska-vs-maska z atlasowych sprite'ow,
- po teleportach jest release guard, zeby nie wyjsc natychmiast z portalu,
- po flipie jest guard na world sprite collision do pierwszego ruchu, zeby nie lapac natychmiastowych kontaktow z fazy przejsciowej.

## Flip Screen

`FlipGameplayEffect` robi card-flip efekt dla playfieldu. Kazda skompresowana klatka jest kopiowana pojedynczym przebiegiem Blittera z odpowiednim `SrcIncY`; podczas zwezania czyszczone sa tylko nowo odsloniete pasy obu buforow. CPU pozostaje uzywany tylko jako fallback dla wysokosci niedzielacych 160 oraz do fizycznego odwrocenia linii `SCREEN_BKG`. `displayFlipped` pilnuje orientacji bufora tla. Po flipie:

- `flipped` zmienia logike gry,
- `flobY := 84 - flobY`,
- sprite'y flipable korzystaja z pionowo odwraconych klatek atlasu,
- kolizje sprite'ow uzywaja tej samej orientacji co render.

## Palety

Kolory pokoju pochodza z danych oryginalu i ida przez `STE_PAL`.

`RebuildRoomPalette` sklada palete pokoju:

- sloty tła/kolizji z level colors,
- sloty sprite'ow z `SPRITE_ATLAS_PAL`,
- slot message moze migac przez bezposrednia zmiane palety.

Title, cutscenes, achievements i menu maja osobne przeplywy palet i nie powinny przypadkowo dostawac palety sprite atlasu.

## UI / Screens

Zaimplementowane / funkcjonalne:

- title screen,
- cutscenes z tekstem po obrazku, linia po linii,
- world selector,
- achievements,
- game over,
- end-world/inter-world screens,
- HUD,
- message cache pod plansza.

Do dopracowania:

- stats screen nadal ma stuby `ShowInt` / `ShowTime`,
- layout world selector docelowo bedzie wiekszy/pelnoekranowy,
- finalny font i finalny wyglad UI sa jeszcze otwarte.

## Audio

Audio jest celowo zostawione na koniec.

Aktualnie:

```pascal
procedure FSfx(patch: byte); begin end;
procedure Sfx(patch: byte);  begin end;
```

Kod gry juz wywoluje `Sfx` / `FSfx` w miejscach zgodnych z oryginalem, wiec pozniejsza implementacja audio powinna podpiac sie do tych procedur.

Lista potrzebnych SFX jest w `TODO.md`.

## Debug / Cheat

`CheckDiags` jest zachowany jako prosty entry point dla dev/cheat mode.

Aktualnie hold `H` przy starcie wlacza `cheatmode`, ktory:

- pokazuje `Wn Rnn` na gornym pasku,
- pozwala przechodzic po pokojach klawiszami `[` (poprzedni) i `]` (nastepny), z zawijaniem,
- odczytuje te klawisze przez odchudzony handler AGT-style (128 key states + 256 event ring), bez przywracania BIOS-owego odczytu klawiatury w gameplayu,
- daje max slime,
- odblokowuje swiaty w selectorze.

Oryginalny slime editor nie jest planowany.

## Typowe Workflow

Zmiana kodu:

```sh
make
```

Jesli Makefile nie widzi zmian:

```sh
make clean
make
```

Zmiana palety/grafiki w `used_sprites.png`:

```sh
make sprite-atlas-assets-only
make clean
make
```

Regeneracja uzywanego atlasu z oryginalnych zrodel:

```sh
make used-sprite-atlas
make sprite-atlas-assets-only
make clean
make
```

Regeneracja tile'i:

```sh
make worlds/world_tiles.inc
```

Regeneracja ikon/achievements zwykle dzieje sie przez zaleznosci Makefile, ale mozna odpalac odpowiednie `generate_*.py` recznie.

## Uwaga Dla Przyszlego Mnie

Najlatwiej zepsuc:

- faze `flipped` vs `displayFlipped`,
- sprite'y flipable bez vertical-flip,
- cache `SCREEN_BKG`, jesli dynamiczne sprite'y przypadkiem trafia do tła,
- palete sprite atlasu, jesli uzyjesz indeksow spoza `4..14`,
- build, jesli zapomnisz `make clean` po zmianie generowanych `.inc`,
- joystick, jesli w trybie gry znow zaczniemy czytac klawiature normalnym GEMDOS/BIOS flow.

Jesli cos wyglada jak “sprite zostaje w obu pozycjach” albo “bramka otwiera sie od samego flipu”, najpierw sprawdz:

- czy `SCREEN_BKG` jest czyste,
- czy sprite idzie przez flipped-klatke,
- czy kolizja uzywa tej samej orientacji co render,
- czy `queuedSpriteCount` nie zostal wyczyszczony/przeniesiony w zlym momencie.
