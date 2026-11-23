# System Aegis 1.6.1

Naprawiono błąd `AegisHUD/client.lua:112: attempt to concatenate a userdata value`.
Natywne pole tekstowe gry zwraca obiekt `LocalizedString`. Panel składa teraz cały
napis lokalnie i przypisuje go dopiero na końcu. Ustawienia bojowego multitoola
oraz kombinezonu wyświetlają się razem. Podobną konwersję dodano w podpowiedzi
chronionego przedmiotu w plecaku.

Światła kombinezonu zachowują dodatni zasięg również po wyłączeniu; o emisji
decyduje `Enabled`. Gra kolejkuje obliczenia cieni w tle z referencją do światła,
a zasięg odczytuje dopiero podczas wykonania zadania. Wcześniejsze zerowanie go
przy wyłączaniu mogło wytworzyć pustą geometrię, odczytaną po ponownym włączeniu.
Usunięto tę ścieżkę prowadzącą do wyjątku w `CalculateLightVertices`.

Sprawdzono w osobnej kopii klienta 1.13.5.0, rewizja c6e8829, z LuaCs:

- Oryginalny błąd panelu odtworzony przed poprawką; oba panele widoczne po poprawce.
- Zmiana czterech trybów, zwijanie/rozwijanie, sam kombinezon i multitool w jednej ręce.
- 40 przełączeń zasilania świateł bez awarii.
- Natywny test geometrii: zadanie z zasięgiem 0 daje pustą listę wierzchołków
  i zgłoszony typ wyjątku; zasięgi 120 i 650 tworzą poprawną geometrię.
- 858 testów automatycznych i walidacja zawartości moda.

Test obejmował Aegis z podstawową zawartością gry. Nie odtworzono całej paczki
modów ani konkretnej awarii na okręcie Triangle of Destiny z raportu użytkownika.

[Pobierz ZIP 1.6.1](../output/System-Aegis-1.6.1.zip).
Podmień poprzedni folder tego moda, a następnie uruchom grę ponownie.
