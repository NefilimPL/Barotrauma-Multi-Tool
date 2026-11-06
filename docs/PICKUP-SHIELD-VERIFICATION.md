# Zbieranie, kategorie i tarcza — 1.3.8

Data: 2026-11-05. Barotrauma 1.13.5.0, LuaCs/Luatrauma c6e8829.
Próby natywne wykonano w osobnym kliencie SP, w prywatnej piaskownicy Azimuth.

## Przyczyny i zachowanie

- **Kategorie pod ikonami:** natywny GUIDropDown dodawał listę na warstwę 1,
  a panel z kafelkami na 10. Otwarta lista jest teraz dodawana na warstwę 11.
  Zamknięcie panelu zwalnia także fokus klawiatury.
- **Opóźniony łup na ziemi:** limit 180 kandydatów obejmował odległe rzeczy
  z całego poziomu. Jeden skan świata nadal działa w porcjach po 256,
  tylko podczas zasysania, ale przygotowuje osobne pobliskie listy dla każdego
  odkurzacza. Margines obejmuje odległość 700 przy zasięgu zasysania 350,
  aby obrót i zwykłe chodzenie nie wymagały od razu nowego skanu.
- **Worek z wykluczonym przedmiotem:** wybierany jest największy bezpieczny
  pojemnik akceptowany przez filtr. Gdy całość odpada, dozwolone rzeczy mogą
  zostać pobrane osobno; worek i wykluczona zawartość pozostają na miejscu.
  Sprawdzenie wszystkich nadrzędnych blokad, dostępu i właścicieli nadal
  poprzedza wybór. Całkowicie dozwolona skrzynka zachowuje zawartość.
- **Podłączony przewód:** LuaCs przekazuje Connection[] jako rzadką tablicę
  Lua od indeksu 1. Sprawdzanie indeksów 0 i 1 mogło przeoczyć samotny drugi
  koniec. Kontrola obejmuje teraz wszystkie obecne połączenia oraz węzły.
- **Pocisk po obrocie/ruchu:** aktywna tarcza mogła zachować geometrię
  z poprzedniej aktualizacji think. Przechwytywanie odczytuje teraz bieżącą
  pozycję i obrót fizyczny broni. Warunki energii, blokady po rozbiciu,
  wcześniejszych przeszkód i friendly fire pozostają sprawdzane.

## Dowody

- **389 testów automatycznych — OK.** Siedem nowych regresji najpierw
  odtworzyło błąd: warstwa/fokus kategorii, rzadki drugi koniec przewodu,
  worek z filtrem i blokadami, opóźnienie przez odległe rzeczy, dwa aktywne
  odkurzacze oraz aktualny obrót i położenie tarczy.
- **5 natywnych prób odkurzacza — PASS:** oba końce prawdziwego przewodu;
  worek z żelazem i miedzią; produkcyjna pętla zasysania zbierająca klucz
  z ziemi i dozwoloną zawartość worka; wskazanie listy kategorii przez natywne
  GUI.UpdateMouseOn i wybór kategorii; zwolnienie fokusu po zamknięciu.
  Test myszy zmienia tylko stan wejścia odizolowanego klienta i go przywraca,
  bez przesuwania systemowego kursora. Pętla zasysania ogranicza wybór do
  własnych obiektów testowych, korzystając z prawdziwej listy świata i kolizji.
  [Surowe wyniki](vacuum/pickup-fixes-native-results.txt).
- **6 natywnych prób tarczy — PASS:** rzeczywiste pociski rewolweru, SMG,
  karabinu i strzelby, następnie strzały przy celowo nieaktualnym obrocie
  i środku tarczy. Bezpośrednie Projectile.Shoot przechodzi przez produkcyjne
  hooki; przed strzałem nie wywołuje się pomocniczego G.findShield.
  Na starej wersji dwie ostatnie próby zadawały po 14,4 obrażeń bez obciążenia
  baterii; po poprawce wszystkie sześć pobiera energię, a zmiana zdrowia
  od strzału wynosi 0.
  [Przed](vacuum/pickup-shield-firearms-before.txt) ·
  [Po](vacuum/pickup-shield-firearms-results.txt).
- Niezależny przegląd wskazał opóźnienie wspólnej listy przy dwóch
  odkurzaczach. Dodano regresję RED→GREEN i osobne listy; pełny zestaw
  ponownie przeszedł. Poprawiono również próbę natywną tarczy, usuwając
  podgląd, który wcześniej odświeżał geometrię przed samym strzałem.
- Walidacja: **13 XML, 39 modułów Lua 5.2**, grafiki i receptury zgodne
  z lokalną grą. `git diff --check` — OK.

## Zakres i ograniczenia

Próby tarczy używają domyślnej amunicji hitscan tych czterech broni.
Dotychczasowe testy automatyczne obejmują również tor fizycznego pocisku,
przeszkody i friendly fire. Nie jest to sprawdzenie wszystkich pocisków modów,
opóźnień WAN ani pełnej kampanii. Odczyt aktualnej geometrii usuwa odtworzony
błąd położenia; nie rozszerza łuku tarczy ani nie zapewnia ochrony przy
rozładowanej baterii. Pierwsza lista łupu nadal wymaga przejścia przez świat
w ograniczonych porcjach. Test limitu 1,5 s dotyczy kontrolowanej symulacji
5000 odległych kandydatów, nie gwarancji czasu dla dowolnego poziomu.

Paczka: `output/MULTI-TOOL-V2-1.3.8.zip`. Zainstaluj ją na hoście
i wszystkich klientach, następnie uruchom ponownie grę i serwer.
