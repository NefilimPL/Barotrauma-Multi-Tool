# Aegis service and movement corrections — 1.3.18

**User scope:** stronger safe airborne grip while running, passage through native stairs/platforms, loose items actually following the claw, stable fast tracking during body turns/minor motion and ladder/seated operation; fire from the visible tool; correct rack sprite and charging; small optional sonar/mineral control/clear selected colors; static impeller housing with spinning blades and scooter bubbles; measured swim comparison. Continue the existing authorized implementation without a new approval loop.

**Design calls:** retain native collisions with walls; only held-body incidental impact damage is suppressed during the lease, and platform/stair treatment is scoped/restored. Use carrier-aware force limits and greater lift, not teleporting held targets. Keep one function per suit and native repair rewards. Retain world arm orientation as torso rotates, stable IK bend, short eased tracking with a practical repair beam width. Validate obstruction from the nozzle while ensuring the arm cannot reach through solid walls. Guard both native CanInteractWith overloads only inside servo scope; preserve secondary ladder/seat selection. Docking charges the installed power source (battery or rod as requested), never ammunition, only inside a powered suit holder. Minimized powered sonar shows just a small native radar; off+minimized hides it; full controls remain expandable. Mineral scanning uses native Sonar.UseMineralScanner with authorized replicated state. Reuse existing atlas crops for rack and rotor; new raster only if reuse cannot produce a good result.

## Steps

- [x] RED/GREEN carrier-aware grip force/lift, scoped platform/impact cleanup, claw attachment for items.
- [x] RED/GREEN world-stable joint tracking, bend choice, practical alignment, muzzle LOS and secondary-interaction repair access. Native ladder/seated/turn tests.
- [x] RED/GREEN powered docking. Separate native ContainedSprite for vertical/window/horizontal suit holders, independent inventory/ground art.
- [x] RED/GREEN compact hidden-off sonar, mineral replication and distinct active colors; native HUD inspection.
- [x] Static rotor housing + isolated blade animation, bounded native scooter bubbles; real swim-speed comparison with ordinary/abyss/PUCS suits.
- [x] Native SP and joined MP acceptance plus targeted performance check, independent review, docs and new byte-verified ZIP. Preserve previous packages and stop isolated processes.

## Root-cause findings

- Grip ApplyForce currently caps world speed at3 while recovering and8 normally. A running carrier can consume that entire cap, suppressing vertical force/gravity compensation. Lift45 is low for a long ragdoll; no carrier acceleration feed-forward. IgnorePlatforms and incidental impact protection are not managed by the lease.
- Motion solves IK with the current facing every frame and stores torso-relative angles with no torso-rotation compensation; changing pose/facing can flip the bend and sweep the arm. A .07-rad check measured from a nozzle only14 units from a repair target amplifies small pose errors.
- Combat acquisition/retention uses torso mount LOS. Native projectile later uses muzzle LOS, so an unobstructed nozzle can never acquire a target blocked only at the torso.
- Native CanInteractWith(Item,bool) delegates to the out-distance overload, which can be inlined. Ladder/seat secondary interaction imposes ordinary hand distance/direction checks; the existing scope hook covers only the wrapper.
- Rack drawing uses the folded ground sprite because no ContainedSprite is defined. No dock charge path exists. The rotor sprite is the entire housing and blades, and the whole sprite spins. Sonar explicitly has HasMineralScanner=false and panel37%x54%; Selected uses visually weak theme defaults.

**Verification limits:** do not infer swim percentages from the additive force parameter; measure the same character/settings. Do not claim native stairs, seats or mineral markers from mocked-only coverage. Record any remaining engine/API limitations explicitly.

## Final observations

591 regressions pass; content validates17XML/59Lua. Native SP15/15 + extra water/LOS9/9 + real structure2/2; final joined MP10/10 and dock charge/sprite pass on both roles. Native5-variant same-character swimming measurement and four20s one-client performance phases recorded in `docs/AEGIS-SERVICE.md`. Performance still has spikes, with VSync/background limitations explicitly stated. Browser model and actual Chrome both21/21; new assets load before checks run.

Review caught shared centered origin for window racks; split and calibrated to negative native origin, fresh joined client screenshot confirms positioning. Final MP also reproduced zero lift below an80-unit ceiling when all high anchors failed; lower-priority25-unit anchors now pass nativeMP plus a failing-then-passing clearance regression. No downward/negative character anchors. A native out-float assignment caused LuaCs to unbox Double as Single; removed the unnecessary assignment and repeated ladder/seat/nativeMP.

Delivered archive `output/System-Aegis-1.3.18-aegis-service-2026-11-17.zip`:126files,26,521,832bytes, SHA256 `f21baacfed621173e8c9ff2161ab82ba80874ee93b9f91c1fa658b59610aee23`. Every ZIP entry and both runtime production copies were byte-verified. Previous1.3.17 archive preserved. Isolated client23096 and server22508 stopped after final validation. No Steam installation/campaign edits.
