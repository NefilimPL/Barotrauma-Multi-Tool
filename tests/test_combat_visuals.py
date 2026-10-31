from lua_support import LuaCase


class VisualContractTests(LuaCase):
    def test_frames_draw_in_a_balanced_native_map_draw_pass(self):
        self.lua.execute('''
            local drawPatch
            local function v(x,y) return {X=x,Y=y} end
            local env={Sprite=function() return {Draw=function() draws=(draws or 0)+1 end} end,
                Vector2=v,Rectangle=function(x,y,w,h) assert(x>=0 and y>=0 and x+w<=1254 and y+h<=1254);return {X=x,Y=y,Width=w,Height=h} end,
                LuaUserData={RegisterType=function() blendRegistered=true end,CreateEnumTable=function() return {Deferred=0} end,
                    CreateStatic=function() assert(blendRegistered);return {NonPremultiplied='straight'} end},
                Color=function() return {} end,GUI={GUI={DrawLine=function(_,_,_,_,_,width)
                    assert(width>=1 and width%1==0,'native GUI line width must be a positive integer')
                end}}}
            local G={now=0,authoritative=false,remote={received=0,shields={},rings={}},
                patch=function(_,_,method,fn,after) assert(method=='DrawMap' and after);drawPatch=fn end,
                cast=function() return nil end}
            require('CombatTool.visuals').install(G,env,'mod')
            local batch={Begin=function(mode,blend) assert(mode==0 and blend=='straight');balance=(balance or 0)+1 end,End=function() balance=balance-1 end}
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

    def test_partial_occlusion_preserves_shield_texture_at_every_aim_angle(self):
        self.lua.execute('''
            local function v(x,y) return {X=x,Y=y} end
            local env={Sprite=function()
                local sprite={}
                sprite.Draw=function(_,_,color,origin,rotation,scale)
                    draws=draws+1;maxAlpha=math.max(maxAlpha,color.A)
                    assert(scale.Y*314<150,'shield texture too tall')
                    assert(math.abs(origin.Y+sprite.SourceRect.Y-313/2)<.01,'cropped strip shifted its pivot')
                end
                return sprite
            end, Vector2=v,Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,CreateStatic=function() return {} end},
                Color=function(r,g,b,a) return {A=a or 255} end,GUI={GUI={DrawLine=function() end}}}
            local G={now=0,authoritative=false,remote={received=0,shields={},rings={}},
                patch=function() end,cast=function(_,p) if p.y>50 then return {kind='wall'} end end}
            require('CombatTool.visuals').install(G,env,'mod')
            local camera={Zoom=1,WorldToScreen=function(p) return p end}
            for _,angle in ipairs({0,math.pi/2,math.pi,-math.pi/2}) do
                G.remote.shields={{x=0,y=0,angle=angle,energy=100}}
                draws=0;maxAlpha=0;G.draw({},camera)
                assert(draws>0,'a single blocked section hid the whole shield')
                assert(maxAlpha<=70,'shield texture is too opaque')
            end
        ''')
