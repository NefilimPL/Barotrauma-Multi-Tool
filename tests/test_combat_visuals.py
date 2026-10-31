from lua_support import LuaCase


class VisualContractTests(LuaCase):
    def test_frames_draw_in_a_balanced_native_map_draw_pass(self):
        self.lua.execute('''
            local drawPatch
            local function v(x,y) return {X=x,Y=y} end
            local env={Sprite=function() return {Draw=function() draws=(draws or 0)+1 end} end,
                Vector2=v,Rectangle=function(x,y,w,h) assert(x>=0 and y>=0 and x+w<=1254 and y+h<=1254);return {} end,
                Color=function() return {} end,GUI={GUI={DrawLine=function(_,_,_,_,_,width)
                    assert(width>=1 and width%1==0,'native GUI line width must be a positive integer')
                end}}}
            local G={now=0,authoritative=false,remote={received=0,shields={},rings={}},
                patch=function(_,_,method,fn,after) assert(method=='DrawMap' and after);drawPatch=fn end,
                cast=function() return nil end}
            require('CombatTool.visuals').install(G,env,'mod')
            local batch={Begin=function() balance=(balance or 0)+1 end,End=function() balance=balance-1 end}
            local screen={Cam={Zoom=1,WorldToScreen=function(p) return p end}}
            for _,name in ipairs({'shieldhit','break','contact','hit','bounce','shot','charge'}) do G.onEffect(name,{x=0,y=0},0,1) end
            for i=0,15 do
                G.now=i/25;G.remote.received=G.now
                G.remote.shields={{x=0,y=0,angle=0,energy=100}}
                drawPatch(screen,{spriteBatch=batch})
                assert(not G.visualError,G.visualError)
                G.updateVisuals(.03)
            end
            G.now=1;G.remote.received=1
            G.remote.rings={{x=0,y=0,dx=1,dy=0,speed=1400,age=0,distance=0,bouncesLeft=1,damageMultiplier=1,radius=6,alive=true}}
            G.updateVisuals(.05)
            predictedX=G.remote.rings[1].x
        ''')
        self.assertGreater(self.lua.globals().draws,16)
        self.assertEqual(self.lua.globals().balance,0)
        self.assertAlmostEqual(self.lua.globals().predictedX,70)
