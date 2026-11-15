# Czytelniejsze trafienia Aegisem

Status: propozycja do zatwierdzenia, bez zmian w kodzie produktu.

## Cel

Trafienie przeciwnika bojowym multitoolem ma być wyraźnie widoczne, słyszalne i powodować krótką reakcję ciała. Użytkownik wybrał wzmocnienie wszystkich trzech elementów.

## Obecne zachowanie i porównanie

- Aegis: jeden pocisk, 18 burn + 12 blunttrauma, impuls 8.625, bezpośrednie ogłuszenie 0. Efekt hit używa tej samej animacji shield-hit co trafienia ścian; pierwsza faza błysku trwa 0.09 s. Dźwięk bodyhit ma volume 0.85, wystrzał 1.0.
- Lokalna definicja gry: zwykły nabój strzelby ma 8 śrucin, każda ze stun 0.1; nabój SMG ma stun 0.2 z prawdopodobieństwem 0.1. Natywne pociski mają również efekt impactfirearm i obrażenia postrzałowe z krwawieniem.
- To różnice potwierdzone w kodzie; nie ustalono jeszcze, czy na kliencie użytkownika występuje dodatkowy błąd renderowania lub odtwarzania dźwięku.

## Podejście

Proponowane: rozbudować istniejący efekt hit i natywną ścieżkę AddDamage. Pozwala zachować synchronizację, obsługę ochrony sojuszników i obecne limity efektów. Dodawanie krwawienia lub ran postrzałowych zmieniłoby charakter i obrażenia broni poza zgłoszonym zakresem. Wprowadzanie osobnej symulacji ragdolla byłoby zbędne, ponieważ AddDamage już przekazuje impuls do trafionej kończyny i głównej części ciała.

## Proponowane parametry

- Tylko trafienie postaci: impuls 12 zamiast 8.625 oraz stun 0.12. Ogłuszenie jako affliction w tej samej liście co obrażenia, za natywną ochroną friendly fire, analogicznie do istniejącego G.shock. Brak osobnego bezwarunkowego SetStun.
- Zachować osłabienie impulsu po rykoszetach. Ogłuszenie również osłabiać tym samym mnożnikiem.
- Osobne parametry wizualne dla hit: animacja o skali 0.35 zamiast 0.26, jasny rdzeń widoczny przez 0.12 s, iskry do 0.4 s. Zachować 12 smug i istniejące limity liczby efektów. Wartości początkowe do oceny w grze.
- Dźwięk bodyhit: volume 1.0 i range 1000, wyraźniejszy początkowy trzask z niskim uderzeniem. Zachować obecny dźwięk wystrzału. Nie regenerować pozostałych plików audio.
- Zachować bazowe burn 18 i blunttrauma 12 oraz obecny łuk elektryczny. Nie zmieniać efektów trafienia tarczy i ścian ani kontaktu z tarczą.

## Weryfikacja

Sprawdzić przekazanie obrażeń, impulsu i stun, osłabienie po rykoszecie, ochronę sojuszników oraz rozdzielenie efektu hit od shieldhit i wallhit. Uruchomić odpowiednie istniejące testy walki. Następnie porównać Aegisa, SMG i strzelbę na rzeczywistym kliencie w izolowanej kopii gry, w tym efekt na ruchomym celu i synchronizację reakcji ciała. Oceny widoczności i odczucia nie wywodzić z samych testów jednostkowych. Jeśli klient nie będzie dostępny, jawnie zgłosić brak takiej weryfikacji.
