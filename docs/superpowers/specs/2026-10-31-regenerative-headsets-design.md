# Komunikatory regeneracyjne Aegis — projekt do zatwierdzenia

Data: 2026-10-31. Status: projekt po niezależnym przeglądzie, do zatwierdzenia,
bez implementacji. Przegląd wykonawczy: brak istotnych pytań otwartych.

## Cel i ustalenia użytkownika

Dodać do istniejącego MULTI-TOOL-V2 dwa urządzenia zajmujące slot słuchawek.
Oba mają działać komunikacyjnie dokładnie jak zwykły komunikator, mieścić
wymienną baterię, chronić przed ciśnieniem kosztem energii i stopniowo usuwać
wszystkie negatywne następstwa zdrowotne. Użytkownik potwierdził pełną
regenerację, włącznie z utraconymi kończynami i organami, oraz dodanie do
obecnego pakietu. Lepsza wersja dodatkowo pochłania trafienia za energię.
Boty wymieniają słabą baterię. Potrzebne są własne grafiki urządzeń, czerwony
migoczący efekt osłony i dźwięki trafień informujące o poziomie zasilania.

## Podejścia

1. **Rozszerzenie obecnego pakietu XML + LuaCs — wybrane przez użytkownika.**
   Natywne komponenty komunikatora i pojemnika, logika ochrony, regeneracji,
   AI i synchronizacji w Lua. Współdzielenie sprawdzonych mechanizmów obecnego
   Aegisa tam, gdzie ich zakres odpowiada nowym urządzeniom.
2. Osobny pakiet XML + LuaCs: takie same możliwości, ale dodatkowy pakiet do
   instalacji i utrzymania. Użytkownik wybrał istniejący pakiet.

Sam XML nie zapewnia ogólnej regeneracji stanów skryptowych i anatomii.
Zerowanie wszystkich afflictions nie jest prawidłowym leczeniem: niektóre
przechowują korzystne efekty albo fizjologię, której prawidłowa wartość nie
wynosi zero. Dlatego wybrany wariant wymaga ogólnego mechanizmu leczenia oraz
integracji dla modów zapisujących zdrowie poza zwykłymi urazami.

## Urządzenia i komunikacja

Proponowane nazwy: **Komunikator regeneracyjny Aegis** (`aegisheadset`)
i **Komunikator osłonowy Aegis** (`aegisheadsetmk2`). Nazwy są decyzją wykonawcy.
Każdy ma jeden slot na ogniwo zgodne z `mobilebattery`, bez prętów paliwowych.
Są oddzielnymi nowymi przedmiotami; zwykłe słuchawki nie są nadpisywane.

Zachować natywny WifiComponent zwykłego headsetu: zasięg 35000,
LinkToChat, kanał, zakłócenia i brak wymogu baterii do komunikacji. Bateria
zasila dodatkowe funkcje. Zwykłe sloty Any/Headset, możliwość noszenia razem
z hełmem i skafandrem. Ochrona działa tylko po założeniu w slot Headset,
również przy nieprzytomności. Samo noszenie w plecaku jej nie uruchamia.

## Energia i ochrona przed ciśnieniem

Wszystkie funkcje używają tego samego rzeczywistego ogniwa. Nie odtwarzać
baterii i nie zastępować jej ukrytym zasobnikiem. Koszty w konfiguracji Lua,
wyrażone jako procent pełnego standardowego ogniwa.

Propozycje wykonawcy do pierwszych testów:

- Ciśnienie: 5 punktów procentowych na sekundę, około 20 s na pełnej baterii
  bez jednoczesnego leczenia i trafień. Pobór tylko wtedy, gdy postaci
  rzeczywiście grozi ciśnienie po uwzględnieniu skafandra i otoczenia.
- Leczenie: wspólny limit 5 jednostek siły urazów na sekundę i koszt
  0,5 punktu procentowego na usuniętą jednostkę. Zapobiega to darmowemu
  leczeniu setek efektów jednocześnie. Kolejność: stany zagrażające życiu,
  krwawienie i obrażenia, następnie pozostałe choroby i zatrucia.
- Odtworzenie organu: 15 punktów procentowych i 5 sekund; kończyny:
  25 punktów i 10 sekund. Koszt pobierany stopniowo; odtworzenie dopiero po
  opłaceniu całego procesu. Postęp przypisany do postaci i konkretnej części,
  bez przenoszenia go na inne cele lub pozostałych po nich przedmiotów.
- Wersja Mk II: koszt trafienia `max(1, 0.5 * siła obrażeń)` punktu
  procentowego. Koszt rośnie z siłą, a każde skuteczne uderzenie zużywa prąd.

Energia nie schodzi podczas bezczynnego noszenia bez zagrożeń ani urazów.
Na granicy wyczerpania zapewniać tylko opłaconą część ochrony lub leczenia;
pozostałe obrażenia przechodzą. Nie dawać pełnej ochrony za resztkę baterii.
Ochrona przed ciśnieniem musi działać przed natywną implozją, a nie przez
leczenie po śmierci. Wyczerpanie i zdjęcie urządzenia przywraca zwykłe zasady
ciśnienia, bez pozostawienia trwałej odporności. Bez dodatkowego wymogu
zatwierdzenia dobór konkretnego hooka i obsługa niepełnego ostatniego kroku
należy do wykonawcy po analizie źródeł gry.

## Leczenie i pełna regeneracja

Obie wersje leczą istniejące negatywne skutki, także sprzed założenia.
Podstawą jest przegląd faktycznych afflictions postaci i kończyn, zamiast
zamkniętej listy identyfikatorów podstawowej gry. Zachować korzystne efekty,
talenty, genetykę i prawidłowe stany organizmu. Nie przywracać do życia
martwych postaci; użytkownik zamówił regenerację żywego użytkownika.

Osobna integracja Neurotrauma odtwarza brakujące organy i kończyny, zamyka
operacyjne uszkodzenia i przywraca fizjologię do wartości zdrowych. Nie usuwa
sprawnych protez ani cybernetycznych ulepszeń tylko dlatego, że są efektami.
Integracja ładuje się warunkowo: brak NT nie psuje podstawowej gry.
Wykonawca ustala bezpieczne API i wykrywanie wersji na podstawie kodu NT.
Lokalnie wykryto **Neurotrauma CS 2.0.7**, Workshop `3744761298`;
to podstawowy cel integracji i testów. Klasyczny Neurotrauma Lua oraz jego
rozszerzenia wymagają osobnej weryfikacji, bez deklarowania zgodności z góry.

Cel użytkownika obejmuje każdy negatywny efekt. Automatycznie obejmować
poprawnie oznaczone szkodliwe afflictions innych modów. Nie obiecywać pełnej
zgodności z dowolnym nieznanym modem: skryptowe zasoby zdrowia, odwrócone
skale, własne reprezentacje anatomii i błędnie opisane efekty wymagają
adapterów. Przewidzieć rozszerzalny rejestr adapterów; w dokumentacji
wyraźnie wskazać rzeczywiście przetestowane mody i pozostałe ograniczenia.
Problemu ze zgodnością nie maskować samym usunięciem ikony choroby.

## Pochłanianie trafień Mk II

Wersja podstawowa nie blokuje zwykłych ataków — może leczyć ich następstwa.
Mk II przechwytuje obrażenia przed zastosowaniem do użytkownika, ze wszystkich
kierunków: natywne ataki wręcz, pociski i eksplozje korzystające ze ścieżki
obrażeń gry. Przy częściowej baterii przepuszcza proporcjonalną resztę.
Przechwycone uderzenie nie może najpierw zranić, amputować ani zabić, a potem
zostać cofnięte leczeniem. Nie opłacać dwukrotnie tego samego trafienia przez
zagnieżdżone hooki. Atak całkowicie zablokowany przez natywne zasady gry nie
kosztuje energii. Bez globalnego wyłączania friendly fire lub zdrowia.

Skrypty innych modów bezpośrednio zmieniające zdrowie z pominięciem natywnej
ścieżki wymagają osobnej integracji. Nadal obejmuje je stopniowa regeneracja,
jeżeli stan da się bezpiecznie rozpoznać. Nie obiecywać przechwycenia każdego
możliwego zapisu w obcym skrypcie.

## Boty

Przy mniej niż 20% baterii bot szuka lepszego naładowanego ogniwa, preferując
własny ekwipunek, a następnie dostępne zapasy. Użyć natywnych zadań pobrania
i włożenia przedmiotu z dojściem, dostępem i bez kradzieży. Nie wyjmować
źródeł z cudzych urządzeń ani reaktorów. Nie wyrzucać działającej baterii,
dopóki nie ma dostępnego zamiennika. Brak zapasu nie zapętla zadań i nie
blokuje bez końca leczenia, walki lub pracy. Nowy moduł nie może zmienić
dotychczasowej obsługi zasilania multitoola.

## Grafika i dźwięk

Dwie spójne grafiki urządzenia z przezroczystością: ikona ekwipunku, sprite
przedmiotu oraz dopasowany do głowy sprite noszonego komunikatora. Mk II
ma widoczne dodatkowe emitery. Styl techniczny pasujący do Barotraumy.

Osłona przypomina pole z Diuny: cienka, półprzezroczysta otoczka całej postaci,
czerwone krótkie migotanie i lokalny rozbłysk przy użyciu energii. Puls przy
ciśnieniu, leczeniu i uderzeniu; w spoczynku wygaszona. Efekt śledzi pozycję
postaci, a nie pozycję przedmiotu na ziemi. Oryginalne zasoby, bez kopiowania
materiałów z filmu. Wykonawca ustala technikę renderowania i liczbę klatek.

Oryginalny krótki efekt trafienia w trzech wersjach zależnych od pozostałej
baterii: powyżej 40% stabilny impuls, 15–40% słabszy impuls z trzaskiem,
poniżej 15% przerywany alarmowy dźwięk. Jednorazowy sygnał wyczerpania.
Przy ciągłym poborze ograniczyć częstotliwość dźwięków; bez syreny 60 razy/s.
Dźwięki przestrzenne, zgodne ze standardową głośnością efektów gry.
Podglądy grafik i odsłuchy poza folderem instalacyjnym, zgodnie z repozytorium.

## Architektura i ograniczenia

Stan zdrowia, pobór energii i AI należą do serwera/symulacji single player.
Klient rysuje i odtwarza zsynchronizowane zdarzenia, bez podwójnego naliczania.
Wykorzystać obecne wzorce inicjalizacji LuaCs, bez zakłócania sieci Aegisa.
Sprzątanie po zdjęciu, śmierci, usunięciu przedmiotu, zmianie rundy i reloadlua.
Brak zmian w plikach instalacji Steam lub innych modach. Własne XML/Lua,
PNG i OGG w MULTI-TOOL-V2; dokumentacja/generatory/testy poza nim.
Receptury i ceny dobiera wykonawca, z wyższym kosztem Mk II, i dokumentuje.

## Weryfikacja i warunki ukończenia

- Natywna komunikacja z normalnymi headsetami, również bez baterii.
- Ochrona tylko w slocie słuchawek; ciśnienie nie zabija przed poborem energii;
  brak kosztu pod sprawnym skafandrem; wyczerpanie przywraca ryzyko.
- Leczenie rzeczywistych stanów ogólnych i lokalnych, zachowanie bonusów;
  proporcjonalne koszty i brak leczenia bez energii.
- NT: rzeczywista regeneracja organu i kończyny, brak odrastania bez energii,
  zachowanie sprawnych implantów; wskazana konkretna testowana wersja.
- Mk II: słaby i śmiertelny atak, eksplozja, wiele trafień, ostatnia energia;
  zwykła wersja otrzymuje ataki normalnie.
- Bot: wymiana słabej baterii, brak zamiennika, niedostępne/cudze ogniwo.
- Klient: widoczne migotanie, sprite noszonego urządzenia i trzy stopnie audio;
  multiplayer: serwer pobiera energię raz, odbiorcy widzą właściwą postać.
- Obecne regresje multitoola, walidacja zasobów i paczka instalacyjna.

Ukończenie wymaga wykonania dostępnych testów i rzetelnego opisania prób,
których nie dało się uruchomić. Projekt nie oznacza jeszcze wdrożenia.
