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
                CollisionItemBlocking=8,CollisionProjectile=16,CollisionLagCompensationBody=32}
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
            G={};require('CombatTool.physics').install(G,env)
        ''')

    def test_platform_and_stair_fixtures_do_not_bounce_rings(self):
        self.lua.execute('''
            fixtures={fixture(64,10),fixture(128,20),fixture(2,80)}
            local hit=G.cast({x=0,y=0},{x=100,y=0},0,nil,true)
            assert(hit and hit.x==80,'platform or stairs blocked the passage before the real wall')
        ''')

    def test_repair_target_for_destroyed_wall_does_not_close_its_hole(self):
        self.lua.execute('''
            fixtures={fixture(256,15)}
            assert(not G.cast({x=0,y=0},{x=100,y=0},0,nil,true),'repair-only fixture blocked an open hole')
        ''')

    def test_disabled_collision_fixture_is_ignored_but_solid_wall_remains(self):
        self.lua.execute('''
            local disabled=fixture(2,10);disabled.CollidesWith=0
            fixtures={disabled,fixture(2,60)}
            local hit=G.cast({x=0,y=0},{x=100,y=0},0,nil,true)
            assert(hit and hit.x==60,'disabled collision fixture caused a false ricochet')
        ''')
