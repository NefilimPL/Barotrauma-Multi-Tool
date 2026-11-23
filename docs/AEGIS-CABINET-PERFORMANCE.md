# Szafki i tekstury w Systemie Aegis 1.8.1

W poprzedniej wersji kod okna plecaka przeglądał zawartość wybranego pojemnika co aktualizację. Na cięższej szafce oznaczało to przejście także przez przedmioty w pojemnikach znajdujących się w środku. Teraz korzysta z indeksu plecaków LuaCs i sprawdza aktualne położenie oraz dostęp do pasujących egzemplarzy.

Porównanie wykonano w pojedynczym kliencie Barotraumy 1.13.5.0 z LuaCs na Dugongu. Każdy wariant obejmował zamknięte okno, pustą szafkę, szafkę z materiałami oraz szafkę z pięcioma skrzynkami i 60 przedmiotami w środku. Ostatnią szafkę otwarto także przez połączony fabrykator. Bezpośrednie otwarcie tej szafki i wejście przez fabrykator powtórzono. Poszczególne okna były otwarte przez 3,2 sekundy.

| Wersja | Wyszukiwanie plecaka w szafce ze skrzynkami, średnia na aktualizację | Czas klatki p95 przy otwartej szafce, dwie próby |
|---|---:|---:|
| Gra z LuaCs | — | 14,92 / 15,18 ms |
| Aegis 1.8.0 | 0,67 ms | 15,02 / 15,95 ms |
| Aegis 1.8.1 | 0,06 ms | 16,13 / 17,11 ms |

Wyszukiwanie plecaka jest tańsze o około 0,61 ms w tym scenariuszu. Wyniki całych klatek nie wykazały wzrostu FPS po zmianie. Nie odtworzono opisanego mocnego spadku po bezpośrednim otwarciu szafki. W obu próbach z Aegisem przy pierwszym wyświetleniu fabrykatora zdarzyła się jedna klatka ok. 52–53 ms. Test obejmuje podstawową zawartość gry i wskazane scenariusze. Zachowanie pełnej paczki modów może się różnić.

Sprawdzono też w kliencie, że dostępny plecak w otwartej szafce nadal pojawia się w panelu, a zamknięcie szafki odbiera dostęp. Scenariusz pomiaru jest w [aegis_cabinet_perf.lua](../tests/runtime/aegis_cabinet_perf.lua).

## Tekstury

- Warianty kombinezonu mają osobne ikony do 384 × 160 px, a moduły do 256 × 256 px.
- Obudowy i łopatki wirników zmniejszono z 1254 × 1254 do 312 × 312 px, zachowując wielkość na postaci.
- Większe grafiki korzystają z DXT5, gdy kompresja tekstur jest włączona w grze. Format potwierdzono na masce wyświetlanej przez klienta.

Maskę klauna wygenerowano wbudowanym imagegen na podstawie projektu z 1.8.0. Polecenie zachowuje opancerzenie i dzwonki, zastępuje szybę białą maską, dodaje czerwony nos, malowany uśmiech i trójkątne okienka. W atlasie otwartego hełmu maska jest podniesiona, a twarz pozostaje odsłonięta. Nowa maska jest również na portrecie i złożonym kombinezonie.
