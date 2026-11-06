# Frontal shield and vacuum salvage follow-up

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans task-by-task.

**Goal:** Diagnose remaining frontal wounds through real native aiming; make backpack capacity and salvage progress understandable and allow collecting during a salvage job.

**Architecture:** Reproduce native firing over physics ticks before changing the shield. Keep the salvage input snapshot stable, expose processed/done/skipped and stop reason, batch only cheap skipped inputs, and permit pickup between atomic spawn transactions. Reuse the game's deconstructor loop with activity expiry.

**Tech Stack:** LuaCs/Lua 5.2, native isolated Barotrauma 1.13.5.0 server with Neurotrauma CS2.0.5, Python unittest/Lupa.

**Spec:** User report in conversation, including screenshot with ambiguous 62/100 and 598/10000 counters and silent busy status. User authorizes continued fixes.

## Global Constraints

- Current authorized checkout; no commit/push/publication or user campaign changes.
- Keep 100 groups of up to 100 items and preserve item identity, nested contents, energy and output rollback.
- Pickup may pause during a pending atomic spawn; it must work throughout the rest of a running job.
- New pickups are excluded from the job's original snapshot.
- Keep per-tick work bounded and idle equipment silent.

## Review Focus

- A probe which manually forces shield geometry cannot establish real input-driven protection.
- Concurrent insertions must not consume reserved output capacity or existing input sources.
- Unsupported recipes/full storage/empty battery must produce visible results.
- Sound must stop on completion, removal, lost heartbeat and reset.
- Network serialization must carry progress symmetrically with a protocol version bump.

### Task 1: Salvage feedback and concurrent collection

- [x] Add failing regressions for bounded skip processing, retained result/progress, pickup during job, capacity labels and sound expiry.
- [x] Implement safe collection between transactions, localized status/progress, and native deconstructor loop.
- [x] Test transactions, snapshots/serialization, audio and full suite (414 passed); native salvage check (7/7).

### Task 2: Remaining shield leak

- [x] Reproduce with cursor-driven poses and actual native firearm path, including positive damage controls.
- [x] Add failing regression for historical limb fixtures, translate only the matching owner's arc/emitter, preserve FF/walls/energy/rear/current-body controls.
- [x] Verify native matrix (96 protected shots + damaging unshielded control) after full restart; diagnose occasional edge hit with all256 spread values (211 intercepted,45 outside arc,0 covered damage calls).

### Task 3: Review and delivery

- [x] Independent shield/salvage reviews; resolve completion/low-energy and reset/late-callback findings with regressions.
- [x] Document scope, update1.3.10, package and byte-verify all85 production files.
- [x] Stop only own isolated server (clean console exit after matrix/edge-pool checks).
