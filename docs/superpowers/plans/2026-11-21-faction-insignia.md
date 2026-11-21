# Faction insignia and visual character

**Goal achieved:** mini emblems and faction-specific surface designs for all six
no-headsets palettes, matching actual suit, arm and impeller parts.

- [x] Generate six transparent reusable insignia PNGs.
- [x] Generate 42 equipment PNGs (seven assets for each faction).
- [x] Keep the original chosen colors and compatible gameplay/recipes/identifiers.
- [x] Validate alpha and native frames; correct palette-specific UV coordinates.
- [x] Update guide, preview, complete prompt provenance and version 1.5.1.
- [x] Pass regression tests, independent review and package integrity checks.

Pirates: red, skull/crossed-wrench stencil and field repairs. Descendens: white,
original double-chevron/diamond emblem and precise ceramic panels. Coalition:
blue, native star/gear motif and standardized military finish. Separatists:
orange, native triangle/fist and industrial/hazard details. Church of Husk:
purple/ivory, native chalice/tendril motif and ceremonial engraving. Clowns:
green/yellow, native diamond/jester and small checker accents.

Native emblem references: installed Content/Map/factions.xml and
Content/UI/CampaignUIAtlas2.png. Pirate and Descendens signs are original mod art.
Built-in image generation was used throughout; chosen output PNGs were copied
byte for byte, with no script recoloring, resizing or compositing.

Review found that four generated atlases shifted some parts beyond old UV frames.
The final implementation caches per-palette frames in F.frame, uses the suit's
own closed/open helmet frames and the installed servo's link/emitter frames.
XML wearable rectangles match those same frames. Wider link frames compensate
explicit origins by half the dimension delta to retain local joint anchors.
All 78 isolated parts fit fully, checked using alpha >16 rather than counting
only pixels that happen to remain within an old frame. These checks, native XML
agreement, mixed-module draws and helmet animation have regression coverage.

The old rack crop also omitted 17.8 percent of visible Coalition suit pixels.
Twelve ContainedSprite definitions now use the whole texture, retaining boots.
The native Sprite loader supports omitted source rectangles:
https://github.com/FakeFishGames/Barotrauma/blob/master/Barotrauma/BarotraumaClient/ClientSource/Sprite/Sprite.cs

Final checks: 778 tests passed; content validation passed for 18 XML files,
55 Lua 5.2 modules, alpha PNGs, source rectangles and native recipe identifiers.
Independent follow-up review found no remaining blocking issues and separately
ran all 15 faction tests successfully. Gameplay and recipes remain unchanged;
only cosmetic frame selection changed in client.lua/factions.lua and item XML.
All 131 files of the original full System-Aegis package remain hash-identical.

The ZIP contains 159 files. Exact bytes, CRC and SHA256 are recorded in
.superpowers/insignia-release-verification.json and the adjacent ZIP SHA256 file.
In-game rendering/animation was not smoke-tested for this art release.
