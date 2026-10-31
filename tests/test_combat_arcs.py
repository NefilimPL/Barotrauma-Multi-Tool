from lua_support import LuaCase


class ImpactArcTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function actor(x,y) return {WorldPosition={X=x,Y=y}} end
            owner=actor(0,0);direct=actor(5,0);near=actor(30,0);far=actor(200,0)
            hidden=actor(10,10);dead=actor(8,0);dead.IsDead=true
            removed=actor(9,0);removed.Removed=true
            gun={};events={};shocks={}
            G={flags=function() return {damage=true} end,state=function() return {item=gun} end,
                event=function(kind,_,point,endpoint) events[#events+1]={kind,point,endpoint} end,
                shock=function(target,point,attacker,burn,stun)
                    shocks[#shocks+1]={target=target,owner=attacker,burn=burn,stun=stun}
                end,
                cast=function(a,b,_,_,wallsOnly)
                    if wallsOnly and b.y==10 then return {kind='wall'} end
                end,findShield=function() end}
            require('CombatTool.projectiles').install(G,{Character={CharacterList={owner,direct,far,hidden,dead,removed,near}}})
            ring={owner=owner,weapon=gun,damageMultiplier=1}
            hit={x=0,y=0,nx=-1,ny=0,kind='character',target=direct}
            math.random=function() return 0 end
        ''')

    def test_impact_shocks_one_nearest_visible_bystander_once_per_ring(self):
        self.lua.execute('''
            assert(G.tryArc,'impact arc is missing')
            G.tryArc(ring,hit);G.tryArc(ring,hit)
            assert(#shocks==1,'ricochets repeated the secondary shock')
            assert(shocks[1].target==near,'shock hit owner/direct victim/occluded or invalid actor')
            assert(shocks[1].owner==owner and shocks[1].burn>0 and shocks[1].stun>0)
            assert(shocks[1].burn<5 and shocks[1].stun<.5,'secondary shock is too strong')
            assert(events[1][1]=='arc' and events[1][3].x==30,'arc endpoint was not emitted')
        ''')

    def test_probability_gate_and_range_prevent_guaranteed_area_damage(self):
        self.lua.execute('''
            assert(G.tryArc,'impact arc is missing')
            math.random=function() return .16 end;G.tryArc(ring,hit)
            assert(#shocks==0,'shock occurred outside the 15 percent roll')
            math.random=function() return .14 end;near.WorldPosition.X=200
            G.tryArc(ring,hit);assert(#shocks==0,'shock reached beyond the small radius or through a wall')
        ''')

    def test_wall_collision_invokes_secondary_arc(self):
        self.lua.execute('''
            local Core=require('CombatTool.core')
            G.cast=function(_,_,_,_,walls)
                if not walls then return {t=.5,x=0,y=0,nx=-1,ny=0,kind='wall'} end
            end
            local r=Core.ring({x=-5,y=0},{x=1,y=0},0)
            r.weapon=gun;r.owner=owner;r.bouncesLeft=0;G.rings={r}
            G.updateRings(.02)
            assert(#shocks==1,'wall collision failed to produce an eligible secondary shock')
        ''')

    def test_network_preserves_both_arc_endpoints(self):
        self.lua.execute('''
            local packet={};local cursor=0;local receive
            local function put(v) packet[#packet+1]=v end
            local function take() cursor=cursor+1;return packet[cursor] end
            local message={WriteByte=put,WriteUInt16=put,WriteSingle=put,
                ReadByte=take,ReadUInt16=take,ReadSingle=take}
            local env={SERVER=true,Game={IsSingleplayer=false,Server={}},Timer={GetTime=function() return 0 end},
                Networking={Start=function() return message end,Send=function() end}}
            local server={direction=function() return {},0 end}
            require('CombatTool.network').install(server,env)
            server.event('arc',{item={ID=17}},{x=5,y=10},{x=30,y=40})
            local client={onEffect=function(kind,point,_,id,endpoint)
                assert(kind=='arc' and id==17 and point.x==5 and point.y==10)
                assert(endpoint.x==30 and endpoint.y==40,'network lost the arc destination')
                received=true
            end}
            require('CombatTool.network').install(client,{CLIENT=true,Game={IsSingleplayer=false},
                Timer=env.Timer,Networking={Receive=function(name,fn) if name:find('effect') then receive=fn end end}})
            receive(message);assert(received,'client ignored the secondary arc')
        ''')

    def test_electric_stun_uses_afflictions_inside_native_friendly_fire_gate(self):
        self.lua.execute('''
            local function prefab(kind) return {Instantiate=function(n) return {kind=kind,strength=n} end} end
            local P={}
            require('CombatTool.physics').install(P,{Vector2=setmetatable({Zero={}},
                {__call=function(_,x,y) return {X=x,Y=y} end}),
                AfflictionPrefab={Prefabs={burn=prefab('burn'),stun=prefab('stun')}}})
            assert(P.shock,'electrical affliction delivery is missing')
            P.shock({AddDamage=function(_,afflictions,stun,_,_,attacker)
                assert(stun==0,'native stun argument bypasses friendly-fire protection')
                assert(#afflictions==2 and afflictions[2].kind=='stun' and afflictions[2].strength==.2)
                assert(attacker==owner);delivered=true
            end},{x=1,y=2},owner,1,.2)
            assert(delivered)
        ''')
