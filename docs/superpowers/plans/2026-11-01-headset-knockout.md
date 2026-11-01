# Knockout recovery

Reported: mudraptor knockout with only unconsciousness visible never recovers.
Root cause reproduced with real NT C# PostHook counters and a single patient
kept inside a safe hull. Native Character.Update restores stun>=5 each frame
while incapacitated. NT unconsciousness creates givein (type paralysis,max1).
The headset prioritizes stun90 above the paralysis and all ordinary wounds0;
every0.217s its entire4.333-strength MkII budget is spent on recreated stun.
After15s: stun5, givein1, unconsciousness78.67, energy62.625%, alive100 vitality.

Fix generic treatment ordering: stun below ordinary injuries; paralysis type
above ordinary symptoms. Existing bleeding/oxygen/cardiac priorities stay higher.
No forced resurrection, free curing, NT dependency or global round timer change.
Alternative NT-only symptom API clearing rejected: hides the symptom while
native/other-mod wounds would still starve behind continuously recreated stun.

Verification correction: NT CS installed DLL delays the last two characters in
CharacterList by120s due integer scheduler arithmetic. Prior short delayed tests
did not execute NT physiology. New fixtures must have trailing non-patients and
assert actual NT PostHook counts. Keep dynamic fixtures in a safe hull to exclude
collision/pressure confounds. Record actual attacks at native timestep1/60.

- [x] Add failing regressions for recreated stun, unknown wounds, NT paralysis.
- [x] Fix generic priorities, preserving costs and ordinary healing rates.
- [x] Run real NT knockout/attack/idle with actual physiology assertions.
- [x] Update documentation/version1.2.7 and validate packaged production files.

2026-11-02 final evidence:178 regressions PASS; native knockout suite8/8,
each patient11 real NT PostHooks. NT unconsciousness recovered by8s, final
energy86.6084%, vitality100, maximum continuous incapacitation0.133s. Coma
and critical burns recovered by15s. Empty cell did not cure. Idle20s retained
100% power/vitality. Real mudraptor bite absorbed byMkII; basic received it.
The first aggregate fixture used fixed world coordinates while the submarine
moved, causing pressure drain; final fixture follows its hull and confirms it.
Content11XML/24Lua/native recipes PASS. ZIP63 exact production files, no tests;
tested medical code matches package. Private server closed. No Steam edits.
