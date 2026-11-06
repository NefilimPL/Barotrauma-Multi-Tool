# Trafienia i plecak — 1.3.11

Data: 2026-11-06. Barotrauma 1.13.5.0 / LuaCs c6e8829. Wszystkie próby
wykonano na osobnych kopiach w `.runtime`, bez kampanii użytkownika.

## Koszt efektów trafień w kliencie GPU

Uruchomiono prawdziwy klient 960 × 540, sandbox Azimuth. Profil korzysta
z prawdziwego SpriteBatch, tekstur, GUI.DrawLine i kamery. Wymusza tryb
rysowania zdalnych efektów (`authoritative=false`). Natywny zegar Stopwatch
w testowym startup hooku mierzy całe polecenie z 30 przebiegami rysowania.
Przygotowanie efektów i ładowanie tekstur są poza pomiarem. Batch.End
jest w pomiarze; prezentacja całej sceny i pozostałe mody nie są.

Porównano oryginalny renderer z HEAD `15fd4eb` i źródła 1.3.11 w tym samym
kliencie, dla identycznych punktów i kamery, po rozgrzewce:

| Scenariusz | Przed, ms / przebieg | Po, ms / przebieg |
|---|---:|---:|
| 64 bliskie trafienia tarczy jednego źródła | 21,21 | 0,394 |
| 64 trafienia poza ekranem | 22,24 | 0,064 |

Wcześniejsza próba różnych źródeł dawała 9,87 ms dla 32 oraz 19,05 ms dla
64 nakładających się trafień. Po ograniczeniu do 24 widocznych efektów:
7,81 ms i 7,96 ms. To koszt samego renderera, nie gwarantowany FPS gry.

Przyczyna potwierdzona w tej ścieżce: każde zdarzenie dodawało osobny efekt
z wieloma proceduralnymi liniami, także daleko poza ekranem. Teraz trafienia
tego samego rodzaju i źródła w odległości poniżej 24 jednostek, w oknie
40 ms, współdzielą jeden błysk i dźwięk. Jednocześnie rysowanych efektów
trafień jest najwyżej 24. Obliczenia punktów korzystają z macierzy kamery,
z zachowaniem obrotu i odwrócenia osi Y. Łuk obejmujący ekran pozostaje
widoczny nawet przy obu końcach poza ekranem. Zasady obrażeń i energii
oraz serwerowe zdarzenia pozostają bez zmian.

Surowe wyniki: [pierwszy pomiar](combat/impact-performance-before.txt),
[pomiar po i porównanie identycznego scenariusza](combat/impact-performance-after.txt).
Scenariusz: `tests/runtime/combat_effects_profile.lua`;
zegar: `tests/runtime/CombatProfileStartup.cs`.

Zakres: jest to rzeczywisty test renderowania klienta, z odtworzonymi
zdarzeniami efektów. Nie wykonano sesji dwóch połączonych klientów z
opóźnieniem ani pomiaru na komputerach znajomych. Nie potwierdza to,
że każdy zgłoszony spadek FPS miał wyłącznie tę przyczynę.

## Plecak w prawdziwej grze

**8/8 sprawdzeń: PASS**, na natywnym kliencie po pełnym restarcie:

- 40 spawarek z różnym stanem: jedno żądanie wyjmuje wiele sztuk do wolnych
  slotów, zachowuje tożsamość i stan; pozostałe sztuki pozostają w plecaku.
- Tryb „Tylko luzem” pomija zawartość pojemników i załadowane torby na ziemi;
  wyłączenie przywraca zwykłe zbieranie.
- Natywna lista `CargoManager.GetSellableItems` zawiera prawdziwe żelazo
  z noszonego plecaka; odrzuca uszkodzony i sprzedany egzemplarz, przedmiot
  z bieżącego posterunku, zablokowane strony oraz aktywną transakcję.
- Natywne przeciążenia TryPutItem dla ekwipunku postaci i szafy obsługują
  przeciągnięcie na plecak, zachowując sam plecak w slocie.
- Rzeczywisty panel ma przetłumaczone przyciski wielowyboru i filtra.
- Nowy pusty plecak tworzy pierwszą stronę i automatycznie kończy ręczne
  wkładanie tego samego egzemplarza po callbacku tworzenia strony.

[Wyniki](vacuum/backpack-workflow-results.txt),
[zrzut panelu](vacuum/backpack-workflow.png),
scenariusz `tests/runtime/backpack_workflow.lua`.
Test przeciągania wywołuje prawdziwe przeciążenie ekwipunku z kontrolowanym
sygnałem puszczenia przycisku myszy. Nie steruje fizycznym kursorem użytkownika.

## Autorytatywna blokada sprzedaży

Przegląd wykrył, że klient multiplayer nie ma serwerowych map `jobs`,
`pending` i `reserved`, a natywna sprzedaż serwera nie wywołuje klientowej
kontroli IsItemSellable. Dodano kontrolę w serwerowym CargoManager.SellItems.
Odfiltrowuje wewnętrzne strony, rzeczy z aktywnej rozbiórki, produkty
transakcji i rezerwacje; sprzedaż z postaci wymaga jej rzeczywistej własności.
Żądanie przekazuje prawdziwą List&lt;SoldItem&gt;, nie tabelę Lua.

**4/4 sprawdzeń: PASS**, na natywnym serwerze z Neurotraumą CS2.0.5:
zachowanie zwykłych pozycji i dozwolonej zawartości, odrzucenie stron,
rozbiórki, pending i rezerwacji.
[Wyniki](vacuum/merchant-server-results.txt).
Scenariusz `tests/runtime/merchant_server.lua` zatrzymuje wykonanie przed
dostępem do portfela i obserwuje finalne argumenty prawdziwych hooków.
Nie jest to pełny zakup/sprzedaż w kampanii z dołączonym graczem.

## Regresje i paczka

**437 testów automatycznych: OK.** Obejmują m.in. format sieciowy v5,
duplikaty i obce ID, pełny ekwipunek, nieaktualne zaznaczenia, zablokowanie
kosza przy wielowyborze, własność i blokady źródła, asynchroniczne utworzenie
strony, anulowanie po resecie, konwersję historii sprzedaży i odtworzenie
ukrycia magazynów po błędzie natywnej kontroli.

Walidacja: 13 XML / 41 modułów Lua 5.2, grafiki, dźwięki i receptury: OK.
Niezależny przegląd: jedna ważna uwaga o serwerowej sprzedaży; poprawiona
z regresją RED → GREEN oraz natywną próbą serwera. Bez odroczonych uwag.

Paczka: `output/MULTI-TOOL-V2-1.3.11.zip`. Protokół plecaka v5 wymaga
aktualizacji i restartu hosta oraz wszystkich klientów.
