# Plecak-odkurzacz — projekt do zatwierdzenia

Data: 2026-11-03. Status: zatwierdzony przez użytkownika („ok”), z poprawką:
bateria musi znajdować się w odkurzaczu, nie w plecaku.

Przegląd wykonalności pierwszej wersji: wykonany przez osobnego recenzenta.
Użytkownik następnie ustalił pomijanie rzeczy bez receptury, obowiązkowe
zasilanie oraz osobne wytwarzanie plecaka i odkurzacza. Dokument uwzględnia
te poprawki oraz przeniesienie baterii do odkurzacza. Użytkownik zatwierdził
wariant ze stosami po 100 we własnym panelu.

## Ustalenia użytkownika

Nowy zestaw do Barotraumy: plecak oraz odkurzacz zajmujący obie ręce.
Oba elementy trzeba osobno wytworzyć. Urządzenie wymaga zasilania,
np. wymiennej baterii. Zbiera wszystkie przenośne przedmioty użytkowe z ziemi, martwych ciał,
pojemników, szaf i skrytek. Obejmuje całe skrzynki z amunicją i kombinezony,
również założone na martwe postacie. Ma bardzo dużą pojemność i stosy po 100.
Potrzebne są własne grafiki plecaka i ssawki oraz animacja zasysania.

Użytkownik potwierdził: **jeden przycisk rozkłada całą zawartość**, a nie
tylko wybrane przedmioty. Obejmuje to zawartość zagnieżdżonych pojemników.
Przedmioty, których nie da się rozłożyć według receptur gry lub modów,
nie są rozbierane i pozostają w magazynie.

Poniższe konkretne ustawienia są propozycjami wykonawcy, nie dodatkowymi
ustaleniami użytkownika.

## Kontekst i podejście

Repozytorium zawiera pakiet MULTI-TOOL-V2 1.2.10, XML przedmiotów,
moduły LuaCs, własne grafiki oraz testową instalację gry. Cel zgodności:
Barotrauma 1.13.5.0 i aktualnie używane w projekcie LuaCs. Zmiana powinna
rozszerzyć istniejący pakiet, korzystając z jego konwencji ładowania,
autorytetu serwera, sprzątania po reloadlua i lokalizacji PL/EN.

Rozważone warianty:

1. **XML i LuaCs w istniejącym pakiecie, z własnym panelem magazynu —
   rekomendowany.** Pozwala prezentować stosy po 100 i obsługiwać dowolne
   przenośne przedmioty bez globalnej zmiany zasad innych ekwipunków.
2. Wyłącznie natywny pojemnik XML: mniejszy zakres kodu, ale nie wystarcza
   do zasysania, ogólnej rozbiórki ani stosów po 100. Lokalny kod
   ItemPrefab ogranicza zwykły MaxStackSize do 63.
3. Globalne podniesienie limitu stosów: wymaga ingerencji także w obce
   ekwipunki i sprawdzenia protokołu sieciowego. Niepotrzebnie poszerza
   zakres zmiany; nie jest proponowane.

Wariant 1 jest propozycją do zatwierdzenia. Faktyczny sposób przechowywania
musi przejść próbę techniczną zapisu i synchronizacji, zanim będzie uznany
za gotowy. Samo wpisanie maxstacksize="100" nie spełnia wymagania.

## Wygląd, noszenie i sterowanie

Robocze nazwy i identyfikatory: **Plecak zbierający Aegis**
(`aegisvacuumpack`) oraz **Odkurzacz Aegis** (`aegisvacuum`). Są to dwa
odrębne przedmioty, każdy z własną recepturą w fabrykatorze i własną grafiką.
Plecak przechowuje łup; odkurzacz jest dwuręczną ssawką z własną baterią.

Propozycja wykonawcy: zestaw działa, gdy postać ma plecak we własnym
ekwipunku i trzyma odkurzacz w obu rękach. Wtedy plecak jest widoczny na
plecach, a przewód łączy go ze ssawką. Nie wymagać slotu skafandra.
Przy kilku plecakach gracz wybiera jeden aktywny; nigdy nie łączyć automatycznie
magazynów ani nie zmieniać celu w trakcie partii rozbiórki. Wybór techniki
przypięcia grafiki i panelu należy do wykonawcy.

Obie ręce rezerwuje odkurzacz przez natywne ograniczenie slotów. Po jego
odłożeniu plecak zachowuje magazyn; samo przechowywanie łupu nie wymaga
trzymania ssawki. Zdjęcie lub przekazanie plecaka zatrzymuje aktywną pracę
zestawu. Nie tworzyć kopii magazynu przy wyposażaniu lub łączeniu elementów.

Propozycja obsługi: celowanie i przytrzymanie użycia zasysa w kierunku
ssawki. Puszczenie użycia natychmiast zatrzymuje zbieranie. Panel zawiera
magazyn, licznik zajętości i przycisk „Rozłóż całą zawartość”. Jeden klik
uruchamia partię rozbiórki bez potwierdzania każdego przedmiotu.

## Zasilanie i wytwarzanie

Wymagane przez użytkownika: urządzenie musi być zasilane, a plecak
i odkurzacz trzeba wytwarzać osobno. Nie zastępować tego jedną recepturą
tworzącą od razu cały zestaw.

Ustalenie użytkownika: jeden wydzielony slot baterii w odkurzaczu, przyjmujący
standardowe ogniwa zgodne z `mobilebattery`, w tym baterię fulgurium.
To samo rzeczywiste ogniwo w odkurzaczu zasila zasysanie i rozbiórkę. Slot zasilania
jest poza magazynem łupu i nie należy do partii rozbiórki. Aktywnego plecaka,
ssawki i ich elementów wewnętrznych nie wolno zassać jako łupu.

Pobór nalicza serwer za rzeczywistą pracę: czas zasysania i wykonaną
rozbiórkę. Wyjęcie lub wyczerpanie ogniwa zatrzymuje obie funkcje bez utraty
zawartości; przed transferem lub rozbiórką sprawdzić energię na całą daną
operację. Nie kasować przedmiotu za nieopłaconą część operacji. Podgląd
magazynu, ręczne wyjmowanie i bezczynne noszenie nie wymagają energii.
Koszty, zgodność ogniw i ewentualny czas rozbiórki są konfigurowalne;
wartości startowe dobiera wykonawca i sprawdza podczas testów.

Receptury obu części, wymagane umiejętności, ceny i dostępność w sklepach
dobrać w trakcie implementacji do pozostałych przedmiotów moda i udokumentować.
Bateria nie powstaje bezpłatnie przy craftingu zestawu.

## Zasysanie

Proponowany zasięg początkowy: 350 jednostek świata gry, stożek około 90°.
Parametry i tempo zbierania w osobnym module konfiguracji. Ściany i zamknięte
drzwi blokują pobieranie; nie zbierać przez dowolną liczbę pomieszczeń.

Cele obejmują wszystkie faktycznie podnoszone przedmioty, a nie zamkniętą
listę identyfikatorów podstawowej gry. Stacjonarna szafa lub skrytka oddaje
zawartość; przenośna skrzynka trafia do plecaka w całości wraz z zawartością.
Nie zbierać drugi raz jej elementów w tej samej operacji. Sprzęt założony na
martwej postaci można zdjąć, zachowując jego stan i zawartość, np. butlę
wewnątrz kombinezonu. Nie zabierać wyposażenia z żywych postaci ani własnego
ekwipunku użytkownika. Nie demontować elementów konstrukcyjnych łodzi.

Zachować istniejące znaczniki własności i konsekwencje kradzieży. Zamknięty
interfejs zwykłej szafki nie blokuje zasysania jej zawartości, ale prawdziwa
blokada dostępu wymaga uprawnień użytkownika. Nie wkładać odkurzacza do
siebie ani do jego własnych podpojemników; nie tworzyć cykli pojemników.

Serwer ponownie sprawdza obie części zestawu, zasilanie, wyposażenie, celowanie, odległość, przeszkody,
dostępność przedmiotu i miejsce. Rezerwuje pojedynczy cel na czas transferu;
dwa odkurzacze nie mogą skopiować tego samego przedmiotu. Limit operacji
na klatkę chroni płynność przy dużych ilościach łupu. Pełny magazyn zatrzymuje
pobieranie, pozostawiając cel i jego zawartość na miejscu.

## Magazyn i stosy po 100

Proponowana pojemność: **100 widocznych stosów po maksymalnie 100 sztuk**,
czyli teoretycznie do 10 000 przedmiotów, zależnie od zgodności grupowania.
Panel stronicowany, z wyszukiwaniem i możliwością wyjmowania jednej sztuki
lub grupy. Konkretna pojemność jest propozycją, a wydajność wymaga pomiaru.

Widoczny stos jest grupą rzeczywistych egzemplarzy. Nie zamieniać przedmiotów
na sam licznik identyfikatora. Zachować stan zużycia, jakość, amunicję,
butle, baterie, dane modów i zawartość każdego pojemnika. Identyczne typy
można grupować wizualnie, ale wydawanie musi jednoznacznie wskazywać konkretny
egzemplarz. Szczegóły panelu pozostają decyzją wykonawcy.

Preferowane zaplecze to rzeczywiste przedmioty w magazynach natywnych,
zgrupowane przez własny panel. Przed wyborem układu sprawdzić limity
indeksów slotów i liczb elementów w komunikatach sieciowych. Jeśli konieczny
jest podział na strony lub magazyny pomocnicze, wszystkie muszą być własnością
plecaka, zapisywać się wraz z nim i nie być osobnymi źródłami łupu.
Nie używać niezweryfikowanej serializacji wybranych właściwości jako
zamiennika pełnego stanu przedmiotu.

Zapis/odczyt kampanii, zmiana poziomu, śmierć właściciela, przekazanie plecaka,
rozłączenie i reloadlua muszą zachowywać całą zawartość. Limit entity ID gry
i koszty tysięcy aktywnych przedmiotów pozostają ograniczeniami do pomiaru;
nie deklarować bezlimitowego przechowywania.

## Rozbiórka całej zawartości

Kliknięcie tworzy migawkę wszystkich przedmiotów obecnych w magazynie,
również wewnątrz zagnieżdżonych skrzynek. Rozbiórka obejmuje najpierw
zawartość, później obudowy. Aktywny plecak, bateria odkurzacza, magazyny pomocnicze
i obsługujący go odkurzacz nie należą do partii.

Przedmioty z recepturą rozbiórki oddają materiały według rzeczywistych
definicji załadowanych do gry, z uwzględnieniem stanu, ilości, losowania
i warunków receptur. Nie zakładać, że każda receptura daje stały zestaw.
Wyniki z tej partii nie trafiają ponownie do kolejki — jeden klik nie
powoduje nieskończonego rozkładania własnych wyników.

**Ustalone przez użytkownika: przedmioty bez receptury nie są rozbierane.**
Pozostają rzeczywistymi przedmiotami w magazynie, ze swoim stanem
i zawartością. Nie zamieniać ich na żelazo ani inny zastępczy materiał
i nie pobierać energii za ich pominięcie. Warunkowa receptura, której nie da
się wykonać dla danego przedmiotu, również nie uprawnia do jego usunięcia.

Jeżeli rozbierany pojemnik zawiera pominięte przedmioty, przed usunięciem
obudowy trzeba przenieść je w całości do plecaka. Gdy nie ma dla nich miejsca,
obudowa pozostaje z zachowaną zawartością. Nie wolno skasować rzeczy tylko
dlatego, że znajdowały się wewnątrz rozbieranej skrzynki. Pojemnik bez
receptury pozostaje w magazynie, nawet jeśli jego zawartość dało się rozłożyć.

Przy braku miejsca odłożyć wykonanie danego elementu, zachowując oryginał;
nie wyrzucać wyników na ziemię i nie kasować źródła przed zabezpieczeniem
wyjścia. Serwer prowadzi kolejkę z limitem pracy na klatkę i odrzuca
powtórne żądania tej samej partii. Transfery oraz usuwanie/spawn wyników
muszą używać właściwych mechanizmów sieciowych gry. Zapis, reload lub
usunięcie urządzenia podczas partii nie może mnożyć przedmiotów ani ich
gubić. Testy muszą sprawdzać także te przerwania.

## Grafika i animacja

Oryginalne PNG z rzeczywistą przezroczystością, w stylistyce technicznej
zgodnej z dotychczasowym Aegisem i skalą postaci Barotraumy:

- Sprite plecaka do noszenia, wygląd odłożonego plecaka i jego ikona.
- Sprite dwuręcznego odkurzacza i jego osobna ikona; przewód łączy go z plecakiem.
- Zapętlona animacja strumienia wciągania skierowanego do wlotu, z osobnym
  początkiem i wygaszeniem albo płynną zmianą intensywności.

Grafiki generować narzędziem image_gen, następnie dopasować skalę,
przezroczystość i punkty mocowania. Klient rysuje przewód i strumień
na podstawie bieżącej pozycji ssawki. Jeżeli używany jest arkusz klatek,
klatki mają identyczne wymiary i stabilny punkt zaczepienia.
Efekt trafienia/pobrania pokazuje rzeczywisty kierunek od celu do wlotu.
Brak zasysania nie może pozostawiać wiszących efektów.

Zasoby w `MULTI-TOOL-V2/Assets/Vacuum/`. Prompty, podgląd animacji i opis
zasobów w `docs/vacuum/`, poza paczką gry. Zestaw testowy i generatory
również pozostają poza katalogiem instalacyjnym.

## Architektura i weryfikacja

Osobne definicje XML obu craftowalnych przedmiotów, moduły `Lua/SalvageVacuum/`
i autorun. Serwer lub
symulacja single player odpowiada za transfery, zawartość, partie rozbiórki
i kontrolę uprawnień. Klient odpowiada za panel, wygląd i zsynchronizowane
efekty. Komendy sieciowe weryfikują rzeczywistego użytkownika i właściciela;
identyfikator z klienta nie jest sam w sobie uprawnieniem.

Warunki ukończenia:

- Dwie ręce zajęte podczas wyposażenia; poprawny plecak, ssawka i przewód.
- Osobne receptury i faktyczny crafting plecaka oraz odkurzacza; bez
  kompletu zestaw nie zasysa i nie rozbiera przedmiotów.
- Wymienna bateria w wydzielonym slocie odkurzacza, jeden wspólny pobór na serwerze,
  zatrzymanie po wyjęciu/wyczerpaniu i zachowanie łupu; aktywna bateria
  nie jest rozbierana ani zasysana.
- Zbieranie z ziemi, szafy, skrytki, ciała, założonego kombinezonu i całej
  pełnej skrzynki; bez duplikowania zagnieżdżonej zawartości.
- Przenośne przedmioty spoza podstawowej gry rozpoznawane według komponentów.
- Stos 100 i przejście 100/101, zachowanie stanu różnych egzemplarzy,
  pełny magazyn, wyjmowanie i jednoczesny dostęp dwóch graczy.
- Jeden klik przetwarza całą migawkę; sprawdzone receptury warunkowe,
  pozostawienie rzeczy bez receptur, zachowanie pominiętej zawartości
  rozbieranych pojemników i pełny magazyn wyników.
- Zachowanie przedmiotów przy zapisie/odczycie, zmianie poziomu,
  rozłączeniu i reloadlua, również podczas rozbiórki.
- Widoczna animacja zasysania przy różnych kierunkach i praca w multiplayer.
- Test wydajności dużego magazynu, testy regresji istniejących urządzeń,
  walidacja XML/Lua/zasobów oraz aktualna paczka moda.

Raport końcowy rozdziela sprawdzone zachowania i próby, których nie wykonano.
Projekt opisuje zamierzony rezultat; nie jest deklaracją gotowej funkcji.
