All eleven bundled effects are original procedurally synthesized discharges
and impacts. The primary shot is a 0.34-second capacitor blast: sharp
ionization, a bass pulse, a rough cross-modulated coil and irregular electrical
crackle. It plays at full source gain with a 1400-unit audible range.
There is no firearm recording or secondary shot layer. The two arc variants
provide the short zap when impact energy jumps to a nearby character.
Rebuild the synthesized files with `python tools/generate_combat_audio.py`
(Python standard library and ffmpeg with libvorbis).

Mono Vorbis, 44.1 kHz. Peak before encoding: -1.7 dBFS. Variants are selected
by the native sound prefab system. Playback uses the event's world position,
the game's audio volume, distance attenuation and underwater/wall muffling.
