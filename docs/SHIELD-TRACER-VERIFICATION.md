# Tarcza i smugi pocisków — 1.3.14 (2026-11-15)

Zgłoszenie: podczas hostowania serwera kapitan strzela z odległości widzenia,
a pociski wyglądają, jakby przechodziły przez tarczę. Objaw występuje zarówno
w lokalnej, jak i opublikowanej kopii moda.

## Przyczyna odtworzonego objawu

Serwer przechwytuje `Projectile.HandleProjectileCollision`, zanim pocisk
zada obrażenia. Klient multiplayera niezależnie wykonuje natywny hitscan
i wywołuje `LaunchProjSpecific`, aby utworzyć smugę. Klient nie instaluje
serwerowego modułu tarczy. Dlatego końcem smugi pozostawała postać za tarczą,
mimo że serwer zatrzymał pocisk.

Poprawka skraca tylko argument `endLocation` natywnego efektu klienta.
Używa łuku potwierdzonego przez serwer, dopasowanego do aktualnego
`DrawPosition` i `DrawRotation` broni, tak samo jak renderer tarczy. Zachowuje
sprawdzenie ściany między emiterem a łukiem, kierunek ochrony, friendly fire,
wykluczenie własnych strzałów oraz wymagany koszt energii, w tym mnożnik
pręta paliwowego. Dane starsze niż 0,5 s nie służą do skracania smug.
Nie pobiera energii, nie usuwa pocisków i nie zmienia obrażeń na serwerze.

## Próba natywna

Izolowany serwer Barotrauma 1.13.5.0 / LuaCs c6e8829 i rzeczywiście
podłączony klient GPU. Załadowano ten sam zestaw 15 pakietów co w konfiguracji
gracza, w tym Enhanced Armaments, DynamicEuropa i Neurotrauma CS. Pliki
wykonywalne klienta i serwera porównano z instalacją Steam — są identyczne.
Nie zmieniano zapisów gracza ani instalacji Steam w ramach próby.

Kapitan utworzony natywną komendą `spawn captain inside 2 false ShieldCaptain`
otrzymał `scp_python` (Service Revolver), a nie podstawowy `revolver`.
Powtórzenie używa tej broni i `scp_357round`, natywnej AI walki oraz wejścia
celowania przesyłanego przez prawdziwego klienta. Gracz ma normalne zdrowie,
`GodMode=false`, trzyma Aegisa oburącz i celuje w przeciwnika około 550–600
jednostek dalej. Test uzupełnia zasilanie i ochronę przed ciśnieniem/tlenem.

- Przed zmianą: sześć strzałów, sześć bloków, zero wywołań obrażeń na graczu,
  zdrowie 100; wszystkie sześć smug przekraczało łuk i kończyło się za nim.
- Po zmianie: sześć strzałów, sześć bloków, zero obrażeń, zdrowie 100;
  wszystkie sześć natywnych końców smug leży na widocznym łuku o promieniu 80.
  Odczyt pochodzi z argumentów po wykonaniu `LaunchProjSpecific`.
- Po pełnym restarcie klienta z produkcyjnym `visuals.lua`: ponownie
  `TOTAL expected=6 passed=6 failed=0`, sześć bloków, zero obrażeń, zdrowie 100.
  Nie przeładowywano kodu produkcyjnego w trakcie tej próby.
- 463 testy automatyczne przechodzą. Nowa regresja przed poprawką wykazywała
  koniec smugi za tarczą, po poprawce na łuku. Dodatkowe przypadki obejmują
  niską energię, koszt trafienia zależny od obrażeń, pręty paliwowe, własny
  strzał, friendly fire, ściany, tył, start wewnątrz tarczy, brak świeżego
  potwierdzenia i wybór bliższej z dwóch tarcz.
- Walidacja 13 XML, 42 modułów Lua 5.2, zasobów i identyfikatorów receptur,
  przegląd poprawki oraz `git diff --check` — bez błędów.

[Smugi przed](combat/shield-tracer-before.txt) ·
[Smugi po](combat/shield-tracer-after.txt) ·
[Serwer po](combat/shield-tracer-server.txt).

Skrypty [klienta](../tests/runtime/shield_tracer_client.lua) i
[serwera](../tests/runtime/shield_host_server.lua) są wyłącznie do odrębnego
Sandboxa. Wymagają klienta nazwanego `ShieldHost`. Najpierw uruchom skrypt
klienta, potem serwera. Oba muszą być skopiowane do `Lua/Tests` odpowiedniej
testowej kopii moda. Skrypt serwera tworzy postacie i zmienia ekwipunek
gracza. Zakończenie rundy sprząta scenariusz; nie uruchamiaj go w kampanii.
Końcowy komunikat klienta wymaga kompletu smug i zera błędów.

## Zakres i ograniczenia

Odtworzono i poprawiono widoczną smugę przechodzącą przez tarczę. Nie
odtworzono obrażeń od tych zablokowanych pocisków. To nie jest dowód
wykluczający wszystkie możliwe rany w sesji użytkownika. Próba korzysta
z lokalnego połączenia Lidgren z dedykowanym procesem serwera; nie bada
transportu Steam P2P używanego przez menu hostowania ani dużego opóźnienia.
Wskazanie niskiego zasilania pozostaje przewidywaniem na podstawie ostatniego
potwierdzonego stanu; ostateczny blok i koszt zawsze rozstrzyga serwer.
