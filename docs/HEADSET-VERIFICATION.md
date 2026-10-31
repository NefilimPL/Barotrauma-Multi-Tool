# Komunikatory Aegis — weryfikacja 1.2.1

## Poprawka po zgłoszeniu wyglądu i poboru energii

Wzór natywnego `Limb.DrawWearable` potwierdził przyczynę ogromnych słuchawek:
WearableSprite.Scale nie jest mnożona przez Item.Scale. Regresja najpierw
wykazała wysokość 877,8 px. Oba noszone sprite'y mają teraz skalę 0,035,
czyli 43,89 px przed skalowaniem ragdolla. Grafika przedmiotu w świecie
zachowała dotychczasowy rozmiar. Dwa odwołania do wrench.png mają
compress=false, aby nie kompresować arkusza 93×19 niepodzielnego przez 4.

Renderer ma wypełnioną półprzezroczystą powierzchnię, szerszą poświatę,
minimalną szerokość pola dla pionowego ragdolla i mocniejszy błysk trafienia.
Leczenie i ciśnienie nie nakładają kilku pól na tę samą postać.
Trzy nowe regresje renderera najpierw nie przechodziły, a po poprawce są zielone.

Natywna próba `tests/runtime/headset_idle.lua`, NT CS, bezpieczny okręt:
po 5 s założenia **energia 100%, witalność 100, ciśnienie kadłuba 0**.
Potem zadano próbne oparzenie. Komenda `aegis_headset_status` poprawnie
wypisała **heal:burn -0.5000%**. Nie odtworzono samoistnego drenażu zdrowej
postaci; nie zgadujemy przyczyny w pełnym zestawie modów użytkownika.
Nowa komenda pozwala wskazać dokładny leczony identyfikator w jego grze.

Ponowione próby natywne: 9/9 podstawowej mechaniki i 6/6 NT.
Suite po poprawkach: **132/132 PASS**. Walidacja: 11 XML i 23 moduły Lua.
Przegląd wykrył fałszywy wpis kosztu po zwrocie energii przy błędzie natywnej
metody. Poprawiono go z regresją; odrzucony koszt nie daje też błysku.

Podglądy SVG eksportują faktyczne polecenia rysowania produkcyjnego Lua;
PNG porównania wyrenderowano w przeglądarce headless. To ilustracja geometrii,
nie test GPU Barotraumy ani zrzut postaci z gry. Ponowiona próba ukrytego
klienta nie zwróciła wyniku; natywne GPU i sesja dwóch klientów pozostają
niezweryfikowane. Nie zmieniano instalacji gry użytkownika.

## Weryfikacja bazowa 1.2.0

2026-10-31. Zmiany pozostawiono do przeglądu na istniejącej gałęzi
`dev-autoinjector`, bez scalania, publikowania i modyfikowania instalacji Steam.

## Testy automatyczne

Uruchomiono `python tools/run_tests.py`: **125/125 PASS**.
Obejmuje 82 istniejące regresje oraz testy zasilania, proporcjonalnych
obrażeń, wspólnego limitu leczenia, nieznanych identyfikatorów chorób,
opcjonalności NT, chronionych stanów NT, opłacanej anatomii, providerów,
wyboru ogniw, cooldownu niedostępnego zapasu i protokołu efektów.

`python tools/validate_content.py --game D:/SteamLibrary/steamapps/common/Barotrauma`
sprawdza 11 XML, 23 moduły Lua 5.2, wszystkie lokalne odwołania do zasobów,
wymiary wycinków obu grafik z alfą, nagłówki OGG i identyfikatory receptur.
Obie grafiki mają rzeczywisty rozmiar 1254×1254; wycinki dostosowano do plików.
Cztery OGG powstają z własnej syntezy, a nie z nagrań gry/filmu.

## Natywny serwer

Prywatna kopia w `.runtime/server`, Barotrauma Dedicated Server 1.13.5.0,
LuaCs/Luatrauma `c6e8829`, Sandbox. Nie zmieniano plików gry na Steam.

Bez Neurotraumy: **9/9 prób PASS** w `tests/runtime/headset_integration.lua`:

1. Slot Headset, natywny pojemnik baterii i radio 35000.
2. Rzeczywiste leczenie oparzeń z poborem energii.
3. Całkowite pochłonięcie natywnego ataku i pojedynczy koszt.
4. Częściowa bateria i dokładnie sprawdzona pozostała siła oparzenia.
5. Zwykła wersja otrzymuje normalne trafienia.
6. Odbudowa fizycznej kończyny, połączeń i masy ragdolla.
7. Pobór 5%/s przy ekspozycji na ciśnienie.
8. Ochrona przez rzeczywiste `Character.Update`, przed implozją.
9. Zdjęcie urządzenia nie zostawia odporności na ciśnienie.

Serwer bez klientów wyłącza odległych NPC. Próba ciśnienia jawnie włącza
postać i wykonuje natywny Update, aby rzeczywiście sprawdzić symulację,
a nie otrzymać fałszywe zaliczenie na nieaktualizowanej postaci.

`tests/runtime/headset_ai.lua`: **PASS** natywnej wymiany ogniwa 10% na
zapas z ekwipunku bota, z zachowaniem starego ogniwa. Sprawdzono również
zakończenie zadania i brak błędów sprzątania po udostępnieniu chronionego
settera `AIObjective.IsCompleted` przez LuaCs.

## Opcjonalna Neurotrauma

Osobno włączono kopię **Neurotrauma CS 2.0.7**, Workshop `3744761298`.
Wczytany moduł C# wypisuje własny numer 2.0.5. Ten wariant nie udostępnia
tabel `NT`/`HF`; adapter wykrywa właściciela prefabów zamiast wymagać tabel.
Nie dodano NT do manifestu, receptur ani importów wymaganych do startu.

`tests/runtime/headset_nt.lua`: **6/6 prób PASS** na rzeczywistych efektach:

- Wykrycie NT CS bez dawnych globalnych tabel Lua.
- Opłacane usunięcie znacznika brakującego serca po pełnym procesie.
- Opłacane usunięcie znacznika amputacji po pełnym procesie.
- Zachowanie ochronnego `tshocktimeout`.
- Wspólne zamknięcie stanów operacji na kończynie.
- Zachowanie grupy krwi i znacznika cybernetyki.

Próby są synchroniczne: nie udają długiej kampanii ani pełnej integracji
każdego dodatku do NT. Fizyczne odtwarzanie anatomii silnika sprawdzono
osobno. Także podstawowe 9 prób przeszło z włączonym NT.
Usuwanie postaci testowych opóźniono o 3 s, aby nie kolidowało z opóźnionym
nadawaniem grupy krwi przez NT podczas tworzenia postaci.

## Przegląd i poprawki

Niezależny przegląd wykrył cztery istotne problemy. Poprawiono je i dodano
regresje: opłacanie na pewno nieskutecznych trafień, usuwanie technicznych
stanów NT, wyjmowanie baterii z urządzeń oraz powtarzanie próby dojścia do
nieosiągalnego ogniwa. Dodano też ograniczony do ataku strażnik amputacji
dla modów korzystających z natywnej ścieżki po `DamageLimb`.

Natywna próba ujawniła dodatkowo raw-cast kolekcji i liczb w Hook.Patch.
Częściowy atak jest teraz wykonywany zwykłym wywołaniem natywnego
DamageLimb, z zabezpieczeniem przed ponownym poborem energii. Końcowe
próby nie zgłaszają tych błędów konwersji.

## Granice weryfikacji

Ukryta kopia klienta utworzyła niewidoczne okno SDL, ale nie zwróciła wyniku
`tests/runtime/headset_client_probe.lua`. Nie zaliczono więc prób GPU,
przestrzennego audio ani dopasowania grafiki do głowy na działającym kliencie.
Tekstury, alfa, wycinki, odwołania i pliki dźwiękowe są sprawdzane osobno;
podgląd i odsłuch znajdują się w `docs/headsets/preview.html`.

Nie wykonano pełnej sesji dwóch aktywnych klientów z opóźnieniem i ponownym
dołączeniem. Przywracanie ragdolla jest wysyłane osobnym zdarzeniem serwera;
regresja sprawdza, że wcześniejszy alarm wyczerpania go nie blokuje.

Nie deklarujemy zgodności z każdym istniejącym/przyszłym modem. Automatyka
obejmuje standardowe afflictions; nieznane skale, własna anatomia i zapisy
poza zdrowiem wymagają adaptera. API opisuje `docs/HEADSETS.md`.

Decyzje wykonawcze: praca w bieżącym checkoutcie, wspólne procentowe koszty,
ostatnia niewystarczająca resztka nie daje pełnego kroku odporności,
regeneracja nie wskrzesza i nie usuwa sprawnych implantów. Brak odłożonych
drobnych uwag z przeglądu; niezbadane próby są wskazane wyżej.
