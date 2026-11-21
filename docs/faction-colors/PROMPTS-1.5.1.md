# System Aegis 1.5.1 — emblematy i detale frakcji

Narzędzie: wbudowane image generation. Sześć emblematów i 42 edycje wyposażenia.
Pliki wynikowe skopiowano bez zmiany pikseli, rozmiaru ani kanału alfa.

Wzorce czterech znaków gry: `Content/Map/factions.xml` oraz
`Content/UI/CampaignUIAtlas2.png` z lokalnej instalacji Barotraumy.
Koalicja: 143,523,94,113; Separatyści: 268,523,105,113;
Kościół Łuski: 402,523,96,113; Klauni: 0,523,118,113.
Piraci (czaszka i klucze) oraz Descendens (szewrony i romb) to autorskie znaki moda.

Każda edycja otrzymała obraz wyposażenia jako pierwszą referencję
i odpowiadający emblemat jako drugą. Geometrię oraz przezroczystość
sprawdzono po generowaniu. Kadry UV czterech palet dopasowano do faktycznego
położenia części bez przesuwania pikseli. XML i `F.frame` w `factions.lua`
korzystają ze zgodnych współrzędnych. Statystyki i receptury nie były zmieniane.

## Emblemat — pirates

Plik: [Assets/Factions/emblems/pirates.png](../../System-Aegis-No-Headsets/Assets/Factions/emblems/pirates.png)

SHA256: `c2fe8cbe030a37840b0f5ce03a0d87087e5d0e4efbf42f1d10d3150d57753710`

```text
Use case: logo-brand / precise emblem reference. Create ONE small faction uniform insignia as a clean production 2D decal asset. Flat opaque ivory-white/silver symbol on genuine transparent alpha background, sharp simple contours, recognizable at tiny size, centered on square canvas with a clear margin, no lettering, numbers, gradients, scene, background, mockup, shadow, glow, border or invented extra decoration. A compact pirate skull above TWO crossed mechanic's wrenches, simple stencil cutouts for the eyes and nose, non-gory, rugged utilitarian pirate engineering badge. This is an original mark for the red pirate Aegis equipment.
```

## Emblemat — descendens

Plik: [Assets/Factions/emblems/descendens.png](../../System-Aegis-No-Headsets/Assets/Factions/emblems/descendens.png)

SHA256: `0c14a7a73da577e9ac5a866223e787da8d2617cc8ff03ce6c1914c4695d90110`

```text
Use case: logo-brand / precise emblem reference. Create ONE small faction uniform insignia as a clean production 2D decal asset. Flat opaque ivory-white/silver symbol on genuine transparent alpha background, sharp simple contours, recognizable at tiny size, centered on square canvas with a clear margin, no lettering, numbers, gradients, scene, background, mockup, shadow, glow, border or invented extra decoration. An original futuristic Descendens faction badge for white high-tech Aegis equipment: two strong descending V-shaped chevrons around a small vertical diamond, symmetric angular geometry, precise minimalist engineering insignia, readable as one compact mark. No letters and no additional heraldry.
```

## Emblemat — coalition

Plik: [Assets/Factions/emblems/coalition.png](../../System-Aegis-No-Headsets/Assets/Factions/emblems/coalition.png)

SHA256: `51fad8a6c7c70cd02d70bb990fc3323c32dc67480516d0832b8a27984f29d535`

```text
Use case: logo-brand / precise emblem reference. Create ONE small faction uniform insignia as a clean production 2D decal asset. Flat opaque ivory-white/silver symbol on genuine transparent alpha background, sharp simple contours, recognizable at tiny size, centered on square canvas with a clear margin, no lettering, numbers, gradients, scene, background, mockup, shadow, glow, border or invented extra decoration. The supplied image is the native Barotrauma UI atlas. Reproduce only the actual COALITION faction symbol at source rectangle x143 y523 width94 height113: the stylized FOUR-POINT COMPASS STAR over a gear/cog. Faithfully retain its existing geometry and relationship of star and cog. Extract this specific faction glyph concept as one standalone transparent decal. Ignore every other symbol in the atlas; do not add shields, eagles, text or a different emblem.
```

## Emblemat — separatists

Plik: [Assets/Factions/emblems/separatists.png](../../System-Aegis-No-Headsets/Assets/Factions/emblems/separatists.png)

SHA256: `2e3594f680d6a13969d9b2d7e42a0cb4cc79747342d76fadf32fdf1b817c150f`

```text
Use case: logo-brand / precise emblem reference. Create ONE small faction uniform insignia as a clean production 2D decal asset. Flat opaque ivory-white/silver symbol on genuine transparent alpha background, sharp simple contours, recognizable at tiny size, centered on square canvas with a clear margin, no lettering, numbers, gradients, scene, background, mockup, shadow, glow, border or invented extra decoration. The supplied image is the native Barotrauma UI atlas. Reproduce only the actual SEPARATIST faction symbol at source rectangle x268 y523 width105 height113: the bold DOWNWARD POINTING TRIANGLE with a RAISED CLENCHED FIST inside. Faithfully retain its existing geometry. Extract this specific faction glyph as one standalone transparent decal. Ignore other symbols; do not add stars, shields, text or a different emblem.
```

## Emblemat — husk

Plik: [Assets/Factions/emblems/husk.png](../../System-Aegis-No-Headsets/Assets/Factions/emblems/husk.png)

SHA256: `cf6f976a3dd651ca884ae3c2b08e2edfa0ed76f2df63f6a5066a67731103648d`

```text
Use case: logo-brand / precise emblem reference. Create ONE small faction uniform insignia as a clean production 2D decal asset. Flat opaque ivory-white/silver symbol on genuine transparent alpha background, sharp simple contours, recognizable at tiny size, centered on square canvas with a clear margin, no lettering, numbers, gradients, scene, background, mockup, shadow, glow, border or invented extra decoration. The supplied image is the native Barotrauma UI atlas. Reproduce only the actual CHURCH OF HUSK faction glyph at source rectangle x402 y523 width96 height113: the symmetrical chalice/trident-like cult symbol with three rising curved tendril/prong shapes and its small horizontal stepped pedestal. Faithfully retain this native shape. Ignore every other glyph, no skull, no letters, no additional frame. Output only this specific standalone transparent faction symbol.
```

## Emblemat — clowns

Plik: [Assets/Factions/emblems/clowns.png](../../System-Aegis-No-Headsets/Assets/Factions/emblems/clowns.png)

SHA256: `5ec2a479d88f83172f25b1f059b161c576d4b33bc86d992e231b3aa3f5194da5`

```text
Use case: logo-brand / precise emblem reference. Create ONE small faction uniform insignia as a clean production 2D decal asset. Flat opaque ivory-white/silver symbol on genuine transparent alpha background, sharp simple contours, recognizable at tiny size, centered on square canvas with a clear margin, no lettering, numbers, gradients, scene, background, mockup, shadow, glow, border or invented extra decoration. The supplied image is the native Barotrauma UI atlas. Reproduce only the actual CHILDREN OF THE HONKMOTHER / CLOWN faction symbol at source rectangle x0 y523 width118 height113: the tilted square/DIAMOND OUTLINE enclosing the stylized JESTER/CLOWN FACE with its small hat/horn shapes. Preserve the native faction glyph geometry. Do NOT use the separate grinning face in a star located farther right in this atlas. Output just the exact diamond-and-clown faction motif as a transparent standalone decal.
```

## clowns/atlas

Plik: [Assets/Factions/clowns/suit-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/suit-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/suit-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-add2eebc-9630-4fdc-926f-60c0851c9a68.png`.

SHA256: `cbe72a8ca93a5237d7f8e340d461a49967f5acbbce53e155207d9f7c4c31b438`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. This is a RIGGED ATLAS. Every separate part must remain in its existing cell at its existing pixel coordinates. Add a tiny badge on the painted TORSO plate (cell x113,y5,w179,h251), and one on the upper-arm shoulder plate (cell x120,y263,w144,h240). Add matching miniature marks on the gripper housing and fan housing cells if visible. Keep ALL other cells, BOTH helmet states and every empty gap unchanged. DO NOT rearrange, resize, move, reflow, merge or delete any part.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## clowns/housing

Plik: [Assets/Factions/clowns/impeller-housing.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/impeller-housing.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/impeller-housing.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-3c581cec-25c7-43a4-864d-ed483745916f.png`.

SHA256: `b765ca257035cf1b560ad07ddbb399f567f1fdb82c1dad0f2414ab30e9aa33c1`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## clowns/impeller

Plik: [Assets/Factions/clowns/impeller-module.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/impeller-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/impeller-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-82490523-326e-4d20-a24a-c67213c2131f.png`.

SHA256: `13de5e15d6d4e57f19b00efc61b4125c1fd14b7a7514531fba0cbc08e4774add`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## clowns/packed

Plik: [Assets/Factions/clowns/packed-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/packed-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/packed-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-d3db79ef-868e-49d5-91b2-e6a5e6263fef.png`.

SHA256: `1370dd4a90b3cc281db4e9b3954c1fd68160548c25aa052d2b6c3859e6abf157`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 1635x962 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## clowns/rack

Plik: [Assets/Factions/clowns/rack-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/rack-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/rack-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b169f989-234e-4f04-826c-b52940fca82b.png`.

SHA256: `bc3d0a20e0eedf127ebc71676fc5a394a20bf5bbca254a62b12974bd27c46f02`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 887x1774 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## clowns/servo

Plik: [Assets/Factions/clowns/servo-module.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/servo-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/servo-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-8c30b357-418b-4793-9f1a-ab1a40f28dc3.png`.

SHA256: `3e2e2527a2c4a38cc113fa2d6d2baa6390edaa67162eda0d2a2942c633935049`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## clowns/window

Plik: [Assets/Factions/clowns/rack-window-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/clowns/rack-window-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/clowns/rack-window-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f913f841-008d-47c3-88db-7288f071a95f.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-259dbc43-4cea-4bd0-b246-784c79d37a97.png`.

SHA256: `884a4ea1a685fe5758af0fd59ab65a56f245b02819eabffbdbd2bfb60d6a65dc`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: GREEN and YELLOW Children of the Honkmother armor: playful small checker/diamond paint inlays and slightly offset yellow accent bands within existing plates. Retain the practical sealed suit and mechanical geometry, not a cloth clown costume. No extra bells, nose, hats or props. Add small high-contrast native diamond-outline jester/clown badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 763x2062 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/atlas

Plik: [Assets/Factions/coalition/suit-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/suit-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/suit-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-e4bd5341-3de6-46e9-9144-9e2aae3e7e52.png`.

SHA256: `4e351dc836d07b62c0e1c09a8dd93d7d26afae2a5cf5de7b7f2e4a4b18021b50`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. This is a RIGGED ATLAS. Every separate part must remain in its existing cell at its existing pixel coordinates. Add a tiny badge on the painted TORSO plate (cell x113,y5,w179,h251), and one on the upper-arm shoulder plate (cell x120,y263,w144,h240). Add matching miniature marks on the gripper housing and fan housing cells if visible. Keep ALL other cells, BOTH helmet states and every empty gap unchanged. DO NOT rearrange, resize, move, reflow, merge or delete any part.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/housing

Plik: [Assets/Factions/coalition/impeller-housing.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/impeller-housing.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/impeller-housing.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-8c726c43-b16e-46c5-bc66-56c8459f4b59.png`.

SHA256: `afd88426d7da116f7467a0105fecc65a0999646a372315f033b2fdce070a0936`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/impeller

Plik: [Assets/Factions/coalition/impeller-module.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/impeller-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/impeller-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-70b18d5a-8f8f-485f-84d2-865a109679d9.png`.

SHA256: `99fd3aef61c5fb9552190dd9d2061ba33dfb7b480b790bc82a8a90b68f78d6fd`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/packed

Plik: [Assets/Factions/coalition/packed-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/packed-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/packed-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-974c5666-acde-4ebb-94ce-991ccfa02af3.png`.

SHA256: `b15bf6c66a31cf4c01fb96f4f0af1eafea7d0377d00da1ee1c4eb58d8a6943a2`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 1635x962 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/rack

Plik: [Assets/Factions/coalition/rack-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/rack-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/rack-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-d7955297-7ade-403c-95b5-093d95c20643.png`.

SHA256: `3ad0351261576a20e8c3382981053d5cc04fc75f6fced5450b3d132fa7744b2b`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 887x1774 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/servo

Plik: [Assets/Factions/coalition/servo-module.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/servo-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/servo-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-265fc844-4803-4ac4-b24a-1ecb7069f100.png`.

SHA256: `7c8b64b9c866ad8690f8948c0cb207e9c21388df95d09b629fb6378bfdf3448d`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## coalition/window

Plik: [Assets/Factions/coalition/rack-window-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/coalition/rack-window-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/coalition/rack-window-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-73bd50e2-79b9-4b22-b9dc-f49ce42aaf18.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-21e8fb88-76b3-405c-991b-8367f184e7c0.png`.

SHA256: `207b23b389fff783c752af5bff8aff416aae2d31979c6e19693816e2ecc8a7e3`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: standardized BLUE Coalition military armor: disciplined matte blue panel finish, orderly silver-gray edging, neatly aligned military-style unit bands and subtle standardized fastener reinforcements. No text. Add small white native Coalition compass-star/gear badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 762x2063 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/atlas

Plik: [Assets/Factions/descendens/suit-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/suit-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/suit-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-958d2c4d-cf60-4f0f-8f9e-ab16c403bbc2.png`.

SHA256: `cce40058893befcc7a058e05547c2e577d1b7ab048d15324734acce653149fc8`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. This is a RIGGED ATLAS. Every separate part must remain in its existing cell at its existing pixel coordinates. Add a tiny badge on the painted TORSO plate (cell x113,y5,w179,h251), and one on the upper-arm shoulder plate (cell x120,y263,w144,h240). Add matching miniature marks on the gripper housing and fan housing cells if visible. Keep ALL other cells, BOTH helmet states and every empty gap unchanged. DO NOT rearrange, resize, move, reflow, merge or delete any part.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/housing

Plik: [Assets/Factions/descendens/impeller-housing.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/impeller-housing.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/impeller-housing.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4445a844-c9ff-4778-8886-71d321d077e9.png`.

SHA256: `83f2706ad53a71d74116d33ee6c3021c60bf84736f4a20a3da8fe58f94450aa7`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/impeller

Plik: [Assets/Factions/descendens/impeller-module.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/impeller-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/impeller-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-24f0baa2-d3a1-41b6-b431-e9999ef2f67a.png`.

SHA256: `74ba0c4e5957022ca9cbc5fdd074a6943980d1aac137420a40e2cc4f2e321810`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/packed

Plik: [Assets/Factions/descendens/packed-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/packed-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/packed-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-ef7356e4-8fa2-493c-8393-40ebe8a8b5cc.png`.

SHA256: `0ff17113223d7f6c38c80ddcc048dd8792bf6e1026d7a5c16f333383928ae6a9`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 1635x962 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/rack

Plik: [Assets/Factions/descendens/rack-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/rack-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/rack-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-bbde7f4a-0d5e-41db-897e-df149b5ea2f4.png`.

SHA256: `79db5d774675493a79d3d5999f6ad4bf5ffc4803e2802fcff7c77aa66d388c13`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 887x1774 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/servo

Plik: [Assets/Factions/descendens/servo-module.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/servo-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/servo-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-0eb461de-ed43-4e96-83d8-88a051a28c5a.png`.

SHA256: `fbe6f45e854cd8baae8e9a040b8102561599028fab3977f75022c85f645a3fec`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## descendens/window

Plik: [Assets/Factions/descendens/rack-window-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/descendens/rack-window-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/descendens/rack-window-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b050ae5b-e55e-45af-8d41-44f9ff7abc3d.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b3994218-3fa5-4138-b262-d61a01a3b30b.png`.

SHA256: `0d40d8e82d38378474be1460f65aa05475520dd98df573a4afcceb1a4a66f739`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: precise IVORY WHITE high-tech Descendens armor: clean ceramic-coated panel surfaces, very fine angular engineering seams and restrained brushed-silver edge inlays, less improvised finish. Keep all part shapes and anchors intact. Add small DARK GRAPHITE double descending-chevron and central diamond badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 763x2062 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/atlas

Plik: [Assets/Factions/husk/suit-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/suit-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/suit-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-bbafbd1a-6696-4c75-a322-e8d041579744.png`.

SHA256: `b4202c68ca5598c90d3bd15359e23fc9e054f6e58695f97a88fbe5471480ddba`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. This is a RIGGED ATLAS. Every separate part must remain in its existing cell at its existing pixel coordinates. Add a tiny badge on the painted TORSO plate (cell x113,y5,w179,h251), and one on the upper-arm shoulder plate (cell x120,y263,w144,h240). Add matching miniature marks on the gripper housing and fan housing cells if visible. Keep ALL other cells, BOTH helmet states and every empty gap unchanged. DO NOT rearrange, resize, move, reflow, merge or delete any part.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/housing

Plik: [Assets/Factions/husk/impeller-housing.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/impeller-housing.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/impeller-housing.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b7baf39d-d357-482b-b3b7-ece235ba115f.png`.

SHA256: `c747e87c35357addc9569c809660268a217e4a43d4e74fb169d3581a36e1623d`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/impeller

Plik: [Assets/Factions/husk/impeller-module.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/impeller-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/impeller-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-63d83d64-1a87-429a-80de-f9ac43537b01.png`.

SHA256: `24587155312d02611ad364a71e4aeef5a5af1551e9f3c08bf768ea4e7214598a`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/packed

Plik: [Assets/Factions/husk/packed-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/packed-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/packed-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-5224005e-b7e5-4f46-a9d1-d0507de3fcf3.png`.

SHA256: `b4f45cc7a8154d84ad55440e5fb6160464be5062762d65a312305b952109a507`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 1635x962 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/rack

Plik: [Assets/Factions/husk/rack-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/rack-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/rack-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-399ee2e0-5ee5-4d17-b1ef-24ddd08e885a.png`.

SHA256: `201291ed4ac85526583ab829113a51b23e8ac9108b4ab9d6e01e003a874bbbd3`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 887x1774 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/servo

Plik: [Assets/Factions/husk/servo-module.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/servo-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/servo-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-590cfad4-0499-4af7-87f1-eae3f34a006d.png`.

SHA256: `a7c4a7faf8fd34afdeddf1d4912523baea29d01e834751abafc4554a82da0ead`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## husk/window

Plik: [Assets/Factions/husk/rack-window-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/husk/rack-window-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/husk/rack-window-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-c11ea63e-dcdf-41ab-bee6-4ada96b5613a.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-e4fe9d73-da52-44ec-8576-dbffcdd56723.png`.

SHA256: `e12941028fc01b110d079829cfc5cf01352a24a4ba1ee666e1b85e3336959fd1`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: PURPLE Church of Husk ritual-industrial armor: restrained pale bone/ivory curving engraved inlays, fine ceremonial linework within armor surfaces and subtle seal-like motifs. Keep it a functional sealed mechanical suit; no body horror, living flesh, robes, growths, hanging decorations or extra limbs. Add small ivory native chalice/tendril cult badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 762x2063 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/atlas

Plik: [Assets/AegisSuit/suit-v2.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/suit-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisSuit/suit-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-a1059a91-31bc-45a1-a292-b653bc513fb6.png`.

SHA256: `4bf31cb046b974e25ff10f4c2f62c77f28f70776a0b5408f4238beb618e27bc4`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. This is a RIGGED ATLAS. Every separate part must remain in its existing cell at its existing pixel coordinates. Add a tiny badge on the painted TORSO plate (cell x113,y5,w179,h251), and one on the upper-arm shoulder plate (cell x120,y263,w144,h240). Add matching miniature marks on the gripper housing and fan housing cells if visible. Keep ALL other cells, BOTH helmet states and every empty gap unchanged. DO NOT rearrange, resize, move, reflow, merge or delete any part.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/housing

Plik: [Assets/AegisSuit/impeller-housing.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/impeller-housing.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisSuit/impeller-housing.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-65912562-17c0-434a-b4cc-e04e80e4dce7.png`.

SHA256: `7e2741dfabce6ce288d3a005a6098dc239461b7c8f4470739a9ab7b9e4894792`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/impeller

Plik: [Assets/AegisModules/impeller-module.png](../../System-Aegis-No-Headsets/Assets/AegisModules/impeller-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisModules/impeller-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-921cc753-1fc0-4eda-82f0-4d01e4e16de1.png`.

SHA256: `938c6984c50ac04e88382c5495d9d21b28b053875b84ac3720295b6b45b8761a`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/packed

Plik: [Assets/AegisSuit/packed-suit.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/packed-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisSuit/packed-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-ad4d8618-adff-450b-b8e5-63bdf428302b.png`.

SHA256: `1c1128ce51bdb0b6c53e8ae1783fb3eb62e46355593a25ada239282014be2c9c`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 1635x962 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/rack

Plik: [Assets/AegisSuit/rack-suit.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/rack-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisSuit/rack-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-b1451336-4d9b-4acf-958d-ee27d344eb47.png`.

SHA256: `171ea332f4025a18c292586d2eeaa5b812898fa6f81de3d4a6ed65160afa9211`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 887x1774 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/servo

Plik: [Assets/AegisModules/servo-module.png](../../System-Aegis-No-Headsets/Assets/AegisModules/servo-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisModules/servo-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-f720934c-850b-444d-bc92-353331d565a0.png`.

SHA256: `975b67b849524a7b9237f8ccf21803fa5e9fda4508ae483597badb3e10957f21`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## pirates/window

Plik: [Assets/AegisSuit/rack-window-v2.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/rack-window-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/AegisSuit/rack-window-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-4d4c83f6-451a-40cf-b022-6ef09db3f8f2.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-7eea6048-59be-4a27-8f02-1287939bed88.png`.

SHA256: `e338697850ec88df759de48f540cc16b0b6f49376172e6470a61df1a1234d4cb`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: rugged RED salvaged pirate engineering armor: patch-repair weld beads, uneven repaired paint, blackened steel reinforcement and subtle scuffed field-work stencil accents. Keep every part and silhouette intact. Add small ivory skull-and-crossed-wrenches badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 762x2063 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/atlas

Plik: [Assets/Factions/separatists/suit-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/suit-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/suit-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-2c6efb25-4d37-4395-a2d8-963c6a8f090f.png`.

SHA256: `10d48bb5121ec1d4d257d1a9a4c04384887ef7a341dd2c72c52d5dc711f98455`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. This is a RIGGED ATLAS. Every separate part must remain in its existing cell at its existing pixel coordinates. Add a tiny badge on the painted TORSO plate (cell x113,y5,w179,h251), and one on the upper-arm shoulder plate (cell x120,y263,w144,h240). Add matching miniature marks on the gripper housing and fan housing cells if visible. Keep ALL other cells, BOTH helmet states and every empty gap unchanged. DO NOT rearrange, resize, move, reflow, merge or delete any part.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/housing

Plik: [Assets/Factions/separatists/impeller-housing.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/impeller-housing.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/impeller-housing.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27e8b230-62ac-4a27-8459-c0e42444d50b.png`.

SHA256: `c9ed3cd80ca8bc168a4c321c03a18452003cb1c0b00a7a9786fc89329f88ce82`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/impeller

Plik: [Assets/Factions/separatists/impeller-module.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/impeller-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/impeller-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-821f8fb5-85f2-45b9-b049-9db05bd0a0e1.png`.

SHA256: `e6870f95710197e3d37e3ef1fe9c0ceaff454ab8d5f7262de0d6c763b78dec79`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1254x1254 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/packed

Plik: [Assets/Factions/separatists/packed-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/packed-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/packed-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-43c5b6aa-f915-46d2-88fb-fbb4dcc38b0f.png`.

SHA256: `e2c8570858a34af235d93cd2c91b8f716bcb94d4ff10b9cad66e0961a02ad857`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 1635x962 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/rack

Plik: [Assets/Factions/separatists/rack-suit.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/rack-suit.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/rack-suit.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-bb575018-ffcf-4e53-be4c-0f6490196f85.png`.

SHA256: `297cd3e76f8f013adad4b66c3c8736cb04aad9836e5186715e3c19f3a918837c`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 887x1774 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/servo

Plik: [Assets/Factions/separatists/servo-module.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/servo-module.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/servo-module.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-7bcfd29e-666e-43ad-af11-32c1a0fa4a53.png`.

SHA256: `7ececb12bd3092475cd9f09923b785e9ee558bcd53c6a3ec06615e32dc967207`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place ONE small etched/stenciled emblem on the outer casing or wrist/gripper housing where it does not obscure the cyan indicator or interfere with joints/blades. Keep the exact two-link arm or four-blade fan assembly.  Preserve the original 1536x1024 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```

## separatists/window

Plik: [Assets/Factions/separatists/rack-window-v2.png](../../System-Aegis-No-Headsets/Assets/Factions/separatists/rack-window-v2.png)

Referencje: `F:/_Github/Barotrauma-Multi-Tool/System-Aegis-No-Headsets/Assets/Factions/separatists/rack-window-v2.png`; `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-27513ce6-d8ea-481b-847a-41a7aa578907.png`.

Wynik generatora: `C:\Users\kamil\.codex\generated_images\01a1fe74-e823-7930-84fd-f92a723512b8\exec-3dcc5cad-9931-45aa-b15c-c634e373a05d.png`.

SHA256: `712cee30483d2fe63b4abfd93ef161b38c249ccd1fa623575c09c57192902fa5`

```text
Use case: precise-object-edit. Image1 is the TARGET game texture and defines the exact canvas, layout and object. Image2 is ONLY the faction EMBLEM SHAPE reference, not an output canvas. Edit Image1 into a subtly more faction-specific production texture: ORANGE Separatist industrial field-modified armor: practical replaceable surface plates with reinforced bolt corners, modest black diagonal hazard stripes and workshop repair scuffs. Maintain the original mechanical silhouette. Add small charcoal/ivory inverted-triangle and raised-fist badge using the emblem shape from Image2. Make the marks genuinely MINI, approximately10-16 percent of a painted plate width, clearly recognizable high-contrast stencils or sewn/metal badges. Adapt emblem ink to contrast with the armor, retaining the same emblem geometry. Place a small badge on the visible shoulder/chest plate; at most two mini badges total. Keep the original folded/rack/window view and pose exactly.  Preserve the original 762x2063 canvas/aspect ratio, part silhouettes, proportions, scale, joint pivots, blade count, grip geometry, locations, material depth and transparent alpha/negative space. Only painted surface treatment, tiny inlays/fastener details inside existing contours and the small faction badges may change. Keep silver bearings/blades silver, graphite framework dark, and all cyan lenses/functional indicator lights cyan. Do not change the badge reference, add words or numbers, create a different suit, or enlarge the logos into banners. No new objects, background, floor, cast shadow, glow backdrop, sheet labels, borders, extra fingers or missing parts. Export the complete edited transparent PNG; copy all rig geometry from Image1 exactly.
```
