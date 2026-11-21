# System Aegis faction colors

> Use superpowers:executing-plans for implementation and requesting-code-review at completion.

**Goal:** Selectable/craftable faction color versions of the modular suit and its servo/impeller modules, preserving matched deployed visuals and inventory/rack images.
**User choices:** Pirates red; Descendens white; Coalition blue. Include remaining game factions. User explicitly chose newly generated textures over script recoloring.
**Additional palette decisions:** Separatists orange, Church of Husk purple, Children of the Honkmother green/yellow, announced in chat.
**Architecture:** Keep existing red prefab identifiers as the pirate/default version. Add five explicit item variants and module variants with identical mechanics, recipes and costs. A shared family module recognizes colored suits/modules, indexes every suit prefab, and selects per-item/deployed module art on clients. Native XML provides body, packed/rack and inventory sprites; Lua selects the matching arm and fan assets. No restriction by player faction/reputation.
**Art:** Built-in image generation, one recolor request per existing PNG and faction (35 requests). Preserve source atlas cell positions, geometry and alpha; no script pixel recoloring. Raster inspection and XML/coordinate metadata updates are allowed, but existing art files must not be modified.

- [x] Generate and inspect art for all five additional palettes, retaining original red for pirates.
- [x] Add failing family/compatibility, item indexing, per-module rendering selection and content/balance tests.
- [x] Add faction data, prefabs, localizations, recognition/indexing and cached client sprite selection/disposal.
- [x] Check all generated atlas rectangles and references; write source metadata and exact prompts.
- [x] Full test suite, game-content validation, independent review and ZIP1.5.0 with digest.

## Review focus

Existing red equipment still works and its state survives. Every new suit is discovered by authority and clients; batteries/ammo/sonar/repairs keep working. Mixed module colors render from the installed module, with matching inventory icons. Cached faction sprites are bounded and disposed on reload. No balance variation or headset content; native source rectangles remain valid.


## Completion evidence

- User explicitly selected all remaining game factions and generated image edits, not script recoloring.
-35 built-in generation calls completed; every output copied byte-for-byte, original assets untouched.
- All five new rig atlases retain1536x1024 canvas; runtime/body crop rectangles remain valid. Two window textures differ by one border pixel, outside every used crop.
- RED: new faction rules/content/render tests failed before implementation. GREEN: all11 pass.
- Full suite:774 tests passed. Validator:18 XML/55 Lua5.2 modules, all referenced assets and recipes checked against installed game.
- Independent code review found no actionable issues, confirmed normalized prefab equivalence and independently ran11 faction tests.
- ZIP1.5.0 verified against153 source files, CRC/manifest/absence of headset content checked; SHA-256 saved beside ZIP.
- All original131 full-mod files and every original red/neutral variant asset remain byte-identical.
- Palette preview links and source/prompt documentation verified.
- Actual in-game rendering was not exercised; no live gameplay claim is made.
