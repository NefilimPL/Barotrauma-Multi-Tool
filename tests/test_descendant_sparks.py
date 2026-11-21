from lua_support import LuaCase


class DescendantNativeSparkTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            emitted={};screen={X=100,Y=100}
            E={Vector2=function(x,y) return {X=x,Y=y} end,
                GUI={GUI={Canvas={Rect={Width=800,Height=600}}}},
                Game={GameScreen={Cam={WorldToScreen=function() return screen end}},
                    ParticleManager={CreateParticle=function(id,p,v)
                        emitted[#emitted+1]={id=id,p=p,v=v};return {}
                    end}}}
            emit=require('DescendantSuit.sparks').new(E)
            state={};point={x=10,y=20}
        """)

    def test_preserves_visible_emission_rate_using_native_particles(self):
        self.lua.execute("""
            for i=1,60 do emit(state,'repair',point,1/60) end
            assert(#emitted==150,'changed normal repair spark density')
            for _,p in ipairs(emitted) do
                assert(p.id=='descendantrepairspark' and p.p.X==10 and p.p.Y==20)
                local speed=math.sqrt(p.v.X^2+p.v.Y^2)
                assert(speed>=80 and speed<=280)
            end
            assert(state.sparks==nil,'Lua still owns per-frame spark arrays')
        """)

    def test_offscreen_sparks_do_not_accumulate_or_burst_when_camera_returns(self):
        self.lua.execute("""
            screen={X=10000,Y=100}
            for i=1,120 do emit(state,'weld',point,1/60) end
            assert(#emitted==0 and state.sparkBudget==0)
            screen={X=100,Y=100};emit(state,'weld',point,1/60)
            assert(#emitted<=3,'offscreen work causes delayed particle burst')
        """)

    def test_large_dt_and_mode_changes_cannot_create_unbounded_bursts(self):
        self.lua.execute("""
            emit(state,'repair',point,10);assert(#emitted<=15)
            state.sparkBudget=.9;emit(state,'combat',point,1/60)
            assert(state.sparkBudget==0)
            emit(state,'repair',nil,1/60);assert(state.sparkBudget==0)
        """)
