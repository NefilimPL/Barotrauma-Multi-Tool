# Dokumentacja System Aegis

## Korzystanie z moda

- [Instalacja i LuaCs](INSTALL.md)
- [Publikacja osobnego moda](PUBLISH.md)
- [Komunikatory Aegis](HEADSETS.md)
- [Odkurzacz i magazyn plecaka](VACUUM.md)
- [Kombinezon Aegis](AEGIS-SUIT.md)
- [Komendy tworzenia przedmiotów](spawn-commands.txt)

## Wydajność i testowanie

- [Pomiary wszystkich ośmiu przedmiotów i stan weryfikacji](PERFORMANCE.md)
- [Nowy pomiar wszystkich przedmiotów — narzędzia i odtwarzanie](../tools/performance/README.md)
- [Historyczny pomiar kombinezonów 1.3.17](AEGIS-PERFORMANCE.md)
- [Historyczne optymalizacje bezczynności](PERFORMANCE-VERIFICATION.md)
- [Czas klatki i pełny magazyn](FRAME-TIME-VERIFICATION.md)
- [Rzeczywista sesja bojowa dwóch klientów](TWO-CLIENT-COMBAT-VERIFICATION.md)
- [Weryfikacja komunikatorów](HEADSET-VERIFICATION.md)
- [Weryfikacja odkurzacza i magazynu](VACUUM-VERIFICATION.md)
- [Weryfikacja bojowego multitoola](COMBAT-VERIFICATION.md)

Starsze raporty dotyczą wersji, sprzętu i scen w nich opisanych. Ich wyników
nie należy przedstawiać jako świeżego testu aktualnego wydania.

## Grafiki i dźwięki

- [Bojowy multitool](combat-assets/preview.html)
- [Komunikatory](headsets/preview.html)
- [Odkurzacz](vacuum/preview.html)
- [Kombinezon](aegis-suit/index.html)

## Układ repozytorium

| Katalog | Zawartość |
|---|---|
| `System-Aegis/` | Wyłącznie paczka produkcyjna dla gry i Workshop |
| `tests/` | Testy automatyczne Python/Lua |
| `tests/runtime/` | Testy w silniku; nowa wspólna macierz w `performance/` |
| `tools/` | Walidacja, paczkowanie i generatory; nowe pomiary w `performance/` |
| `docs/` | Instrukcje, podglądy i historyczne dowody testów |
| `output/` | Ignorowane paczki i nowe surowe wyniki według identyfikatora przebiegu |
| `.runtime/` | Ignorowane prywatne instalacje testowe i zamrożona baza porównania |

System Aegis 1.3.27 ma nowe ścieżki i identyfikatory narzędzi oraz kombinezonu.
To osobny pakiet; stare wyposażenie nie migruje automatycznie.
Raporty wcześniejszych wersji zachowują historyczne pomiary i sumy kontrolne;
nazwy i odsyłacze dostosowano do obecnego układu repozytorium.
