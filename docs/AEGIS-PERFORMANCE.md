# Wydajność kombinezonu 1.3.17 — 17 listopada 2026

Próba wykazała wyraźny koszt wielu pracujących ramion. Przy ośmiu włączonych naprawach średnia spadła z około **557/570 do 197/198 FPS** na klientach A/B, czyli o około **65%**. Serwer utrzymał średnio około **60 aktualizacji/s**. Występowały pojedyncze przycięcia do około **142 ms**, także bez pracy ramienia. Wynik nie potwierdza braku spadków ani braku przycięć.

Sprawdzono bieżące pliki **1.3.17**, identyczne bajtowo na serwerze i obu klientach. To pomiar różnicy między obciążeniami tej wersji. Nie porównywano poprzedniej wersji ani sceny bez kombinezonów, więc nie jest to pomiar regresji wersji lub całkowitego narzutu moda.

## Wyniki klientów

Faktyczne odstępy między wywołaniami renderowania, bez limitu FPS. Każda faza trwała 30 s; pierwsze 5 s odrzucono. Poniżej wybrane fazy z **22 zweryfikowanych scenariuszy na każdym z dwóch klientów**, łącznie **544 508 klatek**. W tabeli liczba oznacza włączone funkcje; poniżej opisano faktyczną aktywność.

| Scenariusz | FPS A / B | p95 czasu klatki A / B |
|---|---:|---:|
| 2 zasilane kombinezony, ramiona wyłączone | 564 / 578 | 5,63 / 6,16 ms |
| 2 naprawy — pierwszy przebieg | 475 / 481 | 6,19 / 6,88 ms |
| 2 obrony — pierwszy przebieg | 451 / 461 | 6,27 / 6,92 ms |
| 2 chwyty żywych osób | 535 / 540 | 5,74 / 6,30 ms |
| 2 widoczne aktywne sonary | 507 / 523 | 6,00 / 6,47 ms |
| 8 zasilanych kombinezonów, ramiona wyłączone | 557 / 570 | 5,69 / 6,14 ms |
| 8 włączonych napraw | 197 / 198 | 9,87 / 10,17 ms |
| 8 obron | 301 / 313 | 7,75 / 8,29 ms |
| 8 obron + 2 widoczne sonary | 283 / 289 | 8,17 / 8,73 ms |

Powtórzenie dwóch napraw dało **489/488 FPS**, a dwóch obron **427/439 FPS**. Obciążenia nie były idealnie stałe: ramię czeka na ustawienie końcówki, a cel i postać podlegają fizyce. Nie wyciągamy z tych dwóch powtórzeń wniosków o statystycznej pewności wyniku.

W fazie ośmiu napraw średnio **6,74 ramienia** jednocześnie miało serwerowy stan pracy; naprawiono łącznie **6121 jednostek stanu**. W obu próbach dwóch napraw średnie wynosiły odpowiednio **1,72 i 0,84**, a w pojedynczej naprawie tylko **0,14**. Pojedyncza naprawa z CSV nie reprezentuje ciągłej pracy przy maksymalnym obciążeniu.

Obrona ośmiu kombinezonów oddała **510 strzałów**; dodatkowa próba z dwoma sonarami **504**, po **63 z każdego z ośmiu emiterów**. Chwyt utrzymywał odpowiednio jedną i dwie osoby przez cały analizowany fragment. Oba sonary miały zasilanie, napięcie powyżej 0,5 i widok szerszy niż 100 px we wszystkich około 1500 próbkach każdej fazy. Liczniki strzałów i napraw obejmują pełne 30 s; średnie czasu i aktywności obejmują ostatnie 25 s. Stan `active` obrony nie jest licznikiem strzałów: obejmuje również przerwy między impulsami i oczekiwanie na asynchroniczny pocisk.

## Przycięcia i serwer

We wszystkich wybranych oknach odnotowano **35 klatek powyżej 33,3 ms**, w tym **16 powyżej 50 ms**. Najdłuższa: **142,26 ms** na A w fazie bez pracy ramienia. Podczas dwóch obron wystąpiły skoki **141,13 ms** na A oraz **135,92 ms** na B. Podczas ośmiu napraw maksima wyniosły **45,39/61,92 ms**. Nie ustalono przyczyny wszystkich pojedynczych skoków; sam fakt wystąpienia podczas danej fazy nie przypisuje ich konkretnej funkcji moda.

Średni czas jednej aktualizacji **kontrolera kombinezonów na serwerze** wyniósł:

| Scenariusz | Średnia | p95 | p99 |
|---|---:|---:|---:|
| 8 zasilanych, bez pracy ramion | 1,31 ms | 2,41 ms | 3,37 ms |
| 8 napraw | 4,23 ms | 14,61 ms | 18,31 ms |
| 8 obron | 4,72 ms | 14,12 ms | 19,97 ms |
| 8 obron + 2 sonary | 4,73 ms | 14,19 ms | 19,29 ms |

Średnie tempo symulacji w tych fazach wynosiło **59,99–60,03/s**. Pojedyncze wywołania kontrolera przekraczały jednak budżet 16,67 ms. To nie pomiar pełnego ticka serwera: część natywnych aktualizacji i asynchroniczne wystrzelenie pocisku wykonują się poza tym kontrolerem.

Klientowy czas `Draw` wzrósł przy wielu naprawach z około **1,00/0,96 do 3,03/2,93 ms**. Wskazuje to na koszt sceny renderowanej podczas wielu napraw, ale pomiar nie rozdziela iskier, świateł, ramienia i pozostałego renderowania. `Draw` i `Update` w CSV są czasem ściennym na wątku wywołania, obejmującym ewentualne oczekiwanie. Nie są profilerem GPU ani czasem samego Lua. `Update` zawiera również częste krótkie wywołania bez pełnego kroku symulacji.

## Warunki i ograniczenia

- **Dwa rzeczywiście połączone klienty GPU** i dedykowany serwer na jednym komputerze: i5-13600KF, RTX 4080, około 64 GiB RAM; 1280×800, okna, VSync wyłączony, brak limitu FPS, wyłączone usypianie nieaktywnego okna. FPS obliczono jako `1000 / średni odstęp między Draw`.
- Dodatkowych sześciu nosicieli to natywne postacie z wyłączoną nawigacją, sterowane przez produkcyjne `G.setMode`. Nie są sześcioma dodatkowymi klientami. W scenie były kombinezony i celowo odnawiane zasoby; naprawy, pociski, fizyka chwytu, światła i sieć nadal działały natywnie.
- Syntetyczna scena w otwartej wodzie, stała kamera, okresowe ograniczanie dryfu postaci, cele naprawy bez samoczynnego zużycia. Zestaw obejmuje ten mod i LuaCs, a nie pełną kampanię i pełną listę modów użytkownika. Nie odtworzono komputerów znajomych ani Internetu/Steam P2P. Wysokie FPS na tym GPU nie gwarantują podobnego wyniku na słabszym sprzęcie.
- Rejestrator ma narzut: odczyty znaczników plikowych, refleksja i okresowy zapis konsoli. Klienty, serwer, narzędzia i inne procesy współdzielą CPU/GPU. Nie wykonywano zrzutów GPU podczas analizowanych okien. Nie izolowano wpływu wszystkich zewnętrznych procesów.
- Rejestrator CPU/RAM obejmuje **840 s**, od `combat_1` do pierwszego zakończenia serii. Pomija późniejsze dodatkowe sprawdzenie sonarów. RSS klientów w tym zakresie wzrósł około **2032 → 2041 MiB** i **2137 → 2146 MiB**; szczyt serwera około **748 MiB**. Ten krótki pomiar nie rozstrzyga długotrwałych wycieków.
- Początkowe nieważne fazy odrzucono: cel chwytaka blokował linię ognia, daleki teleport miał historię interpolacji, a wyłączenie natywnego AI zmienia `IsBot` i wymaga jawnego wyboru funkcji nieruchomego nosiciela. Powtórzono te fazy z nowymi celami i poprawnym sterowaniem; analizator wybiera ostatni kompletny zapis i wymaga prawdziwych akcji. Dodatkowo potwierdzono działanie sonarów i wkład każdego emitera. Wszystkie testowe procesy zamknięto.

## Dane i odtworzenie

[Pełna tabela CSV](aegis-suit/performance/summary.csv), [pomiary A](aegis-suit/performance/client-A-metrics.jsonl), [pomiary B](aegis-suit/performance/client-B-metrics.jsonl), [serwer](aegis-suit/performance/server.txt), [wkład emiterów](aegis-suit/performance/per-wearer-validation.txt), [sonar A](aegis-suit/performance/client-A-sonar-validation.txt), [sonar B](aegis-suit/performance/client-B-sonar-validation.txt), [sprzęt](aegis-suit/performance/hardware.json), [CPU/RAM](aegis-suit/performance/process.jsonl), [SHA256 produkcji](aegis-suit/performance/production-sha256.txt).

Sonda natywna: [AegisPerfStartup.cs](../tests/runtime/AegisPerfStartup.cs). Scena: [serwer](../tests/runtime/aegis_performance_server.lua), [klient](../tests/runtime/aegis_performance_client.lua), [walidacja akcji](../tests/runtime/aegis_performance_validation.lua). Eksport: `python tools/analyze_aegis_performance.py`; CPU/RAM: [narzędzie](../tools/monitor_aegis_performance.py).

Do odtworzenia użyj odrębnych kopii gry, identycznych plików moda i nazw `PerfA`/`PerfB` (`-username`), a serwera wyłącznie na localhost. Zbuduj sondę jako bibliotekę i ustaw ją w `DOTNET_STARTUP_HOOKS` obu klientów. Włącz odpowiednie uprawnienia LuaCs na prywatnym serwerze, rozpocznij świeżą rundę i skopiuj skrypty do `LocalMods/System-Aegis/Lua/Tests`. Wczytaj sondę serwera komendą `lua dofile(...)`, klienta przez `cl_lua dofile(...)` na obu klientach; dołącz walidację przed rozpoczęciem faz. Scena rusza po gotowości obu klientów. Nie uruchamiaj tych skryptów na kampanii użytkownika. Analizator zakłada katalogi `.runtime/aegis-native` oraz `.runtime/vacuum-clients/A` i `B`.
