# Kolory frakcji — System Aegis 1.5.2

Wersja bez komunikatorów zawiera sześć kosmetycznych zestawów kombinezonu,
ramienia serwo i wirnika. Wybierz wariant po nazwie frakcji w fabrykatorze
lub sklepie. Warianty mają takie same receptury, koszty, ochronę i funkcje.

[Podgląd wszystkich palet](faction-colors/preview.html) · [ZIP 1.5.2](../output/System-Aegis-No-Headsets-1.5.2.zip)

| Frakcja | Kolor | Emblemat i detale |
|---|---|---|
| Piraci | czerwony | czaszka ze skrzyżowanymi kluczami, spawy i łatane płyty |
| Descendens | biały | podwójny szewron z rombem, ceramiczne panele i precyzyjne podziały |
| Koalicja | niebieski | gwiazda nad kołem zębatym, wojskowe pasy i srebrne obrzeża |
| Separatyści | pomarańczowy | pięść w trójkącie, przemysłowe płyty i pasy ostrzegawcze |
| Kościół Łuski | fioletowy | symbol kultu, subtelne ceremonialne grawerunki i kość słoniowa |
| Dzieci Honkomatki | zielony z żółtymi akcentami | twarz błazna w rombie, drobna szachownica i żółte wstawki |

Kolor obejmuje pancerz, hełm, widok złożonego kombinezonu i stojaków,
ramię, obudowę napędu oraz ikony obu modułów. Srebrne przeguby i łopaty
pozostają metalowe; szkła i kontrolki zachowują turkusową barwę.

Na postaci ramię i wirnik korzystają z koloru faktycznie zamontowanego
modułu. Można np. włożyć niebieskie serwo i fioletowy wirnik do białego
kombinezonu. Wszystkie kolory modułów pasują do tych samych slotów.
Ikona złożonego kombinezonu i obraz na stojaku pokazują paletę jego pancerza;
zawartość slotów ma własne ikony modułów.

Dotychczasowe czerwone wyposażenie to paleta piratów i zachowuje stare
identyfikatory. Nie trzeba zastępować istniejących egzemplarzy czerwonego
kombinezonu ani modułów. Dla nowych kolorów utwórz lub wycraftuj odpowiedni wariant.

## Sprzedaż kombinezonów

Każdy kombinezon ma cenę bazową **10 000 marek** i zapas jednej sztuki
u przypisanego handlarza. Nie trafia do oferty pozostałych sklepów.

| Wariant | Sprzedawca |
|---|---|
| Piraci — czerwony | Zbrojmistrz (`merchantarmory`) |
| Descendens — biały | Sklep placówki naukowej (`merchantresearch`) |
| Koalicja — niebieski | Sklep placówki wojskowej Koalicji (`merchantmilitary`) |
| Separatyści — pomarańczowy | Sklep placówki wojskowej Separatystów (`merchantmilitary`) |
| Kościół Łuski — fioletowy | Handlarz Łuski (`merchanthusk`) |
| Dzieci Honkomatki — zielono-żółty | Handlarz Klaunów (`merchantclown`) |

Piraci i Descendens nie mają osobnych handlarzy w podstawowej grze; przypisano
im powyższe rodzaje sklepów. Niebieski i pomarańczowy wariant wymagają placówki
odpowiedniej frakcji; kultowe warianty uwzględniają również drugą frakcję placówki.
Wyłączono losowe oferty dnia. Reputacja, umiejętności i inne standardowe
modyfikatory kampanii nadal mogą zmieniać końcową cenę zakupu.
Receptury craftowania pozostają dostępne.

## Identyfikatory

| Frakcja | Kombinezon | Serwo | Wirnik |
|---|---|---|---|
| Piraci | `aegisservosuit` | `aegisservomodule` | `aegisimpellermodule` |
| Descendens | `aegisservosuitdescendens` | `aegisservomoduledescendens` | `aegisimpellermoduledescendens` |
| Koalicja | `aegisservosuitcoalition` | `aegisservomodulecoalition` | `aegisimpellermodulecoalition` |
| Separatyści | `aegisservosuitseparatists` | `aegisservomoduleseparatists` | `aegisimpellermoduleseparatists` |
| Kościół Łuski | `aegisservosuithusk` | `aegisservomodulehusk` | `aegisimpellermodulehusk` |
| Dzieci Honkomatki | `aegisservosuitclowns` | `aegisservomoduleclowns` | `aegisimpellermoduleclowns` |

Przykład zestawu Koalicji:

```text
spawnitem aegisservosuitcoalition inventory 1
spawnitem aegisservomodulecoalition inventory 1
spawnitem aegisimpellermodulecoalition inventory 1
spawnitem batterycell inventory 1
spawnitem pulselaserammobox inventory 1
```

[Instalacja, sloty i receptury](NO-HEADSETS.md). Włączaj tylko jeden wariant
pakietu Aegis naraz. Zasady tarczy i osobno craftowanych modułów są takie same
we wszystkich kolorach.

## Pliki graficzne

Paleta piratów korzysta z `Assets/AegisSuit/` i `Assets/AegisModules/`.
Pozostałe palety są w `System-Aegis-No-Headsets/Assets/Factions/`.
W wydaniu 1.5.1 wszystkie sześć frakcji otrzymało po siedem nowych tekstur:
atlas części, złożony kombinezon, widok stojaka, widok za szybą, obudowę wirnika
oraz ikony serwa i wirnika. Małe emblematy są naniesione na płyty pancerza
lub obudowy modułów, a wykończenie odpowiada danej frakcji.

Cztery symbole frakcji gry odtworzono na podstawie `Content/Map/factions.xml`
i `Content/UI/CampaignUIAtlas2.png` z zainstalowanej Barotraumy. Znaki piratów
i Descendens są autorskimi wzorami dla tego moda. Sześć osobnych, przezroczystych
[emblematów PNG](../System-Aegis-No-Headsets/Assets/Factions/emblems/) dołączono do paczki.

Wszystkie 42 tekstury oraz 6 emblematów wygenerowano wbudowanym generatorem
z referencji. Pliki wynikowe skopiowano bez skryptowego przemalowywania,
skalowania ani zmiany pikseli. Sprawdzono kanał alfa, granice klatek XML
i pokrycie części w atlasach animacji. Wszystkie 78 części mieści się w całości
w dopasowanych kadrach, również podczas zmiany widoku hełmu i mieszania modułów. Kadry stojaków używają całej tekstury,
aby zachować widoczne nogi i buty również przy innych proporcjach PNG.
[Dokładne prompty i sumy SHA256 dla 1.5.1](faction-colors/PROMPTS-1.5.1.md).
[Historia generowania palet 1.5.0](faction-colors/PROMPTS.md).

781 automatycznych testów przeszły. Testy sprawdzają rozpoznawanie wszystkich wariantów, zgodność
modułów, dobór kolorów na postaci, zwalnianie pamięci tekstur, zgodność receptur
i parametry przedmiotów. Walidacja obejmuje XML, Lua, grafiki oraz receptury
z zainstalowanej gry. Test rozgrywki w silniku dla tego wydania pozostaje do wykonania.
