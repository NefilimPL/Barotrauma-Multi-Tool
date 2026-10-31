Bundled effects are original procedurally synthesized, noise-driven discharges
and impacts, without tonal laser sweeps. The primary shot references Barotrauma's
native Coilgun1/2 through Content paths; those game assets are not redistributed.
The bundled shot-1/2 files are a quiet secondary discharge layer.
Rebuild the synthesized files with `python tools/generate_combat_audio.py`
(Python standard library and ffmpeg with libvorbis).

Mono Vorbis, 44.1 kHz. Peak before encoding: -1.7 dBFS. Variants are selected
by the native sound prefab system. Playback uses the event's world position,
the game's audio volume, distance attenuation and underwater/wall muffling.
