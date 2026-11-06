# Held shield firearm interception

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans task-by-task.

**Goal:** Prevent frontal gunshot wounds caused by the held character's arm protruding in front of the shield during a weapon turn.

**Architecture:** Move the shield pivot from 25 units behind the weapon to the weapon mount. Keep simulation, interpolated rendering and wall clipping aligned. Preserve native projectile collision order, rear vulnerability, friendly fire and energy rules.

**Tech Stack:** LuaCs / Lua 5.2, Barotrauma 1.13.5.0 dedicated server with Neurotrauma CS2.0.5, Python unittest/Lupa.

**Spec:** User reports a persistent gunshot wound despite the shield impact effect while hosting. Native held-pose probe reproduces damage before shield contact, including damage plus impact in a single shotgun shot; unshielded control confirms actual damage.

## Global Constraints

- Work in the authorized checkout; no commit, push or publication.
- Use only the isolated native test server; leave user game and campaign untouched.
- Keep the same arc angle/radius, energy costs and wall/friendly-fire policy.
- Do not add character scans or damage-time immunity.

## Review Focus

- Native weapon rotation can change before the hand/arm physics settles.
- Shotgun pellets can produce both a wound and a later shield flash in one shot.
- Drawing, simulation and clipping must use the same pivot.
- A nearer unshielded character or wall must still stop the bullet first.
- Rear shots and shots originating within the shield must remain valid.

### Task 1: Align shield mount and verify native damage

**Files:** `MULTI-TOOL-V2/Lua/CombatTool/shield.lua`, `visuals.lua`, `tests/test_combat_shield_network.py`, `tests/runtime/shield_held_probe.lua`, release/verification documentation.

**Interfaces:** Existing `G.findShield`, `G.updateShield` and render snapshots; no protocol change.

- [x] Reproduce on actual held item with enabled character physics and a damaging unshielded control.
- [x] Add a regression using captured native arm contact coordinates and observe failure.
- [x] Move the pivot and render/clipping origin together; pass focused/full tests (390 passing).
- [x] Run native held-pose baseline and corrected checks, recording damage calls and energy rather than health alone (28 shield shots + damaging control, repeated after full server restart).
- [x] Independent review: no blocking issues; keep the documented scope limited to the deliberately forced transient pose.
- [x] Document scope, package 1.3.9 and verify all 85 ZIP files byte-for-byte against production source.
- [x] Stop own test server (clean console exit).
