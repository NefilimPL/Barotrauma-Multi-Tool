# Shield outline, recoil and shot volume

> Implementation: native execution in the existing dev checkout. Follow test-driven-development for multiplayer recoil and verification-before-completion before reporting results.

**Goal:** Remove the extra blue shield outline, make each shot visibly kick the weapon, and increase both shot sound variants by 30%.

**Architecture:** Preserve the shield texture and its wall clipping. Share the existing native recoil impulse through physics.lua; apply it on the authoritative shot and once when a multiplayer client receives the existing shot event. Use velocity 10 and velocity cap 12, below vanilla ranged weapon recoil (50, cap 64). Change sound prefab gain from 1.0 to 1.3.

**Tech Stack:** LuaCs, Lua 5.2, XML, Python unittest/Lupa.

**Scope:** User request of 2026-11-15 with shield screenshot. The earlier body-hit feedback design is still a separate proposal; do not change NPC damage or stun here.

## Constraints and review focus

- Preserve shield texture, occlusion, collision and energy consumption.
- Apply recoil to the correct weapon using its current direction, including left-facing and vertical aim.
- Skip removed, disabled and unrelated entities from delayed shot events.
- Multiplayer clients apply one local pulse per received shot; singleplayer and host apply one authoritative pulse.
- Preserve shot assets, range, rate of fire and other sound gains.

## Task 1: Three feedback corrections

Files: `MULTI-TOOL-V2/Lua/CombatTool/{physics,projectiles,network,visuals,config}.lua`, `MULTI-TOOL-V2/combat_sounds.xml`, `tests/test_combat_recoil.py`.

- [x] Add behavioral tests for native recoil at three aim angles, disabled/removed/wrong entities, authoritative firing and client shot receipt without firing on non-shot events.
- [x] Run the tests against current code and inspect the expected failures.
- [x] Add `G.recoil(item)` in physics; call from fire and the client shot receiver. Set recoilVelocity=10 and recoilMaxVelocity=12.
- [x] Remove the procedural shield edge and its edge-only ray casts; retain strip clipping and texture.
- [x] Set both aegis_shot gains to 1.3.
- [x] Run recoil tests and full `python tools/run_tests.py`, then content validation and diff checks.
- [x] Report whether real-client visual verification was available. Do not infer the perceived effect from unit tests.

## Validation results

- New recoil tests failed against the previous implementation, then passed after the changes.
- Full suite: 476 tests passed. The two shield occlusion expectations were updated from 41 casts to 16 because the deleted outline no longer needs its 25 edge casts; the test now also rejects any procedural shield lines while requiring the texture to draw.
- Content validator: 13 XML files and 43 Lua 5.2 modules valid, including recipe references against `.runtime/client` content. `git diff --check` passed.
- Checked the installed native SoundManager and SoundChannel code: XML volume populates BaseGain; gain accepts values greater than 1 and applies the normal category volume multiplier.
- No real game client session was run for these changes. Perceived recoil strength and appearance remain unverified in game.
