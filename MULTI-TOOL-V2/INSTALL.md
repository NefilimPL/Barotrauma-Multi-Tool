# MULTI-TOOL-V2 1.1.4 — Aegis

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

Podgląd animacji: [Assets/Combat/preview.html](Assets/Combat/preview.html).
Balans: `Lua/CombatTool/config.lua`.
Wersja 1.1.3 dodaje przestrzenne dźwięki broni i trafień, impuls odpychający
NPC oraz pulsujący pierścień ze śladem energii. Odstęp strzałów wynosi około
0,46 s, a lot jest o 25% wolniejszy przy zachowanym zasięgu.
Podgląd dźwięków: [Assets/Combat/Audio/preview.html](Assets/Combat/Audio/preview.html).
W multiplayer serwer i wszyscy gracze powinni mieć tę samą wersję moda.
Wersja 1.1.4 zmienia dźwięki na krótkie, cięższe wystrzały i suche wyładowania,
łączy całe zasilanie w jednym slocie i pozwala botom samodzielnie się bronić.
Przed aktualizacją wyjmij oba źródła ze starszej wersji broni — nowa ma jeden slot.

Po aktualizacji zastąp stary folder moda i uruchom grę ponownie. Samo
`reloadlua` nie przeładowuje definicji XML latarki.
Diagnostyka w konsoli F3: `aegis_status` (bez prefiksu `lua`).
Wynik pokazuje tryb, skuteczne zezwolenie na walkę, wspólne źródło zasilania,
błąd rysowania i dopuszczenie zwykłego ogniwa baterii.
LuaCs: https://github.com/evilfactory/LuaCsForBarotrauma
