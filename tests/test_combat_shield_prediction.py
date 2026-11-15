from lua_support import LuaCase


class ClientShieldPredictionTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function v(x,y) return {X=x,Y=y} end
            defender={TeamID=1};attacker={TeamID=2,IsOnPlayerTeam=false}
            gun={ID=42,Prefab={Identifier={Value='combatmultitool'}},WorldPosition=v(0,0),
                body={TransformedRotation=0,DrawPosition=v(0,0),DrawRotation=0,Dir=1,
                    UpdateDrawPosition=function() end}}
            env={Game={IsSingleplayer=false,ServerSettings={AllowFriendlyFire=true}},
                Sprite=function() return {} end,Vector2=v,GUI={},
                LuaUserData={RegisterType=function() end,CreateEnumTable=function() return {} end,
                    CreateStatic=function() return {} end},
                Entity={FindEntityByID=function(id) if id==42 then return gun end end}}
            G=require('CombatTool.game').new(env)
            require('CombatTool.physics').install(G,env)
            hooks={};G.patch=function(id,_,_,fn) hooks[id]=fn end
            G.cast=function() end;G.owner=function() return defender end
            G.friendly=function() return false end
            require('CombatTool.visuals').install(G,env,'mod')
            G.authoritative=false
            G.remote={received=0,rings={},shields={{id=42,x=0,y=0,angle=0,energy=100}}}
            require('CombatTool.shield_client').install(G,env)
            health=100;damageCalls=0
            projectile={User=attacker,FriendlyFire=true,MaxTargetsToHit=3,
                Item={WorldPosition=v(120,0),body={Enabled=true}}}
            projectile.Item.Move=function(delta)
                local pos=projectile.Item.WorldPosition
                projectile.Item.WorldPosition=v(pos.X+delta.X,pos.Y+delta.Y)
            end
            function start()
                if hooks['client-shield-start'] then hooks['client-shield-start'](projectile,{}) end
            end
            function collision(x,y)
                projectile.Item.WorldPosition=v(x,y)
                params={}
                local result
                if hooks['client-shield-collision'] then result=hooks['client-shield-collision'](projectile,params) end
                if not params.PreventExecution then health=health-20;damageCalls=damageCalls+1;result=true end
                params.ReturnValue=result
                if hooks['client-shield-result'] then hooks['client-shield-result'](projectile,params) end
                return params.PreventExecution or false
            end
            function finish()
                if hooks['client-shield-finish'] then hooks['client-shield-finish'](projectile,{}) end
            end
        ''')

    def test_confirmed_shield_stops_local_damage_before_health_changes(self):
        self.lua.execute('start();blocked=collision(0,0);finish()')
        self.assertTrue(self.lua.globals().blocked)
        self.assertEqual(self.lua.globals().damageCalls, 0)
        self.assertEqual(self.lua.globals().health, 100)
        self.assertEqual(self.lua.eval('projectile.Item.WorldPosition.X'), 80)
        self.assertEqual(self.lua.eval('G.remote.shields[1].energy'), 100)
        self.assertEqual(self.lua.eval('projectile.MaxTargetsToHit'), 3)
        self.assertTrue(self.lua.eval('projectile.Item.body.Enabled'))

    def test_unshielded_control_still_receives_local_damage(self):
        self.lua.execute('G.remote.shields={};start();blocked=collision(0,0);finish()')
        self.assertFalse(self.lua.globals().blocked)
        self.assertEqual(self.lua.globals().damageCalls, 1)
        self.assertEqual(self.lua.globals().health, 80)

    def test_rear_inside_empty_expired_and_wall_clipped_shots_are_not_suppressed(self):
        for setup in ['projectile.Item.WorldPosition=env.Vector2(-120,0)',
                      'projectile.Item.WorldPosition=env.Vector2(40,0)',
                      'G.remote.shields[1].energy=.5', 'G.now=.6',
                      "G.cast=function() return {kind='wall',t=.1} end"]:
            with self.subTest(setup=setup):
                self.setUp()
                self.lua.execute(setup+';start();collision(0,0);finish()')
                self.assertEqual(self.lua.globals().damageCalls, 1)

    def test_current_physics_pose_is_used_for_collision_instead_of_render_interpolation(self):
        self.lua.execute('gun.body.DrawPosition=env.Vector2(500,0);start();collision(0,0);finish()')
        self.assertEqual(self.lua.globals().damageCalls, 0)

    def test_blocked_tracer_is_placed_on_rendered_arc_after_physics_interception(self):
        self.lua.execute('gun.body.DrawPosition=env.Vector2(10,0);start();collision(0,0);finish()')
        self.assertEqual(self.lua.globals().damageCalls, 0)
        self.assertEqual(self.lua.eval('projectile.Item.WorldPosition.X'), 90)

    def test_native_hits_before_shield_are_preserved(self):
        self.lua.execute('start();first=collision(110,0);second=collision(0,0);finish()')
        self.assertFalse(self.lua.globals().first)
        self.assertTrue(self.lua.globals().second)
        self.assertEqual(self.lua.globals().damageCalls, 1)
        self.assertEqual(self.lua.globals().health, 80)

    def test_collision_after_hitscan_finishes_is_not_given_shield_immunity(self):
        self.lua.execute('start();collision(0,0);finish();collision(0,0)')
        self.assertEqual(self.lua.globals().damageCalls, 1)

    def test_singleplayer_does_not_duplicate_authoritative_shield_hooks(self):
        self.lua.execute('G.authoritative=true;start();collision(0,0);finish()')
        self.assertEqual(self.lua.globals().damageCalls, 1)

    def test_next_pellet_gets_a_fresh_scan_and_original_target_limit(self):
        self.lua.execute('''
            for _=1,2 do
                projectile.Item.WorldPosition=env.Vector2(120,0)
                start();collision(0,0);finish()
                assert(projectile.MaxTargetsToHit==3)
            end
        ''')
        self.assertEqual(self.lua.globals().damageCalls, 0)

    def test_round_cleanup_removes_in_progress_prediction(self):
        self.lua.execute('start();G.clearShieldTracking();collision(0,0)')
        self.assertEqual(self.lua.globals().damageCalls, 1)
