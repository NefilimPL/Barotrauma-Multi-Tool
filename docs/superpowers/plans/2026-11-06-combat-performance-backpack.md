# Combat performance and backpack implementation plan

> **For agentic workers:** Use superpowers:executing-plans task by task.

**Goal:** Measure impact rendering in game and deliver batch withdrawal, floor-only pickup, shop integration and manual insertion.
**Architecture:** Keep real storage pages. Add bounded server-authorized batch requests; extend the existing GUI. Restrict the merchant exception to Aegis storage and retain ordinary selling rules.
**Tech Stack:** LuaCs / Lua 5.2, Python unittest/Lupa, isolated Barotrauma GPU client.
**Spec:** ../specs/2026-11-06-combat-performance-backpack-design.md

## Global Constraints

- Work in the authorized checkout; no campaign changes, commits, pushes or publication.
- Preserve instance identity, nested contents, quality and condition; retain 100 groups of 100 items.
- Server authorizes all mutations. Reject foreign, locked and pending transaction inputs.
- Run baseline and final full suites; native client checks use only .runtime copies.

## Review Focus

- Stale or duplicate batch identifiers must not move foreign items or move an item twice.
- Full character inventory leaves remaining selections in the backpack.
- Floor-only mode never extracts a nested item or a loaded container.
- Dragging must not swap the worn backpack or bypass access restrictions.
- Merchant visibility must preserve outpost, broken-item, reservation and sold-item exclusions.

### Task 1: Client impact profile and performance correction

- [x] Run tests/runtime/combat_effects_profile.lua on the isolated GPU client; record event and draw costs.
- [x] Add a failing regression for the measured expensive path, implement the correction in CombatTool/visuals.lua, and compare the native profile.

### Task 2: Batch withdrawal and floor filter

- [x] Add behavioral regressions in test_vacuum_stack.py, test_vacuum_pickup.py, test_vacuum_network.py and test_vacuum_client.py; watch missing behavior fail.
- [x] Implement withdrawBatch(ctx, ids, groups) in storage.lua; normalize at most 100 IDs and serialize requests symmetrically in network.lua with protocol v5.
- [x] Persist looseOnly on pack tags in filters.lua, reject contained and loaded items in runtime.lua, expose the toggle and multiselection in client.lua.
- [x] Run python tools/run_tests.py and native client checks.

### Task 3: Manual insertion and merchant

- [x] Add regressions for ownership, locked/full/pending storage and selling eligibility.
- [x] Implement manual insertion in a dedicated module; intercept native drag release onto a valid backpack and submit an insert batch. Preserve the original item on failure.
- [x] Implement a merchant module that permits Aegis hidden storage while retaining other native exclusions. Install and dispose via existing lifecycle.
- [x] Run full tests and native inventory/shop checks.

### Task 4: Delivery verification

- [x] Review complete diff, resolve meaningful findings, validate content, update translations/docs/version and package.
- [x] Stop only this task's isolated processes and report measured results and limitations.

## Verification ledger

- Baseline: 414 tests passed. Final: 437 tests passed; 13 XML / 41 Lua modules validated.
- Task 1: native identical-scenario GPU comparison 21.21 → 0.394 ms per draw for 64 nearby impacts of one source; offscreen 22.24 → 0.064 ms.
- Tasks 2–3: 8/8 native client checks, including real character and container inventory overloads, native merchant sold history, full carry limits and first-page deferred insertion.
- Final review: one important issue, multiplayer sale could bypass server-owned transaction guards. Fixed with test_server_rejects_busy_reserved_and_foreign_backpack_sales_before_native_removal RED→GREEN and 4/4 native dedicated-server checks with NT 2.0.5.
- Native checks caught and resolved overloaded hook signatures, distinct index/i argument names, EnumerableWrapper conversion and the need for a real List<SoldItem> in rewritten hook parameters.
- Single-target destructive/actions disabled for multiselection; stale selection regression passes.
- No deferred review findings. No commits, merge, push or publication; source and local 1.3.11 ZIP remain reviewable in the authorized checkout.
- Full results and scope limits: docs/IMPACT-BACKPACK-VERIFICATION.md.
