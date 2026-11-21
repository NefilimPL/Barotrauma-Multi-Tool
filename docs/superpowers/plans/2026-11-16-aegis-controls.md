# Aegis controls implementation plan

> Execute inline with superpowers:executing-plans; use one focused independent review at the end.

**Goal:** persistent physical suspension, connected tool effects, stable faster repair, collapsible controls, optional left native sonar and correct ground art.

**Architecture:** shared pure geometry/contact rules in `core.lua`; authority-owned `grip.lua` and `sonar.lua`; native sonar GUI hosted by a client UI module. Existing game/network/client modules connect them.

**Tech stack:** Barotrauma 1.13.5.0, LuaCs c6e8829, Lua 5.2, native XML GUI/physics, Python/Lupa regression suite.

**Spec:** `docs/superpowers/specs/2026-11-16-aegis-controls-design.md`.

## Constraints and review focus

- Preserve all current suit functions and the slim worn atlas; never modify the user's Steam/campaign.
- Grab cleanup must handle mode/owner transfer, unconsciousness, depleted power, removal, round end and Lua reload, including pre-existing ragdoll state and competing suits.
- A brief LOS interruption retains contact but applies no repair; large range escape releases immediately.
- Pulse origin must match the visible nozzle, including swimming/left-facing and no current target after a kill.
- Sonar requests require the actual equipped owner and server resource debit; hiding either panel must not alter arm mode.
- Keep generated asset bytes unchanged and record source/prompt; package production files only under a fresh name.

## Tasks

- [x] RED/GREEN shared tool/muzzle geometry and repair contact hysteresis; native tool bonus +600%, welding 80/s, operating range 210 plus 32 retention margin, 0.4 s occlusion grace without hidden repair.
- [x] RED/GREEN latched physical grip, scoped ragdoll restore and exclusive leases. Native SP held a living person after both keys released for 6.9 s, anchor error 0.0322 units; second press restored ragdoll state. Final native MP also passed >7 s latch and depleted-power release.
- [x] Native pulse launch/render/lighting share nozzle; endpoint survives target death in protocol v3. Native origin error below 0.01 units in SP/MP. Regressions cover burst controls, atomic shot resources and snapshot state.
- [x] Both collapsible panels and native sonar passed SP/MP. Native circle 302 px, Voltage 1; active/passive and independent hiding verified. Server controls energy and ownership.
- [x] Built-in image_gen asset copied byte-for-byte, full prompt saved. Native ground width 85.68 units; worn proportions unchanged. Final 560 tests, content17XML/57Lua, real Chrome21/21, native SP16/16 and final joined MP9/9 passed. Independent review blockers fixed and verified. Exported new archive with all121files byte-checked against both runtime copies.

## Execution ledger

- Two review findings fixed RED/GREEN: clear removed repair targets before scanning so they cannot block reacquisition; discovery must preserve the previous owner until transfer cleanup. Reviewer independently reran both regressions (2 passed).
- MP found the legacy 0.1 s global throttle dropping the second of independent sonar/arm requests. Replaced with a bounded four-request burst and ten-request/s refill. Both delivery and flood recovery regressions passed; reviewer independently ran the ten sonar/network tests.
- The server's file-code cache survives merely invoking the autorun again. A full `reloadlua` was required; confirmed `controlBurst=4` before final `controls_mp_c.lua` run. The failed stale-code MP pass is not claimed as final evidence.
- Native pulse collision exposed a shared shield handler reading `Limb.LagCompensatedBody` from the client assembly. Added a SERVER guard with a throwing-client-userdata regression; historical server shield tests remain passing.
- Native fixture corrections: GUI callbacks require `GUIButton+OnClickedHandler.Invoke`; ability enums are numeric and compared through the enum table. No desktop cursor movement; inputs and test camera are simulated only inside the disposable fixture.
- Native SP was `controls_b.lua` (16/16). Final native server/client were `controls_mp_c.lua` (9/9 each), with latest lifecycle and burst fixes. Metadata/hashes in `docs/aegis-suit/controls-verification.txt` record the distinction.
- Export script `.runtime/finalize_aegis_controls.py`; archive `output/System-Aegis-1.3.16-aegis-controls-2026-11-16.zip`, 121 files, 23,067,180 bytes, SHA256 `505d6396b330a9cd0a654dbbb67ee1a16eb9ba5d49cfa17435ecbf883087022d`. Prior archives retained. No merge/push/publication.

## Initial findings

The original grab applies only a weak pull toward the wearer's position, without gravity compensation, and expires after 5 s. Exact range/LOS filtering clears repair state and its native session; repeated servo warmups amplify the perceived slow speed. The client draws beams at a hinge while the tool extends beyond that hinge, and skips a connected beam for combat. Its interpolated target differs from the server's projectile pose. The ground sprite is the assembled standing icon at item scale 0.18. No sonar component currently exists in the suit.
