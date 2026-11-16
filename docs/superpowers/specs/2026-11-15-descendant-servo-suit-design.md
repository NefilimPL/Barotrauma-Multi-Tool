# Descendant servo suit

## User requirements

- A wearable diving suit with one extra articulated arm, inspired by industrial servo arms.
- Clickable functions, like the existing multitools. Exactly one arm function may operate at a time, for players and AI.
- Repair mode automatically chooses a nearby damaged device or damaged wall. The arm reaches toward the target, stops close to it and emits a short blue repair/welding beam. Strong sparks originate at the actual repair point.
- Combat mode tracks visible hostile targets in 360 degrees and fires a continuous red beam with modest damage, leaving the normal hands free.
- Grab mode uses an orange beam to hold one indicated target. Items, characters and small creatures are supported; inventory contents are not extracted by the beam.
- Pressure protection to 10,000 m.
- The helmet retracts in breathable air. The oxygen tank is not consumed while breathing room air; water or unbreathable air requires the sealed helmet and a usable oxygen source.
- Caged impellers assist swimming underwater.
- Arm and propulsion accept batteries OR reactor fuel rods. AI must be able to operate all arm functions and change between them without overlapping actions.

## Design decisions made by the implementer

- Repair and welding are sub-actions of the same repair mode, not independently enabled modes. A pinned valid target is finished before switching to another repair target. AI may prioritize a dangerous hull leak.
- Only one arm and one beam exist per suit. Mode changes release the previous target. AI action selection uses the same validation, power and line-of-sight rules as player actions.
- Pressure protection is a property of the intact suit, independent of charge. No free oxygen, no healing of oxygen deprivation as a substitute for breathing.
- Automatic opening requires a dry head, a hull with sufficient oxygen and safe pressure. Closing must take effect immediately upon loss of these conditions. Visual opening must reflect the breathing state.
- Moving a held target through a wall is prohibited. Large or resisting targets must not be immobilized indefinitely. Exact reach, force, energy and damage are balancing values to verify in the game.
- A fuel rod must remain an actual contained item; charge is normalized by MaxCondition. Only the suit's battery/rod slot may supply the arm. An oxygen tank is a separate slot and cannot become an energy source.
- The earlier belt-mounted automatic anchor belongs to the superseded handheld concept and is not added to this suit without a new requirement.

## Assets

Use the two imagegen-generated RGBA source sheets already shown to the user. A file inspection confirmed their PNG color type is RGBA and alpha includes zero: the apparent brown background in the conversation preview must not be removed by destructive color-keying.

Keep the original sheets intact and define sprite rectangles and pivots separately. Produce an animated local browser preview and original synthetic audio without external samples. The preview demonstrates appearance and timing; it does not establish behavior in Barotrauma.

## Execution boundary

The repository baseline passed 477 tests before changes. The sandbox process launcher failed with `setup refresh had errors`; elevated commands then briefly failed because the approval service reported its usage limit. Review recovered after the date changed to 16 November, and approved command execution resumed without bypassing the check. The final implementation passed 500 automated tests, 20 preview checks, content validation, 11 native server checks and actual AI/underwater scenarios. Earlier GPU runs rendered the arm, panel and sparks; a later client startup failed before the game with NoSuitableGraphicsDeviceException. Final armor fitting and a complete joined-client multiplayer session remain unverified. See `docs/DESCENDANT-SUIT.md` and the raw results it links.
