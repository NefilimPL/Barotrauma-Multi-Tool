# Headset LED and idle power correction

User explicitly replaces the entire body field with a tiny red light at the
headset's existing diodes. Energy remains paid for absorption, pressure and
real regeneration; no passive cost.

- [x] Remove body geometry; anchor small flashes to measured diode pixels in
  the native worn sprite, following head rotation and mirroring.
- [x] Cover LED count, size, positioning, expiry and silent healing in tests.
- [x] Preserve normal NT immunity and tolerate healthy blood pressure instead
  of continuously forcing ideal physiology; retain real injury/anatomy costs.
- [x] Verify a longer idle trial, real healing/attacks and full regressions.
- [x] Update current previews/docs and package 1.2.2. Medical mods stay optional.

Existing `aegis_headset_status` remains available for unrecognized mod states.

Verification: 138 unit/regression checks, native 9 mechanic and 8 NT CS checks
passed. Native idle after patch: 30 seconds at full energy/health; previous
baseline 120 seconds. Read-only review identified helmet occlusion and a
vacuous client probe; both corrected. GPU rendering remains unverified;
the documented preview is a browser illustration of production draw commands.
