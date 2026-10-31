from lua_support import LuaCase


class ProjectileRegressionTests(LuaCase):
    def test_rings_delegate_friendly_fire_to_native_damage(self):
        self.lua.execute('''
            local C=require('CombatTool.core')
            local owner,target={},{}
            local gun={WorldPosition={X=0,Y=0}}
            local G={flags=function() return {damage=true} end,state=function() return {} end,
                findShield=function() return nil end,event=function() end,
                cast=function(a,b,r,who,walls,allCharacters)
                    assert(who==owner and not walls)
                    if allCharacters then return {t=.5,x=10,y=0,kind='character',target=target} end
                end,
                damage=function(hit) assert(hit==target);damaged=true end}
            require('CombatTool.projectiles').install(G,{})
            local ring=C.ring({x=0,y=0},{x=1,y=0},0)
            ring.owner=owner;ring.weapon=gun;G.rings={ring}
            G.updateRings(.02)
        ''')
        self.assertTrue(self.lua.globals().damaged)

    def test_impact_orientation_uses_wall_normal(self):
        self.lua.execute('''
            local G={now=0,direction=function() return {x=1,y=0},0 end,
                onEffect=function(_,_,angle) impactAngle=angle end}
            require('CombatTool.network').install(G,{Game={IsSingleplayer=true},Timer={GetTime=function() return 0 end}})
            G.event('bounce',{item={ID=1}},{x=0,y=0,nx=0,ny=1})
        ''')
        self.assertAlmostEqual(self.lua.globals().impactAngle,1.5707963267948966)
