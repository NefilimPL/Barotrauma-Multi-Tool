# Combat Multitool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the approved two-handed energy-ring multitool with a powered shield and exclusive AI tool/combat modes.

**Architecture:** XML defines an ordinary-slot/two-hand item, native ranged/tool components and three checkboxes. Lua has a pure rules/geometry core, an authoritative game adapter, networking and a client renderer. The adapter patches only the new item and uses native AI objectives for movement and resupply.

**Tech Stack:** Barotrauma/LuaCs 1.13.5.0, Lua 5.2-compatible modules, XML, PNG; Python unittest + Lupa for rules and adapters; an isolated dedicated server for loading and runtime API checks.

**Spec:** `docs/superpowers/specs/2026-10-30-combat-multitool-design.md` (approved by user: "działaj").

## Global Constraints

- Preserve the existing multitool. Scope hooks to `combatmultitool`.
- Two hands equipped, one normal inventory slot stowed; two energy slots.
- Quality 0/1/2/3 permits 1/2/3/4 ricochets; no hull damage from rings.
- NPC damage permission is authoritative; bots never enable it automatically.
- Exactly one executable mode per item/use; shield can coexist with tool work when permission is enabled.
- The server owns damage, flight, shielding and resource spending. No external publication or installation changes.
- Execute inline in the existing `dev_weapon` checkout; user has authorized implementation, so no additional plan/worktree approval checkpoint.

## Review Focus

- Stale bot objectives during task changes must never allow a combat shot during welding: adapter test.
- Two identical batteries must not make an empty slot appear charged: core + adapter test.
- Fast shots, hitscan and submarine coordinates must obey the same shield geometry: geometry + runtime test.
- Untrusted/repeated client use messages must not create duplicate damage or shots: adapter test.
- Item owner changes, Lua reload and round transitions must not leave active shields/hooks: lifecycle test.

### Task 1: Rules, geometry and resource accounting

**Files:** `MULTI-TOOL-V2/Lua/CombatTool/{config,core}.lua`, `tests/test_combat_core.py`.
**Interfaces:** `Core.mode(context) -> string`; `Core.reflect(v,n) -> vector`; `Core.segmentArc(a,b,shield) -> t,point`; `Core.spend(source,cost) -> boolean`; `Core.bounces(quality) -> integer`.

- [ ] Write failing tests for mutually exclusive player/bot modes, hard damage disable, 1–4 bounce limits, reflection, nearest arc hits and one-slot spending.
- [ ] Run `python -m unittest discover -s tests -v` with local Lupa; expect failures because modules are missing.
- [ ] Implement pure modules with all tuning values in config; cover TTL, attenuated bounce damage and shield contact costs.
- [ ] Run the same command; expect all core tests to pass.

### Task 2: Native item and exclusive AI integration

**Files:** `MULTI-TOOL-V2/combat_tool.xml`, manifest/text files, `Lua/CombatTool/{game,ai}.lua`, `Lua/Autorun/combatmultitool.lua`, `tests/test_combat_adapter.py`.
**Interfaces:** `Game.state(item)`, `Game.context(item,character)`, `Game.use(component,character,dt)`; AI adapter uses the executing objective and its actual selected tool, not queued orders. Core interfaces from Task 1.

- [ ] Add adapter tests proving use gates, owner transition cancellation and independent resupply slots; watch them fail.
- [ ] Inspect actual runtime methods/fields and native item XML. Implement component use patches and slot-specific AI resupply with ordinary game objectives.
- [ ] Add a craftable item with two-hand Holdable, RangedWeapon, appropriate RepairTools, two visible slots, private mode tokens and the same three checkbox properties.
- [ ] Verify all XML parses, old identifiers remain and recipe identifiers exist in installed content. Expect adapter tests green.

### Task 3: Authoritative rings, shields and networking

**Files:** `Lua/CombatTool/{projectiles,shield,network}.lua`, extend adapter tests.
**Interfaces:** `Projectiles.fire(state,context)`, `Projectiles.update(dt)`; `Shield.update(state,context,dt)`, `Shield.intercept(projectile,start,end)`; `Network.emit(kind,data)` and bounded snapshot sync. Modules consume Core geometry and Game state.

- [ ] Write failing tests for ricochet budget/remaining travel, shield front/back interception, last-energy behavior, source separation and replay throttling.
- [ ] Implement swept movement using native physics fixtures and consistent world/submarine conversion, character-local damage and attenuated bounces.
- [ ] Patch physical projectile launch/travel and hitscan resolution before damage, resolving shield/wall nearest intersections. Add contact shock, cooldown and energy debit.
- [ ] Send validated authoritative snapshots/events to clients, include late join/reload cleanup and disable cancellation. Expect tests green.

### Task 4: Raster assets and animated rendering

**Files:** `Assets/Combat/*`, `Lua/CombatTool/visuals.lua`, item sprite references, asset prompt record.
**Interfaces:** `Visuals.receive(snapshot/event)`, `Visuals.draw(spriteBatch,cam)`; assets are project-local alpha PNGs with explicit frame rectangles.

- [ ] Use built-in imagegen for weapon and separate shield active/hit/break/contact animation sheets.
- [ ] Inspect actual outputs and alpha, copy final files into the mod and record prompts/dimensions. No project references outside the package.
- [ ] Render anchored shield frames, impact/break/shock events and rotating rings; add aimed flashlight and native tool effects.
- [ ] Validate frame rectangles, dimensions, alpha and paths; inspect a standalone preview.

### Task 5: Runtime loading, integration checks and delivery

**Files:** `tests/runtime/*`, `tools/*`, README, packaged ZIP under ignored `output/`, verification record.
**Interfaces:** isolated dedicated-server stdin/console + Lua runtime smoke script; `python -m unittest discover -s tests -v`.

- [ ] Copy a disposable server runtime inside ignored `.runtime/` and enable only the base package plus this mod; do not alter the installed game.
- [ ] Load the mod on actual LuaCs; exercise hooks, native component definitions and API contracts. Fix concrete runtime failures with regression tests.
- [ ] Exercise bots and shield/projectile interactions when available; record precisely which scenarios were run and which still require two-client visual verification.
- [ ] Run full suite, asset/content checks and `git diff --check`. Request one fresh whole-change code review; address important findings and retest.
- [ ] Document installation, mode priority, balance settings, exact runtime versions and verification limits. Build a ZIP of the actual mod folder; leave all changes reviewable on `dev_weapon`.

## Execution decisions

The user explicitly authorized implementing the approved design. Plan review and extra worktree consent are not new blockers: use the existing feature branch and implement inline. Skill shell helpers may be replaced by an equivalent PowerShell/Python ledger because this host has no Bash/SDK assumption. No push, merge or Workshop publication is authorized.
