# Odkurzacz Aegis 1.3.3 — weryfikacja

Aktualizacja: 2026-11-04. Barotrauma 1.13.5.0; LuaCs/Luatrauma c6e8829.
Osobny serwer dedykowany i dwa rzeczywiste klienty w `.runtime`.
Instalacja Steam i prywatne zapisy gracza pozostały nienaruszone.

## Szafa, materiały i siatka — 1.3.3

- Pełny zestaw regresji: **320 testów, OK**; walidacja 12 XML i 36 modułów
  Lua 5.2, tekstur i receptur względem lokalnej gry: **OK**.
- **12 natywnych sprawdzeń SP — PASS**: materiały z założonego plecaka,
  zakończenie obsługi maszyny, przeniesienie składników do natywnego wejścia,
  ich rzeczywiste zużycie i utworzenie klucza, medyczny fabrykator, plecak
  i ssawka w dużej szafie, autoryzacja otwartej szafy, źródło materiałów
  z połączonej szafy bez duplikacji, blokada trwającej rozbiórki, częściowe
  pobranie stosu i 40 ikon w panelu. Ostatnia kontrola sprawdzała aktualność
  indeksu po dodaniu 500 rzeczywistych przedmiotów.
- Czynność ukończenia receptury wywołano przez natywne StartFabricating/Fabricate;
  pominięto oczekiwanie na timer i symulację zasilania kopii maszyny testowej.
  Składniki rzeczywiście opuściły plecak, zostały usunięte po zużyciu,
  a wynik pojawił się w natywnym wyjściu fabrykatora.
- Zarejestrowano dokładny typ słownika materiałów, aby LuaCs nie przekazywała
  jego kopii. Próba serwera ujawniła inną nazwę assembly typu Item; moduł
  wybiera teraz DedicatedServer albo Barotrauma zależnie od środowiska.
  Start dedykowanego serwera i odczyt materiałów z noszonego plecaka: PASS.
- **Rzeczywisty multiplayer**: serwer utworzył 734 przedmioty w ponad 40
  grupach; osobny klient odebrał 40 wierszy ikon i dwie strony przez protokół v2.
  Żądanie „Weź stos” przeniosło 50 oryginalnych sztuk do postaci i zostawiło
  684 w plecaku, zgodnie z wolną pojemnością. Klient i serwer potwierdziły
  ten sam stan oraz zachowanie źródłowego egzemplarza. PASS.
- Początkowa dodatkowa asercja serwera zakładała pobranie pełnych 100 sztuk;
  zgłosiła FAIL, bo natywny ekwipunek mieścił tylko 50. Poprawiona kontrola
  uwzględnia pojemność i potwierdza bilans 734 = 684 + 50. Zapis pozostawiono
  w surowym dzienniku jako błąd założenia testowego.
- Odświeżanie natywnych materiałów przy **566 rzeczywistych przedmiotach**,
  po przygotowaniu indeksu: 10 prób, mediana 3 ms, maksimum 4 ms,
  średnia 3,20 ms (publiczny zegar os.clock). To pomiar operacji odświeżania,
  a nie FPS gry ani pierwszy odczyt pełnego plecaka.
- Osobny limit odpytywania panelu zapobiega zgubieniu kliknięcia pobierania
  przez odświeżanie w tle; operacje nadal mają limit powtórzeń.
- Przegląd kodu nie wskazał potwierdzonych usterek Critical/Important.

Dowody: `grid-native-results.txt`, `grid-network-results.txt`,
`grid-server-results.txt`, `grid-network-counts.txt`, `grid-metrics.txt`
i `grid-automatic-results.txt` w `docs/vacuum/`.
[Rzeczywisty panel ikon](vacuum/grid-window.png).
Nie powtarzano całego cyklu kampanii z 10 000 przedmiotów dla 1.3.3;
wcześniejsze wyniki poniżej mają podaną wersję.

## Poprawka slotu, okna i filtrów — 1.3.2

- Pełny zestaw: **275 testów, OK**. Dodano regresje dla braku slotu przedmiotu,
  drzwi, obu końców i węzłów przewodu, zawartości pojemników, stron plecaka,
  blokad dodatkowych kontenerów, limitu i cykli drzewa. Testy GUI obejmują
  widoczny przycisk, F, prawy klik, dostęp bez ssawki, przełączanie plecaków,
  pierwszeństwo slotu Bag oraz zamknięcie okna przy końcu rundy.
- **7 natywnych prób klienta — PASS** (`tests/runtime/vacuum_bag.lua`):
  wyposażenie Bag jednocześnie z oburęczną ssawką, narzędzia i pełne skrzynki
  oraz kombinezony, odrzucenie włazu i skrzynki elektrycznej, luźny i faktycznie
  podłączony przewód, zapasowy plecak ze stroną i próbą przeniesienia włazu,
  widoczność przycisku na ekranie oraz otwarcie wypełnionego okna samym plecakiem.
- Ponowiono także **13 natywnych regresji zbierania i rozbiórki — PASS**,
  z plecakiem zakładanym w slocie Bag (`bag-integration-results.txt`). Obejmują
  one kombinezon z ciała, pełne skrzynki, blokady, zasysanie w pętli produkcyjnej
  i zakończenie rozbiórki z zachowaniem nierozbieralnej zawartości.
- Filtr porównano z `Barotrauma fast loot/FastLoot/Lua/safety.lua`.
  Przeniesiono regułę rodzaju przedmiotu: musi mieć slot ekwipunku; drzwi
  i włazy oraz przewody z połączeniem lub węzłami nie są łupem. Cała zawartość
  przenoszonego pojemnika jest sprawdzana, z limitem 256 encji.
- Plecak używa natywnego `Wearable` w slocie `Bag`, z grafiką na tułowiu.
  Własny rysunek nie dubluje grafiki założonego plecaka. Slot kombinezonu jest wolny.
- Natywna próba wykryła przycisk poza ekranem przy ujemnym RelativeOffset
  z kotwicą BottomCenter. Zmieniono go na dodatni odstęp od dołu i ponowiono
  kontrolę rzeczywistego prostokąta oraz zrzutu w 960×540.
  [Okno z zawartością](vacuum/bag-window.png) pokazuje rzeczywistą listę trzech
  przedmiotów, ich stan, jakość oraz przyciski wyjmowania i odkładania.
- Przy poprawianiu skryptu testowego użyto enumeracji pinów ConnectionPanel,
  wolnego slotu do próby z włazem i `OnClicked.Invoke` po rejestracji typu
  delegata. Te wcześniejsze problemy dotyczyły narzędzi prób. Końcowy dziennik
  `docs/vacuum/bag-client-results.txt` zawiera siedem PASS.
- Mechanizm przechwytywania obrazu i wykonywania poleceń pozostaje tylko
  w testach. Uruchomienie poleceń przed `GameMain.HasLoaded` powodowało awarię
  piaskownicy; narzędzie czeka teraz na zakończenie ładowania.

Poniższe wyniki kampanii, 10 000 przedmiotów i dwóch klientów dotyczą 1.3.1.
Nie powtarzano całego długiego cyklu kampanii dla 1.3.2; sprawdzono zmienione
elementy na rzeczywistym kliencie i uruchomiono pełny zestaw regresji.

## Testy automatyczne 1.3.1

- `python tools/run_tests.py`: **254 testy, OK**.
- `python tools/validate_content.py --game .runtime/server`: **OK**:
  12 XML, 35 modułów Lua 5.2, zasoby, alpha, prostokąty klatek i receptury.
- Nowe regresje: zdarzenia dodawania/usuwania rzeczy, przenoszenie całych stron,
  rezerwacje rozbiórki, ponowne użycie ID encji, zgodność indeksu po sortowaniu,
  unieważnianie widoku, ograniczone szukanie wolnych slotów i reset nowej rundy.
- Dotychczasowe testy: autoryzacja, CanInteract, dwie ręce, bateria w odkurzaczu,
  grupy po 100, receptury, miejsce na produkty, wycofanie przerwanej transakcji.

## Pełny zapis kampanii i obciążenie

Natywny zapis z wersji 1.3.0 został wczytany w nowym procesie serwera
z poprawkami 1.3.1. To sprawdzenie całego cyklu kampanii, rozszerzające
wcześniejszą próbę samego `Item.Save`.

| Próba | Wynik |
|---|---|
| 104 rzeczy główne, skrzynka z magazynkiem, kombinezon z butlą | PASS |
| 108 oznaczonych egzemplarzy: typy, stan i jakość po odczycie | PASS |
| Ogniwo fulgurium pozostaje w slocie 0 odkurzacza ze swoim stanem | PASS |
| 100 stron i 10 000 rzeczywistych przedmiotów w jednym plecaku | PASS |
| Wszystkie 10 000 tożsamości i stanów po odczycie | PASS |
| 100 grup po 100; rzecz 10 001 odrzucona i zachowana | PASS |
| Odłożenie i ponowne włożenie: 10 000 → 9999 → 10 000 | PASS |

Utworzenie 10 000 natywnych encji w porcjach po 100 trwało około 4,1 s;
pełny zapis około 134 ms na testowym komputerze. Liczniki panelu nie
zastępują egzemplarzy atrapami.

## Dwóch klientów i rozłączenie

Dwa oddzielne procesy (`VacuumA`, `VacuumB`), osobne postacie, konfiguracje
i katalogi danych. Połączenia lokalne, uwierzytelnianie Steam wyłączone
na serwerze testowym. Nie symulowano dużego opóźnienia ani utraty pakietów.

- Oba klienty potwierdziły natywne przedmioty, zagnieżdżoną zawartość i jakość.
- Panel pełnego plecaka odebrał 10 000 rzeczy, 100 grup i najwyżej 8 wierszy
  na stronę przez rzeczywisty transport wiadomości LuaCs.
- Właściciel wyjął rzecz. Żądanie drugiego klienta dotyczące jego plecaka
  odrzucono. Natywne delty obu klientów zgadzały się z serwerem (104 → 103).
- Klient A uruchomił przez produkcyjny protokół partię 200 kluczy francuskich
  i 20 nierozbieralnych surowców, odebrał `busy`, po czym naprawdę rozłączył
  się i ponownie połączył. Postać z urządzeniem pozostała na serwerze.
- Serwer dokończył rozbiórkę bez połączonego gracza: dokładne produkty
  natywnej receptury, 20 oznaczonych surowców zachowanych, brak duplikacji.
- Gracz wrócił do tej samej postaci w trwającej rundzie i odzyskał panel.
  Kontrola zawartości po powrocie: PASS.

## Przejście poziomu

Wybrano sąsiednią lokację i użyto natywnego `CampaignMode.LoadNewLevel`.
Gra zakończyła rundę, zapisała kampanię i postacie, wygenerowała inny poziom
i ponownie wprowadziła obu klientów. Sprawdzono też dalsze wejście do outpostu.

- Dwa wyjścia z outpostu na poziom połączenia i wejście do następnej lokacji: PASS.
- Wszystkie 10 000 egzemplarzy i ich indywidualne stany po trzech przejściach: PASS.
- Pozostałe 103 rzeczy mieszanego plecaka, amunicja w skrzynce, butla
  w kombinezonie, jakość narzędzia i bateria w odkurzaczu: PASS.
- Partia przerwana zmianą rundy zachowała źródła i produkty; nowy poziom
  nie miał starego zadania ani transakcji. Po częściowym rozebraniu zachowano
  227 sztuk żelaza i 193 klucze (łącznie 420), w tym 20 oznaczonych surowców.
- Oba klienty sprawdziły zawartość i otworzyły panele po pierwszym przejściu.
- Dodatkowa partia: 10 kluczy i 20 nierozbieralnych surowców. Natywne przejście
  rozpoczęto z aktywnym zadaniem po rozebraniu trzech kluczy. Po wczytaniu
  zostało dokładnie 7 kluczy i 23 sztuki żelaza, z zachowanymi 20 surowcami
  i bez starej transakcji. Serwer i panel klienta potwierdziły 30 rzeczy: PASS.

## Wykryte problemy i poprawki

Pierwotny panel pełnego magazynu przygotowywał odpowiedź przez około sekundę.
Dodano indeks aktualizowany przez natywne `ItemContainer.OnItemContained`
i `OnItemRemoved` oraz widok grup unieważniany przy zmianie zawartości.
Rekordy używają liczbowych ID z kontrolą referencji przy ponownym użyciu ID.
Stan i jakość wiersza odczytywane są przy odpowiedzi; rezerwacje rozbiórki
nadal korzystają z aktualnej listy.

| Pomiar przy 10 000 rzeczy | Przed | Po |
|---|---:|---:|
| Lista bez zmian, mediana 10 prób | 435 ms | 0 ms |
| Odpowiedź panelu, mediana 10 prób | 1016 ms | 0 ms |
| Odpowiedź panelu, średnia 10 prób | 1018,7 ms | 0,6 ms |
| Pętla urządzenia, średnia 20 prób | 12,15 ms | 4,90 ms |

Pomiary panelu po poprawce dotyczą przygotowanego indeksu i widoku, bez zmiany
zawartości. Odczyt po wczytaniu i odnowienie po zmianie przetwarzają dane ponownie.
To pomiary tych operacji, nie FPS całej gry ani gwarancja dla innych komputerów.
Pełne odtworzenie indeksu i widoku z natywnych inwentarzy, po wyczyszczeniu
cache, zajęło 1175 ms w jednej próbie. Następne 10 odpowiedzi miało medianę
0 ms przy rozdzielczości zegara 1 ms. Pierwsze otwarcie pełnego plecaka może
więc spowodować widoczną pauzę.

Naprawiono też reset list i zegarów zasysania przy końcu rundy. Pozostawione
wcześniej referencje mogły odwołać się do wyczyszczonych stanów w kolejnej rundzie.
Regresje oraz natywne przejścia potwierdziły poprawkę. Przegląd indeksu,
unieważniania widoku i resetu nie wskazał istotnych błędów.

## Dowody i granice

Wcześniejsze 13 natywnych prób serwera i trzy próby klienta z rzeczywistym GPU:
`docs/vacuum/server-results.txt` i `client-results.txt`. Obejmują pobranie
założonego kombinezonu z ciała, pomijanie żywych postaci, blokady pojemników,
odkładanie skrzynek i kombinezonów, zachowanie nierozbieralnej zawartości
oraz rysowanie wszystkich 16 klatek zasysania.

Nowe dzienniki: `extended-results.txt`, `network-client-A-results.txt`,
`network-client-B-results.txt`, `metrics-before.txt` i `metrics-after.txt`
w `docs/vacuum/`. Wczesne FAIL dotyczą skryptów testowych: założono stal
zamiast żelaza jako produkt klucza, użyto niedostępnej metody enumu `ToString`
i próbowano opuścić poziom okrętem poza wyjściem. Poprawione kontrole używają
natywnej receptury, funkcji Lua `tostring` i dostępnego wyjścia. Dodatkowa próba
wymagała ponownego założenia urządzenia po śmierci postaci w bezczynnej rundzie.

Nie sprawdzono wszystkich zestawów modów, sieci WAN ani wielogodzinnej kampanii.
Specjalistyczne receptury wymagające innej maszyny lub dodatkowej rzeczy
pozostają nietknięte; talenty i skryptowe efekty dekonstruktora nie są odtwarzane.
Limit 10 000 nadal podlega limitom encji silnika. Rozłączenie klienta nie oznacza
zatrzymania partii, jeżeli jego postać wciąż trzyma sprawne urządzenie.

Skrypty `tests/runtime/` i sterowanie klientami nie trafiają do moda.
Paczka: `output/MULTI-TOOL-V2-1.3.3.zip`.
