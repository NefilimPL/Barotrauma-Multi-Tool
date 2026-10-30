import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from validate_content import validate

if __name__=='__main__':
    validate(None)
    mod=ROOT/'MULTI-TOOL-V2'
    version=ET.parse(mod/'filelist.xml').getroot().get('modversion')
    output=ROOT/'output';output.mkdir(exist_ok=True)
    archive=output/f'MULTI-TOOL-V2-{version}.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for file in sorted(mod.rglob('*')):
            if file.is_file():z.write(file,file.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert not any('zz_testkeepalive' in name or '/Tests/' in name for name in z.namelist())
    print(f'Package: {archive} ({archive.stat().st_size:,} bytes)')
