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
