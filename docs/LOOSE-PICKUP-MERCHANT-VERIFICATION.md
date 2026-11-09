# Wyrzucone przedmioty i sprzedaż z plecaka — 1.3.12

Weryfikacja: 2026-11-08, izolowany klient Barotrauma 1.13.5.0 z LuaCs,
sandbox w `.runtime/vacuum-clients/A`. Bez zmian w instalacji Steam ani kampanii gracza.

## Zbieranie

Przyczyną był warunek odrzucający w trybie „Tylko luzem” każdy przedmiot
z zawartością. Obejmował również spawarkę z butlą i multitool z baterią,
wyrzucone przez gracza na podłogę.

Poprawka sprawdza, czy sam przedmiot znajduje się w ekwipunku.
Przenośny przedmiot na ziemi jest zbierany w całości wraz z zawartością.
Zawartość szaf, ekwipunki postaci, blokady i wykluczenia nadal są respektowane.
W trybie „Tylko luzem” nie ma pobierania pojedynczych rzeczy z pojemników.

Test regresji przed poprawką: `floor mode rejected a dropped tool with fuel`.
Po poprawce cały zestaw: **438 testów PASS**.

## Sklep

Odtworzono różnicę między pustym bojowym multitoolem a egzemplarzem z baterią.
Natywny `CargoManager.GetSellableItems` pokazuje pusty multitool zarówno przed,
jak i po ręcznym włożeniu do plecaka. Egzemplarz z baterią jest ukrywany,
natomiast sama bateria znajduje się na liście. Po jej wyjęciu narzędzie
wraca na listę. Jest to reguła `CargoManager.IsItemSellable` dla pojemników
z niesprzedaną zawartością; nie zmieniono reguł sprzedaży.

Należy najpierw sprzedać albo wyjąć baterię, paliwo lub amunicję,
a następnie sprzedać narzędzie. Użytkownik potwierdził, że niewidoczny
egzemplarz prawdopodobnie miał baterię lub paliwo. Ta próba sprawdza natywną
listę i kwalifikowanie przedmiotów, nie pełną transakcję kampanii ani mody
zmieniające interfejs sklepu.

## Próba w grze

Scenariusz: [reported_backpack.lua](../tests/runtime/reported_backpack.lua).
Wszystkie **7 sprawdzeń PASS**; [surowe wyniki](vacuum/reported-backpack-results.txt).
Sprawdzono ręczne wkładanie oryginalnego multitoola, listę sprzedaży,
wyrzucenie spawarki z butlą i multitoola z baterią oraz produkcyjną pętlę
zasysania (`RangedWeapon.Use` → `G.update`) przy pobliskiej szafie.
Spawarka została zebrana z tą samą butlą; miedź pozostała w szafie.
Test ograniczał kandydatów zasysania do własnych przedmiotów testowych,
pozostawiając natywny ekwipunek, odświeżanie świata, geometrię i transfer.

Walidacja paczki: 13 XML i 41 modułów Lua 5.2. Protokół pozostaje v5.
