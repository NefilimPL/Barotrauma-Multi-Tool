import argparse
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from validate_content import validate

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--mod',type=Path,default=ROOT/'System-Aegis')
    parser.add_argument('--package-name',help='Public archive name and root folder')
    args=parser.parse_args()
    mod=args.mod.resolve()
    name=args.package_name or mod.name
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*',name):
        parser.error('package name must be a simple folder name')
    validate(None,mod)
    version=ET.parse(mod/'filelist.xml').getroot().get('modversion')
    output=ROOT/'output';output.mkdir(exist_ok=True)
    archive=output/f'{name}-{version}.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for file in sorted(mod.rglob('*')):
            if file.is_file():z.write(file,f'{name}/{file.relative_to(mod).as_posix()}')
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert not any('zz_testkeepalive' in name or '/Tests/' in name for name in z.namelist())
    print(f'Package: {archive} ({archive.stat().st_size:,} bytes)')
