# SPRITE_COMBINED Classification Report

Raport obejmuje wszystkie faktyczne komendy `PUT_SPRITES`, ktore ustawiaja `sprites.state = SPRITE_COMBINED` w szesciu oryginalnych plikach `world_00.asm` ... `world_05.asm`.

## Podsumowanie

| Kategoria | Wystapienia w pokojach | Logiczne sprite'y | Rekomendacja |
| --- | ---: | ---: | --- |
| Nakladka kolorow | 26 | 9 | Scalac offline do jednej klatki 4bpp |
| Obiekt zlozony | 7 | 4 | Zaimplementowane jako jeden szerszy sprite `*_compound` |
| Razem | 33 | 13 | Nie zmieniac mechanicznie wszystkich par `_p0/_p1` |

Wniosek: tylko 13 logicznych sprite'ow wystepuje jako `SPRITE_COMBINED` i sa
one zapisane w `game_sprites.png` bezposrednio jako finalne `*_merged` lub
`*_compound`. Pozostale pary `_p0/_p1` sa uzywane przez inne tryby, przede
wszystkim `SPRITE_DOUBLE`, dlatego pozostaja osobnymi obiektami.

## Stan Implementacji

Etap `merged_overlay` jest zaimplementowany dla wszystkich 26 uzyc z `gap=0`:

- generator sklada P0 i P1 do jednego assetu `*_merged`,
- przy wspolnym pikselu zachowuje wynik obecnej kolejnosci blitow STE, czyli P1 nad P0,
- mapa adresow przypisuje scalony asset do slotu 0 i pozostawia slot 1 bez grafiki,
- `SPRITE_COMBINED` pozostaje bez zmian w logice gry,
- oryginalne wygenerowane pliki P0/P1 dla scalonych nakladek nie sa dolaczane do programu,
- obiekty z `gap > 0` korzystaja z jednego szerszego assetu `*_compound`, jednego blitu i pelnej szerokosci kolizji.

Po przebudowie rozmiar `flob.prg` spadl z okolo 1.300 MB do 1.264 MB. Przed uznaniem etapu za zakonczony potrzebny jest test wizualny pokojow wymienionych w tabeli nakladek.

## Kryteria

### Nakladka kolorow

Klasyfikacja wymaga:

- `gap = 0`,
- identycznych `x` i `y` obu playerow,
- identycznej liczby i wysokosci klatek,
- zgodnych `frameOn`, `frameOff`, `frameSpeed` i `moves`,
- zgodnych parametrow logiki i flipu.

Obie warstwy zajmuja wtedy te sama komorke PMG. Na STE wynik P0, P1 i P0+P1 mozna zapisac bezposrednio w jednym sprite'cie 4bpp i narysowac jednym blitem.

### Obiekt zlozony

`gap > 0` przesuwa P1 poziomo wzgledem P0. Nie jest to zwykla nakladka kolorow w tej samej komorce, nawet gdy animacja obu czesci jest zsynchronizowana.

Te przypadki sa renderowane jednym blitem przez wygenerowanie szerszej klatki zawierajacej obie czesci. Implementacja zachowuje:

- szerokosc wynikowa `8 + gap` pikseli A8, czyli `(8 + gap) * 2` pikseli STE,
- maske bedaca suma obu czesci,
- prawidlowa szerokosc kolizji,
- wspolny numer klatki i vertical flip calej kompozycji.

## Nakladki Kolorow

| Swiat | Sprite | Klatki P0/P1 | Wysokosc P0/P1 | Pokoje | Uzycia |
| --- | --- | ---: | ---: | --- | ---: |
| 00 | `sprite_map` | 1/1 | 8/8 | 5 | 1 |
| 00 | `sprite_flame` | 7/7 | 10/10 | 9 | 1 |
| 00 | `sprite_fireext` | 6/6 | 10/10 | 10 | 1 |
| 00 | `sprite_bigslime` | 8/8 | 6/6 | 23, 24 | 2 |
| 01 | `sprite_lever2` | 11/11 | 11/11 | 7 | 1 |
| 01 | `sprite_vial` | 8/8 | 10/10 | 8 | 1 |
| 01 | `sprite_bigslime` | 8/8 | 6/6 | 9, 20 | 2 |
| 02 | `sprite_vial` | 8/8 | 10/10 | 4 | 1 |
| 02 | `sprite_bigslime` | 8/8 | 6/6 | 9, 18 | 2 |
| 03 | `sprite_lever` | 7/7 | 12/12 | 0 | 1 |
| 03 | `sprite_drop` | 13/13 | 5/5 | 1, 6 | 2 |
| 03 | `sprite_button` | 7/7 | 8/8 | 9 | 1 |
| 03 | `sprite_vial` | 8/8 | 10/10 | 20 | 1 |
| 03 | `sprite_bigslime` | 8/8 | 6/6 | 17, 22 | 2 |
| 04 | `sprite_vial` | 8/8 | 10/10 | 11 | 1 |
| 04 | `sprite_bigslime` | 8/8 | 6/6 | 3, 12 | 2 |
| 05 | `sprite_drop` | 13/13 | 5/5 | 12, 13 | 2 |
| 05 | `sprite_bigslime` | 8/8 | 6/6 | 6, 22 | 2 |

Logiczne nazwy kandydatow: `sprite_map`, `sprite_flame`, `sprite_fireext`, `sprite_bigslime`, `sprite_lever2`, `sprite_vial`, `sprite_lever`, `sprite_drop`, `sprite_button`.

`sprite_bigslime` ma wspolne dane atlasowe dla swiatow. `sprite_vial` ma warianty per-world (`sprite_vial_w01` ...), dlatego generator powinien scalac kazdy wariant osobno.

## Obiekty Zlozone

| Swiat | Sprite | Gap A8 | Szerokosc STE | Klatki P0/P1 | Wysokosc | Pokoje | Uzycia |
| --- | --- | ---: | ---: | ---: | ---: | --- | ---: |
| 00 | `sprite_phone` | 2 | 20 px | 9/9 | 8/8 | 12 | 1 |
| 03 | `sprite_gear` | 8 | 32 px | 6/6 | 16/16 | 8 | 1 |
| 03 | `sprite_spiderjump` | 7 | 30 px | 2/2 | 9/9 | 10 | 1 |
| 03 | `sprite_bat` | 8 | 32 px | 4/4 | 6/6 | 14, 16 | 2 |
| 04 | `sprite_bat` | 8 | 32 px | 4/4 | 6/6 | 0, 1 | 2 |

Warianty `sprite_bat` z obu swiatow korzystaja z tego samego logicznego atlasowego sprite'a.

## Rekomendowana Migracja

1. Dodac do generatora tryb `merged_overlay` dla dziewieciu logicznych nakladek z `gap=0`.
2. Generowac jedna klatke i jedna maske STE z indeksami kolorow P0, P1 oraz overlapu P0+P1.
3. Mapowac oba sloty oryginalu na jeden atlasowy asset, ale na poczatku pozostawic `SPRITE_COMBINED` w logice gry.
4. W rendererze kolejkowac tylko scalony slot dla wpisow oznaczonych jako `merged_overlay`.
5. Zweryfikowac animacje, vertical flip i pikselowa kolizje w wymienionych pokojach.
6. `merged_compound` dla `phone`, `gear`, `spiderjump` i `bat` jest zaimplementowany wraz z szerszym rectem oraz maska kolizji.
7. Zweryfikowac wizualnie i kolizyjnie wszystkie 33 wystapienia podczas przechodzenia swiatow.

## Ryzyka i Testy

Telefon (`sprite_phone_compound`, 20x16 px) zostal zweryfikowany w grze razem z
animacja, kolizja i przeplywem `Reveal`. Renderer dobiera `NFSR` na podstawie
liczby slow zrodla i celu; bez tego szeroki sprite ustawiony pod niezerowym
`X mod 16` byl obcinany do pierwszego slowa.

- `Collided` mapuje kontakt dowolnej czesci `SPRITE_COMBINED` na `pnum = 0`; zachowanie musi pozostac takie samo po scaleniu.
- Obecny rect kolizji zaklada szerokosc jednego playera. Dla obiektow z `gap > 0` trzeba go poszerzyc przed przejsciem na pojedynczy asset.
- Klatki vertical-flip sa druga polowa atlasu i musza byc generowane juz z calej scalonej kompozycji.
- Widocznosc, goals i reveal nadal powinny korzystac z danych logicznych slotu 0.
- Po migracji nalezy sprawdzic wszystkie pokoje z tabel, szczegolnie poruszajace sie `bat` i `spiderjump` oraz interaktywne `phone`, `gear`, `fireext`, `lever` i `button`.

## Zakres Analizy

Raport powstal z oryginalnych `flob/worlds/*/world_*.asm` i dolaczanych plikow `sprite_*.a65`. Pliki `.bak` zostaly pominiete. Klasyfikacja dotyczy faktycznych uzyc `SPRITE_COMBINED`, a nie samej obecnosci par `_p0/_p1` w atlasie.
