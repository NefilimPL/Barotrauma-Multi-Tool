"""Original synthetic servo-suit audio. Requires ffmpeg; no external samples."""
import math
import argparse
import random
import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
SOUNDS = {'repair': (1.5, True), 'weld': (1.5, True), 'combat': (2, True),
          'grab': (2, True), 'impeller': (2, True), 'servo': (.3, False),
          'helmet': (.55, False), 'switch': (.09, False), 'pulse': (.26, False)}


def synth(kind, duration):
    rng = random.Random(15112026 + list(SOUNDS).index(kind))
    data, low = [], 0.0
    for i in range(round(RATE * duration)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low = low * .94 + noise * .06
        tone = lambda f: math.sin(2 * math.pi * f * t)
        if kind in {'repair', 'weld'}:
            burst = max(0, tone(37)) ** 12
            v = .12 * tone(720) + .15 * tone(1440) + .35 * (noise - low)
            v += (.18 if kind == 'repair' else .38) * burst * noise
        elif kind == 'combat':
            v = .24 * tone(110) + .13 * tone(330) + .08 * tone(1760) + .12 * low
            v *= .85 + .15 * tone(20)
        elif kind == 'pulse':
            v = .35 * math.sin(2 * math.pi * (1600*t-2500*t*t)) * math.exp(-12*t)
            v += .16 * noise * math.exp(-55*t) + .18 * tone(120) * math.exp(-9*t)
        elif kind == 'grab':
            v = .22 * tone(160) + .12 * tone(320) + .08 * tone(640)
            v *= .72 + .28 * tone(4)
        elif kind == 'impeller':
            v = .2 * tone(90) + .12 * tone(270) + .5 * low
            v *= .85 + .15 * tone(15)
        elif kind == 'servo':
            v = .2 * math.sin(2 * math.pi * (450 * t - 220 * t * t)) + .17 * noise
        elif kind == 'helmet':
            v = .36 * (noise - low) * math.exp(-5 * t)
            v += .5 * math.exp(-100 * abs(t - .32)) * tone(85)
        else:
            v = .35 * tone(1350) * math.exp(-45 * t)
        if not SOUNDS[kind][1]:
            v *= min(1, t / .008) * min(1, (duration - t) / .025)
        data.append(v)
    if SOUNDS[kind][1]:
        count = round(RATE * .02)
        for n in range(count):
            f = (n + 1) / count
            data[-count + n] = data[-count + n] * (1 - f) + data[n] * f
        data = data[count:]
    peak = max(abs(v) for v in data) or 1
    return [v * .65 / peak for v in data]


def generate(only=None):
    encoder = shutil.which('ffmpeg')
    if not encoder:
        raise SystemExit('ffmpeg with libvorbis is required')
    target = ROOT / 'MULTI-TOOL-V2/Assets/DescendantSuit/Audio'
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        pcm = Path(temporary) / 'sound.wav'
        for kind, (duration, _) in SOUNDS.items():
            if only and kind not in only:continue
            with wave.open(str(pcm), 'wb') as stream:
                stream.setparams((1, 2, RATE, 0, 'NONE', ''))
                stream.writeframes(b''.join(struct.pack('<h', round(v * 32767)) for v in synth(kind, duration)))
            subprocess.run([encoder, '-y', '-hide_banner', '-loglevel', 'error', '-i', str(pcm),
                            '-c:a', 'libvorbis', '-q:a', '5', str(target / (kind + '.ogg'))], check=True)
            print((target / (kind + '.ogg')).relative_to(ROOT))


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--only',nargs='+',choices=list(SOUNDS))
    generate(parser.parse_args().only)
