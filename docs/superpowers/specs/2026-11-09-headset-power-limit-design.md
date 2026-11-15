# Ochrona baterii słuchawek przed spamem efektów

Cel: pełne ogniwo nie może znikać w kilka sekund wskutek powtarzanych
trafień, efektów modowych, leczenia lub regeneracji. Zabezpieczenie obejmuje
oba modele słuchawek i wszystkie ich ścieżki poboru energii.

Obecnie koszt Mk II sumuje siłę efektów ataku i ogłuszenie. Standardowe
wyładowanie cewki (80 electricshock, 8 stun, 10 burn) kosztuje około 19,6%
ogniwa. Koszt nie ma wspólnego ograniczenia czasowego.

Propozycja: wspólny dla fizycznego ogniwa budżet 5 punktów procentowych,
odnawiany w tempie 5 punktów/s czasu symulacji. Przez okres t sekund można
pobrać najwyżej 5 + 5*t punktów. Pełne ogniwo wystarcza więc co najmniej
19 sekund ciągłego maksymalnego obciążenia słuchawkami. Bezczynność nie
powiększa zapasu powyżej 5 punktów.

Po wykorzystaniu budżetu dodatkowe efekty nie zwiększają poboru. Przy
dodatnim naładowaniu działają dotychczasowe funkcje urządzenia. Puste ogniwo
nie daje ochrony ani leczenia; rzeczywiste wyczerpanie podczas opłacania
efektu nadal daje ochronę częściową. Limit zmniejsza cenę przeciążenia,
nie tempo leczenia. Nieudane lub nieskuteczne operacje nie zużywają budżetu.

Budżet należy do ogniwa, aby przeniesienie go między słuchawkami lub
zdjęcie i założenie urządzenia nie otwierało nowego limitu. Serwer rozlicza
energię; klienci nie naliczają drugiego kosztu. Zmiana nie obejmuje zużycia
tego ogniwa przez inne urządzenia ani obcych skryptów zmieniających je wprost.

Rozważone rozwiązania:

- Obniżenie ceny tesli lub wybranego efektu nie zabezpiecza innych modów.
- Ograniczenie ceny pojedynczego trafienia nadal pozwala opróżnić ogniwo
  wieloma trafieniami w jednej klatce.
- Wspólny budżet ogranicza łączny pobór niezależnie od rodzaju i liczby
  efektów. To proponowane rozwiązanie.

Weryfikacja: odtworzenie serii natywnych wyładowań przed zmianą; testy
spamu trafień i mieszanych kosztów, czasu odnawiania, pustej baterii,
przenoszenia ogniwa i nieudanych operacji; pełny zestaw testów projektu.

Status: zatwierdzone przez użytkownika 2026-11-09; wdrożenie według planu.
