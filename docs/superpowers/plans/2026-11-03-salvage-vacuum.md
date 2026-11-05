# Salvage Vacuum Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add separately craftable backpack and powered two-handed vacuum, 100-item display groups, mass salvage and original graphics.

**Architecture:** LuaCs server owns native item transfers, battery debit and salvage. Native inventories preserve complete item state and save normally; a custom client panel groups their contents into stacks of 100 without changing the six-bit vanilla stack protocol. The vacuum owns the battery; the backpack owns storage.

**Tech Stack:** Barotrauma 1.13.5.0, LuaCs, Lua 5.2, XML, PNG, Python/lupa tests.

**Spec:** docs/superpowers/specs/2026-11-03-salvage-vacuum-design.md

## Global Constraints

- Extend MULTI-TOOL-V2, preserve existing tools and headsets.
- Battery in `aegisvacuum`; storage in `aegisvacuumpack`; separate fabricator recipes.
- Vacuum occupies both hands. Portable loot includes entire loaded crates and suits on dead bodies.
- No recipe means no salvage; no replacement iron. Preserve skipped container contents.
- 100 visible groups of up to 100 actual items; native stacks never exceed 63; network inventory slot ranges never exceed 255.
- Server authorizes every operation; clients render and request. No writes to Steam installation or unrelated mods.

## Review Focus

- Forged network requests must not move another player's items or operate an unequipped vacuum.
- Destruction of a crate must preserve unsalvageable nested content.
- Battery depletion and save/reload during salvage must not duplicate or lose items.
- Different condition, quality and nested contents must survive group withdrawal and campaign save.
- Inventory network limits and large loot scans must remain bounded.

### Task 1: Storage and salvage policy

**Files:** `Lua/SalvageVacuum/config.lua`, `core.lua`, `tests/test_vacuum_core.py`.
**Interfaces:** `Core.groups(items)`, `Core.canAccept(items,item)`, `Core.inCone(origin,direction,target)`, `Core.snapshot(items,children)`, `Core.debit(energy,cost)`; plain Lua data, actual items retained as references.

- [x] Write tests for 100/101 grouping, 100-group capacity, heterogeneous state, nested postorder, cycles, power and geometry.
- [x] Run `python -m unittest discover -s tests -p test_vacuum_core.py -v`; observe missing module failure.
- [x] Implement policy and rerun; expect all policy tests pass.

### Task 2: Native adapter and server simulation

**Files:** `Lua/SalvageVacuum/game.lua`, `storage.lua`, `salvage.lua`, `runtime.lua`, `Lua/Autorun/aegisvacuum.lua`, `tests/test_vacuum_adapter.py`.
**Interfaces:** `G.context(vacuum,character)`, `G.contents(pack)`, `G.insert(pack,item,user)`, `G.startSalvage(ctx)`, `G.withdraw(ctx,itemId)`, `G.update(dt)`.

- [x] Inspect installed API for inventory serialization, deconstruction, access and native spawner callbacks.
- [x] Write adapter tests for vacuum-owned battery, both required parts, nested preservation, power interruption and request ownership; run red.
- [x] Implement inventory pages with native save ownership, bounded scans, authoritative pickup and salvage with reserved output space. Leave unsupported recipes intact.
- [x] Run adapter and core tests; expect all pass. Runtime probes verify native inventory/save and salvage APIs.

### Task 3: Original images and item definitions

**Files:** `Assets/Vacuum/*.png`, `vacuum.xml`, package manifest and PL/EN text; `docs/vacuum/PROMPTS.md`; `tests/test_vacuum_content.py`.
**Interfaces:** Item IDs `aegisvacuum`, `aegisvacuumpack`, internal storage page ID if required; vacuum battery slot 0.

- [x] Generate distinct backpack, vacuum and suction effects with image_gen; inspect alpha and sprite dimensions.
- [x] Write content checks for separate recipes, battery location, two-handed holdable and valid references; run red.
- [x] Add definitions, recipes, prices, translations and package references; run checks green.

### Task 4: Network, panel and animation

**Files:** `Lua/SalvageVacuum/network.lua`, `client.lua`, `visuals.lua`, `tests/test_vacuum_network.py`.
**Interfaces:** Server handles bounded `open`, `withdraw`, `salvage`, `select` requests only from actual owning client; native character inputs control suction.

- [x] Write tests for forged ownership, distant targets, stale item IDs, duplicate salvage requests and result paging; run red.
- [x] Implement searchable paged groups, individual withdrawal, active pack selection and one-click salvage. Native storage/battery remain usable without custom UI.
- [x] Draw backpack attached to torso, hose and suction motion anchored to the nozzle; synchronize confirmed transfers and activity.
- [x] Run network tests green and client/runtime loading probes.

### Task 5: Integration and delivery

**Files:** `tests/runtime/vacuum_integration.lua`, `docs/VACUUM.md`, `docs/VACUUM-VERIFICATION.md`, `docs/vacuum/preview.html`, README and spawn commands.

- [x] Exercise pickup, bodies/suits/crates, 100+ groups, salvage and interruption in isolated runtime where available.
- [x] Run `python tools/run_tests.py` and `python tools/validate_content.py --game D:/SteamLibrary/steamapps/common/Barotrauma`.
- [x] Request one independent whole-change review; resolve important findings with reproductions and tests.
- [x] Package with `python tools/package_mod.py`, document exact tested limits and provide artifact paths.
