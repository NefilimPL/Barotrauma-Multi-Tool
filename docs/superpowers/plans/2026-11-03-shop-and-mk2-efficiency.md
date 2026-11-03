# Shop availability and Mk II efficiency

User clarified base prices: combat multitool <=2000mk, basic headset500mk,
MkII1000mk. Enable purchase of all five mod items in standard campaign stores,
with actual minimum stock. Preserve existing57/1300mk base prices for old tools.
Use existing XML Price definitions and native shop generation; no medical
dependency or custom purchasing flow. Native reputation/difficulty pricing
continues to apply to these base prices.

MkII costs60% less energy for treatment, anatomical regeneration, impact and
pressure. Keep ordinary20strength/s and current anatomy times. One .4 cost
multiplier, applied before affordability and partial-hit calculations. Basic
headset rates/costs stay unchanged. This gives2.5x treatment per full cell.
Alternative of increasing healing speed rejected: report requests less energy
use; efficiency buff improves total healing without raising instantaneous drain.

- [x] Verify regressions for partial healing/payment, attacks, basic model.
- [x] Apply MkII cost multiplier to every paid path.
- [x] Enable prices/stock for all items and update release documentation.
- [x] Run native NT recovery and shop-definition checks, validate/package1.2.8.

Final:181 regressions PASS; native prices5/5 (40 store offers), profiles6/6,
mechanics9/9, active NT knockout8/8 with11 physiology ticks per patient.
NT unconsciousness retained94.7258% power after recovery; healthy20s idle100%.
XML/Lua/native recipe validation PASS. ZIP63 exact production files, no tests;
native tested medical code/store XML byte-identical to source. Server closed.
