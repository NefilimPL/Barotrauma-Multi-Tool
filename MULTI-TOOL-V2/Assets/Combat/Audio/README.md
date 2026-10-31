Original procedurally synthesized effects for Aegis. No recordings or samples
from other games are used. Rebuild with `python tools/generate_combat_audio.py`
(Python standard library and ffmpeg with libvorbis).

Mono Vorbis, 44.1 kHz. Peak before encoding: -1.7 dBFS. Variants are selected
by the native sound prefab system. Playback uses the event's world position,
the game's audio volume, distance attenuation and underwater/wall muffling.
