Bundled effects are original procedurally synthesized, noise-driven discharges
and impacts, without tonal laser sweeps. The primary shot references Barotrauma's
native ShotgunShot1/2 through Content paths at full source gain; those game assets
are not redistributed. The bundled shot-1/2 files add a secondary discharge
layer at 0.4 gain. The primary shot has a 1400-unit audible range.
Rebuild the synthesized files with `python tools/generate_combat_audio.py`
(Python standard library and ffmpeg with libvorbis).

Mono Vorbis, 44.1 kHz. Peak before encoding: -1.7 dBFS. Variants are selected
by the native sound prefab system. Playback uses the event's world position,
the game's audio volume, distance attenuation and underwater/wall muffling.
