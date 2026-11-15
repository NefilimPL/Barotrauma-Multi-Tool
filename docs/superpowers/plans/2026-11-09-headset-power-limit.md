# Headset Power Limit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent repeated effects from emptying a headset battery in seconds.

**Architecture:** A shared token budget belongs to each physical battery. All
headset debits use it; unsuccessful operations refund their reservations.
Existing treatment speeds and shield behavior remain, with discounted overload
costs and no benefits from empty cells.

**Tech Stack:** Lua 5.2, Python unittest/lupa, isolated LuaCs dedicated server.

**Spec:** `docs/superpowers/specs/2026-11-09-headset-power-limit-design.md`

## Global Constraints

- Capacity 5 percentage points; refill 5 points/s of simulation time.
- Shared across every headset debit and follows the physical battery.
- Authority stays on the server; no external dependencies.
- No changes to other devices or scripts directly setting cell condition.

## Review Focus

- Failed native damage fallback must refund both charge and budget.
- No-op or failed healing must not consume a reservation or fire OnBroken.
- Transferring batteries and re-equipping must not restart the budget.
- Idle time must not accumulate an unbounded burst allowance.
- Pressure, healing, anatomy and hits must share one budget, including nested callbacks.

### Task 1: Shared debit budget and integration

**Files:** new `MULTI-TOOL-V2/Lua/AegisHeadset/power.lua`, modify
`AegisHeadset/config.lua`, `AegisHeadset/game.lua`, new
`tests/test_headset_power_limit.py`, update related existing tests/docs.

**Interfaces:** `Power.new()` creates a per-source ledger;
`ledger.reserve(cell, now, energy, cost)` returns a payment with remaining energy,
coverage fraction and reserved charge; `ledger.finish(payment, used)` commits
actual charge and releases unused allowance. The adapter owns native writes.

- [x] Add regression tests: 1000 one-frame hits leave at least 95%; mixed
  effects over 5 s leave at least 70%; healing/pressure/anatomy share the cap;
  empty batteries give no benefit; re-equipping, cell transfers, refunds,
  native failure, idle refill and nested treatment callbacks respect the cap.
- [x] Run `python -m unittest discover -s tests -p test_headset_power_limit.py -v`
  and confirm failures reproduce missing rate limiting.
- [x] Implement reservations in `power.lua` and route each debit through them.
  Keep `setEnergy` as an unmetered setter for actual refunds and diagnostics.
- [x] Update intentional old expectations for large isolated hits, separating
  independent battery resets in tests by simulation time.
- [x] Run `python tools/run_tests.py`, `python tools/validate_content.py`,
  and repeat the native power-spam probe on the isolated server.
- [x] Update docs with exact bound, native before/after results and limitations;
  review the final diff before reporting completion.

## Execution record

- Design approved by user; executing inline in the shared checkout.
- Baseline: 438 tests pass. Native probe: six coil hits empty the cell;
  1000 one-frame burn, stun or internaldamage calls each empty it as well.
- Shared ledger regression: 14 new tests, 11 reproduced original defects;
  all 452 tests green after implementation and realistic simulation clocks.
- Final review: independent reviewer; no important findings remain.
- Final: fixed discounted healing slowing with a small positive remainder —
  `test_discounted_healing_keeps_normal_speed_with_a_small_positive_remainder`
  RED→GREEN, suite 453/453.
- Final: minor (deferred): when the cell actually empties, equal-priority
  wounds may receive the last treatment sequentially instead of evenly;
  total healing and priority remain correct.
- Final verification: 453 tests pass; content and recipes valid; native
  final probe leaves 95% after each one-frame spam case and 69.9992%
  after 5.0167 s / 301 frames; small-remainder healing passes; 9 native
  integration cases pass. Isolated test server stopped. ZIP 1.3.13 built
  and checked byte-for-byte against all production files.
