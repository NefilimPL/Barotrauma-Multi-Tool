# Raised land combat aim implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline, task by task. User explicitly requests this behavior; proceed within the current workspace without a new approval loop.

**Goal:** On land, raise the pulse-laser arm above allies or low obstacles when the normal line from wearer to enemy is blocked, and fire only after a reachable clear pose is attained. Keep ordinary low aim when clear, and preserve existing swimming behavior.

**Architecture:** Add `DescendantSuit/aim.lua`, sharing one bounded, cached plan between combat acquisition, joint animation and readiness. Test both IK bends and the actual three arm/barrel segments against solid geometry; test muzzle-to-enemy against characters and walls. Higher wrist candidates stay inside the existing118-unit operating radius. Cache relative wrist offsets for120ms with movement invalidation; retain raised aim briefly after the obstruction clears to avoid bobbing. Actual firing still checks the current pose and line, including asynchronous projectile spawn. Existing replicated joint angles carry the new pose; protocol remainsv5.

**Tech stack:** Lua5.2/LuaCs, current Barotrauma1.13.5.0 binaries and XML, Lupa regressions, isolated native SP and joined MP.

- [x] RED: dry clear path, ally before/after ordinary muzzle, low wall, ceiling/full-wall rejection, unchanged water aim, bounded probe frequency, stable raised plan, lowered return, and no firing during lift.
- [x] GREEN: implement aim planner; connect `game.visibleFromTool`, `motion.advanceTool/armReady` and autorun. Recheck actual articulated path at firing, preserving native damage/energy/ammunition rules.
- [x] Native reproduction and acceptance: standing ally blocks ordinary shot, arm rises and fires over it without ally damage; low wall clearance, full wall/ceiling block, client receives raised joints. Test disappearance/reappearance of obstruction.
- [x] Independent review; final regressions/content validation; document result and actual limits; build byte-verified1.3.21 ZIP, retain older archives, stop isolated processes.

**Important constraints:** No character steering, crouching, teleportation or movement changes in production. No through-wall firing, increased range, increased damage or control-mode changes. Query a bounded candidate list only during planning; avoid per-frame re-search and always perform current firing safety checks.

## Progress and review

Baseline: HEAD8175278, clean worktree. Spec: the user's request in this conversation. Implemented inline; one fresh-context whole-change reviewer.

RED: original feature cases failed before the planner existed (`.runtime/raised-aim-red.txt`). GREEN: 608/608 regressions passed after implementation.

Final review: two Important findings, no deferred minors. Fixed pre-nozzle/forearm character bypass and retained exact original swimming wall semantics. Three additional regressions reproduced the findings before the change (`.runtime/raised-aim-review-red.txt`); all611 passed afterwards (`.runtime/raised-aim-review-green.txt`).

Native cabin acceptance found the first five candidates all intersected Azimuth's actual roof. Added a sixth lower overhead candidate, preserving the same reach and clearance rules. A narrow-headroom regression failed before that addition and passed afterwards; suite612/612 (`.runtime/raised-aim-headroom-red.txt`, `raised-aim-headroom-green.txt`). This fulfills the original cabin behavior without changing test geometry or weakening obstruction checks.

Joined MP: 4/4 stages passed on the final code, with authoritative server, native client, original cabin ceiling, repeated ally entry/exit and vitality100. Replicated muzzle lift ~65.45; each stage emitted6 native projectiles. Functional acceptance only, no new multi-client FPS claim.

Final native SP on the exact release bytes: 7/7 in a2480x288 hull, no ceilings removed in this run. Ordinary shots4, raised-over-ally shots5, low-wall shots4; ally vitality100; full wall and low ceiling emitted no shots and consumed no ammunition.

Final suite: `python tools/run_tests.py`612/612; `python tools/validate_content.py --game .runtime/server`18XML/60Lua, resource and recipe checks passed; `git diff --check` clean. Documentation and untouched native screenshots saved under `docs/descendant-suit/raised-aim-*`.

Release: `output/MULTI-TOOL-V2-1.3.21-descendant-raised-aim-2026-11-18.zip`,129files,28,519,288bytes, SHA256 `c73ae381966512970eed27ca34803f510ccf52ee28504ef8bed10b943eb13eaa`. Every archive entry matched source, and every production source file matched both tested native copies. Previous1.3.20 archive hash confirmed unchanged. Private server exited; isolated client stopped. Work remains in the existing user workspace for review; no merge or publication performed.
