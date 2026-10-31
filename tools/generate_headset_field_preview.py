"""Export production headset LED flashes to transparent SVG overlays.

This validates draw commands, not the game's GPU. No source artwork is edited.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.local-tools/python'))
from lupa.lua52 import LuaRuntime


def generate():
    target = ROOT / 'docs/headsets'
    for name, kind, energy, age in [('heal', 'heal', 100, .06), ('impact', 'hit', 100, 0),
                                    ('low', 'hit', 30, 0), ('critical', 'hit', 10, .06),
                                    ('empty', 'hit', 0, .06)]:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("package.path=... .. '/?.lua;' .. package.path", (ROOT / 'MULTI-TOOL-V2/Lua').as_posix())
        lua.execute('''
            lines={}
            E={CLIENT=true,Game={IsSingleplayer=true},Networking={Receive=function() end},
                InvSlotType={Headset=1},LimbType={Head=2},
                SoundPlayer={PlaySound=function() end},
                Vector2=function(x,y) return {X=x,Y=y} end,
                Color=function(r,g,b,a) return {R=r,G=g,B=b,A=a} end,
                GUI={GUI={DrawLine=function(batch,a,b,color,depth,width)
                    lines[#lines+1]={a=a,b=b,color=color,width=width}
                end}},LuaUserData={RegisterType=function() end,
                    CreateEnumTable=function() return {Deferred=1} end,
                    CreateStatic=function() return {NonPremultiplied=1} end}}
            G=require('AegisHeadset.game').new(E);G.patch=function() end
            require('AegisHeadset.effects').install(G,E)
            cell={Condition=100,MaxCondition=100,HasTag=function() return true end}
            item={Prefab={Identifier={Value='aegisheadsetmk2'}},Condition=100,OwnInventory={GetItemAt=function() return cell end}}
            head={type=2,TextureScale=.5,Params={Scale=1},body={DrawPosition=E.Vector2(0,0),DrawRotation=0,Dir=1}}
            worn={WearableComponent={Item=item},Scale=.035,InheritScale=true,IgnoreLimbScale=true,Rotation=0,
                Sprite={SourceRect={Width=1254,Height=1254},Origin=E.Vector2(426.36,764.94)}}
            head.WearingItems={worn}
            char={ID=42,WorldPosition=E.Vector2(0,0),Inventory={GetItemInLimbSlot=function() return item end},
                AnimController={RagdollParams={LimbScale=1},Limbs={head}}}
            cam={Zoom=12,WorldToScreen=function(p) return E.Vector2(200+p.X*12,220-p.Y*12) end}
        ''')
        lua.execute('local charge,kind,age,id=...;cell.Condition=charge;item.Prefab.Identifier.Value=id;G.emit(char,item,kind);G.updateEffects(age);G.drawEffects({},cam)',
                    energy, kind, age, 'aegisheadset' if name == 'heal' else 'aegisheadsetmk2')
        assert 0 < len(lua.globals().lines) <= 30, 'expected only small local LED commands'
        parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="480" height="420" viewBox="0 0 480 420"><g>']
        for _, line in lua.globals().lines.items():
            a, b, color = line['a'], line['b'], line['color']
            parts.append(f'<line x1="{a["X"]:.2f}" y1="{a["Y"]:.2f}" x2="{b["X"]:.2f}" y2="{b["Y"]:.2f}" '
                         f'stroke="rgb({color["R"]},{color["G"]},{color["B"]})" '
                         f'stroke-opacity="{color["A"]/255:.4f}" stroke-width="{line["width"]}"/>')
        parts.append('</g></svg>')
        (target / f'shield-{name}.svg').write_text('\n'.join(parts), encoding='utf-8')
    print('Exported 5 LED overlays from production Lua draw commands (GPU not implied).')


if __name__ == '__main__':
    generate()
