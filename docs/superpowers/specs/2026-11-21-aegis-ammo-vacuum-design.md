# Amunicja ramienia i ustawienia plecaka

Wdrożono w wersji 1.3.24.

## Ramię i wentylator

Wspólny kod rysowania obu elementów może zatrzasnąć się po jednym wyjątku.
Sprawdzić renderowanie w rzeczywistej grze i zapisać błąd oraz stan wyposażenia,
jeżeli problem wystąpi. Odtworzyć warunek, który blokuje rysowanie, przed
zmianą kodu. Test ma sprawdzać obecność przegubów i obudowy z wirnikiem w
rzeczywistym rysowaniu klienta, także w okolicy łodzi i po zmianie rundy.

Sprawdzono zainstalowane pliki 1.3.23. Kod renderera i grafiki wentylatora
są zgodne z paczką. W kontrolowanej grze jednoosobowej wewnątrz łodzi i w
multiplayerze z Neurotraumą i Enhanced Armaments ramię się rysowało.
Odtworzono osobno zatrzaśnięcie renderera po jednym błędzie i poprawiono
ponawianie rysowania jednego nosiciela. Dokładny wyzwalacz obserwowany
w sesji gracza nadal wymaga identyfikacji.

## Amunicja

Skrzynka w istniejącym slocie wybiera typ pocisku. Preferowane są jawne
profile znanych skrzynek z podstawowej gry. W pierwszej kolejności obejmują
laser pulsacyjny, Gaussa i ich warianty, z zachowaniem odrębności efektów.
Każdy profil ma mniejszy pocisk, dostosowane obrażenia i zużycie
skrzynki dające pełnej skrzynce około trzykrotnie więcej cykli strzału
niż w jej natywnym działku. Warianty wiązek i salw zachowują swój typ.
Użyć istniejącej synchronizacji oraz natywnych zasobów. Sprawdzić skrzynkę,
energię, aktualny cel i tor strzału ponownie przed opłaceniem strzału.
Podmiana skrzynki podczas tworzenia pocisku anuluje ten strzał.

Alternatywa to wyczytanie dowolnej skrzynki i pocisku z definicji moda.
Wymaga zasad dla obcych efektów, typów obrażeń i pocisków, które zależą od
konkretnej broni. Bezpieczniej zacząć od jawnych profili z testami i czytelnie
odrzucać nieobsługiwaną amunicję.

## Plecak

Ustawić 200 grup, po najwyżej 200 sztuk w grupie. Pozostawić natywne
przedmioty i strony oraz zgodność z zapisanymi magazynami. Uwzględnić zakres
liczników w protokole, odczyt grupy 200 i wyczerpanie identyfikatorów świata.
Dodawanie pojedynczego łupu powinno korzystać z liczników w indeksie, aby
duży magazyn nie wymuszał przeglądu całej zawartości przy każdym przedmiocie.

W filtrach dodać dwie niezależne flagi na typ przedmiotu. Czerwone wykluczenie
dotyczy podnoszenia, zielona ochrona dotyczy rozbiórki i usuwania. Flagi są
zapisywane z plecakiem. W podsumowaniu przechowywanych typów widać ochronę.
Rozbiórka pomija zielone elementy, w tym zagnieżdżone. Usunięcie zawierającego
je pojemnika musi zostać odrzucone albo zachować chronioną zawartość.
Alternatywa to oznaczanie pojedynczych egzemplarzy. Wymagałaby znaczników
wielu setek sztuk, innego widoku zbiorczego i dodatkowego uzgadniania grup.
Flaga rodzaju odpowiada istniejącej obsłudze czerwonego filtra.

Szara klasyfikacja katalogu prefabów będzie mogła być ręcznie zastąpiona
zezwoleniem na dany typ, na przykład odczepioną rudę. Należy rozróżnić
klasyfikację katalogu od bezpośrednich warunków silnika na egzemplarzu.
Plecak respektuje dostęp, stan połączeń, przytwierdzenie do skały i blokadę
inwentarza. Zweryfikować osobno rudę jeszcze przytwierdzoną i wydobytą.

W prywatnej grze odczepiony `chalcopyrite` miał `CanBePicked=true`,
`IsAttached=false` i `PickingTime` równe maksimum `Single`. Katalog
akceptował typ, a odrębny warunek przenośności go odrzucał. Ręczne zezwolenie
ma móc rozwiązać ten przypadek w filtrze, bez zasysania przytwierdzonego
złoża i bez obchodzenia natywnego transferu.

Dodać testy wymiany skrzynki przed strzałem, limitów grup i sztuk, nowych
oznaczeń po zapisie i synchronizacji, odmowy zniszczenia zielonych pozycji
oraz rzeczywistego wkładania odczepionego materiału. Przeprowadzić próbę w
prywatnych kopiach gry i zbudować osobną paczkę po weryfikacji.
