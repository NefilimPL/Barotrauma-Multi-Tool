# Aegis suit V2 — corrections from gameplay feedback

The user requests an iteration of the existing suit, retaining its identity and one arm function at a time. The new feedback supersedes the oxygen-tank and continuous defence beam design. Implementation is authorized by the ongoing request to build and continue the mod.

## Required behaviour

- One native ItemContainer with two individually restricted slots: battery/reactor fuel at index 0, pulse laser ammunition box at index 1. Both remain visible while equipped. Remove the oxygen tank requirement.
- Closed-loop breathing uses suit power in water or unsafe air; safe air opens the helmet and does not consume breathing power. Empty power does not supply oxygen. Pressure protection remains 10000.
- Defence fires miniature pulse laser shots with native tracer, muzzle/impact effects and audible shot sound. Initial tuning chosen by implementer: 1600 range, one shot every 0.4 seconds, 20 burn + 5 explosion damage per shot, native box expenditure 2.25 condition per shot. These are tunable defaults, replacing 420 range and 4 damage/second.
- Faster repair uses the actual Repairable.Update completion path, its skill/stat/quality/maximum-condition calculations, skill gain and OnRepairComplete talents. A scoped bridge permits the servo to act without selecting the device or occupying hands. No duplicate progress from the normal frame update; do not interrupt another fixer. Suit tool bonus: +300% repair speed. Wall welding receives a substantial speed increase and the native outside-leak talent event when applicable.
- The first panel button toggles arm on/off; its current-state label changes between enabled and disabled. Other buttons still select one function. Show power and ammunition separately.
- Replace tan/brass sprites with a coherent futuristic exosuit: slim gunmetal plates, limited crimson panels, cyan optics, covered cabling and compact manipulator. Preserve the user's own visible head when the helmet retracts. Reduce the arm's proportions and keep attachment to the torso.
- Remove both the land speed penalty and diving-suit walk/run animation overrides.
- Render the mechanical parts in the character/world pass before lighting and postprocessing, rather than an unlit overlay. Provide real native light sources for helmet and tool, following the suit and respecting walls; remove them on unequip, stale state, round end and Lua reload.
- Enabled AI replenishes empty power and ammo from its own inventory and accessible submarine supplies. Use native fetching/pathfinding objectives, preserve other characters' inventory and installed reactors/tools, one fetch at a time, bounded search/retry, no spawning supplies.

## Approach

Continue the existing XML/LuaCs package. A single container with a subcontainer is the native solution for independently restricted visible slots; moving two custom frames apart would retain the original fragile ownership layout. Native projectile effects and native repair completion are preferred to recreating them by custom beam drawing/direct condition increments. Existing Aegis AI objective patterns provide the resupply model.

New generated RGBA atlas is a project asset, not a concept-only image. Generate with the built-in imagegen tool, inspect alpha/layout and save its prompt and provenance. Existing screenshots are regression references, not source images to recolour.

## Verification and boundaries

Use RED/GREEN regressions for power-slot roles, breathing, pulse costs/cooldown/no-ammo behaviour, native repair ownership/cleanup and replenishment eligibility. Run full existing tests, preview checks and content validation. In isolated native copies verify visible slots, pulse damage/ammo, repair completion skill/talent path, enabled bot supply replacement, lighting changes and cleanup, movement and joined-client replication. Record failed probes and their resolution honestly. Do not modify Steam installation or the user's campaign, publish, merge or overwrite earlier ZIPs. New suit instances are required after changing native container layout.
