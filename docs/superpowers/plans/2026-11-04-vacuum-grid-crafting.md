# Aegis backpack storage and crafting

User requirements: cabinet storage, fabrication from a worn backpack and from
a backpack in a linked cabinet, stack withdrawal, icon grid with hover names,
no Drop button or technical entity number in the pack selector.

Implementation choices: use native mobilecontainer cabinet slots and native
fabricator ingredient collections; extend personal inventory discovery without
changing world links. Keep the existing real item/page storage. Display 8×5
icon cells per page. Withdraw at most the selected 100-item group, respecting
native inventory capacity and preserving item instances and nested contents.

1. Add regression tests for stack identity/capacity, cabinet authorization,
   ingredient ownership/locks/busy transactions, icon metadata and 40-cell pages.
2. Add mobilecontainer classification and accessible cabinet-pack contexts.
3. Add worn-backpack fabrication support and verify genuine ingredient use.
4. Replace the textual list and Drop action with selectable icons and shared
   Take one / Take stack buttons. Keep detailed instances accessible separately.
5. Run all tests, native GUI/cabinet/fabrication checks, review and package.

Review focus: stale selections, partial capacity, foreign/locked inventories,
pending salvage, duplicate ingredients, multiplayer authority and native icon
fallbacks. Do not expose items globally or fabricate copies of materials.
