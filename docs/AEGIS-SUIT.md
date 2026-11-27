# Kombinezon serwomanipulacyjny Aegis V2

Wersja **1.3.26** dla Barotrauma 1.13.5.0 / LuaCs c6e8829. Identyfikator przedmiotu `aegisservosuit`. Obie strony multiplayera muszą mieć tę samą wersję moda. Komunikaty kombinezonu używają protokołu v6. [Poprawiona grafika szafki i porównanie z grą](AEGIS-RACK.md) · [Próby funkcji i zmierzone prędkości pływania w 1.3.18](AEGIS-SERVICE.md).

[Otwórz animowany podgląd V2](aegis-suit/index.html). Działa lokalnie, bez instalowania bibliotek. Pokazuje nowy pancerz, oba stany hełmu, ramię, impulsy, iskry, wirniki i dźwięki. To demonstracja zasobów; nie zastępuje próby w grze.

[Oryginalny miniaturowy laser i nowe promienie1.3.20](AEGIS-BEAMS.md).
[Strzelanie na lądzie nad sojusznikami i niskimi przeszkodami1.3.21](AEGIS-RAISED-AIM.md).

## Używanie

Kombinezon zachowuje smukłe proporcje. Obecna poprawka dodaje trwałe podtrzymywanie celu, wspólną końcówkę promieni, tolerancję ruchu podczas naprawy, chowane panele i natywny sonar. [Zawieszenie osoby i schowane panele](aegis-suit/controls-hold.png), [osobny sonar](aegis-suit/controls-sonar.png), [szersza naprawa](aegis-suit/controls-repair.png), [przedmiot na ziemi](aegis-suit/controls-ground.png), [impuls z końcówki](aegis-suit/controls-pulse.png). Zrzuty pochodzą z gry, z włączonym oświetleniem i bez obróbki obrazu.

Aktualna paczka to `output/System-Aegis-1.3.26.zip`.

Załóż kombinezon w slocie ubrania zewnętrznego. Włóż baterię lub pręt reaktora do pierwszego slotu i obsługiwaną skrzynkę amunicji do drugiego. Obieg oddechowy i ramię korzystają z zasilania kombinezonu. Przycisk „Ramię włączone / Ramię wyłączone” pokazuje stan, a ponowne włączenie przywraca ostatni tryb.

Komendy F3 (na serwerze wymagają uprawnień):

```text
enablecheats
spawnitem aegisservosuit inventory 1
spawnitem batterycell inventory 1
spawnitem pulselaserammobox inventory 1
```

Pręt zamiast baterii: `spawnitem fuelrod inventory 1`. Obsługiwane są też baterie fulgurium oraz pręty torowe i fulgurium. Panel po prawej stronie pozwala wybrać jedną funkcję:

- **Naprawa / spawanie**: automatycznie wybiera pobliskie urządzenie albo sekcję ściany. Ramię ma promień ruchu 118, końcówkę wysuniętą o 24 i promień naprawczy długości do 68; podstawowy zasięg od mocowania wynosi 210 jednostek. Rozpoczęta naprawa ma dodatkowe 32 jednostki tolerancji ruchu. Krótkie zasłonięcie zachowuje cel do 0,4 s, ale w tym czasie nie naprawia przez przeszkodę. Szerszy niebieski promień i mocne iskry wychodzą z końcówki narzędzia. Natywna naprawa uwzględnia umiejętności, statystyki szybkości, jakość urządzenia, nadnaprawę, zdobywanie umiejętności i `OnRepairComplete`; narzędziowa premia wynosi +450%. Nie przejmuje urządzenia naprawianego przez inną postać. Spawanie ma bazową siłę 64 na sekundę, uwzględnia premię postaci i wywołuje natywny talent po zamknięciu zewnętrznego przecieku. Nie symuluje QTE ani nagród za ręczne trafienia w QTE.
- **Obrona** dobiera miniaturowy pocisk do skrzynki. Pełne skrzynki dają 132 strzały pulsacyjne, 84 potrójne, 600 standardowych Gaussa, 600 z fizykorium, 300 wybuchowych lub 447 przebijających. Potrójna amunicja wypuszcza trzy promienie na strzał, Gauss używa fizycznych pocisków, a amunicja wybuchowa zadaje obrażenia od eksplozji przy bezpośrednim trafieniu. Ramię szuka jednego wrogiego celu w promieniu 1800 jednostek. Minimalny odstęp to 0,25 s dla Gaussa i 0,40 s dla lasera. Przeszkody i postacie na linii celowania blokują wybór celu.
- **Chwytak** — wybierz tryb, wskaż cel kursorem, przytrzymaj **PPM (Celuj)** i naciśnij **E (Użyj)**, potem puść klawisze. Chwytak podtrzymuje cel, stopniowo wyhamowuje jego ruch i próbuje poprowadzić go wokół przeszkody. Jeśli przejście jest zamknięte, trzyma cel po dostępnej stronie. Po puszczeniu postać wraca do wcześniejszego stanu ragdolla. Kolejne naciśnięcie E podczas celowania zwalnia cel. Chwyt puszcza również po przekroczeniu zasięgu podtrzymania, zmianie trybu, utracie energii lub przytomności oraz zdjęciu kombinezonu. Panel pokazuje własne przypisania klawiszy. W zasięgu 300 jednostek gry chwytak łapie jeden luźny przedmiot do 80 jednostek masy lub jedną istotę, także martwą. Można wycelować w odsłoniętą część ciała. Chwytak omija zamocowane urządzenia, rzeczy z ekwipunków i podłączone przewody podczas wybierania celu. Od wersji 1.3.22 chwytak jest dostępny do ręcznego użycia przez gracza.

Prawy panel chowa się przyciskiem `»`; zakładka **Ramię** przywraca go bez zmiany wybranej funkcji. **Sonar** otwiera niezależny lewy panel z własnym przyciskiem zasilania, trybem aktywnym i pasywnym oraz natywnymi echami gry do 6000 jednostek. Schowanie panelu nie wyłącza sonaru ani ramienia. Aktywny sonar pobiera bazowo 0,12 stanu zwykłej baterii/s, pasywny 0,03/s, z normalnym mnożnikiem prętów reaktora. Impulsy i reakcje AI wynikają z natywnego sonaru; to nie radar wszystkich obiektów. Sonar działa niezależnie od pojedynczej funkcji ramienia. Bez energii przestaje działać, a po wymianie źródła może wznowić żądany tryb.

Na lądzie **Obrona pulsacyjna** sprawdza również drogę od mocowania ramienia do przeciwnika. Gdy sojusznik lub niska przeszkoda blokuje zwykłą pozycję, ramię próbuje unieść lufę. Strzela po ustawieniu przegubów i sprawdzeniu całej drogi ramienia oraz promienia. Brak miejsca pod sufitem albo pełna ściana zatrzymują ogień. Po co najmniej 0,5 s stabilnego prześwitu wraca do zwykłego celowania. Funkcja działa automatycznie, bez nowych przycisków. Zachowanie pod wodą pozostaje dotychczasowe.

Wszystkie funkcje ramienia są wzajemnie wykluczające. Wirniki i układ oddechowy działają osobno. Nienaruszona powłoka daje ochronę ustawioną na **10 000 m**, także bez baterii. To parametr natywnej ochrony, nie nieśmiertelność ani potwierdzony test na każdej głębokości.

Hełm odsłania się przy suchej głowie, bezpiecznym ciśnieniu i co najmniej 50% tlenu w pomieszczeniu. Wtedy obieg oddechowy nie pobiera energii. W wodzie lub nieoddychalnym środowisku hełm zamyka się, a zasilany zamknięty obieg dostarcza tlen **bez butli**. Bez energii obieg i latarki przestają działać. Kombinezon nie ma kary szybkości na lądzie ani narzuconych animacji ciężkiego skafandra.

Hełm i narzędzie mają prawdziwe latarki z cieniami. Ramię i wirnik są rysowane w świecie razem z postacią, przed oświetleniem i obróbką obrazu. Światła są usuwane po zdjęciu kombinezonu, zakończeniu rundy i restarcie LuaCs, również po pauzie.

AI używa tego samego kontrolera funkcji: widoczne zagrożenie, pilny przeciek, naprawa. Nie chwyta postaci ani przedmiotów i nie podnosi nieprzytomnych sojuszników. Natywny znacznik `divinggear_wearableindoors` pozwala botowi zachować kombinezon w bezpiecznych pomieszczeniach. Nawigacją i zwykłymi rękami nadal steruje silnik gry.

AI samo wymienia puste zasilanie i amunicję: najpierw z własnego ekwipunku, potem z dostępnych zapasów w tej samej łodzi, używając natywnego chodzenia do magazynów. Nie tworzy zasobów i nie zabiera ich innym postaciom, reaktorom ani zainstalowanym narzędziom. Wyszukiwanie ma limit czasu i odstęp ponowienia; zdjęcie kombinezonu anuluje jego pobieranie. AI rozpoznaje obieg bezbutlowy.

Przedmiot jest dostępny u sprzedawców badawczych i wojskowych oraz w fabrykatorze. Integracja z rzeczywistymi sklepami i reputacją Aegis pozostaje do dopasowania po udostępnieniu DLC; obecna wersja nie wymaga Home & Harbor.

Ramię zachowuje kierunek w świecie podczas obrotu tułowia i wybiera najbliższe ułożenie łokcia. Naprawa i obrona czekają na ustawienie narzędzia; trwający chwyt zachowuje siłę podczas obrotu. Światło i promienie pozostają przy końcówce.

Automatyczna naprawa omija animację zwykłych rąk, która wymuszała ruch i kucanie, oraz działa na drabinie i siedzeniu. Ręczna komenda naprawy nadal oddaje urządzenie normalnemu sterowaniu. Premia +450% daje bazowy mnożnik narzędzia 5,5×; rzeczywisty czas zależy od postaci i urządzenia. Spawanie naprawia bazowo **64 jednostki/s**, a impuls zadaje **16 poparzeń + 4 obrażenia od eksplozji** przed odpornościami.

Chwyt uwzględnia względną prędkość celu i noszącego, podnosi postać docelowo o 85 jednostek i szuka niższego bezpiecznego miejsca pod sufitem. Podczas chwytu postać przechodzi przez zwykłe schody i podesty, a po puszczeniu wracają wcześniejsze ustawienia. Ochrona obejmuje przypadkowe urazy od zderzeń podczas przenoszenia. Luźny przedmiot jest przyciągany do końcówki szczypiec, gdy droga do niej jest wolna.

Zasilany stojak na kombinezony ładuje zainstalowane źródło — baterię lub pręt — o **0,5% maksymalnego stanu/s**. Brak napięcia, zepsuty stojak lub zwykła skrzynia zatrzymują ładowanie. Amunicja nie jest odnawiana. Osobna pionowa grafika służy do ekspozycji za szybą i w stojaku; ikona i przedmiot na ziemi zachowują złożoną postać.

Sonar po zwinięciu pokazuje wyłącznie mały radar. `+` rozwija ustawienia; wyłączony i zwinięty sonar jest całkowicie ukryty. Przycisk **Sonar** po prawej ponownie otwiera ustawienia. **Minerały** uruchamia natywny skaner złóż w trybie aktywnym. Aktywna funkcja ramienia ma zielonkawe podświetlenie.

Pływanie zmierzono na tej samej postaci: zasilany kombinezon **2,336 m/s**, zwykły **2,226**, głębinowy **1,813**, UKOS **2,326**; odpowiednio około **+5%, +29% i +0,4%**. Bez zasilania nowy kombinezon osiągnął **2,226 m/s**. To wynik opisanej próby, a nie stała premia procentowa dla każdej postaci. [Metoda i aktualna weryfikacja](AEGIS-SERVICE.md).

## Obrażenia ramienia

Wartości bazowe przed uwzględnieniem pancerza i odporności trafionej części ciała.

| Amunicja | Bezpośrednie obrażenia | Dodatkowe efekty |
|---|---|---|
| Pulsacyjna | 16 poparzeń + 4 od eksplozji | 0,15 ogłuszenia |
| Potrójna pulsacyjna | 7 poparzeń + 3 od eksplozji na promień. Do 30 łącznie przy trafieniu trzema promieniami | 0,10 ogłuszenia na promień |
| Gauss standardowa | 12 ran szarpanych | 0,8 krwawienia i 0,025 ogłuszenia |
| Gauss z fizykorium | 20 ran szarpanych | 1,2 krwawienia i 0,05 ogłuszenia |
| Gauss wybuchowa | 19 obrażeń od eksplozji | 1 krwawienia i 0,20 ogłuszenia przy trafieniu |
| Gauss przebijająca | 9 ran szarpanych za trafienie | 1,5 krwawienia i 0,0125 ogłuszenia na trafienie. Do dwóch trafień, także w dwie części ciała jednego celu |

Pociski Gaussa mają własny odgłos, smugę i efekt trafienia. Oba warianty
lasera kończą wiązkę błyskiem i iskrami. Błysk przy lufie odpowiada rodzinie
oddanego strzału.

## Zasoby

- [Złożony kombinezon — PNG](../System-Aegis/Assets/AegisSuit/packed-suit.png): osobna ikona ekwipunku i sprite przedmiotu na ziemi, około 86 × 35 jednostek. Wbudowany `image_gen`, oryginalny raster bez zmian; [pełny prompt](aegis-suit/packed-suit-prompt.txt).

- [Nowy arkusz V2 — PNG](../System-Aegis/Assets/AegisSuit/suit-v2.png): grafitowe płyty, czerwone panele, osłonięte przewody, cyjanowe optyki, kompaktowe ramię i wirnik. Starsze arkusze `suit.png` i `arm.png` zachowano jako źródła pierwszego prototypu.
- [Mapa wycinków](../System-Aegis/Assets/AegisSuit/sprites.json). Gra i podgląd korzystają z prostokątów źródłowych, zachowując arkusze bez utraty przezroczystości.
- Osiem oryginalnych dźwięków OGG w `System-Aegis/Assets/AegisSuit/Audio`: naprawa, spawanie, bojowy promień, chwytak, wirnik, serwo, hełm i przełącznik. Ponowne generowanie: `python tools/generate_aegis_audio.py` z dostępnym ffmpeg.
- V2 w grze odwołuje się do natywnego dźwięku lasera; nie skopiowano go do moda. Podgląd ma dodatkowy oryginalny krótki odsłuch `pulse.ogg`, generowany przez `python tools/generate_aegis_audio.py --only pulse`.
- Natywna warstwa uszczelniająca korzysta z istniejącej tekstury kombinezonu głębinowego gry; nie skopiowano jej do moda.
- [Pochodzenie i prompty](aegis-suit/ASSET-SOURCES.md).

## Weryfikacja 1.3.17 — 17 listopada 2026

[Oddzielny test wydajności na dwóch klientach](AEGIS-PERFORMANCE.md): 22 scenariusze na każdym kliencie, ramiona i sonary oraz sześciu dodatkowych nosicieli. Wiele napraw powoduje duży mierzalny koszt; wyniki funkcjonalne poniżej nie oznaczają braku spadków FPS.

- **575 testów — OK**, walidacja **17 XML / 58 modułów Lua 5.2**, **21/21 sprawdzeń w Chrome**, bez wyjątków podglądu.
- **19/19 prób w natywnym singleplayerze**: ograniczona prędkość przegubów, utrzymanie osoby bez klawiszy, korekta punktu podtrzymania przy prawdziwym suficie, panele i sonar, pełna naprawa oraz impuls z poruszającej się końcówki. Maksymalny krok górnego przegubu przy 60 Hz wyniósł 0,06667 rad; punkt chwytu obniżył się z +45 do około +0,82 bez zwolnienia ragdolla. [Wyniki](aegis-suit/motion-native-client.txt).
- **9/9 etapów rzeczywistego multiplayera lokalnego**: klient otrzymał nowe kąty przegubów i jawny znacznik automatycznej naprawy. Podczas oglądania naprawianego urządzenia zarejestrowano **0** wywołań `UpdateUseItem` i **0** wymuszeń kucania; ręczny ruch i ręczne kucanie zadziałały po 30 próbek. Naprawa osiągnęła 100, umiejętność wzrosła **20 → 22**, `OnRepairComplete` wystąpił raz. [Serwer](aegis-suit/motion-mp-server.txt), [klient](aegis-suit/motion-mp-client.txt).
- Natywny pocisk i narzędzie miały ten sam początek promienia z błędem poniżej **0,008 jednostki** w SP i MP. W ciasnym pomieszczeniu multiplayera chwyt wybrał niższą kotwicę i pozostał aktywny przez ponad 7 s, z błędem podtrzymania około 0,58 jednostki.
- Niezależny przegląd wykrył przypadek otwarcia panelu podczas naprawy. Dodano regresję RED/GREEN, znacznik sesji przesyłany w v4 oraz oddawanie urządzenia po prawdziwej ręcznej komendzie naprawy. Powtórny przegląd nie znalazł pozostałych problemów Critical/Important.
- Próby początkowe wymagały usunięcia konkurujących urządzeń pozostawionych w scenie, znalezienia rzeczywistego sufitu zamiast granicy obszaru powietrza oraz użycia natywnej akcji `Crouch`. Pełny stan naprawy mierzono przed późniejszym zużyciem urządzenia. Są to korekty scenariuszy, uwzględnione w finalnych plikach `tests/runtime/aegis_motion_*`.
- [Manifest plików i zakres weryfikacji](aegis-suit/motion-verification.txt). Starsze paczki i pomiary zachowano. Zestaw obejmuje jeden lokalny klient; nie obejmuje Steam P2P, dużych opóźnień ani wszystkich modowych ciał i talentów. Próba sufitu potwierdza kontakt z geometrią, a regułę krótkiej utraty widoczności i prowadzenie przy ścianie sprawdzają również regresje Lua.

## Archiwum weryfikacji 1.3.16 — 16 listopada 2026

- **560 testów**, walidacja **17 XML / 57 modułów Lua 5.2**, **21/21 sprawdzeń w rzeczywistym Chrome**, bez wyjątków podglądu.
- **16/16 prób w rzeczywistym kliencie singleplayer**: sprzęt, bezwład żywego celu po puszczeniu klawiszy, niezależne chowanie paneli, prawdziwy sonar, podtrzymywanie ponad 5 s, puszczenie drugim naciśnięciem, ruch podczas naprawy, natywne nagrody, przedmiot na ziemi i początek impulsu. [Wyniki](aegis-suit/controls-native-client.txt).
- **9/9 etapów rzeczywistego lokalnego multiplayera** po końcowych poprawkach: podtrzymywanie bez klawiszy przez ponad 7 s, oba tryby sonaru i oba panele, zwolnienie ragdolla, pełna naprawa po ruchu gracza, impulsy oraz automatyczne zwolnienie po wyczerpaniu baterii. [Serwer](aegis-suit/controls-mp-server.txt), [klient](aegis-suit/controls-mp-client.txt).
- Natywna naprawa podniosła umiejętność **20 → 22** i wywołała ukończenie dokładnie raz. Początek natywnego strzału różnił się od wspólnej pozycji końcówki o mniej niż 0,01 jednostki w próbach SP i MP. Widoczna wiązka jest rysowana od tej samej końcówki.
- Przegląd znalazł usunięty cel blokujący kolejną naprawę i pomijanie sprzątania podczas zmiany właściciela. Oba przypadki mają regresje RED/GREEN i poprawki. Próba MP wykryła dodatkowo gubienie szybkiej serii niezależnych poleceń; ograniczony budżet żądań obsługuje serię i nadal ogranicza spam. Naprawiono też odczyt serwerowego pola kompensacji trafień w klienckim kodzie tarczy, ujawniony przez laser.
- [Środowisko, pomiary i sumy plików](aegis-suit/controls-verification.txt). Multiplayer obejmuje jeden klient na tym samym komputerze; nie zastępuje próby Steam P2P ani długiej kampanii.

## Korekta sylwetki i ramienia — archiwum, 16 listopada 2026

- **528 testów**, **21/21 sprawdzeń w rzeczywistym Chrome**, walidacja **17 XML / 54 Lua 5.2** — poprawne.
- **3/3 prób natywnego klienta**: podniesione ramię w spoczynku z prawej strony, lustrzany widok z lewej oraz aktywne przyciąganie przedmiotu z widocznym ramieniem. [Wyniki](aegis-suit/slim-native.txt), [środowisko i sumy plików](aegis-suit/slim-verification.txt).
- Skala tułowia 0,82 → 0,60, hełmu 0,50 → 0,40; pozostałe płyty również zmniejszone. Segmenty ramienia 50/42 → 68/60, większa głowica. Dłuższe segmenty składają się w dotychczasowym promieniu roboczym 92; zasięgi funkcji nie zostały zwiększone.
- Wspólna pozycja spoczynkowa steruje rysowaniem i latarką narzędzia. Tekstura atlasu pozostała bez zmian; korekta dotyczy skali i ułożenia części. Przegląd nie znalazł problemów Critical/Important. Te próby wizualne dotyczą singleplayer; wcześniejsze wyniki multiplayer pozostają osobnym zapisem.

## Poprawka chwytaka — 16 listopada 2026

Podpowiedź w panelu pokazuje rzeczywiste klawisze celowania i użycia. Chwytak obejmuje również luźne obiekty bez komponentu standardowego podnoszenia. Limit masy dotyczy całej istoty.

- **528 testów automatycznych**, walidacja **17 XML / 54 modułów Lua 5.2** — poprawne.
- **6/6 prób w natywnym kliencie singleplayer**: masa człowieka i molocha, luźny obiekt bez `Pickable`, przechwycenie i fizyczne przyciąganie tego obiektu, rozwiązane nazwy klawiszy w panelu, przechwycenie żywego człowieka oraz puszczenie drugim naciśnięciem. Wejście symulowano przez natywne `SetInput` i pozycję kursora bez zmiany produkcyjnej logiki sterowania. [Wyniki](aegis-suit/grab-followup.txt), [panel](aegis-suit/grab-help.png), [środowisko i sumy plików](aegis-suit/grab-verification.txt).
- Natywny typ dynamicznego ciała to enum `FarseerPhysics.BodyType`, a nie tekst. Regresje i próba w grze obejmują tę reprezentację.
- Nowa paczka: `output/System-Aegis-aegis-v2-grab-2026-11-16.zip`. Poprzednia paczka V2 pozostaje zachowana. Poniższe próby multiplayer dotyczą wcześniejszego V2; poprawkę chwytaka sprawdzono osobno w singleplayer.

## Weryfikacja V2 — 16 listopada 2026

- **523 testy automatyczne**, **21 sprawdzeń podglądu**, walidacja **17 XML / 54 modułów Lua 5.2** — poprawne.
- **11/11 etapów z rzeczywistym podłączonym klientem**: dwa sloty, szybka naprawa z iskrami i pełne ukończenie, impulsy i zużycie amunicji, blokada pustej skrzynki, chwyt, oddychanie/pływanie, spawanie, wymiana zasobów z ekwipunku AI i pobranie z magazynów, wyłączenie latarek bez energii oraz stan przycisku. [Serwer](aegis-suit/v2-multiplayer-server.txt), [klient](aegis-suit/v2-multiplayer-client.txt).
- Natywna naprawa podniosła umiejętność elektryczną **20 → 22** i wywołała `OnRepairComplete` dokładnie raz. Po około 2 s stan urządzenia wzrósł z 10 do około 58; dalszy pomiar potwierdził pełną naprawę.
- Impulsy trafiły cel około **650 jednostek** od noszącego. Osobny obserwator potwierdził emisje natywnego śladu, automatyczne wywołania dźwięku i działające kanały audio. [Pomiar](aegis-suit/v2-pulse-visual.txt).
- Natywny obserwator restartu LuaCs potwierdził usunięcie **4/4 własnych świateł**. [Pomiar](aegis-suit/v2-light-cleanup.txt).
- Po `pauseClient + clear` obserwator również naliczył **4/4 usunięć świateł**: [pomiar po pauzie](aegis-suit/v2-light-pause.txt).
- Natywny serwer potwierdził wyjęcie i ponowne włożenie obu zasobów wykonane przez klienta: [energia](aegis-suit/v2-inventory-0.txt), [amunicja](aegis-suit/v2-inventory-1.txt). Pomiar modyfikatorów ruchu pokazał `WalkingSpeed=0`, `MovementSpeed=0`, przy ochronie 10 000: [wynik](aegis-suit/v2-movement.txt).
- Zrzuty z GPU z aktywnym oświetleniem gry: [naprawa i sloty](aegis-suit/v2-repair.png), [natywny impuls](aegis-suit/v2-pulse.png), [pływanie](aegis-suit/v2-water.png), [spawanie](aegis-suit/v2-weld.png), [brak energii w ciemności](aegis-suit/v2-dark.png).
- Przegląd znalazł dwa przypadki sprzątania: cel AI po zdjęciu kombinezonu i światła po pauzie. Oba poprawiono z regresjami RED/GREEN przed finalną próbą. Potwierdzono natywną ścieżkę nagród, nie każdy talent osobno.

## Archiwum weryfikacji pierwszego prototypu

Poniższe pomiary dotyczą wcześniejszej wersji z butlą i ciągłym promieniem. Pozostają zapisem historii, a nie instrukcją ani wynikiem V2.

- **505 testów automatycznych — OK**, pełny zestaw projektu. Regresje obejmują oddychanie klienta bez lokalnego pobierania tlenu, pauzę, pojedynczy tryb, zwalnianie chwytu, jego czas i ponowne przejęcie, nieprzytomną postać, filtry przenośnych rzeczy, AI, kontakt z właściwą sekcją ściany oraz rozpoczęcie pracy po dosunięciu ramienia. Dodatkowe pięć sprawdza obrót mocowania razem z tułowiem, interpolowaną pozycję rysowania i wybór pojedynczego celu chwytaka po kierunku celowania.
- **20 sprawdzeń podglądu — OK**. Składnia JavaScript i lokalne wczytanie w przeglądarce sprawdzone.
- Walidacja **17 XML / 49 modułów Lua 5.2**: odwołania, receptura, OGG, RGBA i wycinki tekstur poprawne.
- **11 prób na natywnym izolowanym serwerze — PASS**: prawdziwe sloty, brak podwójnego naliczania ochrony przez płyty, oddzielne źródła tlenu i energii, naprawa urządzenia, pręt, puste zasilanie, właściwości oddychania, wyszukiwanie celów, spawanie sekcji, siła chwytu żywej postaci i obrażenia promienia. [Surowe wyniki](aegis-suit/native-checks.txt).
- **Rzeczywisty włączony AI** utrzymał kombinezon i automatycznie naprawił urządzenie z 10 do 23,5. Pręt spadł do 99,7755; butla została na 200; hełm był otwarty, ochrona 10 000. [Wynik](aegis-suit/ai-check.txt).
- **Zanurzenie AI** zamknęło hełm, utrzymało dostępny tlen około 99,17 i zmniejszyło butlę do 199,3944. Wirniki pracowały, pręt spadł do 99,6981; postać żyła, ochrona wynosiła 10 000. [Wynik](aegis-suit/water-check.txt).
- **Finalny klient GPU działa**: obejrzano obie warstwy Wearable, 14 widocznych płyt, hełm w powietrzu i wodzie oraz ramię i wirniki. Poprawiono mocowanie do tułowia: obraca się z postacią podczas pływania i korzysta z interpolowanej pozycji rysowania. Wcześniejszy błąd inicjalizacji adaptera graficznego nie powtórzył się; nie przypisujemy tego poprawce moda. Zrzuty z rzeczywistego klienta: [naprawa](aegis-suit/gpu-repair.png), [chwytak](aegis-suit/gpu-grab.png), [pływanie](aegis-suit/gpu-water.png), [spawanie](aegis-suit/gpu-weld.png). Na potrzeby oglądu wyłączono oświetlenie i ograniczenie pola widzenia; po próbie przywrócono ustawienia.
- **8/8 etapów rzeczywistego multiplayera lokalnego — PASS**: dedykowany serwer i osobny podłączony klient, autorytet po stronie serwera. Sprawdzono replikację dwóch pojemników, naprawę urządzenia z iskrami, obrażenia bojowe, wskazanie i przyciągnięcie przedmiotu, zamknięcie hełmu i zużycie tlenu podczas pływania, wymianę baterii na pręt, odrzucenie próby sterowania cudzym kombinezonem, wyłączenie promienia oraz spawanie z replikacją stanu ściany i iskrami. [Wynik serwera](aegis-suit/multiplayer-server.txt), [wynik klienta](aegis-suit/multiplayer-client.txt).
- Próba wykryła i pozwoliła poprawić chwytak: natywna sieć gry przesyła kąt celowania, a serwer odtwarza kursor w stałej odległości 500 jednostek. Wybór celu wzdłuż kierunku działa teraz jednakowo lokalnie i w sieci; serwer nadal sprawdza zasięg, widoczność i dostępność celu. Początkowe nieudane przebiegi ujawniły też konkurujące cele pozostawione przez wcześniejsze próby. Scenariusz usuwa je i osobno sprawdza przyciągnięcie właściwego przedmiotu.

Nie przeprowadzono próby Steam P2P, wielu klientów z dużym opóźnieniem, rzeczywistej granicy 10 km ani pełnych kombinacji modowych ragdolli, efektów i talentów. Lokalny multiplayer obejmuje jeden sterowany klient i kontrolowane cele testowe, a nie długą kampanię. Automatyczne ratowanie botem ma test reguł; fizyczny chwyt żywej postaci sprawdzono osobno na serwerze.

Próby dotyczyły wyłącznie odrębnych katalogów `.runtime/aegis-native` i `.runtime/aegis-client`. Instalacja Steam i kampania użytkownika nie zostały zmienione.
