# Kombinezony frakcji w Systemie Aegis 1.8.4

Każda z sześciu frakcji ma własny krój kombinezonu, hełm i osłony osprzętu.
Rozpoznasz zestawy po kształtach, materiale i widocznych oznaczeniach.
Warianty mają te same receptury, ochronę i funkcje.

[Porównaj kombinezony](faction-colors/preview.html) · [ZIP 1.8.4](../output/System-Aegis-1.8.4.zip)

| Frakcja | Motyw |
|---|---|
| Piraci | Czerwone płyty z nitami, mosiężny iluminator z kratą, zewnętrzne węże i czaszka z kluczami. |
| Descendens | Gładkie białe osłony, szeroka fasetowana szyba w kobalcie i turkusowe szewrony. |
| Koalicja | Granatowe płyty abordażowe z białymi pasami, bursztynowy wizjer i znak Koalicji z gry na pancerzu. |
| Separatyści | Pomarańczowe osłony przemysłowe, trzy okrągłe wizjery, uchwyty i żółto-czarne pasy. |
| Kościół Łuski | Fioletowy kaptur hełmu, żebrowane płyty w kolorze kości, wąski wizjer i zwijający się znak kultu. |
| Dzieci Honkomatki | Biała maska z czerwonym nosem i uśmiechem, hełm z dzwonkami, szachownica i paski na rękawach. |

Ramię i obudowa wirnika pokazują styl faktycznie zamontowanego modułu.
Możesz włożyć np. niebieskie serwo i fioletowy wirnik do białego kombinezonu.
Nowy wygląd wyświetli się także na egzemplarzach z wcześniejszego zapisu.

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

Każdy zestaw ma własny atlas animowanych części, zamknięty i otwarty hełm,
portret na stojaku, złożony kombinezon, obudowę wirnika oraz ikony serwa i wirnika.
Piracki zestaw jest w `Assets/AegisSuit/` i `Assets/AegisModules/`, pozostałe
w `Assets/Factions/`. [Założenia grafik 1.8.0](faction-colors/STYLE-1.8.0.md).

[Maska klauna i wyniki pomiaru szafek w 1.8.1](AEGIS-CABINET-PERFORMANCE.md).
