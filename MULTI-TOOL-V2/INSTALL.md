# MULTI-TOOL-V2 1.1.11 — Aegis

Wypakuj ten folder do `Barotrauma/LocalMods/` i włącz pakiet w grze.
Wymagane jest zgodne **Lua for Barotrauma / LuaCs na kliencie i serwerze**.
Punktem zgodności jest Barotrauma 1.13.5.0 i LuaCs `c6e8829`.

Aegis powstaje w fabrykatorze z kompozytowego multitoola, 2 stopów
tytanowo-aluminiowych, 2 miedzi, 1 FPGA i 1 fulgurium.
Broń zajmuje dwie ręce, a po schowaniu jeden zwykły slot.

- Jeden wspólny slot: broń, tarcza, narzędzia i latarka.
- Zasilanie: jedno ogniwo baterii lub pręt paliwowy.
- Ikonka slotu Aegisa przedstawia baterię i pręt paliwowy.
- Gracz włącza checkbox obrażeń, aby zezwolić na strzały i tarczę.
- U gracza wyłącz obrażenia, aby spawać/ciąć; gaśnica ma pierwszeństwo.
- Bot sam wybiera funkcję techniczną albo walkę/samoobronę, niezależnie
  od ręcznego checkboxa gracza. Zapisane ustawienie checkboxa pozostaje bez zmian.
- Jakość broni daje 1 / 2 / 3 / 4 odbicia pierścieni.
- Obrażenia sojuszników podlegają ustawieniu friendly fire rozgrywki.

Od wersji 1.1.8 obie wersje multitoola dają dokładnie +2 do sterowania,
broni, mechaniki, elektryki i medycyny po każdych 5 minutach trzymania.
Aegis wymaga niewyczerpanego ogniwa lub pręta; mniejszy multitool — pręta.
Schowanie narzędzia lub brak zasilania zatrzymuje licznik, zachowując postęp
w tej rundzie. Przełączanie narzędzi zachowuje jeden wspólny licznik postaci;
dwa multitool’e nie podwajają bonusu. Pierwszy bonus wymaga pełnych 300 sekund.
Przyrost działa także u botów, wymaga LuaCs, respektuje limity umiejętności
i nie jest mnożony przez premię do nauki z pręta ani przez talenty.
Licznik zeruje się po zakończeniu rundy lub przeładowaniu Lua; zdobyte punkty
są zapisywane normalnie przez grę.

Podgląd animacji: [Assets/Combat/preview.html](Assets/Combat/preview.html).
Od wersji 1.1.10 wystrzał używa wybranego rezonatora plazmowego (próbka 3),
a łuk — natywnej animacji Electricity i cząstek ElectricShock z cewki wyładowczej.
Wersja 1.1.7 mocuje początek stożka latarki do obracającego się korpusu broni,
także podczas pionowego celowania i zmiany kierunku patrzenia.
Balans: `Lua/CombatTool/config.lua`.
Broń ma przestrzenne dźwięki broni i trafień, impuls odpychający NPC oraz
pulsujący pierścień ze śladem energii. Wersja 1.1.5 skraca ładowanie do 0,10 s
i przerwę po strzale do 0,28 s: około 20% więcej strzałów przy trzymaniu spustu.
Broń ma natywny celownik przy celowaniu. Wersja 1.1.6 daje jej własny dźwięk
wyładowania kondensatora, mocniejszy rozbłysk trafienia i o 15% większe odpychanie.
Trafienie postaci lub powierzchni ma 15% szansy na łańcuch prądu do maksymalnie
trzech innych postaci. Każdy przeskok ma zasięg 90 jednostek i wymaga wolnej
drogi; ściany go blokują. Jeden pocisk może wywołać jeden łańcuch, bez ponownego
trafiania tych samych postaci. Pierwsze porażenie daje 1 oparzenia i 0,2 s
ogłuszenia; każde następne jest o 25% słabsze. Friendly fire podlega ustawieniom
rozgrywki. Serwer rozstrzyga losowanie. Platformy, schody i kolizje naprawcze
zniszczonych ścian nie odbijają pierścieni; pełne ściany i zamknięte włazy nadal tak.
Podgląd dźwięków: [Assets/Combat/Audio/preview.html](Assets/Combat/Audio/preview.html).
W multiplayer serwer i wszyscy gracze powinni mieć tę samą wersję moda.
Wersja 1.1.4 zmienia dźwięki na krótkie, cięższe wystrzały i suche wyładowania,
łączy całe zasilanie w jednym slocie i pozwala botom samodzielnie się bronić.
Przed aktualizacją wyjmij oba źródła ze starszej wersji broni — nowa ma jeden slot.

Po aktualizacji zastąp stary folder moda i uruchom grę ponownie. Samo
`reloadlua` nie przeładowuje definicji XML celownika ani dźwięków.
Diagnostyka w konsoli F3: `aegis_status` (bez prefiksu `lua`).
Wynik pokazuje tryb, skuteczne zezwolenie na walkę, wspólne źródło zasilania,
błąd rysowania i dopuszczenie zwykłego ogniwa baterii.
LuaCs: https://github.com/evilfactory/LuaCsForBarotrauma
