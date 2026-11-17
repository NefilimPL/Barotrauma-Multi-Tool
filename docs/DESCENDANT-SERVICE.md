# Kombinezon 1.3.18 — obsługa i próby, 17 listopada 2026

Poprawka obejmuje wyższy chwyt podczas biegu, luźne przedmioty przy szczypcach, przechodzenie niesionej osoby przez zwykłe schody i podesty, stabilniejsze obracanie ramienia oraz naprawę na drabinie i siedzeniu. Zasilany stojak odnawia zainstalowaną baterię lub pręt o 0,5% maksymalnego stanu/s. Nie odnawia amunicji. W stojaku używana jest osobna pionowa grafika; ikona i sprite na ziemi pozostają złożone.

Sonar po zwinięciu pokazuje tylko mały radar; wyłączony znika całkowicie. `+` rozwija ustawienia, a przycisk **Sonar** po prawej pozwala ponownie je otworzyć. **Minerały** włącza natywny skaner złóż w trybie aktywnym. W trybie pasywnym skanowanie jest wstrzymane. Aktywna funkcja ramienia ma osobny zielonkawy kolor. Obudowa wirnika pozostaje nieruchoma względem kombinezonu, obracają się wyłącznie łopatki. Pływanie emituje natywne bąbelki skutera, maksymalnie 24/s na kombinezon.

Po aktualizacji uruchom ponownie grę i serwer, zaktualizuj wszystkich klientów i utwórz nowy kombinezon. Protokół ramienia to **v5**. [Komendy i pełna instrukcja](DESCENDANT-SUIT.md).

## Wyniki funkcjonalne

Środowisko: izolowane kopie Barotrauma **1.13.5.0 / LuaCs c6e8829**, klient GPU oraz oddzielny serwer z rzeczywiście dołączonym klientem, Sandbox, Azimuth. Instalacja Steam i kampanie użytkownika pozostają niezależne od katalogów `.runtime`.

- **15/15 prób SP:** sloty, ukrycie wyłączonego sonaru, natywne zasilanie i skaner, radar 216 px przy 1280×800, kolor aktywnej funkcji, chwyt człowieka, bieg, puszczenie i przywrócenie ustawień, chwyt klucza, rzeczywiste połączenie przewodem ze stojakiem, ładowanie, zatrzymanie po rozłączeniu przewodu, naprawa na drabinie i siedzeniu. [Log](descendant-suit/service-native-client.txt).
- Podczas biegu noszący przebył **873 jednostki** w cztery sekundy; minimalna różnica wysokości wynosiła **44,98**, a zdrowie niesionej osoby pozostało **100**. Klucz ustalił się **0,016 jednostki** od końcówki. Bateria w stojaku wzrosła z **20 do 21** w dwie sekundy; napięcie wynosiło **0,9833**.
- **9/9 dodatkowych prób SP:** woda, naprawa przy natywnych obrotach i kontrolowanym małym przesunięciu ±3 jednostki, bąbelki oraz rzeczywista przeszkoda w postaci sojusznika. Cel naprawy zachował się w **288/301** próbkach, praca trwała w **281/301**, największy obrót kierunku narzędzia między próbkami wynosił **0,194 rad**, a animacja zwykłych rąk nie została wywołana. Zatrzymano bierne opadanie postaci, żeby nie mylić wyjścia poza zasięg z utratą kontaktu przy obrocie. [Log](descendant-suit/service-native-extra.txt).
- W tej próbie naliczono **48 żywych natywnych bąbelków**. Laser oddał **4 strzały** przy zasłonięciu promienia od tułowia i odsłoniętej końcówce; zdrowie sojusznika pozostało 100. Przeniesienie sojusznika przed samą końcówkę zatrzymało kolejne strzały.
- **2/2 prób fizyki:** ciało przeszło przez utworzone natywne `platform` i `stairsright`, a natywny handler kolizji zwrócił `false` dla ich rzeczywistych fixture podczas aktywnego chwytu. Zdrowie pozostało 100. [Log](descendant-suit/service-platforms.txt). Pełne ściany nadal ograniczają ruch.
- **10/10 etapów multiplayera:** fizyczny chwyt po puszczeniu klawiszy, natywny aktywny/pasywny sonar i minerały, mały radar, zwolnienie chwytu, pełna naprawa po przesunięciu postaci, impulsy, brak energii i spawanie ściany. Umiejętność elektryczna wzrosła **20 → 22**, natywne ukończenie wystąpiło raz; błąd miejsca emisji impulsu wyniósł maksymalnie **0,0078 jednostki**. [Serwer](descendant-suit/service-mp-server.txt), [klient](descendant-suit/service-mp-client.txt).

Próba serwerowa ujawniła dodatkowy przypadek: w niskim przejściu wszystkie punkty 45/65/85 jednostek wyżej kolidowały z sufitem. Planer sprawdza teraz także podniesienie o 25 jednostek, dopiero po odrzuceniu wyższych pozycji, z tymi samymi kontrolami prześwitu i drogi. Ostatnia pełna próba multiplayera obejmuje tę korektę; wcześniejsze logi SP dotyczą wyższych punktów. Regresja odtwarza sufit z prześwitem 81 jednostek i uniemożliwia powrót do punktu na podłodze, kiedy niższe podniesienie jest dostępne.

Usunięto także natywny błąd `Double → Single`: hook dostępu do urządzenia nie przypisuje liczby Lua do parametru `out float`. Ustawienia ręcznej interakcji są pomijane wyłącznie w zakresie konkretnej naprawy ramieniem. Niezależny przegląd wskazał przesunięcie grafiki w szafce z szybą; otrzymała osobny punkt zaczepienia.

Końcowa próba stojaka na serwerze i dołączonym kliencie potwierdziła wzrost baterii **20 → 22,25** przy napięciu **1** i replikację stanu. Klient wczytał poprawny punkt zaczepienia grafiki za szybą. [Zrzut z gry](descendant-suit/service-rack.png), [serwer](descendant-suit/service-dock-mp-server.txt), [klient](descendant-suit/service-dock-mp-client.txt). Pozostałe zrzuty: [mały sonar](descendant-suit/service-compact.png), [bąbelki](descendant-suit/service-bubbles.png), [praca w wodzie](descendant-suit/service-water-repair.png), [naprawa na drabinie](descendant-suit/service-ladder.png).

## Prędkość pływania

Ta sama postać, te same wejścia **prawo + bieg**, pusty korytarz w wodzie, brak obrażeń, 6 s rozpędzania i 4 s pomiaru, po 241 próbek. Natywna prędkość collidera i przemieszczenie dały zgodne wyniki. [Surowy pomiar](descendant-suit/service-swim.txt), [scenariusz](../tests/runtime/descendant_service_swim.lua).

| Kombinezon | Średnia prędkość |
|---|---:|
| Zwykły | 2,22566 m/s |
| Głębinowy | 1,81347 m/s |
| UKOS | 2,32619 m/s |
| Descendants, zasilany | **2,33609 m/s** |
| Descendants, bez energii | 2,22566 m/s |

W tej próbie przewaga wyniosła około **5,0% nad zwykłym**, **28,8% nad głębinowym** i **0,4% nad UKOS-em**. Wirnik dodaje siłę; nie ustawia stałej premii procentowej. Masa postaci, talenty, prąd i inne mody mogą zmienić wynik. Obecny napęd daje przewagę bardzo zbliżoną do UKOS-u.

## Zakres weryfikacji

Końcowy zestaw: **591 testów automatycznych**, **21/21 sprawdzeń modelu podglądu**, poprawna składnia JavaScript i walidacja **17 XML / 59 modułów Lua 5.2**, w tym odwołania do zasobów i receptur. Niezależny przegląd po poprawce stojaka i niskich punktów chwytu nie znalazł dalszych ważnych usterek.

## Krótki pomiar wydajności 1.3.18

Jeden rzeczywiście połączony klient 1280×800 i oddzielny lokalny serwer, jeden kombinezon i jedna przenoszona postać. Cztery fazy po 20 s; pierwsze 3 s pominięto. Klient odczytuje natywny `PerformanceCounter.CurrentFramesPerSecond` przy każdym renderowaniu. Serwer mierzy cały kontroler `G.update` zegarem `Stopwatch`. **VSync był włączony, limit w konfiguracji wynosił 60 FPS, a okno działało w tle**. Wyniki są krótkim sprawdzeniem tej sceny, nie odpowiednikiem wcześniejszego testu bez limitu ani testem wielu graczy.

| Faza | FPS klienta | p95 klatki | Najdłuższa klatka | Średni czas kontrolera serwera |
|---|---:|---:|---:|---:|
| Ramię wyłączone | 36,67 | 30,19 ms | 37,03 ms | 0,527 ms |
| Chwyt | 36,38 | 30,67 ms | 36,02 ms | 3,034 ms |
| Naprawa | 35,01 | 31,58 ms | **109,24 ms** | 1,916 ms |
| Chwyt + mały sonar | 35,89 | 31,72 ms | 51,68 ms | 3,180 ms |

Każda aktywna faza miała stan pracy w **1021/1021** analizowanych aktualizacjach serwera. p99 czasu kontrolera wyniosło odpowiednio **1,63 / 18,02 / 9,20 / 22,46 ms**, więc wystąpiły aktualizacje przekraczające budżet 16,67 ms. Nie stwierdzamy braku spadków FPS ani braku przycięć. Ten przebieg nie porównuje wersji 1.3.17 z 1.3.18. [Dane klienta](descendant-suit/service-perf-client.csv), [dane serwera](descendant-suit/service-perf-server.csv).

Automatyczne regresje i walidacja zawartości są uruchamiane poleceniami:

```text
python tools/run_tests.py
python tools/validate_content.py --game .runtime/server
```

Nie potwierdzono wszystkich modowych ragdolli ani każdego talentu osobno. Kontrola minerałów została sprawdzona na rzeczywistym natywnym komponencie i przez sieć; nie jest to zapis skanowania konkretnego złoża. Test lokalnego multiplayera nie obejmuje opóźnień internetowych ani wielogodzinnej kampanii. [Wcześniejszy pełny test wydajności dwóch klientów i ośmiu kombinezonów](DESCENDANT-PERFORMANCE.md) dotyczy wersji 1.3.17 i zachowuje osobne wyniki — w tym znaczny koszt wielu równoczesnych napraw.
