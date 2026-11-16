# Kombinezon serwomanipulacyjny Descendants

Pierwsza wersja robocza dla Barotrauma 1.13.5.0 / LuaCs c6e8829. Identyfikator przedmiotu: `descendantservosuit`.

[Otwórz animowany podgląd](descendant-suit/index.html). Działa lokalnie, bez instalowania bibliotek. Pokazuje oba stany hełmu, ramię, kolory promieni, iskry, wirniki i odsłuch ośmiu dźwięków. To demonstracja zasobów; nie zastępuje próby w grze.

## Używanie

Załóż kombinezon w slocie ubrania zewnętrznego. Pierwszy pojemnik mieści butlę tlenową, drugi baterię lub pręt reaktora. Zasilanie ramienia nie wymaga trzymania narzędzia w ręce. Panel po prawej stronie pozwala wybrać jedną funkcję:

- **Naprawa / spawanie**: automatycznie wybiera pobliskie uszkodzone urządzenie albo sekcję ściany. Ramię dosuwa emiter, następnie uruchamia krótki niebieski promień. Silne, ograniczone liczbowo iskry powstają w punkcie naprawy. Widoczny pilny przeciek ma pierwszeństwo; rozpoczęta poprawna naprawa urządzenia zachowuje cel.
- **Obrona**: ciągły czerwony promień atakuje jeden widoczny wrogi cel w dowolnym kierunku. Natywne zasady AI rozpoznają załogę, przyjaznych NPC i zwierzęta. Ściana, zamknięte drzwi lub postać stojąca na linii strzału blokują ostrzał.
- **Chwytak**: celuj i naciśnij użycie, aby przechwycić pierwszy poprawny widoczny cel wzdłuż kierunku celowania, w zasięgu 300 jednostek gry. Wymaga przytrzymania celowania podczas kliknięcia. Kolejne naciśnięcie lub zmiana funkcji zwalnia chwyt. Obsługuje pojedynczy przenośny przedmiot, postać lub małe stworzenie. Nie wyciąga rzeczy z ekwipunków ani podłączonych przewodów. Chwyt ma limit czasu, masy i prędkości, a powtórne przechwycenie tego samego celu wymaga krótkiej przerwy.

Wszystkie funkcje ramienia są wzajemnie wykluczające. Wirniki i układ oddechowy działają osobno. Nienaruszona powłoka daje ochronę ustawioną na **10 000 m**, także bez baterii. To parametr natywnej ochrony, nie nieśmiertelność ani potwierdzony test na każdej głębokości.

Hełm odsłania się przy suchej głowie, bezpiecznym ciśnieniu i co najmniej 50% tlenu w pomieszczeniu. Wtedy butla nie jest zużywana. W wodzie lub nieoddychalnym środowisku hełm się zamyka i potrzebna jest niepusta butla. Zużycie wynosi 0,3 punktu stanu butli na sekundę; postacie niewymagające powietrza nie zużywają butli. Utrata zasilania nie tworzy darmowego tlenu.

AI używa tego samego kontrolera funkcji: widoczne zagrożenie, pilny przeciek, naprawa, ratowanie nieprzytomnej przyjaznej postaci. Natywny znacznik `divinggear_wearableindoors` pozwala botowi zachować kombinezon w bezpiecznych pomieszczeniach. Nawigacją i zwykłymi rękami nadal steruje silnik gry.

Przedmiot jest dostępny u sprzedawców badawczych i wojskowych oraz w fabrykatorze. Integracja z rzeczywistymi sklepami i reputacją Descendants pozostaje do dopasowania po udostępnieniu DLC; obecna wersja nie wymaga Home & Harbor.

## Zasoby

- [Kombinezon — PNG](../MULTI-TOOL-V2/Assets/DescendantSuit/suit.png): oryginalny arkusz RGBA z zamkniętym/otwartym hełmem i częściami pancerza.
- [Ramię i efekty — PNG](../MULTI-TOOL-V2/Assets/DescendantSuit/arm.png): segmenty, emitery, trzy promienie, efekty kontaktu i cztery klatki wirnika.
- [Mapa wycinków](../MULTI-TOOL-V2/Assets/DescendantSuit/sprites.json). Gra i podgląd korzystają z prostokątów źródłowych, zachowując arkusze bez utraty przezroczystości.
- Osiem oryginalnych dźwięków OGG w `MULTI-TOOL-V2/Assets/DescendantSuit/Audio`: naprawa, spawanie, bojowy promień, chwytak, wirnik, serwo, hełm i przełącznik. Ponowne generowanie: `python tools/generate_descendant_audio.py` z dostępnym ffmpeg.
- Natywna warstwa uszczelniająca korzysta z istniejącej tekstury kombinezonu głębinowego gry; nie skopiowano jej do moda.
- [Pochodzenie i prompty](descendant-suit/ASSET-SOURCES.md).

## Weryfikacja — 16 listopada 2026

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
