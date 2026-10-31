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
    rng=random.Random(731+variant)
    samples=[];filtered=0.0;phase=0.0
    pitch=1.0-variant*.055
    for i in range(int(RATE*duration)):
        t=i/RATE;u=t/duration
        noise=rng.uniform(-1,1);filtered=.78*filtered+.22*noise
        if kind=='shot':
            phase+=2*math.pi*(110+1550*math.exp(-t*29))*pitch/RATE
            value=(.52*math.sin(phase)+.32*math.sin(2*math.pi*76*t*pitch)+.7*filtered)*math.exp(-t*13)
            value+=.22*noise*math.exp(-t*90)
        elif kind=='bodyhit':
            value=(.65*math.sin(2*math.pi*(100-65*u)*t)+1.1*filtered)*math.exp(-t*23)
            value+=.15*math.sin(2*math.pi*1250*t*pitch)*math.exp(-t*30)
        elif kind=='wallhit':
            value=sum(math.sin(2*math.pi*f*pitch*t)/(j+2) for j,f in enumerate((330,973,1789,3411)))*math.exp(-t*21)
            value+=.8*noise*math.exp(-t*55)
        elif kind=='bounce':
            phase+=2*math.pi*(650+2100*(1-u)**2)*pitch/RATE
            value=(.6*math.sin(phase)+.2*noise)*math.exp(-t*24)
        else:
            phase+=2*math.pi*(450+950*u*u)*pitch/RATE
            value=.42*math.sin(phase)*(u**.6)
        envelope=min(1,t/.0025)*min(1,(duration-t)/.012)
        samples.append(value*envelope)
    peak=max(abs(x) for x in samples)
    return [x*.82/max(peak,.001) for x in samples]

def generate():
    encoder=shutil.which('ffmpeg')
    if not encoder: raise SystemExit('ffmpeg with libvorbis is required')
    target=ROOT/'MULTI-TOOL-V2/Assets/Combat/Audio';target.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for kind,duration,variants in [('shot',.34,2),('bodyhit',.19,2),('wallhit',.23,2),('bounce',.15,2),('charge',.12,1)]:
            for variant in range(variants):
                pcm=Path(tmp)/'effect.wav'
                with wave.open(str(pcm),'wb') as f:
                    f.setparams((1,2,RATE,0,'NONE','not compressed'))
                    f.writeframes(b''.join(struct.pack('<h',int(x*32767)) for x in synth(kind,duration,variant)))
                output=target/f'{kind}-{variant+1}.ogg'
                subprocess.run([encoder,'-y','-hide_banner','-loglevel','error','-i',str(pcm),'-c:a','libvorbis','-q:a','5',str(output)],check=True)
                print(output.relative_to(ROOT))

if __name__=='__main__':generate()
