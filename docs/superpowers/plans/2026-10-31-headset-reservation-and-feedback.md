# Headset battery reservation and visible feedback

User specifies replacement at 10%, no passive drain, visible red impact /
blue healing light, audible low power and stronger paid shield hits with an
original resonant science-fiction impact sound.

Evidence before implementation: installed mod is 1.2.3. Its headset-specific
AI refuses replacement at >=30%, but CombatTool.ai's separate candidate scan
allows cells inside headsets. Native TakeItem/containment also need reservation.
Current audio intentionally suppresses non-hit low-tier warnings, explaining
missing alarms during healing/pressure. Existing GPU tests verify calls rather
than a visible frame. Exact idle debit still needs a trace.

- [x] Run unchanged 1.2.3 with physical isolated copies of all 13 active mods;
  record every actual idle debit and capture an actual game frame.
- [x] Reproduce/fix other AI taking headset cells; reserve them for headset
  replacement and set threshold <=10%, keeping a working cell until swap.
- [x] Identify actual idle reason and fix its classification or source; retain
  paid real regeneration and pressure. Never suppress arbitrary real wounds.
- [x] Verify visible diode pixels and actual audio playback; add low/critical
  alarms independent of damage plus stronger per-hit energy and sound.
- [x] Synthesize original resonant impacts without movie recordings; update
  tests/docs, review and package 1.2.4 after native final checks.

Execution inline, current feature branch; only workspace copies are modified.

Result: actual repeated heal:serversidelua reproduced with Real Sonar and
confirmed by user's screenshot. Explicit preservation removes the real cost.
Native final client4/4 reservation/flag, server3/3 reservation (flag absent),
client real attack/heal/draw4/4, native7 audio channels, safe idle100/100/30s.
Server9 mechanics+8 NT+3 insertion passed;164 regressions pass.
Ruling: physical copies must be in client LocalMods discovery root. Mere
external package paths were ignored; actual EnabledPackages is recorded now.
Native screenshots and pixel counts validate visible colors. Unqualified
generic overload signature avoids differing client/server assembly names.
Reviewer checked native API names; its turn ended at usage limit without a
completed final review. Remaining overload/bot-fixture issues were found and
corrected through native tests. No new delegation required.
Final: ZIP63 production files byte-for-byte matches source. All7 unique OGG
decode. Final Lua matches both native runtime copies. Native alarm driver
20/10/0 passed with no power cost. Private test processes stopped.
