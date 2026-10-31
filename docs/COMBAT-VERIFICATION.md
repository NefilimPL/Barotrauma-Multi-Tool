# Aegis — weryfikacja wersji 1.1.x

## Poprawka 1.1.10 — wybrany rezonator i natywny efekt cewki

Użytkownik wybrał próbkę 3 (rezonator plazmowy) i wskazał istniejący w grze
efekt przeskoku elektrycznego. Oba produkcyjne pliki shot-1/2 są teraz identyczną
kopią zaakceptowanego pojedynczego wystrzału 3-plasma.ogg, bez dodatkowych zmian
barwy czy głośności. Generator deleguje syntezę strzału do tego samego profilu
z czasem 0,46 s i jakością Vorbis 6; odbudowa daje identyczne zdekodowane PCM.

Natywna cewka ElectricalDischarger korzysta z SpriteSheet Electricity.png (4×4)
i cząstek ElectricShock. Wizualizacja każdego odcinka arc używa teraz tej samej
animacji silnika i cząstek, rozmieszczonych co 50 jednostek oraz przy trafionym
celu. Zastępuje poprzednią wizualizację łamaną z odcinków GUI. Cząstki emitowane
są raz na zdarzenie; rysowanie tylko animuje arkusz. Limit graficzny cząstek
może zwrócić null i jest obsłużony. Nie kopiowano plików gry do moda.

Dobór celów i obrażenia pozostają w dotychczasowej symulacji serwera. Nie
uruchamiano obszarowego ataku ElectricalDischarger, który ma własny zasięg
i przewodzenie po ścianach. Zachowane są trzy cele, osobne odcinki, kontrola
ścian, tłumienie siły i natywne friendly fire. Zmiany nie dotyczą protokołu
ani logiki trafień i AI sprawdzonej w wersji 1.1.9.

Regresja efektu najpierw RED (brak natywnych iskier), potem GREEN. **82/82 testy**
przechodzą. Natywny klient potwierdził rzeczywisty przyrost liczby cząstek po
zdarzeniu ElectricShock i rysowanie Electricity na GPU w 16 klatkach/czterech
kątach/trzech odcinkach łańcucha. Przeszły też celownik, mocowanie latarki
i sześć rodzin kanałów audio. Obydwa pliki strzału porównano bajt po bajcie
z zaakceptowaną próbką. Walidacja: 9 XML i 15 Lua. Nie powtarzano prób serwera,
ponieważ ta poprawka zmienia audio oraz wizualizację klienta.

## Poprawka 1.1.9 — otwarte przejścia, łańcuch prądu i odsłuchy

Zgłoszenie: fałszywe odbicia w otwartych poziomych przejściach, potrzeba
przeskoku łuku na kilka celów oraz kilku alternatywnych próbek wystrzału.

Natywny Projectile.DoRayCast używa maski kategorii pocisków. Poprzedni G.cast
pytał o wszystkie kategorie i uznawał każde Structure za ścianę, w tym platformy,
schody oraz ciało CollisionRepairableWall obecne również w pełnej dziurze.
G.cast stosuje teraz maskę natywnego pocisku i pomija wyłączone kolizje.
Maska jest inicjalizowana raz, przez natywne stałe Physics. Zmiana obejmuje
także przewidywanie lotu na kliencie i test widoczności przeskoków prądu.

Natywna próba porównawcza załadowała poprzedni moduł wyłącznie jako lokalny
baseline w testowym serwerze. Stary raycast trafił platformę i kolizję naprawczą
w zniszczonej ścianie; nowy przeszedł. Pozostałe próby potwierdzają, że pełna
ściana i zamknięty poziomy właz blokują, a w pełni otwarty właz przepuszcza.

Łuk nadal ma 15% szansy uruchomienia i jeden łańcuch na pocisk. Teraz może
przejść przez trzy różne postacie, z promieniem 90 jednostek od poprzedniego
punktu i osobnym raycastem ścian dla każdego odcinka. Strzelec, bezpośrednia
ofiara pierścienia i odwiedzone postacie są pomijani. Każdy kolejny przeskok
zachowuje 75% siły poprzedniego: bazowe oparzenia 1 / 0,75 / 0,5625 i ogłuszenie
0,2 / 0,15 / 0,1125 s. Friendly fire pozostaje natywne. Każdy odcinek wysyła
istniejące zdarzenie arc z oboma końcami; format wiadomości nie zmienił się.

Próbki tworzy tools/generate_audio_alternatives.py: impuls jonowy, wyładowanie
Tesli, rezonator plazmowy i pierścień magnetyczny. Każdy ma pojedynczy wystrzał
oraz serię pięciu przy nominalnym odstępie 0,38 s. Samodzielny HTML zawiera
osadzony dźwięk i dotychczasowy strzał jako odniesienie; ZIP zawiera HTML i osiem
plików OGG. Wszystkie są oryginalną syntezą. Produkcyjne audio pozostało bez zmian,
aby użytkownik mógł najpierw wybrać wariant.

Weryfikacja: **81/81 testów**, w tym cztery nowe regresje najpierw RED
(trzy dotyczące kolizji i jedna wielu celów) oraz osobna próba blokady kolejnego
przeskoku przez ścianę. Natywny serwer: **4/4** prób przejść, **5/5** łuku
(w tym trzy rzeczywiste ofiary i nietknięty czwarty cel), **5/5** pierścienia
i friendly fire, **5/5** tarczy. AI: **5/5**, 334 użycia spawarki bez strzelania,
potem 7 strzałów bez funkcji technicznych i zatrzymanie po ustaniu zagrożenia.
Klient: GPU 16 klatek/cztery kąty/dziewięć efektów, w tym trzy odcinki łańcucha,
celownik, mocowanie latarki oraz sześć rodzin audio — PASS.

Osiem próbek poprawnie dekoduje się, cztery wystrzały mają różne zawartości,
dziewięć osadzonych odtwarzaczy zawiera poprawne OGG, ZIP odsłuchów ma poprawne
CRC. Barwa pozostaje wyborem użytkownika. Walidator: 9 XML i 15 Lua.

## Poprawka 1.1.8 — pasywny przyrost wszystkich pięciu umiejętności

Użytkownik potwierdził wszystkie pięć umiejętności i zmianę tempa w obu wersjach:
+2 helm/weapons/mechanical/electrical/medical co 5 minut. Usunięto wcześniejszy
GiveSkill XML z mniejszego multitoola. Natywny interval przyznaje bonus również
przy pierwszym użyciu, więc nowy licznik wymaga pełnych 300 sekund przed pierwszą
nagrodą. Licznik postaci jest wspólny dla narzędzi; kilka egzemplarzy nie sumuje
czasu. Schowanie lub brak zasilania zatrzymuje naliczanie, zachowując postęp
w rundzie. Śmierć, koniec rundy i reload Lua zerują licznik; zdobyte poziomy
są przechowywane normalnie przez grę.

Przyjęty warunek zasilania: mniejszy multitool zachowuje wymaganie pręta;
Aegis dopuszcza pręt lub ogniwo. Źródło i narzędzie muszą być niewyczerpane,
postać musi być żywa, przytomna i trzymać narzędzie. Boty podlegają tym samym
zasadom. Naliczanie odbywa się tylko na serwerze albo w symulacji single player.

Dokładne +2 jest nadawane przez natywne CharacterInfo.SetSkillLevel z natywną
synchronizacją. Nie przechodzi przez mnożniki SkillGainSpeed ani premię pręta
+40% do tempa nauki mechaniki/elektryki. Zachowane są natywny limit 100 i wyższy
limit SkillSettings dla postaci z GainSkillPastMaximum; istniejące poziomy
ponad aktualnym limitem nie są obniżane. Standardowy przyrost z wykonywania
napraw i premia pręta do napraw pozostają niezależne.

Weryfikacja: **76/76 testów**, w tym siedem nowych najpierw RED (brak modułu),
potem GREEN: opóźnienie pierwszej nagrody, pięć dokładnych przyrostów, pauza
i wspólny licznik, źródła, klient multiplayer, limity i reset rundy.
Natywny serwer przeszedł **5/5** prób: +2 do wszystkich pięciu po progu 300 s,
schowanie/przełączenie narzędzia, dokładne +2 mimo aktywnej premii pręta,
brak nauki z pustym źródłem i limit 100, oraz automatyczne przekroczenie progu
przez rzeczywistą pętlę think. Dla skrócenia próby produkcyjny licznik przyspieszono
bez zmiany API postaci; w ostatniej próbie podano 299 s, a ostatnią sekundę
naliczyła sama gra. Nie wykonywano pięciominutowej próby czasu rzeczywistego.

Klient ponownie przeszedł próbę startu, mocowania latarki (5 kątów/2 kierunki),
GPU celownika, 16 klatek/czterech kątów/dziewięciu efektów i sześciu kanałów
audio. Walidator potwierdza 9 XML i 15 modułów Lua. Polska i angielska treść
przedmiotów opisują przyrost. Również pasywny bonus mniejszego multitoola wymaga
teraz LuaCs. Aktualizacja wymaga restartu gry i serwera, aby usunąć stary efekt XML.

## Poprawka 1.1.7 — obrót punktu emisji latarki

Zgłoszenie: początek stożka pasuje przy celowaniu poziomym, ale przesuwa się
obok broni przy pionowym. Natywny LightComponent obraca LightOffset według
statycznego `item.RotationRad`, podczas gdy kierunek stożka pobiera z fizycznego
`body.DrawRotation`. LightManager dodaje OffsetFromBody do pozycji korpusu
bez ponownego obrotu. To rozdziela obrót kierunku i początku światła.

Przed RenderLightMap klient aktualizuje pozycję rysowania korpusu i przelicza
lokalny LightOffset lampy tą samą interpolowaną rotacją oraz skalą i kierunkiem
patrzenia. Aktualizowana jest wyłącznie druga LightComponent Aegisa, bez zmiany
światła sterującego checkboxem obrażeń i bez wpływu na inne przedmioty.

Regresja jednostkowa najpierw wykazała brak poprawki. Rzeczywisty klient przed
zmianą odtworzył błąd przy 45 stopniach: offset (45,56; -6,12) zamiast
(36,54; 27,89). Po zmianie **69/69 testów** przechodzi; klient potwierdził
pozycję lampy dla pięciu kątów i obu kierunków (10 przypadków), a także GPU
celownika/16 klatek/czterech kątów/dziewięciu efektów i sześciu rodzin audio.
Walidacja: 9 XML i 14 modułów Lua. Zmiana dotyczy wyłącznie renderowania klienta;
nie zmieniano ani nie ponawiano prób serwerowych obrażeń i AI z wersji 1.1.6.

Odpowiedzi o balansie potwierdzono w kodzie: przeskok 15% na kontakt, również
przy odbiciu, zasięg 90 i najwyżej jeden na pocisk; 1–4 odbicia według jakości;
18 burn/12 blunttrauma bezpośrednio, burn 1/stun 0,2 s w przeskoku,
burn 1/stun 0,25 s przy kontakcie z tarczą. Każde odbicie osłabia obrażenia
i impuls o 15%. Aegis nie ma pasywnego GiveSkill; mniejszy multitool ma wpisane
mechanical 1 i electrical 1 co 60 s przy pręcie paliwowym (`reactorfuel`).

## Poprawka 1.1.6 — energetyczny strzał i przeskok prądu

- Zgłoszenie dotyczy brzmienia broni palnej zamiast energetycznej, słabo
  widocznego trafienia, większego stopping power i małej szansy porażenia obok.
  Ostatnie nagranie ShotgunShot było rzeczywistym odgłosem strzelby; zastąpiono
  je własnym 0,34-sekundowym wyładowaniem kondensatora z basem, modulacją cewki
  i nieregularnym trzaskiem. Dwa warianty strzału grają z głośnością 1,0.
  Usunięto osobną cichą warstwę strzału. Doszły dwa krótkie dźwięki przeskoku.
- Efekty trafień były już emitowane, ale arkusz miał skalę 0,12 i cienkie,
  krótkie iskry. Skala trafienia ściany/NPC/odbicia wynosi teraz 0,26, pojawia
  się jasny krzyż w punkcie kontaktu, dwanaście iskier i rozszerzający impuls.
- Impuls trafienia wzrósł z 7,5 do 8,625 (+15%). Bezpośrednie obrażenia,
  szybkostrzelność i koszt strzału pozostają takie jak w 1.1.5.
- Decyzje wykonawcy dla dodatkowego porażenia: 15% szansy na kontakt ze ścianą
  lub postacią, zasięg 90 jednostek, jedna najbliższa widoczna postać, najwyżej
  jeden udany przeskok na pierścień. Pomijani są strzelec, bezpośrednia ofiara,
  martwe i usunięte postacie. Test widoczności używa prawdziwych kolizji ścian
  i zamkniętych drzwi. Porażenie daje 1 oparzenia (słabsze po odbiciu) i 0,2 s
  ogłuszenia. Odbijający się pierścień może dalej lecieć po przeskoku.
- Losuje wyłącznie serwer/symulacja single player. Zdarzenie `arc` (ID 9)
  przekazuje oba końce wyładowania; istniejące zdarzenia zachowują format.
  Klient rysuje migoczący łuk przez 0,22 s i odtwarza przestrzenny trzask.
- Natywne `DamageLimb` ustawia argument stun przed sprawdzeniem friendly fire.
  Dlatego nowy przeskok przekazuje ogłuszenie jako affliction, razem z oparzeniem,
  za natywną kontrolą friendly fire. Nie dodano własnej odporności sojuszników.

Weryfikacja: sześć nowych regresji najpierw odtworzyło brak przeskoku,
brak przesyłania końca łuku i zbyt delikatny efekt. Po zmianie **68/68 testów**
przechodzi. Natywny serwer: **5/5** prób pierścienia (obrażenia, impuls,
friendly fire i wyrównanie emiterów), **4/4** prób elektrycznych (wrogie obrażenia
i ogłuszenie, FF off chroni oba, FF on dopuszcza oba, jeden przeskok na ring),
**13/13** prób podstawowych. W testach elektrycznych wymuszono udany wynik
losowania; postacie, raycasty, affliction i ustawienia rozgrywki były natywne.

Natywny klient z GPU: celownik, 16 klatek/cztery kąty/dziewięć rodzajów efektów,
w tym łuk, oraz sześć rodzin kanałów audio — PASS. Walidator: 9 XML/14 Lua,
referencje i receptura zgodne; wszystkie 11 plików Vorbis poprawnie dekoduje się.
Subiektywna barwa dźwięku i czytelność efektów wymagają oceny w rozgrywce.
Nowy format zdarzenia wymaga tej samej wersji moda na kliencie i serwerze;
po aktualizacji należy ponownie uruchomić grę, aby wczytać XML dźwięków.

## Poprawka 1.1.5 — mocniejszy wystrzał, szybkostrzelność i celownik

- Zgłoszony brak celownika wynikał z braku `Crosshair`, `CrosshairPointer`
  i `drawhudwhenequipped` w komponencie RangedWeapon. Dodano natywne grafiki
  celownika gry ze skalą 0,18; obsługa celowania pozostaje w natywnym HUD.
- Nagrania Coilgun zastąpiono mocniejszymi ShotgunShot1/2 przy głośności 1,0
  i zasięgu 1400. Warstwa wyładowania wzrosła z 0,14 do 0,4 i zasięgu 1100.
  Pliki gry są referencjami Content, bez dołączania ich do paczki moda.
  Zachowano natywne tłumienie przez wodę, ściany i ustawienia dźwięku.
- Ładowanie 0,10 s i przerwa 0,28 s zamiast 0,12/0,34: nominalnie 21% więcej
  strzałów. Test rzeczywistej pętli przytrzymanego spustu przy 60 Hz daje
  wzrost około 24% wskutek zaokrąglania do klatek. XML i Lua mają tę samą
  przerwę. Koszt pojedynczego strzału pozostaje taki sam, więc szybszy ogień
  szybciej zużywa energię.

Oba nowe testy regresji najpierw odtworzyły brak celownika i starą
szybkostrzelność; po poprawce **62/62** testy przechodzą. Walidator potwierdza
9 XML, 14 modułów Lua i obecność referencji Content w instalacji 1.13.5.0.
Rzeczywisty klient utworzył broń, sprawdził włączony natywny HUD, załadował
i narysował obie grafiki celownika na GPU. Przeszedł także 16 klatek/cztery
kąty/osiem efektów i pięć rodzin przestrzennych kanałów audio. Test nie
zastępuje oceny brzmienia w rozgrywce ani ręcznej oceny położenia celownika.

Świeży serwer: **13/13** prób podstawowych oraz **3/3** prób naturalnej
samoobrony, w tym 12 strzałów bota z początkowo wyłączonym checkboxem gracza.
Ponowiona próba naprawy/walki przeszła **5/5** sprawdzeń: 304 użycia spawarki
bez innych funkcji, potem 6 strzałów w walce bez funkcji technicznych;
usunięcie zagrożenia zatrzymało strzelanie i tarczę. Liczba strzałów w tym
scenariuszu zależy także od czasu namierzania, więc nie służy do pomiaru
szybkostrzelności.

## Poprawka 1.1.4 — wspólne zasilanie, samoobrona i dźwięk

Użytkownik zmienił wymagania: jeden slot dla całego zasilania; bot ma sam
decydować o walce, a nie wymagać ręcznego checkboxa. Te ustalenia zastępują
pierwotną zasadę dwóch źródeł i blokowania botów checkboxem gracza.

- Kontener ma jeden slot. Broń, narzędzia, latarka, tarcza i jej trafienia
  obciążają fizyczny slot 0. AI uzupełnia tylko ten slot; podczas walki
  minimalny zapas wystarcza na pełny strzał. Stan tarczy w sieci i rendererze
  odczytuje to samo źródło.
- Odtworzono zgłoszenie na rzeczywistym serwerze: naładowany Aegis schowany
  w ekwipunku, śrubokręt w ręce, ręczny checkbox wyłączony, zwykłe natywne
  zadanie Defensive dodane ścieżką kontrolera reakcji na zagrożenie. Przed
  poprawką bot wybierał śrubokręt i oddawał zero strzałów. Przyczyna: hook
  wyzerował priorytet Aegisa na podstawie ręcznej preferencji gracza.
- Po poprawce natywne porównanie uzbrojenia wybiera Aegisa. Efektywne
  zezwolenie bota pochodzi z wykonywanego zadania walki lub zapamiętanego
  aktywnego natywnego zadania samoobrony, również równoległego do napraw.
  Zapisany checkbox gracza nie jest zmieniany; dla gracza nadal jest blokadą.
  Pocisk wystrzelony przez bota nie znika z powodu wyłączonej preferencji
  gracza. Zakończenie zagrożenia wyłącza automatyczną tarczę i kolejne strzały.
- Główna warstwa strzału korzysta z natywnych nagrań Coilgun1/2 przez ścieżki
  Content, bez kopiowania plików gry do moda. Cichy dodatkowy trzask jest
  syntetyczny. Usunięto przemiatanie wysokości tonu; wyładowania, odbicia
  i ładowanie są krótkie i szumowe zamiast melodyjnych.

Weryfikacja: **60/60 testów automatycznych**, **13/13** prób podstawowych
z jednym slotem, **5/5** prób tarczy, **5/5** prób obrażeń/impulsu oraz
**3/3** prób naturalnej samoobrony. W tej ostatniej bot sam odłożył
śrubokręt, wyposażył schowanego Aegisa i oddał **10 strzałów**; nie ustawiano
mu broni, wymuszonego rozkazu, najwyższego priorytetu, wejścia celowania ani
checkboxa. Natywne zadanie samoobrony zostało dodane przez kontroler AI,
nie przez faktyczne zranienie postaci.

Rzeczywisty klient z GPU ponownie narysował 16 klatek/cztery kąty i osiem
efektów, a pięć rodzin dźwięków utworzyło przestrzenne kanały audio. Barwa
dźwięku pozostaje subiektywną oceną użytkownika podczas rozgrywki.

Ponowiona próba naprawy/walki przeszła **5/5** sprawdzeń: 312 użyć spawarki
bez innych funkcji, potem 7 strzałów w walce bez funkcji technicznych.
Usunięcie rzeczywistego zagrożenia zatrzymało strzelanie i tarczę bota.

Przy aktualizacji należy wyjąć oba źródła ze starszej broni przed zmianą
definicji kontenera na jeden slot. Do oceny nowego układu najlepiej utworzyć
nowy egzemplarz po ponownym uruchomieniu gry. Zmiany dotyczą wyłącznie Aegisa.

## Poprawka 1.1.3 — odczucie strzału, dźwięk i impuls

Zgłoszenie użytkownika: brak dźwięków strzelania i trafień, zbyt statyczny
pierścień, słaba reakcja NPC, za długa przerwa między strzałami i za szybki lot.
Dobór dokładnych wartości i charakteru audio jest decyzją wykonawcy w ramach
zleconego strojenia istniejącej broni.

- Ładowanie 0,12 s i przerwa 0,34 s dają około 2 strzałów/s przy trzymaniu
  spustu, wobec około 1/s wcześniej. Lot: 1050 zamiast 1400 jednostek/s.
  Czas życia podniesiono do 3,2 s, aby zachować zasięg 3200.
- Dziewięć oryginalnych, proceduralnie syntezowanych plików mono Vorbis
  tworzy pięć rodzin: wystrzał, ładowanie, NPC, powierzchnia i odbicie.
  Natywne prefabrykaty dźwięków wybierają warianty. Odtwarzanie następuje
  raz na zdarzenie serwera/lokalnej symulacji, w pozycji świata, z natywną
  głośnością, tłumieniem przez ściany i wodę. Błąd audio nie blokuje broni.
- Naprawiono brak zdarzenia ostatniego uderzenia w ścianę po wyczerpaniu
  odbić. Zdarzenie `wallhit` ma własny numer; serwer i klienci wymagają
  tej samej wersji moda.
- Pierścień pulsuje, ma obracające się gorące fragmenty, poświatę i krótki
  ślad. Ślad zapisuje faktyczne punkty odbić, ma limit 12 punktów/0,12 s
  i jest zachowywany przy synchronizacji, o ile korekta nie przecina ściany.
  Dodano rozbłysk lufy, rozchodzące się impulsy i kierunkowe iskry trafień.
- Trafienie przekazuje impuls 7,5 pomniejszany po odbiciach. Impuls przechodzi
  przez `Character.AddDamage`, dzięki czemu wyłączone friendly fire chroni
  też przed popchnięciem. Nie dodano osobnego ogłuszania omijającego tę
  ochronę. Dodano umiarkowany natywny odrzut samej broni.
- Obrażenia pojedynczego trafienia i koszt strzału nie wzrosły. Większa
  częstotliwość zwiększa obrażenia i zużycie energii w jednostce czasu.

Wyniki końcowe:

- **56/56 testów automatycznych**, w tym nowe regresje dźwięku zdarzeń,
  końcowego trafienia, impulsu natywnego, ruchomej obręczy, trasy śladu,
  ciągłości po synchronizacji i kadencji. Przed implementacją nowe testy
  odtworzyły brak tych zachowań.
- **Rzeczywisty klient/GPU i audio:** 16 klatek, 4 kąty, animowane pierścienie
  i ślady, 8 rodzajów efektów; pięć rodzin dźwięków utworzyło rzeczywiste
  przestrzenne kanały audio bez błędu. Wszystkie 9 plików przeszło też
  niezależne dekodowanie Vorbis przez ffmpeg.
- **5/5 natywnych prób pierścienia:** obrażenia przeciwnika, mierzalny
  ograniczony przyrost prędkości NPC po trafieniu, obrażenia sojusznika
  przy friendly fire włączonym, brak obrażeń i zmiany prędkości przy
  friendly fire wyłączonym, zgodność pozycji emiterów.
- **13/13** prób podstawowych i **5/5** prób AI: 319 dozwolonych użyć
  spawarki bez strzelania, następnie 6 strzałów w zadaniu walki bez
  wywołań technicznych; checkbox zatrzymuje broń i tarczę.
- Ponownie przeszło **5/5** natywnych prób tarczy i kolizji pocisków.

Próba audio potwierdza dekodowanie, tworzenie kanałów i przestrzenne API;
subiektywna barwa i głośność pozostają do oceny w rozgrywce. Podgląd HTML
w `Assets/Combat/Audio/preview.html` pozwala odsłuchać efekty osobno.

## Poprawka 1.1.2 — geometria grafiki i friendly fire

Zgłoszenie użytkownika: zbyt duża broń i tarcza, znikanie tekstury przy
celowaniu w górę, przesunięte efekty, światło poza lampą, złe punkty chwytu
oraz brak obrażeń załogi w testerze.

Przyczyny i zmiany:

- Kod pomijał sojuszników już podczas sprawdzania kolizji pierścienia.
  Teraz wykrywa trafienia postaci poza strzelcem i wywołuje natywne
  `Character.AddDamage`, które uwzględnia ustawienia friendly fire rozgrywki.
  Tarcza nadal przechwytuje wrogie ataki i poraża przeciwników.
- Jeden zasłonięty punkt wyłączał całą teksturę tarczy. Przycinanie odbywa
  się teraz w 16 pasach z zachowaniem wspólnego punktu obrotu.
  Promień tarczy zmniejszono z 95 do 80, wysokość grafiki wynosi około
  139 jednostek, a krycie tekstury około 18% zamiast dotychczasowych 90%.
- PNG mają zwykły kanał alfa; domyślny `AlphaBlend` oczekuje kolorów
  pomnożonych przez alfa i nadmiernie rozjaśniał efekty. Renderer używa
  `NonPremultiplied`. Typ `BlendState` jest jawnie rejestrowany w LuaCs.
- Skalę broni zmniejszono z 0.085 do 0.068. Uchwyty wskazują dolne chwyty
  tekstury (poprawiony znak Y), a lampa ma początek na jej soczewce.
  Emitery `RepairTool` wymagają jednostek świata, w przeciwieństwie
  do skalowanego `RangedWeapon`; wszystkie trzy mają poprawione pozycje.
- Ładowanie zaczyna się przy lufie i podąża za nią. Efekty trafienia/odbicia
  są mniejsze i wykorzystują normalną powierzchni zamiast kierunku broni.
  Kompresję sprite'a broni wyłączono, ponieważ jego wymiary nie są
  wielokrotnością czterech. Sam bitmapowy zasób pozostaje bez zmian.

Weryfikacja:

- **49/49 testów automatycznych.** Nowe regresje odtworzyły odmowę trafiania
  sojusznika, znikanie całej tarczy przy częściowym zasłonięciu,
  niewłaściwą orientację trafień i niepoprawny układ broni. Testy sprawdzają
  też stały punkt obrotu pasów tekstury i tryb mieszania alfa.
- **4/4 nowe próby natywne:** rzeczywisty pierścień odbiera żywotność wrogiemu
  NPC; odbiera ją załodze przy friendly fire włączonym; nie odbiera jej po
  wyłączeniu tej opcji; pozycje lufy narzędzia i broni pokrywają się.
  Scenariusz przechodzi przez produkcyjne `fire/updateRings`, raycasty
  i natywne obrażenia, a nie bezpośrednie wywołanie testowej funkcji obrażeń.
- Powtórzono **13/13** prób podstawowych, **5/5** prób tarczy/fizyki i
  **5/5** prób AI (328 wywołań spawarki, 3 strzały podczas walki,
  brak równoczesnych funkcji, checkbox skutecznie wyłącza broń/tarczę).
- **Rzeczywisty klient z GPU:** osobna kopia klienta 1.13.5.0/LuaCs,
  uruchomiona w ukrytym oknie, w edytorze statku. Produkcyjny renderer
  narysował 16 klatek dla czterech kątów celowania i siedmiu typów zdarzeń
  na rzeczywistym `SpriteBatch`, bez błędu. Wynik: `PASS native client GPU
  rendering: 16 frames, 4 aim angles, 7 effect kinds`.
  Instalacja gry użytkownika nie była zmieniana.

Próba klienta potwierdza działanie API rysowania; nie zastępuje wizualnej
oceny dłoni na animowanej postaci ani dłuższej rozgrywki z dwoma klientami.
Przy sprawdzaniu nowej skali należy utworzyć nowy egzemplarz broni;
zapisany przedmiot może przechować starą skalę.

## Poprawka 1.1.1 — zgłoszenie z testera statku

Zrzut konsoli użytkownika ujawnił `attempt to index a nil value` w
`visuals.lua` podczas rysowania arkusza. Kod wymagał globalnego
`SpriteEffects.None`, którego nie było na kliencie. Teraz korzysta
z domyślnego argumentu natywnego `Sprite.Draw`. Poprawiono również
odwołanie do rysowania linii: aktualny LuaCs udostępnia je przez `GUI.GUI`.
Test renderera używa tego układu API i braku globalnego enumu; odtworzył
błąd przed zmianą i przechodzi po poprawce.

Latarka otrzymała `directional="true"`, natywny `LightTexture` z
`Content/Lights/lightcone.png` oraz `LightColor` i przesunięcie do lufy.
Samo `coneangle` bez tekstury nie tworzyło stożka. Osobny test wykazał
błędną konfigurację przed poprawką i przechodzi po zmianie.

Pełny zestaw ma teraz **45/45 testów automatycznych**. Walidacja obejmuje
8 XML i 13 Lua. Natywne API potwierdziło, że zwykłe `batterycell` ma tag
`mobilebattery`, jest dopuszczone w obu slotach i daje się włożyć.
Ponowiony test podstawowy przeszedł **13/13 sprawdzeń**, w tym ograniczenia
obu slotów i rzeczywisty callback checkboxa zamiast ręcznej zmiany flagi.
Nie odtworzono jeszcze zgłoszonej odmowy wkładania na kliencie użytkownika;
nie należy traktować jej jako usuniętej. Dodano niemodyfikującą stanu
komendę `aegis_status`, sprawdzoną również na rzeczywistym serwerze.
Pełny test renderera w kliencie i ponowna próba użytkownika pozostają
konieczne. Dalszy tekst opisuje wcześniejszą weryfikację 1.1.0.

Weryfikacja końcowa: 2026-10-31. Kod i paczka są przeznaczone do prób w grze;
poniższe wyniki nie zastępują sprawdzenia grafiki i synchronizacji na klientach.

## Środowisko i odtworzenie

- Barotrauma Dedicated Server 1.13.5.0, LuaCs `c6e8829`.
- Osobna kopia w `.runtime/server`, bazowa zawartość gry i MULTI-TOOL-V2.
  Oficjalny patch LuaCs zastosowano wyłącznie do tej kopii. Instalacja Steam
  nie była modyfikowana.
- Python, Lupa 2.8 (interpreter Lua 5.2), Pillow; zależności lokalne.

```powershell
python tools/run_tests.py
python tools/validate_content.py --game 'D:/SteamLibrary/steamapps/common/Barotrauma'
git diff --check
python tools/package_mod.py
```

Skrypty natywne wymagają rundy Sandbox na serwerze testowym. Skopiuj
`tests/runtime/{smoke,shield_integration,ai_integration}.lua` do katalogu
`Lua/Tests/` testowej kopii moda, następnie uruchom z konsoli:

```text
lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/smoke.lua')
lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/shield_integration.lua')
lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/ai_integration.lua')
```

Ostatni skrypt trwa około 14 sekund. Testy tworzą postacie i przedmioty,
modyfikują stan rundy i zapisują wyniki w testowym folderze moda. Wyłącznie
testowy `keepalive.lua` utrzymuje rundę bez graczy. Żaden z tych skryptów
nie należy do paczki moda.

## Wyniki

- **43/43 testy automatyczne:** geometria i budżet odbić dla wszystkich jakości,
  wydawanie energii z właściwego slotu, priorytety funkcji, anulowanie ładowania,
  blokada powtórzonych użyć, zmiana właściciela, zasięg tarczy i zasłonięcie
  ścianą, uzupełnianie źródeł, synchronizacja po przeładowaniu Lua.
  Test renderera używa atrap API: sprawdza wszystkie prostokąty klatek,
  poprawne otwarcie/zamknięcie rysowania i lokalną predykcję pierścienia.
- **Walidacja zawartości:** 8 plików XML, składnia 12 plików Lua 5.2,
  ścieżki zasobów, kanał alfa pięciu PNG, prostokąty 16-klatkowych animacji,
  dwie ręce, dwa sloty, trzy checkboxy i identyfikatory surowców z gry.
- **12/12 natywnych sprawdzeń podstawowych:** wyposażenie, rozdzielenie
  zasilania, rzeczywiste właściwości komponentów, ładowany strzał,
  zapytanie fizyki, tarcza i blokada po wyczerpaniu, wyłączenie obrażeń,
  wyłączność spawania/cięcia, wymiana częściowo zużytej baterii broni oraz
  uzupełnienie tarczy bez ruszania źródła w slocie broni.
- **5/5 natywnych prób fizyki i obrażeń:** promień trafia rzeczywistą ścianę
  łodzi, tarcza zatrzymuje hitscan przed obrażeniami chronionej postaci,
  bliższa niechroniona postać nadal otrzymuje obrażenia, szybki pocisk fizyczny
  jest przechwytywany na przebytym odcinku, kontakt z tarczą zadaje natywne
  obrażenia i zużywa 6 jednostek energii.
- **5/5 natywnych prób AI:** podczas usuwania wycieku bot wykonał 308
  dozwolonych wywołań spawarki, bez cięcia, gaszenia ani strzelania,
  mimo włączonych checkboxów technicznych. Po zmianie zadania oddał
  4 ładowane strzały, z zerem wywołań technicznych podczas zadania walki.
  Wyłączenie obrażeń zatrzymało kolejne strzały i tarczę.

## Poprawki po przeglądzie i testach

Przegląd całej zmiany wskazał sześć istotnych problemów. Każdy otrzymał
test regresji i poprawkę: przesunięcie współrzędnych łodzi, pobieranie
odległego źródła przed wkładaniem, anulowanie zawieszonych zadań uzupełniania,
kolejność kolizji hitscan, anulowanie ładowania przez bierne odczyty AI
oraz reset numeracji pakietów po przeładowaniu serwera.

Natywne próby wykryły również ograniczenia mostka Lua/C#: dostęp do pola
wymaga deskryptora, a delegaty `Func<Item,bool>` i `Func<PathNode,bool>`
nie przyjmują bezpośrednio użytych funkcji Lua. Wymiana baterii korzysta
dlatego ze standardowego przeniesienia dokładnie jednego starego źródła
do ekwipunku bota (lub upuszczenia przy pełnym ekwipunku), a następnie
z natywnego zadania wkładania do wskazanego slotu. Inny slot pozostaje
nienaruszony. Odrzucone wywołania komponentów podczas natywnego `Item.Use`
nie przerywają już ładowania właściwego strzału.

## Pozostałe próby w kliencie gry

- Dopasowanie sprite'a do dłoni i lufy, jasność latarki oraz pozycja,
  czytelność i płynność czterech animacji tarczy w rzeczywistym rendererze.
  PNG obejrzano i przygotowano podgląd HTML; klient gry nie był uruchamiany.
- Dwa klienty, opóźnienia sieciowe, dołączenie w trakcie rundy i ponowne
  wczytanie zapisu. Serwerowa logika i testy kontraktu sieci przeszły;
  pełna rozgrywka sieciowa pozostaje do sprawdzenia.
- Pełne dojście bota do odległej baterii przez drzwi i śluzy. Tworzenie
  natywnego zadania pobrania objęto testem, a wkładanie sprawdzono w grze;
  cała trasa nie była osobnym scenariuszem integracyjnym.
- Oddzielne scenariusze AI naprawy urządzenia, gaszenia pożaru i wyboru
  przecinarki. Wybór funkcji oraz blokady objęto testami adaptera; natywny
  scenariusz wykonywanego zadania sprawdzono dla spawania i walki.
- Pełny cykl fabrykacji/dekonstrukcji z bateriami wewnątrz. Receptura
  i identyfikatory są poprawne. Zwrot zawartości wynika z odczytanego kodu
  natywnego fabrykatora/dekonstruktora oraz ustawień kontenera, lecz cykl
  nie został wykonany w grze.
- Skryptowe lasery i nietypowe pociski innych modów; balans w dłuższej rundzie.

## Decyzje wykonawcze

Polecenie „działaj” upoważniało do implementacji zatwierdzonego projektu.
Pracę wykonano bezpośrednio w istniejącej gałęzi funkcji `dev_weapon`;
nie wykonywano publikacji, push ani merge. W Windows użyto równoważnego
rejestru PowerShell/Python zamiast pomocników Bash. Ukryty kontener z atrapią
paliwa zastąpiono natywnymi zadaniami dojścia i obsługi spawarki, ponieważ
AI wycieków odczytuje tylko pierwszy kontener. Nie zmieniono tagów paliwa
ani istniejącego jednoręcznego multitoola.
