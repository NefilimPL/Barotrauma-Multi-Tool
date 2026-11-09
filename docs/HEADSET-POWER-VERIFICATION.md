# Weryfikacja limitu poboru słuchawek — 1.3.13

Zgłoszenie dotyczyło opróżniania baterii przez spam efektów, nie tylko teslę.
Problem potwierdzono w kodzie 1.3.12 i na izolowanym serwerze Barotrauma
1.13.5.0/LuaCs c6e8829 z Neurotraumą CS 2.0.5.

## Przyczyna i zmiana

Koszt Mk II sumował siłę zewnętrznych affliction i ogłuszenia przy każdym
wywołaniu obrażeń, bez wspólnego limitu. Natywny atak cewki, pobrany z
komponentu `ElectricalDischarger`, kosztował 19,6% ogniwa. Sześć wywołań
`Character.ApplyAttack` w jednej klatce opróżniało pełne ogniwo. Tysiąc
wywołań `Character.AddDamage` z oparzeniem, ogłuszeniem lub obrażeniami
wewnętrznymi po jednej jednostce również zostawiało 0%.

Wspólny budżet fizycznego ogniwa ma pojemność 5 punktów procentowych
i odnawia się o 5 punktów/s czasu symulacji. Obejmuje trafienia, leczenie,
regenerację anatomii i ciśnienie obu modeli słuchawek. W okresie `t` sekund
zużycie wynosi najwyżej `5 + 5*t` punktów. Pełne ogniwo wystarcza na co
najmniej 19 s maksymalnego obciążenia słuchawkami. Zapas po bezczynności
pozostaje ograniczony do 5 punktów; przełożenie ogniwa go nie resetuje.

Przekroczenie budżetu obniża koszt kolejnych efektów, zachowując działanie
ochrony i tempo leczenia przy dodatniej energii. Puste ogniwo nie chroni
i nie leczy. Rzeczywisty niedobór przy pobieraniu ostatniej energii nadal
przepuszcza proporcjonalną część ataku. Rezerwacje zapobiegają ponownemu
wydaniu tej samej energii przez zagnieżdżone wywołania. Nieudane leczenie
i nieudany natywny fallback zwracają niewykorzystany budżet.

## Pomiary natywne

Scenariusz: [headset_power_spam_probe.lua](../tests/runtime/headset_power_spam_probe.lua).
Używa prawdziwych przedmiotów, ogniw i metod obrażeń postaci. Postacie
testowe nie mają GodMode. Cewka jest testowana przez jej natywny obiekt
ataku; test celowo wywołuje go wielokrotnie, pomijając ładowanie urządzenia.

| Próba | Przed zmianą | Po zmianie |
|---|---:|---:|
| 6 natywnych ataków cewki w jednej klatce | 0% | 95% |
| 1000 × burn w jednej klatce | 0% | 95% |
| 1000 × stun w jednej klatce | 0% | 95% |
| 1000 × internaldamage w jednej klatce | 0% | 95% |
| Mieszany spam przez 5,0167 s / 301 klatek | — | 69,9992% |

Ostatnia próba łączy natywne ataki co klatkę z wywołaniami leczenia
i dodatkowym kosztem przez wspólną ścieżkę poboru. Wynik mieści się
w granicy 30,0835 punktu dla zmierzonego czasu. Po jednoramkowych próbach
sprawdzono także brak śmierci i ogłuszenia chronionych postaci.

Surowe wyniki: [przed](headsets/power-spam-before.txt),
[po](headsets/power-spam-after.txt).

## Testy automatyczne i zakres

`python tools/run_tests.py`: 453 testy przechodzą, w tym 15 nowych prób
wspólnego limitu. Obejmują też nieznany efekt modowy, podstawowy headset,
regenerację organu przy wyczerpanym budżecie, odnawianie limitu, przełożenie
ogniwa, różne pojemności ogniw, pustą baterię, częściowe trafienie, refundacje,
nieudane leczenie, zagnieżdżony atak i brak drugiego poboru na klientach.

Niezależny przegląd wykrył spowalnianie leczenia przy małej dodatniej resztce
energii i wykorzystanym budżecie. Dodano test odtwarzający błąd, poprawiono
planowanie leczenia i ponownie uruchomiono cały zestaw. Przy rzeczywistym
wyczerpywaniu ogniwa równorzędne urazy mogą być teraz leczone kolejno,
zamiast dzielić ostatnią porcję energii równo; suma leczenia jest zachowana.
Dziewięć istniejących natywnych prób integracyjnych słuchawek również
przechodzi: [wyniki](headsets/power-integration-results.txt).

`python tools/validate_content.py --game .runtime/server`: poprawne XML,
42 moduły Lua 5.2, grafiki i identyfikatory receptur.

Limit obejmuje kod słuchawek. Nie ogranicza innych urządzeń ani obcych
skryptów bezpośrednio zmieniających stan baterii. Nie testowano każdego
istniejącego moda; zabezpieczenie działa niezależnie od identyfikatora
efektu. Koszty rozstrzyga serwer. Po aktualizacji wymagany jest restart
gry i serwera: gorące przeładowanie zachowało stare pliki w cache LuaCs.

Przed zmianą natychmiastowe usuwanie postaci testowych powodowało błąd
opóźnionej inicjalizacji krwi NT; sprzątanie przesunięto o 3 s. Końcowa
próba po restarcie serwera zakończyła się bez tego błędu. Instalacji Steam
i kampanii użytkownika nie zmieniano.
