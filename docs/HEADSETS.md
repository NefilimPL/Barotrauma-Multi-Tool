# Komunikatory Aegis

Wersja 1.2.4 zawiera dwa przedmioty dodane w 1.2.0 do MULTI-TOOL-V2. Wymagany jest LuaCs
na kliencie i serwerze. **Żaden mod medyczny nie jest wymagany.**

| Przedmiot | Identyfikator | Funkcje |
|---|---|---|
| Komunikator regeneracyjny Aegis | `aegisheadset` | Radio, ochrona przed ciśnieniem, regeneracja |
| Komunikator osłonowy Aegis Mk II | `aegisheadsetmk2` | To samo oraz pochłanianie natywnych ataków |

Oba zajmują slot słuchawek i mają jeden slot na ogniwo `mobilebattery`.
Pręty paliwowe nie pasują. Natywne radio ma zwykły zasięg 35000 i działa
bez baterii: kanał, komunikacja głosowa/tekstowa i zakłócenia należą do gry.
Nie nadpisujemy standardowych słuchawek. Urządzenie działa przy
nieprzytomności, ale musi być założone; przedmiot w plecaku nie chroni.

## Migotanie po założeniu i diagnostyka

Czerwone diody migoczą przy pochłanianiu trafień i ochronie przed ciśnieniem;
niebieskie oznaczają regenerację. Błysk trafienia ma pierwszeństwo przed leczeniem.
Samo migotanie nie oznacza otrzymywania obrażeń. Założenie urządzenia
na wcześniej ranną postać może od razu rozpocząć leczenie, również na
bezpiecznym okręcie. Zdrowa postać bez zagrożenia nie powinna zużywać baterii.

Samo noszenie nie kosztuje energii. W 1.2.2 usunięto podbijanie odporności NT
do 100 oraz ciągłe korygowanie prawidłowego ciśnienia i ilości krwi.
Odporność pozostaje bez zmian; wartości krwi i ciśnienia od 90 do 110
nie uruchamiają leczenia. Rzeczywiste niedociśnienie nadal wymaga regeneracji.
Od 1.2.3 pomijane są także efekty poniżej ich natywnego progu aktywacji.
Nieudana próba zmiany efektu nie pobiera energii ani nie daje błysku.
Od 1.2.4 zachowywany jest także `serversidelua`, znacznik Real Sonar stale
odtwarzany przez ten mod. Jego usuwanie było rzeczywistą przyczyną zgłoszonego
pasywnego kosztu oraz mogło włączać zastępcze efekty XML sonaru.

W konsoli F3 wpisz `aegis_headset_status`. Komenda pokazuje naładowanie
i ostatnie rzeczywiste koszty, np. `heal:burn`, `pressure`, `hit` lub
`regenerate:organ:heartremoved`. W multiplayer przyczyny należy odczytać
na serwerze. Nie zmienia ona zdrowia ani energii.

W 1.2.1 poprawiono błąd rozmiaru grafiki noszonej: silnik nie mnoży jej
przez `Item.Scale`. Skala 0,7 powiększała arkusz 1254 px do około 878 px;
nowa skala 0,035 daje około 44 px przed skalą ragdolla. Po podmianie
pakietu uruchom grę ponownie; do pierwszej próby użyj nowego komunikatora.

[Podgląd diod](headsets/field-comparison.html) pokazuje powiększone słuchawki
z geometrią produkcyjnego renderera. To ilustracja, nie zrzut ekranu gry.

## Zasilanie

- Ciśnienie: 2,5% standardowego ogniwa/s, około 40 s samej ochrony.
- Leczenie: wspólny limit 5 jednostek siły/s, 0,125% ogniwa/jednostkę.
- Organ: 7,5% i co najmniej 5 s opłacanej regeneracji.
- Kończyna: 12,5% i co najmniej 10 s opłacanej regeneracji.
- Zamknięcie operacji NT: 7,5% i co najmniej 5 s na daną część ciała.
- Mk II: co najmniej 1% za trafienie, dalej 0,5% za jednostkę przyjmowanej
  siły. Na pewno nieskuteczne efekty (np. prawdopodobieństwo zero, pełna
  odporność, pełne pokrycie pancerzem) nie są opłacane jako obrażenia.

Wszystkie koszty korzystają z tego samego rzeczywistego ogniwa. Leczenie
dzieli wspólny limit między urazy, najpierw zagrażające życiu. Organ lub
kończyna wraca dopiero po opłaceniu całego procesu. Bez energii leczenie
ustaje. Pozostała energia pokrywa część ataku, a reszta przechodzi.
Ostatnia resztka niewystarczająca na krok ochrony ciśnieniowej przepada;
nie kupuje całego kroku odporności. Sprawny skafander i bezpieczne wnętrze
nie zużywają energii na ciśnienie. Zdejmowanie i zakładanie nie daje
darmowej odporności ani odtwarzania baterii. Martwe postacie nie odżywają.

Parametry: `MULTI-TOOL-V2/Lua/AegisHeadset/config.lua`.

## Mody medyczne i przyszłe rozszerzenia

Ogólne leczenie odczytuje aktualne efekty postaci i kończyn. Nie potrzebuje
listy nazw chorób: nowy szkodliwy affliction z przyszłego moda może być
leczony od razu. Buffy i genetyka pozostają; efekt oznaczony jako buff,
który faktycznie obniża witalność, jest traktowany jako szkodliwy.

Opcjonalny adapter Neurotraumy obsługuje brakujące organy, amputacje,
operacyjne stany oznaczone przez NT jako buffy oraz prawidłowe wartości
fizjologii. Zachowuje grupę krwi, implanty i techniczne/protekcyjne znaczniki.
Rozpoznaje także NT CS bez starych tabel Lua. Sprawdzono pakiet NT CS 2.0.7
(Workshop 3744761298; sam moduł wypisuje wersję 2.0.5).

Nie istnieje bezpieczny automatyczny sposób odgadnięcia znaczenia każdej
zmiennej dowolnego przyszłego moda. Mod może przechowywać chorobę poza
systemem zdrowia, mieć odwróconą skalę albo oznaczać uraz jako korzystny.
Takie przypadki wymagają integracji przez publiczne API:

```lua
-- Wykonać po uruchomieniu BMTHeadsets; ponowić po reloadlua.
BMTHeadsets.registerTreatment('my_disease', {target=0, priority=80})
BMTHeadsets.registerTreatment('my_blood_level', {target=100, priority=90})
BMTHeadsets.registerTreatment('my_implant', {preserve=true})
BMTHeadsets.registerTreatment('my_missing_organ', {target=0, anatomy='organ'})

-- Dla stanu przechowywanego poza afflictions:
BMTHeadsets.registerProvider('my-mod', function(character)
    local state = MyMod.GetHealth(character)
    return {{id='my_damage', strength=state.damage, policy={target=0},
        apply=function(value) state.damage=value end}}
end)
```

`registerTreatment` nadpisuje automatyczną klasyfikację konkretnego ID.
`priority` ma domyślnie 0, wyższa wartość jest leczona wcześniej.
`anatomy='organ'`, `'limb'` lub `'surgery'` oznacza opłacany proces atomowy;
opcjonalne `part` grupuje kilka znaczników jednej części.
Provider zwraca bieżące wpisy; jego `apply` jest wykonywane tylko wtedy,
gdy dostępna energia pokrywa zaplanowany krok. Integracja musi rzeczywiście przywrócić zewnętrzny stan, a nie
tylko usunąć ikonę. Przechwytywanie Mk II obejmuje natywną ścieżkę ataków;
obcy skrypt zabijający postać bezpośrednio wymaga osobnej integracji.

## Boty

Przy 10% lub mniej bot co sekundę szuka dostępnego ogniwa o wyższym naładowaniu. Najpierw
korzysta z własnego ekwipunku, później ze zwykłych magazynów. Nie wyjmuje
baterii z cudzych ekwipunków, broni, sonarów ani innych rozpoznanych
urządzeń ani nie bierze ogniw oznaczonych jako cudza własność na posterunku.
Po zdobyciu zapasu dokonuje natywnej, atomowej zamiany; dotyczy to też
pustego slotu i bota bez bieżącego zadania. Działająca bateria pozostaje
w słuchawkach przy nieudanej podmianie lub przerwanym dojściu. Nieosiągalne
ogniwo jest pomijane przez 60 s; brak zapasów nie blokuje pracy.

Ogniwo w słuchawkach jest zarezerwowane: inne zadania botów oraz bojowy
multitool nie wybierają go jako zapasu, nie pobierają i nie opróżniają
pojemnika. Ręczne przenoszenie przez gracza pozostaje dostępne.

## Wytwarzanie i zasoby

Fabrykator lub fabrykator wojskowy. Podstawowy: elektryka 45, 30 s,
zwykłe słuchawki, FPGA, fulgurium, 2 miedzi, stop tytanowo-aluminiowy.
Mk II: elektryka 65, 45 s, podstawowy komunikator, FPGA, 2 fulgurium
i 2 stopy. Ogniwo wkłada się osobno. Ceny bazowe: 3500 / 7000.

Własne grafiki i OGG są w `Assets/Headsets`. Zamiast obwódki postaci renderer
rysuje krótkie, małe światło w miejscach istniejących soczewek: jedną diodę
w podstawowym modelu, trzy w Mk II. Światło podąża za głową, jej obrotem
i odbiciem grafiki. Zewnętrzne emitery pozostają widoczne przy nakryciu głowy.
Błysk wygasa po 0,55 s od ostatniego zdarzenia; kolejne kroki leczenia
podtrzymują niebieskie światło. Trafienie nie jest natychmiast nadpisywane
przez równoczesną regenerację.
Dźwięki trafienia: stabilny powyżej 20%, słabnący przy 10–20%, krytyczny
przy 10% lub mniej, osobny impuls wyczerpania. Rezonujące, elektroniczne
uderzenia powstały z własnej syntezy; nie używają nagrań filmu.
Trafienia mogą odtwarzać dźwięk co 0,1 s, niezależnie od wolniejszego
odświeżania leczenia. Alarmy są osobne: przy 20% co 10 s, przy 10% co 5 s,
przy 0% jednokrotnie. Nie wymagają trafienia, nie pobierają energii i nie
wywołują pasywnego błysku. Dźwięk własnych słuchawek nie zależy od odległości
kamery; inni słyszą go przestrzennie.

## Szybkie tworzenie w testerze

F3, następnie:

```text
enablecheats
spawnitem aegisheadsetmk2 inventory
spawnitem batterycell inventory 3
```

Słabsza wersja: `spawnitem aegisheadset inventory`. Włóż ogniwo do
komunikatora, a komunikator do slotu słuchawek. W razie nieoczekiwanego
kosztu `aegis_headset_status` pokazuje konkretny leczony identyfikator.

[Podgląd i odsłuch](headsets/preview.html) · [Prompty](headsets/PROMPTS.md)
· [Weryfikacja](HEADSET-VERIFICATION.md)
