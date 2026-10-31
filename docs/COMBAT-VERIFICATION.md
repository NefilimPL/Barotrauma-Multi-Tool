# Aegis — weryfikacja wersji 1.1.x

## Poprawka 1.1.3 — odczucie strzału, dźwięk i impuls

Zgłoszenie użytkownika: brak dźwięków strzelania i trafień, zbyt statyczny
pierścień, słaba reakcja NPC, za długa przerwa między strzałami i za szybki lot.
Dobór dokładnych wartości i charakteru audio jest decyzją wykonawcy w ramach
zleconego strojenia istniejącej broni.

- Ładowanie 0,12 s i przerwa 0,34 s dają około 2 strzałów/s przy trzymaniu
  spustu, wobec około 1/s wcześniej. Lot: 1050 zamiast 1400 jednostek/s.
  Czas życia podniesiono do 3,2 s, aby zachować zasięg 3200.
- Dziewięć oryginalnych, proceduralnie syntezowanych plików mono Vorbis
  tworzy pięć rodzin: wystrzał, ładowanie, NPC, powierzchnia i odbicie.
  Natywne prefabrykaty dźwięków wybierają warianty. Odtwarzanie następuje
  raz na zdarzenie serwera/lokalnej symulacji, w pozycji świata, z natywną
  głośnością, tłumieniem przez ściany i wodę. Błąd audio nie blokuje broni.
- Naprawiono brak zdarzenia ostatniego uderzenia w ścianę po wyczerpaniu
  odbić. Zdarzenie `wallhit` ma własny numer; serwer i klienci wymagają
  tej samej wersji moda.
- Pierścień pulsuje, ma obracające się gorące fragmenty, poświatę i krótki
  ślad. Ślad zapisuje faktyczne punkty odbić, ma limit 12 punktów/0,12 s
  i jest zachowywany przy synchronizacji, o ile korekta nie przecina ściany.
  Dodano rozbłysk lufy, rozchodzące się impulsy i kierunkowe iskry trafień.
- Trafienie przekazuje impuls 7,5 pomniejszany po odbiciach. Impuls przechodzi
  przez `Character.AddDamage`, dzięki czemu wyłączone friendly fire chroni
  też przed popchnięciem. Nie dodano osobnego ogłuszania omijającego tę
  ochronę. Dodano umiarkowany natywny odrzut samej broni.
- Obrażenia pojedynczego trafienia i koszt strzału nie wzrosły. Większa
  częstotliwość zwiększa obrażenia i zużycie energii w jednostce czasu.

Wyniki końcowe:

- **56/56 testów automatycznych**, w tym nowe regresje dźwięku zdarzeń,
  końcowego trafienia, impulsu natywnego, ruchomej obręczy, trasy śladu,
  ciągłości po synchronizacji i kadencji. Przed implementacją nowe testy
  odtworzyły brak tych zachowań.
- **Rzeczywisty klient/GPU i audio:** 16 klatek, 4 kąty, animowane pierścienie
  i ślady, 8 rodzajów efektów; pięć rodzin dźwięków utworzyło rzeczywiste
  przestrzenne kanały audio bez błędu. Wszystkie 9 plików przeszło też
  niezależne dekodowanie Vorbis przez ffmpeg.
- **5/5 natywnych prób pierścienia:** obrażenia przeciwnika, mierzalny
  ograniczony przyrost prędkości NPC po trafieniu, obrażenia sojusznika
  przy friendly fire włączonym, brak obrażeń i zmiany prędkości przy
  friendly fire wyłączonym, zgodność pozycji emiterów.
- **13/13** prób podstawowych i **5/5** prób AI: 319 dozwolonych użyć
  spawarki bez strzelania, następnie 6 strzałów w zadaniu walki bez
  wywołań technicznych; checkbox zatrzymuje broń i tarczę.
- Ponownie przeszło **5/5** natywnych prób tarczy i kolizji pocisków.

Próba audio potwierdza dekodowanie, tworzenie kanałów i przestrzenne API;
subiektywna barwa i głośność pozostają do oceny w rozgrywce. Podgląd HTML
w `Assets/Combat/Audio/preview.html` pozwala odsłuchać efekty osobno.

## Poprawka 1.1.2 — geometria grafiki i friendly fire

Zgłoszenie użytkownika: zbyt duża broń i tarcza, znikanie tekstury przy
celowaniu w górę, przesunięte efekty, światło poza lampą, złe punkty chwytu
oraz brak obrażeń załogi w testerze.

Przyczyny i zmiany:

- Kod pomijał sojuszników już podczas sprawdzania kolizji pierścienia.
  Teraz wykrywa trafienia postaci poza strzelcem i wywołuje natywne
  `Character.AddDamage`, które uwzględnia ustawienia friendly fire rozgrywki.
  Tarcza nadal przechwytuje wrogie ataki i poraża przeciwników.
- Jeden zasłonięty punkt wyłączał całą teksturę tarczy. Przycinanie odbywa
  się teraz w 16 pasach z zachowaniem wspólnego punktu obrotu.
  Promień tarczy zmniejszono z 95 do 80, wysokość grafiki wynosi około
  139 jednostek, a krycie tekstury około 18% zamiast dotychczasowych 90%.
- PNG mają zwykły kanał alfa; domyślny `AlphaBlend` oczekuje kolorów
  pomnożonych przez alfa i nadmiernie rozjaśniał efekty. Renderer używa
  `NonPremultiplied`. Typ `BlendState` jest jawnie rejestrowany w LuaCs.
- Skalę broni zmniejszono z 0.085 do 0.068. Uchwyty wskazują dolne chwyty
  tekstury (poprawiony znak Y), a lampa ma początek na jej soczewce.
  Emitery `RepairTool` wymagają jednostek świata, w przeciwieństwie
  do skalowanego `RangedWeapon`; wszystkie trzy mają poprawione pozycje.
- Ładowanie zaczyna się przy lufie i podąża za nią. Efekty trafienia/odbicia
  są mniejsze i wykorzystują normalną powierzchni zamiast kierunku broni.
  Kompresję sprite'a broni wyłączono, ponieważ jego wymiary nie są
  wielokrotnością czterech. Sam bitmapowy zasób pozostaje bez zmian.

Weryfikacja:

- **49/49 testów automatycznych.** Nowe regresje odtworzyły odmowę trafiania
  sojusznika, znikanie całej tarczy przy częściowym zasłonięciu,
  niewłaściwą orientację trafień i niepoprawny układ broni. Testy sprawdzają
  też stały punkt obrotu pasów tekstury i tryb mieszania alfa.
- **4/4 nowe próby natywne:** rzeczywisty pierścień odbiera żywotność wrogiemu
  NPC; odbiera ją załodze przy friendly fire włączonym; nie odbiera jej po
  wyłączeniu tej opcji; pozycje lufy narzędzia i broni pokrywają się.
  Scenariusz przechodzi przez produkcyjne `fire/updateRings`, raycasty
  i natywne obrażenia, a nie bezpośrednie wywołanie testowej funkcji obrażeń.
- Powtórzono **13/13** prób podstawowych, **5/5** prób tarczy/fizyki i
  **5/5** prób AI (328 wywołań spawarki, 3 strzały podczas walki,
  brak równoczesnych funkcji, checkbox skutecznie wyłącza broń/tarczę).
- **Rzeczywisty klient z GPU:** osobna kopia klienta 1.13.5.0/LuaCs,
  uruchomiona w ukrytym oknie, w edytorze statku. Produkcyjny renderer
  narysował 16 klatek dla czterech kątów celowania i siedmiu typów zdarzeń
  na rzeczywistym `SpriteBatch`, bez błędu. Wynik: `PASS native client GPU
  rendering: 16 frames, 4 aim angles, 7 effect kinds`.
  Instalacja gry użytkownika nie była zmieniana.

Próba klienta potwierdza działanie API rysowania; nie zastępuje wizualnej
oceny dłoni na animowanej postaci ani dłuższej rozgrywki z dwoma klientami.
Przy sprawdzaniu nowej skali należy utworzyć nowy egzemplarz broni;
zapisany przedmiot może przechować starą skalę.

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
