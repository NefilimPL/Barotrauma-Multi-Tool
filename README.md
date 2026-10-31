# Barotrauma-Multi-Tool

Mod Barotrauma z kompozytowym multitool'em oraz dwuręcznym **bojowym multitool'em Aegis**.

Wersja Aegis wymaga [Lua for Barotrauma / LuaCs](https://github.com/evilfactory/LuaCsForBarotrauma)
na kliencie i serwerze. Punktem zgodności jest Barotrauma **1.13.5.0**;
testowy serwer używa wydania LuaCs z 27.10.2026, commit `c6e8829`.
Starszy multitool nadal ma własną, dotychczasową definicję XML.

## Instalacja

1. Zainstaluj zgodne LuaCs według instrukcji jego projektu, także na serwerze.
   Same pozostałe po starej instalacji pliki `Lua/` nie wystarczą.
2. Skopiuj folder `MULTI-TOOL-V2` do `Barotrauma/LocalMods/`.
3. Włącz pakiet `MULTI-TOOL-V2` i uruchom grę ponownie. Nie włączaj jednocześnie
   dwóch kopii tego samego pakietu ze Workshop i LocalMods.
4. W fabrykatorze szukaj **Bojowy multitool Aegis**, identyfikator `combatmultitool`.

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

Własne grafiki PNG z przezroczystością są w `MULTI-TOOL-V2/Assets/Combat/`.
Arkusze pracy tarczy, trafienia, rozpadu i porażenia mają po 16 klatek.
Prompty i wymiary zapisano w `Assets/Combat/PROMPTS.md`.

Wszystkie koszty, obrażenia, czasy i limity są w
`MULTI-TOOL-V2/Lua/CombatTool/config.lua`. Po zmianie uruchom ponownie grę
lub użyj konsolowego `reloadlua` na serwerze i klientach.

## Sprawdzenia

Wersja 1.1.4 wprowadza jeden wspólny slot zasilania i automatyczną zgodę
na walkę dla botów. Dźwięk wystrzału korzysta z natywnego nagrania broni
elektromagnetycznej z cichą, krótką warstwą wyładowania. Usunięto tonalne
przemiatanie z generowanych efektów i skrócono odbicia oraz ładowanie.

Wersja 1.1.3 dodaje oryginalne przestrzenne efekty audio, osobne dla wystrzału,
NPC, powierzchni i odbić, oraz krótki sygnał ładowania. Pierścień pulsuje,
ma obracające się jasne fragmenty i krótki ślad zachowujący trasę odbić.
Trafienie przekazuje natywny impuls, a broń ma niewielki odrzut.
Friendly fire wyłączone chroni sojuszników także przed tym impulsem.
Ładowanie trwa 0,12 s, przerwa po strzale 0,34 s; prędkość lotu wynosi
1050 zamiast 1400. Obrażenia, koszt pojedynczego strzału i zasięg pozostają
takie same. Większa częstotliwość zwiększa obrażenia i zużycie energii
w jednostce czasu. Głośność efektów reguluje standardowa głośność dźwięków gry.

Wersja 1.1.2 zmniejsza broń o 20%, poprawia punkty chwytu i pozycję lampy,
wyrównuje emitery narzędzi do lufy, zmniejsza i wycisza wizualnie tarczę.
Tekstura jest przycinana fragmentami przy ścianach. Renderer używa właściwego
mieszania alfa, a efekty ładowania i trafień mają poprawione punkty zaczepienia.
Pierścienie korzystają z natywnego friendly fire zamiast własnej odporności
sojuszników. Po zmianie definicji XML sprawdź nowo utworzoną broń;
stare przedmioty mogą zachować zapisaną skalę.

Wersja 1.1.1 poprawia błąd rysowania efektów na kliencie oraz ustawia
natywne światło kierunkowe z teksturą stożka. Po aktualizacji uruchom grę
ponownie, aby przeładować XML. Komenda `aegis_status` w konsoli F3 wypisuje
stan broni i sprawdza natywne ograniczenia slotów dla zwykłego ogniwa baterii.
W konsoli klienta kod Lua wykonuje się przez `cl_lua`, na serwerze przez `lua`.

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
