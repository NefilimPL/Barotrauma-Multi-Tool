# System Aegis 1.8.3

Archiwum zawiera kompletny folder moda `System-Aegis/`.
[Gotowy ZIP](../output/System-Aegis-1.8.3.zip).


W tym wariancie są odkurzacz z plecakiem, kombinezon Aegis, bojowy multitool,
kompozytowy multitool i klucz-śrubokręt. Nie zawiera komunikatorów Aegis,
ich regeneracji, osłon, skryptów ani zasobów. Wymaga LuaCs na kliencie i serwerze.

[Kroje, hełmy i wyposażenie frakcji](FACTION-COLORS.md) · [Podgląd palet](faction-colors/preview.html)

## Instalacja

1. Skopiuj folder `System-Aegis` z archiwum do `Barotrauma/LocalMods/`.
2. Włącz pakiet **System Aegis**. Włączaj jedną wersję Aegis naraz,
   ponieważ wersje używają tych samych identyfikatorów wyposażenia.
3. Uruchom grę ponownie. Moduły wytwarza się i wkłada osobno.
   Przy aktualizacji kombinezonu wyjmij pręt paliwowy i włóż baterię.

[Nowy panel i ochrona przed rozbiórką](INTERFACE.md).

## Używanie bez modułów

Można założyć sam kombinezon. Bez serwa nie działa ramię, a bez wirnika napęd.
Kombinezon chroni przed ciśnieniem. Ramię, napęd, sonar i latarka potrzebują baterii.
Do oddychania poza bezpiecznym powietrzem potrzebna jest osobna butla. Bojowy multitool bez wkładu tarczy nadal działa jako
broń i narzędzie, lecz nie blokuje pocisków. Pozostałe multitoole nie potrzebują
wkładu tarczy. Moduły są osobnymi przedmiotami wkładanymi do slotów, nie bonusami
odblokowywanymi samym posiadaniem ich w ekwipunku.

Kombinezony kosztują bazowo **10 000 marek** i są sprzedawane wyłącznie przez
[przypisanych handlarzy](FACTION-COLORS.md#sprzedaż-kombinezonów).
Zakup ani craft kombinezonu/broni nie dołącza modułów.

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
| 1 | Bateria | Zasilanie |
| 2 | Obsługiwana skrzynka amunicji | Amunicja ramienia |
| 3 | Moduł serwa (`aegisservomodule`) | Naprawa, spawanie, obrona i chwytak |
| 4 | Moduł wirnika (`aegisimpellermodule`) | Wspomaganie pływania |
| 5 | Kompresor (`aegiscompressormodule`) | Automatyczne napełnianie zwykłej butli |
| 6 | Butla tlenowa | Zapas do oddychania |

Bez serwa nie ma ramienia ani jego funkcji; przyciski ramienia są nieaktywne.
Wyjęcie serwa zwalnia trzymany cel, zatrzymuje naprawę i anuluje oczekujący
strzał. Wirnik z baterią zwiększa docelową prędkość pływania o 50%. Panel pokazuje
poziom tlenu, zamontowane moduły oraz pracę napędu. Przycisk **Pokaż sloty**
otwiera natywną siatkę modułów, baterii i amunicji. Zwiń panel Aegis albo
kliknij **Schowaj sloty**, aby ją zamknąć.

W suchym pomieszczeniu z bezpiecznym powietrzem postać oddycha z otoczenia.
Kompresor uzupełnia wtedy zwykłą butlę w tempie 2% na sekundę i zużywa 0,2%
baterii na sekundę pracy. Pod wodą, w próżni i w niebezpiecznej atmosferze
postać oddycha z butli także przy rozładowanej baterii. Kompresor obsługuje
butle oznaczone w grze jako napełnialne.

Boty noszące Aegis montują dostępne serwa, wirniki i kompresory. Przy 10% tlenu
lub mniej szukają pełniejszej butli przed pozostałym wyposażeniem.

## Craftowanie

Moduły wytwarza się w fabrykatorze lub fabrykatorze wojskowym. Nie są
sprzedawane przez sklepy. Podane poziomy oznaczają mechanikę / elektrykę.

| Przedmiot | Materiały | Czas | Umiejętności |
|---|---|---|---|
| Wkład tarczy | 2 stopy tytanowo-aluminiowe, 2 miedzi, 1 FPGA, 1 fulgurium | 30 s | 45 / 55 |
| Moduł serwa | 2 stopy tytanowo-aluminiowe, 2 miedzi, 1 FPGA, 1 stal | 40 s | 60 / 40 |
| Moduł wirnika | 2 stale, 1 stop tytanowo-aluminiowy, 1 miedź, 1 plastik | 30 s | 50 / 25 |
| Kompresor | 1 stal, 1 miedź, 1 plastik, 1 FPGA | 30 s | 45 / 25 |

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
spawnitem aegiscompressormodule inventory 1
spawnitem oxygentank inventory 1
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

Kompresor korzysta ze sprite’a przenośnej pompy z gry. Pozostałe grafiki
wygenerowano wbudowanym narzędziem image generation, bez skalowania lub
przemalowywania plików źródłowych. [Komplet promptów](modular-assets/PROMPTS.md).

## Sprawdzenia

```powershell
python tools/run_tests.py
python tools/validate_content.py --mod System-Aegis-No-Headsets --game 'D:/SteamLibrary/steamapps/common/Barotrauma'
python tools/package_mod.py --mod System-Aegis-No-Headsets --package-name System-Aegis
```

Testy obejmują limit blokad, kolejkę regeneracji, brak zasilania, pauzę,
przekładanie i odtwarzanie wkładu, natywny float stanu, przechwytywanie pocisków,
limit predykcji klienta, synchronizację modułów, przerwanie naprawy oraz
anulowanie strzału po wyjęciu serwa. Sprawdzono XML, składnię Lua 5.2,
referencje i przezroczystość grafik oraz identyfikatory materiałów z gry.
