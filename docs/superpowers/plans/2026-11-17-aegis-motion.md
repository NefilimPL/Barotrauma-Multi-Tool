# Aegis motion, grip recovery and player control

**Goal:** restore smooth servo motion without separating beam origins, recover a held body around brief obstruction, moderately reduce repair/damage, and prevent automatic repair from steering/crouching its wearer.

**Execution:** inline, continuing the user's authorized suit work. Native Barotrauma 1.13.5.0 / LuaCs c6e8829; preserve previous packages and current art/UI.

## Findings and design

- 1.3.16 deliberately replaced interpolated drawing with an instantaneous shared tool pose. Add bounded, eased joint angles in torso space. The server advances motion; snapshots carry those angles, clients interpolate them. Drawing, lights and projectile launch use the resulting pose. Repair/combat wait for alignment; an established physical grip continues while the arm moves.
- The grip currently shares strict acquisition LOS/range and clears immediately on an obstruction. Keep an established lease through a bounded brief obstruction and a larger release margin. Reposition its force anchor closer/lower when a body cannot fit, and use wall-tangent guide points when the straight tether is obstructed. Preserve collisions, exclusive ownership and all manual/power/incapacitation cleanup; do not teleport through walls.
- Native Repairable.UpdateFixAnimation calls AnimController.UpdateUseItem(false,...), which changes movement, facing, hands and crouch. Existing guard is authority-only/scoped; a multiplayer replica still animates the replicated CurrentFixer. Install a narrow servo-animation guard on both sides and leave genuine manually selected repairs/crouch input alone.
- Balance call: reduce device tool bonus from +600% to +450%, welding from 80 to 64/s, pulse from 25 to 20 damage (16 burn + 4 explosion), keep pulse cadence and resource costs. These are moderate initial adjustments to the user's feedback.

## Tasks

- [x] RED/GREEN client/server animation guard with manual-repair preservation.
- [x] RED/GREEN bounded smooth joint poses, wrap-around and frame-step handling; integrate shared pose, alignment and network interpolation.
- [x] RED/GREEN retained grip contact and collision-aware recovery anchor; preserve release after permanent blockage and other lifecycle failures.
- [x] Adjust balance and preview/docs; run regressions/content checks and native SP/MP motion/control/grip cases.
- [x] Focused independent review, export current native evidence and a new byte-verified 1.3.17 package; stop isolated processes.

**Review focus:** first acquisition must animate from rest; small target motion must not reset alignment; no firing from an unaligned head; no force/animation cancellation of the player's keys; temporary obstruction must retain ragdoll but permanent walls must eventually release it; no native/manual repair takeover.

## Verification and rulings

- RED/GREEN recorded in `.runtime/servo-motion-red.txt`, `servo-anchor-red.txt`, and `servo-review-guard-red.txt`; 575 tests pass. Content 17 XML / 58 Lua 5.2; real Chrome 21/21, zero exceptions.
- Native SP final `motion_g.lua` 19/19, native loopback MP final `motion_mp_c.lua` 9/9, full LuaCs reload on both sides after source changes. SP measured max upper joint step .066667 rad, ceiling recovery minimum anchorY .8242, repair peak100/skill20->22/event once, projectile origin error .0078125 units. MP repair UI inspection had zero UpdateUseItem/forced crouch, manual movement/crouch30 samples each, joint snapshots360 samples.
- Ruling: native fixture samples peak repair condition and completion event, not only delayed Condition, because native deterioration can already reduce a fully repaired item by the final assertion. Fixture isolation removes earlier nearby test devices and casts for actual ceiling geometry rather than assuming a hull rectangle is a physical wall. Manual crouch uses InputType.Crouch. No production behavior was changed to satisfy fixture setup.
- Reviewer found one Important issue: selecting a servo-repaired device UI bypassed the original client guard. Fixed with an explicit automatic-session marker in v4 snapshots and native manual StartRepairing handoff, with RED/GREEN coverage. Focused rereview found no remaining Critical/Important issues and independently checked handoff/cleanup.
- Bounds: no native proof of navigating every doorway shape; ceiling collision is native, occlusion/guide edge cases use Lua regression casts. One local joined client, no high latency/Steam P2P or third-party ragdoll/talent matrix.
- Export complete: 122 production files byte-matched against both tested runtimes and ZIP entries; ZIP CRC check passed. `System-Aegis-1.3.17-aegis-motion-2026-11-17.zip`, 23,069,938 bytes, SHA256 `97d82c51ded4f7003ed0e7c13b8af66ecdd712d268e2148c59d6bbf341f20c94`. Native evidence and original GPU captures exported to `docs/aegis-suit/motion-*`. Isolated client PID 5516 stopped after path verification; dedicated server exited cleanly (PTY 42175 exit0). Earlier packages preserved.
