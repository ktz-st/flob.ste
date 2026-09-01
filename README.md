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
- joystick w trybie gry przez raw IKBD handler,
- klawiatura w menu / title / ekranach pomocniczych,
- podstawowe kolizje, teleporty, sprite keys, portals, slimes, enemies, exits,
- dynamiczna aktualizacja kolizji po `PUT_TILE`, w tym gaz, kable i zapory,
- wspolna paleta sprite atlasu dla pokojow gry,
- level colors mapowane z danych A8 przez `STE_PAL`,
- efekty SFX odtworzone z danych POKEY przez PSG lub syntezator DMA STE.

Najwazniejsze braki sa w `TODO.md`. Na dzis glowne otwarte obszary to muzyka,
dalsza optymalizacja pamieci atlasu oraz pelna weryfikacja wszystkich swiatow.

Aktualny build po migracji kanonicznych assetow oraz kompresji danych ma
`994124 B` (okolo 971 KiB). Wygladzony title screen, ladowanie skompresowanych
danych swiatow i dekompresja kolizji per pokoj zostaly potwierdzone w grze.

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

Po edycji PNG wystarczy `make`. Pierwszy import wykonuje:

```sh
make game-world-icons-init
make
```

`create_game_world_icons.py --force` odtwarza ikony z oryginalnych GIF-ow i
nadpisuje prace grafika, dlatego nie jest czescia normalnego builda.

## End-world Icons

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

## Title Artwork

Kanonicznym zrodlem title screenu sa indeksowane PNG `320x184`:

```text
game_title/title.png
game_title/title_crown.png
game_title/manifest.json
```

Oba warianty powstaly przez jednorazowy Scale2x oryginalnego obrazu `160x92`.
Korona jest nakladana przed skalowaniem, a normalny build tylko centruje gotowe
PNG w ekranie `320x200`, dodajac po 8 czarnych linii u gory i na dole.

Po edycji PNG wystarczy `make`. Pierwszy import wykonuje:

```sh
make game-title-init
make
```

`create_game_title.py --force` odtwarza oba warianty z oryginalnych GIF-ow i
nadpisuje prace grafika, dlatego nie jest czescia normalnego builda.

## Cutscene Artwork

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

W trybie gry klawiatura nie jest czytana do sterowania. Joystick idzie przez raw IKBD handler. Menu/title/cutscenes nadal korzystaja z klawiatury.
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

- stats screen ma szesc stron swiata i jedna strone globalna,
- layout world selector docelowo bedzie wiekszy/pelnoekranowy,
- finalny font i finalny wyglad UI sa jeszcze otwarte.

## Audio

Efekty zostaly wyciagniete z oryginalnego RMT/POKEY do kompaktowych rekordow
`run, AUDF, AUDC` odswiezanych z czestotliwoscia 50 Hz. `Sfx` i `FSfx` wybieraja
dane z `assets/sfx_synth.inc`.

Domyslny backend PSG:

- `asm/psgsound.s` instaluje callback w kolejce VBL TOS,
- uzywa jednego kanalu YM2149 i zachowuje jego poprzedni stan,
- mapuje czestotliwosc, distortion/noise oraz glosnosc POKEY na PSG,
- nie zatrzymuje petli gry i nie wykonuje kosztownej syntezy probek co klatke.

Alternatywny backend DMA pozostaje do porownan. `asm/sfxsynth.s` renderuje
przebieg POKEY do buforow 8-bit signed mono, a DMA STE odtwarza je w tle.
Wariant PSG zostal wybrany jako domyslny, bo daje dobra responsywnosc i czytelne
efekty. Wszystkie obecnie podpiete SFX korzystaja z jednego kanalu.

Do zrobienia pozostaje muzyka oraz koncowy balans i test wszystkich efektow.

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
