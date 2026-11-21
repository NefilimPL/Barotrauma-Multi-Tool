# Tekstury modułów Aegis 1.4.1

Wbudowany generator obrazów, transparent_background=true.
Referencjami są faktyczne tekstury używane przez mod. Pliki wynikowe skopiowano bez zmiany pikseli.

## servo

[PNG](../../System-Aegis-No-Headsets/Assets/AegisModules/servo-module.png)

Referencje:
- [suit-v2.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/suit-v2.png)

```text
Use case: compositing. Make one production inventory/crafting sprite of the ACTUAL removable servo arm from this Barotrauma System Aegis suit atlas. Image 1 is the exact design reference, not a mood board. The deployed arm uses the two slim open rectangular link assemblies in row3 at x792,y590,w336,h101 and x1185,y598,w319,h81, and the two-finger gripper/emitter at x45,y841,w293,h113. Assemble precisely those three parts into one connected, gently folded articulated servo arm with one mounting pivot, one elbow pivot, and that exact red rectangular gripper head. Preserve the slim twin graphite rails, visible RED corrugated hose running through each open link, concentric SILVER circular bearings, muted dark-red head casing, tiny rectangular cyan indicator, and the exact TWO thin angular metal fingers. Match shapes, proportions, dark graphite and muted red materials and the hand-painted 2D side-view rendering of these atlas parts. This must look like the same removable arm the player sees on the suit, not a different redesigned robotic arm. Do not use the human sleeve/hand parts from the atlas. Output only one assembled arm, centered on a square with generous transparent margins, fully visible, clean genuine transparent alpha background. No suit, person, sprite sheet, extra objects, labels, text, backdrop, glow cloud, floor or cast shadow. No brass or gold joints, no cream/white armor, no chunky new housing, no third finger. Keep crisp silhouette readable in a small inventory slot.
```

Final revision (initial generated icon + original atlas reference):

```text
Use case: precise-object-edit. Image 1 is the edit target, a nearly correct inventory icon. Image 2 is the exact deployed suit texture reference. Correct ONLY the mechanical chain of the arm in Image 1. It currently has an EXTRA small elbow and an extra third short section near the bottom; REMOVE that extra bend/section. The finished module must contain exactly TWO straight rigid open-frame links of roughly equal length (upper length76, lower length66), joined at ONE elbow. Exactly THREE large concentric silver bearings along the chain: base pivot -> ONE upper link -> elbow pivot -> ONE lower link -> wrist pivot -> the existing red two-finger gripper. Each link is straight between its two bearings and has paired graphite rails enclosing a red corrugated hose, like the two links in row3 of Image 2. There must be no intermediate joint on either link, no third link, no fourth bearing, no zigzag third section. Arrange the TWO links with a shallow single elbow bend so both have room, then the gripper at the end. Reposition the existing parts as needed to fit the complete assembly in the square with clear margins; preserve their actual graphite/red/silver colors, worn paint, cyan rectangular indicator, exact slim rails and TWO angular gripper fingers. This is the same arm as the suit uses. Output one complete isolated assembled module on genuine transparent alpha, same inventory sprite rendering quality; no background, text, extra parts, frame, shadow or suit. Do not redesign any part or change to brass/white.
```

## impeller

[PNG](../../System-Aegis-No-Headsets/Assets/AegisModules/impeller-module.png)

Referencje:
- [impeller-housing.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/impeller-housing.png)
- [impeller.png](../../System-Aegis-No-Headsets/Assets/AegisSuit/impeller.png)

```text
Use case: compositing. Create one production crafting/inventory sprite by combining the EXACT existing System Aegis underwater thruster parts. Image 1 is the exact outer housing to preserve: circular worn dark GRAPHITE ring with the same muted RED accent armor plates, same bolt layout, same rectangular unit on its left containing THREE small cyan bars. Image 2 is the exact rotor to preserve: FOUR broad curved SILVER metal blades and a plain circular silver hub, viewed straight on. Place this four-bladed silver rotor centered inside the opening of the first housing, as one assembled removable impeller module, keeping the full housing and rotor recognizable as the same components used on the suit. Rotor is smaller than the housing, fits freely within the dark hole with clearance, as in a working ducted thruster. Preserve graphite/red/cyan housing colors and silver blade material; preserve all four blade shapes and the casing's proportions. No redesign or new decorative components. Output one isolated complete front-view assembly, square canvas, centered with clear transparent margins, genuinely transparent alpha background inside the blade gaps and outside the housing. No background, text, letters, logo, numbers, frame, cast shadow, hoses or other objects. No white/cream or brass casing, no teal blades, no five-blade fan, no cross grille or extra protective cage. Crisp hand-painted industrial 2D game sprite matching the references.
```

## shield

[PNG](../../System-Aegis-No-Headsets/Assets/AegisModules/shield-module.png)

Referencje:
- [weapon.png](../../System-Aegis-No-Headsets/Assets/AegisCombat/weapon.png)

```text
Use case: precise-object-edit. Derive a production crafting/inventory icon for a detachable Aegis shield power cartridge from the ACTUAL twin vertical turquoise energy cylinders visible in the middle-left receiver of the supplied weapon texture, just above the trigger and behind the long main turquoise barrel. The reference weapon is the exact visual design to match. Isolate and faithfully reproduce those TWO adjacent cylindrical turquoise/cyan glass capacitors with their existing worn silver metal caps and clamps, brass vented lower collars and a compact dark graphite/navy mounting bracket. The cartridge should visibly be the twin-cylinder component from this weapon, removed as one self-contained assembly, same side-view perspective, metal shading, glass texture, colors, wear and relative proportions. Keep two equal cylindrical glowing glass tubes, not a hexagonal crystal. Include only the connector/mount needed to join the existing two tubes. Square image with the whole twin-cylinder assembly centered and readable at small inventory size, clear transparent margins. Genuine transparent alpha background, no gun, barrel, stock, grip, person, other parts, background, ground, shadow, words, logo or frame. Do not invent an unrelated generator shape: no hex core, white rectangular armor box, round shield disc, large extra coils or red suit armor. Preserve the weapon's existing industrial dark navy, steel, aged brass and turquoise materials.
```

