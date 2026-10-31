"""Validate package references, source identifiers, textures and Lua 5.2 syntax."""
import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.local-tools/python'))
from PIL import Image
from lupa.lua52 import LuaRuntime

def validate(game):
    mod=ROOT/'MULTI-TOOL-V2'
    files=list(mod.glob('*.xml'))
    for path in files: ET.parse(path)
    manifest=ET.parse(mod/'filelist.xml').getroot()
    for entry in manifest:
        assert (mod/entry.attrib['file'].replace('%ModDir%/','')).is_file(),entry.attrib
    combat=ET.parse(mod/'combat_tool.xml').getroot().find('Item')
    assert combat.attrib['identifier']=='combatmultitool'
    assert combat.find('Holdable').attrib['slots']=='Any,RightHand+LeftHand'
    assert combat.find('ItemContainer').attrib['capacity']=='2'
    assert len(combat.find('CustomInterface').findall('TickBox'))==3
    sounds=ET.parse(mod/'combat_sounds.xml').getroot()
    for entry in sounds:
        path=mod/entry.attrib['file'].replace('%ModDir%/','')
        assert path.is_file() and path.read_bytes().startswith(b'OggS'),path
    for texture in combat.iter():
        if 'texture' in texture.attrib and texture.attrib['texture'].startswith('%ModDir%/'):
            path=mod/texture.attrib['texture'].replace('%ModDir%/','')
            with Image.open(path) as image:
                x,y,w,h=map(int,texture.attrib['sourcerect'].split(','))
                assert x>=0 and y>=0 and x+w<=image.width and y+h<=image.height,path
    for path in (mod/'Assets/Combat').glob('*.png'):
        with Image.open(path) as image:
            assert image.mode=='RGBA' and image.getchannel('A').getextrema()[0]==0,path
            if path.stem.startswith('shield-'):assert image.size==(1254,1254)
    lua=LuaRuntime()
    scripts=list((mod/'Lua').rglob('*.lua'))
    for path in scripts:lua.execute('assert(load(...))',path.read_text(encoding='utf-8'))
    if game:
        known=set()
        for path in (game/'Content/Items').rglob('*.xml'):
            try: root=ET.parse(path).getroot()
            except ET.ParseError:continue
            known.update(i.get('identifier','').lower() for i in root.iter('Item'))
        known.update(i.get('identifier','').lower() for i in ET.parse(mod/'tool.xml').getroot().iter('Item'))
        for entry in combat.find('Fabricate').findall('RequiredItem'):
            assert entry.attrib['identifier'].lower() in known,entry.attrib
    print(f'Content valid: {len(files)} XML, {len(scripts)} Lua 5.2 modules, alpha PNGs and frame rectangles; recipe identifiers checked={bool(game)}')

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--game',type=Path)
    validate(parser.parse_args().game)
