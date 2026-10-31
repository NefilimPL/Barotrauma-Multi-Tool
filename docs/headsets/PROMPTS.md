# Grafiki i dźwięki komunikatorów

Grafiki powstały narzędziem **built-in imagegen**, z prawdziwym kanałem alfa.
Pliki 1254×1254 zapisano bez przeróbek w:

- `MULTI-TOOL-V2/Assets/Headsets/headset.png`
- `MULTI-TOOL-V2/Assets/Headsets/headset-mk2.png`

Prompt podstawowy:

> Production game asset: one isolated sci-fi industrial regenerative radio
> headset for a 2D side-view submarine survival game, Barotrauma-compatible
> painted gritty technical sprite style. Strict orthographic side view facing
> right, compact single visible charcoal earcup, slender curved steel headband
> with empty transparent space for a human head, short microphone boom extending
> toward lower right, small inset red emitter on earcup, exposed screws, subtle
> copper details, battered practical equipment. No head, face, person, battery
> outside device or floating extra parts. Centered square canvas, ample
> transparent margin. Crisp silhouette legible at 48px. Genuine transparent
> background. No text, labels, logos, panels, grid or border. One standalone
> equipment sprite, not a sprite sheet.

Prompt Mk II:

> One production equipment sprite for a 2D side-view submarine survival game.
> A heavy advanced shield-generating radio headset, gritty hand-painted
> industrial sci-fi style matching Barotrauma. Strict orthographic side profile
> facing right. Charcoal metal earcup, slender curved steel headband leaving
> transparent space for a human head, short microphone boom. Three small deep
> red shield emitter lenses integrated around earcup rim, angular titanium
> reinforcing plates, small copper wiring, worn screws. Practical equipment,
> not a helmet. No person, scenery, loose battery, floating parts, text or
> logos. Centered square canvas, transparent margin, crisp 48px silhouette.
> Genuine transparent background, no external shadow, grid or border.

W 1.2.2 obwódkę postaci zastępują małe czerwone błyski na soczewkach
słuchawek. Renderer Lua rysuje kilka krótkich linii GUI na każdą diodę,
z subtelną poświatą i wygaszaniem po 0,22 s. Pozycje soczewek zmierzono
w oryginalnych PNG; grafiki pozostają bez przeróbek. Transformacja odwzorowuje
noszony sprite, obrót głowy i odbicie. Nie wymaga nowej tekstury.
`python tools/generate_headset_field_preview.py` eksportuje produkcyjne
polecenia rysowania do poglądowych SVG. Nie zastępuje próby GPU gry.

Cztery oryginalne dźwięki syntetyzuje `python tools/generate_headset_audio.py`:
impuls, impuls z trzaskiem, przerywany alarm oraz sygnał wyczerpania.
Mono Vorbis, 44100 Hz; nie wykorzystano nagrań gry ani filmu.
Podgląd i odsłuch: [preview.html](preview.html).
