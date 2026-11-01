# Mk II medical throughput

User reports mod effects still heal too slowly after 1.2.5. The shared 7.5
strength/s budget divides across all injuries; 200 strength needs at least
26.7 seconds even without ongoing illness. Increase Mk II ordinary healing
to20/s (4x basic, 2.67x previous) for all automatically classified mod effects.
Keep unit price .125%, basic5/s and anatomy1.5x. Split the configuration for
ordinary treatment and anatomy progress so a medical buff does not silently
make limbs regrow in2.5s. No optional mod becomes required.

Alternative: multiply all healing including anatomy4x; rejected because the
reported issue concerns lingering mod afflictions and current anatomy timing
already restores a leg in6.7s. No change to the classification of buffs.

- [x] Verify regression for unknown/NT effects, fixed prices and anatomy timing.
- [x] Set separate ordinary/anatomical multipliers and update native probes.
- [x] Run native NT delayed amputation, profile checks and idle control.
- [x] Update documentation/version1.2.6 and verify release ZIP.

Evidence:176/176 regressions; native NT profiles6/6 including two100-strength
injuries cured in10s at25% total cost. Live delayed amputation16s: no hit debit,
leg restored, fracture/arterial cut fully cured, alive100 vitality, energy58.60%.
Healthy NT idle30s retained100% power. XML/Lua/native recipe validation passed;
ZIP has63 files byte-identical to production source, no test fixtures. Native
medical modules byte-identical to packaged source. Private server closed.
