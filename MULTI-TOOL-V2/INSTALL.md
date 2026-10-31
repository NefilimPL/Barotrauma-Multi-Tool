# MULTI-TOOL-V2 1.1.1 — Aegis

Wypakuj ten folder do `Barotrauma/LocalMods/` i włącz pakiet w grze.
Wymagane jest zgodne **Lua for Barotrauma / LuaCs na kliencie i serwerze**.
Punktem zgodności jest Barotrauma 1.13.5.0 i LuaCs `c6e8829`.

Aegis powstaje w fabrykatorze z kompozytowego multitoola, 2 stopów
tytanowo-aluminiowych, 2 miedzi, 1 FPGA i 1 fulgurium.
Broń zajmuje dwie ręce, a po schowaniu jeden zwykły slot.

- Slot 1: broń, narzędzia i latarka.
- Slot 2: tarcza.
- Oba sloty: bateria lub pręt paliwowy.
- Włącz checkbox obrażeń, aby zezwolić na strzały i tarczę, również u botów.
- U gracza wyłącz obrażenia, aby spawać/ciąć; gaśnica ma pierwszeństwo.
- Bot sam dobiera funkcję techniczną do zadania, bez włączania obrażeń.
- Jakość broni daje 1 / 2 / 3 / 4 odbicia pierścieni.

Podgląd animacji: [Assets/Combat/preview.html](Assets/Combat/preview.html).
Balans: `Lua/CombatTool/config.lua`.

Po aktualizacji zastąp stary folder moda i uruchom grę ponownie. Samo
`reloadlua` nie przeładowuje definicji XML latarki.
Diagnostyka w konsoli F3: `aegis_status` (bez prefiksu `lua`).
Wynik pokazuje tryb, zgodę na obrażenia, oba źródła zasilania, błąd rysowania
i dopuszczenie zwykłego ogniwa baterii w obu slotach.
LuaCs: https://github.com/evilfactory/LuaCsForBarotrauma
