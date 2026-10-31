"""Create a disposable local server copy; never writes into the Steam install."""
import argparse
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def prepare(game):
    target = ROOT / '.runtime/server'
    target.mkdir(parents=True, exist_ok=True)
    for file in game.iterdir():
        if file.is_file() and (file.suffix.lower() in {'.dll','.exe','.json','.xml','.txt','.dat'}):
            if file.name not in {'config_player.xml','serversettings.xml','clientpermissions.xml','bannedplayers.txt'}:
                destination = target / file.name
                if not destination.exists():
                    shutil.copy2(file,destination)
    for folder in ['Content','Lua','Submarines']:
        shutil.copytree(game/folder,target/folder,dirs_exist_ok=True)
    (target/'Data').mkdir(exist_ok=True)
    for file in (game/'Data').iterdir():
        if file.is_file() and file.name.lower() not in {'bannedplayers.xml','clientpermissions.xml'}:
            shutil.copy2(file,target/'Data'/file.name)
    shutil.copytree(ROOT/'MULTI-TOOL-V2',target/'LocalMods/MULTI-TOOL-V2',dirs_exist_ok=True)
    config=ET.parse(game/'config_player.xml')
    packages=config.getroot().find('contentpackages')
    if packages is None:
        packages=ET.SubElement(config.getroot(),'contentpackages')
    packages.clear()
    ET.SubElement(packages,'corepackage',path='Content/ContentPackages/Vanilla.xml')
    regular=ET.SubElement(packages,'regularpackages')
    ET.SubElement(regular,'package',path='LocalMods/MULTI-TOOL-V2/filelist.xml')
    config.getroot().set('savepath',str(target/'Saves'))
    config.write(target/'config_player.xml',encoding='utf-8',xml_declaration=True)
    ET.ElementTree(ET.Element('ServerSettings',ServerName='BMT isolated tests',IsPublic='false',
        EnableUPnP='false',MaxPlayers='2',Port='27945',QueryPort='27946')).write(
        target/'serversettings.xml',encoding='utf-8',xml_declaration=True)
    print(target)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--game',type=Path,default=Path('D:/SteamLibrary/steamapps/common/Barotrauma'))
    prepare(p.parse_args().game)
