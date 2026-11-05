# Płynność klatek — 1.3.7

2026-11-05. Barotrauma 1.13.5.0, LuaCs c6e8829. Bazowy kod: HEAD 0790c59
(poprawki 1.3.6). Pomiary modułów nie są pomiarami FPS całej gry.

## Zmiany

- Widoczność tarczy: pomijanie tarcz poza `Camera.WorldView`, buforowanie 41
  wyników sprawdzenia przeszkód przez maksymalnie 0,1 s. Ruch ponad 2 jednostki
  lub obrót ponad 0,01 rad unieważnia bufor od razu. Rysowana pozycja nadal
  podąża za wyświetlanym narzędziem. Kolizje i absorpcja trafień nie używają
  tego bufora i są sprawdzane na bieżąco.
- Odłożone narzędzia: konfiguracja komponentów raz na egzemplarz, zachowane
  referencje świateł i uproszczony kontekst przy braku użycia w obu dłoniach.
  Zmiana właściciela, wyłączenie światła i uzupełnianie zasilania przez boty
  nadal są obsługiwane. Korekta położenia światła pomija wyłączone lampy.
- Pasywne umiejętności: aktualizacja właścicieli narzędzi z indeksu, bez
  przeglądania wszystkich postaci. `item.equip` dodaje nowego użytkownika
  natychmiast, a okresowe odkrywanie obejmuje już istniejące wyposażenie.
  Warunki zasilania i przytomności są sprawdzane co klatkę; nagroda nadal
  wynosi +2 do pięciu umiejętności po 300 s rzeczywistego uprawnionego użycia.
- Skan odkurzacza: maksymalnie 256 klasyfikowanych przedmiotów na aktualizację,
  wspólnie dla aktywnych odkurzaczy. Ostatnia ukończona lista działa podczas
  budowania następnej. Kończenie zasysania i reset rundy odrzucają pracę w toku.
  Pierwsza lista dużego poziomu wymaga kilku klatek, więc początek zbierania
  po rozpoczęciu zasysania może być nieco późniejszy.
- Panel plecaka: 40 trwałych kafelków na otwarte okno, aktualizacja danych
  i podmiana sprite'ów zamiast usuwania całego drzewa GUI. Akcje używają
  aktualnego rekordu; ikony zachowują natywne kolory i skalowanie okna.

## Liczba operacji

`python tools/benchmark_frame_operations.py` porównuje produkcyjny kod HEAD
i kod roboczy przez istniejące testowe granice API Lua. To liczby operacji,
bez pomiaru GPU lub fizyki silnika:

| Operacja | Przed | Po |
|---|---:|---:|
| Sprawdzenia przeszkód nieruchomej tarczy / 120 klatek | 4920 | 779 |
| Nowe kontrolki GUI / 120 niezmienionych odpowiedzi, po otwarciu | 14 400 | 0 |

Dokładna liczba odnowień maski zależy od kroku zegara i ruchu. Tarcza poza
ekranem nie wykonuje sprawdzeń przeszkód dla renderowania.

## Rzeczywisty serwer

Prywatny serwer `.runtime/server`, aktywna runda Sandbox na Azimuth,
Neurotrauma CS. Dodano 32 narzędzia leżące na podłodze oraz 1500 sztuk żelaza.
Skrypt `tests/runtime/frame_time.lua` mierzy osobno każde ze 120 wywołań.
Łup został wyłączony na granicy wyboru celu tylko na czas pomiaru, aby nie
zmieniać wyposażenia okrętu. Kontekst właściciela i odczyty przedmiotów są
natywne.

| Moduł | Mediana przed → po | P95 przed → po | Maksimum przed → po |
|---|---:|---:|---:|
| 32 odłożone bojowe multitoole | 1,924 → 0,102 ms | 3,897 → 0,209 ms | 10,950 → 10,181 ms |
| Pasywne umiejętności | 0,006 → 0,001 ms | 0,029 → 0,001 ms | 0,639 → 0,006 ms |
| Aktywny odkurzacz | 0,003 → 1,134 ms | 0,865 → 7,081 ms | 68,389 → 8,117 ms |

Suma czasu odkurzacza w tej próbie: 273,94 → 278,90 ms. Porcjowanie rozkłada
pracę na wiele klatek; nie zmniejsza całej pracy skanu. Niski wcześniejszy P95
wynikał z małej liczby bardzo drogich wywołań. Pozostałe skoki, w tym GC
i inne mody, nie są wyeliminowane.

Surowe wyniki: `docs/vacuum/frame-time-before.txt`, `frame-time-after.txt`.

## Weryfikacja zachowania

- 382 testy automatyczne: PASS; bazowo 375, dodano 7 regresji czasu klatki.
- 13 XML i 39 produkcyjnych modułów Lua 5.2 oraz zasoby: zwalidowane.
- Natywny serwer: 5 prób pasywnych umiejętności PASS — 300 sekund, zmiana
  narzędzia, przerwa po schowaniu, mnożniki, puste paliwo, limit umiejętności
  i końcowy krok zwykłej pętli `think`.
- Natywny klient SP: konstrukcja obrazów, podmiana ikony i 120 odpowiedzi
  panelu bez przebudowy kontrolek PASS. GPU: cztery kąty × dwa kierunki tarczy,
  aktualna pozycja wyświetlanego narzędzia zamiast starej pozycji sieciowej PASS.
- Niezależny przegląd zmian: bez istotnych znalezionych defektów.

Kopie testowe mają osobne pliki konfiguracyjne i zapisy. Testy i narzędzia
pomiarowe nie trafiają do ZIP. Nie testowano długiej kampanii użytkownika ani
nie obiecuje się konkretnego wzrostu FPS całej gry.
