# Komunikatory Aegis — weryfikacja 1.2.6

## Większa wydajność leczenia efektów modowych w Mk II

2026-11-01. Zgłoszenie dotyczyło nadal powolnego usuwania efektów NT.
Dotychczasowe 7,5 jednostki/s było wspólną pulą dla wszystkich urazów;
zwiększono ją do 20/s (4 razy model podstawowy, około 2,67 razy 1.2.5).
Odtwarzanie anatomii zachowuje osobny mnożnik 1,5 i dotychczasową cenę.
Koszt zwykłego leczenia pozostaje 0,125% za jednostkę. Nie zmieniono
klasyfikacji efektów ani opcjonalności Neurotraumy.

Weryfikacja na świeżo uruchomionym prywatnym serwerze 1.13.5.0/LuaCs
c6e8829 z aktywną Neurotraumą C#:

- **6/6 natywnych porównań**: oba modele, cena i tempo leczenia,
  rzeczywiste `fracturedextremity 100` wraz z `arterialcut 100`, wspólna
  regeneracja znacznika NT i fizycznego stawu. Usunięcie 200 jednostek
  trwa 10 kroków po 1 s w Mk II, 40 w podstawowym; w obu kosztuje 25%.
- **Rzeczywista opóźniona amputacja `gate_ta_ll`, 16 s symulacji**:
  PASS, brak kosztów fałszywych trafień, noga odtworzona za 12,5%,
  złamanie i uszkodzenie tętnicy całkowicie wyleczone, postać żyje,
  witalność 100, bateria 58,60%. W 1.2.5 po tym samym czasie urazy
  nadal wymagały leczenia. Większy wydatek w tych 16 s odpowiada większej
  ilości wykonanego leczenia, a nie podniesieniu ceny jednostkowej.
- **176/176** testów regresyjnych, w tym jednoczesne leczenie nieznanej
  choroby z moda i uszkodzenia tętnicy, stały koszt za cały uraz, brak
  kosztu po wyleczeniu oraz zachowanie czasu odtwarzania kończyn.
- **30 s bezczynności z NT C#**: bateria 100%, witalność 100, bezpieczny
  kadłub. Następnie zadane oparzenie uruchomiło płatne leczenie.

Scenariusze: `tests/runtime/headset_medical_profiles.lua`,
`tests/runtime/headset_nt_amputation_trace.lua`. Kod medyczny w prywatnej
kopii jest zgodny z kodem paczki. W tej iteracji nie uruchamiano klienta
graficznego ani połączonych klientów multiplayer. Instalacja Steam bez zmian.

## Historia 1.2.5

## Amputacja NT i szybszy Mk II

2026-11-01. W prywatnym serwerze Barotrauma 1.13.5.0/LuaCs c6e8829,
z włączonym C# Neurotraumy CS (pakiet 2.0.7, DLL zgłasza 2.0.5), odtworzono
rzeczywistą amputację nogi przez `gate_ta_ll`. Pozwolono grze wykonać
opóźnione efekty oraz 16 sekund symulacji; wcześniejsze synchroniczne próby
samych znaczników amputacji nie obejmowały tej kaskady.

Przed poprawką `severepain 100` i `fracturedextremity 99999` wygenerowane
przez samą postać były rozliczane jako dwa trafienia po 50% w jednym kroku.
Bateria spadała ze 100% do zera. Rejestrowany natywny wynik
`StatusEffect.GetMultipliedAffliction` ma teraz pochodzenie źródło/cel.
Własne konsekwencje fizjologiczne omijają koszt tarczy, ale nadal wymagają
rzeczywistego, płatnego leczenia. Zewnętrzny atak bez wskazanego napastnika
nadal podlega pochłanianiu. Brak napastnika sam w sobie nie jest wyjątkiem.

Końcowy test opóźnionej amputacji: **PASS**, zero kosztów `hit`, dokładnie
**12,5% za odtworzenie nogi**, po 16 s pozostało **72,67%**, postać żyła
z witalnością 100, znacznik amputacji był usunięty. Pozostałe złamanie
i uszkodzenie tętnicy nadal wymagały leczenia; wynik nie oznacza końca
wszystkich kosztów regeneracji. Scenariusz:
`tests/runtime/headset_nt_amputation_trace.lua`.

Dalsze próby końcowej wersji:

- **4/4 natywne porównania**: podstawowy leczy 5 jednostek/s za 0,625%,
  Mk II 7,5 za 0,9375%; amputacja NT wraz z fizycznie zerwanym stawem
  tworzy jeden proces i odtwarza oba stany za 12,5%. Podstawowy kończy
  w 10 krokach po 1 s, Mk II w 7 (dokładna konfiguracja: 10 / 1,5 s).
- **9/9** natywnej mechaniki: pełna i częściowa blokada ataku, zwykłe
  obrażenia modelu podstawowego, odtwarzanie stawów i ochrona ciśnieniowa.
- **8/8** natywnej integracji NT CS: organy, amputacje, operacje,
  zachowanie grupy krwi, implantów i prawidłowej fizjologii.
- **30 s rzeczywistej bezczynności** z NT CS: energia 100%, witalność 100,
  bezpieczny kadłub, NeedsAir=true. Późniejsze zadane oparzenie uruchomiło
  płatne leczenie, więc kontrola nie korzystała z wyłączonego urządzenia.
- **175/175** testów regresyjnych, w tym pochodzenie efektów, ponowne użycie
  tego samego affliction, wygaszanie pochodzenia, mieszane źródła obrażeń,
  różnica tempa i te same ceny leczenia.

Przegląd kodu ujawnił, że jeden wynik natywnego mnożenia affliction może
trafić w wiele kończyn. Pochodzenie pozostaje ważne dla wszystkich takich
aplikacji w tym kroku, zamiast znikać po pierwszej. Test natywny wykrył też,
że LuaCs zwraca liczbowe wartości `LimbType`; grupowanie stawów porównuje
teraz prawdziwe enumy, a nie ich nazwy tekstowe. Obie regresje odtworzono
testem przed poprawką.

Próby odbywały się na kopii serwera, bez zmian w instalacji Steam. W tej
iteracji nie uruchamiano klienta graficznego ani połączonej sesji multiplayer.
Neurotrauma nadal jest opcjonalna; ogólna obsługa pochodzenia efektów nie
odwołuje się do jej DLL ani nie wymaga jej znaczników.

## Historia 1.2.4

## Rezerwacja ogniwa, Real Sonar i słyszalne alarmy

2026-11-01. Raport użytkownika z `aegis_headset_status` jednoznacznie
wskazuje `heal:serversidelua -0.1250%`. Ten sam powtarzający się koszt
odtworzono w prywatnym kliencie z kopiami wszystkich 13 aktywnych pakietów.
Real Sonar deklaruje ten efekt jako nie-buff o maksymalnej sile 1 i stale
utrzymuje go w Lua. To znacznik wyboru obsługi Lua/XML, nie uraz.
Leczenie zachowuje go bez kosztu i bez włączania alternatywnej ścieżki XML.

Drugą potwierdzoną ścieżką był wybór baterii słuchawek przez osobny moduł
bojowego multitoola. Zablokowano go oraz natywne wyszukiwanie, pobieranie,
przekładanie i opróżnianie przez AI. Własna atomowa podmiana przy <=10%
nadal działa. Ręczne działania gracza pozostają dostępne.

Próby natywne końcowej wersji:

- Klient z pełnym zestawem XML/Lua: **4/4** rzeczywista blokada trafienia,
  leczenie, pozycje trzech diod i GPU; dodatkowo oba sprite'y, cztery stany
  energii i **7 natywnych kanałów audio**.
- Klient z Real Sonar: **4/4** ochrona ogniwa 80% przed TakeItem, przed
  opróżnianiem, zachowanie 80% i wymiana przy dokładnie 10%, zachowanie
  prawdziwego znacznika Real Sonar na 1 bez kosztu podczas 100 kroków leczenia.
- Serwer: te same trzy próby AI **3/3**; próba Real Sonar oznaczona SKIP,
  bo pakiet nie jest tam włączony. Ponadto **9/9** mechaniki, **8/8** NT CS
  i **3/3** automatycznego wkładania baterii.
- Końcowa bezczynność klienta z pełnym zestawem: **30 s, energia 100%,
  witalność 100, bezpieczny kadłub, NeedsAir=true, Removed=false**.
- Natywny sterownik odtworzył trzy alarmy przy 20%, 10% i 0% bez zużycia
  energii; komplet siedmiu plików otwiera natywne kanały audio.
- **164/164** testów regresyjnych. Obejmują też alarm wysyłany przez serwer
  i odebrany przez klienta bez kosztu i bez pasywnego błysku.

Zapisano faktyczne końcowe klatki gry:
[czerwone diody](headsets/in-game-red.png) i [niebieskie diody](headsets/in-game-blue.png).
Widziana postać ma założony komunikator; klatki demonstracyjne wywołują
rodzaj zdarzenia kontrolowanie, z ochroną postaci przed losowymi potworami.
W próbie pikseli obok soczewek czerwony kadr miał 13 mocnych czerwonych
pikseli, a niebieski 3 niebieskie. Rozmiar rdzenia to minimum 3 piksele.
Nie są to ilustracje przeglądarkowe ani grafiki wygenerowane przez AI.

Wcześniejsze próby podawały ścieżki opcjonalnych pakietów poza katalogiem
wykrywania LocalMods klienta, więc sam wpis w konfiguracji nie dowodził
ich uruchomienia. Poprawiono to przez fizyczne kopie w LocalMods oraz zapis
faktycznej listy EnabledPackages, z kolejnością z konfiguracji użytkownika.
W prywatnym kliencie log wskazuje CSharp disabled: próba pełnego zestawu
dotyczy aktywnych XML/Lua; integrację C# Neurotraumy weryfikuje serwer.
Sesja połączonych klientów multiplayer pozostaje niezweryfikowana.

Natywna próba ujawniła też niejednoznaczne przeciążenie
`AIController.UnequipContainedItems`. Wybrano jawny podpis z niekwalifikowanym
``System.Func`2[Barotrauma.Item,System.Boolean]``, który działa w obu assembly.
Pierwsza próba rezerwacji błędnie wyłączała AI, przez co aktor nie był IsBot;
końcowe wyniki pochodzą od bota z włączonym AI. Zmieniono sprzątanie nowej
próby na opóźnione, aby oczekujące callbacki tworzenia NT nie trafiały na
usunięty ragdoll. Wszystkie zmiany i testy są w repozytorium/prywatnych kopiach;
instalacji Steam użytkownika nie modyfikowano.

## Historia 1.2.3

## Naprawa klienta, kolorów i wymiany ogniw

2026-10-31. Zrzut użytkownika wskazał niedostępne w kliencie LuaGame pole
`Game.Server` w `G.absorb`. W grze solo wyjątek przerywał blokadę natywnego
trafienia i emisję błysku. Odczyt ustawień serwera jest teraz osłonięty
warunkiem `SERVER`; ścisła atrapa klienta najpierw odtworzyła dokładny błąd.

Nieaktywne efekty poniżej `ActivationThreshold` nie uruchamiają regeneracji.
Aktywne choroby dokładnie na progu nadal są leczone. Zmiany natywnych
afflictions rozliczane są według faktycznie zmienionej siły; nieudane lub
ignorowane zapisy nie kosztują energii. Obliczenie dostępnego budżetu nie
opróżnia tymczasowo baterii, aby zwrot nie wyzwalał nieodwracalnego `OnBroken`.
Nie odtworzono pełnego zestawu modów i stanu postaci użytkownika, więc nie
przypisujemy całego jego ciągłego poboru jednej niepotwierdzonej przyczynie.

Diody migoczą na czerwono przy trafieniach, na niebiesko przy leczeniu.
Osobne czasy zdarzeń chronią czerwony błysk przed nadpisaniem przez
równoczesną regenerację. Błysk trwa 0,55 s; wielkość pozostaje lokalna przy uchu.
Bot używa natywnej atomowej zamiany zamiast wyjmować starą baterię przed
odroczonym zadaniem wkładania nowej. Lokalny zapas wkłada także bez bieżącego
zadania. Przerwany marsz nie opróżnia słuchawek; cudze ogniwa posterunku
oznaczone `Illegitimate` są pomijane.

Bilans: leczenie i trafienia kosztują 4 razy mniej, procesy anatomiczne
2 razy mniej, a samo ciśnienie 2,5%/s zamiast 5%/s (40 s pełnego ogniwa).
Bot szuka zapasu co 1 s poniżej 30%. Mody medyczne nadal są opcjonalne.

Końcowe dowody:

- **151/151** testów jednostkowych i regresyjnych.
- Prywatny klient Barotrauma/LuaCs: rzeczywista postać, wyposażone Mk II,
  pochłonięcie natywnego trafienia, płatne leczenie, trzy pozycje diod
  z prawdziwego noszonego sprite'a i rysowanie przez natywny SpriteBatch:
  **4/4 PASS**, bez NT i z NT CS. Dodatkowa próba obejmuje oba sprite'y,
  cztery poziomy baterii i cztery kanały dźwięku.
- Po końcowych zmianach klient z NT CS: **30 s bezczynności, energia 100%,
  witalność 100, bezpieczny kadłub, NeedsAir=true, Removed=false**.
- Prywatny serwer po świeżym starcie: **9/9** mechaniki oraz **8/8** NT CS.
  Trzy dodatkowe próby botów: pusty slot/zapas w ekwipunku, słaba bateria/zapas
  w ekwipunku, słaba bateria/zapas na podłodze — **3/3 PASS**.
- Końcowa próba bezczynności serwera z NT CS: **30 s, energia i witalność 100**.

Klient jest uruchamiany z prywatnej kopii `.runtime/client`. Lokalny hak
startowy omija oczekiwanie ekranu ładowania na klawisz i włącza próbną rundę;
nie wchodzi do paczki moda. Podgląd PNG nadal jest ilustracją z przeglądarki,
nie zrzutem z gry. Sesja dwóch klientów pozostaje niezweryfikowana.
Jedna próba narzędziowa zakończyła serwer, gdy polecenia Lua wysłano jeszcze
w trakcie asynchronicznego `reloadlua`; końcowe próby wykonano w świeżym procesie.
Instalacja Steam użytkownika nie była modyfikowana.

## Historia 1.2.2

## Małe diody i brak kosztu normalnej fizjologii

2026-10-31. Zgodnie z nowym wymaganiem usunięto całe pole wokół postaci.
Renderer daje jedynie krótkie czerwone błyski na istniejących soczewkach
grafiki: jedną diodę w modelu podstawowym, trzy w Mk II. Transformacja
odwzorowuje natywny noszony sprite, obrót głowy i odbicie. Hełm ukrywający
słuchawki ukrywa też światło. Regeneracja i ciśnienie nie odtwarzają dźwięku
trafienia; wyczerpanie zachowuje osobny sygnał.

Poprzedni adapter mógł opłacać zwiększanie normalnej odporności NT do 100
oraz wyrównywanie drobnych odchyleń krwi i ciśnienia do idealnej wartości.
Nowe regresje odtwarzają ten niepotrzebny koszt. Odporność jest teraz
zachowywana, a krew i ciśnienie w zakresie 90–110 nie wymagają leczenia.
Rzeczywiste urazy, regeneracja organów/kończyn, pochłanianie trafień
i ochrona przed ciśnieniem nadal kosztują energię. Samo noszenie nie kosztuje.

Wyniki po poprawce:

- `python tools/run_tests.py`: **138/138 PASS**.
- Walidator: **11 XML, 24 moduły Lua 5.2**, zasoby i receptury poprawne.
- Prywatny natywny serwer: **9/9** prób mechaniki oraz **8/8** prób NT CS,
  w tym zerowy pobór dla normalnej odporności/fizjologii oraz płatne leczenie
  rzeczywistego niedociśnienia.
- Natywna próba bezczynności po poprawce: **30 s, energia 100%, witalność 100**.
  Wcześniejsza próba porównawcza trwała 120 s i także nie wykazała kosztu
  w domyślnym zdrowym stanie. Nie odtwarzano pełnego zestawu modów użytkownika.
- Regresje renderera sprawdzają pozycję, rozmiar i liczbę diod, obrót,
  odbicie, wygaszenie, ukrycie pod hełmem i brak dźwięku trafienia przy leczeniu.

Podgląd PNG pochodzi z poleceń produkcyjnego Lua nałożonych na oryginalną
grafikę w przeglądarce. Nie jest zrzutem z gry. Natywne GPU klienta i sesja
dwóch klientów pozostają niezweryfikowane. Poprawiono próbę klienta tak,
aby wymagała rzeczywistego wyposażenia i niezerowej liczby diod zamiast
pozornie zaliczać puste rysowanie. Mody medyczne pozostają opcjonalne.

## Historia 1.2.1

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
