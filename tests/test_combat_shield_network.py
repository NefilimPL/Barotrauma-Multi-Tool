from lua_support import LuaCase


class ShieldFriendlyFireTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            env={Game={IsSingleplayer=false,ServerSettings={AllowFriendlyFire=true}},Entity={}}
            G=require('CombatTool.game').new(env)
            require('CombatTool.physics').install(G,env)
            hooks={};G.patch=function(id,_,_,fn) hooks[id]=fn end
            G.cast=function() end;G.event=function() end
            require('CombatTool.shield').install(G,env)
            defender={TeamID=1,IsFriendly=function() return true end}
            attacker={TeamID=1,IsOnPlayerTeam=true,IsFriendly=defender.IsFriendly}
            battery={Condition=100,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            gun={ID=1,WorldPosition={X=0,Y=0},OwnInventory={GetItemAt=function() return battery end}}
            state=G.state(gun);state.owner=defender
            state.shield={x=0,y=0,radius=80,angle=0,halfAngle=math.pi/3}
            function shoot(friendlyFire)
                local item={WorldPosition={X=100,Y=0},body={Enabled=true}}
                projectile={Item=item,IsActive=true,User=attacker,FriendlyFire=friendlyFire,
                    Attack={GetTotalCharacterDamage=function() return 20 end}}
                hooks['projectile-launch'](projectile,{})
                item.WorldPosition={X=0,Y=0}
                params={};hooks['projectile-update'](projectile,params)
            end
        ''')

    def test_server_blocks_crew_bullet_when_friendly_fire_is_enabled(self):
        self.lua.execute('shoot(true)')
        self.assertFalse(self.lua.eval('projectile.IsActive'))
        self.assertTrue(self.lua.eval('params.PreventExecution'))
        self.assertEqual(self.lua.eval('battery.Condition'), 98)

    def test_turning_weapon_refreshes_collision_arc_before_next_shield_tick(self):
        self.lua.execute('''
            gun.body={TransformedRotation=math.pi}
            local bullet={Item={WorldPosition={X=-120,Y=0},body={Enabled=true}},
                IsActive=true,User=attacker,FriendlyFire=true}
            hooks['projectile-launch'](bullet,{})
            bullet.Item.WorldPosition={X=0,Y=0}
            hooks['projectile-update'](bullet,{})
            assert(not bullet.IsActive and battery.Condition==98,
                'bullet used the old right-facing arc after the weapon turned left')
        ''')

    def test_moving_weapon_refreshes_collision_center_before_next_shield_tick(self):
        self.lua.execute('''
            gun.body={TransformedRotation=0};gun.WorldPosition={X=200,Y=0}
            local bullet={Item={WorldPosition={X=300,Y=0},body={Enabled=true}},
                IsActive=true,User=attacker,FriendlyFire=true}
            hooks['projectile-launch'](bullet,{})
            bullet.Item.WorldPosition={X=200,Y=0}
            hooks['projectile-update'](bullet,{})
            assert(not bullet.IsActive and battery.Condition==98,
                'bullet used the old arc center after the weapon moved')
        ''')

    def test_disabled_server_friendly_fire_does_not_drain_shield(self):
        self.lua.execute('env.Game.ServerSettings.AllowFriendlyFire=false;shoot(true)')
        self.assertTrue(self.lua.eval('projectile.IsActive'))
        self.assertEqual(self.lua.eval('battery.Condition'), 100)

    def test_turning_held_weapon_blocks_before_protruding_arm_fixture(self):
        # Native server capture: weapon turns left while the arm still occupies
        # the preceding pose. The arm fixture is hit 4 units before the old arc.
        self.lua.execute('''
            gun.WorldPosition={X=14.274,Y=.742}
            gun.body={TransformedRotation=math.pi}
            local hit=G.findShield({x=-239.686,y=25.023},
                {x=-40.75,y=24.469},attacker,nil,true)
            assert(hit,'native arm fixture is in front of the protective arc')
            assert(hit.x < -40.75,'shield must stop the bullet before the arm')
        ''')

    def test_projectile_friendly_fire_opt_out_does_not_drain_shield(self):
        self.lua.execute('shoot(false)')
        self.assertTrue(self.lua.eval('projectile.IsActive'))
        self.assertEqual(self.lua.eval('battery.Condition'), 100)

    def test_own_projectile_is_never_blocked(self):
        self.lua.execute('attacker=defender;shoot(true)')
        self.assertTrue(self.lua.eval('projectile.IsActive'))
        self.assertEqual(self.lua.eval('battery.Condition'), 100)

    def test_faction_npc_bullet_is_blocked_even_with_server_friendly_fire_disabled(self):
        # Faction hostility does not change Character.IsFriendly's team result.
        # Native damage still allows NPC -> player shots when crew FF is off.
        self.lua.execute('''
            env.Game.ServerSettings.AllowFriendlyFire=false
            attacker.TeamID=3;attacker.IsOnPlayerTeam=false
            shoot(true)
        ''')
        self.assertFalse(self.lua.eval('projectile.IsActive'))
        self.assertEqual(self.lua.eval('battery.Condition'), 98)

    def test_faction_npc_ring_is_blocked_with_server_friendly_fire_disabled(self):
        self.lua.execute('''
            env.Game.ServerSettings.AllowFriendlyFire=false
            attacker.TeamID=3;attacker.IsOnPlayerTeam=false
            local Core=require('CombatTool.core')
            G.flags=function() return {damage=true} end
            require('CombatTool.projectiles').install(G,env)
            local ring=Core.ring({x=100,y=0},{x=-1,y=0},0)
            ring.owner=attacker;ring.weapon={};G.rings={ring}
            G.updateRings(.05)
        ''')
        self.assertEqual(self.lua.eval('#G.rings'), 0)
        self.assertLess(self.lua.eval('battery.Condition'), 100)

    def test_crew_ring_uses_same_server_friendly_fire_policy(self):
        self.lua.execute('''
            local Core=require('CombatTool.core')
            G.flags=function() return {damage=true} end
            require('CombatTool.projectiles').install(G,env)
            local ring=Core.ring({x=100,y=0},{x=-1,y=0},0)
            ring.owner=attacker;ring.weapon={};G.rings={ring}
            G.updateRings(.05)
        ''')
        self.assertEqual(self.lua.eval('#G.rings'), 0)
        self.assertLess(self.lua.eval('battery.Condition'), 100)


class ShieldRenderSynchronizationTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function v(x,y) return {X=x,Y=y} end
            body={DrawPosition=v(30,40),DrawRotation=math.pi/2,Dir=1,
                TransformedRotation=0,UpdateDrawPosition=function() refreshed=true end}
            gun={ID=42,Prefab={Identifier={Value='combatmultitool'}},body=body,
                WorldPosition=v(1000,2000),Components={}}
            env={Sprite=function() return {Draw=function(_,pos,_,_,rotation)
                    drawCount=drawCount+1;drawX=pos.X;drawY=pos.Y;drawAngle=rotation
                end} end,Vector2=v,Color=function() return {} end,
                Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,
                GUI={GUI={DrawLine=function() end}},
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,
                    CreateStatic=function() return {} end},
                Entity={FindEntityByID=function(id) if id==42 then return gun end end}}
            G=require('CombatTool.game').new(env)
            require('CombatTool.physics').install(G,env)
            G.patch=function() end;G.cast=function() end
            require('CombatTool.visuals').install(G,env,'mod')
            G.authoritative=false
            G.remote={received=0,rings={},shields={{id=42,x=-100,y=-200,angle=0,energy=70}}}
            camera={Zoom=1,WorldToScreen=function(p) return p end}
            function draw() drawCount=0;G.draw({},camera) end
        ''')

    def test_confirmed_client_shield_tracks_rendered_weapon_between_snapshots(self):
        self.lua.execute('draw()')
        self.assertAlmostEqual(self.lua.globals().drawX, 30)
        self.assertAlmostEqual(self.lua.globals().drawY, 100)
        self.assertAlmostEqual(self.lua.globals().drawAngle, -1.5707963267948966)
        self.lua.execute('body.DrawPosition={X=80,Y=90};body.Dir=-1;draw()')
        self.assertAlmostEqual(self.lua.globals().drawX, 80)
        self.assertAlmostEqual(self.lua.globals().drawY, 30)
        self.assertAlmostEqual(self.lua.globals().drawAngle, 1.5707963267948966)
        self.assertEqual(self.lua.eval('G.remote.shields[1].x'), -100)

    def test_host_shield_also_tracks_rendered_pose_without_mutating_collision_arc(self):
        self.lua.execute('''
            G.authoritative=true;G.rings={};G.source=function() return {condition=70} end
            state=G.state(gun);state.shield={x=-100,y=-200,angle=0}
            draw()
        ''')
        self.assertAlmostEqual(self.lua.globals().drawX, 30)
        self.assertAlmostEqual(self.lua.globals().drawY, 100)
        self.assertEqual(self.lua.eval('state.shield.x'), -100)

    def test_client_never_draws_unconfirmed_or_expired_shield(self):
        self.lua.execute('G.state(gun);G.remote.shields={};draw()')
        self.assertEqual(self.lua.globals().drawCount, 0)
        self.lua.execute('G.remote.shields={{id=42,x=0,y=0,angle=0}};G.now=.6;draw()')
        self.assertEqual(self.lua.globals().drawCount, 0)

    def test_missing_weapon_uses_snapshot_position(self):
        self.lua.execute('env.Entity.FindEntityByID=function() end;draw()')
        self.assertAlmostEqual(self.lua.globals().drawX, -40)
        self.assertAlmostEqual(self.lua.globals().drawY, -200)
