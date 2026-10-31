from lua_support import LuaCase


class HeadsetVisualTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            lines={};sounds=0
            E={CLIENT=true,Game={IsSingleplayer=true},Networking={Receive=function() end},
                InvSlotType={Headset=1},LimbType={Head=2},
                SoundPlayer={PlaySound=function() sounds=sounds+1 end},
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
            item={Prefab={Identifier={Value='aegisheadset'}},Condition=100,OwnInventory={GetItemAt=function() return cell end}}
            head={type=2,TextureScale=1,Params={Scale=1},WorldPosition=E.Vector2(0,32),
                body={DrawPosition=E.Vector2(0,32),DrawRotation=0,Dir=1}}
            worn={WearableComponent={Item=item},Scale=.035,InheritScale=true,IgnoreLimbScale=true,Rotation=0,
                Sprite={SourceRect={Width=1254,Height=1254},Origin=E.Vector2(426.36,764.94)}}
            head.WearingItems={worn}
            char={ID=42,WorldPosition=E.Vector2(0,0),Inventory={GetItemInLimbSlot=function() return item end},
                AnimController={RagdollParams={LimbScale=1},Limbs={head,{WorldPosition=E.Vector2(0,-32)}}}}
            cam={Zoom=.5,WorldToScreen=function(p) return E.Vector2(p.X*.5,-p.Y*.5) end}
        ''')

    def test_tiny_red_light_stays_at_headset_without_any_body_outline(self):
        self.lua.execute('''
            G.emit(char,item,'hit');G.drawEffects({},cam)
            assert(#lines>0 and #lines<60,'indicator must remain a tiny local effect')
            for _,line in ipairs(lines) do
                assert(math.abs(line.a.X)<8 and math.abs(line.b.X)<8)
                assert(line.a.Y < -10 and line.a.Y > -22,'effect escaped the ear/head area')
            end
        ''')

    def test_diode_tracks_head_rotation_and_facing(self):
        self.lua.execute('''
            local led=require('AegisHeadset.leds')
            local right=led.positions(E,char,item)[1]
            head.body.Dir=-1
            local left=led.positions(E,char,item)[1]
            assert(math.abs(right.x+left.x)<.001 and math.abs(right.y-left.y)<.001)
            head.body.Dir=1;head.body.DrawRotation=math.pi/2
            local turned=led.positions(E,char,item)[1]
            assert(math.abs(turned.x+(right.y-32))<.001 and math.abs((turned.y-32)-right.x)<.001)
        ''')

    def test_heal_and_pressure_share_one_diode_effect(self):
        self.lua.execute('''
            G.emit(char,item,'pressure');G.drawEffects({},cam);local first=#lines;lines={}
            G.emit(char,item,'heal');G.drawEffects({},cam)
            assert(#lines<=first*1.1,'simultaneous consumers stack duplicate shield surfaces')
        ''')

    def test_mk2_blinks_at_all_three_existing_artwork_diodes(self):
        self.lua.execute('''
            item.Prefab.Identifier.Value='aegisheadsetmk2'
            assert(#require('AegisHeadset.leds').positions(E,char,item)==3)
        ''')

    def test_indicator_disappears_soon_after_power_event(self):
        self.lua.execute('''
            G.emit(char,item,'hit');G.updateEffects(.3);G.drawEffects({},cam)
            assert(#lines==0,'the indicator stays lit passively')
        ''')

    def test_regeneration_is_silent_while_impacts_keep_their_sound(self):
        self.lua.execute('''
            G.emit(char,item,'heal');assert(sounds==0,'continuous healing is playing impact sounds')
            G.now=1;G.emit(char,item,'hit');assert(sounds==1)
        ''')

    def test_a_helmet_hiding_the_headset_also_hides_its_diode_glow(self):
        self.lua.execute('''
            worn.CanBeHiddenByOtherWearables=true
            head.WearingItems[2]={HideOtherWearables=true}
            G.emit(char,item,'hit');G.drawEffects({},cam)
            assert(#lines==0,'LEDs show through headgear hiding the headset')
            worn.CanBeHiddenByOtherWearables=false
            G.drawEffects({},cam);assert(#lines>0)
        ''')
