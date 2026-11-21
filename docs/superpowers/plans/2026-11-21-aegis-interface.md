# System Aegis interface and equipment presentation

User authorized: public name System Aegis, conical flashlights, complete protection
UI redesign, collapsible combined multitool/suit controls, clear enabled states,
and no large shield cartridge overlaid on the existing weapon sprite.
User clarified: protection is per item type and includes future collected copies.

Design: keep authoritative existing item slots, rules and native CustomInterface
network events. One client AEGIS panel hosts tool controls and the suit arm section;
collapse hides both and leaves one compact status tab. Explicit mode buttons and
textual ON/OFF states accompany colors. Sonar retains its independent small map.
Native hidden checkbox selection relays original safe network events; no direct
client mutation of server weapon state and no new control protocol.

Protection: searchable six-row catalog with named types and independent controls
for protection, collection, and explicit unblock. No global edit mode, symbolic
badges or mode-dependent tile clicks. Direct protection action from a selected
stored type. Preserve saved tags and server guards against busy jobs/unauthorized
changes; protected children still protect whole containers and future items.

Lighting: use actual native lightcone textures (Directional alone changes shadow
calculation, not the light bitmap). Narrow beam height. Replace unsupported coneangle
on the composite tool; use a native configured cone component for suit helmet light.
Retain power/aim requirements and small tool/muzzle effect glows.

Tasks:
1. Add regression coverage for branding, hidden contained cartridge, light geometry,
   shared panel collapse/composition/flags/native events/cleanup and protection rules.
2. Correct content settings and implement shared panel with existing control backend.
3. Rebuild protection catalog controls/pagination and test existing storage behaviors.
4. Localize PL/EN, update usage guide and interactive preview, publish cleanly named
   archive System-Aegis-1.6.0.zip without changing the original full source package.
5. Run all automated tests/native content validation, independent review and native
   runtime UI smoke test if isolated runtime is usable, then verify archive bytes.

Review focus: multiplayer toggles remain authoritative, collapsed panels accept no
hidden clicks, empty/missing modules have clear disabled labels, protection toggles
never alter collection rules, stale selection/pagination cannot act on another kind,
light follows facing/aim/rotation and turns off without power, reload clears widgets.


Implemented and verified: 857 tests pass, native content validation passes for
18 XML and59 Lua 5.2 modules. Independent focused review found no blocking issues.
Native checkbox Selected setter, CustomInterface event handling and LightSource
constructor were checked against engine sources. DrawHudWhenEquipped stays true
for server authorization; only client ShouldDrawHUD is suppressed for these tools.
All163 archive entries match source bytes and CRC; public name/root are clean.
Original full package's131 files and all existing bitmap/audio assets are unchanged.
No live game UI trial was performed for this release.
