# Kombinezon serwomanipulacyjny Descendants V2

Druga wersja robocza dla Barotrauma 1.13.5.0 / LuaCs c6e8829. Identyfikator przedmiotu: `descendantservosuit`. Po aktualizacji pierwszego prototypu **utwórz nowy egzemplarz**, aby otrzymać nowy układ slotów. Obie strony multiplayera muszą mieć tę samą wersję moda.

[Otwórz animowany podgląd V2](descendant-suit/index.html). Działa lokalnie, bez instalowania bibliotek. Pokazuje nowy pancerz, oba stany hełmu, ramię, impulsy, iskry, wirniki i dźwięki. To demonstracja zasobów; nie zastępuje próby w grze.

## Używanie

Aktualna korekta sylwetki zmniejsza płyty tułowia, hełm i osłony kończyn. Ramię ma dłuższe segmenty, większy chwytak i pozycję spoczynkową ponad barkiem. [Wygląd z prawej](descendant-suit/slim-right.png), [z lewej](descendant-suit/slim-left.png), [podczas chwytania](descendant-suit/slim-working.png). To natywne zrzuty ze zbliżeniem kamery 2×, bez obróbki obrazu. Nowa paczka: `output/MULTI-TOOL-V2-descendant-slim-2026-11-16.zip`.

Załóż kombinezon w slocie ubrania zewnętrznego. Jeden widoczny panel ma dwa ograniczone sloty: pierwszy na baterię/pręt reaktora, drugi na skrzynkę amunicji lasera pulsacyjnego. Butla nie jest potrzebna. Zasilanie ramienia nie wymaga trzymania narzędzia w ręce. Przycisk „Ramię włączone / Ramię wyłączone” pokazuje stan i przełącza funkcję; ponowne włączenie przywraca ostatni tryb.

Komendy F3 (na serwerze wymagają uprawnień):

```text
enablecheats
spawnitem descendantservosuit inventory 1
spawnitem batterycell inventory 1
spawnitem pulselaserammobox inventory 1
```

Pręt zamiast baterii: `spawnitem fuelrod inventory 1`. Obsługiwane są też baterie fulgurium oraz pręty torowe i fulgurium. Panel po prawej stronie pozwala wybrać jedną funkcję:

- **Naprawa / spawanie**: automatycznie wybiera pobliskie urządzenie albo sekcję ściany. Ramię dosuwa emiter, potem uruchamia krótki niebieski promień i mocne iskry w punkcie naprawy. Natywna naprawa uwzględnia umiejętności, statystyki szybkości, jakość urządzenia, nadnaprawę, zdobywanie umiejętności i `OnRepairComplete`. Kombinezon daje narzędziową premię +300% szybkości. Nie przejmuje urządzenia naprawianego przez inną postać. Spawanie ma bazową siłę 48 na sekundę, uwzględnia premię postaci do spawania i wywołuje natywny talent po zamknięciu zewnętrznego przecieku. Nie symuluje QTE ani nagród za ręczne trafienia w QTE.
- **Obrona pulsacyjna**: krótkie czerwone impulsy atakują jeden widoczny wrogi cel, 360°. Zasięg 1800 jednostek gry, odstęp 0,4 s, bazowe trafienie 20 poparzeń + 5 obrażeń od eksplozji przed odpornościami celu. Wcześniej było to 420 i 4 obrażenia/s. Każdy impuls zużywa 2,25 stanu skrzynki i energię; pełna zwykła skrzynka daje 44 impulsy. Pocisk używa natywnego śladu, rozbłysków, iskier trafienia i dźwięku lasera pulsacyjnego. Natywne zasady AI rozpoznają przyjazne cele; przeszkody i postacie na linii celowania blokują wybór celu.
- **Chwytak**: wybierz tryb, wskaż cel kursorem, przytrzymaj **PPM (Celuj)** i naciśnij **E (Użyj)**. Ponowne E podczas celowania albo zmiana trybu puszcza cel. Panel i podpowiedź pokazują aktualnie przypisane klawisze, także po zmianie sterowania. Łapie pierwszy poprawny widoczny cel wzdłuż kierunku celowania: jeden luźny, dynamiczny przedmiot (również bez standardowego komponentu podnoszenia) albo żywą istotę/ciało. Wyklucza masywne cele — limit 80 jednostek masy silnika jest sprawdzany dla całej postaci, nie samego collidera. Nie wyrywa zamocowanych urządzeń, nie porusza statycznych dekoracji i nie zabiera rzeczy z ekwipunków ani podłączonych przewodów. Zasięg 300 jednostek gry; chwyt do 5 s, po wygaśnięciu 2 s przerwy dla tego samego celu.

Wszystkie funkcje ramienia są wzajemnie wykluczające. Wirniki i układ oddechowy działają osobno. Nienaruszona powłoka daje ochronę ustawioną na **10 000 m**, także bez baterii. To parametr natywnej ochrony, nie nieśmiertelność ani potwierdzony test na każdej głębokości.

Hełm odsłania się przy suchej głowie, bezpiecznym ciśnieniu i co najmniej 50% tlenu w pomieszczeniu. Wtedy obieg oddechowy nie pobiera energii. W wodzie lub nieoddychalnym środowisku hełm zamyka się, a zasilany zamknięty obieg dostarcza tlen **bez butli**. Bez energii obieg i latarki przestają działać. Kombinezon nie ma kary szybkości na lądzie ani narzuconych animacji ciężkiego skafandra.

Hełm i narzędzie mają prawdziwe latarki z cieniami. Ramię i wirnik są rysowane w świecie razem z postacią, przed oświetleniem i obróbką obrazu. Światła są usuwane po zdjęciu kombinezonu, zakończeniu rundy i restarcie LuaCs, również po pauzie.

AI używa tego samego kontrolera funkcji: widoczne zagrożenie, pilny przeciek, naprawa, ratowanie nieprzytomnej przyjaznej postaci. Natywny znacznik `divinggear_wearableindoors` pozwala botowi zachować kombinezon w bezpiecznych pomieszczeniach. Nawigacją i zwykłymi rękami nadal steruje silnik gry.

AI samo wymienia puste zasilanie i amunicję: najpierw z własnego ekwipunku, potem z dostępnych zapasów w tej samej łodzi, używając natywnego chodzenia do magazynów. Nie tworzy zasobów i nie zabiera ich innym postaciom, reaktorom ani zainstalowanym narzędziom. Wyszukiwanie ma limit czasu i odstęp ponowienia; zdjęcie kombinezonu anuluje jego pobieranie. AI rozpoznaje obieg bezbutlowy.

Przedmiot jest dostępny u sprzedawców badawczych i wojskowych oraz w fabrykatorze. Integracja z rzeczywistymi sklepami i reputacją Descendants pozostaje do dopasowania po udostępnieniu DLC; obecna wersja nie wymaga Home & Harbor.

## Zasoby

- [Nowy arkusz V2 — PNG](../MULTI-TOOL-V2/Assets/DescendantSuit/suit-v2.png): grafitowe płyty, czerwone panele, osłonięte przewody, cyjanowe optyki, kompaktowe ramię i wirnik. Starsze arkusze `suit.png` i `arm.png` zachowano jako źródła pierwszego prototypu.
- [Mapa wycinków](../MULTI-TOOL-V2/Assets/DescendantSuit/sprites.json). Gra i podgląd korzystają z prostokątów źródłowych, zachowując arkusze bez utraty przezroczystości.
- Osiem oryginalnych dźwięków OGG w `MULTI-TOOL-V2/Assets/DescendantSuit/Audio`: naprawa, spawanie, bojowy promień, chwytak, wirnik, serwo, hełm i przełącznik. Ponowne generowanie: `python tools/generate_descendant_audio.py` z dostępnym ffmpeg.
- V2 w grze odwołuje się do natywnego dźwięku lasera; nie skopiowano go do moda. Podgląd ma dodatkowy oryginalny krótki odsłuch `pulse.ogg`, generowany przez `python tools/generate_descendant_audio.py --only pulse`.
- Natywna warstwa uszczelniająca korzysta z istniejącej tekstury kombinezonu głębinowego gry; nie skopiowano jej do moda.
- [Pochodzenie i prompty](descendant-suit/ASSET-SOURCES.md).

## Korekta sylwetki i ramienia — 16 listopada 2026

- **528 testów**, **21/21 sprawdzeń w rzeczywistym Chrome**, walidacja **17 XML / 54 Lua 5.2** — poprawne.
- **3/3 prób natywnego klienta**: podniesione ramię w spoczynku z prawej strony, lustrzany widok z lewej oraz aktywne przyciąganie przedmiotu z widocznym ramieniem. [Wyniki](descendant-suit/slim-native.txt), [środowisko i sumy plików](descendant-suit/slim-verification.txt).
- Skala tułowia 0,82 → 0,60, hełmu 0,50 → 0,40; pozostałe płyty również zmniejszone. Segmenty ramienia 50/42 → 68/60, większa głowica. Dłuższe segmenty składają się w dotychczasowym promieniu roboczym 92; zasięgi funkcji nie zostały zwiększone.
- Wspólna pozycja spoczynkowa steruje rysowaniem i latarką narzędzia. Tekstura atlasu pozostała bez zmian; korekta dotyczy skali i ułożenia części. Przegląd nie znalazł problemów Critical/Important. Te próby wizualne dotyczą singleplayer; wcześniejsze wyniki multiplayer pozostają osobnym zapisem.

## Poprawka chwytaka — 16 listopada 2026

Podpowiedź w panelu pokazuje rzeczywiste klawisze celowania i użycia. Chwytak obejmuje również luźne obiekty bez komponentu standardowego podnoszenia. Limit masy dotyczy całej istoty.

- **528 testów automatycznych**, walidacja **17 XML / 54 modułów Lua 5.2** — poprawne.
- **6/6 prób w natywnym kliencie singleplayer**: masa człowieka i molocha, luźny obiekt bez `Pickable`, przechwycenie i fizyczne przyciąganie tego obiektu, rozwiązane nazwy klawiszy w panelu, przechwycenie żywego człowieka oraz puszczenie drugim naciśnięciem. Wejście symulowano przez natywne `SetInput` i pozycję kursora bez zmiany produkcyjnej logiki sterowania. [Wyniki](descendant-suit/grab-followup.txt), [panel](descendant-suit/grab-help.png), [środowisko i sumy plików](descendant-suit/grab-verification.txt).
- Natywny typ dynamicznego ciała to enum `FarseerPhysics.BodyType`, a nie tekst. Regresje i próba w grze obejmują tę reprezentację.
- Nowa paczka: `output/MULTI-TOOL-V2-descendant-v2-grab-2026-11-16.zip`. Poprzednia paczka V2 pozostaje zachowana. Poniższe próby multiplayer dotyczą wcześniejszego V2; poprawkę chwytaka sprawdzono osobno w singleplayer.

## Weryfikacja V2 — 16 listopada 2026

- **523 testy automatyczne**, **21 sprawdzeń podglądu**, walidacja **17 XML / 54 modułów Lua 5.2** — poprawne.
- **11/11 etapów z rzeczywistym podłączonym klientem**: dwa sloty, szybka naprawa z iskrami i pełne ukończenie, impulsy i zużycie amunicji, blokada pustej skrzynki, chwyt, oddychanie/pływanie, spawanie, wymiana zasobów z ekwipunku AI i pobranie z magazynów, wyłączenie latarek bez energii oraz stan przycisku. [Serwer](descendant-suit/v2-multiplayer-server.txt), [klient](descendant-suit/v2-multiplayer-client.txt).
- Natywna naprawa podniosła umiejętność elektryczną **20 → 22** i wywołała `OnRepairComplete` dokładnie raz. Po około 2 s stan urządzenia wzrósł z 10 do około 58; dalszy pomiar potwierdził pełną naprawę.
- Impulsy trafiły cel około **650 jednostek** od noszącego. Osobny obserwator potwierdził emisje natywnego śladu, automatyczne wywołania dźwięku i działające kanały audio. [Pomiar](descendant-suit/v2-pulse-visual.txt).
- Natywny obserwator restartu LuaCs potwierdził usunięcie **4/4 własnych świateł**. [Pomiar](descendant-suit/v2-light-cleanup.txt).
- Po `pauseClient + clear` obserwator również naliczył **4/4 usunięć świateł**: [pomiar po pauzie](descendant-suit/v2-light-pause.txt).
- Natywny serwer potwierdził wyjęcie i ponowne włożenie obu zasobów wykonane przez klienta: [energia](descendant-suit/v2-inventory-0.txt), [amunicja](descendant-suit/v2-inventory-1.txt). Pomiar modyfikatorów ruchu pokazał `WalkingSpeed=0`, `MovementSpeed=0`, przy ochronie 10 000: [wynik](descendant-suit/v2-movement.txt).
- Zrzuty z GPU z aktywnym oświetleniem gry: [naprawa i sloty](descendant-suit/v2-repair.png), [natywny impuls](descendant-suit/v2-pulse.png), [pływanie](descendant-suit/v2-water.png), [spawanie](descendant-suit/v2-weld.png), [brak energii w ciemności](descendant-suit/v2-dark.png).
- Przegląd znalazł dwa przypadki sprzątania: cel AI po zdjęciu kombinezonu i światła po pauzie. Oba poprawiono z regresjami RED/GREEN przed finalną próbą. Potwierdzono natywną ścieżkę nagród, nie każdy talent osobno.

## Archiwum weryfikacji pierwszego prototypu

Poniższe pomiary dotyczą wcześniejszej wersji z butlą i ciągłym promieniem. Pozostają zapisem historii, a nie instrukcją ani wynikiem V2.

- **505 testów automatycznych — OK**, pełny zestaw projektu. Regresje obejmują oddychanie klienta bez lokalnego pobierania tlenu, pauzę, pojedynczy tryb, zwalnianie chwytu, jego czas i ponowne przejęcie, nieprzytomną postać, filtry przenośnych rzeczy, AI, kontakt z właściwą sekcją ściany oraz rozpoczęcie pracy po dosunięciu ramienia. Dodatkowe pięć sprawdza obrót mocowania razem z tułowiem, interpolowaną pozycję rysowania i wybór pojedynczego celu chwytaka po kierunku celowania.
- **20 sprawdzeń podglądu — OK**. Składnia JavaScript i lokalne wczytanie w przeglądarce sprawdzone.
- Walidacja **17 XML / 49 modułów Lua 5.2**: odwołania, receptura, OGG, RGBA i wycinki tekstur poprawne.
- **11 prób na natywnym izolowanym serwerze — PASS**: prawdziwe sloty, brak podwójnego naliczania ochrony przez płyty, oddzielne źródła tlenu i energii, naprawa urządzenia, pręt, puste zasilanie, właściwości oddychania, wyszukiwanie celów, spawanie sekcji, siła chwytu żywej postaci i obrażenia promienia. [Surowe wyniki](descendant-suit/native-checks.txt).
- **Rzeczywisty włączony AI** utrzymał kombinezon i automatycznie naprawił urządzenie z 10 do 23,5. Pręt spadł do 99,7755; butla została na 200; hełm był otwarty, ochrona 10 000. [Wynik](descendant-suit/ai-check.txt).
- **Zanurzenie AI** zamknęło hełm, utrzymało dostępny tlen około 99,17 i zmniejszyło butlę do 199,3944. Wirniki pracowały, pręt spadł do 99,6981; postać żyła, ochrona wynosiła 10 000. [Wynik](descendant-suit/water-check.txt).
- **Finalny klient GPU działa**: obejrzano obie warstwy Wearable, 14 widocznych płyt, hełm w powietrzu i wodzie oraz ramię i wirniki. Poprawiono mocowanie do tułowia: obraca się z postacią podczas pływania i korzysta z interpolowanej pozycji rysowania. Wcześniejszy błąd inicjalizacji adaptera graficznego nie powtórzył się; nie przypisujemy tego poprawce moda. Zrzuty z rzeczywistego klienta: [naprawa](descendant-suit/gpu-repair.png), [chwytak](descendant-suit/gpu-grab.png), [pływanie](descendant-suit/gpu-water.png), [spawanie](descendant-suit/gpu-weld.png). Na potrzeby oglądu wyłączono oświetlenie i ograniczenie pola widzenia; po próbie przywrócono ustawienia.
- **8/8 etapów rzeczywistego multiplayera lokalnego — PASS**: dedykowany serwer i osobny podłączony klient, autorytet po stronie serwera. Sprawdzono replikację dwóch pojemników, naprawę urządzenia z iskrami, obrażenia bojowe, wskazanie i przyciągnięcie przedmiotu, zamknięcie hełmu i zużycie tlenu podczas pływania, wymianę baterii na pręt, odrzucenie próby sterowania cudzym kombinezonem, wyłączenie promienia oraz spawanie z replikacją stanu ściany i iskrami. [Wynik serwera](descendant-suit/multiplayer-server.txt), [wynik klienta](descendant-suit/multiplayer-client.txt).
- Próba wykryła i pozwoliła poprawić chwytak: natywna sieć gry przesyła kąt celowania, a serwer odtwarza kursor w stałej odległości 500 jednostek. Wybór celu wzdłuż kierunku działa teraz jednakowo lokalnie i w sieci; serwer nadal sprawdza zasięg, widoczność i dostępność celu. Początkowe nieudane przebiegi ujawniły też konkurujące cele pozostawione przez wcześniejsze próby. Scenariusz usuwa je i osobno sprawdza przyciągnięcie właściwego przedmiotu.

Nie przeprowadzono próby Steam P2P, wielu klientów z dużym opóźnieniem, rzeczywistej granicy 10 km ani pełnych kombinacji modowych ragdolli, efektów i talentów. Lokalny multiplayer obejmuje jeden sterowany klient i kontrolowane cele testowe, a nie długą kampanię. Automatyczne ratowanie botem ma test reguł; fizyczny chwyt żywej postaci sprawdzono osobno na serwerze.

Próby dotyczyły wyłącznie odrębnych katalogów `.runtime/descendant-native` i `.runtime/descendant-client`. Instalacja Steam i kampania użytkownika nie zostały zmienione.
