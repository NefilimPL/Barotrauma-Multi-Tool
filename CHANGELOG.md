# Historia zmian

Przeniesione opisy wcześniejszych wydań z README. Pomiary i deklaracje
w tych wpisach dotyczą wskazanych wersji, nie bieżącego kodu roboczego.

## 1.3.23

- Ramię Descendants rzadziej ponawia wyszukiwanie aktywnego celu i ponownie
  wykorzystuje obliczoną geometrię. Zachowuje płynne wygładzanie przegubów
  oraz aktualne sprawdzenie zasięgu, dostępu i drogi strzału.
- Iskry naprawy rysuje natywny system cząstek. Bojowy multitool ogranicza
  zbędne testy promienia i przeliczenia geometrii tarcz oraz pierścieni.
- Zwykły multitool ponownie przyznaje pasywne punkty umiejętności.
- Pomiary ośmiu przedmiotów, próba mieszana, ponowne dołączenie i zapis
  pełnego plecaka są opisane w [raporcie wydajności](docs/PERFORMANCE.md).

## 1.3.22

Wyłączono automatyczne chwytanie postaci przez AI. Ręczny chwyt gracza,
naprawa i obrona botów pozostały dostępne.

## Wcześniejsze wydania

W **1.3.21** ramię na lądzie próbuje strzelać ponad sojusznikiem lub niską
przeszkodą: płynnie unosi lufę i czeka na bezpieczny prześwit. Ściana lub
zbyt niski sufit nadal blokują ogień. Po usunięciu przeszkody wraca do
zwykłego celowania. [Zachowanie i próby w grze](docs/DESCENDANT-RAISED-AIM.md).

W **1.3.20** tryb obronny używa pomniejszonej oryginalnej lufy lasera
pulsacyjnego i jego tekstury promienia. Usunięto dublowane czerwone linie;
chwytak i naprawa mają miękką poświatę zamiast prostokątnych pasów.
[Wygląd i próby w grze](docs/DESCENDANT-BEAMS.md).

W **1.3.19** szafka z szybą pokazuje duży hełm i fragment tułowia od przodu,
zanikające w przyciemnionym szkle, zgodnie z grafikami podstawowej gry.
[Porównanie z natywnymi kombinezonami](docs/DESCENDANT-RACK.md).

W **1.3.18** chwyt utrzymuje ciało wyżej podczas biegu i przepuszcza je przez
schody i podesty. Zasilany stojak ładuje baterię lub pręt. Mały sonar ma
skaner minerałów, a podświetlenie wskazuje aktywną funkcję. Obudowa wirnika
pozostaje nieruchoma, obracają się łopatki; podczas pływania powstają bąbelki.
[Aktualne próby i porównanie pływania](docs/DESCENDANT-SERVICE.md).
Paczka: [MULTI-TOOL-V2 1.3.22](output/MULTI-TOOL-V2-1.3.22.zip).

Od **1.3.17** ramię płynnie ustawia przeguby, a chwyt dostosowuje punkt
podtrzymania przy przeszkodach. Naprawa jest nieco wolniejsza, obrażenia
impulsu zmniejszono o 20%, a automatyczna naprawa nie wymusza kucania
ani ruchu postaci, również podczas oglądania panelu urządzenia.
Chwyt podtrzymuje cel po puszczeniu klawiszy, oba panele można
schować, a opcjonalny natywny sonar ma własny widok po lewej. Naprawa ma
większy zasięg i tolerancję ruchu, a promienie wychodzą z końcówki narzędzia.
[Podgląd tekstur, animacji i dźwięków](docs/descendant-suit/index.html) ·
[Używanie i rzeczywisty zakres weryfikacji](docs/DESCENDANT-SUIT.md).
Weryfikacja obejmuje testy regresji, klienta GPU i lokalny multiplayer.
Szczegóły i granice próby opisano w dokumentacji. Po aktualizacji zrestartuj
grę i serwer; obie strony potrzebują protokołu kombinezonu v5.

[Pomiar FPS na dwóch rzeczywistych klientach](docs/DESCENDANT-PERFORMANCE.md)
wykazał wyraźny narzut wielu napraw naraz: około 65% niższe FPS przy ośmiu
włączonych naprawach w scenie testowej. Raport zawiera również czasy klatek,
pojedyncze przycięcia, obciążenie serwera i ograniczenia porównania.

Wersja **1.3.15** zatrzymuje także lokalnie przewidywane trafienie pocisku
w tarczę. W 1.3.14 serwer blokował obrażenia i smuga kończyła się na tarczy,
ale klient nadal chwilowo naliczał ranę i ból, po czym synchronizacja
przywracała zdrowie. Poprawka przerywa trafienie przed zadaniem obrażeń;
nie leczy postaci po strzale. [Weryfikacja](docs/SHIELD-CLIENT-DAMAGE-VERIFICATION.md).
Po aktualizacji zrestartuj grę i hostowany serwer.

Wersja **1.3.14** kończy smugi pocisków na widocznej tarczy w multiplayerze.
Klient wcześniej rysował je przez tarczę mimo zablokowania obrażeń na serwerze.
Odtworzono to na rewolwerze kapitana z Enhanced Armaments i podłączonym graczu.
[Próba przed i po oraz zakres poprawki](docs/SHIELD-TRACER-VERIFICATION.md).
Po aktualizacji zrestartuj grę i hostowany serwer.

Wersja **1.3.13** zabezpiecza baterie obu słuchawek Aegis przed spamem
trafień i efektów, również modowych. Wszystkie koszty ochrony, leczenia
i regeneracji dzielą limit: początkowo do 5% baterii, następnie do 5%/s.
Pełne ogniwo wystarcza na co najmniej 19 s maksymalnego obciążenia
słuchawkami. Ochrona i tempo leczenia pozostają zachowane przy dodatnim
naładowaniu. Przekładanie baterii nie resetuje limitu.
[Testy i zakres zabezpieczenia](docs/HEADSET-POWER-VERIFICATION.md).
Po aktualizacji zrestartuj grę i serwer, aby wczytać nowe skrypty LuaCs.

Wersja **1.3.12** zawiera **plecak zbierający i dwuręczny odkurzacz Aegis**.
Obie części wytwarza się osobno. Bateria znajduje się w odkurzaczu i zasila
zasysanie oraz rozbiórkę całej zawartości jednym przyciskiem. Przedmioty bez
receptury pozostają nietknięte. Panel magazynu (**F**) grupuje rzeczy po 100,
zachowując stan i zawartość skrzynek. **Weź stos** wypełnia tylko jeden slot
zgodnie z natywnym limitem stosu, zostawiając nadmiar w plecaku.
[Instrukcja](docs/VACUUM.md) ·
[Grafiki i animacja](docs/vacuum/preview.html) ·
[Wyniki i ograniczenia testów](docs/VACUUM-VERIFICATION.md).

W **1.3.11** można zaznaczać wiele ikon i używać **Wyjmij zaznaczone**,
także dla grup spawarek i innych rzeczy z natywnym stosem 1. Nadmiar zostaje
w plecaku. Ręczne wkładanie działa przez przeciągnięcie przedmiotu na ikonę
plecaka. Zawartość jest dostępna u sprzedawcy w **Przy sobie**. Przełącznik
**Tylko luzem** pomija zawartość szaf i innych ekwipunków. Od **1.3.12**
zbiera także wyrzucone narzędzia z paliwem i przenośne pojemniki na ziemi,
zachowując ich zawartość.
Ustawienie zapisuje się na plecaku. Trafienia mają ograniczony koszt rysowania:
zbliżone błyski z jednej serii łączą się, a efekty poza ekranem są pomijane.
[Pomiary w grze i weryfikacja 1.3.11](docs/IMPACT-BACKPACK-VERIFICATION.md).
[Poprawka zbierania i wyjaśnienie sprzedaży narzędzi z baterią — 1.3.12](docs/LOOSE-PICKUP-MERCHANT-VERIFICATION.md).
[Rzeczywista sesja dwóch klientów: ostrzał 1/15 celów i masowe blokowanie](docs/TWO-CLIENT-COMBAT-VERIFICATION.md).
Host i wszyscy gracze muszą zaktualizować mod oraz ponownie uruchomić grę;
protokół plecaka zmienił się na v5.

Poprawka **1.3.5** usuwa okresowe skanowanie całego świata przy bezczynności
odkurzacza i bojowego multitoola na serwerze oraz klientach. Łup jest skanowany
tylko podczas zasysania po stronie serwera. Nieaktywny odkurzacz nie wysyła
ciągłych komunikatów sieciowych ani nie sprawdza ekwipunku dla audio.
Poprawka **1.3.6** przyspiesza dodatkowo wyszukiwanie baterii i paliwa przez
boty z headsetami oraz bojowym multitoolem, korzystając z indeksu źródeł
zasilania zamiast powtarzanych skanów całego poziomu.
[Pomiary i testy wydajności](docs/PERFORMANCE-VERIFICATION.md).

Poprawka **1.3.7** ogranicza sprawdzanie widoczności tarcz i pomija tarcze poza
ekranem, upraszcza aktualizacje odłożonych narzędzi oraz śledzi właścicieli
narzędzi dla pasywnych umiejętności. Skan łupu działa w porcjach po 256 rzeczy
na klatkę, a panel magazynu ponownie wykorzystuje 40 kafelków.

Poprawka **1.3.8** przenosi rozwijaną listę kategorii nad ikony i usuwa
opóźnienia zbierania spowodowane odległymi przedmiotami, także przy kilku
aktywnych odkurzaczach. Worek z wykluczoną zawartością pozostaje na miejscu,
a odkurzacz zabiera z niego dozwolone rzeczy. Chronione są oba końce
podłączonego przewodu. Tarcza sprawdza aktualne położenie i obrót broni
przy trafieniu. [Weryfikacja poprawek](docs/PICKUP-SHIELD-VERIFICATION.md).

Poprawka **1.3.9** przesuwa osadzenie tarczy do punktu mocowania broni,
aby wystająca podczas obrotu ręka nie przyjmowała pocisku przed łukiem.
Grafika i sprawdzanie ścian używają tego samego punktu. Test serwera
z Neurotraumą obejmuje rewolwer, SMG, karabin i pełne serie śrutu.
[Wyniki i zakres testu](docs/COMBAT-VERIFICATION.md).
Po aktualizacji host i gracze powinni ponownie uruchomić grę oraz serwer.

Poprawka **1.3.10** uwzględnia historyczne kolizje postaci przy przechwytywaniu
pocisków w multiplayerze. Plecak opisuje osobno **Grupy / 100** i **Sztuki / 10000**,
pokazuje postęp oraz wynik rozbiórki i pozwala dalej zbierać podczas jej pracy.
Nowe rzeczy czekają na następną partię. Rozbiórka pomija rzeczy bez receptury
w krótkich porcjach i odtwarza zapętlony dźwięk dekonstruktora z gry.
[Sprawdzenia i zakres poprawki](docs/SHIELD-SALVAGE-VERIFICATION.md).

Plecak zakłada się do slotu torby na pasie; grafika pozostaje na plecach
również bez ssawki. Okno otwiera przycisk **Magazyn plecaka [F]**, klawisz F
lub prawy klik ikony plecaka. Filtr zgodny z zasadą FastLoot pomija drzwi,
włazy, przedmioty bez slotu ekwipunku i zamontowane przewody, także w pojemnikach.

Panel pokazuje **40 ikon na stronę**, z nazwą, stanem i jakością po najechaniu.
Kategorie łączą się z wyszukiwaniem. **Filtr zbierania** pozwala wykluczać typy
przedmiotów, również wewnątrz pojemników; ustawienia są zapisane na plecaku.
**Kosz** trwale usuwa wybraną grupę lub egzemplarz wraz z zawartością po
potwierdzeniu liczby. Wsysanie ma dźwięk silnika i płynnie przenikające klatki
z ciągłym ruchem smug; udana rozbiórka uruchamia dźwięk rozdrabniacza.
Wybór plecaka jest widoczny tylko przy kilku dostępnych magazynach.
Plecak pasuje do miejsc na torby w dużej stalowej szafie; odkurzacz także można
schować w szafie. Zwykły i medyczny fabrykator korzystają z prawdziwych materiałów
z założonego plecaka oraz z plecaka w szafie połączonej z maszyną.

Poprawka 1.3.1 przyspiesza panel pełnego magazynu i czyści stan zasysania
przy zmianie rundy. Sprawdzono pełny zapis i odczyt kampanii, dwóch klientów,
rozłączenie podczas rozbiórki oraz przejście poziomu z 10 000 przedmiotów.

Mod Barotrauma z kompozytowym multitool'em, dwuręcznym **bojowym multitool'em Aegis**
oraz **dwoma komunikatorami regeneracyjnymi Aegis**.

Wersja **1.2.10** poprawia przechwytywanie pocisków mieszkańców wrogiej frakcji:
przynależność NPC do drużyny `FriendlyNPC` nie pozwala już omijać tarczy
przy wyłączonym friendly fire załogi. Zachowano poprawkę **1.2.9**:
obraz tarczy podąża płynnie za bronią między pakietami serwera, a ostrzał
członków załogi jest blokowany przy włączonym friendly fire.
Serwer nadal rozstrzyga aktywność tarczy, trafienia i zużycie energii.
Zaktualizuj mod na serwerze i wszystkich klientach.

Wersja **1.2.8** włącza zakup wszystkich pięciu przedmiotów moda.
Ceny bazowe: bojowy Aegis 2000 mk, zwykłe słuchawki 500 mk, Mk II 1000 mk.
Mk II zużywa **o 60% mniej energii** na leczenie, odtwarzanie anatomii,
trafienia i ciśnienie, przy zachowanym leczeniu 20 jednostek/s.
Poprawka **1.2.7** naprawia leczenie nokautu: słuchawki najpierw leczą
przyczynę obezwładnienia, zamiast zużywać całą energię na ogłuszenie
stale odtwarzane przez grę. Dotyczy to również paraliżu i nieprzytomności NT.
Od **1.2.6** Mk II leczy efekty urazów i chorób z wydajnością
**20 jednostek/s**, cztery razy większą niż model podstawowy (5/s),
od 1.2.8 dodatkowo taniej na jednostkę niż model podstawowy.
Odtwarzanie anatomii nadal jest
o 50% szybsze niż w podstawowym. Zachowano poprawkę 1.2.5: skutki amputacji
NT nie opróżniają baterii jak trafienia w tarczę. Neurotrauma jest opcjonalna.
Zachowano poprawki 1.2.4: usunięty pobór za techniczny znacznik Real Sonar;
ogniwo słuchawek jest chronione przed pobieraniem przez inne zadania AI.
Bot wymienia je przy **10% lub mniej**. Czerwone diody sygnalizują trafienie,
niebieskie leczenie; nowe rezonujące uderzenia i osobne alarmy 20%/10%/0%.
Komenda
`aegis_headset_status` pokazuje przyczynę rzeczywistego poboru energii.
Komunikatory zajmują slot słuchawek, mieszczą baterię,
chronią przed ciśnieniem i stopniowo regenerują zdrowie. Mk II dodatkowo
pochłania trafienia. **Neurotrauma i inne mody medyczne są opcjonalne.**
[Instrukcja komunikatorów](docs/HEADSETS.md) ·
[Grafiki, migotanie i odsłuch](docs/headsets/preview.html)

## Historia 1.1.x i pierwotnych prób

Wersja 1.1.10 włącza wybraną próbkę 3 — rezonator plazmowy — jako wystrzał.
Łuk rysowany jest natywną animacją Electricity i cząstkami ElectricShock,
których używa cewka wyładowcza gry. Każdy odcinek łańcucha korzysta z tego
efektu; zasady wybierania celów i obrażeń pozostają w symulacji serwera.

Wersja 1.1.9 stosuje filtr kolizji natywnych pocisków, pomijając platformy,
schody i kolizje naprawcze zniszczonych ścian. Usuwa to fałszywe rykoszety
w otwartych przejściach. Łuk może teraz trafić trzy różne postacie: 90 jednostek
na przeskok, każda kolejna ofiara otrzymuje o 25% słabsze porażenie. Nadal
obowiązuje 15% szansy na uruchomienie jednego łańcucha na pocisk i kontrola ścian.

Cztery oryginalne alternatywy wystrzału (pojedynczo i w serii) generuje
`python tools/generate_audio_alternatives.py`. Wyniki to samodzielny odtwarzacz
`output/AEGIS-sound-alternatives.html` i ZIP z plikami OGG. Próbki nie zmieniają
bieżącego wystrzału w modzie.

Wersja 1.1.8 dodaje wspólny pasywny przyrost dla obu multitooli: dokładnie
+2 do wszystkich pięciu umiejętności co 300 sekund trzymania z zasilaniem.
Aegis przyjmuje ogniwo lub pręt, a mniejszy multitool zachowuje wymóg pręta.
Licznik postaci nie sumuje się od kilku narzędzi i zatrzymuje się po schowaniu.
Bonus nalicza serwer albo symulacja single player, również botom; natywne limity
umiejętności są zachowane. Usunięto poprzedni bonus XML +1/minutę.
Pasywna nauka mniejszym multitoolem również wymaga teraz LuaCs.

Wersja 1.1.7 poprawia pozycję latarki podczas obracania broni. Przed narysowaniem
mapy światła punkt emisji i kierunek korzystają z tej samej interpolowanej
pozy fizycznego korpusu, z uwzględnieniem kierunku patrzenia.

Wersja 1.1.6 zastępuje nagranie broni palnej własnym wyładowaniem kondensatora
z basowym impulsem i trzaskiem elektrycznym. Trafienia mają większy rozbłysk,
iskry i rozchodzący się impuls. Odpychanie postaci wzrosło o 15%.
Każde trafienie powierzchni lub postaci daje 15% szansy na lekki przeskok
prądu do jednej innej postaci w promieniu 90 jednostek, najwyżej raz na pocisk.
Bezpośrednia ofiara i strzelec są pomijani. Ściany blokują przeskok, a friendly
fire rozgrywki chroni sojuszników zarówno przed oparzeniem, jak i ogłuszeniem.
Decyzja należy do serwera; klienci otrzymują oba końce widocznego łuku.

Wersja 1.1.5 dodaje natywny celownik podczas celowania i zwiększa
szybkostrzelność o około 20%: ładowanie 0,10 s, przerwa po strzale 0,28 s.
Główny dźwięk to teraz mocny wystrzał strzelby przy pełnej głośności źródła,
z głośniejszą warstwą elektrycznego wyładowania i większym zasięgiem słyszalności.
Aktualizacja wymaga ponownego uruchomienia gry, także na serwerze.

Wersja 1.1.4 wprowadza jeden wspólny slot zasilania i automatyczną zgodę
na walkę dla botów. Dźwięk wystrzału korzysta z natywnego nagrania broni
elektromagnetycznej z cichą, krótką warstwą wyładowania. Usunięto tonalne
przemiatanie z generowanych efektów i skrócono odbicia oraz ładowanie.

Wersja 1.1.3 dodaje oryginalne przestrzenne efekty audio, osobne dla wystrzału,
NPC, powierzchni i odbić, oraz krótki sygnał ładowania. Pierścień pulsuje,
ma obracające się jasne fragmenty i krótki ślad zachowujący trasę odbić.
Trafienie przekazuje natywny impuls, a broń ma niewielki odrzut.
Friendly fire wyłączone chroni sojuszników także przed tym impulsem.
Ładowanie trwa 0,12 s, przerwa po strzale 0,34 s; prędkość lotu wynosi
1050 zamiast 1400. Obrażenia, koszt pojedynczego strzału i zasięg pozostają
takie same. Większa częstotliwość zwiększa obrażenia i zużycie energii
w jednostce czasu. Głośność efektów reguluje standardowa głośność dźwięków gry.

Wersja 1.1.2 zmniejsza broń o 20%, poprawia punkty chwytu i pozycję lampy,
wyrównuje emitery narzędzi do lufy, zmniejsza i wycisza wizualnie tarczę.
Tekstura jest przycinana fragmentami przy ścianach. Renderer używa właściwego
mieszania alfa, a efekty ładowania i trafień mają poprawione punkty zaczepienia.
Pierścienie korzystają z natywnego friendly fire zamiast własnej odporności
sojuszników. Po zmianie definicji XML sprawdź nowo utworzoną broń;
stare przedmioty mogą zachować zapisaną skalę.

Wersja 1.1.1 poprawia błąd rysowania efektów na kliencie oraz ustawia
natywne światło kierunkowe z teksturą stożka. Po aktualizacji uruchom grę
ponownie, aby przeładować XML. Komenda `aegis_status` w konsoli F3 wypisuje
stan broni i sprawdza natywne ograniczenia slotów dla zwykłego ogniwa baterii.
W konsoli klienta kod Lua wykonuje się przez `cl_lua`, na serwerze przez `lua`.

