# Faction suit sales and insertable modules

User request: retain real insertable servo/impeller/shield modules; each suit costs
10,000 marks and is sold only by its assigned vendor. Work in No Headsets variant.

1. Verify existing native item slots and runtime gates; preserve basic suit/tool
   use without special modules, disabled arm/propulsion/shield without them.
2. Add sales regression coverage, then assign six Price blocks. Default sales are
   disabled, only one explicit vendor enabled, one suit stocked, base price10000,
   multiplier1, daily specials disabled. Coalition and Separatists use military
   stores in their own faction locations; Husk and Clowns their cult merchants.
   Builder choice: pirate outfit at armory, Descendens at research; neither has a
   dedicated native faction trader. Preserve normal campaign price adjustments.
3. Update guide/preview/release notes to1.5.2; run full tests, native content
   validation, package, and verify archive byte equality and original package hashes.

Native reference: ItemPrefab.GetPriceInfo / CanBeBoughtFrom and PriceInfo.CreatePriceInfos.
https://github.com/FakeFishGames/Barotrauma/blob/master/Barotrauma/BarotraumaShared/SharedSource/Items/ItemPrefab.cs
https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-server/html/_price_info_8cs_source.html

Review focus: no sale fallback to unrelated merchants, faction-gated blue/orange
stock, cult stores with secondary factions, no free modules on spawn, unchanged
module condition/slot gating and recipes. Existing modular tests cover gates.

Completed: 781 tests and native validation (18 XML,55 Lua 5.2) passed.
Independent review: no findings; 18 faction and52 modular tests passed.
ZIP byte equality and CRC checked for159 files. Only six suit Price blocks
and manifest version changed inside the mod since1.5.1. Full original package
retains all131 baseline file hashes. No live game shop trial was performed.
SHA256: 8e6281276490d8be783b9da3a944754d54983e6b9a42a08ecfa53416081b9d62
