from lua_support import LuaCase


class ShieldContactSamplingTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            reads=0;damage=0;point={X=500,Y=0}
            local limb=setmetatable({IsSevered=false},{__index=function(_,key)
                if key=='WorldPosition' then reads=reads+1;return point end
            end})
            target={WorldPosition={X=10000,Y=0},AnimController={Limbs={limb}}}
            E={SERVER=true,Game={},Character={CharacterList={target}}}
            G={now=1,states={},patch=function() end,
                direction=function() return {x=1,y=0},0 end,
                powered=function() return true end,spend=function() return true end,
                friendly=function() return false end,cast=function() end,event=function() end,
                shieldDebit=function() return true,false end,
                damage=function() damage=damage+1;point={X=500,Y=0} end}
            require('AegisCombat.shield').install(G,E)
            a={item={WorldPosition={X=0,Y=0}},brokenUntil=0,contactTimes={}}
            b={item={WorldPosition={X=0,Y=0}},brokenUntil=0,contactTimes={}}
            ctx={valid=true,aim=true,damage=true,owner={}}
        """)

    def test_multiple_shields_share_limb_reads_in_one_explicit_update_scope(self):
        self.lua.execute("""
            local contacts={}
            G.updateShield(a,ctx,1/60,contacts);G.updateShield(b,ctx,1/60,contacts)
            assert(reads==1,'same native limb sampled separately for every shield: '..reads)
        """)

    def test_cached_distant_limbs_skip_repeated_native_friendly_checks(self):
        self.lua.execute("""
            local friendlyChecks=0
            G.friendly=function() friendlyChecks=friendlyChecks+1;return false end
            local contacts={}
            G.updateShield(a,ctx,1/60,contacts);G.updateShield(b,ctx,1/60,contacts)
            assert(friendlyChecks==1 and reads==1 and damage==0,
                'a distant limb snapshot was reconsidered by the second shield')
            b.item.WorldPosition={X=420,Y=0}
            G.updateShield(b,ctx,1/60,contacts)
            assert(friendlyChecks==2 and reads==1 and damage==1,
                'a second shield within reach must still use the shared snapshot')
        """)

    def test_direct_calls_without_a_scope_always_read_current_position(self):
        self.lua.execute("""
            G.updateShield(a,ctx,1/60);point={X=80,Y=0}
            G.updateShield(b,ctx,1/60)
            assert(reads==2 and damage==1,'direct call reused obsolete limb positions')
        """)

    def test_contact_side_effects_invalidate_shared_positions_before_next_shield(self):
        self.lua.execute("""
            point={X=80,Y=0};local contacts={}
            G.updateShield(a,ctx,1/60,contacts);G.updateShield(b,ctx,1/60,contacts)
            assert(damage==1 and reads==2,'another shield hit the position preceding the damage callback')
        """)

    def test_distant_character_origin_does_not_hide_a_long_limb_at_the_shield(self):
        self.lua.execute("""
            point={X=80,Y=0};G.updateShield(a,ctx,1/60,{})
            assert(damage==1,'large or stretched creature was rejected by its distant center')
        """)

    def test_shield_break_callback_also_invalidates_positions(self):
        self.lua.execute("""
            point={X=80,Y=0};local contacts={}
            G.shieldDebit=function() return false,true end
            G.event=function(kind) if kind=='break' then point={X=500,Y=0} end end
            G.updateShield(a,ctx,1/60,contacts);G.updateShield(b,ctx,1/60,contacts)
            assert(reads==2,'shield break side effect left stale contact positions')
        """)

    def test_idle_power_failure_invalidates_prior_shield_samples(self):
        self.lua.execute("""
            local contacts={}
            G.updateShield(a,ctx,1/60,contacts)
            G.spend=function(item) return item~=b.item end
            G.source=function() end
            G.event=function(kind) if kind=='break' then point={X=80,Y=0} end end
            G.updateShield(b,ctx,1/60,contacts)
            G.updateShield(a,ctx,1/60,contacts)
            assert(reads==2 and damage==1,'power-failure break left earlier shield samples stale')
        """)
