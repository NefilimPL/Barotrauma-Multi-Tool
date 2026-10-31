# Regenerative Headsets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add two battery-powered headsets with pressure shielding, full regeneration, optional medical-mod adapters, and Mk II damage absorption.
**Architecture:** Independent `AegisHeadset` Lua namespace, native headset XML components, authoritative health/energy simulation and client-only effects. A public treatment registry handles future mods without hard dependencies.
**Tech Stack:** Barotrauma 1.13.5.0, LuaCs, Lua 5.2, XML, PNG, OGG, Python unittest/lupa.
**Spec:** `docs/superpowers/specs/2026-10-31-regenerative-headsets-design.md`

## Global Constraints

- Extend MULTI-TOOL-V2; existing multitool behavior must survive.
- Neurotrauma and every other medical mod remain optional.
- Native radio: range 35000, LinkToChat, unaffected by battery depletion.
- Server/single-player alone spends energy and changes health.
- Defaults: pressure 5%/s; healing budget 5 strength/s at 0.5%/strength;
  organs 15% over 5s; limbs 25% over 10s; hit max(1, damage*0.5)%.
- Bot swaps below 20%; low audio below 40%, critical below 15%.
- User authorized continuous execution; no further plan approval is needed.

## Review Focus

- Unknown harmful affliction identifiers must heal without an allowlist.
- Mod physiology, buffs and implants must not be erased by generic healing.
- Nested damage methods and the last battery fraction must not double-charge or grant immunity.
- Taking off a headset or reloading Lua must never leave pressure resistance behind.
- An unavailable battery must not interrupt a bot's work or trigger an endless swap.

### Task 1: Energy and generic treatment policy

**Files:** Create `Lua/AegisHeadset/config.lua`, `core.lua`, `treatments.lua` under MULTI-TOOL-V2; `tests/test_headset_core.py`.
**Interfaces:** `Core.debit(energy,cost) -> remaining,fraction`; `Core.absorb(energy,damage) -> remaining,residual`; `Treatments.classify(prefab) -> policy`; `Treatments.register(id,policy)`; `Treatments.plan(entries,budget) -> actions`.
- [x] Write behavioral tests for proportional debit/absorption, shared healing budget, unknown harmful effects, buffs and explicit normal-value overrides.
- [x] Run `python -m unittest discover -s tests -p test_headset_core.py`; expect missing feature failures.
- [x] Implement deterministic policy/core, no game globals or medical-mod imports.
- [x] Repeat tests; expect PASS.

### Task 2: Native runtime, optional anatomy adapters and bots

**Files:** Create `Lua/Autorun/aegisheadsets.lua`; `Lua/AegisHeadset/game.lua`, `medical.lua`, `ai.lua`; `tests/test_headset_adapter.py`; `tests/runtime/headset_integration.lua`.
**Interfaces:** `Game.new(E)` exposes `equipped(character)`, `energy(item)`, `spend(item,cost)`, `heal(character,item,dt)`, `update(dt)`, `dispose()`; medical adapter returns treatment entries and paid anatomy jobs.
- [x] Inspect matching native health/pressure APIs and optional NT API; record actual signatures in runtime comments.
- [x] Write and run adapter tests: no NT globals, equipped slot only, partial power, treatment preservation, paid regeneration and bot candidate ownership/access; expect FAIL.
- [x] Implement authoritative pressure and damage hooks before damage side effects, optional NT bridge, native battery fetch/container tasks and cleanup.
- [x] Repeat adapter tests; expect PASS. Add runtime probe for actual game APIs.

### Task 3: Items and audiovisual assets

**Files:** Create `regenerative_headsets.xml`, `headset_sounds.xml`, `Assets/Headsets/*`, `Lua/AegisHeadset/effects.lua`; modify manifest and Polish/English text. Create `tools/generate_headset_audio.py`, `docs/headsets/preview.html`, `PROMPTS.md` and `tests/test_headset_content.py`.
**Interfaces:** Effects install provides `emit(character,item,kind)`, `update(dt)`, `dispose()`; server events contain entity IDs, position, event kind and energy tier. Independent protocol `bmt.headsets.v1`.
- [x] Add and run content contracts for two slot-compatible native radios, battery-only containers, optional dependencies and packaged references; expect FAIL.
- [x] Generate original transparent headset sprites using built-in imagegen; render shield shimmer as code-native geometry; synthesize original three-tier impacts and power-off OGG.
- [x] Implement items, balanced recipes/prices, localization and bounded server-to-client effects.
- [x] Run content contracts and `python tools/validate_content.py --game D:/SteamLibrary/steamapps/common/Barotrauma`; expect PASS.

### Task 4: Verification, review, documentation and package

**Files:** Extend content validator to all new references; update README and `docs/HEADSET-VERIFICATION.md`; use existing `tools/package_mod.py`.
- [x] Run full `python tools/run_tests.py`, syntax/content/assets checks; expect all tests PASS.
- [x] Run available native runtime probes on isolated server/client; document specific successes and unavailable tests accurately.
- [x] Fresh reviewer checks complete change, especially Review Focus, optional dependencies and API signatures; fix important findings with regression tests.
- [x] Package mod; inspect ZIP for both devices and assets, exclude docs/tests. Leave reviewable working tree; no push/publish.
