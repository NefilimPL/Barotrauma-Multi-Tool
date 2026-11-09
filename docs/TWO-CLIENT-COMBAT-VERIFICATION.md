# Rzeczywista sesja dwóch klientów — 1.3.11

Próba 2026-11-06/07, Europe/Warsaw. Prywatny serwer i **dwa rzeczywiście
połączone klienty GPU**, CombatA i CombatB. Barotrauma 1.13.5.0 / LuaCs
c6e8829; źródła moda 1.3.11 bez zmian produkcyjnych.

## Wynik

Nie odtworzono trwałego załamania FPS do kilku–kilkunastu klatek/s.
Strzelanie i blokowanie miało mierzalny koszt na obu klientach, również
u obserwatora. Każda faza trwała 18 s; pomiar odrzuca pierwsze 3 s:

| Scenariusz | FPS A | FPS B | p95 czasu klatki A / B |
|---|---:|---:|---:|
| Jeden cel, normalne zdrowie, strzela A | 133,5 | 134,0 | 14,91 / 13,99 ms |
| 15 bliskich celów, normalne zdrowie, strzela A | 114,9 | 114,8 | 14,80 / 14,68 ms |
| Ciągle blokuje A; 15 emiterów + strzela B | 119,2 | 113,9 | 14,66 / 14,63 ms |
| Ciągle blokuje B; 15 emiterów + strzela A | 98,6 | 99,3 | 15,93 / 16,03 ms |

Punkt odniesienia A bez strzelania: około 174 FPS przy jednym celu i 163 FPS
przy grupie. Dodatkowe serie przez B potwierdziły podobny koszt po zamianie
ról. [Pełna tabela CSV](combat/two-client/summary.csv) zawiera średnią,
p95/p99, maksimum, Draw/Update i liczbę klatek przekraczających 33/50 ms.

Pojedyncze przycięcia nadal występowały: do **73 ms** podczas końcowego
masowego ostrzału na B; w fazie bez ostrzału do **162 ms**, a we wcześniejszym
pomiarze grupy bez strzelania do **420 ms**. Dobra średnia nie oznacza braku
przycięć. Te próby nie ustaliły przyczyny wszystkich pojedynczych skoków.

## Potwierdzenie rzeczywistych trafień

- Jeden cel: A oddał 45 strzałów, serwer potwierdził 44 trafienia i 44 spadki
  zdrowia. Po zamianie ról B: 45 strzałów i 45 trafień.
- Grupa 15 postaci: po 47 strzałów, 45 trafień i 24 zdarzenia łuku dla A/B.
- Osobny przebieg z maksimum zdrowia 100 i bez GodMode celów: 45 trafień
  pojedynczego celu oraz 44 trafienia i 18 łuków w grupie. Wywołania obrażeń
  w grupie objęły osiem różnych postaci.
- Ciągły ostrzał tarcz: **510 natywnych strzałów ze strzelb**, **90 strzałów
  Aegis sojusznika**, **558 zdarzeń przechwycenia**: 299 przez A, 259 przez B.
  Strzelba używa amunicji z ośmioma śrutami; licznik zdarzeń blokady nie jest
  liczbą pojedynczych śrutów.
- Każda tarcza była aktywna przez około 1080 aktualizacji w 18 s. W tych
  końcowych fazach nie było aktualizacji z martwym obrońcą.
- Oba klienty niezależnie odebrały 299 i 259 zdarzeń shieldhit, zachowały
  kontrolowaną postać, `authoritative=false` i `visualError=nil`.
  Analizator potwierdził **14 wybranych faz na każdym kliencie**: każda ma
  ponad 500 próbek i około 15 s rzeczywistych odstępów między Draw.

Liczniki: [ostrzał](combat/two-client/combat-session-server.txt),
[normalne zdrowie](combat/two-client/combat-session-followup.txt),
[ciągłe tarcze](combat/two-client/combat-session-shield-stress.txt).
Metryki: [klient A](combat/two-client/client-A-metrics.jsonl),
[klient B](combat/two-client/client-B-metrics.jsonl).

## Warunki i ograniczenia

Klienty i serwer współdzieliły **jeden komputer**, CPU/GPU i localhost.
Okna 960×540, VSync wyłączony, wyłączone usypianie nieaktywnego okna w sondzie.
Plik konfiguracji żądał 144 FPS, ale zmierzony Draw potrafił przekraczać tę
wartość; tabela podaje faktyczne odstępy między Draw. Nie są to pomiary
komputerów znajomych ani opóźnień Internetu. Rejestrator ma własny narzut.

Serwer uruchomił Neurotraumę C# 2.0.5. Klienty miały zgodne definicje pakietu
NT; ich LuaCs raportował `CSharp is disabled`. Próba nie obejmuje dodatkowej
pracy klientowego pluginu C# NT ani pełnego zestawu modów użytkownika.

Aegis strzelał przez natywne wejścia Aim/Shoot połączonego klienta,
synchronizację wejść i serwerowe użycie trzymanej broni. Nie wysyłano ręcznie
zdarzeń hit/shieldhit do renderera. Cele były prawdziwymi postaciami z
wyłączoną AI, z fizyką, obrażeniami i synchronizacją. Sceny obejmowały
pomieszczenie i wodę; nie odwzorowują pełnej walki z ruchomymi przeciwnikami.

Pierwsze serie używały zwiększonego zdrowia; potem wykonano osobne próby
z maksimum 100. Pierwsze długie fazy blokowania zakończyły się śmiercią
obrońców od NT, dlatego **ich średnich nie użyto do oceny ciągłej tarczy**.

Końcowy test ciągły miał 15 nieruchomych natywnych strzelb kierowanych na
obrońcę przez RangedWeapon.Use, natywną amunicję i rzeczywistą tarczę
kierowaną wejściem gracza. Uzupełniano amunicję i energię, a obrońcy mieli
GodMode, aby śmierć nie kończyła obciążenia. Sprawdza to ciągłe pociski,
przechwycenia, efekty i sieć; nie dowodzi szczelności tarczy ani odporności
postaci na wszystkie obrażenia. W drugim przebiegu odnotowano też trzy
trafienia Aegis poza zdarzeniami przechwycenia.

Przerwane przygotowania sondy (ponowne użycie ID po lokalnym usunięciu encji,
próba ponownego zakładania już założonej broni) odrzucono. Właściwy pomiar
podstawowy rozpoczęto w świeżej rundzie; analizator wybiera poprawne fazy.

## Odtworzenie

Testowe pliki nie należą do paczki moda:

- `tests/runtime/CombatSessionStartup.cs`: rzeczywiste czasy klatek/Draw/Update.
- `tests/runtime/combat_session_client.lua`: wejścia i odebrane efekty.
- `tests/runtime/combat_session_server.lua`: dwa klienty i 1/15 celów.
- `tests/runtime/combat_session_followup.lua`: cele z normalnym zdrowiem.
- `tests/runtime/combat_session_shield_stress.lua`: ciągły masowy ostrzał.
- `tools/analyze_combat_session.py`: kontrola próbek, postaci i liczników,
  wybór faz oraz eksport CSV/JSONL.

Bez zmian w kodzie produkcyjnym moda, instalacji Steam i kampanii użytkownika.
