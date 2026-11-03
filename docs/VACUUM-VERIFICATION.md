# Odkurzacz Aegis 1.3.0 — weryfikacja

Data: 2026-11-03. Kod i zasoby w istniejącym pakiecie MULTI-TOOL-V2.
Barotrauma 1.13.5.0; LuaCs/Luatrauma c6e8829. Wykorzystano osobne kopie
serwera i klienta w `.runtime`, bez zmian w instalacji Steam.

## Wyniki automatyczne

- `python tools/run_tests.py`: **242 testy, OK**, po poprawkach autoryzacji,
  typów przenośnych, odkładania i cyklu panelu.
- Walidator sprawdził XML pakietu, odwołania do plików, prostokąty PNG,
  receptury względem lokalnej gry i składnię wszystkich 35 modułów Lua 5.2.
- Nowe testy obejmują grupowanie 100/101, pojemność grup, zachowanie referencji
  do egzemplarzy, postorder i cykle pojemników, pełny koszt energii,
  baterię wyłącznie w odkurzaczu, wymaganie dwóch rąk i plecaka,
  autoryzację właściciela, CanInteract, ograniczenie żądań i stronicowanie.
- Testy receptur sprawdzają brak receptury, zakaz rozbiórki, ilości,
  zakresy stanu, kopiowanie kondycji, ważone losowanie bez powtórzeń,
  brak prefabów i wymaganie innego przedmiotu.
- Cztery testy transakcji sprawdzają zachowanie oryginału do ukończenia
  spawnu wszystkich wyników, cofnięcie produktów i energii przy przerwaniu,
  ewakuację nierozbieralnej zawartości oraz brak miejsca na wyjście.

## Próby natywnego serwera

13 sprawdzeń w `tests/runtime/vacuum_integration.lua` zakończyło się PASS:

1. Osobny plecak, odkurzacz w obu rękach i bateria w jego slocie 0.
2. 101 rzeczywistych przedmiotów, z różnymi stanami, pokazanych jako 100+1.
3. Pełna skrzynka zachowuje rzeczywisty magazynek amunicji w środku.
4. Założony kombinezon można pobrać z martwej postaci.
5. Wyposażenie żywej postaci jest wykluczone ze zbierania.
6. Skrzynka i kombinezon wracają na ziemię; amunicja pozostaje w skrzynce.
7. Sam plecak pozostaje dostępny bez trzymanej ssawki i bez energii;
   rozbiórka bez baterii nie startuje.
8. Zablokowanego inwentarza nie można opróżnić przez zasysanie.
9. Jeden przycisk rozpoczyna partię; ponowne uruchomienie tej samej partii
   jest odrzucane, a rzeczy bez receptury pozostają.
10. Partia kończy się z zachowanym nierozbieralnym plecakiem i baterią.
11. Rozbieralna skrzynka narzędziowa oddaje nierozbieralną zawartość przed
    usunięciem obudowy.
12. Po zakończeniu spawnu obudowa znika, a zachowany surowiec zostaje.
13. Produkcyjna pętla zasysania pobiera luźny klucz francuski.

Dodatkowo ręczna próba natywnego `Item.Save` zapisała ponad 100 elementów
plecaka, stron i łupu oraz ich odwołania `contained` — PASS. Jest to próba
serializacji, a nie pełny zapis i ponowny odczyt kampanii.

Surowy końcowy wynik: `docs/vacuum/server-results.txt`. Wcześniejsza próba
przypadkowo użyła metalowej skrzynki z pustą listą produktów rozbiórki;
pozostała ona nietknięta zgodnie z wymaganiem. Test zachowania zawartości
został następnie wykonany na skrzynce narzędziowej z recepturą stali.

## Próby prawdziwego klienta

`tests/runtime/vacuum_client.lua`, osobny klient single player i rzeczywisty
SpriteBatch/GPU:

- Bootstrap i położenie baterii — PASS.
- Tworzenie panelu z lokalizacją, wierszami i polem wyszukiwania — PASS.
- Rysowanie plecaka, przewodu i wszystkich 16 klatek zasysania — PASS.
- Dodatkowa próba finalnego modułu klienta: panel jest widoczny dzięki
  dodawaniu go w produkcyjnym `think`. Potwierdzono na rzeczywistym zrzucie
  `.runtime/vacuum-panel-production.png`, po usunięciu testowego hooka.

Wykryte błędy naprawiono: przeciążenie Sprite.Draw wymaga jawnego punktu
zaczepienia dla skali Vector2; jawne numery enumów usunięto na rzecz
domyślnych parametrów. Samo dodanie panelu podczas przebudowy listy ekranu
nie wystarczało — panel jest obecnie kolejkowany w fazie think i jawnie
usuwany przy zamknięciu. „Grupy” zastępuje znak niewyświetlany przez font gry.

Surowy wynik: `docs/vacuum/client-results.txt`. Skrypty testowe i mechanizm
rozruchu klienta pozostają poza paczką moda.

## Niezależny przegląd i poprawki

Przegląd całej funkcji wskazał konieczność:

- Dodania odłożenia na ziemię: Any nie przyjmuje skrzynek i kombinezonów.
  Poprawka i natywna próba zwracania obu typów zakończyły się sukcesem.
- Sprawdzania CanInteract: ogłuszenie i zablokowane ręce muszą zatrzymywać
  obsługę, także przy sfałszowanych żądaniach właściciela.
- Poszanowania Inventory.Locked, którego Item.HasAccess nie sprawdza.
  Regresja i natywna próba blokady zakończyły się sukcesem.
- Wykluczenia zawartości magazynów z listy łupu przeszukiwanej co 0,12 s.
  Użyto natywnego buforowanego RootContainer.

## Granice weryfikacji

- Nie wykonano pełnego zapisania i ponownego załadowania kampanii, zmiany
  poziomu podczas transakcji ani rozłączenia dwóch rzeczywistych klientów.
  Zaplecze korzysta z natywnych encji i zapisu pojemników; to nie zastępuje
  testu całego cyklu kampanii i sieci.
- Nie wykonano obciążenia 10 000 rzeczywistych encji w jednym plecaku.
  10 000 jest limitem projektu, nie gwarancją płynności dla każdego zestawu
  modów. Native entity ID, liczba graczy i koszty symulacji nadal ograniczają grę.
- Przetestowano 101 rzeczywistych przedmiotów i zagnieżdżone pojemniki.
  Samo grupowanie nie scala stanów ani jakości i nie niszczy zawartości.
- Specjalistyczne receptury wymagające innych maszyn lub łączenia rzeczy
  są zachowywane; nie odtwarza się talentów i skryptowych efektów natywnego
  dekonstruktora. Nie obiecuje się zgodności z dowolnym nieznanym modem.

Artefakty: `MULTI-TOOL-V2/Assets/Vacuum/*.png`,
`docs/vacuum/preview.html`, paczka `output/MULTI-TOOL-V2-1.3.0.zip`.
