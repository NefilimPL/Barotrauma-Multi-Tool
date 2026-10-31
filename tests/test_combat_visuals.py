from lua_support import LuaCase


class VisualContractTests(LuaCase):
    def test_flashlight_mount_follows_rendered_body_rotation_and_facing(self):
        self.lua.execute('''
            local beforeLightMap
            local function v(x,y) return {X=x,Y=y} end
            local env={Sprite=function() return {} end,Vector2=v,
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,CreateStatic=function() return {} end}}
            local body={DrawRotation=0,Dir=1,UpdateDrawPosition=function() refreshed=true end}
            local saved={Name='LightComponent',Light={OffsetFromBody=v(11,22)}}
            local lamp={Name='LightComponent',LightOffset=v(670,-90),Light={}}
            local gun={Prefab={Identifier={Value='combatmultitool'}},Scale=.068,body=body,Components={saved,lamp}}
            local G={states={[gun]={}},patch=function(_,class,method,fn,after)
                if method=='RenderLightMap' then
                    assert(class=='Barotrauma.Lights.LightManager' and not after)
                    beforeLightMap=fn
                end
            end}
            require('CombatTool.visuals').install(G,env,'mod')
            assert(beforeLightMap,'lamp has no render-time mount correction')
            local cases={{0,1,45.56,-6.12},{math.pi/2,1,6.12,45.56},
                {-math.pi/2,1,-6.12,-45.56},{0,-1,-45.56,-6.12},
                {math.pi/2,-1,6.12,-45.56}}
            for _,c in ipairs(cases) do
                body.DrawRotation=c[1];body.Dir=c[2];refreshed=false
                beforeLightMap()
                local p=lamp.Light.OffsetFromBody
                assert(math.abs(p.X-c[3])<.001 and math.abs(p.Y-c[4])<.001,'cone origin detached from the rotating lamp')
                assert(refreshed and lamp.Light.ParentBody==body)
                local expected=c[1]+(c[2]<0 and -math.pi or 0)
                assert(math.abs(lamp.Light.Rotation-expected)<.001,'cone direction and origin disagree')
            end
            assert(saved.Light.OffsetFromBody.X==11,'manual damage permission light was modified')
        ''')

    def test_impact_is_visible_at_contact_and_arc_reaches_its_destination(self):
        self.lua.execute('''
            local function v(x,y) return {X=x,Y=y} end
            local E={Sprite=function() return {Draw=function(_,_,_,_,_,scale) sheetSize=scale.X end} end,
                Vector2=v,Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,CreateStatic=function() return {} end},
                Color=function(r,g,b,a) return {A=a} end,
                GUI={GUI={DrawLine=function(_,a,b,color,_,width)
                    if width>=3 and color.A>=180 then brightLines=(brightLines or 0)+1 end
                    if math.abs(b.X-80)<.01 and math.abs(b.Y-30)<.01 then reached=true end
                end}}}
            local G={now=0,authoritative=false,remote={received=0,rings={},shields={}},patch=function() end}
            require('CombatTool.visuals').install(G,E,'mod')
            local camera={Zoom=1,WorldToScreen=function(p) return p end}
            G.onEffect('wallhit',{x=0,y=0},0,1);G.draw({},camera)
            assert(sheetSize>=.22,'impact sheet is too small to read in combat')
            assert(brightLines and brightLines>0,'impact has no bright substantial flash')
            G.onEffect('arc',{x=0,y=0},0,1,{x=80,y=30});G.draw({},camera)
            assert(reached,'electrical bolt did not reach the affected character')
        ''')

    def test_ring_animates_in_place_and_drawing_never_repeats_sound(self):
        self.lua.execute('''
            local function v(x,y) return {X=x,Y=y} end
            local E={Sprite=function() return {Draw=function() end} end,Vector2=v,
                Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,Color=function() return {} end,
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,CreateStatic=function() return {} end},
                GUI={GUI={DrawLine=function(_,a,b) signature=signature..string.format('%.2f,%.2f;',a.X,b.Y) end}}}
            local ring={id=1,x=0,y=0,dx=1,dy=0,radius=6,age=0,alive=true}
            local G={now=0,authoritative=false,remote={received=0,rings={ring},shields={}},patch=function() end,
                playCombatSound=function() sounds=(sounds or 0)+1 end}
            require('CombatTool.visuals').install(G,E,'mod')
            local cam={Zoom=1,WorldToScreen=function(p) return p end}
            G.onEffect('shot',{x=0,y=0},0,1)
            signature='';G.draw({},cam);first=signature
            ring.age=.08;signature='';G.draw({},cam);second=signature
            assert(first~=second,'projectile loop is static')
            assert(sounds==1,'sound must play once on event, never on drawing')
        ''')

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
                patch=function(_,_,method,fn,after) if method=='DrawMap' then assert(after);drawPatch=fn end end,
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
