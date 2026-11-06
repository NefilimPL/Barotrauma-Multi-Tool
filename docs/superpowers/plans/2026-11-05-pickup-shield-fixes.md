# Vacuum pickup, category menu and projectile interception

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans task-by-task. Steps use checkbox syntax.

**Goal:** Fix the reported inaccessible category list, missed ground loot, mixed filtered containers, connected wires and frontal bullet leaks.

**Architecture:** Preserve server authority, item identity and bounded active-only scans. Fix the native GUI order and LuaCs array representation at their boundaries; retain whole containers when all descendants qualify, otherwise extract eligible contents. Diagnose projectile leaks against native collision timing before changing interception.

**Tech Stack:** Lua 5.2 / LuaCs, Barotrauma 1.13.5.0, Python unittest/Lupa, isolated native client.

**Spec:** User bug report and screenshot in this conversation; frontal leaks affect multiple firearms.

## Global Constraints

- Do not touch the user's campaign or running Steam installation.
- Keep scan/refresh budgets and no idle world enumeration.
- Never collect connected wires, locked inventories or another living character's equipment.
- Excluded children stay in the original container; eligible children keep their identities.
- Continue local work in the current authorized checkout; no commit, push or publication.

## Review Focus

- LuaCs converts Connection[] into a sparse one-based Lua table; test either lone end.
- Dropdown must remain above tiles for drawing and mouse selection, including after snapshots.
- A filtered ancestor must not bypass a locked inventory or an own active device.
- Distant installed items must not force seconds of candidate cycling for nearby loose loot.
- Physical impacts and hitscans must preserve earlier obstacles, friendly fire and shield energy rules.

### Task 1: Category overlay

**Files:** `Lua/SalvageVacuum/client.lua` under the production mod; `tests/test_vacuum_client.py`; native GUI probe.
**Interface:** `G.updateClient()` queues the open dropdown above panel order 10. `G.closePanel()` closes and releases it.

- [x] Reproduce the native list order 1 under panel order 10; add a regression for overlay order and close lifecycle.
- [x] Queue `category.ListBox` with order 11 only when dropped, after queuing panel; verify selection after reused snapshots in the actual client.

### Task 2: Safe, responsive loot selection

**Files:** `Lua/SalvageVacuum/runtime.lua`; `tests/test_vacuum_pickup.py`; active scan regressions; native pickup probe.
**Interfaces:** `G.portable(item) -> boolean`; `G.pickupTarget(item,ctx) -> item|nil`; bounded candidate refresh.

- [x] Add failing tests for a wire connected only at sparse index 2, a filtered bag with allowed and excluded children, locks above a fallback child, and nearby ground loot after thousands of distant entries.
- [x] Audit every non-null wire connection including one-based sparse tables. Choose the highest safe, accepted ancestor, falling back to the allowed child. Prioritize nearby loot during bounded refresh without idle scans.
- [x] Verify native wires at either end, a real duffel bag and live suction; run all pickup/filter/idle/frame regressions.

### Task 3: Frontal projectile leaks and release

**Files:** `Lua/CombatTool/shield.lua` and geometry only as evidence requires; shield regression tests and native probe; README/VACUUM/verification docs; manifest.
**Interfaces:** native Projectile launch/collision/hitscan hooks continue to debit energy once and suppress damage only after the shield contact.

- [x] Reproduce frontal physical and hitscan shots with real projectile types; trace native queued impacts and shield segment endpoints.
- [x] Add a failing regression for each confirmed cause, implement the minimal correction, and retest protection plus earlier obstacles/characters.
- [x] Independent whole-change review; `python tools/run_tests.py`, `python tools/validate_content.py --game 'D:/SteamLibrary/steamapps/common/Barotrauma'`, `git diff --check`.
- [x] Document measured scope and limitations, bump to 1.3.8, package and verify ZIP contents against production source. Stop only test processes started by this task.
