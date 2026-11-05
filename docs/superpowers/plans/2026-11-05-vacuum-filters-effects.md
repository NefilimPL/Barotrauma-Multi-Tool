# Vacuum filters, single-stack withdrawal and effects

**Goal:** Withdraw one native inventory stack; add FastLoot-style saved pickup
exclusions, category browsing, explicit trash, suction/salvage audio and smooth flow.

**Architecture:** Preserve actual entities, native inventory limits and authoritative
server mutations. Store per-prefab exclusions in backpack tags (save-compatible).
Use the existing 40-cell panel for inventory and a paginated prefab filter catalog;
category and search compose in either mode. Advance the wire protocol for new fields.

**Implementation choices:** A stack fills exactly one native slot, including a partial
existing stack; large unstackable items transfer once. Filters reject a whole portable
container if any descendant is excluded. Trash deletes the selected displayed group
(one instance in details), including contents, after an inline second confirmation;
no blanket deletion. Smooth the current sprite animation by frame interpolation and
continuous inward flow. Provide original generated mono OGG motor/grinder sounds.

- [x] Reproduce stack spreading; regression tests for one slot, incompatibility,
  partial/full slots and real-item conservation. Implement one destination slot.
- [x] Add filters/category module and tests for saved tags, nested exclusions,
  prefab catalog, category/search composition and invalid network requests.
- [x] Add authoritative trash with busy/ownership guards and descendant removal;
  extend protocol and panel with category, filter mode and confirmation.
- [x] Add audio, client/server salvage activity and interpolated suction visuals;
  test stop/reset, remote activity and deterministic continuous flow.
- [x] Run full suite/content validation and isolated native checks; review, document
  evidence, bump version to 1.3.4 and build verified ZIP.

Review focus: native per-slot limits and quality/condition compatibility, filtering
nested crates, stale network snapshots and trash confirmations, reserved salvage
sources, saved tag preservation, sound channel cleanup and graphics/audio errors.

Completed: 362 automatic tests; 9 native SP checks; 6 real client/server checks,
plus native fixture and final entity conservation on server (734 = 725 + 8 + 1).
Native category flags arrived as numbers; corrected using the actual enum masks
after a failing regression, then all checks passed. Unicode text damage during
the initial shell edit was corrected through apply_patch. Final review clean.
