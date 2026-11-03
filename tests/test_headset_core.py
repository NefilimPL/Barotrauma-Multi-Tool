from lua_support import LuaCase


class HeadsetCoreTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("H=require('AegisHeadset.core');T=require('AegisHeadset.treatments')")

    def test_debit_never_creates_power_and_reports_partial_payment(self):
        self.assertEqual(self.lua.eval('function() return H.debit(2,5) end')(), (0, .4))
        self.assertEqual(self.lua.eval('function() return H.debit(100,5) end')(), (95, 1))
        self.assertEqual(self.lua.eval('function() return H.debit(0,5) end')(), (0, 0))

    def test_large_hit_requires_more_power_and_partial_hit_survives(self):
        self.assertEqual(self.lua.eval('function() return H.absorb(5,20) end')(), (0, 10))
        self.assertEqual(self.lua.eval('function() return H.absorb(50,20) end')(), (40, 0))
        self.assertEqual(self.lua.eval('function() return H.absorb(10,.1) end')(), (9, 0))

    def test_zero_damage_does_not_spend_power(self):
        self.assertEqual(self.lua.eval('function() return H.absorb(8,0) end')(), (8, 0))

    def test_unknown_future_mod_disease_is_treated_without_allowlist(self):
        self.assertEqual(self.lua.eval("T.classify({id='futuremod_radiant_plague',isBuff=false}).target"), 0)

    def test_buffs_genetics_and_blood_types_are_preserved(self):
        self.lua.execute("""
            assert(T.classify({id='strongbuff',isBuff=true})==nil)
            assert(T.classify({id='x',type='talentbuff'})==nil)
            assert(T.classify({id='x',type='geneticmaterialbuff'})==nil)
        """)

    def test_explicit_homeostasis_can_increase_a_buff_to_healthy_value(self):
        self.lua.execute("T.register('pressure',{target=100,priority=90});p=T.classify({id='pressure',isBuff=true})")
        self.assertEqual(self.lua.eval('p.target'), 100)

    def test_provider_can_exempt_implants_even_if_marked_nonbuff(self):
        self.lua.execute("T.register('customimplant',{preserve=true})")
        self.assertIsNone(self.lua.eval("T.classify({id='customimplant'})"))

    def test_many_mod_afflictions_share_one_healing_budget(self):
        self.lua.execute("""
            entries={}
            for i=1,100 do entries[i]={id='disease'..i,strength=10,policy={target=0,priority=0}} end
            actions=T.plan(entries,5);total=0
            for _,a in ipairs(actions) do total=total+math.abs(a.value-a.entry.strength) end
        """)
        self.assertAlmostEqual(self.lua.eval('total'), 5)
        self.assertEqual(self.lua.eval('#actions'), 100)

    def test_high_priority_life_threat_is_treated_first(self):
        self.lua.execute("""
            a={id='bruise',strength=100,policy={target=0,priority=0}}
            b={id='bleeding',strength=20,policy={target=0,priority=100}}
            actions=T.plan({a,b},5)
            assert(#actions==1 and actions[1].entry==b and actions[1].value==15)
        """)

    def test_homeostasis_stops_at_target_and_anatomy_is_not_erased(self):
        self.lua.execute("""
            actions=T.plan({{id='pressure',strength=98,policy={target=100}},
                {id='missingorgan',strength=100,policy={anatomy='organ',target=0}}},50)
            assert(#actions==1 and actions[1].value==100)
        """)

    def test_anatomy_progress_requires_full_payment_over_time(self):
        self.lua.execute("""
            job={paid=0};energy=100
            for i=1,9 do energy,done=H.advanceJob(job,energy,1,25,10);assert(not done) end
            energy,done=H.advanceJob(job,energy,1,25,10)
            assert(done and math.abs(energy-75)<1e-6)
        """)

    def test_anatomy_cannot_finish_on_empty_battery(self):
        self.lua.execute("""
            job={paid=0};energy=1
            for i=1,20 do energy,done=H.advanceJob(job,energy,1,15,5);assert(not done) end
            assert(energy==0 and job.paid==1)
        """)

    def test_invalid_or_negative_cost_never_adds_energy(self):
        self.assertEqual(self.lua.eval('function() return H.debit(5,-10) end')(), (5, 0))
        self.assertEqual(self.lua.eval('function() return H.debit(5,0/0) end')(), (5, 0))
