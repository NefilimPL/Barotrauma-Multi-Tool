import json
from pathlib import Path

from lua_support import LuaCase


class RingProjectionTests(LuaCase):
    def capture(self):
        result = self.lua.execute('''
            local vectors,lines=0,{}
            local E={Sprite=function() return {} end,
                Vector2=function(x,y) vectors=vectors+1;return {X=x,Y=y} end,
                Color=function(r,g,b,a) return {r,g,b,a} end,
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,
                    CreateStatic=function() return {} end},
                GUI={GUI={DrawLine=function(_,a,b,c,_,width)
                    lines[#lines+1]={a.X,a.Y,b.X,b.Y,c[1],c[2],c[3],c[4],width}
                end}}}
            local ring={id=7,x=30,y=40,dx=.6,dy=.8,radius=7,age=.23,alive=true,
                trail={{x=-10,y=3,age=-1},{x=-5,y=7,age=.1},
                       {x=4,y=9,age=.17},{x=20,y=30,age=.22}}}
            local G={now=0,authoritative=false,remote={received=0,rings={ring},shields={}},patch=function() end}
            require('AegisCombat.visuals').install(G,E,'mod')
            vectors=0
            G.draw({}, {Zoom=1.75,
                Transform={M11=.8,M12=.3,M21=-.4,M22=.7,M41=100,M42=-50},
                WorldToScreen=function() error('affine camera projection must stay local') end})
            return {vectors=vectors,lines=lines}
        ''')
        return result['vectors'], [[result['lines'][i][j] for j in range(1, 10)]
                                   for i in range(1, len(result['lines']) + 1)]

    def test_shared_endpoints_bound_managed_vector_allocations(self):
        vectors, _ = self.capture()
        self.assertLessEqual(vectors, 110, 'shared circle and trail endpoints were reprojected')

    def test_every_drawn_segment_matches_recorded_preoptimization_appearance(self):
        _, actual = self.capture()
        expected = json.loads((Path(__file__).parent / 'fixtures/combat-ring-lines.json').read_text())['lines']
        self.assertEqual(len(actual), len(expected))
        for row, reference in zip(actual, expected):
            for value, old in zip(row, reference):
                self.assertAlmostEqual(value, old, places=6)
