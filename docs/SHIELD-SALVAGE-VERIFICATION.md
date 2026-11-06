# Tarcza i informacja o rozbiórce — 1.3.10

Data: 2026-11-06. Barotrauma 1.13.5.0, LuaCs c6e8829, izolowany serwer
z Neurotraumą CS2.0.5. Próby nie używają kampanii użytkownika.

## Tarcza

`Projectile.Use` wywołuje `Limb.SetLagCompensatedBodyPositions` dla strzelca
z listy klientów. Hitscan bierze pod uwagę dodatkowe kolizje Cat10 również
przy `CollidesWith=None`. Próby bez klienta nie ustawiały tych kolizji,
więc nie obejmowały tego źródła ran. Natywne przesunięte kolizje pozwoliły
odtworzyć trafienie kończyny przed bieżącą tarczą i ranę z błyskiem przy śrucie.

Przed obsługą trafienia sprawdzana jest tożsamość `fixture.Body` oraz
`limb.LagCompensatedBody.FarseerBody`. Różnica historycznej i bieżącej pozycji
tej kończyny przesuwa tylko obliczenie tarczy jej właściciela i punktu emisji.
Obie pozycje kończyny są w tym samym układzie symulacji; ich różnica wymaga
tylko przeliczenia jednostek. Bieżąca geometria, renderowanie i fizyczne
pociski pozostają bez tego przesunięcia.

- Regresja jednostkowa najpierw przepuszczała historyczne trafienie.
- Kontrole zachowują tył, rzeczywiste bieżące kończyny, ściany, friendly fire
  i przepuszczenie trafienia przy niewystarczającej energii.
- Natywna macierz: **96/96 strzałów z przechwyceniem i zerem wywołań
  `Attack.DoDamageToLimb` na obrońcy**. Sześć kierunków sterowanych kursorem,
  cztery kierunki celowania w kończyny i cztery natywne rodzaje amunicji.
- **Kontrola bez tarczy: PASS**, prawdziwe wywołanie obrażeń.
- Rewolwer wystrzeliwuje amunicję z własnego ekwipunku przez `RangedWeapon.Use`.
  Jego rozrzut jest zerowany dla dokładnego pomiaru toru. Pozostałe pociski
  używają `Projectile.Shoot`; strzelba zachowuje pełne śruty i ich rozrzut.
  Lufa jest poza bieżącą i historyczną tarczą.
- Dodatkowy pomiar krawędzi: wszystkie **256** wartości natywnej puli
  rozrzutu, pojedynczy śrut z każdą wartością. **211 przechwyceń**, **45 trafień
  po torach, które nie przecinają łuku**, **0 wywołań obrażeń dla toru
  przecinającego łuk**. Postać ma w tej pomocniczej próbie GodMode, aby
  dozwolone trafienia nie zmieniały kolejnych pozycji; liczone jest wejście
  do `Attack.DoDamageToLimb`, przed natywną ochroną zdrowia. To wyjaśnia,
  dlaczego pełny rozrzut przy krawędzi może dać ranę i późniejszy błysk.
  [Pomiar krawędzi](combat/shield-edge-spread-results.txt).
- [Przed](combat/shield-lag-before.txt),
  [celowane strzały przed](combat/shield-lag-aimed-before.txt),
  [macierz po](combat/shield-lag-after.txt).

Zakres: rzeczywiste natywne kończyny i ich historyczne kolizje są jawnie
przesuwane o 160 jednostek w kierunku strzelca. Tarcza i postawa obrońcy
wynikają ze zwykłych aktualizacji celowania oraz fizyki. To potwierdza
obsługę przesuniętych kolizji; nie zastępuje sesji dwóch połączonych klientów,
nie cofa historycznego kierunku celowania i nie obejmuje wszystkich modów
pocisków ani przejść między łodziami.
Tarcza chroni swój łuk; trafienie poza jego krawędzią nadal zadaje obrażenia.
Jedna wcześniejsza macierz po restarcie miała taki przypadek przy pasie
i śrucie. Czysty ponowny przebieg zaliczył 97/97, a pomiar całej puli
rozrzutu osobno sprawdził granicę ochrony.

Scenariusze: [macierz](../tests/runtime/shield_frontal_matrix.lua)
i [uruchomienie](../tests/runtime/shield_lag_runner.lua).

## Plecak i rozbiórka

- Status opisuje **Grupy / 100** i **Sztuki / 10000**; pomoc wyjaśnia grupy
  po 100 sztuk jednego typu. Osobny wiersz pokazuje sprawdzone, rozłożone,
  pominięte i wynik albo przyczynę zatrzymania.
- Zadanie pracuje na pierwotnej kopii listy wejściowej. Nowy łup można
  wkładać między atomowymi transakcjami tworzenia surowców. Pending nadal
  blokuje wkładanie, aby nie zajmować miejsca produktów.
- Do 32 rzeczy bez obsługiwanej receptury jest pomijanych w jednej
  aktualizacji; maksymalnie jedna rozbiórka tworzy produkty w danym kroku.
- Dźwięk odwołuje się do `Content/Items/Fabricators/Deconstructor.ogg`
  z gry. Kanał jest ponownie wykorzystywany, zapętlony i wygaszany po
  0,5 s bez potwierdzenia udanego przetwarzania lub po usunięciu/resetowaniu.
- Protokół magazynu **v4** przenosi postęp symetrycznie w obu kierunkach
  serializacji. Host i klienci wymagają aktualizacji i restartu.

**7/7 natywnych sprawdzeń: PASS.** Zadanie z kluczem i 40 sztukami żelaza
przyjęło dodatkowy klucz w trakcie pracy; rozłożyło oryginał, zachowało
nowy klucz, pominęło surowce i zachowało wynik 41 sprawdzonych / 1 rozłożony
/ 40 pominiętych. [Wyniki](combat/salvage-progress-results.txt).

Testy transakcyjne obejmują równoczesny insert, zablokowanie insertu przy
oczekiwaniu na produkty, wykluczenie nowego łupu z partii, rollback,
ostatnią rozbiórkę zużywającą resztę energii i spóźnione callbacki po resecie.
Test sieciowy wykonuje roundtrip statusu i liczników. Testy klienta
sprawdzają etykiety i postęp, a testy audio ponowne użycie kanału i wygaśnięcie.
Nie wykonano nowego odsłuchu w kliencie GPU ani zrzutu renderowania panelu;
użyty plik dźwiękowy jest istniejącym zasobem gry.

**414 testów automatycznych: OK.** Walidacja 13 XML / 39 modułów Lua 5.2
i receptur: OK. Niezależne przeglądy tarczy i rozbiórki: bez pozostających
istotnych uwag. Paczka: `output/MULTI-TOOL-V2-1.3.10.zip`.

Po pełnym restarcie serwera potwierdzono 97/97 prób tarczy i 7/7 plecaka.
ZIP zawiera 85 plików, porównanych bajt w bajt ze źródłami produkcyjnymi.
