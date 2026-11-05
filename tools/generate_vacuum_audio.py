"""Original mono motor loop and short recycling grinder, no external samples."""
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


def synth(kind, seconds):
    rng = random.Random(1384)
    samples = []
    low = 0.0
    for i in range(int(RATE * seconds)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low = low * .91 + noise * .09
        if kind == 'suction':
            # Periodic motor tones sit under air noise; loop ends blend below.
            value = .26 * math.sin(2 * math.pi * 120 * t)
            value += .11 * math.sin(2 * math.pi * 240 * t)
            value += .07 * math.sin(2 * math.pi * 960 * t)
            value += .44 * low + .045 * (noise - low)
        else:
            gate = .65 + .35 * math.sin(2 * math.pi * 43 * t)
            value = (.5 * low + .17 * noise + .15 * math.sin(2 * math.pi * 170 * t)) * gate
            value *= min(1, t / .012) * min(1, (seconds - t) / .07)
        samples.append(value)
    if kind == 'suction':
        # Blend the final 10 ms toward the beginning for a quiet loop boundary.
        count = int(RATE * .01)
        for n in range(count):
            u = (n + 1) / count
            samples[-count+n] = samples[-count+n] * (1-u) + samples[n] * u
        samples = samples[count:]
    peak = max(abs(s) for s in samples)
    return [s * .76 / peak for s in samples]


def generate():
    encoder = shutil.which('ffmpeg')
    if not encoder:
        raise SystemExit('ffmpeg with libvorbis is required')
    target = ROOT / 'MULTI-TOOL-V2/Assets/Vacuum/Audio'
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        for kind, duration in [('suction', 2.0), ('salvage', .22)]:
            pcm = Path(temporary) / 'effect.wav'
            with wave.open(str(pcm), 'wb') as sound:
                sound.setparams((1, 2, RATE, 0, 'NONE', ''))
                sound.writeframes(b''.join(struct.pack('<h', round(s * 32767)) for s in synth(kind, duration)))
            output = target / (kind + '.ogg')
            subprocess.run([encoder, '-y', '-hide_banner', '-loglevel', 'error', '-i', str(pcm),
                            '-c:a', 'libvorbis', '-q:a', '5', str(output)], check=True)
            print(output.relative_to(ROOT))


if __name__ == '__main__':
    generate()
