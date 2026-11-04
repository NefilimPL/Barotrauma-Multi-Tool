# Odkurzacz i plecak zbierający Aegis

Wersja 1.3.3 zawiera dwa osobno wytwarzane przedmioty. Wymaga LuaCs na
kliencie i serwerze, tak jak pozostałe urządzenia Aegis.

## Przygotowanie

1. Wytwórz **Plecak zbierający Aegis** i **Odkurzacz zbierający Aegis**.
2. Załóż plecak do **slotu torby na pasie (Bag)**, tak jak pas narzędziowy.
   Widać go na plecach także bez odkurzacza. Slot kombinezonu pozostaje wolny.
3. Włóż naładowane ogniwo do jedynego slotu **odkurzacza**. Zwykła bateria
   i bateria fulgurium są obsługiwane. Plecak nie ma slotu baterii.
4. Weź odkurzacz w obie ręce. Przewód połączy ssawkę z plecakiem.
   Sam plecak można przenosić w obu rękach, gdy slot torby jest zajęty.

Celowanie i przytrzymanie strzału uruchamia zasysanie w stożku o zasięgu
350 jednostek gry. Pobierane są przenośne rzeczy z ziemi, szaf, skrytek,
pojemników i martwych postaci. Przenośne skrzynki trafiają do plecaka
w całości, razem z amunicją. Można zdjąć kombinezon z martwej postaci.
Żywe postacie, własny ekwipunek, przymocowane urządzenia, zablokowane
inwentarze i niedostępne zamknięcia są pomijane. Ściany i zamknięte drzwi
blokują zasysanie. Obowiązują natywne zasady własności i kradzieży.

Reguła przedmiotów ekwipunkowych odpowiada FastLoot: wymagany jest rzeczywisty
slot przedmiotu. Drzwi i włazy, urządzenia bez slotów oraz przewody podłączone
choćby jednym końcem lub rozłożone w ścianie są wykluczone. Luźny przewód,
skrzynka z amunicją i kombinezon nadal mogą zostać pobrane. Kontrola obejmuje
zawartość pojemników, aby nie przenosić w nich niedozwolonych elementów.
Cały pojemnik przekraczający 256 sprawdzanych encji jest pomijany.

## Magazyn

Kliknij widoczny przycisk **Magazyn plecaka [F]**, naciśnij **F** lub kliknij
**prawym przyciskiem ikonę plecaka**. Okno działa również bez odkurzacza
i bez prądu. Panel pokazuje do 100 grup,
każda po maksymalnie 100 rzeczywistych przedmiotów tego samego typu.
Teoretyczny limit to 10 000 przedmiotów na plecak; zagnieżdżone skrzynki
zachowują własną zawartość. Licznik nie zastępuje przedmiotów — stan,
jakość, baterie, butle i zawartość pozostają przy konkretnych egzemplarzach.

- Pole wyszukiwania filtruje nazwy i identyfikatory.
- Siatka mieści **40 ikon na stronie**. Nazwa, liczba, stan i jakość są
  w podpowiedzi po najechaniu. Kliknięcie ikony zaznacza stos.
- **Wyjmij 1** przenosi jedną sztukę, a **Weź stos** pobiera zaznaczoną grupę,
  maksymalnie 100 sztuk. Gra zachowuje własne limity stosów w ekwipunku postaci;
  pozostałe rzeczy zostają w plecaku. Skrzynki i kombinezony wymagają wolnych rąk.
- **Egzemplarze** pokazuje pojedyncze sztuki wybranej grupy. Strzałki zmieniają
  stronę, a **Grupy** przywraca widok stosów. Przycisku „Odłóż” już nie ma.
- Przycisk **Plecak 1/2** przełącza magazyn, jeśli masz więcej niż jeden dostępny
  plecak. Przy jednym magazynie jest ukryty. Numer oznacza kolejność wyboru.
  Bez ręcznego wyboru pierwszeństwo ma plecak założony w slocie Bag.

Stosy po 100 są prezentacją w panelu. Zaplecze używa zapisywanych przez grę
stron po 100 pojedynczych rzeczy, mieszczących się w natywnym protokole.
Maksymalna pojemność nie oznacza gwarancji płynności przy 10 000 aktywnych
przedmiotów; ograniczenia i wyniki prób są w raporcie weryfikacji.

## Szafa i fabrykatory

Plecak można włożyć do dolnych miejsc na torby w dużej stalowej szafie.
Odkurzacz pasuje do jej zwykłych miejsc. Zawartość schowanego plecaka otworzysz
prawym kliknięciem jego ikony lub przyciskiem magazynu przy otwartej szafie.
Obowiązują odległość, blokady i wymagane uprawnienia do szafy.

Zwykły i medyczny fabrykator widzą materiały z plecaka założonego w slocie Bag
przez osobę obsługującą maszynę. Po zakończeniu obsługi osobisty plecak przestaje
być źródłem. Plecak w szafie działa zgodnie ze zwykłymi połączeniami maszyn:
**szafa musi być połączona z fabrykatorem**, tak jak inne magazyny materiałów.

Uwzględniana jest również zagnieżdżona zawartość. Maszyna pobiera i zużywa
rzeczywiste egzemplarze; nie powstaje kopia surowców. Plecak zablokowany lub
przetwarzany przez rozbiórkę nie udostępnia materiałów maszynie.

Po aktualizacji uruchom ponownie grę i serwer. Obie strony potrzebują 1.3.3,
ponieważ panel korzysta z nowej wersji komunikatów sieciowych.

## Rozbiórka

Trzymaj odkurzacz oburącz z baterią i wybierz **Rozłóż całą zawartość**.
Jeden klik tworzy partię wszystkich rzeczy obecnych wtedy w plecaku,
również w zagnieżdżonych skrzynkach. Przedmioty bez wykonalnej receptury
pozostają nietknięte. Nie zamieniają się w zastępcze żelazo.

Odzysk korzysta z załadowanych receptur, ilości, zakresów stanu,
warunkowego zwracania i ważonego losowania produktów. Receptury wymagające
łączenia z innym przedmiotem albo innego, specjalistycznego dekonstruktora
są zachowywane do obróbki w odpowiedniej maszynie. Urządzenie nie wykonuje
specjalistycznego rafinowania genetyki ani talentowych premii dekonstruktora.

Najpierw przetwarzana jest zawartość, następnie obudowa. Pozostałe rzeczy
z rozbieranej skrzynki są przenoszone do magazynu przed usunięciem skrzynki.
Gdy brakuje miejsca na zachowane rzeczy i produkty, źródło zostaje.
Nowo odzyskane materiały nie są ponownie rozbierane w tej samej partii.
Bateria zasilająca, aktywny odkurzacz i magazyny pomocnicze nie należą do łupu.

Wyjęcie baterii, brak energii, odłożenie odkurzacza lub utrata plecaka
zatrzymują pracę. Aby przetworzyć pozostałe rzeczy, uruchom przycisk ponownie.
W czasie rozbiórki wyjmowanie i zmiana plecaka są blokowane.

## Energia, crafting i konfiguracja

Wspólna bateria **w odkurzaczu** zasila zasysanie i rozbiórkę. Koszty
w procentach pełnego ogniwa: praca ssawki 0,15/s, pobranie przedmiotu 0,08,
rozbiórka jednego przedmiotu 0,4. Bezczynne noszenie i panel są bezpłatne.

Odkurzacz: fabrykator/fabrykator wojskowy, 30 s, mechanika 45, elektryka 35;
2 stopy tytanowo-aluminiowe, 2 miedzi, 2 plastiki, 1 FPGA. Cena bazowa 1800 mk.

Plecak: fabrykator/fabrykator wojskowy, 25 s, mechanika 40;
2 stopy tytanowo-aluminiowe, 3 plastiki, 2 gumy, 1 FPGA. Cena bazowa 1400 mk.
Ogniwo trzeba zdobyć osobno.

Parametry: `MULTI-TOOL-V2/Lua/SalvageVacuum/config.lua`.
Grafiki i animacja: `MULTI-TOOL-V2/Assets/Vacuum/`.
[Podgląd grafik i animacji](vacuum/preview.html) · [Raport testów](VACUUM-VERIFICATION.md).

## Tworzenie do testów

```text
enablecheats
spawnitem aegisvacuumpack inventory 1
spawnitem aegisvacuum inventory 1
spawnitem batterycell inventory 1
```

Nie twórz ręcznie wewnętrznych magazynów `aegisvacuumpage`; urządzenie
zakłada je automatycznie w miarę zapotrzebowania.
