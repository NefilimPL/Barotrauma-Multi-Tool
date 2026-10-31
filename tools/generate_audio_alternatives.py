"""Generate four original energy-shot auditions without changing game audio."""
import base64
import math
import random
import shutil
import struct
import subprocess
import tempfile
import wave
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
RATE=44100
PROFILES=[
    ('1-ion','Impuls jonowy','Ciężki bas, szorstka cewka i mocne wyładowanie.',.40),
    ('2-tesla','Wyładowanie Tesli','Ostry, poszarpany trzask elektryczny z krótkim brzęczeniem.',.28),
    ('3-plasma','Rezonator plazmowy','Dłuższy, głęboki rezonans i ziarnista, rozgrzana energia.',.46),
    ('4-magnetic','Pierścień magnetyczny','Trzy zwarte impulsy, metaliczny rezonans i elektryczny ogon.',.34),
]

def synth(index,duration):
    rng=random.Random(9917+index)
    samples=[];fast=low=0.0
    for i in range(int(duration*RATE)):
        t=i/RATE
        noise=rng.uniform(-1,1)
        fast=.78*fast+.22*noise;low=.97*low+.03*noise
        band=fast-low;high=noise-fast
        if index==0:
            value=1.25*band*math.exp(-t*9)+.65*noise*math.exp(-t*80)
            value+=.95*math.sin(2*math.pi*55*t)*math.exp(-t*12)
            value+=.35*math.sin(2*math.pi*145*t+2.8*math.sin(2*math.pi*43*t))*math.exp(-t*13)
        elif index==1:
            gate=.2+.8*math.sin(2*math.pi*173*t)**2
            value=1.1*high*gate*math.exp(-t*17)
            value+=.4*math.sin(2*math.pi*680*t+2*math.sin(2*math.pi*227*t))*math.exp(-t*23)
            value+=.4*math.sin(2*math.pi*76*t)*math.exp(-t*25)
            for start in (.014,.028,.071,.119):
                if t>=start: value+=.7*high*math.exp(-(t-start)*110)
        elif index==2:
            coil=math.sin(2*math.pi*104*t+3.5*math.sin(2*math.pi*37*t))
            value=(1.7*band+.55*coil+.6*math.sin(2*math.pi*48*t))*math.exp(-t*9)
            value+=.7*high*math.exp(-t*65)
        else:
            value=.5*band*math.exp(-t*13)
            for start,weight in ((0,1),(.031,.8),(.067,.6)):
                if t>=start:
                    u=t-start
                    value+=weight*(high+.55*math.sin(2*math.pi*340*u+2*math.sin(2*math.pi*86*u)))*math.exp(-u*45)
            value+=.5*math.sin(2*math.pi*62*t)*math.exp(-t*19)
        value=math.tanh(value*1.4)*min(1,t/.0015)*min(1,(duration-t)/.015)
        samples.append(value)
    peak=max(abs(s) for s in samples)
    return [s*.88/peak for s in samples]

def encode(encoder,samples,path,tmp):
    pcm=tmp/'sample.wav'
    with wave.open(str(pcm),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',round(max(-1,min(1,s))*32767)) for s in samples))
    subprocess.run([encoder,'-y','-v','error','-i',str(pcm),'-c:a','libvorbis','-q:a','6',str(path)],check=True)

def data(path):
    return 'data:audio/ogg;base64,'+base64.b64encode(path.read_bytes()).decode('ascii')

def generate():
    encoder=shutil.which('ffmpeg')
    if not encoder: raise SystemExit('ffmpeg with libvorbis is required')
    output=ROOT/'output';output.mkdir(exist_ok=True)
    folder=output/'AEGIS-sound-alternatives';folder.mkdir(exist_ok=True)
    sections=[]
    with tempfile.TemporaryDirectory() as directory:
        tmp=Path(directory)
        for index,(name,title,description,duration) in enumerate(PROFILES):
            samples=synth(index,duration)
            single=folder/(name+'.ogg');burst=folder/(name+'-burst.ogg')
            encode(encoder,samples,single,tmp)
            cadence=round(.38*RATE)
            series=[0.0]*(4*cadence+len(samples))
            for shot in range(5):
                for i,value in enumerate(samples): series[shot*cadence+i]+=value
            peak=max(abs(s) for s in series)
            if peak>.95: series=[s*.95/peak for s in series]
            encode(encoder,series,burst,tmp)
            sections.append(f'<section><h2>{index+1}. {title}</h2><p>{description}</p>'
                f'<label>Pojedynczy wystrzał<audio controls preload="none" src="{data(single)}"></audio></label>'
                f'<label>Seria pięciu wystrzałów<audio controls preload="none" src="{data(burst)}"></audio></label>'
                f'<a download="{single.name}" href="{data(single)}">Pobierz próbkę OGG</a></section>')
    current=data(ROOT/'MULTI-TOOL-V2/Assets/Combat/Audio/shot-1.ogg')
    page='''<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Aegis — alternatywne wystrzały</title><style>
body{background:#081722;color:#e4f9ff;font:16px system-ui;max-width:840px;margin:32px auto;padding:20px}
h1{font-size:30px}p{color:#b0cbd4;line-height:1.6}section{background:#102a38;border:1px solid #28566a;border-radius:12px;padding:20px;margin:20px 0}
audio{display:block;width:100%;margin:8px 0 16px}a{color:#7deaff}label{display:block;margin-top:12px}
</style><h1>Aegis — cztery propozycje wystrzału</h1>
<p>Porównaj pojedynczy strzał i serię przy obecnym tempie broni. Wszystkie propozycje są oryginalnymi dźwiękami syntezowanymi.
Odtwarzaj po jednej próbce. W grze dźwięk zmienią odległość, woda i ściany. Obecny dźwięk w modzie pozostaje bez zmian do wyboru wariantu.</p>
'''+f'<section><h2>Obecny dźwięk — do porównania</h2><audio controls preload="none" src="{current}"></audio></section>'
    page+=''.join(sections)+'''<script>
document.querySelectorAll('audio').forEach(a=>a.addEventListener('play',()=>document.querySelectorAll('audio').forEach(b=>{if(a!==b)b.pause()})));
</script></html>'''
    preview=output/'AEGIS-sound-alternatives.html';preview.write_text(page,encoding='utf-8')
    archive=output/'AEGIS-sound-alternatives.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        z.write(preview,preview.name)
        for file in sorted(folder.glob('*.ogg')): z.write(file,'samples/'+file.name)
    print('Preview:',preview)
    print('Samples:',archive)

if __name__=='__main__': generate()
