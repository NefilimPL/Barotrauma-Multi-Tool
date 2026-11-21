# Aegis ammunition and backpack implementation plan

> **For agentic workers:** Use superpowers:executing-plans and regression tests for each independent change.

**Goal:** Recover arm rendering after a temporary failure, fire reduced projectiles matching the loaded box, and offer a 200 by 200 backpack with destructive-operation protection and pickup overrides.

**Architecture:** Known ammo boxes select miniature native projectile prefabs. Index counts bound storage insertion cost, while existing saved pack tags hold user filters. The authoritative server validates every network request and asynchronous action.

**Tech Stack:** Barotrauma, LuaCs, XML, Python/Lua 5.2 tests.

**Spec:** `docs/superpowers/specs/2026-11-21-aegis-ammo-vacuum-design.md`, accepted by user directing work to continue.

- [x] Reproduce and fix the shared render latch in `AegisSuit/client.lua`. Verify `test_aegis_render.py` and a real client recovering from a single injected draw failure.
- [x] Add `AegisSuit/ammo.lua` with lookup, scaled cost and remaining-shot calculations. Use it in `game.lua`, `pulse.lua`, `supplies.lua` and `ui.lua`. Test wrong box, changed magazine during spawn, and triple shot count. Extend ammo slot and native miniature projectile definitions in `aegis_suit.xml`.
- [x] Update `AegisVacuum/config.lua`, `storage.lua`, `network.lua` and `aegis_vacuum.xml` to allow 200 groups of 200 items. Maintain root index counts on native add/remove and use native page capacities. Test the 40,000 boundary, group index 200, old saves, and inventory mutations.
- [x] Extend `filters.lua`, `network.lua`, `client.lua`, `runtime.lua`, `trash.lua` and `salvage.lua` with saved independent protection and manual allow flags. Test nested protection, authorization, filter precedence, and detached ore with the native sentinel picking time. Display green protection in storage and catalog.
- [x] Verify full suite, content and archive. Exercise both ammo families and detached ore in a private game along with panel and larger storage. Document actual numeric limits and verify the native schema and save compatibility.
