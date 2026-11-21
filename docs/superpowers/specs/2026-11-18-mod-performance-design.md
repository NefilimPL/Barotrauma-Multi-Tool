# Wydajność całego moda i porządek w projekcie

Data: 2026-11-18. Status: zatwierdzony przez użytkownika („działaj”).

## Cel i wymagania użytkownika

Ponownie przetestować każdy przedmiot dodawany przez mod osobno, ustalić
źródła spadków FPS, przycięć i obciążenia serwera, następnie zoptymalizować
potwierdzone koszty. Szczególny priorytet mają wybór celu i ruch ramienia
kombinezonu przy zachowaniu jego elastyczności. Uporządkować pliki projektu.

Proponowana granica zmian: zachować obecny balans, zasięgi, tempo pracy,
obrażenia, zużycie zasobów, pojemność magazynu i obsługę przedmiotów.
Nie dodawać nowych funkcji rozgrywki. Nie obiecywać procentowej poprawy
przed pomiarem; zmiany mają wynikać z ustalonego kosztu.

## Stan wyjściowy sprawdzony lokalnie

- Baza: `1e14d6d`, pakiet `1.3.22`, Barotrauma `1.13.5.0`.
- `python tools/run_tests.py`: 613 testów, wszystkie przeszły.
- `python tools/validate_content.py --game .runtime/aegis-native`:
  poprawne 18 XML, 60 modułów Lua 5.2 i odwołania do zasobów/receptur.
- Są odrębne lokalne kopie serwera i klientów w ignorowanym `.runtime/`.
  Podczas rozpoznania nie działały procesy Barotrauma/DedicatedServer.
- Kopie są nieaktualne: serwer `aegis-native` ma wersję 1.3.21
  i 4 różne/brakujące pliki produkcyjne, klienci A/B mają 1.3.17
  i po 25 różnych/brakujących plików. Przed nowym pomiarem trzeba
  zsynchronizować wszystkie kopie i potwierdzić manifestami ich zgodność.
- Starszy raport dla 1.3.17 pokazał około 65% niższe FPS przy ośmiu
  włączonych naprawach. Nie jest nowym pomiarem 1.3.22 ani dowodem,
  że przyczyną są wyłącznie iskry, Lua lub GPU.
- Istnieją testy funkcjonalne i pomiary wybranych ścieżek, ale brakuje
  jednej porównywalnej macierzy wydajności wszystkich przedmiotów.

Testy regresji nie są pomiarem FPS ani pełnego czasu ticka serwera.

## Podejście i alternatywy

Rekomendowane jest porównanie tych samych scen przed i po małych zmianach,
z osobnym wynikiem dla każdego przedmiotu. Pozwala wskazać przyczynę,
wycofać nieskuteczną zmianę i zachować zachowanie rozgrywki.

Rozważone alternatywy:

1. Obniżenie częstotliwości wszystkich aktualizacji i liczby efektów.
   Krótsza implementacja, ale może pogorszyć reakcję, płynność i ochronę
   przed trafieniami, a poprawa FPS nie musi zmniejszyć kosztu serwera.
2. Pełna przebudowa modułów wokół wspólnego harmonogramu i indeksu świata.
   Większy potencjał współdzielenia pracy, lecz szerokie ryzyko regresji
   przed ustaleniem, które operacje naprawdę dominują.
3. Pomiary, następnie lokalne optymalizacje potwierdzonych kosztów.
   Więcej przygotowania, ale każda zmiana ma mierzalny cel. To propozycja
   wykonawcy zgodna z priorytetem ponownego testowania użytkownika.

## Inwentaryzacja i obowiązkowe próby

Osiem przedmiotów użytkowych należy raportować oddzielnie:

| Przedmiot / identyfikator | Scenariusze poza wspólną bezczynnością |
|---|---|
| Klucz-śrubokręt `aegiswrenchscrewdriver` | naprawa mechaniczna i elektryczna, użycie przez AI |
| Kompozytowy multitool `aegiscompositetool` | naprawa, spawanie, cięcie, gaśnica, światło, pasywna nauka, AI |
| Bojowy multitool `aegiscombattool` | powyższe funkcje narzędziowe, strzelanie, rykoszety, łuki, tarcza bez ostrzału i pod ostrzałem, AI |
| Komunikator `aegisheadset` | zdrowy nosiciel, leczenie wielu efektów, ciśnienie, odtwarzanie anatomii w próbie z NT, szukanie baterii przez AI |
| Komunikator Mk II `aegisheadsetmk2` | oddzielne powtórzenie prób Mk I oraz pochłanianie serii trafień |
| Odkurzacz `aegisvacuum` | bez plecaka, bez zasilania, zasysanie przy małej i dużej liczbie łupów, filtry, wiele odkurzaczy |
| Plecak `aegisvacuumpack` | bez odkurzacza, magazyn 0/1000/10000 sztuk, panel zamknięty/otwarty, szukanie, pobieranie, rozbiórka, fabrykacja, sprzedaż |
| Kombinezon `aegisservosuit` | ramię wyłączone, naprawa urządzenia, spawanie ścian, obrona z prostą i trudną linią ognia, chwyt przedmiotu i osoby, ruch nosiciela, pływanie, sonar, AI |

Siedem ukrytych przedmiotów też ma być objęte testami, w kontekście ich
funkcji: `aegistoolwelder`, `aegistoolcutter`, `aegistooldamageflag`, `aegistoolfireon`, `aegistoolfireoff`
(multitool), `aegisvacuumpage` (magazyn), `aegispulsebolt` (obrona).
Oddzielnie policzyć ich liczbę, czas życia, tworzenie/usuwanie i pozostające
referencje po zmianie trybu, końcu rundy oraz rozłączeniu.

Każdy użytkowy przedmiot: brak egzemplarzy, leżenie/schowanie, wyposażenie
bez pracy oraz aktywna funkcja; skala 1, 2 i 8 egzemplarzy, gdy funkcja na
to pozwala. Dla narzędzi porównać odpowiedni natywny przedmiot w tej samej
scenie. Nie używać natywnego odpowiednika jako zamiennika próby moda.

Koszty zależności rozdzielić: sam plecak, sam nieaktywny odkurzacz oraz
komplet podczas zbierania. Dla pełnego plecaka porównać także taki sam
zestaw fizycznych przedmiotów w natywnych kontenerach. Ukryte strony i
natywna aktualizacja zawartości również należą do kosztu plecaka.

## Metoda pomiarów

### Środowisko i izolacja

- Użyć wyłącznie prywatnych kopii w `.runtime/`, zapisu testowego i portów
  lokalnych. Nie zmieniać instalacji Steam, kampanii ani konfiguracji gracza.
- Zapisać wersję gry i LuaCs, listę modów, SHA kodu, SHA256 paczki,
  sprzęt, rozdzielczość, ustawienia grafiki i warunki procesów.
- Podstawowa seria: Vanilla + LuaCs. Porównać mod wyłączony i włączony
  bez jego przedmiotów, aby zobaczyć koszt globalnych hooków.
- Dwa rzeczywiste klienty GPU i dedykowany serwer; dodatkowi nosiciele
  mogą być botami. Nie nazywać tego próbą ośmiu klientów.
- Po izolacji wykonać serię współdziałania z Neurotraumą i dostępnymi
  modami broni oraz scenę mieszaną. Zachować odrębne wyniki; lokalna
  kopia zestawu modów nie dowodzi odtworzenia pełnego serwera użytkownika.
- Nie uruchamiać benchmarków równolegle z innymi benchmarkami. Przed
  startem sprawdzić obciążenie; przerwać lub oznaczyć zakłócony przebieg.

### Przebiegi

- Wstępnie 30 s na fazę, pierwsze 5 s jako rozgrzewka, co najmniej trzy
  ważne powtórzenia. Naprzemiennie przeplatać aktywną fazę z bazą.
- Powtórzyć porównanie na tej samej scenie, zasobach, nasieniu losowości
  tam, gdzie jest kontrolowane, i tych samych warunkach kamery.
- Osobno rzadki i gęsty poziom: liczba urządzeń/ścian, postaci,
  luźnych przedmiotów, kontenerów i ich zawartości ma być zapisana.
- Dla plecaka najpierw skala 1 przy 10000 sztuk; dalsze skalowanie
  pełnych magazynów dopiero po ocenie RAM i czasu fazy. Pominięte
  przypadki oznaczać jako niewykonane, nie jako zaliczone.
- Zmiana poziomu, zapis/odczyt, rozłączenie i ponowne dołączenie jako
  osobne próby skoków obciążenia i zachowania danych.
- Po optymalizacji co najmniej 30 minut próby mieszanej oraz kontrola
  powtarzanych zmian rundy. Taki test może wykryć narastanie pamięci,
  ale sam nie dowodzi braku wszystkich wycieków.

### Metryki i sprawdzenie, czy test naprawdę pracował

- Klient: odstępy między klatkami, FPS, czasy Update/Draw, p50/p95/p99,
  maksimum, liczba klatek >33,3 i >50 ms, CPU i RAM procesu.
- Serwer: pełny natywny tick i UPS, p95/p99/maksimum, osobno kontrolery
  Lua i wybrane funkcje, CPU/RAM oraz przyrost pamięci po cyklach.
- Sieć: liczba i rozmiar komunikatów moda oraz ruch procesu tam, gdzie
  można go wiarygodnie odczytać; nie utożsamiać payloadu Lua z całym
  ruchem transportu. Osobno bezczynność, praca i duża liczba nosicieli.
- Liczniki przyczynowe: odwiedzone obiekty, testy widoczności, próby
  pozycji ramienia, wywołania solvera, aktywne iskry i światła,
  przebudowy GUI/magazynu, komunikaty i liczniki stworzonych obiektów.
- Każda faza wymaga dowodu działania: faktycznie naprawiony stan,
  strzały/trafienia/blokady, leczone efekty, utrzymany chwyt,
  przeniesione przedmioty i pracujące sonary. Włączyć kontrolę osobno
  dla każdego nosiciela. Brak pracy unieważnia fazę zamiast poprawiać FPS.
- Sondy mają działać również dla wolnego serwera. Analizator nie może
  odrzucać wyniku wyłącznie dlatego, że UPS spadło poniżej 55.
- Oddzielić koszt rejestratora od produkcji i zmierzyć jego narzut.
  Nie pisać logów ani pobierać pełnego stanu przez refleksję co klatkę.
  Dotychczasowy analizator zapisujący raport 1.3.17 pozostawić jako
  historyczny; nowy nie może nadpisywać starszych surowych wyników.

## Kierunki optymalizacji do potwierdzenia pomiarem

### Cel i ruch ramienia

1. Sprawdzić koszt `G.gather`: obecnie skany urządzeń, ścian i postaci
   są wykonywane oddzielnie dla nosicieli; tryb chwytaka bez celu
   przegląda światowe przedmioty także przed faktycznym naciśnięciem chwytu.
2. Tanie odrzucanie po odległości przed dostępem do komponentów,
   sprawdzaniem relacji drużyn i raycastami. Kandydatów indeksować lub
   współdzielić tylko tam, gdzie pomiar uzasadnia dodatkową strukturę.
   Uwzględnić tworzenie/usuwanie, ekwipunki i ruch łodzi/pomieszczeń.
3. Rozłożyć skany w czasie i nadać im budżet. Aktualny cel sprawdzać
   tanio na bieżąco; nowego szukać okresowo lub po unieważnieniu celu.
   Nie dopuścić do zagłodzenia kolejnych nosicieli albo odległych wpisów.
4. Przechowywać wynik obliczenia podstawy, pozycji i kątów w ramach
   jednego kroku symulacji. Unieważniać go po ruchu, obrocie, zmianie
   celu, trybu, geometrii lub przegubów. Ograniczyć tworzenie tabel
   i ponowne obliczanie tej samej pozycji bez zmiany geometrii.
5. Zachować interpolację przegubów na kliencie, obie strony zgięcia,
   podnoszenie lufy i stabilność celu. Tańsza praca planisty nie może
   oznaczać aktualizacji widocznego ramienia raz na kilka klatek.
6. Zachować aktualną kontrolę bezpieczeństwa w chwili strzału, także
   po asynchronicznym utworzeniu pocisku. Nie strzelać na podstawie
   starego cache przez ścianę lub sojusznika.
7. Przypadki regresji: ruch i obrót nosiciela/celu, niski sufit,
   sojusznik na drodze, drzwi otwarte/zamknięte, przeszkoda pojawiająca
   się w ostatniej chwili, zmiana trybu, brak energii i zdjęcie stroju.
   Zachować wyłączenie automatycznego chwytania osób przez boty z 1.3.22.

### Klient i ogólna praca serwera

- Zmierzyć przegląd wszystkich stanów kombinezonów przy każdym
  `Character.Draw`; rozważyć bezpośrednie przypisanie nosiciel → stan.
- Zmierzyć aktualizację i tworzenie iskier poza ekranem; ograniczenie
  pracy niewidocznych efektów nie zmienia działania serwerowej naprawy.
  Pozostawić czytelny widoczny efekt i końcowe wygaszanie.
- Dla każdego modułu zbadać globalne hooki bez jego przedmiotów,
  powtarzane skany, dostęp Lua/C#, alokacje, utrzymywanie stanów,
  baterie AI i czyszczenie po rundzie. Współdzielić pracę tylko przy
  zgodnych wymaganiach dostępu, własności i aktualności danych.
- Dla plecaka zweryfikować niezmienione snapshoty, otwarty panel,
  fabrykatory, sprzedawcę, rozbiórkę oraz obecny cache magazynu.
  Zachować atomowość operacji, rezerwacje i rzeczywistą zawartość.
- Optymalizować snapshoty dopiero po pomiarze. Jeżeli potrzebne są
  komunikaty zmian, zachować pełną synchronizację po dołączeniu,
  usuwanie stanów i zgodny heartbeat; obecny klient wygasza stan po
  0,6 s. Nie zmniejszać nadawania bez dostosowania tego zachowania.

## Porządek w plikach

- Paczka `System-Aegis/` nadal zawiera wyłącznie zasoby produkcyjne.
  Zachować identyfikatory przedmiotów, ścieżki zasobów i punktów Autorun,
  aby nie uszkodzić zapisów, Workshop ani skryptów ładowania.
- Dodać jasny indeks dokumentacji, pomiarów oraz sposobów uruchamiania
  testów; aktualny raport odsyła do surowych danych konkretnego przebiegu.
- Nowe testy i narzędzia pogrupować pod wydajność, wspólne sondy i
  scenariusze przedmiotów. Starsze przenosić tylko po sprawdzeniu
  importów, instrukcji, twardo zapisanych ścieżek i testów.
- Duże surowe dane, zrzuty i paczki nowych przebiegów trzymać w osobnych
  ignorowanych katalogach `output/performance/<run-id>/`; do repozytorium
  trafiają krótkie podsumowania, manifesty i potrzebne dowody. Nie usuwać
  ani nadpisywać starych wyników i zasobów użytkownika.
- README prowadzi do aktualnej instrukcji, raportu i wydania. Historyczne
  wpisy można przenieść do changeloga z zachowaniem działających odsyłaczy.
- Nie usuwać zasobu tylko dlatego, że nie jest wymieniony w XML:
  sprawdzić również odwołania Lua, skrypty generujące i dokumentację.

## Kolejność i warunki uznania wyniku

1. Zbudować wspólną macierz i rejestrator; potwierdzić działanie scen.
2. Wykonać świeżą bazę każdego przedmiotu na niezmienionym kodzie.
3. Ustalić ranking kosztów klienta i serwera oraz ich przyczyny.
4. Wprowadzać małe zmiany od największego potwierdzonego kosztu;
   dla ramienia osobno mierzyć wybór celu, planowanie i ruch.
5. Powtórzyć właściwe sceny, testy zachowania i próbę mieszaną.
6. Uporządkować pliki w oddzielnym kroku, sprawdzić odsyłacze i paczkę.
7. Dostarczyć tabelę przed/po dla wszystkich ośmiu przedmiotów,
   ograniczenia testów oraz paczkę zgodną na serwerze i klientach.

Zmianę uznać za poprawę dopiero, gdy różnica przekracza zmienność
powtórzeń, nie rosną niewyjaśnione p95/p99 i zachowane są liczniki pracy
oraz funkcje przedmiotu. Celem serwera jest ograniczanie przekroczeń
16,67 ms przy 60 UPS; przeciążony scenariusz jest ważnym wynikiem.
Brak mierzalnego zysku oznacza brak podstaw do zachowania komplikacji.

Wykonawca dobiera wielkości indeksów i budżetów po pomiarze; nie jest
to zgoda na zmianę balansu albo usunięcie funkcji. Nieosiągalne próby
oznaczyć jako niewykonane z konkretną przyczyną. Zakres Internetu,
Steam P2P i sprzętu innych graczy opisać zgodnie z faktycznym testem.

## Zatwierdzenie

Zakres zatwierdzono przed tworzeniem nowych sond i zmianami
produkcyjnymi. W momencie zatwierdzenia wykonano rozpoznanie, testy regresji oraz
walidację zawartości; nie wykonano nowej macierzy FPS/serwera i nie
wprowadzono optymalizacji.

Niezależna kontrola projektu nie zgłosiła istotnych pytań blokujących
przygotowanie planu implementacji.
