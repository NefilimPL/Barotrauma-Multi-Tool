"""Count production Lua work across 120 frames using the existing native-boundary fixtures."""
import difflib
import re
import subprocess
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tests'))
from test_combat_shield_network import ShieldRenderSynchronizationTests
from test_vacuum_client import VacuumClientTests


def old_module(lua,path):
    def show(name):
        return subprocess.run(['git', 'show', f'HEAD:{name}'], cwd=ROOT,
                              check=True, capture_output=True, text=True, encoding='utf-8').stdout

    names = subprocess.run(['git', 'ls-tree', '-r', '--name-only', 'HEAD'], cwd=ROOT,
                           check=True, capture_output=True, text=True, encoding='utf-8').stdout.splitlines()
    current = Path(path)
    if path in names:
        source = show(path)
    else:
        # Find the pre-rename file in HEAD without pinning obsolete directory names.
        candidates = [n for n in names if Path(n).name == current.name and '/Lua/' in n]
        reference = (ROOT / current).read_text(encoding='utf-8')
        matches = [(difflib.SequenceMatcher(None, reference, show(n)).ratio(), n)
                   for n in candidates]
        if not matches or max(matches)[0] < .5:
            raise RuntimeError(f'Cannot locate historical Lua module for {path}')
        _, previous = max(matches)
        source = show(previous)
        imports = r"require\(['\"]([^'\"]+)['\"]\)"
        old_imports = re.findall(imports, source)
        new_imports = re.findall(imports, reference)
        if len(old_imports) != len(new_imports) or any(
                old.split('.')[-1] != new.split('.')[-1]
                for old, new in zip(old_imports, new_imports)):
            raise RuntimeError(f'Historical imports changed beyond a rename: {path}')
        modules = dict(zip(old_imports, new_imports))
        source = re.sub(imports, lambda match: "require('" + modules[match[1]] + "')", source)
    return lua.execute('return assert(load(...))()',source)


for version in ('before','after'):
    case=ShieldRenderSynchronizationTests('test_missing_weapon_uses_snapshot_position');case.setUp()
    lua=case.lua
    if version=='before':
        old_module(lua,'System-Aegis/Lua/AegisCombat/visuals.lua').install(lua.globals().G,lua.globals().env,'mod')
    lua.execute('casts=0;G.cast=function() casts=casts+1 end;for i=1,120 do G.now=(i-1)/60;G.remote.received=G.now;draw() end')
    print(version,'shield occlusion casts / 120 frames:',lua.globals().casts)
    case=VacuumClientTests('test_visible_storage_button_opens_backpack_without_nozzle');case.setUp()
    lua=case.lua
    if version=='before':
        old_module(lua,'System-Aegis/Lua/AegisVacuum/client.lua').install(lua.globals().G,lua.globals().E)
    lua.execute('''
        G.openPanel(pack)
        s={vacuum=pack.ID,pack=pack.ID,charge=0,groups=40,count=40,busy=false,
            page=0,pages=1,packs={pack.ID},rows={}}
        for i=1,40 do s.rows[i]={id=i,kind='iron',name='Iron',count=1,condition=100,quality=0,group=i} end
        G.onSnapshot(s);initial=#widgets
        for i=1,120 do G.onSnapshot(s) end
        allocated=#widgets-initial
    ''')
    print(version,'GUI widgets allocated / 120 unchanged snapshots:',lua.globals().allocated)
