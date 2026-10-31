"""Synthesize original Aegis effects and encode mono Vorbis with ffmpeg."""
import math
import random
import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
RATE=44100

def synth(kind,duration,variant):
    if kind=='shot':
        from generate_audio_alternatives import synth as plasma
        return plasma(2,duration) # User-selected audition 3, unchanged in both sound prefabs.
    rng=random.Random(731+variant)
    samples=[];filtered=0.0;slow=0.0
    pitch=1.0-variant*.055
    for i in range(int(RATE*duration)):
        t=i/RATE;u=t/duration
        noise=rng.uniform(-1,1);filtered=.78*filtered+.22*noise
        slow=.96*slow+.04*noise
        band=filtered-slow
        if kind=='arc':
            gate=.35+.65*abs(math.sin(2*math.pi*137*t+math.sin(2*math.pi*41*t)))
            value=(1.3*(noise-filtered)*gate+.2*math.sin(2*math.pi*960*pitch*t))*math.exp(-t*24)
            if t>.035: value+=.6*band*math.exp(-(t-.035)*55)
        elif kind=='bodyhit':
            value=(.6*math.sin(2*math.pi*90*t)+1.8*filtered)*math.exp(-t*32)
        elif kind=='wallhit':
            value=1.1*noise*math.exp(-t*60)+.6*band*math.exp(-t*22)
            value+=.16*math.sin(2*math.pi*890*pitch*t)*math.exp(-t*55)
        elif kind=='bounce':
            value=(noise-filtered)*math.exp(-t*65)+.1*math.sin(2*math.pi*1850*pitch*t)*math.exp(-t*80)
        else:
            value=filtered*math.exp(-t*60)+.12*math.sin(2*math.pi*160*t)*math.exp(-t*70)
        envelope=min(1,t/.0025)*min(1,(duration-t)/.012)
        samples.append(value*envelope)
    peak=max(abs(x) for x in samples)
    return [x*.82/max(peak,.001) for x in samples]

def generate():
    encoder=shutil.which('ffmpeg')
    if not encoder: raise SystemExit('ffmpeg with libvorbis is required')
    target=ROOT/'MULTI-TOOL-V2/Assets/Combat/Audio';target.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for kind,duration,variants in [('shot',.46,2),('arc',.2,2),('bodyhit',.16,2),('wallhit',.18,2),('bounce',.09,2),('charge',.07,1)]:
            for variant in range(variants):
                pcm=Path(tmp)/'effect.wav'
                with wave.open(str(pcm),'wb') as f:
                    f.setparams((1,2,RATE,0,'NONE','not compressed'))
                    f.writeframes(b''.join(struct.pack('<h',round(x*32767) if kind=='shot' else int(x*32767)) for x in synth(kind,duration,variant)))
                output=target/f'{kind}-{variant+1}.ogg'
                quality='6' if kind=='shot' else '5'
                subprocess.run([encoder,'-y','-hide_banner','-loglevel','error','-i',str(pcm),'-c:a','libvorbis','-q:a',quality,str(output)],check=True)
                print(output.relative_to(ROOT))

if __name__=='__main__':generate()
