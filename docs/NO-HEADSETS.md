# System Aegis 1.4.1 — wersja bez komunikatorów

Osobny, kompletny folder moda: `System-Aegis-No-Headsets/`.
[Gotowy ZIP](../output/System-Aegis-No-Headsets-1.4.1.zip).
Pełna wersja `System-Aegis/` pozostaje bez zmian.

W tym wariancie są odkurzacz z plecakiem, kombinezon Aegis, bojowy multitool,
kompozytowy multitool i klucz-śrubokręt. Nie zawiera komunikatorów Aegis,
ich regeneracji, osłon, skryptów ani zasobów. Wymaga LuaCs na kliencie i serwerze.

## Instalacja

1. Skopiuj `System-Aegis-No-Headsets` do `Barotrauma/LocalMods/`.
2. Włącz pakiet **System Aegis (No Headsets)**. Włączaj jedną wersję Aegis naraz,
   ponieważ wersje używają tych samych identyfikatorów wyposażenia.
3. Uruchom grę ponownie. Utwórz nowe egzemplarze broni i kombinezonu,
   aby mieć nowe sloty. Moduły wytwarza się i wkłada osobno; nie są dołączane
   przy zakupie ani wytworzeniu wyposażenia.

## Tarcza bojowego multitoola

| Slot | Zawartość |
|---|---|
| 1 | Bateria lub pręt paliwowy — wspólne zasilanie broni i narzędzi |
| 2 | Wkład tarczy Aegis (`aegisshieldmodule`) |

Bez wkładu broń i narzędzia działają, lecz tarcza jest wyłączona.
Pełny wkład blokuje maksymalnie **5 pocisków**. Każda skuteczna blokada
zużywa jedną blokadę, czyli 20% ładunku wkładu, oraz dotychczasowy koszt
energii broni. Zablokowanie silniejszego pocisku nadal kosztuje więcej
energii, ale zużywa jedną blokadę. Szósty pocisk przechodzi przez pustą tarczę.
Pusty wkład pozostaje w slocie i można go doładować.

Wkład odnawia **jedną blokadę co 15 sekund**. Po dwóch blokadach ma 60%:
po 15 sekundach wraca do 80%, a po 30 sekundach do 100%. Od zera pełna
regeneracja zajmuje 75 sekund. Kolejne trafienie nie resetuje już rozpoczętego
ładowania. Stan przedmiotu pokazuje również częściowy postęp regeneracji;
pełne 20% odpowiada jednej gotowej blokadzie.

Regeneracja działa tylko wewnątrz sprawnej broni z niewyczerpanym źródłem
zasilania. Nie wymaga celowania, więc broń może być schowana. Wyjęty wkład,
brak energii, uszkodzona broń oraz pauza zatrzymują ładowanie. Przełożenie
wkładu i zapis gry zachowują jego ładunek — nie przywracają pięciu blokad.

Tarcza **nie zadaje obrażeń kontaktowych ani nie ogłusza przy dotyku**.
Chroni przed przechwytywanymi pociskami z przodu, jak wcześniej; nie chroni
przed atakami od tyłu, ciśnieniem ani pobliskimi eksplozjami.

## Moduły kombinezonu

| Slot | Zawartość | Rola |
|---|---|---|
| 1 | Bateria lub pręt paliwowy | Zasilanie |
| 2 | Obsługiwana skrzynka amunicji | Amunicja ramienia |
| 3 | Moduł serwa (`aegisservomodule`) | Naprawa, spawanie, obrona i chwytak |
| 4 | Moduł wirnika (`aegisimpellermodule`) | Wspomaganie pływania |

Bez serwa nie ma ramienia ani jego funkcji; przyciski ramienia są nieaktywne.
Wyjęcie serwa zwalnia trzymany cel, zatrzymuje naprawę i anuluje oczekujący
strzał. Bez wirnika nie działa napęd. Obieg oddechowy, sonar i oświetlenie
nadal korzystają ze źródła zasilania niezależnie od tych modułów.
Panel kombinezonu pokazuje obecność lub brak obu modułów.

## Craftowanie

Moduły wytwarza się w fabrykatorze lub fabrykatorze wojskowym. Nie są
sprzedawane przez sklepy. Podane poziomy oznaczają mechanikę / elektrykę.

| Przedmiot | Materiały | Czas | Umiejętności |
|---|---|---|---|
| Wkład tarczy | 2 stopy tytanowo-aluminiowe, 2 miedzi, 1 FPGA, 1 fulgurium | 30 s | 45 / 55 |
| Moduł serwa | 2 stopy tytanowo-aluminiowe, 2 miedzi, 1 FPGA, 1 stal | 40 s | 60 / 40 |
| Moduł wirnika | 2 stale, 1 stop tytanowo-aluminiowy, 1 miedź, 1 plastik | 30 s | 50 / 25 |

Receptury są w `aegis_modules.xml`. Limit blokad i regenerację ustawiają
`shieldCharges` oraz `shieldRechargeSeconds` w `Lua/AegisCombat/config.lua`.

## Komendy do testowania

```text
enablecheats
spawnitem aegiscombattool inventory 1
spawnitem aegisshieldmodule inventory 1
spawnitem aegisservosuit inventory 1
spawnitem aegisservomodule inventory 1
spawnitem aegisimpellermodule inventory 1
spawnitem batterycell inventory 3
spawnitem pulselaserammobox inventory 1
spawnitem aegisvacuum inventory 1
spawnitem aegisvacuumpack inventory 1
spawnitem aegiscompositetool inventory 1
spawnitem aegiswrenchscrewdriver inventory 1
```

## Tekstury

Trzy PNG z przezroczystością dopasowane do rzeczywistych części wyposażenia.
Serwo odtwarza linki, przewody i chwytak z atlasu `suit-v2.png`, wirnik łączy
oryginalną obudowę z czterema srebrnymi łopatami, a wkład tarczy odpowiada
dwóm turkusowym cylindrom w korpusie broni. Używane jako sprite świata,
ikona ekwipunku i ikona nowego slotu:

- [Wkład tarczy](../System-Aegis-No-Headsets/Assets/AegisModules/shield-module.png)
- [Moduł serwa](../System-Aegis-No-Headsets/Assets/AegisModules/servo-module.png)
- [Wirnik](../System-Aegis-No-Headsets/Assets/AegisModules/impeller-module.png)

Wygenerowano wbudowanym narzędziem image generation, bez skalowania lub
przemalowywania plików źródłowych. [Komplet promptów](modular-assets/PROMPTS.md).

## Sprawdzenia

```powershell
python tools/run_tests.py
python tools/validate_content.py --mod System-Aegis-No-Headsets --game 'D:/SteamLibrary/steamapps/common/Barotrauma'
python tools/package_mod.py --mod System-Aegis-No-Headsets
```

Testy obejmują limit blokad, kolejkę regeneracji, brak zasilania, pauzę,
przekładanie i odtwarzanie wkładu, natywny float stanu, przechwytywanie pocisków,
limit predykcji klienta, synchronizację modułów, przerwanie naprawy oraz
anulowanie strzału po wyjęciu serwa. Sprawdzono XML, składnię Lua 5.2,
referencje i przezroczystość grafik oraz identyfikatory materiałów z gry.
Próba rozgrywki tego wariantu w silniku gry nie była jeszcze wykonywana.
