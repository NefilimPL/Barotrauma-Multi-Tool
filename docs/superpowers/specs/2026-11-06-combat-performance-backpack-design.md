# Trafienia i wygodniejszy plecak

Użytkownik zatwierdził wielokrotny wybór z jednym wyjęciem zaznaczonych,
sprzedaż zawartości w „Przy sobie” i zapamiętywany tryb „Tylko luzem”.
Dodał ręczne wkładanie przez przeciągnięcie przedmiotu na plecak.

Zachowujemy LuaCs, prawdziwe przedmioty na ukrytych stronach oraz natywne
ograniczenia slotów, jakości i stanu. Wyjęcie grupy obejmuje jej sztuki,
wybór w szczegółach obejmuje konkretne egzemplarze. Brak miejsca zostawia
resztę w plecaku. Zmiana widoku czy plecaka czyści zaznaczenie.
Tryb „Tylko luzem” pomija rzeczy z ParentInventory i pojemniki z zawartością,
aby nie opróżniać także toreb leżących na podłodze. Ręczne wkładanie ignoruje
filtr zasysania, ale zachowuje dostęp, pojemność i blokady transakcyjne.

Podejścia: samo pole ilości nie obsługuje różnych rodzajów naraz; zmiana
stron na zwykły ekwipunek odsłania techniczne przedmioty. Wybrano rozszerzenie
obecnego panelu i żądania serwerowe z ograniczoną listą identyfikatorów.
Sklep zachowuje natywne warunki sprzedaży i sprzedaje te same egzemplarze.

Spadki FPS wymagają pomiaru na prawdziwym kliencie GPU. Rozdzielamy koszt
odbioru zdarzenia, dźwięku i rysowania. Test pojedynczego klienta nie stanowi
potwierdzenia wydajności na komputerach znajomych ani sesji z opóźnieniami.
Nie zmieniamy kampanii użytkownika, nie publikujemy i nie wypychamy zmian.
