# Headset idle and visual regression fix

User report: equipping Mk II immediately flickers red and consumes power on
the submarine; worn graphic is huge and the shield is a thin red line.
Clarification: red flicker itself was interpreted as damage; determine the
actual debit before changing damage interception.

- [x] Reproduce healthy NT CS idle consumption and record every treated ID,
  current value, desired value, and actual energy debit.
- [x] Fix only unintended treatment of healthy/mechanical states, add a
  regression for the discovered state, and expose recent debit reasons.
- [x] Regression: worn headset texture must have a human-head-sized native
  scale independent of Item.Scale; fix both XML sprites.
- [x] Replace thin outline with a translucent filled field and broad impact
  glow; verify client renderer and keep low-energy flicker and bounded audio.
- [x] Suppress the separate wrench compression warning without editing art.
- [x] Run full suite, native idle/attack/pressure probes, asset validation;
  package 1.2.1 and document measured behavior and remaining limits.

No medical mod becomes mandatory. Do not modify the user's installed mod
or game files. Use the current feature checkout and disposable runtimes.

Result: healthy NT idle stayed at 100% energy and 100 vitality; no speculative health-policy changes. Exact drain diagnostics added. Native GPU remains unverified; SVG/PNG show production geometry on an illustrative figure. Suite132/132, native9/9 + NT6/6, ZIP matches59 production files.
