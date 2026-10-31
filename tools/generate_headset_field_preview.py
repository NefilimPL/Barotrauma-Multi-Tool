"""Export the production Lua renderer's geometry to illustrative SVG previews.

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
            item={OwnInventory={GetItemAt=function() return cell end}}
            char={ID=42,WorldPosition=E.Vector2(0,0),AnimController={Limbs={
                {WorldPosition=E.Vector2(0,35)},{WorldPosition=E.Vector2(-8,-38)},
                {WorldPosition=E.Vector2(8,-38)}}}}
            cam={Zoom=2.8,WorldToScreen=function(p) return E.Vector2(240+p.X*2.8,210-p.Y*2.8) end}
        ''')
        lua.execute('local charge,kind,age=...;cell.Condition=charge;G.emit(char,item,kind);G.updateEffects(age);G.drawEffects({},cam)', energy, kind, age)
        assert len(lua.globals().lines) > 140, 'production field surface was not exported'
        parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="480" height="420" viewBox="0 0 480 420">',
                 '<rect width="480" height="420" rx="12" fill="#101a22"/>',
                 '<g stroke="#526875" stroke-linecap="round" fill="#526875">',
                 '<circle cx="240" cy="112" r="18" stroke="none"/>',
                 '<path d="M240 150V235M240 160L202 213M240 160L278 213M240 235L216 308M240 235L264 308" stroke-width="23"/>',
                 '</g><g>']
        for _, line in lua.globals().lines.items():
            a, b, color = line['a'], line['b'], line['color']
            parts.append(f'<line x1="{a["X"]:.2f}" y1="{a["Y"]:.2f}" x2="{b["X"]:.2f}" y2="{b["Y"]:.2f}" '
                         f'stroke="rgb({color["R"]},{color["G"]},{color["B"]})" '
                         f'stroke-opacity="{color["A"]/255:.4f}" stroke-width="{line["width"]}"/>')
        parts.extend(['<animate attributeName="opacity" values="1;.4;.9;.3;1" dur=".65s" repeatCount="indefinite"/>', '</g></svg>'])
        (target / f'shield-{name}.svg').write_text('\n'.join(parts), encoding='utf-8')
    print('Exported 5 shield previews from production Lua draw commands (GPU not implied).')


if __name__ == '__main__':
    generate()
