# Dokumentacja projektu

## Korzystanie z moda

- [Instalacja i LuaCs](INSTALL.md)
- [Komunikatory Aegis](HEADSETS.md)
- [Odkurzacz i magazyn plecaka](VACUUM.md)
- [Kombinezon Descendants](DESCENDANT-SUIT.md)
- [Komendy tworzenia przedmiotów](spawn-commands.txt)

## Wydajność i testowanie

- [Pomiary wszystkich ośmiu przedmiotów i stan weryfikacji](PERFORMANCE.md)
- [Nowy pomiar wszystkich przedmiotów — narzędzia i odtwarzanie](../tools/performance/README.md)
- [Historyczny pomiar kombinezonów 1.3.17](DESCENDANT-PERFORMANCE.md)
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
- [Kombinezon](descendant-suit/index.html)

## Układ repozytorium

| Katalog | Zawartość |
|---|---|
| `MULTI-TOOL-V2/` | Wyłącznie paczka produkcyjna dla gry i Workshop |
| `tests/` | Testy automatyczne Python/Lua |
| `tests/runtime/` | Testy w silniku; nowa wspólna macierz w `performance/` |
| `tools/` | Walidacja, paczkowanie i generatory; nowe pomiary w `performance/` |
| `docs/` | Instrukcje, podglądy i historyczne dowody testów |
| `output/` | Ignorowane paczki i nowe surowe wyniki według identyfikatora przebiegu |
| `.runtime/` | Ignorowane prywatne instalacje testowe i zamrożona baza porównania |

Zasoby produkcyjne zachowują swoje ścieżki i identyfikatory. Nowy układ
narzędzi nie wymaga migracji zapisów kampanii.
