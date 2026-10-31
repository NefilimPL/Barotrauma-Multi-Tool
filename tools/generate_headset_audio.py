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
    duration = [.24, .30, .42, .55][tier]
    rng = random.Random(8731 + tier)
    samples = []
    filtered = 0
    for i in range(int(RATE * duration)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        filtered = .84 * filtered + .16 * noise
        pitch = [180, 135, 100, 65][tier]
        pulse = math.sin(2 * math.pi * pitch * t + 5 * math.exp(-t * 35)) * math.exp(-t * 18)
        fizz = (noise - filtered) * math.exp(-t * 32) * .45
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
        samples.append((pulse + fizz + warning) * envelope)
    peak = max(abs(s) for s in samples)
    return [s * .78 / peak for s in samples]


def generate():
    encoder = shutil.which('ffmpeg')
    if not encoder:
        raise SystemExit('ffmpeg with libvorbis is required')
    target = ROOT / 'MULTI-TOOL-V2/Assets/Headsets/Audio'
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for tier, name in enumerate(['high', 'low', 'critical', 'empty']):
            source = Path(tmp) / 'shield.wav'
            with wave.open(str(source), 'wb') as stream:
                stream.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
                stream.writeframes(b''.join(struct.pack('<h', round(s * 32767)) for s in synth(tier)))
            subprocess.run([encoder, '-y', '-hide_banner', '-loglevel', 'error', '-i', str(source),
                            '-c:a', 'libvorbis', '-q:a', '6', str(target / f'shield-{name}.ogg')], check=True)
    print('Generated 4 original headset power-tier sounds.')


if __name__ == '__main__':
    generate()
