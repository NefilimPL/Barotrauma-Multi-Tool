# MULTI-TOOL-V2 1.1.8 — Aegis

Wypakuj ten folder do `Barotrauma/LocalMods/` i włącz pakiet w grze.
Wymagane jest zgodne **Lua for Barotrauma / LuaCs na kliencie i serwerze**.
Punktem zgodności jest Barotrauma 1.13.5.0 i LuaCs `c6e8829`.

Aegis powstaje w fabrykatorze z kompozytowego multitoola, 2 stopów
tytanowo-aluminiowych, 2 miedzi, 1 FPGA i 1 fulgurium.
Broń zajmuje dwie ręce, a po schowaniu jeden zwykły slot.

- Jeden wspólny slot: broń, tarcza, narzędzia i latarka.
- Zasilanie: jedno ogniwo baterii lub pręt paliwowy.
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
Wersja 1.1.7 mocuje początek stożka latarki do obracającego się korpusu broni,
także podczas pionowego celowania i zmiany kierunku patrzenia.
Balans: `Lua/CombatTool/config.lua`.
Broń ma przestrzenne dźwięki broni i trafień, impuls odpychający NPC oraz
pulsujący pierścień ze śladem energii. Wersja 1.1.5 skraca ładowanie do 0,10 s
i przerwę po strzale do 0,28 s: około 20% więcej strzałów przy trzymaniu spustu.
Broń ma natywny celownik przy celowaniu. Wersja 1.1.6 daje jej własny dźwięk
wyładowania kondensatora, mocniejszy rozbłysk trafienia i o 15% większe odpychanie.
Trafienie postaci lub powierzchni ma 15% szansy na przeskok prądu do najbliższej
innej postaci w promieniu 90 jednostek. Ściany blokują przeskok; jeden pocisk
może wywołać go najwyżej raz. Porażenie daje 1 oparzenia i 0,2 s ogłuszenia;
podlega ustawieniu friendly fire. Serwer rozstrzyga losowanie.
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
