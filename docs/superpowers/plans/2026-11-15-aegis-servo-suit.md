# Aegis Servo Suit Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task. The user has requested continued execution in the current session.

**Goal:** Prepare the suit's textures, animated arm/helmet/impeller and audio assets, then integrate its three exclusive functions into the mod.

**Architecture:** Preserve imagegen source sheets and use explicit source rectangles. Keep asset preparation and its browser preview independent of the live mod. The eventual Lua adapter must share one mode/action controller between human and AI operation and retain server authority over repair, damage, grabbing, oxygen and energy.

**Tech Stack:** RGBA PNG, browser Canvas/Web Audio, original PCM synthesis and ffmpeg Vorbis encoding, existing Barotrauma XML/LuaCs and Lua 5.2 test harness.

**Spec:** `docs/superpowers/specs/2026-11-15-aegis-servo-suit-design.md`

## Global Constraints

- Pressure protection to 10,000 m.
- One arm function at a time, including AI operation.
- Blue repair/welding, red combat, orange grabbing.
- Strong repair sparks at the target, short repair beam and bounded 360-degree arm reach.
- Batteries or reactor rods supply energy; oxygen has its own slot.
- No oxygen tank consumption in breathable air; helmet closes when conditions cease to be safe.
- Preserve the user's Steam installation and campaign. Use isolated `.runtime` copies for native checks.
- Treat browser preview results separately from game results.

## Review Focus

1. Air pocket disappearing or the head submerging must close the helmet and resume tank breathing.
2. Simultaneous AI goals must result in only one action and one energy debit.
3. A target behind a wall must not receive damage, repair or grab force.
4. Empty, missing and swapped batteries/rods must stop powered functions without creating free oxygen or disabling the suit's passive pressure shell.
5. Repair contact and sparks must follow moving targets and stop when the target leaves reach.

## Tasks

- [x] Preserve the two original PNGs in a reproducible asset bundle. Inspect alpha and rectangle bounds; retain prompts and provenance.
- [x] Implement and exercise pure preview math: bounded arm reach/IK, exclusive mode changes, repair contact, breathable-air state, fuel eligibility and AI task arbitration.
- [x] Provide a local animated preview with clickable modes, helmet/water controls, repair/welding targets, strong contact sparks, moving impellers and user-triggered audio.
- [x] Generate original repair, combat, tractor, servo, impeller and helmet sounds. Provide the original PCM synthesis/ffmpeg generator and actual game OGG assets.
- [x] Add Lua controller tests and run RED before implementing the game adapter. Cover repair vs welding selection, hostile LOS, one grabbed root target, AI priority, power swaps and breathing transitions.
- [x] Add the actual XML suit and namespaced Lua adapter without changing existing multitool behavior. Validate native component APIs against the installed game before using them.
- [x] Run the complete test suite and `tools/validate_content.py --game .runtime/server`.
- [x] Check the actual suit, repair sparks, welding, AI, oxygen and beam/arm rendering in an isolated game. Record what was observed and any remaining limits.
- [x] Reinspect final armor fitting on a functioning GPU client and run a complete joined-client multiplayer session. Keep this a documented preview pending wider gameplay testing.

## Execution record

- Baseline: 477 tests passed using `python tools/run_tests.py`; evidence `.runtime/aegis-baseline-tests.txt`.
- Source PNG inspection: both selected sheets are 1536 x 1024 RGBA with alpha range 0..254, not opaque brown images.
- Approved command execution recovered on 16 November. The preview-only embedded base64 copy was removed; actual PNGs and OGG files are in the mod.
- Ruling: no asset materializer is needed once direct filesystem access works; retain original sheets and use source rectangles rather than destructively cropping or removing RGB backgrounds.
- Native findings fixed with regressions: client breathing properties, pause handling, GUI queueing, grab lease/input/cooldown, wrong wall section, native oxygen API, and bot gear removal. Added verified `divinggear_wearableindoors` tag.
- Review findings fixed: functional seal/helmet Wearable plus a separate visual plate Wearable prevent doubled armor; non-hideable plates and explicit source depths preserve layering. Native armor check passes.
- Final continuation: 505 full-suite tests, 20 preview checks, 17 XML / 49 Lua content validation. Previous 11 native checks and enabled bot repair/underwater checks remain recorded. Final GPU armor inspection and all eight joined-client localhost multiplayer phases passed; raw evidence and screenshots live in `docs/aegis-suit/`.
- Native multiplayer exposed the fixed-distance reconstructed cursor: replaced point-distance acquisition with an aim ray using the native aim reference, with range, LOS and eligibility checks. RED/GREEN regressions cover acquisition, blocked/behind/out-of-range targets and first-target selection. Corrected torso rotation and interpolated attachment drawing, with two regressions.
- Repeated probe fixtures initially interfered with repair/grab targets; isolated cleanup and aim settling corrected the test, without weakening authoritative assertions. Test scripts remain outside the distributed mod.
- Read-only follow-up review found no Important/Critical issue. No Steam P2P/high-latency multi-client or actual 10 km boundary test; these limits remain in `docs/AEGIS-SUIT.md`.
