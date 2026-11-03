# Headset client and resupply correction

> Execute inline with superpowers:executing-plans. Existing user authorization
> covers fixes and the requested red impact / blue healing indicator.

**Goal:** restore singleplayer absorption, show actual LED effects, eliminate
unnecessary regeneration costs and make bot battery insertion reliable.

**Architecture:** keep XML + LuaCs with optional medical adapters. Correct
client/server boundaries, verify native drawable fields, and complete local
battery replacement atomically after a spare is available. Fetch remote cells
through native AI. No changes to the user's Steam installation.

- [x] Reproduce SP `Game.Server` access with a strict client stub; fix and
  verify native SP absorption before claiming protection works.
- [x] Reproduce LED binding/visibility errors with a native client probe;
  add red impact / blue healing tests and fix their actual causes.
- [x] Inspect live healthy afflictions in native runtime, skip inactive
  effects without suppressing unknown mod diseases; charge only actual changes.
- [x] Test bot empty/low batteries, interrupted fetches and local insertion;
  keep the old cell until the spare can be installed.
- [x] Reduce consumption: pressure 2.5%/s (40 s), healing .125%/strength,
  attacks max(.25%, .125%/strength), organ/surgery 7.5%, limb 12.5%.
- [x] Run regressions, native client/server checks and read-only review;
  update documentation and package 1.2.3.

Ruling: work in the current feature checkout, as before; ignored runtime and
reference sources are available here. No commit, push or publishing requested.
Exact root of the user's idle drain remains unproven until native evidence;
the reported client exception is confirmed directly in `G.absorb`.

Results: 151 regressions pass. Native real SP character attack, healing,
worn LED coordinates and GPU PASS; both vanilla and optional NT CS tried.
Final NT client/server healthy idle: 30s, power/health100, safe hull, needs air.
Native server9 mechanic+8 NT checks and3 bot insertion cases pass. Review
found threshold equality and provisional OnBroken side effects; reproduced
RED then fixed GREEN. Ownership filtering also added RED->GREEN.
Ruling: retain generic unknown affliction support. Below-threshold traces and
ignored writes are not paid; exact full user-mod-stack idle cause remains
unverified. Existing provider API requires apply to mutate external state.
One queued command during asynchronous reloadlua crashed the disposable
server; final verification used a fresh process. No user installation edits.
