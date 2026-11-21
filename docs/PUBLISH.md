# Publikacja System Aegis

System Aegis jest pełnym, samodzielnym modem wyposażenia. W paczce znajdują się:

- klucz-śrubokręt Aegis (`aegiswrenchscrewdriver`);
- kompozytowy multitool Aegis (`aegiscompositetool`);
- bojowy multitool Aegis (`aegiscombattool`);
- komunikatory Aegis (`aegisheadset`, `aegisheadsetmk2`);
- odkurzacz i plecak Aegis (`aegisvacuum`, `aegisvacuumpack`);
- kombinezon serwomanipulacyjny Aegis (`aegisservosuit`).

Wymaganie: zgodne Lua for Barotrauma / LuaCs na kliencie i serwerze.
Wszystkie mechaniki, zasoby, receptury i skrypty dostarcza jeden pakiet.
Ukryte techniczne przedmioty to pociski, znaczniki trybów i wewnętrzne
strony magazynu, potrzebne do działania wyposażenia.

Przygotowanie paczki:

```powershell
python tools/run_tests.py
python tools/validate_content.py --game 'D:/SteamLibrary/steamapps/common/Barotrauma'
python tools/package_mod.py
```

Wypakuj `output/System-Aegis-1.3.27.zip` do `Barotrauma/LocalMods/`.
Folder `System-Aegis` zawiera `filelist.xml` z nazwą **System Aegis**.
Do publikacji użyj tego folderu i utwórz nowy wpis Workshop. Manifest
przed pierwszą publikacją nie zawiera `steamworkshopid`. Nowa publikacja
powinna otrzymać własny identyfikator; zachowaj go dla kolejnych aktualizacji.
Nie dołączaj `tests/`, `docs/`, `.runtime/` ani `.local-tools/`.

System Aegis używa nowych identyfikatorów narzędzi i kombinezonu.
Nie przenosi automatycznie wyposażenia ze starych zapisów. Wspólne nazwy
istniejących komunikatorów i odkurzacza oznaczają, że do zwykłej rozgrywki
należy włączyć tylko jedną wersję pakietu Aegis. Zachowaj kopię kampanii
przed przejściem na osobne wydanie.
