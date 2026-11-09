from test_headset_adapter import HeadsetAdapterTests


def load_tests(loader, tests, pattern):
    return loader.loadTestsFromNames([
        __name__ + '.HeadsetPowerLimitTests.' + name
        for name in HeadsetPowerLimitTests.__dict__ if name.startswith('test_')
    ])


class HeadsetPowerLimitTests(HeadsetAdapterTests):
    def setUp(self):
        super().setUp()
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")
        self.lua.execute('''
            local original=add
            function add(...)
                local a=original(...)
                a.CreateMultiplied=function(f) return {Strength=a.Strength*f,Prefab=a.Prefab} end
                return a
            end
        ''')

    def test_one_frame_spam_of_any_external_affliction_keeps_95_percent(self):
        self.lua.execute('''
            for _,id in ipairs({'burn','stun','electricshock','future_mod_effect'}) do
                G.now=G.now+1;battery.Condition=100
                local a=add(id,100,false)
                for i=1,1000 do
                    local result=G.absorb(char,{a},0,1)
                    assert(result and result.empty,'positive battery lost full protection')
                end
                assert(math.abs(battery.Condition-95)<.00001,id..' exhausted battery')
            end
        ''')

    def test_all_costs_share_one_budget_over_five_seconds(self):
        self.lua.execute('''
            E.NT={};char.NeedsAir=true
            add('heartremoved',100,false);add('unknown_disease',10000,false)
            local hit=add('burn',100,false)
            for frame=0,299 do
                G.now=frame/60
                assert(G.absorb(char,{hit},0,1).empty)
                assert(G.pressure(char,1/60,false))
                G.heal(char,item,1/60)
            end
            assert(battery.Condition>=70-.00001,'combined effects bypass shared cap')
        ''')

    def test_basic_model_healing_and_pressure_also_share_the_cap(self):
        self.lua.execute('''
            item.Prefab.Identifier.Value='aegisheadset';char.NeedsAir=true
            local wound=add('burn',10000,false)
            for i=1,100 do G.pressure(char,1,false);G.heal(char,item,1) end
            assert(math.abs(battery.Condition-95)<.00001)
            assert(math.abs(wound.Strength-9500)<.00001,'cap slowed paid treatment')
        ''')

    def test_anatomy_and_healing_continue_at_normal_speed_after_budget_is_used(self):
        self.lua.execute('''
            E.NT={};local organ=add('heartremoved',100,false)
            local wound=add('burn',100,false)
            G.absorb(char,{wound},0,1)
            for i=1,5 do G.heal(char,item,1) end
            assert(organ.Strength==0 and wound.Strength==0)
            assert(math.abs(battery.Condition-95)<.00001)
        ''')

    def test_refill_is_proportional_and_idle_cannot_accumulate_a_large_burst(self):
        self.lua.execute('''
            local a=add('burn',100,false)
            G.absorb(char,{a},0,1)
            assert(math.abs(battery.Condition-95)<.00001)
            G.now=.1;G.absorb(char,{a},0,1)
            assert(math.abs(battery.Condition-94.5)<.00001)
            G.now=1000
            for i=1,100 do G.absorb(char,{a},0,1) end
            assert(math.abs(battery.Condition-89.5)<.00001)
        ''')

    def test_limit_follows_the_cell_between_devices_and_re_equipping(self):
        self.lua.execute('''
            local a=add('burn',100,false)
            G.absorb(char,{a},0,1)
            equipped=nil;assert(not G.equipped(char));equipped=item
            G.absorb(char,{a},0,1)
            local other={Prefab=item.Prefab,Condition=100,OwnInventory=item.OwnInventory}
            equipped=other
            for i=1,100 do G.absorb(char,{a},0,1) end
            assert(math.abs(battery.Condition-95)<.00001,'moving cell restarted budget')
        ''')

    def test_distinct_cells_have_independent_budgets(self):
        self.lua.execute('''
            local first=battery;local a=add('burn',100,false)
            G.absorb(char,{a},0,1)
            battery={Condition=100,MaxCondition=100,HasTag=first.HasTag}
            G.absorb(char,{a},0,1)
            assert(first.Condition==95 and battery.Condition==95)
            battery=first;G.absorb(char,{a},0,1);assert(first.Condition==95)
        ''')

    def test_empty_cell_still_gives_no_protection_or_healing_after_budget_exhaustion(self):
        self.lua.execute('''
            char.NeedsAir=true;local a=add('burn',100,false)
            G.absorb(char,{a},0,1);battery.Condition=0
            assert(G.absorb(char,{a},0,1)==nil)
            assert(not G.pressure(char,1,false));G.heal(char,item,1)
            assert(a.Strength==100 and battery.Condition==0)
        ''')

    def test_discounted_healing_keeps_normal_speed_with_a_small_positive_remainder(self):
        self.lua.execute('''
            battery.Condition=5.1
            G.absorb(char,{add('burn',100,false)},0,1)
            entries={};local wound=add('burn',100,false)
            G.heal(char,item,1)
            assert(math.abs(wound.Strength-80)<.00001,'nominal cost slowed discounted healing')
            assert(math.abs(battery.Condition-.1)<.00001)
        ''')

    def test_actual_depletion_still_passes_proportional_damage(self):
        self.lua.execute('''
            battery.Condition=2
            local a=add('burn',20,false)
            a.CreateMultiplied=function(f) return {Strength=20*f,Prefab=a.Prefab} end
            local result=G.absorb(char,{a},0,1)
            assert(battery.Condition==0 and result.fraction==.5)
            assert(result.afflictions[1].Strength==10)
        ''')

    def test_failed_native_fallback_refunds_its_shared_allowance(self):
        self.lua.execute('''
            local a=add('burn',20,false);local buff=add('harmlessbuff',1,true)
            char.DamageLimb=function() error('native binding failure') end
            local p={afflictions={a,buff},stun=0,damageMultiplier=1,attackImpulse=0}
            G.intercept(char,p,function() return {} end)
            assert(battery.Condition==100 and not p.PreventExecution)
            local big=add('burn',100,false);G.absorb(char,{big},0,1)
            assert(math.abs(battery.Condition-95)<.00001,'failed attack consumed budget')
        ''')

    def test_no_op_treatment_does_not_use_allowance_or_write_battery(self):
        self.lua.execute('''
            local writes=0
            battery=setmetatable({MaxCondition=100,HasTag=battery.HasTag},{
                __index=function(_,key) if key=='Condition' then return 100 end end,
                __newindex=function(_,key) if key=='Condition' then writes=writes+1 end end})
            G.registerProvider('no-op',function()
                return {{id='unknown_mod',strength=100,policy={target=0},apply=function() error('cannot apply') end}}
            end)
            G.heal(char,item,1)
            assert(writes==0,'failed treatment wrote native battery')
            local hit=add('burn',100,false);G.absorb(char,{hit},0,1)
            assert(G.state(item).debits[1].amount==5,'failed treatment consumed allowance')
        ''')

    def test_nested_treatment_hit_cannot_spend_reserved_power_twice(self):
        self.lua.execute('''
            local hit=add('burn',100,false)
            G.registerProvider('nested-hit',function()
                return {{id='unknown_mod',strength=100,policy={target=0,priority=100},
                    apply=function() G.absorb(char,{hit},0,1) end}}
            end)
            G.heal(char,item,1)
            assert(math.abs(battery.Condition-95)<.00001,'nested callback bypassed cap')
        ''')

    def test_budget_scales_with_real_cell_capacity(self):
        self.lua.execute('''
            battery.MaxCondition=200;battery.Condition=200
            local a=add('burn',100,false)
            for i=1,100 do G.absorb(char,{a},0,1) end
            assert(math.abs(battery.Condition-190)<.00001)
        ''')

    def test_clients_do_not_debit_or_treat(self):
        self.lua.execute('''
            G.authoritative=false;char.NeedsAir=true;local a=add('burn',100,false)
            for i=1,100 do
                assert(G.absorb(char,{a},0,1)==nil)
                G.pressure(char,1,false);G.heal(char,item,1)
            end
            assert(battery.Condition==100 and a.Strength==100)
        ''')
