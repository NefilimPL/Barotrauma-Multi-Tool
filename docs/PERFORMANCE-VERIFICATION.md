# Wydajność przy bezczynności — 1.3.5–1.3.7

Data: 2026-11-05. Zgłoszenie: spadki FPS także bez używania narzędzi,
u wszystkich graczy, najsilniejsze u hosta.

## Przyczyna i poprawka

Odkurzacz i bojowy multitool przeglądały `Item.ItemList` co 0,5 sekundy
na serwerze i każdym kliencie. Odkurzacz dodatkowo odczytywał kontenery
i identyfikatory, nawet gdy nikt nie zasysał. Koszt rósł z liczbą wszystkich
przedmiotów poziomu, w tym rzeczy schowanych w plecakach.

Wykrywanie narzędzi korzysta teraz z indeksu `Util.GetItemsById` dostarczanego
przez LuaCs. Indeks obejmuje istniejące przedmioty, dopisuje nowe przez
`item.created` i jest czyszczony przy końcu rundy. Usunięte egzemplarze są
pomijane. Łup jest odświeżany tylko podczas zasysania po stronie autorytatywnej,
co najwyżej raz na 0,5 sekundy, wspólnie dla wszystkich aktywnych odkurzaczy.

Nieaktywne odkurzacze nie wysyłają już komunikatów o nieaktywności co 0,12
sekundy. Aktywne zachowują komunikaty podtrzymujące efekty; puszczenie spustu
wysyła jeden komunikat zatrzymania. Reset rundy czyści stan nadawania i zdalne
limity czasu. Audio odrzuca nieaktywny odkurzacz przed sprawdzaniem ekwipunku.

`Inventory.AllItems` zwraca bezpośrednią zawartość inwentarza. Nie był to
rekurencyjny odczyt 10 000 przedmiotów plecaka w każdej klatce.

## Pomiar w silniku

Barotrauma 1.13.5.0, LuaCs c6e8829, prywatny dedykowany serwer w `.runtime/server`
z Neurotrauma CS 2.0.5. Kod bazowy: `fb8346b`; po zmianie przeładowano Lua.
Skrypt `tests/runtime/idle_performance.lua` tworzy 3000 prawdziwych przedmiotów
`iron` w pustym lobby i mierzy wyłącznie `update` obu modułów.
Każda próbka obejmuje 120 wywołań z `dt=1/60`; wykonano pięć próbek.

| Moduł | Mediana przed | Mediana po | Maksimum przed | Maksimum po |
|---|---:|---:|---:|---:|
| Odkurzacz | 167,96 ms | 0,44 ms | 178,57 ms | 0,79 ms |
| Bojowy multitool | 26,44 ms | 1,96 ms | 29,12 ms | 2,62 ms |

Wyniki dotyczą łącznego czasu 120 wywołań, nie jednej klatki. Koszt wcześniejszych
skanów skupiał się w wywołaniach co 0,5 sekundy. To nie jest pomiar FPS całej gry
ani gwarancja usunięcia wszystkich opóźnień w kampanii z innymi modami.
Surowe wyniki: `docs/vacuum/idle-performance-before.txt` i
`docs/vacuum/idle-performance-after.txt`.

## Testy

- 370 testów automatycznych: PASS.
- Walidacja 13 XML, 39 modułów Lua 5.2 i zasobów paczki: PASS.
- Próba w aktywnej rundzie rzeczywistego serwera: PASS — zdarzenie `item.created`
  natychmiast dopisuje nowe narzędzia do indeksu; oba moduły wykrywają je,
  odkurzacz schowany w plecaku jest pomijany, a usunięte narzędzia znikają ze
  stanów. Skrypt: `tests/runtime/idle_devices.lua`; wynik:
  `docs/vacuum/idle-devices-results.txt`.
- Nowe regresje sprawdzają brak skanów świata przy bezczynności na serwerze
  i kliencie, odkrywanie nowych narzędzi z indeksu, pomijanie schowanych
  zapasowych odkurzaczy, usuwanie stanu zniszczonych narzędzi, skan łupu tylko
  podczas autorytatywnego zasysania i wykrywanie nowo dodanego łupu.
- Dodatkowe testy sprawdzają ciszę sieciową przy bezczynności, komunikaty
  podtrzymujące i jeden komunikat zatrzymania, reset rundy oraz zdalne audio
  bez lokalnego użycia spustu i jego wygasanie.

Pierwsze otwarcie pełnego magazynu i aktywne zasysanie nadal mogą wykonywać
pracę zależną od liczby przedmiotów. Ta poprawka usuwa potwierdzony koszt
powtarzany również przy bezczynności. Nie testowano FPS w kampanii użytkownika.

## Pozostałe wyposażenie — 1.3.6

Headsety Mk I/Mk II oraz bojowy multitool przeszukiwały cały poziom przy
każdej próbie znalezienia zasilania dla bota. Przy niskiej energii headseta
próba powtarza się co sekundę, osobno dla każdego bota. Oba mechanizmy
korzystają teraz z grupy baterii i prętów paliwowych indeksowanej przez LuaCs.
Zasady dostępu, rezerwacja baterii innych headsetów i zakaz zabierania zasilania
z urządzeń pozostają sprawdzane przy każdej próbie.

Grupa obejmuje nowo tworzone źródła oraz istniejące przedmioty, które otrzymają
tag zasilania przez `AddTag`, `ReplaceTag` lub ustawienie `Tags`. Oczekujące
zmiany są wspólne dla obu modułów i czyszczone przy końcu rundy. Obsługa partii
1000 źródeł zachowuje koszt liniowy, bez porównywania każdej pary przedmiotów.

Pomiar w tej samej aktywnej rundzie prywatnego serwera z Neurotrauma CS:
3000 dodatkowych sztuk żelaza, łącznie 5224 przedmioty przed zmianą i 5264
po zmianie. Różnica wynika z przedmiotów pojawiających się w trwającej rundzie.
Pięć próbek po 20 wywołań każdej operacji, po rozgrzaniu indeksu:

| Operacja | Mediana przed | Mediana po |
|---|---:|---:|
| Szukanie baterii dla headseta | 184,63 ms | 10,26 ms |
| Kontrola leczenia zdrowego użytkownika headseta | 2,17 ms | 1,08 ms |
| Natywna bezczynna aktualizacja zwykłego multitoola | 0,02 ms | 0,02 ms |
| Natywna bezczynna aktualizacja klucza/śrubokręta | 0,01 ms | 0,01 ms |

Zmiana przyspiesza wyszukiwanie zasilania. Kod leczenia i XML zwykłych narzędzi
nie zostały zmienione; różnice pomiarów tych operacji nie są efektem ich
optymalizacji. Leczenie headsetów jest sprawdzane co 0,2 sekundy; ochrona
ciśnieniowa i trafienia wymagają bieżącej obsługi. Zwykły multitool, klucz,
śrubokręt i wewnętrzne znaczniki trybu nie mają globalnego skanera przedmiotów.
Nie wykryto u nich porównywalnego kosztu bezczynności w tej próbie.

375 testów automatycznych: PASS. Natywne próby potwierdziły dopisywanie nowych
baterii i paliwa oraz aktualizację po wszystkich trzech metodach zmiany tagów.
Skrypt: `tests/runtime/equipment_performance.lua`. Surowe wyniki:
`docs/vacuum/equipment-performance-before.txt` i
`docs/vacuum/equipment-performance-after.txt`.

Pierwsza inicjalizacja grupy nadal wymaga jednego przeglądu istniejących
przedmiotów. Nie mierzono renderowania GPU zwykłych narzędzi ani całkowitego FPS
kampanii; aktywne spawanie, tarcze i cząsteczki pozostają osobnym obciążeniem.

Wersja 1.3.7 dodaje [optymalizacje czasu klatki](FRAME-TIME-VERIFICATION.md):
renderowanie tarcz, odłożone narzędzia, właściciele pasywnych bonusów,
porcjowany skan łupu i ponowne używanie GUI.

Paczka: `output/MULTI-TOOL-V2-1.3.7.zip`. Zaktualizuj hosta oraz wszystkich
klientów i uruchom ponownie grę oraz serwer.
