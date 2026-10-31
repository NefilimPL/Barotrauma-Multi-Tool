from lua_support import LuaCase


class HeadsetVisualTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            lines={}
            E={CLIENT=true,Game={IsSingleplayer=true},Networking={Receive=function() end},
                SoundPlayer={PlaySound=function() end},
                Vector2=function(x,y) return {X=x,Y=y} end,
                Color=function(r,g,b,a) return {R=r,G=g,B=b,A=a} end,
                GUI={GUI={DrawLine=function(batch,a,b,color,depth,width)
                    lines[#lines+1]={a=a,b=b,color=color,width=width}
                end}},
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {Deferred=1} end,
                    CreateStatic=function() return {NonPremultiplied=1} end}}
            G=require('AegisHeadset.game').new(E)
            G.patch=function() end
            require('AegisHeadset.effects').install(G,E)
            cell={Condition=100,MaxCondition=100,HasTag=function() return true end}
            item={OwnInventory={GetItemAt=function() return cell end}}
            char={ID=42,WorldPosition=E.Vector2(0,0),AnimController={Limbs={
                {WorldPosition=E.Vector2(0,32)},{WorldPosition=E.Vector2(0,-32)}}}}
            cam={Zoom=.5,WorldToScreen=function(p) return E.Vector2(p.X*.5,-p.Y*.5) end}
        ''')

    def test_shield_has_translucent_surface_across_body_not_just_thin_outline(self):
        self.lua.execute('''
            G.emit(char,item,'hit');G.drawEffects({},cam)
            local filled=0
            for _,line in ipairs(lines) do
                if line.a.X < -12 and line.b.X > 12 and line.width>=2 and line.color.A>10 then filled=filled+1 end
            end
            assert(filled>=10,'shield has no visible filled energy surface')
        ''')

    def test_standing_ragdoll_has_full_width_shield_even_when_limbs_align(self):
        self.lua.execute('''
            G.emit(char,item,'hit');G.drawEffects({},cam)
            local xmin,xmax=math.huge,-math.huge
            for _,line in ipairs(lines) do
                xmin=math.min(xmin,line.a.X,line.b.X);xmax=math.max(xmax,line.a.X,line.b.X)
            end
            assert(xmax-xmin>=34,'field collapses to a narrow red line on upright characters')
        ''')

    def test_heal_and_pressure_share_one_visual_field(self):
        self.lua.execute('''
            G.emit(char,item,'pressure');G.drawEffects({},cam);local first=#lines;lines={}
            G.emit(char,item,'heal');G.drawEffects({},cam)
            assert(#lines<=first*1.1,'simultaneous consumers stack duplicate shield surfaces')
        ''')
