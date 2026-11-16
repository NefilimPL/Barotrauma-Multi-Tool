# Asset sources

## Folded suit item — 16 November 2026

`MULTI-TOOL-V2/Assets/DescendantSuit/packed-suit.png` is a new transparent sprite generated with built-in `image_gen` (no API/CLI fallback). Original `exec-648f1fd1-b312-49b4-bb01-a39ce6964d20.png` was copied unchanged from the Codex generated-images directory. RGBA 1635 × 962; the native XML selects source rectangle `96,173,1428,586` and item scale 0.06. These metadata settings do not resample or repaint the raster. Worn atlas/scales are independent. [Full prompt and source path](packed-suit-prompt.txt).

## V2 selected atlas — 16 November 2026

The current suit and browser preview use `MULTI-TOOL-V2/Assets/DescendantSuit/suit-v2.png`. Generated with the built-in `image_gen` tool, not the CLI/API fallback; copied unchanged from `exec-264932a8-bfaa-4036-8dce-818c72b979a6.png`. Inspection: 1536 × 1024 RGBA, alpha 0..254, 1,144,640 pixels with zero alpha. No scripted colour-keying, repainting or background removal. The JSON/Lua source rectangles are rendering metadata only.

The [full production prompt](suit-v2-prompt.txt) specifies sixteen separated components in a four-by-four atlas, a slim graphite/crimson/cyan futuristic suit, covered cabling and compact servo links, with a genuine transparent background. The old brass/ivory art below remains archival and is not selected by V2.

In-game V2 pulse shots reference the base game's `WEAPONS_laserGunShot1.ogg`, `tracerpulselaser`, `muzzleflashpulselaser` and `weldspark` resources. These are referenced, not redistributed. The additional browser `pulse.ogg` is original procedural synthesis, reproducible with `python tools/generate_descendant_audio.py --only pulse`.

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

- All eight audio effects are original procedural synthesis from `tools/generate_descendant_audio.py`, encoded to mono Vorbis with ffmpeg. No external audio samples or copyrighted dialogue were used.
- The native pressure undersuit is referenced from the installed base game at `Content/Items/Diving/Abyss_DivingSuit.png`. It is not redistributed here.
- The browser preview adds procedural particles and simple demonstration targets; those targets are not new in-game item textures.
