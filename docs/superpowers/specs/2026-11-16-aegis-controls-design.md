# Aegis suit controls, contact and suspension

The user reports a weak short-lived grab, a disconnected pulse trace, repair contact lost after slight movement, slow/narrow repair, an obstructive menu, missing optional left sonar and a miniature-person dropped sprite. Continue the existing authorized suit implementation in the shared workspace.

## Design

- A player's Aim+Use press toggles a latched grab. Release the keys after acquisition. Keep a movable object or non-massive creature suspended at an anchor relative to the wearer until the second press, mode change, blocked/broken range, missing power, owner incapacitation or unequip. Held creatures become temporarily ragdolled. Apply damped forces with gravity compensation to enabled limb bodies; preserve and restore prior ragdoll state. One controller owns a target at a time. Bots retain a bounded rescue lease.
- One shared tool pose defines links, head angle and muzzle for drawing, lights and native pulse launch. Add a brief connected red beam on each pulse. The native projectile remains responsible for hits, particles and audio. Replicate pulse endpoint and optional sonar power state with a new protocol revision.
- Arm links 76/66, operating radius 118, nozzle offset 24, repair beam reach 68. Keep damaged repair targets through a 32-unit release margin and 0.4 s temporary LOS interruption; never repair through a wall during the interruption. Increase native repair tool bonus to +600% and welding rate to 80/s while retaining native skills/rewards. Blue beam becomes wider.
- Collapse the right control panel to a small edge tab without changing its mode. Sonar has a separate left pane with its own collapse tab and explicit power toggle. Use a native portable Sonar component (6000 range, active/passive controls); server owns suit-energy debit. Sonar and life support are independent of the mutually exclusive arm modes.
- Use a new generated transparent folded-suit item sprite for inventory and ground display, not a scaled standing-person icon. Preserve existing worn atlas and slim proportions. Metadata and native scale control display size; retain the original raster unchanged.

## Approach and constraints

Extend the existing Lua/XML architecture with focused geometry/grip/sonar/UI modules. A force-based hold with native collision keeps the game physics; teleporting targets would bypass obstacles. Native sonar provides real echoes rather than an unrestricted entity radar. Existing session instructions authorize proceeding without another approval round.

No Steam installation, user campaign, publication, merge or push changes. Preserve earlier archives. Verify finite geometry, gravity/stability, lifetime cleanup, no repair across blockers, native rewards, forged controls, UI collapse independence and native loopback multiplayer before claiming completion.
