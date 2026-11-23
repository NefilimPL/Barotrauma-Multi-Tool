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


class ShieldBandsTests(LuaCase):
    frame_size = 313
    clipped_bands = (78, 136, 177, 20.5)

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function vector(x,y) return {X=x,Y=y} end
            local env={Sprite=function()
                    local sprite={}
                    sprite.Draw=function(_,pos,_,origin,rotation)
                        local rect=sprite.SourceRect
                        bands[#bands+1]={rect.Y,rect.Height,origin.X,origin.Y,pos.X,pos.Y,rotation}
                    end
                    return sprite
                end,
                Vector2=vector,Color=function() return {} end,
                Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,
                    CreateStatic=function() return {} end},GUI={GUI={DrawLine=function() end}}}
            local shield={id=1,x=0,y=0,angle=0,energy=100}
            local game={now=0,authoritative=false,remote={received=0,rings={},shields={shield}},
                patch=function() end}
            local camera={Zoom=1,WorldToScreen=function(p) return p end}
            require('AegisCombat.visuals').install(game,env,'mod')
            function frame(now,x,occluded)
                game.now=now;shield.x=x;bands={}
                local strip=0
                game.cast=function()
                    strip=strip+1;casts=(casts or 0)+1
                    return occluded(strip)
                end
                game.draw({},camera)
            end
        ''')

    def test_adjacent_visible_strips_share_draw_and_preserve_crop_and_pivot(self):
        self.lua.execute('''
            local size,firstHeight,lastTop,lastHeight,lastPivot=...
            frame(0,0,function(strip) return strip>=5 and strip<=7 end)
            assert(#bands==2,'expected one draw for each contiguous visible band, got '..#bands)
            assert(bands[1][1]==0 and bands[1][2]==firstHeight and bands[1][4]==size/2)
            assert(bands[2][1]==lastTop and bands[2][2]==lastHeight and bands[2][4]==lastPivot)
            for _,band in ipairs(bands) do
                assert(band[3]==size/2 and band[5]==60 and band[6]==0 and band[7]==0)
            end
        ''', self.frame_size, *self.clipped_bands)

    def test_fully_visible_shield_draws_once_and_fully_occluded_shield_has_no_draw(self):
        self.lua.execute('''
            local size=...
            frame(0,0,function() return false end)
            assert(#bands==1 and bands[1][2]==size and bands[1][4]==size/2)
            frame(.1,0,function() return true end)
            assert(#bands==0)
        ''', self.frame_size)

    def test_small_pose_change_waits_briefly_while_large_change_refreshes_immediately(self):
        self.lua.execute('''
            local clear=function() return false end
            frame(0,0,clear)
            frame(.015,3,clear)
            assert(casts==16,'small interpolated shift repeated all occlusion rays')
            assert(bands[1][5]==63,'rendered pose must still track every frame')
            frame(.035,3,function() return true end)
            assert(casts==32 and #bands==0,'small shift did not refresh at the next interval')
            frame(.04,14,clear)
            assert(casts==48 and #bands==1,'large shift reused an obsolete mask')
        ''')


class ModularShieldBandsTests(ShieldBandsTests):
    mod_directory = 'System-Aegis-No-Headsets'
    frame_size = 156
    clipped_bands = (39, 68, 88, 10)
