# Odkurzacz Aegis 1.3.1 — weryfikacja

Aktualizacja: 2026-11-04. Barotrauma 1.13.5.0; LuaCs/Luatrauma c6e8829.
Osobny serwer dedykowany i dwa rzeczywiste klienty w `.runtime`.
Instalacja Steam i prywatne zapisy gracza pozostały nienaruszone.

## Testy automatyczne

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
Paczka: `output/MULTI-TOOL-V2-1.3.1.zip`.
