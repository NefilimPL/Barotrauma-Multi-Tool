# System Aegis

**System Aegis** to samodzielny, pełny mod wyposażenia do Barotraumy.
Zawiera narzędzia techniczne i bojowe, komunikatory, odkurzacz z plecakiem
oraz kombinezon. Wymaga LuaCs na kliencie i serwerze.

Mod zawiera **kombinezon serwomanipulacyjny Aegis** z jednym
ramieniem do automatycznej naprawy i spawania, obrony lub chwytania celu.
Wersja V2 ma widoczne sloty baterii/pręta i skrzynki amunicji, obieg
oddechowy bez butli, latarki i automatyczną wymianę zapasów przez AI.
W **1.3.22** wyłączono automatyczne chwytanie postaci przez AI. Bot nadal
naprawia i broni, ale nie podnosi już nieprzytomnych sojuszników chwytakiem.
Ręczny chwyt gracza działa jak wcześniej.

Pomiary obejmują osobne sceny wszystkich ośmiu przedmiotów. Największy
spadek czasu klatki uzyskano przy widocznych naprawach kombinezonów.
[Wyniki porównania i stan testów](docs/PERFORMANCE.md).

[Dokumentacja projektu](docs/README.md) · [Historia zmian](CHANGELOG.md)

[Paczka System Aegis 1.3.27](output/System-Aegis-1.3.27.zip).
[Publikacja jako osobny mod](docs/PUBLISH.md).

**Wersja bez komunikatorów, z modułową tarczą i kombinezonem:**
[System Aegis — No Headsets](docs/NO-HEADSETS.md). Osobny folder
`System-Aegis-No-Headsets/`; pełna wersja pozostaje bez zmian.

System Aegis wymaga [Lua for Barotrauma / LuaCs](https://github.com/evilfactory/LuaCsForBarotrauma)
na kliencie i serwerze. Punktem zgodności jest Barotrauma **1.13.5.0**;
testowy serwer używa wydania LuaCs z 27.10.2026, commit `c6e8829`.
Kompozytowy multitool i klucz-śrubokręt są pełnoprawnymi elementami System Aegis.

## Zakup w sklepach

W zwykłych sklepach kampanii dostępne są wszystkie przedmioty moda:

| Przedmiot | Cena bazowa |
|---|---:|
| Klucz-śrubokręt 2 w 1 Aegis | 57 mk |
| Kompozytowy multitool Aegis | 1300 mk |
| Bojowy multitool Aegis | 2000 mk |
| Komunikator Aegis | 500 mk |
| Komunikator Aegis Mk II | 1000 mk |
| Odkurzacz zbierający Aegis | 1800 mk |
| Plecak zbierający Aegis | 1400 mk |

Oferty mają co najmniej jedną sztukę (klucz 5–10). Ceny bazowe podlegają
zwykłym modyfikatorom kampanii, reputacji i promocji. Zapas istniejącego
sklepu może wymagać odświeżenia przy przejściu do nowej lokacji.

## Instalacja

1. Zainstaluj zgodne LuaCs według instrukcji jego projektu, także na serwerze.
   Same pozostałe po starej instalacji pliki `Lua/` nie wystarczą.
2. Skopiuj folder `System-Aegis` do `Barotrauma/LocalMods/`.
3. Włącz pakiet **System Aegis** i uruchom grę ponownie. Nie włączaj jednocześnie
   dwóch kopii tego samego pakietu ze Workshop i LocalMods.
4. W fabrykatorze szukaj **Bojowy multitool Aegis**, identyfikator `aegiscombattool`.

System Aegis jest osobnym pakietem z nowymi identyfikatorami. Nie zastępuje
automatycznie wyposażenia ze starszych zapisów. Utwórz nowe egzemplarze;
przed migracją zachowaj kopię zapisu i opróżnij stare pojemniki.

## Komendy tworzenia przedmiotów (F3)

W trakcie rozgrywki lub w testerze edytora otwórz konsolę **F3** i wpisz:

```text
enablecheats
```

Następnie użyj wybranej komendy. `inventory` tworzy przedmiot w ekwipunku
kontrolowanej postaci. Na serwerze potrzebujesz uprawnień do tych komend.
Komendy kopiuj przyciskiem kopiowania bloku kodu. Dostępne są też w
[zwykłym pliku tekstowym](docs/spawn-commands.txt).

Kombinezon serwomanipulacyjny Aegis V2 z baterią i amunicją do testowania:

```text
spawnitem aegisservosuit inventory 1
spawnitem batterycell inventory 1
spawnitem pulselaserammobox inventory 1
```

Załóż kombinezon w slocie ubrania zewnętrznego. Do pierwszego slotu włóż
baterię albo pręt reaktora (`spawnitem fuelrod inventory 1`), do drugiego
skrzynkę amunicji lasera pulsacyjnego lub działa Gaussa. Ramię dostosowuje
pocisk do skrzynki i oddaje z niej trzy razy tyle strzałów co wieżyczka. Obieg
oddechowy korzysta z zasilania kombinezonu. Po aktualizacji utwórz nowy egzemplarz,
aby otrzymać aktualne komponenty i skalę złożonego przedmiotu na ziemi.
W panelu po prawej wybierz naprawę/spawanie, obronę lub chwytak.
Przycisk „Ramię włączone/wyłączone” przełącza funkcję ramienia.
Chwytak: wybierz ten tryb, wskaż cel kursorem, przytrzymaj **PPM (Celuj)**
i naciśnij **E (Użyj)**, potem puść klawisze. Cel pozostaje zawieszony,
a osoba staje się chwilowo bezwładna. Ponowne E przy trzymanym PPM puszcza cel.
Przy zmienionym sterowaniu użyj przycisków pokazanych w panelu kombinezonu.
Łapie jeden luźny, ruchomy przedmiot albo istotę poniżej limitu masy;
nie wyrywa zamocowanych urządzeń ani rzeczy z ekwipunków.
Zasięg wynosi 300 jednostek gry. Chwyt gracza nie ma limitu 5 sekund;
zmiana trybu, przeszkoda, wyjście poza zasięg, brak energii lub zdjęcie
kombinezonu zwalnia cel. Nie trzeba trzymać narzędzia w ręce.
Przycisk `»` chowa prawy panel; zakładka **Ramię** otwiera go ponownie.
**Sonar** otwiera niezależny panel po lewej. Jego przycisk zasilania oraz
tryby aktywny/pasywny sterują natywnym sonarem. `«` zwija go do małego radaru,
a `+` rozwija ustawienia. Wyłączony i zwinięty sonar jest niewidoczny.
**Minerały** włącza skaner w trybie aktywnym. Sonar wyłącz
jego przyciskiem zasilania, jeśli ma przestać pobierać energię i nadawać impulsy.
[Pełna instrukcja kombinezonu](docs/AEGIS-SUIT.md).

Odkurzacz Aegis:

```text
spawnitem aegisvacuum inventory 1
```

Plecak zbierający Aegis, wymagany do pracy odkurzacza:

```text
spawnitem aegisvacuumpack inventory 1
```

Załóż plecak w slocie torby na pasie, włóż naładowaną baterię do odkurzacza
i weź odkurzacz w obie ręce. Zwykłą baterię utworzysz komendą
`spawnitem batterycell inventory 1`.

Komunikator regeneracyjny Aegis:

```text
spawnitem aegisheadset inventory 1
```

Komunikator osłonowy Aegis Mk II:

```text
spawnitem aegisheadsetmk2 inventory 1
```

Bojowy multitool Aegis:

```text
spawnitem aegiscombattool inventory 1
```

Kompozytowy multitool Aegis:

```text
spawnitem aegiscompositetool inventory 1
```

Klucz-śrubokręt 2 w 1 Aegis:

```text
spawnitem aegiswrenchscrewdriver inventory 1
```

Zasilanie i butle do testowania narzędzi:

Zwykłe baterie — 3 sztuki:

```text
spawnitem batterycell inventory 3
```

Baterie fulgurium — 3 sztuki:

```text
spawnitem fulguriumbatterycell inventory 3
```

Pręt paliwowy:

```text
spawnitem fuelrod inventory 1
```

Pręt torowy:

```text
spawnitem thoriumfuelrod inventory 1
```

Pręt fulgurium:

```text
spawnitem fulguriumfuelrod inventory 1
```

Butla z tlenem:

```text
spawnitem oxygentank inventory 1
```

Butla z tlenitem:

```text
spawnitem oxygenitetank inventory 1
```

Liczba po `inventory` oznacza ilość. Aby utworzyć przedmiot pod kursorem,
zamień `inventory` na `cursor`:

```text
spawnitem aegisheadsetmk2 cursor 1
```

Po utworzeniu włóż baterię lub pręt do odpowiedniego urządzenia; komunikatory
przyjmują baterie, a kompozytowy multitool wymaga pręta do pasywnej nauki.

Stan i ostatnie koszty energii sprawdzisz komendami `aegis_headset_status`
(komunikatory) oraz `aegis_status` (bojowy multitool). W multiplayer koszty
odczytuj z konsoli serwera.

## Obsługa Aegis

Broń zajmuje dwie ręce po wyposażeniu i jeden zwykły slot po schowaniu.
Jeden wspólny slot zasila broń, tarczę, narzędzia i latarkę. Przyjmuje ogniwo
baterii lub pręt paliwowy. Koszty wszystkich funkcji odejmowane są od tego
samego źródła; jego wyczerpanie zatrzymuje strzelanie, tarczę i narzędzia.

Pozostają trzy checkboxy:

- **Włącz zadawanie obrażeń NPC:** pozwala strzelać pierścieniami i aktywować
  tarczę przy celowaniu. Wyłączenie anuluje ładowanie, wygasza tarczę i własne
  pierścienie gracza w locie. Bot sam ocenia zgodę na walkę według rzeczywistego
  zadania; nie nadpisuje ręcznego ustawienia gracza.
- **Włącz tryb gaśnicy:** u gracza ma pierwszeństwo przed strzelaniem.
- **Włącz tryb przecinarki:** po wyłączeniu obrażeń przełącza spawarkę na cięcie.

Naprawa urządzenia przez standardowy interfejs uruchamia tylko naprawę.
Spust nie włącza wtedy równocześnie strzelania ani spawania. Latarka działa
podczas celowania, także przy wyłączonych obrażeniach. Tarcza może chronić
podczas pracy technicznej, jeśli zgoda na obrażenia pozostaje włączona.

Pierścienie odbijają się od ścian, kadłuba, podłoża i zamkniętych drzwi;
otwarte drzwi i dziury przepuszczają impuls. Limit odbić wynosi odpowiednio
**1 / 2 / 3 / 4** dla jakości zwykłej / dobrej / doskonałej / mistrzowskiej.
Każde odbicie osłabia obrażenia o 15%. Trafienie postaci kończy lot.
Pierścienie pomijają strzelca i nie niszczą kadłuba. Trafienia sojuszników
podlegają natywnemu ustawieniu friendly fire rozgrywki, jak zwykłe pociski.

Tarcza osłania przednią część głowy i tułowia. Przechwytuje standardowe
pociski fizyczne, hitscan oraz wrogie pierścienie. Kontakt przeciwnika
daje lekkie porażenie, z przerwą co najmniej 0,75 s, i kosztuje więcej
niż pojedyncze przechwycenie pocisku. Wyczerpanie energii powoduje rozpad
i trzysekundową blokadę. Jeżeli energii nie wystarcza na kontakt, ostatnia
energia przepada, a dany pocisk przechodzi dalej. Ataki od tyłu, ciśnienie
i wybuch obok postaci nie są blokowane.

## Boty

Bot wybiera funkcję według faktycznie wykonywanego zadania. Do walki używa
pierścieni, do wycieków spawarki, do napraw urządzeń standardowego narzędzia,
a do pożarów gaśnicy. Techniczne checkboxy nie ograniczają doboru funkcji
przez AI, a ich zapisane ustawienia nie są nadpisywane. Bot samodzielnie
zezwala na użycie bojowe przy faktycznym zadaniu walki/samoobrony, również
przy wyłączonym ręcznym checkboxie gracza. Samo zlecenie oczekujące w kolejce
nie uruchamia strzelania. W pracy technicznej nadal wykonuje jedną funkcję.

Uzupełnianie wspólnego slotu korzysta z natywnych zadań podnoszenia i wkładania
przedmiotów oraz zachowuje wymagania dostępu i dojścia. W walce bot wymienia
również źródło, w którym pozostała energia niewystarczająca na pełny strzał.
Przy aktualizacji z wersji dwuslotowej wyjmij oba źródła przed podmianą moda.

## Wytwarzanie

Fabrykator lub fabrykator wojskowy, 30 s, mechanika 50 i elektryka 40:

- 1 kompozytowy multitool;
- 2 stopy tytanowo-aluminiowe;
- 2 miedzi;
- 1 układ FPGA;
- 1 fulgurium.

Zasilanie nie jest częścią receptury. Fabrykator stosuje standardowe zasady
oddawania zawartości zużywanego narzędzia jako osobnych przedmiotów.
Dekonstrukcja Aegis odzyskuje część materiałów; zawarte źródła są oddawane.

## Grafiki i balans

Własne grafiki PNG z przezroczystością są w `System-Aegis/Assets/AegisCombat/`.
Arkusze pracy tarczy, trafienia, rozpadu i porażenia mają po 16 klatek.
Prompty i wymiary: [PROMPTS.md](docs/combat-assets/PROMPTS.md).
Podglądy: [grafika i animacje](docs/combat-assets/preview.html),
[dźwięki](docs/combat-assets/audio/preview.html).
Instrukcja instalacji: [INSTALL.md](docs/INSTALL.md).

Folder `System-Aegis/` zawiera wyłącznie pliki używane przez grę.
Dokumentacja i podglądy znajdują się w `docs/`, generatory w `tools/`,
a gotowe paczki i alternatywne próbki dźwięków w `output/`.

Wszystkie koszty, obrażenia, czasy i limity są w
`System-Aegis/Lua/AegisCombat/config.lua`. Po zmianie uruchom ponownie grę
lub użyj konsolowego `reloadlua` na serwerze i klientach.

## Sprawdzenia

Historyczne opisy wydań i ich prób są w [historii zmian](CHANGELOG.md).

```powershell
python -m pip install -r tests/requirements.txt
python tools/run_tests.py
python tools/validate_content.py --game 'D:/SteamLibrary/steamapps/common/Barotrauma'
```

Skrypty `tests/runtime/` uruchamia się wyłącznie na osobnej kopii serwera
w trakcie rundy Sandbox. Nie należą do paczki moda i nie wolno kopiować
testowego `keepalive.lua` do zwykłej rozgrywki. `tools/prepare_runtime.py`
tworzy lokalną kopię w ignorowanym `.runtime/server`; oficjalny patch LuaCs
trzeba zastosować do tej kopii. Wyniki i ograniczenia testów są w
`docs/COMBAT-VERIFICATION.md`.

Zgodność ze skryptowymi laserami innych modów oraz pełna próba dwóch
klientów z opóźnieniem sieciowym wymagają osobnych testów w grze.
