# Dwuręczny multitool bojowy — projekt

Data: 2026-10-30. Status: projekt do zatwierdzenia przed implementacją.

## Cel i uzgodnienia

Rozszerzyć istniejący mod o osobny, futurystyczny multitool bojowy. Ma zajmować
obie ręce podczas używania i jeden zwykły slot podczas przenoszenia, zachowując
funkcje techniczne mniejszego multitoola. Użytkownik zaakceptował emitowanie
pierścieni energii i zależność od Lua for Barotrauma. Dodatkowo wymaga rykoszetów
zależnych od jakości oraz prawidłowego przełączania zadań przez boty.

Wymagania użytkownika:

- Wytwarzanie z obecnego multitoola i dodatkowych surowców.
- Dwa dostępne sloty zasilania: slot 1 — broń i funkcje techniczne,
  slot 2 — generator tarczy. Baterie i pręty są prawidłowymi źródłami.
- Pierścienie energii odbijają się od ścian i innych twardych przeszkód;
  wyższa jakość daje więcej odbić.
- Podczas celowania przed bronią pojawia się lekko zakrzywiona tarcza,
  osłaniająca tułów i głowę, oraz mocne światło w kierunku celowania.
- Tarcza przechwytuje wrogie strzały i lekko poraża przeciwnika, który w nią
  wejdzie. Zużywa energię przy trafieniach; porażenie ma kosztować więcej
  niż przechwycenie zwykłego pocisku.
- Pozostają trzy dotychczasowe checkboxy. Wyłączenie obrażeń NPC blokuje
  strzelanie i tarczę, także dla botów.
- Boty rozpoznają przedmiot jako broń i narzędzie, uzupełniają oba sloty,
  strzelają podczas walki i naprawiają/spawają podczas odpowiednich zadań.
  Nie mogą uruchamiać wszystkich funkcji jednocześnie.
- Potrzebne są grafika broni i animacje: aktywna tarcza, trafienie w tarczę,
  zniszczenie tarczy oraz porażenie przy kontakcie.

Parametry oznaczone dalej jako decyzje projektowe są propozycjami wykonawcy,
nie dodatkowymi wymaganiami użytkownika. Balans będzie zapisany w jednym miejscu
i możliwy do zmiany po testach.

## Podejścia i wybrana architektura

1. Sam XML: dobrze opisuje przedmiot, recepturę i zwykłe funkcje narzędziowe.
   Nie wybieramy go do całego zadania, ponieważ nie zapewnia sam z siebie
   zaprojektowanej kontroli rykoszetów, przechwytywania strzałów i arbitrażu AI.
2. XML + Lua for Barotrauma: wybrane przez użytkownika. XML opisuje komponenty
   rozpoznawane przez grę, a Lua steruje trybem, pociskami, tarczą, zasilaniem
   i synchronizacją. Korzysta z API i mechanizmu patchowania udostępnianego
   przez LuaCs, bez osobnej kompilowanej biblioteki C#.

Nowy przedmiot powstanie obok istniejącego w pakiecie MULTI-TOOL-V2,
z własnymi identyfikatorami. Obecny multitool i jego zapisy pozostają zgodne.
Skrypty mają działać tylko na nowych identyfikatorach. Nowe funkcje wymagają
zgodnego Lua for Barotrauma na serwerze i klientach; single player uruchamia
tę samą autorytatywną logikę lokalnie.

Manifest obecnie deklaruje Barotrauma 1.10.7.2. Odczyt lokalnej instalacji
w D:/SteamLibrary/steamapps/common/Barotrauma wykazał klienta i serwer
1.13.5.0 oraz obecność katalogu Lua, LuaCsSetupConfig.xml i MoonSharp.
Pierwszym celem zgodności jest dostępna wersja 1.13.5.0; samo istnienie
plików nie potwierdza uruchomienia Lua. Przed implementacją trzeba sprawdzić
wersję i działanie LuaCs, dobrać zgodny zestaw i zapisać dokładne wersje
w instrukcji testów. Kod z gałęzi master gry jest materiałem do analizy,
a nie dowodem zgodności ze starszą wersją.

## Jeden tryb wykonawczy na raz

Każda broń ma dokładnie jeden tryb: bezczynność, walka, spawanie, cięcie,
gaszenie albo naprawa urządzenia. Za wybór odpowiada jeden kontroler.
Każde wywołanie strzału lub komponentu technicznego ponownie sprawdza ten tryb
przed efektem i pobraniem energii. Sama zmiana wyglądu lub CharacterUsable
nie wystarcza jako zabezpieczenie.

Tarcza jest funkcją obronną, oddzielną od trybu wykonawczego: przy włączonych
obrażeniach i celowaniu może chronić również podczas spawania. Nie uruchamia
strzałów ani innych narzędzi. Latarka działa podczas celowania także przy
wyłączonych obrażeniach, jeśli slot 1 ma zasilanie.

### Sterowanie gracza

Pozostają checkboxy przecinarki, gaśnicy i obrażeń NPC, bez dodatkowego
obowiązkowego przełącznika. Proponowana reguła wyboru po naciśnięciu użycia:

1. Otwarta naprawa urządzenia: tylko naprawa mechaniczna/elektryczna;
   spust bojowy i efekty spawania są zablokowane.
2. Włączona gaśnica: tylko gaszenie.
3. Włączone obrażenia, gaśnica wyłączona: tylko pierścienie.
4. Obrażenia wyłączone: spawanie albo cięcie według checkboxa przecinarki.

Wyłączenie obrażeń anuluje ładowanie, wygasza tarczę i usuwa z lotu
pierścienie wystrzelone przez tę broń, aby blokada działała od razu.
Domyślnie obrażenia są wyłączone, jak w mniejszej wersji.

### Boty: zadanie decyduje o funkcji

Bot nie zgaduje trybu po samym kierunku celowania ani obecności przeciwnika
w pobliżu. Liczy się rzeczywiście wykonywane zadanie, w tym jego aktywne
podzadanie; samo zlecenie naprawy w kolejce nie uruchamia spawarki.

| Wykonywane zadanie | Dozwolona funkcja | Wyłączone funkcje |
| --- | --- | --- |
| Walka z prawidłowym celem, obrażenia włączone | Pierścienie; tarcza podczas celowania | Wszystkie narzędzia |
| Uszczelnianie kadłuba | Spawanie | Pierścienie, cięcie, gaśnica |
| Naprawa mechaniczna/elektryczna | Odpowiednia naprawa | Pierścienie i wszystkie strumienie |
| Gaszenie | Gaśnica | Pierścienie, spawanie, cięcie |
| Zadanie wymagające przecinarki | Cięcie | Pierścienie, spawanie, gaśnica |
| Brak rozpoznanego zadania | Bezczynność | Wszystkie funkcje wykonawcze |

Bot może tymczasowo dobierać funkcję techniczną do zadania niezależnie od
ustawienia checkboxów przecinarki/gaśnicy. Nie nadpisuje zapisanych preferencji
gracza. Checkbox obrażeń pozostaje bezwzględną zgodą na strzał i tarczę;
bot nigdy sam go nie włącza. Przy wyłączonych obrażeniach nie wybiera tego
multitoola do walki i korzysta z innej dostępnej broni.

Decyzja projektowa: do walki potrzebny jest tylko sprawny slot 1.
Pusty slot 2 oznacza brak tarczy, a nie niezdolność do strzału.
W sytuacji bezpośredniego zagrożenia bot walczy dostępną bronią zamiast
przerywać obronę na poszukiwanie baterii do tarczy. Uzupełnianie tarczy
odbywa się w bezpiecznej przerwie; źródło dla slotu 1 ma pierwszeństwo.

Obsługa przeładowania ma rozróżniać indeksy slotów. Ogólne sprawdzenie
„w środku jest bateria” nie dowodzi zasilania obu systemów. Bot używa dwóch
różnych przedmiotów, usuwa puste źródło z właściwego slotu i wkłada nowe
z własnego ekwipunku lub dostępnego magazynu, z zachowaniem normalnego
dostępu, odległości i ścieżki. Nie teleportuje surowców ze schowków,
nie powiela ich i nie zużywa pręta z reaktora. Niedostępne zasilanie kończy
próbę po ograniczonym czasie i nie tworzy nieskończonej pętli zadania.

Przejęcie bota przez gracza, oddanie przedmiotu i zmiana zadania natychmiast
unieważniają poprzedni wybór funkcji i częściowo naładowany strzał.

## Pierścienie i rykoszety

Decyzje projektowe dla pierwszej wersji:

| Jakość gry | Maksymalna liczba odbić jednego pierścienia |
| --- | --- |
| Zwykła, poziom 0 | 1 |
| Dobra, poziom 1 | 2 |
| Doskonała, poziom 2 | 3 |
| Mistrzowska, poziom 3 | 4 |

Limit jest odczytywany przy wystrzale; późniejsza zmiana jakości nie zmienia
pierścienia w locie. Parametry spoza standardowego zakresu są ograniczane
do poziomów 0–3.

Pierścień jest widocznym, wirującym impulsem o skończonej prędkości.
Ładowanie trwa początkowo 0,25 s, odstęp między strzałami 0,65 s,
prędkość 1400 jednostek świata/s, czas życia maksymalnie 2,5 s,
łączna droga maksymalnie 3200 jednostek. Rozszerzenie wizualne podczas lotu
jest łagodne; promień kolizji wzrasta od 6 do maksymalnie 12 jednostek.
Parametry podlegają dostrojeniu w grze.

Odbija się od nienaruszonych części ścian i kadłuba, podłoża oraz zamkniętych
drzwi/włazów. Otwarte drzwi i rzeczywiste dziury przepuszczają impuls.
Nie odbija się od drobnych przedmiotów ani postaci; trafienie postaci
kończy lot i wywołuje pojedyncze, miejscowe wyładowanie.
Impuls nie niszczy kadłuba ani urządzeń. Podstawowe obrażenia do dostrojenia:
18 oparzeń i 12 urazu obuchowego; bez eksplozji obszarowej.

Kierunek odbicia wynika z normalnej trafionej powierzchni. Każde odbicie
zmniejsza obrażenia o 15% względem poprzedniej wartości i daje krótki błysk.
Po wykorzystaniu limitu następny kontakt z przeszkodą wygasza impuls.
Odbicia nie pobierają dodatkowej energii z broni.

Kolizje są sprawdzane na całej przebytej w danej aktualizacji drodze,
z uwzględnieniem promienia impulsu i najbliższego kontaktu. Pozostała droga
po odbiciu jest rozpatrywana w tej samej aktualizacji. Zapobiega to
przenikaniu przez ściany przy niskiej liczbie klatek i podwójnym odbiciom
w narożnikach. Obowiązuje limit kontaktów na krok symulacji; po jego
osiągnięciu pocisk wygasa. Obliczenia uwzględniają układy współrzędnych
wnętrza/otoczenia i ruch łodzi, również przy przejściu przez wyłom.

Decyzja projektowa: pierścienie pomijają strzelca i sojuszników, także po
odbiciu. Zapobiega to przypadkowemu ostrzeliwaniu załogi przez boty.
Nie przechodzą przez wrogie aktywne tarcze. Tarcza własnej broni przepuszcza
własny impuls; kontakt z tarczą przeciwnika pochłania go, bez rykoszetu.
Boty celują bezpośrednio; obliczanie celowych strzałów zza rogu nie jest
wymagane. Rykoszety działają tak samo dla strzałów graczy i botów.

## Tarcza

Tarcza jest wycinkiem łuku, wypukłym w stronę celowania, osadzonym przed
emiterem. Jej rozmiar i przesunięcie zostaną dopasowane do głowy i tułowia
humanoida w pozycji stojącej, kucającej i podczas pływania. Obraca się wraz
z bronią. Grafika i rzeczywisty obszar przechwytywania muszą się pokrywać.
Nie wystaje przez zamkniętą ścianę na drugą stronę; przeszkoda ogranicza
widoczny i działający obszar.

Warunki aktywacji: nowa broń jest w obu rękach żywego, przytomnego użytkownika,
użytkownik celuje, broń jest sprawna, obrażenia są włączone, slot 2 ma energię
i minął czas blokady po przeciążeniu. Slot 1 nie jest wymagany do tarczy.
Utrata dowolnego warunku natychmiast wyłącza ochronę.

Przechwycenie obejmuje standardowe fizyczne pociski i strzały hitscan
przecinające przednią powierzchnię tarczy przed trafieniem postaci.
Własne pierścienie używają tego samego testu geometrii. Zniszczenie pocisku
następuje przed jego zwykłymi obrażeniami, a dany strzał jest rozliczany raz.
Obsługa hitscan musi działać na ścieżce rozstrzygania trafienia, a nie wyłącznie
w aktualizacji klatkowej. Tarcza nie daje odporności na ataki od tyłu,
ciśnienie, trucizny, ogień otoczenia ani wybuchy obok postaci.
Pełna zgodność z dowolnym skryptowym laserem z innego moda jest poza zakresem.

Energia slotu 2 jest jedynym zapasem tarczy; przy trafieniu spada wskazanie
źródła i jasność/stabilność efektu. Brak oddzielnej, regenerowanej za darmo
puli punktów życia. Proponowane koszty w punktach procentowych baterii:

- Podtrzymanie podczas celowania: 0,1/s.
- Zablokowanie pocisku: koszt zależny od potencjalnych obrażeń,
  ograniczony do 1–4 punktów; zwykły pocisk około 2 punktów.
- Kontakt przeciwnika: 6 punktów, lekkie oparzenie i krótkie ogłuszenie.
  Jeden przeciwnik może uruchomić kontakt najwyżej raz na 0,75 s,
  także jeśli pozostaje w tarczy. Dla prętów proporcje kosztów są identyczne.

Decyzja projektowa: jeśli energii nie wystarcza na dany kontakt, tarcza
zużywa resztę i pęka. Nie blokuje tego pocisku i nie aplikuje darmowego
porażenia. Przy dokładnie wystarczającej energii blokuje/razi, po czym pęka.
Po pęknięciu obowiązuje blokada przez 3 s; wymiana źródła, odłożenie broni
i ponowne celowanie nie omijają blokady.

Wrogie postacie są ustalane według relacji gry, z uwzględnieniem potworów,
wrogich ludzi i trybu PvP, a nie wyłącznie nazwy gatunku. Właściciel
i sojusznicy nie są rażeni. Dla standardowego pocisku z nieznanym strzelcem
decyzja projektowa to blokada, jeśli przylatuje z zewnątrz na przednią stronę
tarczy. Sojusznicze pociski o znanym strzelcu są przepuszczane.

## Zasilanie i funkcje techniczne

Dwa widoczne sloty mają stałą kolejność i podpisy „Narzędzia / broń” oraz
„Tarcza”. Każdy przyjmuje jeden przedmiot z tagiem mobilebattery lub
reactorfuel. Butle tlenowe i paliwo spawalnicze pozostają obsługiwane przez
starszy multitool; nowa wersja wykonuje prace elektrycznie.

Zużycie dotyczy wyłącznie źródła z właściwego slotu, nie wszystkich
zawartych baterii/prętów. Brak energii blokuje tylko zależną funkcję.
Źródła nie są ładowane przez samą broń. Obowiązują nieujemne wartości,
kontrola pełnego kosztu przed strzałem i pojedyncze rozliczenie na serwerze.
Początkowo strzał kosztuje 1 punkt baterii, prace 0,2 punktu/s;
pręty zużywają 1/4 kosztu baterii. Ten sam współczynnik dotyczy tarczy.

Spawanie, cięcie, gaśnica i zwykłe naprawy korzystają z istniejących
rozpoznawalnych przez AI komponentów/tagów i efektów cząsteczkowych.
Mocne światło podczas celowania: początkowo zasięg 1100, jasność 1,5,
stożek 40 stopni, dostrojenie do czytelności w grze. Pobór światła zawiera
się w niewielkim koszcie podtrzymania ze slotu 1; ostateczna wartość
w konfiguracji. Naprawa urządzenia zachowuje standardową mechanikę gry
i nie powoduje wystrzału ani strumienia spawalniczego.

## Wytwarzanie i noszenie

Proponowana receptura: 1 obecny Multi-toolSET, 2 stopy tytanowo-aluminiowe,
2 miedzi, 1 FPGA i 1 fulgurium; fabrykator lub fabrykator wojskowy,
30 s, mechanika 50 i elektryka 40. Identyfikatory surowców zostaną sprawdzone
w docelowej wersji gry. Baterie/pręty z wejściowego multitoola muszą zostać
bezpiecznie wyjęte lub zachowane przez fabrykację; nie mogą zniknąć.

Broń wymaga obu rąk; próba jednoczesnego trzymania drugiego przedmiotu
nie może pozostawić jej w używalnym stanie. Przenoszenie w zwykłym slocie
zawsze wyłącza tarczę i światło. Dekonstrukcja nie zwraca całego wejściowego
multitoola i wszystkich surowców, aby nie tworzyć pętli zasobów; odzysk
materiałów dobierze wykonawca. Zawarte źródła mają zostać bezpiecznie zwrócone.

## Grafika i dźwięk

Nowy sprite i ikona: widok boczny, futurystyczna broń techniczna, wyraźny
chwyt na dwie ręce, oddzielne moduły zasilania i emiter tarczy. Styl ma być
czytelny przy skali sprite'ów Barotraumy i wizualnie spójny z narzędziem.

Własne pliki PNG z kanałem alfa oraz animacje z klatek:

- Pierścień energii, ładowanie i błysk rykoszetu.
- Zapętlona, lekko pulsująca tarcza.
- Miejscowa fala trafienia na tarczy.
- Rozpad tarczy przy przeciążeniu.
- Krótkie łuki elektryczne przy kontakcie wroga.

Dokładna liczba klatek i rozdzielczość są decyzją wykonawcy, pod warunkiem
płynnej animacji, stałych punktów zakotwiczenia i zgodności grafiki z kolizją.
Efekty bazowych narzędzi oraz tool.ogg można wykorzystać ponownie.
Wszystkie używane assety muszą być wewnątrz pakietu moda.

## Logika, synchronizacja i cykl życia

Kontroler Lua posiada osobne moduły wyboru trybu, AI, zasilania, lotu
pierścieni, tarczy oraz efektów. Publiczne elementy pozostają opisane w XML:
przedmiot, receptura, pojemnik, UI, klasyfikacja broni i narzędzi, tłumaczenia.
Przypięcie do RangedWeapon zapewnia rozpoznawanie przez AI; sposób wywołania
strzału i potrzebne patche zostaną sprawdzone dla wybranego runtime.
Wbudowane pobieranie zwykłej amunicji nie może blokować energetycznego strzału
ani tworzyć pustych, nieskończonych przeładowań.

Serwer rozstrzyga zadania botów, strzały, tor, odbicia, trafienia, stan tarczy,
zużycie i obrażenia. Klient zgłasza użycie/zmianę ustawienia własnej trzymanej
broni; serwer sprawdza właściciela, obie ręce, stan, tryb, czas i energię.
Klient nie przesyła wiążących obrażeń, jakości ani liczby odbić.
Klienci odtwarzają efekty z autorytatywnych zdarzeń i okresowych korekt.
Przełączenie checkboxa i zużycie źródeł są widoczne dla wszystkich.

Powtarzane żądania nie mogą dawać dodatkowego strzału/zużycia. Identyfikatory
zdarzeń i instancji broni zapobiegają odtwarzaniu starego stanu po usunięciu
przedmiotu. Dołączenie w trakcie rundy dostarcza aktualny stan tarczy
i żywych pierścieni. Zejście z celowania usuwa ochronę natychmiast na serwerze.
Przy oddaniu/usunięciu broni, śmierci, zakończeniu rundy i ponownym ładowaniu
skryptów czyści się referencje, timery i efekty. Każda instancja ma własny stan.

Zapis zachowuje przedmiot, jakość, zawartość slotów i preferencje checkboxów.
Lot pocisków i częściowe ładowanie są ulotne. Wczytanie zapisu nie odtwarza
aktywnej tarczy przed weryfikacją celowania i zasilania. Jeśli Lua nie działa,
nowa broń ma pozostać bierna i wyświetlić zrozumiałą informację o zależności.

## Kryteria odbioru

Testy logiki obejmują geometrię odbić i tarczy, limity według jakości,
rozdzielenie źródeł, wykluczanie trybów i walidację żądań. Nie zastępują
prób w działającej grze. Wymagany scenariusz integracyjny:

1. Wytworzenie, oba uchwyty, przenoszenie i poprawne przypisanie zasilania.
2. Każda z czterech jakości: dokładnie odpowiedni limit rykoszetów, ściana,
   narożnik, drzwi otwarte/zamknięte, uszkodzony kadłub, wnętrze i woda.
3. Brak przebijania ścian przy dużym kroku symulacji i brak uszkodzeń kadłuba.
4. Strzał, spawanie, cięcie, gaszenie i naprawa oddzielnie; w danej próbie
   tylko właściwy efekt, tylko właściwy pobór i właściwe skutki na celu.
5. Bot z pustymi slotami: pobiera dwa źródła, wkłada we właściwe miejsca,
   wymienia puste. Nie zabiera źródła z reaktora ani z innej postaci.
6. Bot: naprawa urządzenia → uszczelnianie → walka → powrót do naprawy.
   Powtórzyć ze zmianą zadania podczas ładowania i z checkboxami ustawionymi
   inaczej niż wymaga zadanie. Nigdy nie występują równoległe funkcje.
7. Bot z wyłączonymi obrażeniami nie strzela i nie aktywuje tarczy;
   wybiera inną dostępną broń. Pusty slot tarczy nie blokuje strzelania.
8. Tarcza: standardowy pocisk fizyczny, hitscan i wrogi pierścień; z przodu
   blokada, od tyłu trafienie. Sprawdzić stanie, kucanie, pływanie, obrót
   i przeszkodę przed emiterem. Brak podwójnego naliczania trafienia.
9. Kontakt wroga daje lekkie porażenie, odstęp 0,75 s i większy koszt niż
   przechwycenie pocisku; sojusznik przechodzi bez porażenia.
10. Ostatnia energia, przeciążenie, wymiana źródła i blokada ponownej aktywacji.
11. Wyłączenie obrażeń w locie, zmiana właściciela, odłożenie, śmierć,
    zapis/wczytanie, koniec rundy i wiele broni jednocześnie.
12. Single player oraz serwer z dwoma klientami: wspólny stan i grafika,
    jednokrotne obrażenia/zużycie, dołączenie w trakcie i powtarzane żądania.

Brak uruchomionej gry lub serwera oznacza brak potwierdzenia odpowiednich
scenariuszy; nie wolno opisywać samej walidacji XML/Lua jako dowodu działania AI.

## Otwarte decyzje wykonawcze i granice

Wykonawca dobiera dokładne hooki zgodne z runtime, format wiadomości,
układ plików, rozdzielczości i klatki, brzmienie, drobny balans i pozycje
uchwytów. Nie wymaga to osobnych uzgodnień, o ile zachowuje powyższe zachowanie.
Jeśli wybrany runtime nie udostępnia ścieżki przechwycenia hitscan przed
obrażeniami lub dostępu do właściwego zadania AI, trzeba zgłosić konkretny
problem zgodności; nie zastępować ochrony animacją ani arbitrażu losowym trybem.

Poza zakresem: autonomiczne planowanie rykoszetów przez boty, nowe talenty,
publikacja Workshop, zmiana starszego multitoola oraz pełna zgodność
z każdą skryptową bronią z innych modów.

## Źródła techniczne do planowania

- Istniejące definicje: MULTI-TOOL-V2/tool.xml i filelist.xml.
- [Kod wyboru broni i przeładowania AI](https://github.com/FakeFishGames/Barotrauma/blob/master/Barotrauma/BarotraumaShared/SharedSource/Characters/AI/Objectives/AIObjectiveCombat.cs).
- [Kod RangedWeapon](https://github.com/FakeFishGames/Barotrauma/blob/master/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Holdable/RangedWeapon.cs).
- [Kod Projectile, w tym hitscan](https://github.com/FakeFishGames/Barotrauma/blob/master/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Projectile.cs).
- [LuaCsForBarotrauma](https://github.com/evilfactory/LuaCsForBarotrauma).

Źródła upstream mogą zmieniać się niezależnie od docelowego runtime;
plan implementacji ma wskazać zweryfikowaną wersję.

## Przegląd projektu

Niezależny przegląd pod kątem możliwości zaplanowania implementacji
nie wykazał istotnych pytań wymagających doprecyzowania. Nie jest to
weryfikacja działania w grze ani zatwierdzenie projektu przez użytkownika.
