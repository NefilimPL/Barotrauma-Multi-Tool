# Combat recoil and shot gain verification — 2026-11-15

The previous physical impulse did not visibly recoil a held weapon. The installed native `Barotrauma.AnimController.HoldItem` resets item dynamics and sets the held transform every animation update. Increasing the impulse therefore did not establish visible movement.

The correction adds a short offset to the existing aimed `HoldItem` call: move the grip back and lift the weapon angle, then recover over 0.20 seconds. It changes call arguments rather than saved Holdable properties. Native facing conversion handles the left/right direction. The angle argument uses LuaCs `Single(...)`, which is required for patched C# float parameters.

Both shot variants now use gain 1.69: another 30% above the previous 1.3. Shot assets, range, cadence and NPC damage are unchanged.

## Actual client comparison

A fresh isolated LuaCs client under `.runtime/recoil-client` ran a singleplayer Dugong Sandbox with only this mod enabled. A real controlled character held the weapon in both hands with a battery installed. Native player input drove the production firing path. The probe sampled the native HoldItem call and rendered body rotation, and captured GPU frames. The client was restarted between versions to avoid module caching. No probe scripts were added to the production package.

Before, while firing:

- Hold position stayed at `(0.40000, -0.07000)` simulation units.
- Angle offset stayed at zero and body/draw rotation stayed at approximately 6.24881 radians.
- Actual native shot channel gain was 1.29999995.

After:

- Eight shots completed with `visualError=nil` and `audioError=nil`.
- At 0.033 seconds after a shot, hold X was 0.33056: a 6.944-pixel backward pose offset.
- At 0.050 seconds, actual body/draw rotation was 6.26936 radians, about 1.18 degrees above rest. The requested peak angle offset was 0.03125 radians.
- The pose and rotation recovered between shots and after firing stopped.
- Actual native shot channel gain was 1.69000006.
- No recoil `InvalidCastException` appeared after using the typed Single argument.

Raw measurements: [before](combat/recoil-pose/before.txt), [after](combat/recoil-pose/after.txt).

GPU captures are retained in `.runtime/recoil-before/{idle,shot}.png` and `.runtime/recoil-client/recoil-{idle,shot}.png`. These frames were visually inspected; this is a small weapon kick, not camera shake.

The actual client comparison was singleplayer. Multiplayer event dispatch remains covered by regression tests; a new two-client visual comparison was not run.

## Automated verification

- A regression for the held-pose pulse failed before the fix. A typed-parameter boundary regression also reproduced the native float conversion failure before that correction.
- `python tools/run_tests.py`: 477 tests passed.
- `python tools/validate_content.py --game .runtime/client`: 13 XML files, 43 Lua modules, textures and recipe identifiers valid.
- `git diff --check`: passed.
