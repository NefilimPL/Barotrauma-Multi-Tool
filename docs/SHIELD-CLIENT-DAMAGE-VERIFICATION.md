# Tarcza — lokalne obrażenia cofane przez serwer (1.3.15)

Zgłoszenie z 2026-11-15: po poprawieniu smug gracz nadal widzi obrażenia,
które wyglądają na natychmiast leczone. Gracz nie nosi słuchawek Aegis.

## Przyczyna

Wersja 1.3.14 poprawiała wyłącznie koniec smugi w `LaunchProjSpecific`.
Multiplayerowy klient nadal wykonywał `HandleProjectileCollision`,
`Attack.DoDamageToLimb` i `Character.DamageLimb`. Powstawały lokalne rany,
spadek zdrowia, impuls i efekt bólu. Serwer zatrzymywał pocisk przed atakiem,
więc następny stan zdrowia z serwera cofał te lokalne obrażenia. Była to
korekta sieciowa, a nie leczenie przez tarczę.

Na natywnym kliencie odtworzono spadki **100 → 56 → 12** i wzrost
`DamageOverlayTimer` do **0,44**, mimo że na serwerze było sześć bloków,
zero wywołań obrażeń i zdrowie 100. Zarejestrowano pięć lokalnych wywołań
ataku. [Klient przed](combat/shield-client-health-before.txt) ·
[Serwer przed](combat/shield-client-health-server-before.txt).

## Poprawka

Moduł `CombatTool.shield_client` śledzi wyłącznie aktualnie wykonywany
hitscan klienta. Przy przecięciu potwierdzonej tarczy przerywa natywną kolizję
przed atakiem, bólem, krwią i impulsem. Blok wyznacza z bieżącej pozycji
fizyki, a smugę kończy na interpolowanym łuku renderera. Przywraca natywny
limit celów po skanie i czyści dane przy zakończeniu rundy/przeładowaniu.

Nie podnosi zdrowia, nie usuwa ran po trafieniu i nie nadaje postaci ogólnej
odporności. Zachowuje wcześniejsze trafienia w inne cele, ściany, kierunek
tarczy, własne pociski, friendly fire, koszt energii oraz limit świeżości
potwierdzenia 0,5 s. Serwer nadal sam decyduje o rzeczywistych obrażeniach
i energii. Skan bez przecięcia tarczy wykonuje zwykłą natywną kolizję.

## Próby

Izolowany serwer i rzeczywisty klient Barotrauma 1.13.5.0 / LuaCs c6e8829,
ten sam zestaw 15 modów, w tym Enhanced Armaments i Neurotrauma CS.
Broń `scp_python`, amunicja `scp_357round`, AI walki, około 550–600 jednostek
odległości i rzeczywiste wejście celowania klienta. `GodMode=false`.
Słuchawki zdjęto i sprawdzono brak ochrony/leczenia przez `BMTHeadsets`.

Zdrowie i rany są resetowane **raz podczas przygotowania**, przed ostrzałem.
W trakcie strzałów test utrzymuje wyłącznie tlen, ochronę przed ciśnieniem
i zasilanie broni. Nie leczy postaci ani nie przywraca jej zdrowia.

Próba po zmianie wymaga zera lokalnych wywołań ataku, zdrowia co najmniej
99,99 i braku wzrostu efektu bólu. Liczba natywnych odtworzeń strzału na
kliencie jest liczona osobno od strzałów serwera; test wymaga sprawdzenia
wszystkich zaobserwowanych odtworzeń. Nie zakłada, że warstwa replikacji
zawsze odtworzy każdą smugę serwera.
[Klient po](combat/shield-client-health-after.txt) ·
[Serwer po](combat/shield-client-health-server-after.txt).

W końcowej próbie: **sześć strzałów i bloków serwera, sześć odtworzeń klienta,
sześć smug na łuku, zero lokalnych ataków, minimalne zdrowie 100,
maksymalny efekt bólu 0**. Wcześniejsza próba również utrzymała zdrowie 100
bez lokalnych obrażeń, ale odtworzyła pięć z sześciu strzałów na kliencie.

Kontrola z wyłączoną tarczą i tą samą bronią: jeden strzał, zero bloków,
rzeczywiste wywołanie obrażeń na serwerze, zdrowie około 45,45; klient
naliczył spadek 100 → 56 i efekt bólu 0,44. Potwierdza to zachowanie zwykłych
trafień bez tarczy. [Klient](combat/shield-client-health-control-client.txt) ·
[Serwer](combat/shield-client-health-control-server.txt).

Regresje automatyczne obejmują brak chwilowego uszczerbku, kontrolę bez tarczy,
tył, start wewnątrz łuku, niskie zasilanie, nieaktualne potwierdzenie, ściany,
różnicę pozycji fizyki i renderera, zachowanie wcześniejszego celu, kolejne
śruty, przywrócenie limitu celów i czyszczenie rundy. Test przed poprawką
wykazywał lokalne obrażenia; po zmianie przechodzi.

Cały zestaw: **473 testy automatyczne**, walidacja 13 XML i 43 modułów Lua 5.2,
zasobów i identyfikatorów receptur oraz przegląd kodu — bez błędów.

Skrypty natywne: [klient](../tests/runtime/shield_tracer_client.lua) i
[serwer](../tests/runtime/shield_host_server.lua), wyłącznie w odrębnym
Sandboxie z klientem `ShieldHost`. Najpierw uruchom skrypt klienta, potem
serwera. Próba nie obejmuje Steam P2P, dużych opóźnień ani wszystkich typów
pocisków modowych. Lokalne przewidywanie korzysta z ostatniego potwierdzenia;
rzeczywisty stan zdrowia i zużycie energii zawsze pochodzą z serwera.
