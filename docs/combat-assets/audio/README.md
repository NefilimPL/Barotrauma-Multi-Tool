All eleven bundled effects are original procedurally synthesized discharges
and impacts. The primary shot is the user-approved alternative 3, the
0.46-second plasma resonator: deep resonance and a rough, grainy discharge.
Both shot files contain the same approved single-shot recording, at full
source gain with a 1400-unit audible range.
There is no firearm recording or secondary shot layer. The two arc variants
provide the short zap when impact energy jumps to a nearby character.
Rebuild the synthesized files with `python tools/generate_combat_audio.py`
(Python standard library and ffmpeg with libvorbis).

Mono Vorbis, 44.1 kHz. Peak before encoding: -1.1 dBFS for the plasma shot,
-1.7 dBFS for other effects. Variants are selected by the native sound prefab
system. Playback uses the event's world position,
the game's audio volume, distance attenuation and underwater/wall muffling.
