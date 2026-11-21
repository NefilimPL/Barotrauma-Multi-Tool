# Asset sources

## Original miniaturized pulse laser and soft beams — 1.3.20

The combat head directly references the base game's `Content/Items/Weapons/Turrets.png`: native RailSprite904,592,120,287, BarrelSprite779,592,125,333, and both ChargeSprites570,692,59,150 /642,692,59,150. Uniform scale0.11; origins include the original firing offset so the visible nozzle is anchored to the actual shot muzzle. No generated substitute or altered copy of these textures is used.

The pulse particle references the original `ParticleAtlas.png` sprite144,440,1,68, with original additive blending, color and0.4s lifetime. Only vertical initial size and vertical shrink rate are reduced by0.22; emitter scale1 preserves native ray length. Repair/tractor beams use the neutral feathered native trail130,383,225,40, tinted blue/orange. Native textures are referenced, not redistributed. [GPU evidence and validation](../AEGIS-BEAMS.md).

## Front-facing locker window correction — 1.3.19

`rack-window-v2.png` is a new762×2063 RGBA output from built-in `image_gen`, copied byte-for-byte from `C:/Users/kamil/.codex/generated_images/01a1e12e-c367-7941-a93a-422015faf3a7/exec-02621b4d-f2cc-4796-a4ce-c10e75cfdcb3.png`. The previous custom side-view suit was the edit target; the game's containers atlas was a composition reference. No native PNG is redistributed in the mod.

This replaces the old full-body side view behind the window with a large frontal helmet and partial torso fading into scratched dark glass. The XML source rectangle50,63,657,1742 selects the pane without margins and excess empty lower glass to match the physical size of native window sprites. The raster itself was not resized, repainted or background-removed. Vertical-holder source rectangles now omit the lower legs and boots. [Spec and prompt](rack-window-v2-prompt.txt); [native comparison](../AEGIS-RACK.md).

## Rack and independent impeller — 17 November 2026

Three new transparent PNGs generated using the built-in `image_gen` tool via the [imagegen skill](C:/Users/kamil/.codex/skills/.system/imagegen/SKILL.md), copied unchanged into `System-Aegis/Assets/AegisSuit`. No external image API, scripted repainting, cropping, background removal or raster resizing was used. XML source rectangles, origins and draw scales are rendering metadata.

| Production asset | Dimensions | Original built-in output |
|---|---|---|
| `rack-suit.png` | 887 × 1774 | `exec-104423c7-581a-4f21-8d47-820e293ccc7f.png` |
| `impeller.png` | 1254 × 1254 | `exec-64572d4c-baeb-4933-b2ff-fcdc5a31b1e6.png` |
| `impeller-housing.png` | 1254 × 1254 | `exec-d2c62826-fcbe-4037-a824-b920bb14c56a.png` |

Original directory: `C:/Users/kamil/.codex/generated_images/01a1e12e-c367-7941-a93a-422015faf3a7/`.

Generation briefs: slim upright empty graphite/crimson futuristic pressure suit in right-facing side view, with a compact folded backpack and no long projecting manipulator, for a suit rack; separately, an isolated four-bladed curved metal rotor and hub with alpha gaps and no housing; separately, an empty matching metal/red circular housing with a small cyan side module, transparent center and no blades. All requested true transparent backgrounds, consistent side-view game art, no text, logos or watermark. These are briefs, not verbatim transcripts of generation prompts.

Only `impeller.png` rotates. Housing remains aligned to the wearer. The native game's `bubbles` particle is referenced, not redistributed.

## Folded suit item — 16 November 2026

`System-Aegis/Assets/AegisSuit/packed-suit.png` is a new transparent sprite generated with built-in `image_gen` (no API/CLI fallback). Original `exec-648f1fd1-b312-49b4-bb01-a39ce6964d20.png` was copied unchanged from the Codex generated-images directory. RGBA 1635 × 962; the native XML selects source rectangle `96,173,1428,586` and item scale 0.06. These metadata settings do not resample or repaint the raster. Worn atlas/scales are independent. [Full prompt and source path](packed-suit-prompt.txt).

## V2 selected atlas — 16 November 2026

The current suit and browser preview use `System-Aegis/Assets/AegisSuit/suit-v2.png`. Generated with the built-in `image_gen` tool, not the CLI/API fallback; copied unchanged from `exec-264932a8-bfaa-4036-8dce-818c72b979a6.png`. Inspection: 1536 × 1024 RGBA, alpha 0..254, 1,144,640 pixels with zero alpha. No scripted colour-keying, repainting or background removal. The JSON/Lua source rectangles are rendering metadata only.

The [full production prompt](suit-v2-prompt.txt) specifies sixteen separated components in a four-by-four atlas, a slim graphite/crimson/cyan futuristic suit, covered cabling and compact servo links, with a genuine transparent background. The old brass/ivory art below remains archival and is not selected by V2.

In-game V2 pulse shots reference the base game's `WEAPONS_laserGunShot1.ogg`, `tracerpulselaser`, `muzzleflashpulselaser` and `weldspark` resources. These are referenced, not redistributed. The additional browser `pulse.ogg` is original procedural synthesis, reproducible with `python tools/generate_aegis_audio.py --only pulse`.

## First prototype — archived sources

Generated with the built-in `image_gen` tool on 15 November 2026; the CLI/API fallback was not used. Source sheets were copied into the mod unchanged. Both PNGs are 1536 × 1024 RGBA, with an inspected alpha range of 0..254. Their brown RGB values in transparent pixels are not an opaque background and must not be removed with color-keying.

## Selected files

- `suit.png`: built-in output `exec-3b71d9c0-4e9e-4cc5-8896-15ba75d328f1.png`, a transparency-focused revision of the first suit sheet.
- `arm.png`: built-in output `exec-434706c2-7de3-43d3-a417-0b8fab876bd7.png`, generated using the selected suit as its style reference.

## Prompt set

The suit generation requested a landscape transparent 2D side-view game asset sheet for a Barotrauma mod: an abyssal pressure suit with one additional backpack-mounted industrial servo manipulator; closed and retracted helmet versions; caged impellers; ivory pressure plates, graphite seals, gunmetal mechanisms and copper joints; separately arranged torso, helmet, human-arm, leg, boot, backpack and propulsion components. Constraints: no lettering, no background, no scenery, no external shadows, generous gutters, no extra human limbs and no copied franchise characters or insignia.

The selected suit revision requested: "Preserve the suit designs, all individual mechanical pieces and their layout. REMOVE ALL OF THE DARK BROWN / GRAY BACKGROUND AND ALL SHADOW / VIGNETTE / ATMOSPHERIC AREAS between and around the sprites. Output a genuine alpha-transparent PNG, no painted backdrop, no checkerboard drawn into image. Empty areas must be fully transparent including the opening in the retracted helmet and gaps between the servo arm links."

The companion generation requested a new matching isolated game sprite parts sheet, without another assembled suit: separate pivot base, proximal link, distal link, flexible wrist and claw/laser head; identical red, blue and orange emitter variants; independent straight combat, repair and tractor beam strips and contact effects; four frames of a caged rotating impeller. Constraints: orthographic side view, consistent scale/materials, rounded unobstructed pivots, transparent gutters, no labels, no characters or scenery.

The original prompts specified transparent output. Subsequent file inspection confirmed alpha transparency; no scripted background removal or raster repainting was performed. Source rectangles and layering are implementation metadata, not modifications to the sheets.

## Other resources

- All eight audio effects are original procedural synthesis from `tools/generate_aegis_audio.py`, encoded to mono Vorbis with ffmpeg. No external audio samples or copyrighted dialogue were used.
- The native pressure undersuit is referenced from the installed base game at `Content/Items/Diving/Abyss_DivingSuit.png`. It is not redistributed here.
- The browser preview adds procedural particles and simple demonstration targets; those targets are not new in-game item textures.
