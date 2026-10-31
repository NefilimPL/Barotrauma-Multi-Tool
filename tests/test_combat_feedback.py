from lua_support import LuaCase


class CombatFeedbackTests(LuaCase):
    def test_snapshot_keeps_trail_but_never_links_it_through_a_wall(self):
        self.lua.execute('''
            local G={now=0,cast=function() return nil end}
            local E={CLIENT=true,Game={IsSingleplayer=false},Timer={GetTime=function() return 0 end},
                Networking={Receive=function(name,fn) if name:find('snapshot') then receive=fn end end}}
            require('CombatTool.network').install(G,E)
            local trail={{x=0,y=0,age=0}}
            G.remote={epoch=100,rings={{id=4,x=0,y=0,trail=trail}},shields={}}
            local function packet(sequence)
                local u32,u16,single={100,sequence},{0,1,4},{10,0,1,0,6,.1,10}
                local a,b,c=0,0,0
                return {ReadUInt32=function() a=a+1;return u32[a] end,
                    ReadUInt16=function() b=b+1;return u16[b] end,
                    ReadSingle=function() c=c+1;return single[c] end,ReadByte=function() return 1 end}
            end
            receive(packet(1));assert(G.remote.rings[1].trail==trail)
            G.cast=function() return {kind='wall'} end
            receive(packet(2));assert(G.remote.rings[1].trail==nil)
        ''')

    def test_continuous_fire_is_faster_but_travel_is_slower(self):
        self.lua.execute('''
            local C=require('CombatTool.config')
            local G=require('CombatTool.game').new({})
            local gun={ID=1};local component={Item=gun,Name='RangedWeapon'}
            G.context=function() return {valid=true,aim=true,damage=true,mode='combat'} end
            G.canSpend=function() return true end;G.spend=function() return true end
            shots=0;G.fire=function() shots=shots+1 end
            for i=0,120 do G.now=i/60;G.frame=i;G.use(component,nil,1/60) end
            assert(C.speed<1400 and C.speed>=800)
            assert(C.speed*C.lifetime>=C.maxDistance,'slower ring lost its previous range')
        ''')
        self.assertGreaterEqual(self.lua.globals().shots,4)

    def test_trail_preserves_the_actual_ricochet_corner_and_stays_bounded(self):
        self.lua.execute('''
            local C=require('CombatTool.core')
            local ring=C.ring({x=0,y=0},{x=1,y=0},0)
            ring.speed=200
            C.advanceRing(ring,.1,function(a,b)
                if b.x>10 then return {t=(10-a.x)/(b.x-a.x),x=10,y=0,nx=-1,ny=0,kind='wall'} end
            end)
            assert(ring.trail and #ring.trail>=3)
            assert(ring.trail[2].x==10,'trail cut across a reflected path')
            for i=1,100 do C.advanceRing(ring,.01,function() end) end
            assert(#ring.trail<=12)
        ''')

    def test_terminal_wall_hit_has_an_event_and_character_hit_has_impulse(self):
        self.lua.execute('''
            local Core=require('CombatTool.core')
            local gun={};local target={}
            local G={flags=function() return {damage=true} end,state=function() return {} end,
                findShield=function() return nil end,
                cast=function() return {t=.5,x=5,y=0,kind=kind,target=target,nx=-1,ny=0} end,
                event=function(event) lastEvent=event end,
                damage=function(_,_,_,_,_,_,impulse) deliveredImpulse=impulse end}
            require('CombatTool.projectiles').install(G,{})
            function fire(kindValue)
                kind=kindValue
                local r=Core.ring({x=0,y=0},{x=1,y=0},0)
                r.weapon=gun;r.bouncesLeft=0;G.rings={r};G.updateRings(.02)
            end
            fire('wall');assert(lastEvent=='wallhit','last wall contact was silent')
            fire('character');assert(deliveredImpulse and deliveredImpulse.x>0 and deliveredImpulse.y==0)
        ''')

    def test_impulse_flows_through_native_damage_not_a_separate_force(self):
        self.lua.execute('''
            local G={}
            local E={Vector2=setmetatable({Zero={X=0,Y=0}},{__call=function(_,x,y) return {X=x,Y=y} end}),
                AfflictionPrefab={Prefabs={burn={Instantiate=function(n) return n end}}}}
            require('CombatTool.physics').install(G,E)
            G.damage({AddDamage=function(_,_,_,_,impulse) actualImpulse=impulse end},
                {x=1,y=2},nil,1,0,0,{x=7,y=0})
        ''')
        self.assertEqual(self.lua.eval('actualImpulse.X'),7)

    def test_audio_is_spatial_and_only_runs_on_event(self):
        self.lua.execute('''
            local G={};local E={Vector2=function(x,y) return {X=x,Y=y} end,
                SoundPlayer={PlaySound=function(tag,position) calls=(calls or 0)+1;soundTag=tag;soundPosition=position end}}
            require('CombatTool.audio').install(G,E)
            G.playCombatSound('shot',{x=12,y=34})
            assert(soundTag=='aegis_shot' and soundPosition.X==12 and soundPosition.Y==34)
            G.playCombatSound('wallhit',{x=4,y=8});assert(soundTag=='aegis_wallhit')
            G.playCombatSound('hit',{x=4,y=8});assert(soundTag=='aegis_bodyhit')
            G.playCombatSound('unknown',{x=0,y=0})
        ''')
        self.assertEqual(self.lua.globals().calls,3)
