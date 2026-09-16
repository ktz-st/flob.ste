# Flob STE Port Notes

Port gry **Flob** z Atari 8-bit / MadPascal do Atari STE / Free Pascal.

Oryginalne zrodla sa w `../flob`. Port STE jest w tym katalogu (`flob-ste`).

## Status

Gra kompiluje sie do `flob.prg` i ma juz dzialajacy glowny przeplyw:

- title screen, cutscenes, credits,
- world selector,
- ekrany miedzy swiatami / end-world / game-over,
- achievements screen,
- wariant title screenu z korona po zdobyciu koncowego achievementu,
- ladowanie swiata i pokoju,
- render tla 320x160 w playfieldzie,
- HUD i message cache,
- Flob, slime i world sprite'y renderowane blitterem z atlasu,
- flip screen z wizualnym efektem card-flip,
- eksplozja Floba z rozsunieciem warstw i opadajacymi czastkami,
- joystick i spacja jako FIRE w trybie gry przez raw IKBD handler,
- klawiatura w menu / title / ekranach pomocniczych,
- podstawowe kolizje, teleporty, sprite keys, portals, slimes, enemies, exits,
- dynamiczna aktualizacja kolizji po `PUT_TILE`, w tym gaz, kable i zapory,
- wspolna paleta sprite atlasu dla pokojow gry,
- level colors mapowane z danych A8 przez `STE_PAL`,
- efekty SFX odtworzone z danych POKEY przez PSG lub syntezator DMA STE.

Najwazniejsze braki sa w `TODO.md`. Muzyka i core SFX sa juz podpiete.
Otwarte obszary to finalna grafika, pelna weryfikacja wszystkich swiatow,
polish audio/UI oraz osobna optymalizacja pamieci pod 1 MB.

Build z 2026-09-09 ma `1106170 B` (okolo 1080 KiB). Dawne `994124 B`
dotyczylo etapu migracji assetow, nie obecnej wersji. Rozmiar PRG nie jest
pomiarem calego zapotrzebowania RAM (dochodzi BSS, bufory i system).
Wygladzony title screen, ladowanie skompresowanych
danych swiatow i dekompresja kolizji per pokoj zostaly potwierdzone w grze.

### Ostatnie Optymalizacje (2026-09-09)

Wszystkie piec punktow ostatniego audytu zostalo wdrozonych:

- Zmiana punktow odswieza tylko cyfry 40x8; blitter kopiuje 48x8 wraz z prawym marginesem do obu stron ekranu.
- EMS omija przygotowanie masek brzegowych i wskaznika maski potrzebnych tylko IMS.
- Kolizje szerokich sprajtow porownuja maski oknami 16-bitowymi zamiast pojedynczych pikseli.
- Dynamiczne zagrozenia porownuja maski wierszy Floba; licznik zagrozen wylacza dodatkowy test po usunieciu ostatniego bitu.
- Stale ID w zwartej kolejce zapobiegaja nadmiarowemu przerysowaniu po zebraniu slime'a.

Wczesniej wdrozono ASM IMS, EMS dla Floba/slime i zbiorcze odtwarzanie
prostokatow w `asm/restore.s`. Nadal sa trzy bufory i osobna historia sprajtow
dla kazdej strony; odtwarzanie prostokatow tla uzywa teraz HOG ($C0).

Spacja wspoldzieli z joystickiem FIRE i detekcje zbocza. Przytrzymanie lub
dolozenie drugiego zrodla nie powoduje kolejnego flipa. W menu spacja
potwierdza/startuje zamiast dawnego SELECT.

Testy w Hatari STE 8 MHz przeszly: 4000 porownan masek, 2000 porownan
dynamicznych zagrozen, licznik zagrozen, 80 klatek dirty-renderera na obu
buforach (takze nakladanie/usuwanie), stan FIRE oraz 12 zmian wyniku.
Istniejace testy EMS/IMS obejmuja odpowiednio 2304 i 32720 porownan.
Kontrolowany renderer W0 R06 utrzymuje 50 FPS bez opuszczonych terminow VBL;
nie obejmuje pelnej fizyki, zbierania, animacji NPC ani wiadomosci.
Nie mamy jeszcze pomiaru przyspieszenia calej rozgrywki po ostatnich zmianach.

Teraz priorytetem jest granie i zglaszanie regresji z numerem W/R, orientacja
i czynnoscia. Dalsze optymalizacje CPU dopiero po pomiarze konkretnego problemu;
ukonczony audyt nie oznacza wyczerpania wszystkich mozliwych optymalizacji.

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
- `asm/ems.s`, `asm/ims.s` - sterowniki sprajtow wywolywane z FPC przez cdecl.
- `asm/restore.s` - zbiorcze odtwarzanie listy prostokatow z BKG do LOG.
- `danger_expand.inc` - tablica rozszerzania bitow komorek kolizji do par pikseli.
- `unapl.s` - dekompresja Apultra.
- `worlds/*.inc` - skonwertowane dane swiatow i pokojow.
- `images/*.inc` - skonwertowane tla, title/cutscene/menu assets.
- `generated/*.inc` - wygenerowane assety STE.

Wazne generatory:

- `create_game_tiles.py` - jednorazowy import i Scale2x kafli do kanonicznych PNG.
- `generate_world_tiles.py` - pakowanie kanonicznych PNG jako maska + planar STE bez preshiftow.
- `export_flob_sheet.py` - eksport Floba z oryginalnych dwoch warstw PMG do edytowalnego PNG.
- `export_lsy_sheets.py` - eksport LSY/PMG sprite sheets.
- `build_full_sprite_atlas.py` - atlas wszystkich wyciagnietych sprite'ow.
- `build_used_sprite_atlas.py` - referencyjny eksport sprite'ow uzywanych przez port STE z oryginalnych danych.
- `create_game_sprite_sheet.py` - jednorazowa migracja eksportu do produkcyjnego arkusza na siatce 16 px oraz generator podpisanego guide'a.
- `create_game_rooms.py` - jednorazowy Scale2x oryginalnych pokojow do kanonicznych PNG 320x160.
- `create_game_world_icons.py` - jednorazowy Scale2x ikon selektora do kanonicznych PNG 192x80.
- `create_game_endworld_icons.py` - jednorazowy Scale2x czterech ikon podsumowania swiata do kanonicznych PNG 64x80.
- `create_game_cutscenes.py` - jednorazowy Scale2x slajdow intro/outro do kanonicznych PNG 320x160.
- `create_game_title.py` - jednorazowy Scale2x zwyklego i ukoronowanego title screenu do kanonicznych PNG 320x184.
- `generate_world_data.py` - kompresja Apultra danych poziomow per swiat i kolizji per pokoj.
- `convert_images.py` - konwersja kanonicznych pokojow i cutscenek bez skalowania do planarnych danych STE oraz kompresja Apultra.
- `generate_sprite_assets_from_atlas.py` - konwersja atlasu PNG do blitterowych masek/danych `.inc`.
- `generate_world_sprite_atlas_map.py` - mapowanie oryginalnych adresow sprite'ow ze swiata na atlasowe dane STE.
- `generate_sfx_synth.py` - ekstrakcja kompaktowych strumieni rejestrow POKEY 50 Hz dla PSG/DMA.
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
images/sprite_atlas/game_sprites.png
images/sprite_atlas/game_sprites.json
```

`game_sprites.png` jest indeksowanym arkuszem na siatce 16 px. Jego szerokosc
jest automatycznie dobierana do najdluzszego pasa i zaokraglana do 16 px:

- zwykla klatka zajmuje slot 16 px szerokosci,
- szeroka klatka zajmuje slot 32 px, ale JSON zachowuje jej rzeczywiste 20-32 px,
- kazdy sprite zaczyna sie na granicy 16 px w pionie,
- pas sprite'a ma 16, 32 albo 48 px, zalezne od rzeczywistej wysokosci,
- przezroczysty padding nie jest czescia klatki, bo rzeczywisty prostokat zapisuje JSON,
- arkusz zawiera Floba, slime i wszystkie world sprite'y uzywane przez port.

Prawdziwe warstwy kolorow PMG sa juz na siebie nalozone jako finalne
`*_merged`. Obiekty rozstawione przez `gap` sa polaczone na szerokosc jako
`*_compound`, np. telefon ma rzeczywiste 20 px w slocie 32 px. Tylko pary
bedace niezaleznymi obiektami `SPRITE_DOUBLE` pozostaja jako osobne `_p0/_p1`.

Pomocniczy `game_sprites_guide.png` pokazuje nazwy, numery klatek i siatke. Nie jest
uzywany przez build i mozna go odswiezyc przez `make game-sprite-guide`.

`used_sprites.png/json` oraz `all_sprites.png/json` sa tylko eksportami
referencyjnymi z oryginalnych danych. Build nie czyta ich automatycznie.

Nie stosujemy automatycznego Scale2x do produkcyjnego atlasu. Testowy podglad
pokazal, ze algorytm dobrze wygladza czesc duzych ksztaltow, ale znieksztalca
drobne sprite'y i szczegoly animacji. Finalne wygladzanie `game_sprites.png`
pozostaje praca grafika wykonywana selektywnie, przy zachowaniu siatki i palety.
Flob jest wygladzony tylko na zewnetrznym konturze; oczy, wewnetrzne kolory i
klatki rozpadu zachowuja oryginalne piksele powiekszone 2x.

Po recznej zmianie grafiki lub palety w `game_sprites.png`:

```sh
make sprite-atlas-assets-only
make clean
make
```

Pierwsze utworzenie kanonicznego arkusza z eksportu referencyjnego:

```sh
make used-sprite-atlas
make game-sprite-sheet-init
```

`game-sprite-sheet-init` celowo odmawia nadpisania istniejacego
`game_sprites.png`. Opcji `create_game_sprite_sheet.py --force` nalezy uzywac
tylko swiadomie, poniewaz usuwa prace grafika i odtwarza arkusz z eksportu.

### Paleta Sprite'ow

Sprite atlas jest 4bpp, ale praktycznie:

- indeks `0` = transparent,
- indeksy `1..3` sa zarezerwowane dla kolorow pokoju/tla,
- indeksy `4..14` sa dla sprite'ow,
- indeks `15` jest uzywany m.in. pod message/text special color.

Generator czyta palete bezposrednio z aktualnego PNG, nie z JSON-a. Jesli PNG uzyje indeksu `>15`, generator przerwie z bledem, bo STE sprite'y sa pakowane jako 4 bitplanes.

## Room Artwork

Kanonicznym zrodlem grafiki pokojow jest:

```text
game_rooms/world_00/room_00.png
game_rooms/world_00/room_00_collision.png
...
game_rooms/world_05/room_23.png
game_rooms/world_05/room_23_collision.png
```

Sa to indeksowane PNG `320x160`, uzywajace indeksow `0..3`. Poczatkowy zestaw
zostal utworzony jednorazowo algorytmem Scale2x z oryginalnych GIF-ow `160x80`.
Scale2x wybiera tylko istniejace kolory, wiec wygladza schodki bez antyaliasingu,
ditheringu i rozszerzania palety.

Kazdy pokoj ma tez kanoniczna mape kolizji `room_XX_collision.png` o rozmiarze
`160x80`. Jej indeksy `0..3` oznaczaja odpowiednio powietrze, dekoracje,
podloze i zagrozenie. Dzieki oddzieleniu mapy zmiana wygladu tla nie zmienia
fizyki gry.

Podczas builda kazda mapa kolizji jest pakowana osobnym strumieniem Apultra.
`LoadImage` rozpakowuje tylko mape aktualnego pokoju do wspolnego bufora
`3200 B`, z ktorego korzysta `GetPix`. Dane poziomow `world_XX.bin` sa pakowane
per swiat i rozpakowywane przez `LoadWorld` do wspolnego bufora `8192 B`.
Pozwala to zachowac losowy dostep logiki bez trzymania wszystkich surowych
kolizji i szesciu blokow danych w pamieci programu.

Migracja zostala sprawdzona w dzialajacej grze: przejscia miedzy pokojami,
kolizje i ladowanie swiatow zachowuja dotychczasowe zachowanie.

Zwykly build czyta pokoje i ich kolizje wylacznie z `game_rooms` i nigdy ich
nie nadpisuje. Oryginalne GIF-y sa tylko referencja oraz wejsciem do jawnego,
jednorazowego importu `make game-rooms-init`.

Po edycji jednego lub kilku pokojow wystarczy:

```sh
make room-assets
make
```

Konwerter porownuje daty plikow i regeneruje tylko zmienione pokoje. Pierwsze
utworzenie zestawu w nowym checkoutcie:

```sh
make game-rooms-init
make room-assets
```

`create_game_rooms.py --force` odtwarza wszystkie obrazy i mapy kolizji z
oryginalu oraz usuwa prace grafika, dlatego nie jest czescia normalnego builda.

## Tile Artwork

Kanonicznym zrodlem przezroczystych kafli `PUT_TILE` jest:

```text
game_tiles/world_00/00_tile_smokeleft.png
...
game_tiles/world_05/10_tile_desk_close.png
game_tiles/manifest.json
```

Sa to indeksowane PNG po jednorazowym Scale2x. Uzywaja indeksow `0..3`, a
indeks `0` jest przezroczysty. Manifest zachowuje oryginalne adresy kafli,
ktorych komendy poziomu uzywaja do wyszukania assetu.

Zwykly build czyta kafle wylacznie z `game_tiles`. Generator nie skaluje PNG i
zapisuje tylko jedna maske oraz cztery plaszczyzny bez preshiftu `+8`.
Pozycjonowanie co 8 pikseli obsluguje `SKEW` Blittera.

Po edycji PNG wystarczy zwykle `make`. Jawny rebuild kafli:

```sh
make worlds/world_tiles.inc
make
```

Pierwszy import w nowym checkoutcie wykonuje `make game-tiles-init`.
`create_game_tiles.py --force` odtwarza PNG z oryginalnych `.gfx/.asm` i
nadpisuje prace grafika, dlatego nie jest czescia normalnego builda.

## World Selector Icons

Achievements: siatka 12x7 pucharkow 24x20 (krok 24x22), importowanych
przez Scale2x z ach_off/ach_on/ach_new w oryginalnym sprites.asm.
`generate_achievement_ui.py` generuje `assets/achievement_ui.inc` dla blittera.
Palety DLI sa rozdzielone indeksami: 1..3 zwykle pucharki, 4..6 globalne,
7..9 naglowek, 10..11 opisy 8x8, 12 separatory, 15 pulsujaca ramka kursora.
Naglowek korzysta z fontu 16x16 selektora. Ramka jest uproszczeniem animacji
PMG A8 (bez jej pieciu klatek). Stan nowych pucharkow zostaje widoczny
przez cala sesje ekranu, a zapisany stan 2 przechodzi na 1 jak w oryginale.
`images/achievements_ste_preview.png` to podglad hosta z przykladowym
stanem 0/84, nie zrzut emulatora ani zrodlo builda.

Kanonicznym zrodlem ikon selektora sa indeksowane PNG `192x80`:

```text
game_world_icons/world_00.png
...
game_world_icons/world_05.png
game_world_icons/manifest.json
```

Poczatkowy zestaw powstal przez jednorazowy Scale2x oryginalnych `icon.gif`
`96x40`. Normalny build pakuje PNG bez skalowania jako surowe cztery
plaszczyzny STE dla `BlitterCopyBitmap4`. Ikony nadal uzywaja indeksow `0..3`
i zachowuja osobna palete kazdego swiata.

Selektor STE odtwarza uklad A8 w wycentrowanym obszarze 320x184:
naglowek y=8, miniatura (64,34), nazwa y=128, statystyka y=168.
`generate_selector_assets.py` generuje osobny font 16x16 przez Scale2x
oryginalnego 8x8 oraz wygladzone sprite'y Floba i strzalek z PMG.
Font jest rysowany maskowanym blitterem, bez zmiany fontu rozgrywki.
`assets/selector_ui.inc` jest wynikiem generowania; `font/selector_16x16.png`
i `images/selector_ste_preview/` to podglady, nie zrodla builda.

Paleta: 0 to wspolna czern; 1..3 to miniatura; 4..5 naglowek;
6..7 kolory nazwy z world.goalcolor1/2; 8..10 statystyki/blokada;
12..14 Flob; 15 strzalki. Bez DLI. Indeksy kanonicznych ikon
sa mapowane na selektory A8 przez SELECTOR_ICON_MAP (0,3,1,2),
poniewaz import GIF porzadkuje kolory wedlug jasnosci.
Swiaty zablokowane maja szara miniature i Floba, jak w oryginale.
Sterowanie i zmiana statystyk pozostaja dynamiczne.

Po edycji PNG wystarczy `make`. Pierwszy import wykonuje:

```sh
make game-world-icons-init
make
```

`create_game_world_icons.py --force` odtwarza ikony z oryginalnych GIF-ow i
nadpisuje prace grafika, dlatego nie jest czescia normalnego builda.

## End-world Icons

Ekran wygranej/przegranej ma uklad A8: naglowek 16x16 z cieniem y=8,
ikona 64x80 w (128,32), czas y=128, wynik y=150 i slime y=170.
Uzywa fontu selektora i maskowanego blittera. Zgony/sekrety nadal sa
liczone i zapisywane, ale nie sa dodatkowymi wierszami tego ekranu.
FIRE/Return oraz fade-in/out pozostaja aktywne.
Paleta DLI jest splaszczona: 1..3 ikona (PNG -> A8: 0,3,1,2),
4..5 naglowek, 6 czas (world.goalcolor2), 7..8 wynik/slime.
Wygrana: ikona $82, goalcolor1, goalcolor2; mapa swiata 0 ma $82,$BA,$26.
Przegrana: czaszka $38,$3F,$34. Kolory sa przepuszczane przez STE_PAL.
`preview_endworld.py` tworzy podglady hosta z przykladowymi wynikami
w `images/endworld_ste_preview/`; nie sa to zrzuty emulatora.

Kanonicznym zrodlem czterech ikon ekranu podsumowania swiata sa indeksowane
PNG `64x80`:

```text
game_endworld_icons/bigmap.png
game_endworld_icons/bigvial.png
game_endworld_icons/bigformula.png
game_endworld_icons/skull.png
game_endworld_icons/manifest.json
```

Poczatkowy zestaw powstal przez jednorazowy Scale2x oryginalnych GIF-ow
`32x40`. Normalny build pakuje gotowe PNG bez dalszego skalowania do formatu
ST-low zgodnego z `BlitterCopyBitmap4`. Wszystkie cztery grafiki zachowuja
wspolne indeksy palety `0..3`.

Po edycji PNG wystarczy `make`. Pierwszy import wykonuje:

```sh
make game-endworld-icons-init
make
```

Importer zachowuje istniejace PNG. Opcja `create_game_endworld_icons.py
--force` swiadomie odtwarza je z oryginalnych GIF-ow i nadpisuje prace grafika.

## Gameplay Sprite Palette

Sprite palette reimport: `recolor_game_atlas.py` is an explicit, destructive
artwork reimport (not part of make). It first backs up PNG/JSON/guide and the
generated palette under `images/sprite_atlas/backups/`. The pre-reimport atlas
is in `20260908-213318-735136`. It restores A8 PAL colours and PMG colour-OR
overlays for world sprites, reconstructs missile slime, and preserves Flob's
edited silhouette/eyes. Frame rectangles and reserved RGB slots 0..3/15 stay
unchanged. Reimport now finishes by assigning semantic palette roles, rather
than approximating all world-object colours with one shared palette.
`generate_sprite_assets_from_atlas.py` now writes full STE 4-bit/channel words.
After PNG edits use `make sprite-atlas-assets-only` and `make`, not reimport.

`sprite_palette_roles.py` is the explicit, backed-up atlas migration. Slots:
0..3 room, 4..6 Flob, 7..9 small slime, 10..12 world objects (P0/P1/overlap),
13 opaque black, 14 white eyes/HUD, 15 animated message. Index 0 remains sprite
transparency. The PNG palette is only an editing preview for slots 10..12;
their runtime colours come from the current original A8 frame of each layer.
The overlap is `STE_PAL[c0 or c1]`, never an OR of converted STE words.
Bigslime is a world object and therefore uses the independent object slots.
Flob invulnerability changes 4..6 only, leaving slime unchanged.

`LoadSpritesData` reads both colour arrays before either graphics array.
`ShowSprites` prepares palette colours with the queued animation frames;
`PresentQueuedSprites` writes only changed registers after SwapScreen/VSync.
BlackAll/FadeOut suppress these writes until FadeIn or SetLevelColors.
Menus retain their independent palettes. The old 16 room-colour assignments
are superseded: equal RGB in one frame does not imply a shared palette role.
The legacy binding tool refuses to alter a role-based atlas.
Normal builds still consume the canonical PNG without recolouring artist edits.

Small slime stays on the editable 16x16 grid, but the asset compiler packs the
union of visible pixels across its animation (currently 6x6, crop offset 5,5).
Generated SPR_SLIME_CROP_X/Y feed one shared drawing/collision position helper.
Pickup uses the actual Flob/slime masks and the queued slime animation frame,
not a distance from their atlas corners. Single-word masks use row-wise bit
intersection; wider objects now use 16-bit mask windows across source words.
Run `python3 -m unittest test_sprite_palette_roles` for palette, source-data,
crop reconstruction and mask-intersection regression checks.

Renderer measurement: `python3 run_slime_benchmark.py` compiles an isolated
`BENCH_SLIME` executable, runs three PAL 50 Hz / STE 8 MHz Hatari tests in W0 R06,
and writes `reports/slime_r06_benchmark_ems.md` plus raw CSV/JSON. It does not modify
the production PRG or game save. Physics, NPC animation and pickup are excluded
to isolate renderer costs. The historical pre-EMS baseline with moving Flob
plus six animated slime measured 45.47
render iterations/s, versus 50 for either workload alone (51/512 frames used
two VBLs). sysframe increments per game iteration, explaining coupled slowdowns.
Production rendering is unchanged by the conditional benchmark instrumentation.

Ending sequence: build with `-dTEST_ENDING` to enter the completion path directly
(end-world summary, outro cutscene, credits) without playing through the game; it was
built to measure the outro and is the quickest way to re-check it. `ShowCutScene` latches
the skip request before `FadeOut`, matching the original — testing it after the fade loses
a transient press, which used to shorten one slide per stray key instead of skipping.

Whole-loop profiling: `python3 profile_room.py --room 11` (add `--move`) cycle-profiles the
production gameplay loop in one room through hatari-hrdb's remote debug profiler, and
`python3 profile_report.py reports/profile_w0_r11_idle.json --out reports/x.md` attributes
the capture to symbols from an unstripped `-Xm` build whose text is byte-identical to
`flob.prg`. Unlike the renderer benchmark this includes physics, hazards, collisions,
input and the music callback. It reaches the room by arming cheatmode (H during boot),
poking `levelNum`, and patching `Explode` with an RTS so a hazard contact cannot end the
window; every detection path still runs and is still counted. `--split <symbol>` prints a
per-address breakdown, which is what separates a stalled routine from a busy one.
Requires the `hatari-debugging` skill scripts (`HATARI_SKILL_SCRIPTS` overrides the path).
W0 R11 measured 31.9 FPS against R06's 49.9; see `reports/profile_w0_r11.md`.

### Batched Background Restore

Gameplay collision/queue follow-up: `GeneratedSpritesOverlap` retains the
one-word fast path and compares wider masks in aligned 16-bit windows, not
per-pixel calls. `NarrowFlobDynamicDanger` expands eight collision-cell bits
through `danger_expand.inc` and intersects the affected Flob rows, preserving
the odd render Y offset and flipped map addressing. Wider/non-2x Flob formats
retain the general fallback. `dynamicTileDangerCount` tracks bit transitions
so clearing the last hazard disables the extra scan until another is painted.

Queued sprites have stable IDs: slime 0..19, Flob 20, world objects 21..22;
generic effect entries use 32+queue position. The list remains compact and in
the original drawing order. Per-buffer dirty matching uses IDs, not compacted
array indices, so collecting one slime does not invalidate every later entry.
Explicit IDs must be unique within a frame and below 32; generic IDs are
reserved for the renderer. Changing object draw order would require separate
invalidation; current gameplay preserves relative layering.

Flob (stable ID 20 with the Flob asset) is drawn last among queued sprites,
independent of enqueue order. This fixes W0 R13 switches overwriting him when
room-entry order differs from the gameplay loop. Other sprites keep queue order;
overlap propagation still controls whether Flob needs repainting. The target
regression covers 128 W0 R13 overlaps on both buffers and sprite orientations.

2026-09-11: dirty bookkeeping no longer globally merges rectangles. Animation
changes with identical bounds add one rectangle; changed sprites are marked
for drawing directly. Unchanged overlapping sprites are included transitively
so full-sprite redraws preserve layering. Queue fields use a single record
pointer and per-buffer history is copied in one Move. The previous bookkeeping
is available for comparison with `LEGACY_DIRTY_BOOKKEEPING` / benchmark
`--legacy-dirty`. W1 R13 renderer throughput improves from 40 to 44.44 FPS;
this is not a full gameplay FPS result. See `reports/dirty_bookkeeping.md`.

An optional `SLIME_CPU` experiment draws preshifted slime graphics/masks with
68000 AND/OR operations. Isolated drawing takes about 30% less time than EMS,
but W1 R13 remains at 44.44 FPS in the controlled render benchmark. It adds about
7 KB and is not enabled in normal builds. Reproduction commands and validation
are in `reports/slime_cpu_preshift.md`.

Delaying odd slime animation IDs by one tick (`STAGGER_SLIME`) is enabled in
normal builds since 2026-09-16. It worsens the *controlled render benchmark* in
W1 R13 from 44.52 to 42.11 FPS, because there every frame does the same work and
spreading a change over three iterations is simply more of it. In the production
loop the opposite holds: W1 R13 averages 61% of the frame budget and redraws 1.9
sprites on a typical frame, and the only frames that miss the VBL are the two
(one per screen page) where all 16 slime change at once. Staggering raises that
room from 44.3 to 46.7 FPS while total work rises 1.8%. It costs 0.3 FPS in
W0 R11, which has no peak to flatten. See `reports/slime_stagger.md`. This is
the clearest case in the project of the render benchmark and the real loop
disagreeing in sign; trust `profile_room.py` for perceived smoothness.

Graphics arithmetic (2026-09-12): `SpriteCollisionRect` uses a shift for the
current 2x scale, and `NarrowFlobDynamicDanger` shifts only after bounds checks
guarantee nonnegative numerators. Flip heights 160/80/32/8 use precomputed blitter
source increments and destination offsets; border centering also uses shifts.
The release object contains no FPC division/modulo helpers in these four routines.
Other heights retain CPU sampling as a fallback. Palette fades and text formatting
are unchanged. Gameplay verification compares the flip table against CPU sampling.

Credits (2026-09-12): seven canonical indexed `game_credits/credits_01..07.png`
images at 320x200, imported explicitly by `python3 create_game_credits.py`.
The importer decodes original ANTIC D `.gfx` selectors and `credColors` in
`flob/flob.pas`: COLBK=0 and PF0/PF1/PF2 as set by `dlicredits`. It applies the
canonical PAL RGB mapping, STE quantization and Scale2x. Existing PNG edits are
preserved unless `--force` is requested; normal builds only convert the PNGs.
`ShowCredits` displays full-height images and fades to their own palettes, without
intro cropping, captions or palette rebuilding. The original rolling transition's
second DLI palette is not emulated: the STE presentation retains slide fades.
The eighth "In Stereo Where Available" slide is excluded from the image include
list and runtime sequence. `python3 verify_credits.py` tests all seven visible
framebuffers and hardware palettes in Hatari after fade-in.

Jan in W2 R17 uses hardware double-width PMG (`SIZEP2=1`) in the original.
`HARDWARE_DOUBLE_WIDTH_SPRITES` in `sprite_combined_config.py` makes the build
expand `sprite_jan_drop_p0` from canonical 16x46 to 32x46, including masks and
vertically flipped frames. The artist PNG is unchanged; the adjacent drop P1
remains normal width. Do not also widen this atlas row without removing the
build-time expansion. Runtime rendering, restore bounds and sprite contact bounds
use the generated width; there is no per-frame scaling.

W2 R07's blinking horizontal light (`sprite_light_electro_p0`) also has SIZEP2=1
and is expanded to 32x2 at build time. Its six opaque source bits cover 24 screen
pixels rather than 12. `path_light` moves the same sprite between two positions;
the P1 electrical discharge has SIZEP3=0 and remains normal width.

Flob-only foreground occlusion: the deferred stable-ID 20 Flob draw uses
`DrawOccludedFlob`. It intersects the preshifted EMS opacity masks with the
inverse of BKG indices 1/2 inside the playfield, then uses the existing EMS
blitter. Four-plane equality is `(plane0 xor plane1) and not (plane2 or plane3)`;
matching RGB values in other palette slots do not occlude. The scratch mask is
built only when Flob is redrawn, directly from current BKG, so tile changes and
flips need no separate cached mask. Other sprites are neither clipped nor erased
by this pass. Collisions are unchanged. Split explosion layers and particles
use different assets/IDs and retain their previous foreground behaviour.
Gameplay verification includes an independent per-pixel reference, both-page
overlap checks and 128 direct mask comparisons across frames/shifts/field edges.

W2 R22 palette repair: the original GIF has only three used indices and a
nonstandard grey palette. Sorting/requantizing these colours corrupted both
the visible room and collision meanings. `room_palette_config.py` records the
verified GIF-to-A8 selector mapping (0->3, 1->0, 2->1). This room's canonical PNG
now uses fixed STE indices and bypasses Netpbm palette reordering; its collision
PNG matches the cartridge bitmap. The original room colour bytes remain
96/EA/82/00 (not copied from R21). The importer reproduces the correction on an
explicit reimport. `repair_w2_r22.py` is the guarded one-time migration;
`python3 -m unittest test_room_palette` checks cartridge collisions, smoothing
geometry and all planar pixels including the 20-line top/bottom margins.

Space is also FIRE: gameplay reads its held state from the existing raw IKBD
handler and ORs it with joystick fire before edge detection. No BIOS polling
was added to gameplay. Menus accept space as start/confirm; it no longer aliases
legacy SELECT. `python3 verify_gameplay.py` runs target-side reference collision,
hazard bookkeeping, both-buffer dirty-render and shared-fire-state tests.

Score changes use `RefreshScore`: redraw only the five digits (40x8) in BKG,
then blit 48x8 to each display buffer, including the unchanged right 8px margin
for planar alignment. They no longer redraw the world/room labels or refresh
message areas. `ShowSlime` retains the full overlay refresh for room entry and
return from stats. `python3 verify_score.py` compares 12 score transitions
against full HUD rendering across all three buffers and checks message state.

The sprite dispatcher now selects EMS before preparing IMS boundary masks and
its mask pointer. Common span/skew/address calculations are unchanged. Validate
both paths with `verify_ems.py` and `verify_ims.py` after modifying dispatch.

`RestoreDirtyRects` sends its already clipped, 16px-aligned rectangles to
`asm/restore.s` in one cdecl call. The adapter initializes common blitter
registers once, then copies all four planes in one blit per rectangle from
SCREEN_BKG to SCREEN_LOG (160-byte stride). As of 2026-09-12, rectangle restore
uses HOG `$C0` starts and ordinary BUSY polling, including the optional prepared
path; it does not adopt AGT's BUSY restart loop. Other copy routines are unchanged.
Dirty-region merging, per-buffer tracking and the full-copy fallback are
unchanged. `TDirtyRect` is an eight-byte packed record (x/y/width/height words).
`NO_RESTORE_ASM` selects the previous Pascal copy path for comparisons.

`python3 verify_restore.py` compares complete framebuffers for 400 rectangle
lists, including empty lists, overlaps and screen edges. The isolated 32,000
small-rectangle benchmark measured 17,665 ms in Pascal versus 5,355 ms in ASM
(69.7% less time) on Hatari STE 8 MHz using emulated HZ200 ticks. This is not
a whole-game FPS measurement. Results are in `reports/restore_verification.txt`
and `reports/restore_benchmark.txt`.

### EMS For Flob And Slime

Flob and small slime now use an EndMask blitter adapter inspired by AGT EMS
(`agtools/agtsys/m68k/emsprt.inc`), without linking the AGT framework.
`asm/ems.s` draws four planes per scanline with LOP=source, using preshifted
opacity as EndMask1/3. Colour data is NOT preshifted. Other sprites and effects
retain the original eight-pass blitter. Collision masks and dirty restoration
are unchanged.

The eight-pass path now uses `asm/ims.s`, an IMS-style register driver adapted
to our separate mask/colour blocks (not an AGT IMS asset-format conversion).
It preserves four AND + four OR operations, HOG mode, skew/NFSR and current
whole-sprite bounds rejection; it does not add partial clipping. No asset or
collision format changed. `NO_IMS` selects the retained Pascal reference path.

`python3 verify_ims.py` builds an isolated test with EMS disabled and checks
every generated frame against the Pascal path using Hatari's blitter:
152 sprites, 1,636 frames, 32,720 comparisons, 27,812 actual ASM draws, all
16 horizontal shifts plus screen-edge rejection. No pixel differences.
Its timed all-frame workload (52,352 calls per renderer, no VSync/restore)
measured 46,770 ms Pascal versus 41,720 ms ASM: 10.8% less draw time at STE
8 MHz. This is not a claim of 10.8% higher game FPS. Logs and results are in
`reports/ims_verification.txt` and `reports/ims_benchmark.txt`.

The asset build emits all 16 mask shifts for both orientations, costing 34,304
extra mask bytes (+72 bytes of offset tables). This trades memory for time.
For these two sprite types, the otherwise unused `paletteOffset` field stores
the EMS mask word offset (`paletteCount` stays zero). This avoids a costly
32-bit frame-index division on the 68000. The same canonical PNG remains the
build source; do not edit generated EMS masks.

`python3 verify_ems.py` compares real Hatari blitter output against the legacy
renderer: 2,304 framebuffer comparisons, 1,304 actual EMS draws, all frames,
both orientations, all horizontal shifts, top/bottom/right-edge cases and
untouched pixels. See `reports/ems_verification.txt`.

`python3 run_slime_benchmark.py` now tests EMS; add `--legacy` to test the old
renderer. Three repetitions each measured W0 R06 moving Flob + animated slime
at 50 FPS / zero missed deadlines with EMS, versus 45.47 FPS / 51 two-VBL frames
out of 512 with legacy. These remain controlled renderer measurements, not a
claim of full gameplay FPS. Reports have `_ems` and `_legacy` suffixes.

`python3 audit_sprite_bounds.py` audits all 152 packed sprites, without changing
artwork. See `reports/sprite_bounds.md`: common animation crops save 2,040 bytes;
per-frame crops/empty-frame omission could save 35,640 bytes before offset metadata.
Per-frame cropping requires shared anchor handling in drawing AND collisions.

## Title Artwork

Kanonicznym zrodlem title screenu sa indeksowane PNG `320x184`:

```text
game_title/title.png
game_title/title_crown.png
game_title/manifest.json
```

Oba warianty powstaly przez jednorazowy Scale2x oryginalnego obrazu `160x92`.
Kolory uwzgledniaja PAL DLI: logo i dolne napisy maja osobne indeksy w jednej
palecie PNG (stan po 150 klatkach). Napisy to PRESS FIRE TO START,
A FOR ACHIEVEMENTS i C FOR CREDITS. W title A otwiera achievements,
C lub fizyczny klawisz HELP otwiera credits; FIRE/Return/spacja rozpoczyna gre.
Korona jest nakladana przed skalowaniem, a normalny build tylko centruje gotowe
PNG w ekranie `320x200`, dodajac po 8 czarnych linii u gory i na dole.
Konwerter zachowuje indeksy PNG, zapisuje palete z precyzja STE i pakuje
bitplany apultra. Fade-in title uzywa tej palety bez mapowania kolorow pokoju.

Po edycji PNG wystarczy `make`. Pierwszy import wykonuje:

```sh
make game-title-init
make
```

`create_game_title.py --force` odtwarza oba warianty z oryginalnych GFX i DLI i
nadpisuje prace grafika, dlatego nie jest czescia normalnego builda.

## Cutscene Artwork

Scenki pokojowe (`ShowScene`) maja osobny przebieg, bez animacji tekstu.
Audyt szesciu `world_??.asm`: jedna definicja SET_SCENE, W5 R10,
trigger 12 ONCE, obraz 23, tekst `msg_scene0` (adres A8 $AA97 w banku
assetow), kolory $28,$0D,$34. To scenka upadku Dr Sven Torffa.
STE rozpakowuje obraz do BKG, kopiuje 320x160 z y=20 na y=8 LOG,
rysuje cztery pelne wiersze ANTIC->ASCII na y=168/176/184/192,
potem robi swap i fade-in do palety scenki. Tekst ma jasnosc A8 $0A.
FIRE/Return zamyka ekran przez fade-out i BackToLevel, ktore odtwarza
pokoj, palete, sprite'y i orientacje. Wskaznik tekstu jest sprawdzany
dla pelnych 160 bajtow. Kod nie nadpisuje kolorow/collision data pokoju
przy prezentacji scenki. Dzialanie przejsc wymaga testu w Hatari.

Napisy cutscenek rozswietlaja sie liniami jak w A8 `dliintro2`:
indeks 15 przechodzi od koloru tla do bieli przez 15 klatek, potem linia
jest utrwalana indeksem 14 w obu buforach. Indeksy 14 i 15 sa zarezerwowane
dla tekstu cutscenek. Efekt dziala wewnatrz dotychczasowego czasu linii,
bez dodatkowych pauz zmieniajacych synchronizacje intro/outro z muzyka.
Stale: `CUTSCENE_TEXT_COLOR`, `CUTSCENE_FADE_COLOR`,
`CUTSCENE_TEXT_FADE_FRAMES` i `CUTSCENE_TEXT_WHITE` w `flob.pas`.

Kanonicznym zrodlem szesciu slajdow intro i trzech slajdow outro sa indeksowane
PNG `320x160`:

```text
game_cutscenes/intro_00.png
...
game_cutscenes/intro_05.png
game_cutscenes/outro_00.png
...
game_cutscenes/outro_02.png
game_cutscenes/manifest.json
```

Poczatkowy zestaw powstal przez jednorazowy Scale2x oryginalnych GIF-ow
`160x80`. Obrazy zachowuja indeksy palety `0..3`, a normalny build pakuje je
bez dalszego skalowania. `scene_00.gif` nie jest osobnym globalnym assetem:
ta sama grafika jest scena pokoju `world_05/room_23`, ktora juz korzysta z
kanonicznego, wygladzonego tla w `game_rooms`.

Po edycji PNG wystarczy `make`. Pierwszy import wykonuje:

```sh
make game-cutscenes-init
make
```

`create_game_cutscenes.py --force` odtwarza slajdy z oryginalnych GIF-ow i
nadpisuje prace grafika, dlatego nie jest czescia normalnego builda.

### Flob i PMG Overlap

Oryginalny Flob sklada sie z dwoch playerow PMG (`flobFrames0` + `flobFrames1`) nakladanych na siebie. W overlayu P0+P1 powstaje trzeci kolor, u nas bialy kolor oczu.

`export_flob_sheet.py` eksportuje Floba jako splaszczony sprite 4bpp:

- P0 = kolor bazowy,
- P1 = drugi kolor,
- P0+P1 = bialy overlap.

Mruganie oczu nie jest osobnym sprite'em. To ramka `FRAME_BLINK = 2`, wybierana losowo gdy Flob stoi.

### SPRITE_COMBINED i warstwy P0/P1

W `game_sprites.png/json` pozostale nazwy zakonczone `_p0` i `_p1` oznaczaja
niezalezne obiekty `SPRITE_DOUBLE`. Warstwy jednego obrazu zostaly juz
zastapione finalnymi rzedami `*_merged` albo `*_compound`.

Port zachowuje dla obu czesci osobne:

- `spriteFrame[0..1]` i liczby klatek,
- wysokosci, typy ruchu i animacje,
- pozycje, z dodatkowym przesunieciem drugiej czesci przez `sprites.gap`,
- maski kolizji i warunki widocznosci.

Dlatego `SPRITE_COMBINED` pozostaje elementem logiki gry. Bezpieczna optymalizacja polega na scalaniu offline tylko prawdziwych nakladek PMG: zgodna pozycja, rozmiar, przebieg animacji i zerowy gap. Obiekty z przesunieciem lub niezaleznymi klatkami sa obiektami zlozonymi i nadal wymagaja osobnych czesci albo specjalnie wygenerowanych kombinacji.

Faktyczne uzycia `SPRITE_COMBINED` sa generowane jako pojedyncze assety STE:

- `*_merged` dla nakladek kolorow z `gap=0`,
- `*_compound` dla `phone`, `gear`, `spiderjump` i `bat`, z zachowaniem szerokosci wynikajacej z `gap`.

Szerokie assety wymagaja warunkowego `NFSR`: flaga jest ustawiana tylko wtedy, gdy
skew powoduje, ze cel zajmuje o jedno slowo wiecej niz spakowane zrodlo. Bez tego
telefon 20 px tracil drugi word grafiki przy niezerowym `X mod 16`.

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

W trybie gry joystick, strzalki lewo/prawo, spacja-FIRE i klawisze pomocnicze ida przez raw IKBD,
bez BIOS/GEMDOS polling. Menu/title/cutscenes nadal korzystaja z klawiatury.
Przeciwne kierunki (takze strzalka kontra joystick) znosza sie. Ruch czyta
polaczony `stick0`, a `joyStatus` pozostaje surowym stanem joysticka.
Raw IKBD obsluguje takze pauze w grze: `P` lub Enter zatrzymuje petle, a `P`, Enter, Esc albo FIRE wznawia gre.

Efekt `Reveal` buduje dwa warianty docelowego pokoju w osobnych buforach i miga
miedzy nimi razem z odpowiadajacymi im paletami pokoju. Po zakonczeniu
`BackToLevel` ponownie laduje kolory biezacego pokoju i wspolna palete sprite'ow.

## Kolizje

Oryginal A8 uzywal:

- kolizji PMG z playfieldem/PMG,
- kolorow tla do kolizji podlogi/zagrozen,
- sprite hardware collision.

Port STE:

- podloga/zagrozenia sa sprawdzane przez `GetPix` z danych tla,
- `PUT_TILE` od razu aktualizuje bazowa mape kolizji pod dynamicznym kaflem,
- dynamiczne niebezpieczne piksele maja dodatkowa maske 1bpp i sa testowane
  przeciw rzeczywistej masce Floba, zamiast kosztownego skanowania calego ekranu,
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

Kolory pokoju pochodza z danych oryginalu i ida przez `STE_PAL`. Tablica jest
generowana do `palette.inc` przez `generate_palette.py` ze zweryfikowanej
referencji PAL `assets/a8_pal_rgb.hex`, a nastepnie kwantyzowana do natywnego
ukladu bitow skladowych Atari STE. Tablicy nie nalezy ponownie wpisywac recznie
w `flob.pas`.

`RebuildRoomPalette` sklada palete pokoju:

- wszystkie cztery sloty tla/kolizji z `level.colors` danego pokoju,
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

- stats screen ma szesc stron swiata i jedna strone globalna,
- world selector ma uklad A8 z osobnym wygladzonym fontem 16x16,
- finalny font i finalny wyglad UI sa jeszcze otwarte.

## Audio

Efekty zostaly wyciagniete z oryginalnego RMT/POKEY do dwoch kompaktowych
strumieni 50 Hz. `run, AUDF, AUDC` pozostaje dla zapasowego syntezatora DMA,
a domyslny PSG dostaje gotowe rekordy `run, periodLo, periodHi, noise, mixer,
volume`. Oba warianty generuje `generate_sfx_synth.py` do
`assets/sfx_synth.inc`.

Domyslny backend PSG:

- `asm/psgsound.s` instaluje callback w kolejce VBL TOS,
- uzywa jednego kanalu YM2149 i zachowuje jego poprzedni stan,
- zapisuje do PSG okres, noise, mixer i glosnosc przeliczone podczas buildu,
- nie zatrzymuje petli gry i nie wykonuje kosztownej syntezy probek co klatke.

Alternatywny backend DMA pozostaje do porownan. `asm/sfxsynth.s` renderuje
przebieg POKEY do buforow 8-bit signed mono, a DMA STE odtwarza je w tle.
Wariant PSG zostal wybrany jako domyslny, bo daje dobra responsywnosc i czytelne
efekty. Wszystkie obecnie podpiete SFX korzystaja z jednego kanalu.

Muzyka FYM jest podpieta dla title, wszystkich swiatow, intro, outro i ekranu
konca swiata. `retarget_music_loops.py` zachowuje zestrojone dane rejestrowe,
ale ustawia punkty petli zgodne z komendami `GOTO` w oryginalnych RMT:

- world 00 i 05: ramka 896 (17.92 s),
- world 02: ramka 448 (8.96 s),
- pozostale utwory zapetlone: ramka 0,
- intro pozostaje jednorazowym strumieniem bez petli.

Do zrobienia pozostaje koncowy balans i pelny test muzyki oraz efektow.

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

Zmiana palety/grafiki w `game_sprites.png`:

```sh
make sprite-atlas-assets-only
make clean
make
```

Regeneracja referencyjnego eksportu z oryginalnych zrodel:

```sh
make used-sprite-atlas
```

Ta komenda nie zmienia produkcyjnego `game_sprites.png`.

Regeneracja strumieni PSG/DMA SFX oraz ponowne ustawienie petli FYM:

```sh
make sfx-psg
make music-loops
```

Regeneracja kafli z kanonicznych `game_tiles`:

```sh
make worlds/world_tiles.inc
```

Jednorazowy import kafli z oryginalu:

```sh
make game-tiles-init
```

Jednorazowy import ikon selektora z oryginalu:

```sh
make game-world-icons-init
```

Jednorazowy import ikon podsumowania swiata z oryginalu:

```sh
make game-endworld-icons-init
```

Jednorazowy import slajdow intro/outro z oryginalu:

```sh
make game-cutscenes-init
```

Jednorazowy import title screenu z oryginalu:

```sh
make game-title-init
```

Zmiana grafiki pokoju w `game_rooms`:

```sh
make room-assets
make
```

Regeneracja ikon/achievements zwykle dzieje sie przez zaleznosci Makefile, ale mozna odpalac odpowiednie `generate_*.py` recznie.

## Uwaga Dla Przyszlego Mnie

Komunikaty przy STYPE_GOAL (np. fiolka W4 R11) maja w A8 osobne triggery
punktowe. Kolizja masek STE moze zebrac przedmiot przed wejsciem tego punktu
w trigger. ShowCollectedGoalMessage uruchamia przy zebraniu nadal aktywne
ONCE/SHOW_MSG obejmujace oryginalna kotwice przedmiotu. Nie przesuwa globalnie
triggerow i nie powtarza juz zuzytych komunikatow. Test verify_gameplay.py
obejmuje kontakt krawedziowy w obu orientacjach W4 R11.

W4: adresy wszystkich siedmiu kafli w `world_04_assets.bin` sa o $70 wyzsze
niz wyliczone z dostepnych zrodel ASM. Manifest korzysta z adresow binarnych;
woda w R11 to $A693, nie $A623. Bledne adresy powodowaly ciche pominiecie
rysowania oraz kolizji przez FindSteTile. Import W4 dopasowuje teraz oryginalne
bajty kafla do binarnego banku. `python3 test_w4_tile_addresses.py` sprawdza
wszystkie adresy, odwolanie PUT_TILE w pokoju oraz zabijajacy kolor wody.
Nie odtwarzac adresow wedlug rozmiaru sprajtow STE ani aktualnego ukladu ASM.

W3 R12 ma tylko trzy uzywane kolory GIF. Sortowanie palety przypisywalo
podlodze indeks kolizji 3 (zabijajacy), zamiast 2. Mapowanie w
`room_palette_config.py` jest potwierdzone obrazem z oryginalnego cartridge'a:
GIF 0/1/2 -> A8 3/1/0. Kanoniczny PNG oraz kolizje sa naprawione;
`test_room_palette.py` porownuje wszystkie piksele z CAR i wynik planar STE.
`repair_w2_r22.py` obsluguje teraz obie potwierdzone poprawki: W2 R22 i W3 R12.
Nie wolno wnioskowac o roli koloru z jasnosci ani liczby uzywanych barw.

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
