# Modular System Aegis without headsets

> **For agentic workers:** Use superpowers:executing-plans for implementation, and a fresh review at completion.

**Goal:** A separate complete System-Aegis-No-Headsets folder and installable ZIP containing vacuum/backpack, suit and multitools, with craftable shield/servo/impeller modules and original textures.
**Spec:** User request in Polish, 2026-11-21: remove headsets in this variant; weapon gains a craftable shield slot with five blocked hits, no contact damage, 15 seconds per restored charge; suit gains separate servo and impeller slots; supply crafting textures.
**Architecture:** Keep System-Aegis unchanged. Copy a standalone variant. Shield charge is persisted in the installed module condition: 20% per blocked projectile and 20% regenerated over 15 powered seconds, so two charges take 30 seconds. Recharge only while installed in an intact powered weapon; no regeneration while paused, unequipped module or no power. Native condition replication plus server-authoritative interception. Suit modules use fixed slots 2/3 after power/ammo; missing servo stops every arm action, drops held targets and cancels pending shots; missing impeller stops propulsion. Life support/lights/sonar retain their current behavior.
**Tech stack:** Barotrauma XML, Lua 5.2, Python unittest/lupa/Pillow validation, built-in image generation.

- [x] Add failing behavioral tests for charge limits/recharge/removal/no contact damage and suit module gating.
- [x] Create variant, remove headset content/scripts/assets/localization, add runtime module gating and network state.
- [x] Generate and install three transparent inventory textures; add separately fabricated module definitions, slot filters, icons and translated instructions.
- [x] Extend existing validation/packaging CLI to accept --mod, document recipes/installation/spawn commands.
- [x] Run full baseline+variant suite, recipe/asset/Lua validation, archive checks, independent review; verify original package hashes unchanged.

## Review focus

No charge or battery debit for missed/friendly/rear/occluded hits; sixth shot passes, recharge survives removing/reinserting or saving module. No client can authoritatively restore charges. Suit asynchronous callbacks recheck the actual module before acting; removal releases grip and stops native repair. Fixed slots cannot accept a module in a power/ammo slot. No headset content in variant; native inventory equipment names must stay intact. Never enable original and variant together because item identifiers overlap.


## Completion evidence

- Original System-Aegis: all 131 files match pre-task SHA-256 records.
- Red: 19 dedicated variant test failures before the variant existed; network-budget and module-snapshot tests also failed before those fields were implemented.
- Green: 763 complete suite tests passed (711 original + 52 variant).
- Validator: 17 variant XML, 54 Lua 5.2 modules, all referenced assets/frame rectangles/transparent module PNGs and recipe identifiers checked against installed game content.
- Independent mechanics review found no Critical/Important/Minor issues. Reviewer confirmed native condition save/replication/authority and SubContainer slot layout against local native source.
- Three image assets generated with the built-in tool; exact prompts saved in docs/modular-assets/PROMPTS.md. Each original PNG has transparent RGBA and dimensions1254x1254, copied without modification.
- Variant ZIP compared byte-for-byte to every source file, CRC checked, manifest coverage checked, headset assets/loaders excluded, SHA-256 saved beside archive.
- In-game smoke test has not been run; actual inventory presentation and multiplayer timing remain to be checked in the engine. No gameplay performance measurements are claimed for this variant.
