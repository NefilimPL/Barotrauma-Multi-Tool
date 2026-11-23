from lua_support import LuaCase


class PassageCollisionTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function vec(x,y)
                return setmetatable({X=x,Y=y},{__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y) end,
                    __sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y) end})
            end
            local physics={CollisionNone=0,CollisionCharacter=1,CollisionWall=2,CollisionLevel=4,
                CollisionItemBlocking=8,CollisionProjectile=16,CollisionLagCompensationBody=32,CollisionPlatform=64}
            env={LuaUserData={IsTargetType=function(value,name) return value.kind==name end,
                    RegisterType=function() end,CreateStatic=function() return physics end,
                    CreateEnumTable=function() return {None=0} end},
                Submarine={Loaded={}},Vector2=setmetatable({Zero=vec(0,0)},{__call=function(_,x,y) return vec(x,y) end}),
                ConvertUnits={ToSimUnits=function(v) return v end,ToDisplayUnits=function(v) return v end},
                Game={World={RayCast=function(callback,a,b,mask)
                    for _,f in ipairs(fixtures) do
                        if not mask or bit32.band(f.CollisionCategories,mask)~=0 then
                            callback(f,vec(f.distance,0),vec(-1,0),f.distance/100)
                        end
                    end
                end}}}
            function fixture(category,distance,collides)
                return {Body={UserData={kind='Barotrauma.Structure'}},CollisionCategories=category,
                    CollidesWith=collides or 1,distance=distance}
            end
            G={};require('AegisCombat.physics').install(G,env)
        ''')

    def test_platform_and_stair_fixtures_do_not_bounce_rings(self):
        self.lua.execute('''
            fixtures={fixture(64,10),fixture(128,20),fixture(2,80)}
            local hit=G.cast({x=0,y=0},{x=100,y=0},0,nil,true)
            assert(hit and hit.x==80,'platform or stairs blocked the passage before the real wall')
        ''')

    def test_wall_cast_returns_the_actual_blocking_structure(self):
        self.lua.execute('''
            local f=fixture(2,60);fixtures={f}
            local hit=G.cast({x=0,y=0},{x=100,y=0},0,nil,true)
            assert(hit.blocker==f.Body.UserData)
        ''')

    def test_grip_path_detours_around_blocking_equipment_and_ignores_its_own_target(self):
        self.lua.execute('''
            local held=fixture(8,20)
            local obstacle=fixture(8,50)
            held.Body.UserData.kind='Barotrauma.Item'
            obstacle.Body.UserData.kind='Barotrauma.Item'
            fixtures={held,obstacle}
            local a,b={x=0,y=0},{x=100,y=0}
            local hit=G.cast(a,b,0,nil,true,false,held.Body.UserData)
            assert(hit and hit.blocker==obstacle.Body.UserData,'grip path missed blocking equipment')
            assert(not G.cast(a,b,0,nil,true),'equipment changed the normal weapon ray')
        ''')

    def test_repair_target_for_destroyed_wall_does_not_close_its_hole(self):
        self.lua.execute('''
            fixtures={fixture(256,15)}
            assert(not G.cast({x=0,y=0},{x=100,y=0},0,nil,true),'repair-only fixture blocked an open hole')
        ''')

    def test_item_haul_paths_respect_platforms_that_the_ragdoll_can_pass(self):
        self.lua.execute('''
            local platform=fixture(64,30);fixtures={platform}
            local a,b={x=0,y=0},{x=100,y=0}
            local held={kind='Barotrauma.Item'}
            local hit=G.cast(a,b,12,nil,true,false,held,true)
            assert(hit and hit.blocker==platform.Body.UserData,'item route guides through a platform')
            assert(not G.cast(a,b,12,nil,true,false,{kind='Barotrauma.Character'}))
        ''')

    def test_disabled_collision_fixture_is_ignored_but_solid_wall_remains(self):
        self.lua.execute('''
            local disabled=fixture(2,10);disabled.CollidesWith=0
            fixtures={disabled,fixture(2,60)}
            local hit=G.cast({x=0,y=0},{x=100,y=0},0,nil,true)
            assert(hit and hit.x==60,'disabled collision fixture caused a false ricochet')
        ''')

    def test_closest_hit_clips_native_traversal_without_hiding_a_nearer_later_fixture(self):
        self.lua.execute('''
            local visited=0
            fixtures={fixture(2,90),fixture(2,10),fixture(2,80),fixture(2,5)}
            env.Game.World.RayCast=function(callback,a,b,mask)
                local limit=1
                for _,f in ipairs(fixtures) do
                    local fraction=f.distance/100
                    if fraction<=limit then
                        visited=visited+1
                        local result=callback(f,env.Vector2(f.distance,0),env.Vector2(-1,0),fraction)
                        if result>=0 then limit=result end
                        if result==0 then break end
                    end
                end
            end
            local hit=G.cast({x=0,y=0},{x=100,y=0},0,nil,true)
            assert(hit and hit.x==5,'clipped a closer fixture later in traversal')
            assert(visited==3,'native traversal still visits walls behind the nearest hit: '..visited)
        ''')
