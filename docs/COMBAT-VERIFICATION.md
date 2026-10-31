# Aegis 1.1.0 — weryfikacja

## Poprawka 1.1.1 — zgłoszenie z testera statku

Zrzut konsoli użytkownika ujawnił `attempt to index a nil value` w
`visuals.lua` podczas rysowania arkusza. Kod wymagał globalnego
`SpriteEffects.None`, którego nie było na kliencie. Teraz korzysta
z domyślnego argumentu natywnego `Sprite.Draw`. Poprawiono również
odwołanie do rysowania linii: aktualny LuaCs udostępnia je przez `GUI.GUI`.
Test renderera używa tego układu API i braku globalnego enumu; odtworzył
błąd przed zmianą i przechodzi po poprawce.

Latarka otrzymała `directional="true"`, natywny `LightTexture` z
`Content/Lights/lightcone.png` oraz `LightColor` i przesunięcie do lufy.
Samo `coneangle` bez tekstury nie tworzyło stożka. Osobny test wykazał
błędną konfigurację przed poprawką i przechodzi po zmianie.

Pełny zestaw ma teraz **45/45 testów automatycznych**. Walidacja obejmuje
8 XML i 13 Lua. Natywne API potwierdziło, że zwykłe `batterycell` ma tag
`mobilebattery`, jest dopuszczone w obu slotach i daje się włożyć.
Ponowiony test podstawowy przeszedł **13/13 sprawdzeń**, w tym ograniczenia
obu slotów i rzeczywisty callback checkboxa zamiast ręcznej zmiany flagi.
Nie odtworzono jeszcze zgłoszonej odmowy wkładania na kliencie użytkownika;
nie należy traktować jej jako usuniętej. Dodano niemodyfikującą stanu
komendę `aegis_status`, sprawdzoną również na rzeczywistym serwerze.
Pełny test renderera w kliencie i ponowna próba użytkownika pozostają
konieczne. Dalszy tekst opisuje wcześniejszą weryfikację 1.1.0.

Weryfikacja końcowa: 2026-10-31. Kod i paczka są przeznaczone do prób w grze;
poniższe wyniki nie zastępują sprawdzenia grafiki i synchronizacji na klientach.

## Środowisko i odtworzenie

- Barotrauma Dedicated Server 1.13.5.0, LuaCs `c6e8829`.
- Osobna kopia w `.runtime/server`, bazowa zawartość gry i MULTI-TOOL-V2.
  Oficjalny patch LuaCs zastosowano wyłącznie do tej kopii. Instalacja Steam
  nie była modyfikowana.
- Python, Lupa 2.8 (interpreter Lua 5.2), Pillow; zależności lokalne.

```powershell
python tools/run_tests.py
python tools/validate_content.py --game 'D:/SteamLibrary/steamapps/common/Barotrauma'
git diff --check
python tools/package_mod.py
```

Skrypty natywne wymagają rundy Sandbox na serwerze testowym. Skopiuj
`tests/runtime/{smoke,shield_integration,ai_integration}.lua` do katalogu
`Lua/Tests/` testowej kopii moda, następnie uruchom z konsoli:

```text
lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/smoke.lua')
lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/shield_integration.lua')
lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/ai_integration.lua')
```

Ostatni skrypt trwa około 14 sekund. Testy tworzą postacie i przedmioty,
modyfikują stan rundy i zapisują wyniki w testowym folderze moda. Wyłącznie
testowy `keepalive.lua` utrzymuje rundę bez graczy. Żaden z tych skryptów
nie należy do paczki moda.

## Wyniki

- **43/43 testy automatyczne:** geometria i budżet odbić dla wszystkich jakości,
  wydawanie energii z właściwego slotu, priorytety funkcji, anulowanie ładowania,
  blokada powtórzonych użyć, zmiana właściciela, zasięg tarczy i zasłonięcie
  ścianą, uzupełnianie źródeł, synchronizacja po przeładowaniu Lua.
  Test renderera używa atrap API: sprawdza wszystkie prostokąty klatek,
  poprawne otwarcie/zamknięcie rysowania i lokalną predykcję pierścienia.
- **Walidacja zawartości:** 8 plików XML, składnia 12 plików Lua 5.2,
  ścieżki zasobów, kanał alfa pięciu PNG, prostokąty 16-klatkowych animacji,
  dwie ręce, dwa sloty, trzy checkboxy i identyfikatory surowców z gry.
- **12/12 natywnych sprawdzeń podstawowych:** wyposażenie, rozdzielenie
  zasilania, rzeczywiste właściwości komponentów, ładowany strzał,
  zapytanie fizyki, tarcza i blokada po wyczerpaniu, wyłączenie obrażeń,
  wyłączność spawania/cięcia, wymiana częściowo zużytej baterii broni oraz
  uzupełnienie tarczy bez ruszania źródła w slocie broni.
- **5/5 natywnych prób fizyki i obrażeń:** promień trafia rzeczywistą ścianę
  łodzi, tarcza zatrzymuje hitscan przed obrażeniami chronionej postaci,
  bliższa niechroniona postać nadal otrzymuje obrażenia, szybki pocisk fizyczny
  jest przechwytywany na przebytym odcinku, kontakt z tarczą zadaje natywne
  obrażenia i zużywa 6 jednostek energii.
- **5/5 natywnych prób AI:** podczas usuwania wycieku bot wykonał 308
  dozwolonych wywołań spawarki, bez cięcia, gaszenia ani strzelania,
  mimo włączonych checkboxów technicznych. Po zmianie zadania oddał
  4 ładowane strzały, z zerem wywołań technicznych podczas zadania walki.
  Wyłączenie obrażeń zatrzymało kolejne strzały i tarczę.

## Poprawki po przeglądzie i testach

Przegląd całej zmiany wskazał sześć istotnych problemów. Każdy otrzymał
test regresji i poprawkę: przesunięcie współrzędnych łodzi, pobieranie
odległego źródła przed wkładaniem, anulowanie zawieszonych zadań uzupełniania,
kolejność kolizji hitscan, anulowanie ładowania przez bierne odczyty AI
oraz reset numeracji pakietów po przeładowaniu serwera.

Natywne próby wykryły również ograniczenia mostka Lua/C#: dostęp do pola
wymaga deskryptora, a delegaty `Func<Item,bool>` i `Func<PathNode,bool>`
nie przyjmują bezpośrednio użytych funkcji Lua. Wymiana baterii korzysta
dlatego ze standardowego przeniesienia dokładnie jednego starego źródła
do ekwipunku bota (lub upuszczenia przy pełnym ekwipunku), a następnie
z natywnego zadania wkładania do wskazanego slotu. Inny slot pozostaje
nienaruszony. Odrzucone wywołania komponentów podczas natywnego `Item.Use`
nie przerywają już ładowania właściwego strzału.

## Pozostałe próby w kliencie gry

- Dopasowanie sprite'a do dłoni i lufy, jasność latarki oraz pozycja,
  czytelność i płynność czterech animacji tarczy w rzeczywistym rendererze.
  PNG obejrzano i przygotowano podgląd HTML; klient gry nie był uruchamiany.
- Dwa klienty, opóźnienia sieciowe, dołączenie w trakcie rundy i ponowne
  wczytanie zapisu. Serwerowa logika i testy kontraktu sieci przeszły;
  pełna rozgrywka sieciowa pozostaje do sprawdzenia.
- Pełne dojście bota do odległej baterii przez drzwi i śluzy. Tworzenie
  natywnego zadania pobrania objęto testem, a wkładanie sprawdzono w grze;
  cała trasa nie była osobnym scenariuszem integracyjnym.
- Oddzielne scenariusze AI naprawy urządzenia, gaszenia pożaru i wyboru
  przecinarki. Wybór funkcji oraz blokady objęto testami adaptera; natywny
  scenariusz wykonywanego zadania sprawdzono dla spawania i walki.
- Pełny cykl fabrykacji/dekonstrukcji z bateriami wewnątrz. Receptura
  i identyfikatory są poprawne. Zwrot zawartości wynika z odczytanego kodu
  natywnego fabrykatora/dekonstruktora oraz ustawień kontenera, lecz cykl
  nie został wykonany w grze.
- Skryptowe lasery i nietypowe pociski innych modów; balans w dłuższej rundzie.

## Decyzje wykonawcze

Polecenie „działaj” upoważniało do implementacji zatwierdzonego projektu.
Pracę wykonano bezpośrednio w istniejącej gałęzi funkcji `dev_weapon`;
nie wykonywano publikacji, push ani merge. W Windows użyto równoważnego
rejestru PowerShell/Python zamiast pomocników Bash. Ukryty kontener z atrapią
paliwa zastąpiono natywnymi zadaniami dojścia i obsługi spawarki, ponieważ
AI wycieków odczytuje tylko pierwszy kontener. Nie zmieniono tagów paliwa
ani istniejącego jednoręcznego multitoola.
