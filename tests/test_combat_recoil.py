from lua_support import LuaCase


class CombatRecoilTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local mt={}
            mt.__mul=function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b},mt) end
            local vector=setmetatable({Zero={X=0,Y=0}}, {
                __call=function(_,x,y) return setmetatable({X=x,Y=y},mt) end})
            gun={ID=7,Quality=0,WorldPosition=vector(0,0),
                Prefab={Identifier={Value='combatmultitool'}},
                body={Enabled=true,Mass=2,TransformedRotation=0,
                    ApplyLinearImpulse=function(impulse,cap)
                        kicks=(kicks or 0)+1;lastImpulse=impulse;lastCap=cap
                    end}}
            env={Vector2=vector,CLIENT=true,Game={IsSingleplayer=false},
                Timer={GetTime=function() return 0 end},
                Entity={FindEntityByID=function(id) if id==7 then return gun end end},
                Networking={Receive=function(name,fn)
                    if name:find('effect') then receive=fn end
                end}}
            G=require('CombatTool.game').new(env)
            require('CombatTool.physics').install(G,env)
        ''')

    def test_recoil_follows_aim_and_ignores_invalid_bodies(self):
        self.lua.execute('''
            for _,angle in ipairs({0,math.pi,math.pi/2}) do
                gun.body.TransformedRotation=angle
                G.recoil(gun)
                assert(math.abs(lastImpulse.X+20*math.cos(angle))<.001)
                assert(math.abs(lastImpulse.Y+20*math.sin(angle))<.001)
                assert(lastCap==12,'recoil exceeds the intended velocity limit')
            end
            assert(kicks==3)
            gun.body.Enabled=false;G.recoil(gun)
            gun.body.Enabled=true;gun.Removed=true;G.recoil(gun)
            gun.Removed=false;gun.Prefab.Identifier.Value='wrench';G.recoil(gun)
            G.recoil(nil)
            assert(kicks==3,'invalid or disabled item received recoil')
        ''')

    def test_multiplayer_shot_receipt_kicks_only_its_weapon(self):
        self.lua.execute('''
            require('CombatTool.network').install(G,env)
            G.onEffect=function() effects=(effects or 0)+1 end
            function packet(kind,id)
                return {ReadByte=function() return kind end,ReadUInt16=function() return id end,
                    ReadSingle=function() return 0 end}
            end
            receive(packet(2,7))
            assert(kicks==1,'received shot did not recoil locally')
            receive(packet(3,7)) -- body hit must not recoil the weapon again
            receive(packet(2,99)) -- late packet for a despawned weapon
            gun.body.Enabled=false;receive(packet(2,7))
            assert(kicks==1,'non-shot, missing or disabled weapon received recoil')
            assert(effects==4,'recoil handling suppressed existing effects')
        ''')

    def test_authoritative_fire_kicks_once_even_with_local_effects(self):
        self.lua.execute('''
            env.Game.IsSingleplayer=true
            require('CombatTool.network').install(G,env)
            require('CombatTool.projectiles').install(G,env)
            G.muzzle=function() return {x=0,y=0} end
            G.cast=function() end
            G.onEffect=function() effects=(effects or 0)+1 end
            G.fire({item=gun},{owner={}})
            assert(kicks==1 and effects==1,'singleplayer recoil duplicated by shot effect')
            assert(lastImpulse.X==-20 and lastImpulse.Y==0)
            assert(#G.rings==1,'recoil changed projectile creation')
        ''')

    def test_held_pose_recoils_and_recovers_without_changing_prefab(self):
        self.lua.execute('''
            local v=env.Vector2
            local hold={Name='Holdable',AimPos=v(40,-7),AimAngle=0}
            gun.Components={hold}
            local hooks={}
            G.patch=function(name,_,_,fn) hooks[name]=fn end
            env.LuaUserData={CreateEnumTable=function() return {Both=1} end,
                RegisterType=function() return {} end,MakeFieldAccessible=function() end}
            env.Hook={Add=function() end}
            env.Single=function(value) return {Value=value,isSingle=true} end
            require('CombatTool.runtime').install(G,env)
            assert(hooks['recoil-pose'],'held weapon pose has no recoil hook')
            G.now=1;G.recoil(gun)
            local function arguments(item,aim)
                local values={item=item,aim=aim,itemPos=v(.4,-.07),itemAngleRelativeToHoldAngle=0}
                return setmetatable({}, {__index=values,__newindex=function(_,key,value)
                    if key=='itemAngleRelativeToHoldAngle' then
                        assert(type(value)=='table' and value.isSingle,'native float parameter received an unboxed Lua double')
                        values[key]=value.Value
                    else values[key]=value end
                end})
            end
            local function pose(age,aim,item)
                G.now=1+age
                local p=arguments(item or gun,aim)
                hooks['recoil-pose']({},p)
                return p
            end
            local peak=pose(.025,true)
            assert(peak.itemPos.X<.35,'held weapon did not move back at least five pixels')
            assert(peak.itemAngleRelativeToHoldAngle>.02,'held weapon did not visibly lift its muzzle')
            local recovery=pose(.15,true)
            assert(recovery.itemPos.X>peak.itemPos.X and recovery.itemPos.X<.4)
            for _,p in ipairs({pose(.3,true),pose(.025,false),pose(.025,true,{})}) do
                assert(p.itemPos.X==.4 and p.itemAngleRelativeToHoldAngle==0,'recoil leaked outside its aimed pulse')
            end
            assert(hold.AimPos.X==40 and hold.AimAngle==0,'recoil permanently changed the prefab pose')
            G.now=2;G.recoil(gun)
            G.now=2.025
            local p=arguments(gun,true)
            hooks['recoil-pose']({},p)
            assert(math.abs(p.itemPos.X-peak.itemPos.X)<.00001,'repeated shots accumulated positional drift')
        ''')
