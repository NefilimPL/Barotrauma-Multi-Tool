# Mod performance implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Attribute client/server costs to each of eight items, optimize measured hot paths while retaining behavior, and organize reproducible evidence.

**Architecture:** Isolated native server and two clients run repeatable item scenarios. Test-only probes measure frame/tick time and activity, with run-scoped raw artifacts. Small production changes follow causal measurements; deterministic tests cover their safety boundaries.

**Tech Stack:** Lua 5.2/LuaCs, Barotrauma 1.13.5.0, Python unittest/lupa, .NET startup hooks.

**Spec:** `docs/superpowers/specs/2026-11-18-mod-performance-design.md` (approved 2026-11-18).

## Global constraints

- Preserve item identifiers, asset/Autorun paths, balance, capacities, ranges and resource costs.
- Test only private `.runtime/` installations and disposable saves; no Steam-install changes.
- Report two actual clients separately from additional bot wearers.
- Measure unchanged 1.3.22 first; retain historical evidence without overwriting it.
- Require actual activity for active phases; low UPS is a result, not an invalidation.
- Raw new runs belong in `output/performance/<run-id>/`; probes never enter the production package.

## Review focus

- Changed ownership/removal and new rounds must invalidate cached references.
- Moving submarines and fast owner/target turns must not reuse obsolete geometry.
- New last-moment obstacles must block async shots even with cached plans.
- A full backpack must retain item contents and reservations through concurrent operations.
- An inactive/no-item scene must include globally patched native paths and native update costs.

## Task 1: Reproducible measurement harness

**Files:** create `tools/performance/README.md`, `tools/performance/run_native.py`,
`tools/performance/analyze.py`, `tests/runtime/performance/NativeProbe.cs`,
`tests/runtime/performance/server.lua`, `tests/runtime/performance/client.lua`,
`tests/test_performance_tools.py`.

**Interfaces:** runner accepts `--label`, `--phase-seconds`, `--repeats`, `--filter`;
`output/performance/<run-id>/manifest.json` identifies code, environment and scenarios;
native role JSONL plus server activity JSONL feed `analyze.collect(run_dir)`.

- [x] Test analysis with known frame/tick samples, incomplete phases, idle/active evidence and slow UPS. Run tests RED.
- [x] Implement run-scoped analysis with p50/p95/p99/max, phase matching and activity validity; run tests GREEN.
- [x] Implement probes and isolated orchestration with exact production hashes, process ownership, readiness/timeouts and cleanup.
- [x] Smoke test an idle phase and an actually working item with two native clients. Verify full-server ticks separately from Lua controller timings.

## Task 2: Complete the unchanged baseline

**Files:** `tests/runtime/performance/server.lua`, `client.lua`, harness manifest;
run evidence in `output/performance/`.

**Interfaces:** scenario IDs identify item, mode, wearer count, density and repetition;
each scenario has an explicit measurable activity predicate.

- [ ] Cover all eight user items plus their seven hidden helpers, individually and in required combinations.
- [ ] Run 1/2/8 instances, idle and active paths, camera on/off screen, dense world, large storage and round lifecycle cases as specified.
- [x] Repeat valid representative baseline phases at least three times; retain invalid phases and their reasons.
- [ ] Rank measured module costs and record the exact causal operation counts before editing production code.

## Task 3: Arm targeting and movement

**Files:** modify `MULTI-TOOL-V2/Lua/DescendantSuit/game.lua`, `motion.lua`, `aim.lua`
and introduce a focused helper only if measurements justify one;
tests `tests/test_descendant_performance.py`, existing motion/aim/suit tests.

**Interfaces:** existing `G.gather(owner,state)`, `G.advanceTool(owner,state,dt)`,
`G.planShot(owner,state,target)`, `G.toolPose(owner,state,draw,point)` remain compatible.

- [x] Reproduce measured redundant scans/pose computations in call-count tests; observe RED.
- [x] Optimize acquisition and candidate filtering; retain native access/faction/visibility and target priorities.
- [x] Reuse per-step geometry where inputs match; avoid idle repeated IK, retaining smooth per-frame joint stepping and immediate invalidation.
- [x] Verify last-moment wall/ally, ownership/round changes, moving mount/target, opposite bends and no automatic bot grabbing; run targeted suite GREEN.
- [x] Repeat affected native workloads against baseline. Dense repair and combat show lower controller costs; visible repair mainly improves rendering in the ordinary scene.

## Task 4: Client and other server costs

**Files:** measured modules under `DescendantSuit`, `CombatTool`, `AegisHeadset`,
`SalvageVacuum`; regressions in corresponding tests.

**Interfaces:** existing module APIs and network schemas remain unless a measured
benefit requires a documented, synchronized protocol revision.

- [x] Write failing regressions for measured dominant costs, including renderer lookup/hidden effects if confirmed.
- [x] Implement local changes one at a time; keep behavior and validate cleanup on removal/round/ownership transitions.
- [ ] Test backpack transaction safety and native paths for global patches even when no mod item exists.
- [x] Repeat affected native scenes, full suite and combined workloads; compare function activity as well as speed.

## Task 5: File organization and evidence

**Files:** create `docs/PERFORMANCE.md`, update `README.md`, documentation index,
`tools/performance/README.md`, package metadata only when packaging final production changes.

**Interfaces:** concise per-item before/after tables link to run manifests and reproduction commands.

- [x] Keep historical scripts/results intact; group new performance tools/scenarios and document entry points.
- [x] Consolidate README history with a changelog when links and public instructions remain valid.
- [x] Run full regression suite, content validator, artifact/link checks and package validator.
- [x] Run at least 30 minutes mixed load and lifecycle checks; mark unavailable cases with reasons.
- [x] Obtain a fresh whole-change review, resolve important findings with RED/GREEN tests, and report actual limits. Production changes reviewed; later lifecycle/package-inventory test tooling is additional work, with its own verification still required.

## Execution record

Use `.superpowers/sdd/2026-11-18-mod-performance/progress.md` for checkpoints,
commands, measurements and rulings. Work on the existing clean `dev` checkout;
do not move the user's runtime copies into another checkout or publish changes.
