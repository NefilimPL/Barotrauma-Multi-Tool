"""Original procedural shield impacts; no film/game recordings are copied."""
import math
import random
import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def synth(tier):
    duration = [.48, .60, .72, .90][tier]
    rng = random.Random(8731 + tier)
    samples = []
    filtered = 0
    for i in range(int(RATE * duration)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        filtered = .84 * filtered + .16 * noise
        pitch = [170, 145, 115, 80][tier]
        # Inharmonic metallic body, a falling electronic chirp and a short
        # noise transient: original energy-shield impact, no sampled film audio.
        phase = 2 * math.pi * pitch * t + 12 * (1 - math.exp(-t * 35))
        pulse = (math.sin(phase) + .48 * math.sin(phase * 2.31) +
                 .24 * math.sin(phase * 4.73)) * math.exp(-t * 9)
        fizz = (noise - filtered) * math.exp(-t * 90) * .9
        fizz += .26 * filtered * math.exp(-t * 12)
        pulse += .35 * math.sin(2 * math.pi * (95 * t + 35 * (1 - math.exp(-t * 22)))) * math.exp(-t * 16)
        if tier >= 1:
            gate = .15 + .85 * (math.sin(2 * math.pi * (24 + tier * 7) * t) > .2)
            pulse *= gate
            fizz += .22 * filtered * math.exp(-t * 12) * gate
        warning = 0
        if tier >= 2:
            for onset in ([.09, .23] if tier == 2 else [.03, .19, .35]):
                s = t - onset
                if 0 <= s < .075:
                    warning += .28 * math.sin(2 * math.pi * (680 if tier == 2 else 390) * s) * math.sin(math.pi * s / .075)
        envelope = min(1, t / .002) * min(1, (duration - t) / .02)
        samples.append(math.tanh((pulse + fizz + warning) * 1.3) * envelope)
    peak = max(abs(s) for s in samples)
    return [s * .90 / peak for s in samples]


def alarm(tier):
    duration = [.65, .85, 1.05][tier]
    samples = []
    onsets = [[0, .24], [0, .18, .36], [0, .27, .54]][tier]
    for i in range(round(RATE * duration)):
        t = i / RATE
        value = 0
        for n, onset in enumerate(onsets):
            age = t - onset
            length = .16 if tier < 2 else .24
            if 0 <= age < length:
                pitch = (880 if tier == 0 else 1050 if tier == 1 else 500) * (.72 ** n)
                phase = 2 * math.pi * (pitch * age - pitch * .7 * age * age)
                value += (math.sin(phase) + .25 * math.sin(phase * 2)) * math.sin(math.pi * age / length) ** .6
        samples.append(value * .65)
    return samples


def generate():
    encoder = shutil.which('ffmpeg')
    if not encoder:
        raise SystemExit('ffmpeg with libvorbis is required')
    target = ROOT / 'MULTI-TOOL-V2/Assets/Headsets/Audio'
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        clips = [(f'shield-{name}', synth(tier)) for tier, name in enumerate(['high', 'low', 'critical', 'empty'])]
        clips += [(f'warning-{name}', alarm(tier)) for tier, name in enumerate(['low', 'critical', 'empty'])]
        for name, samples in clips:
            source = Path(tmp) / 'shield.wav'
            with wave.open(str(source), 'wb') as stream:
                stream.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                stream.writeframes(b''.join(struct.pack('<h', round(s * 32767)) for s in samples))
            subprocess.run([encoder, '-y', '-hide_banner', '-loglevel', 'error', '-i', str(source),
                            '-c:a', 'libvorbis', '-q:a', '6', str(target / f'{name}.ogg')], check=True)
    print('Generated 4 original resonant impacts and 3 independent power alarms.')


if __name__ == '__main__':
    generate()
