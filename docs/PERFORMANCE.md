# Optymalizacja i ponowna weryfikacja wszystkich przedmiotów

Stan na 20 listopada 2026. Zakończono porównanie osobnych scen wszystkich
ośmiu przedmiotów, krótką macierz funkcji z powtórkami i półgodzinną próbę
mieszaną. Sprawdzono też rundy, ponowne dołączenie i zapis kampanii. Bazą
jest 1.3.22 z commitu `1e14d6d`. Paczka 1.3.23 zawiera zmierzony kod.

## Pomiary przed i po zmianach

Każda pozycja w tabeli ma trzy zaliczone powtórzenia przed i po zmianach.
Faza trwa 30 s, z czego pierwsze 5 s to rozgrzewka. Tabela podaje mediany
średnich czasów ticka oraz FPS dla dwóch rzeczywistych klientów. Surowe
dane zawierają także p95/p99, CPU, pamięć, licznik pracy każdego nosiciela
i rozmiar wiadomości przed kompresją.

| Przedmiot i scenariusz | Tick serwera, ms | FPS A | FPS B |
|---|---:|---:|---:|
| Klucz–śrubokręt, 8 napraw | 3,61 → 3,70 | 712 → 796 | 684 → 644 |
| Kompozytowy multitool, 8 napraw | 3,74 → 4,02 | 680 → 755 | 644 → 615 |
| Bojowy multitool, 8 tarcz | 6,03 → 5,34 | 125 → 131 | 119 → 123 |
| Bojowy multitool, 8 strzelających [1] | 14,15 → 12,58 | 34 → 43 | 31 → 39 |
| Aegis Mk I, 8 leczących | 3,03 → 3,16 | 498 → 544 | 480 → 452 |
| Aegis Mk II, 8 leczących | 2,98 → 3,08 | 386 → 414 | 375 → 364 |
| Odkurzacz, 8 zbierających | 5,44 → 5,48 | 151 → 159 | 148 → 144 |
| Plecak, 2 otwarte panele po 1000 rzeczy | 2,72 → 2,91 | 733 → 815 | 702 → 672 |
| Plecak, 10 000 rzeczy po replikacji | 3,69 → 3,90 | 676 → 746 | 658 → 617 |
| Descendants, 8 bezczynnych | 4,36 → 4,70 | 414 → 436 | 399 → 359 |
| Descendants, 8 widocznych napraw | 7,75 → 7,93 | 153 → 343 | 151 → 301 |
| Descendants, 8 napraw poza ekranem [2] | 8,01 → 6,88 | 1570 → 1362 | 1130 → 1122 |
| Descendants, 8 strzelających [2] | 9,45 → 8,25 | 370 → 364 | 329 → 311 |

Wynik [1] pochodzi z wersji przed dodatkową optymalizacją rysowania
pierścieni. Zachowano wygląd 100 odcinków w teście porównawczym, tworząc
103 zamiast 200 wektorów. Świeża para z aktualnym kodem miała cięższą
bazę. W trzech powtórzeniach średni tick spadł z 27,33 do 14,70 ms,
p95 z 31,25 do 20,28 ms, a UPS wzrosło z 36,4 do 60,0. Klient A
uzyskał 6,3 → 49,8 FPS, klient B 6,4 → 65,7 FPS. Każdy nosiciel oddał
37–41 strzałów w bazie i 62–65 po zmianach. Porównanie obejmuje wspólny
efekt nowszej fizyki i rysowania. Wcześniejsza, lżejsza para z tabeli lepiej
pokazuje koszt przy podobnej liczbie strzałów.
[Porównanie głównej serii](../output/performance/20261119T234454Z-isolated-after-all-items/comparison.json) · [Świeża para ostrzału](../output/performance/20261120T161522Z-final-fire-retry/comparison.json).

Wyniki [2] pochodzą z dodatkowej pary świeżych sesji. Długie serie przed
i po miały nieaktywne stanowiska w scenie walki. Jedna próba poza ekranem
zawierała dodatkową diagnostykę. Te dane zachowano, a w tabeli użyto
kompletnych, poprawnych powtórzeń z nowej pary.
[Porównanie dodatkowej serii](../output/performance/20261120T002743Z-after-extra-suit/comparison.json).
[Zestawienie metryk, pracy i skrótów manifestów](performance-paired-2026-11-20.json).

Największy potwierdzony koszt klienta pochodzi z widocznego ostrzału
bojowych multitooli. Naprawa kombinezonami najbardziej zyskała na zmianie
rysowania iskier, choć czas całego ticka i jego p95 w głównej scenie naprawy
nie spadły. Po odjęciu pobliskiej pustej kontroli dodatkowy czas klatki
spadł z około 5,4 do 1,9 ms u obu klientów, a dodatkowy czas ticka pozostał
około 5,19 ms. Pusta kontrola ma jedno powtórzenie, więc służy do oszacowania
tła. W świeżej próbie walki kombinezonów koszt kontrolera spadł z
5,60 do 4,28 ms, a p95 ticka z 22,81 do 11,67 ms. W scenie ośmiu tarcz koszt
kontrolera spadł z 3,00 do 2,21 ms, przy podobnym p95 ticka.

Osiem aktywnych odkurzaczy nadal wywołuje skoki. Mediana p95 ticka wyniosła
20,61 ms po zmianach wobec budżetu 16,67 ms przy 60 UPS. Osiem strzelających
bojowych multitooli również przekracza ten budżet w części ticków. Różnice
w pustych kontrolach i przeciwne zmiany FPS klientów A i B ograniczają
interpretację małych zmian w scenach pozostałych przedmiotów. Zwykły multitool
ma dodatkowo koszt przywróconej pasywnej nauki. Próby funkcjonalne potwierdziły
po +2 do pięciu umiejętności dla każdego z 1, 2 i 8 nosicieli.

Rejestr procesu pozwala oszacować koszt przygotowania magazynu. Faza przed
pierwszym pomiarem 10 000 rzeczy trwała około 47 s w bazie i 49 s po
zmianach. Dwie następne fazy przygotowania trwały 88/119 s w bazie oraz
97/124 s po zmianach. Obejmowały tworzenie i replikację nowego magazynu,
sprzątanie poprzedniej próby oraz oczekiwanie na obu klientów. Szczyt
pamięci roboczej serwera wyniósł około 1380 MiB w ostatniej fazie
przygotowania. Próbkowanie co sekundę nie pozwala przypisać całego czasu
do samego przesłania lub pojedynczego dołączenia gracza.

Krótka macierz wszystkich funkcji obejmowała 122 fazy dla aktualnego kodu.
Pierwszy przebieg dał 342/366 poprawnych wyników. Sonda latarki odczytała
wskaźnik trybu zamiast reflektora, a sonda ścian liczyła tylko wybraną sekcję.
Po poprawieniu obu sond powtórki latarki, spawania i cięcia zaliczyły 24/24
wyniki z kontrolą. Walkę ośmiu kombinezonów zaliczono w osobnej świeżej
serii z tabeli. Każda scena macierzy uzyskała więc poprawny wynik w co
najmniej jednym przebiegu. [Pierwsza macierz](../output/performance/20261120T003224Z-current-all-functions/summary.csv) · [Powtórki narzędzi](../output/performance/20261120T155043Z-verify-tools/summary.csv).

## Naprawa w gęstej scenie

Do wspólnego świata dodano 300 uszkodzonych skrzynek elektrycznych poza
zasięgiem ramion. Sonda potwierdziła ich wpisy w indeksie napraw oraz
replikację do obu klientów. Wszystkie 21 wyników na każdą wersję zaliczono.

| Osiem napraw | Tick serwera, ms | p95 ticka, ms | UPS | Kontroler ramion, ms |
|---|---:|---:|---:|---:|
| Widoczne | 21,82 → 9,28 | 53,71 → 11,07 | 45,5 → 60,0 | 8,47 → 3,29 |
| Poza ekranem | 21,68 → 9,04 | 53,98 → 10,98 | 45,8 → 60,0 | 8,63 → 3,35 |

W każdej próbce przed zmianą wykonano 696–768 skanów. Po pierwszym
uzyskaniu celu w rozgrzewce nowy kod wykonał zero ponownych skanów w
tych próbkach. Ilość naprawy na nosiciela wzrosła wraz z UPS, z około
661–683 do 886–888 jednostek stanu na okno. Pusta kontrola całej sceny
również przyspieszyła z 12,03 do 5,38 ms. Dlatego wielkości zmiany
całego ticka i FPS nie przypisujemy bezpośrednio samej poprawce.
[Porównanie gęstej sceny](../output/performance/20261120T160424Z-after-final-dense/comparison.json).

## Pół godziny mieszanego obciążenia

Próbę zaliczono na serwerze i obu klientach. Każde z ośmiu stanowisk
wykonało pracę we wszystkich 60 kolejnych oknach, przez 1800 s po rozgrzewce.
Scena obejmowała naprawę i obronę kombinezonami, tarczę, ostrzał bojowym
multitoolem, leczenie Mk I, pochłanianie trafień Mk II, zbieranie łupu i
magazyn 1000 przedmiotów. Sonda uzupełniała zasilanie i usuwała zebrany
łup partiami, żeby stanowiska mogły pracować przez cały pomiar.

| Proces | Średni czas, ms | p95, ms | p99, ms | Najdłuższy, ms | Mediana RSS w pierwszych → ostatnich 5 min |
|---|---:|---:|---:|---:|---:|
| Tick serwera (59,6 UPS) | 6,48 | 8,79 | 25,28 | 475,69 | 719 → 951 MiB |
| Klatka klienta A (38,3 FPS) | 26,14 | 35,67 | 46,04 | 464,59 | 1861 → 2020 MiB |
| Klatka klienta B (39,3 FPS) | 25,43 | 35,11 | 44,93 | 345,69 | 1745 → 1919 MiB |

Wzrost pamięci procesu i skoki przekraczające budżet 16,67 ms pozostają
do wyjaśnienia. Pomiar obejmuje silnik, mod i sondę. Bufory pomiarowe
zachowują czasy klatek i ticków w trakcie fazy. Równolegle przez kilka
sekund działały lokalne testy automatyczne i pakowanie, co mogło wpłynąć na
pojedyncze skoki. Brakuje pary długich prób przed i po na identycznej scenie,
więc wzrostu pamięci nie można przypisać wprowadzonej zmianie ani ustalić
na tej podstawie wycieku. [Wyniki próby mieszanej](../output/performance/20261120T151837Z-final-mixed-soak/summary.csv).

## Zmiany rundy i ponowne dołączenie

W trzech rundach prywatnego serwera sprawdzono wyposażenie i wyczyszczenie
stanów czterech kontrolerów po zakończeniu rundy. Po usunięciu przedmiotów
nadrzędnych serwer usunął pięć znaczników trybów multitoola, stronę plecaka
i jej zawartość. Klient A faktycznie zakończył proces, uruchomił się ponownie
i wszedł do trwającej rundy. Serwer potwierdził tożsamość i stan 30 rzeczy,
a klient potwierdził odebranie pełnej zawartości.
[Dziennik rund i ponownego dołączenia](../output/performance/20261120T161826Z-lifecycle-native-join/lifecycle.txt) · [Potwierdzenie klienta](../output/performance/20261120T161826Z-lifecycle-native-join/A-rejoined.txt).

Kopię historycznej kampanii z 10 000 oznaczonych przedmiotów wczytano
na prywatnym serwerze z jednym klientem. W kopii przypisano zapisany
ekwipunek do klienta testowego. Zawartość z oryginalnymi stanami sprawdzono
po wczytaniu, a odzyskany plecak umieszczono w pustym slocie postaci do
testu zapisu wyposażenia. Zapis ekwipunku i kampanii zajął 4,88 s. Plik ekwipunku
zawierał 10 000 identyfikatorów i zmieniony stan oznaczonego przedmiotu.
Z odrębnej kopii tego zapisu silnik ponownie odtworzył wszystkie 10 000
przedmiotów z oczekiwanymi stanami.
[Dziennik zapisu i ponownego odczytu](../output/performance/20261120T163031Z-campaign-empty-slot/lifecycle.txt).

## Próba z dodatkowymi modami

Neurotrauma CS 2.0.7 (moduł zgłasza 2.0.5) i Enhanced Armaments 1.43
działały razem w krótkiej scenie. Zaliczono 21/21 wyników dla serwera i
dwóch klientów, z kontrolami. Osiem SMG oddało po 54 strzały w 9 s pomiaru.
Dwie tarcze bojowych multitooli były aktywne, a po dwie sztuki obu headsetów
wykonały leczenie. Zakres tej próby obejmuje te tryby i podane wersje.
[Wyniki próby z dodatkami](../output/performance/20261120T160911Z-optional-nt-ea/summary.csv) · [Wersje pakietów](../output/performance/20261120T160911Z-optional-nt-ea/server-packages.json).

## Zmiany w 1.3.23

- Ramię zachowuje aktualny, poprawny cel gracza bez ponownego przeglądania
  świata. Boty nadal sprawdzają zagrożenia podczas naprawy. Chwyt szuka
  nowego celu po żądaniu gracza.
- Pozycja tułowia jest współdzielona wyłącznie wewnątrz jednego wywołania
  kontrolera. Pozycje ramienia i obie strony zgięcia są ponownie używane
  tylko przy identycznych danych geometrycznych. Interpolacja rysowania
  i wygładzanie przegubów nadal pracują co klatkę.
- Kontrola widoczności strzału używa bieżącej pozycji lufy po ruchu ramienia.
  Asynchroniczny strzał nadal sprawdza świeżą geometrię i przeszkody.
- Przegląd wykrył i testy odtworzyły błędne liczenie zasięgu do środka
  szerokiej ściany zamiast trafionej krawędzi. Poprawiono je. Przypięta
  naprawa sprawdza dostęp i przeniesienie celu do ekwipunku co tick;
  opóźniony strzał sprawdza także zmianę drużyny i aktualność stanu rundy.
- Iskry naprawy obsługuje natywny menedżer cząstek. Zachowano emisję
  150/s; Lua nie przesuwa i nie rysuje już każdej iskry osobno.
  Efekty poza ekranem nie są emitowane.
- Testy promienia pomijają dalsze przeszkody po znalezieniu bliższego
  trafienia. Kilka tarcz w jednym kroku współdzieli odczyty pozycji kończyn;
  trafienie, pęknięcie tarczy i brak zasilania unieważniają te odczyty.
- Ponowny test ujawnił błąd pasywnej nauki zwykłego multitoola:
  indeks LuaCs zachowuje wielkość liter, a XML używa `Multi-toolSET`.
  Skrypt rozwiązuje teraz rzeczywistą nazwę przez natywny rejestr prefabów.
  Nagroda pozostaje równa +2 do pięciu umiejętności co 300 s.

Zachowano zasięgi, obrażenia, koszty energii, pojemność plecaka,
identyfikatory przedmiotów oraz schematy komunikatów produkcyjnych.

## Historyczne próby diagnostyczne bazy

Poniższe wyniki pochodzą z **niezmienionej 1.3.22**. To diagnostyka,
nie tabela ukończonej poprawy przed/po. Pokazane fazy zaliczyły liczniki
ówczesnej sondy; ich ograniczenia opisano poniżej. Czasy obejmują natywny tick
serwera, a FPS wynikają z odstępów między klatkami klienta A.

| Przedmiot | Scena | Próbka po rozgrzewce | Tick serwera, średnia | FPS klienta A | Obecny kod po zmianach |
|---|---|---|---:|---:|---|
| Klucz–śrubokręt | 8 napraw | 3 s, 1 powtórzenie [M] | 5,07 ms | 622 | do pomiaru |
| Zwykły multitool | 8 spawarek, pobór zasobu | 3 s, 1 powtórzenie [M] | 8,02 ms | 306 | do pomiaru |
| Bojowy multitool | 8 tarcz, bez ostrzału | 3 s, 1 powtórzenie [M] | 12,73 ms | 93 | do pomiaru |
| Aegis Mk I | 8 leczonych nosicieli | 7 s, 1 powtórzenie [R] | 2,86 ms | 517 | do pomiaru |
| Aegis Mk II | 8 nosicieli pod serią trafień | 3 s, 1 powtórzenie [M] | 3,87 ms | 356 | do pomiaru |
| Odkurzacz | 8 zbierających zestawów | 7 s, 1 powtórzenie [R] | 5,04 ms | 391 | do pomiaru |
| Plecak | 1 magazyn, 10 000 rzeczy | 7 s, 1 powtórzenie [R] | 4,65 ms | 752 | do pomiaru |
| Kombinezon | 8 widocznych napraw | 25 s × 3 [S] | 6,56 ms | 144 | do pomiaru |

Źródła lokalne, przechowywane poza kontrolą wersji:

- [M: macierz przedmiotów](../output/performance/20261118T213813Z-matrix-smoke-before2/manifest.json).
- [R: poprawione sceny leczenia, ciśnienia, odkurzaczy i pełnego magazynu](../output/performance/20261118T215851Z-matrix-repaired-smoke/manifest.json).
- [S: trzy powtórzenia kombinezonów](../output/performance/20261118T205645Z-baseline-suit/manifest.json).

[Skrót dowodów w repozytorium](performance-baseline-2026-11-18.json) zawiera
metryki obu klientów, CPU/RAM, liczniki pracy i SHA256 manifestów dla tych
ośmiu przypadków. Pełne surowe przebiegi pozostają w lokalnym `output/`.

Tabela łączy różne przebiegi i długości próbek. Nie służy do wyliczania
procentowej różnicy między przedmiotami ani do ekstrapolacji na cudzy serwer.
Cały tick zawiera również świat, fizykę, testowe postacie i sondy.
Wczesna sonda mogła doliczyć końcowe sprzątanie do ostatniego ticka lub
klatkę zaczętą podczas rozgrzewki. Wskaźnik spawania/cięcia opierał się
na poborze energii, a nie potwierdzonej zmianie ściany. Tych danych nie
używa się do końcowego porównania p95/p99 ani dowodzenia skuteczności naprawy.

Przy ośmiu tarczach sam kontroler bojowego multitoola zajmował około
5,84 ms na aktualizację. W pierwotnej próbie kombinezonu było to około
3,6 ms dla naprawy i 6 ms dla obrony. Te odczyty uzasadniają badanie
odczytów kończyn, pozycji ramienia i raycastów.

Wczesna wersja zmian dała około 307 zamiast 144 FPS przy ośmiu widocznych
naprawach, lecz przebiegi miały inne nasiona poziomu. Nie jest to dowód
poprawy czasu serwera ani końcowy wynik aktualnego kodu. W tym samym
porównaniu obrona miała gorszy czas klatki, co również wymaga powtórzenia.
[Wczesny przebieg po zmianach](../output/performance/20261118T212600Z-after-suit-stress/manifest.json).

## Wiarygodność testów

Testy używają prywatnego serwera i dwóch rzeczywistych klientów GPU.
Pozostałych sześciu nosicieli stanowią natywne postacie testowe z wyłączoną
nawigacją AI. Nie jest to próba ośmiu klientów sieciowych.
Sprzęt: i5-13600KF, RTX 4080, klient 1280×800, bez VSync i limitu klatek;
Barotrauma 1.13.5.0 / LuaCs `c6e8829`.

Aktualne sondy utrwalają nasiono `BMT-performance-20261118`, Dugonga,
liczbę obiektów i manifesty SHA256. Dla krótkich scen [M] pomiar służy
wykrywaniu kosztów, a nie ocenie powtarzalności. Poprawiony przebieg [R]
miał 1310 przedmiotów i 16 postaci przed dodaniem wyposażenia faz.

Aktywna faza bez pracy któregokolwiek nosiciela jest nieważna. Pełny
magazyn czeka na otrzymanie zawartości przez obu klientów; panel czeka
na rzeczywistą odpowiedź serwera. Przyspieszony rozruch pasywnej nauki
przesuwa wyłącznie licznik przygotowania poza pomiarem — normalne ticki
muszą przekroczyć niezmieniony próg i rzeczywiście przyznać umiejętności.

Wcześniejsze nieudane próby zachowano. Obejmują brak pełnej replikacji,
zużywanie leczenia na niedotlenienie, odkurzacze konkurujące o ten sam łup
oraz niegotowy panel. Nie zalicza się ich jako dobrych wyników wydajności.
Próby z 18 listopada od 23:17 CET nie uruchomiły klientów z powodu
`Failed to create graphics device` przed załadowaniem moda. To awaria
środowiska, nie pomiar FPS.

[Osobny przebieg samego serwera](../output/performance/20261118T222622Z-server-fixture-check2/manifest.json)
potwierdził pracę scen leczenia, bojowej pasywnej nauki i krótkiej sceny
mieszanej. Zwykły multitool nie przyznał nagrody; ten wynik pozostał
nieważny i doprowadził do poprawki wielkości liter. Ten przebieg nie ma
klientów, FPS ani rzeczywistego ruchu sieciowego i nie zastępuje multiplayera.

Liczniki sieci mierzą wywołania i bajty przekazywane do natywnego
`LidgrenServerPeer.Send`, przed kompresją i ramkowaniem transportu.
Nie są pomiarem bajtów na przewodzie. CPU podawane jest jako procent
jednego rdzenia; może przekroczyć 100%.

## Weryfikacja paczki i zakres pomiarów

20 listopada: **676 testów regresji PASS**, walidacja 18 XML i 61 modułów
Lua 5.2 oraz odwołań do natywnych receptur i zasobów PASS.
Przegląd kodu produkcyjnego doprowadził do poprawek z testami odtwarzającymi
błędy. Późniejsza zmiana rysowania pierścieni ma osobne porównanie
współrzędnych, kolorów i grubości wszystkich odcinków.

Paczka zawiera 130 plików. Sprawdzono CRC i zgodność każdego pliku z kodem.
Numer wersji w manifeście jest jedyną różnicą względem kodu z półgodzinnego
pomiaru. [Paczka 1.3.23](../output/MULTI-TOOL-V2-1.3.23.zip) · [Sumy kontrolne](../output/MULTI-TOOL-V2-1.3.23.manifest.json).

Uruchomiono pliki rozpakowane z ZIP-a na serwerze i dwóch klientach. W
próbie dwóch kombinezonów utworzono 56 pocisków pomocniczych. Po zakończeniu
fazy wszystkie zostały usunięte. [Dowód usunięcia pocisków](../output/performance/20261120T163403Z-release-1-3-23-smoke/pulse-lifetime.txt).

Zrzut rozgrzewki potwierdza widoczne niebieskie efekty podczas naprawy.
[Zrzut z klienta A](../output/performance/20261120T003224Z-current-all-functions/descendantservosuit_repair_8_r1-A.png).

Uruchamiacz zapisuje konfigurację każdej roli oraz kolejność, wersje i skróty
plików `filelist.xml` włączonych pakietów. W starszej bazie te informacje
zachowano w dodatkowych plikach obok pierwotnego manifestu.

Próba gaśnicy obecnie potwierdza natywne rozpylanie i pobór zasobu,
nie liczbę ugaszonych pożarów. Test magazynu mierzy stan po replikacji,
nie pełny koszt pierwszego przesłania 10 000 przedmiotów.
Internet, Steam P2P, sprzęt innych graczy i wszystkie możliwe wycieki
pamięci pozostają poza zakresem dowodów.

## Odtwarzanie

[Instrukcja narzędzi i formatów](../tools/performance/README.md).
Sondy są w `tests/runtime/performance/`, produkcja w `MULTI-TOOL-V2/`.
Nie uruchamiać pomiarów jednocześnie z normalną sesją gry.
Uruchamiacz odmawia startu przy wykrytych procesach gry; żadnego nie zamyka.
