# Descendant Suit V2 Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for inline implementation task by task.

**Goal:** Correct the suit's inventory, native repair rewards, pulse defence, appearance, lighting, mobility and AI supplies using the user's gameplay feedback.

**Architecture:** Retain the namespaced controller. Move supply, native repair and pulse firing into focused Lua modules, with a single native restricted inventory. Draw attachments in the native world pass and use native lights/projectile effects.

**Tech Stack:** Barotrauma 1.13.5.0, LuaCs c6e8829, XML, Lua 5.2, generated RGBA atlas, local Python/Lua tests and isolated native clients.

**Spec:** `docs/superpowers/specs/2026-11-16-descendant-suit-v2-design.md`

## Constraints and review focus

Server-authoritative resource/damage/repair changes; one arm mode at a time; no external supplies spawned for AI; no borrowing from other characters or installed tools/reactors. Preserve pending README command additions. Do not attribute native repair rewards to direct condition increments. Light sources and native repair sessions must be released on every lifecycle exit. Native slot roles change: respawn old suit fixtures and document this.

## Tasks

- [x] Inventory/life support: RED/GREEN regressions for one inventory with power/ammo roles and closed-loop breathing. Native visible slots and client extraction/reinsertion of both resources confirmed. WalkingSpeed/MovementSpeed modifiers both 0; pressure 10000.
- [x] Pulse defence: native mini hitscan projectile, 1800 range, 25 base damage every 0.4 s, atomic resource/cooldown tests. Actual joined-client shot hits at approximately 650 range, ammo debit, tracer emission and audible native sound channels confirmed.
- [x] Repair rewards: guarded native Repairable.Update, no competing fixer takeover, +300% tool bonus. Native completion raised electrical skill 20 to 22 and fired OnRepairComplete once. Increased welding, native outside-leak event and structure-repair stat applied.
- [x] AI supplies: eligibility/ownership regressions, native GetItem pathfinding, atomic inventory replacement, bounded retry and lifecycle cancellation. Enabled bot replaced both own-inventory resources and fetched replacements from submarine storage; closed-loop support verified underwater.
- [x] Art/lighting: built-in imagegen atlas saved unchanged with prompt/provenance. Native pre-lighting draw, compact links, helmet/tool lights and cleanup. Light/dark/water/screenshots inspected. Native stop observer saw 4/4 light removals; pauseClient+clear also saw 4/4. Browser preview loaded in actual Chrome without exceptions, 21/21 checks.
- [x] Final validation: 523 full-suite tests, 21 preview checks, 17 XML / 54 Lua modules valid, native 11/11 joined-client phases. Focused review found two Important lifecycle issues; both fixed RED/GREEN before the final native run. README/commands/help and raw evidence updated; packaging is performed by the verified export script recorded below.

## Execution notes

### Grab usability follow-up

- [x] Explain Aim + Use (tested/default RMB + E), release click, range and lease in README and in-game localized hints using actual input bindings.
- [x] RED/GREEN: accept loose dynamic world props without a Pickable or inventory slot; reject anchored/static/contained/connected objects and excessive mass. Apply the same eligibility to acquisition, retention and execution.
- [x] Use native Character.Mass for the whole creature, not collider mass; check an actual human and a massive creature in the isolated runtime.
- [x] 528 regressions and content validation passed; native fixture h passed 6/6 acquisition/pull/live/release/mass/UI checks. New package export: `.runtime/finalize_descendant_grab.py`, byte-compared to the tested runtime and archived without overwriting V2.
- Focused independent review `/root/review_grab_followup`: no Critical/Important findings in eligibility, native whole-creature mass, acquisition/retention/pre-debit checks, localized hints or regression coverage. Reviewer inspected code and recorded native results; did not independently rerun runtime checks.

- Ruling: continue in the existing authorized workspace and preserve pending README command edits. Keep all native execution in the two existing isolated .runtime copies, not Steam or the user's campaign.
- Ruling: use a native GetItem objective followed by native atomic TryPutItem, instead of a specific-item ContainItem objective, because the existing project documents that specific-item containment does not pathfind to the source by itself.
- Native RED findings fixed: AICharacter requires its own userdata exposure for the inherited private selection field, concrete AI objective descriptors require the completion setter, and lighting must wait for inventory/owner replication. These are covered by meaningful regressions.
- Fixture corrections: native button labels uppercase their text; the crate used initially rejects large ammunition boxes, so the ammo reserve uses a native ammo shelf. A large box is extracted into a free hand, not an Any-only pocket. Final server observed both native client transfers.
- Native Pulse observer recorded 9 tracer emissions and 9 automatic sound calls, including playing audio channels. No copied vanilla audio/particle assets. Browser pulse.ogg is separately synthesized.
- Review fixes: cancel pending fetches before state deletion/ownership change; retain states until client lights are removed, including pause-to-clear. Final native run used the corrected production module bytes.
- Package/evidence export: `.runtime/finalize_descendant_v2.py`; output `output/MULTI-TOOL-V2-descendant-v2-2026-11-16.zip`. Prior packages are retained. Distribution contains production mod files only.
