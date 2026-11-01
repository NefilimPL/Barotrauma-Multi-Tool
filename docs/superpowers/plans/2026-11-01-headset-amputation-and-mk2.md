# Amputation costs and Mk II healing

User requests fixing battery exhaustion after NT limb loss and faster Mk II
healing. Execute inline; preserve optional medical dependencies and real costs.

Evidence: a real delayed NT gate_ta_ll amputation on the private C# NT server
produced two shield hit debits of50% in the same tick, exhausting the cell.
These are secondary status effects, not the configured12.5%/10s regeneration.
Previous NT probes were synchronous and missed the delayed injury cascade.

- [x] Track native StatusEffect.GetMultipliedAffliction source/target/result;
  self-generated physiological effects bypass impact absorption and remain
  subject to gradual paid healing. External attacks/environment still absorb.
  Tests cover provenance, mixed damage, reused afflictions and expiry.
- [x] Give Mk II 1.5x medical rate and job progress with unchanged per-unit
  and total anatomy costs. Basic model stays5strength/s and10s per limb.
- [x] Group NT limb markers and matching severed native joints into one job
  when both represent the same amputation; preserve unrelated severance.
- [x] Run delayed NT amputation through real time, compare both versions,
  test native attacks still cost power, run regressions and review.
- [x] Update documentation/version1.2.5 and package checked production files.

Ruling: use source identity rather than attacker=nil. World hazards and attacks
can legitimately have no attacker; the native status-effect source identifies
physiological consequences across optional mods. No free healing is introduced.
Work in the existing feature checkout and private runtime, no game-install edits.

Review found native multi-limb application reuses the same Affliction reference;
provenance must survive every limb until replacement or the next frame. Added
red/green regression. Real native profile tests also exposed numeric LimbType
values, fixed with enum comparisons and a second red/green regression.
Final NT delayed test: no hit debit, limb12.5%, energy72.67% after16s, alive100
vitality. Native profiles4/4, mechanics9/9, NT8/8; unit/regression175/175.
Healthy live NT idle30s retained100% energy and vitality100. Content validation
passed11XML/24Lua with native recipes. ZIP1.2.5 contains63 production files,
all byte-identical to source; tested medical Lua matches package. Server closed.
