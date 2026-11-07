# Two-client combat verification

**Request:** Real multiplayer session with a single enemy, fifteen close enemies,
and mass projectile interception, with two connected clients.

**Scope:** Test-only scripts and evidence. Production behavior changes only if a
reproduced defect requires a separately verified correction. No user campaign,
Steam installation, publishing, merge or push changes.

- [x] Prepare matching Aegis and Neurotrauma packages on an isolated dedicated
  server and two GPU clients; use distinct native client names and roles.
- [x] Implement native client input automation, server fixtures and event
  counters, and per-client wall-frame / draw / update timing via a startup hook.
- [x] Run idle and live firing phases for one enemy and fifteen clustered human
  enemies; swap the actual firing client A/B.
- [x] Run idle and mass shotgun fire against each player's real aiming shield,
  including allied Aegis fire with friendly fire enabled.
- [x] Verify native damage/interception counts, actual two-client presence,
  received client effects and stable per-phase frame samples.
- [x] Preserve raw results, scene captures, workload caveats and conclusions;
  stop only the isolated test processes.

Each phase lasts 18 seconds. The frame recorder excludes three seconds of
settling, then records frame mean/p50/p95/p99/max, CPU draw/update durations
and frames above 33/50 ms. Both clients share the same host CPU/GPU and use
960×540 with VSync disabled. Configuration requested 144 FPS but measured Draw
frequency could exceed it; reports use actual frame intervals. Absolute
performance is not a measurement of either friend's computer.

Initial actors retain native damage handling with raised health capacity;
separate followup phases use max health 100 and no GodMode on opponents.
Oxygen/pressure protection are maintained. Disabled AI and native positioning
stabilize opponents. Initial held-gun mass phases ended in NT deaths; their
means are excluded from sustained-shield conclusions. Final stress uses fixed
native RangedWeapon emitters, replenished energy/ammo and GodMode on defenders
to prevent deaths from ending the workload. Players use native networked input.

Results: 14 selected phases × two clients validated, 437 regression tests OK.
Single normal-health target: 133/134 FPS; 15 clustered targets: 115/115 FPS;
sustained mass shield phases: 99–119 FPS. 510 native shotgun shots, 90 allied
Aegis shots and 558 shieldhit events across the two final blocking phases.
No production changes. Full evidence and limitations:
docs/TWO-CLIENT-COMBAT-VERIFICATION.md.
