from lua_support import LuaCase


class HeadsetAdapterTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            E={InvSlotType={Headset=4,Any=0},SERVER=true,Game={IsSingleplayer=false}}
            G=require('AegisHeadset.game').new(E)
            battery={Condition=100,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            item={Prefab={Identifier={Value='aegisheadset'}},Condition=100,
                OwnInventory={GetItemAt=function() return battery end}}
            equipped=item
            char={ID=1,Inventory={GetItemInLimbSlot=function(slot) if slot==4 then return equipped end end},
                AnimController={Limbs={},LimbJoints={}},WorldPosition={X=0,Y=0}}
            entries={}
            char.CharacterHealth={GetAllAfflictions=function() return entries end,
                RecalculateVitality=function() end}
            function add(id,strength,buff,kind)
                local a={Strength=strength,Prefab={Identifier={Value=id},IsBuff=buff,
                    AfflictionType={Value=kind or ''}}}
                entries[#entries+1]=a;return a
            end
        ''')

    def test_optional_mod_globals_are_not_required(self):
        self.lua.execute("assert(E.NT==nil and E.HF==nil);G.heal(char,item,1)")

    def test_bag_and_broken_headset_give_no_protection(self):
        self.lua.execute("assert(G.equipped(char)==item);equipped=nil;assert(G.equipped(char)==nil);equipped=item;item.Condition=0;assert(G.equipped(char)==nil)")

    def test_unknown_disease_heals_with_proportional_energy(self):
        self.lua.execute("a=add('unknownfuture_disease',20,false);G.heal(char,item,1)")
        self.assertEqual(self.lua.eval('a.Strength'), 15)
        self.assertEqual(self.lua.eval('battery.Condition'), 99.375)

    def test_healing_records_exact_affliction_behind_power_use(self):
        self.lua.execute("add('burn',20,false);G.heal(char,item,1)")
        self.assertEqual(self.lua.eval('G.state(item).debits[1].reason'), 'heal:burn')
        self.assertEqual(self.lua.eval('G.state(item).debits[1].amount'), .625)

    def test_healthy_wearer_never_emits_a_healing_pulse_or_spends_energy(self):
        self.lua.execute("""
            local pulses=0;G.emit=function() pulses=pulses+1 end
            for i=1,60 do G.heal(char,item,.2) end
            assert(battery.Condition==100 and pulses==0)
        """)

    def test_last_energy_cannot_buy_a_whole_heal(self):
        self.lua.execute("battery.Condition=.125;a=add('burn',20,false);G.heal(char,item,1)")
        self.assertEqual(self.lua.eval('a.Strength'), 19)
        self.assertEqual(self.lua.eval('battery.Condition'), 0)

    def test_buffs_and_absent_negative_effects_do_not_cost_power(self):
        self.lua.execute("a=add('excellentbuff',100,true);G.heal(char,item,1)")
        self.assertEqual(self.lua.eval('a.Strength'), 100)
        self.assertEqual(self.lua.eval('battery.Condition'), 100)

    def test_positive_vitality_damage_is_treated_even_if_mod_marks_it_buff(self):
        self.lua.execute("a=add('badlylabelled_disease',10,true);a.GetVitalityDecrease=function() return 10 end;G.heal(char,item,1)")
        self.assertEqual(self.lua.eval('a.Strength'), 5)

    def test_optional_neurotrauma_anatomy_waits_for_paid_regeneration(self):
        self.lua.execute("""
            E.NT={};a=add('heartremoved',100,false)
            for i=1,4 do G.heal(char,item,1);assert(a.Strength==100) end
            G.heal(char,item,1);assert(a.Strength==0)
        """)
        self.assertEqual(self.lua.eval('battery.Condition'), 92.5)

    def test_generic_job_provider_supports_future_mod_anatomy(self):
        self.lua.execute("""
            a=add('alien_missing_gland',100,true)
            G.registerTreatment('alien_missing_gland',{anatomy='organ',target=0})
            for i=1,5 do G.heal(char,item,1) end
            assert(a.Strength==0 and battery.Condition==92.5)
        """)

    def test_paid_progress_does_not_transfer_to_another_character(self):
        self.lua.execute("""
            E.NT={};a=add('heartremoved',100,false)
            battery.Condition=3;G.heal(char,item,2)
            battery.Condition=100;other={CharacterHealth=char.CharacterHealth,AnimController=char.AnimController}
            G.heal(other,item,1);assert(a.Strength==100)
        """)

    def test_pressure_is_only_paid_for_real_exposure(self):
        self.lua.execute("""
            char.NeedsAir=true;char.AnimController.CurrentHull={LethalPressure=0}
            assert(not G.pressure(char,.1,false));assert(battery.Condition==100)
            char.AnimController.CurrentHull=nil
            assert(not G.pressure(char,.1,true));assert(battery.Condition==100)
            assert(G.pressure(char,.1,false));assert(battery.Condition==99.75)
        """)

    def test_insufficient_pressure_energy_exhausts_without_free_immunity(self):
        self.lua.execute("battery.Condition=.1;char.NeedsAir=true;assert(not G.pressure(char,1,false));assert(battery.Condition==0)")

    def test_bot_candidate_never_takes_another_characters_cell(self):
        self.lua.execute("""
            AI=require('AegisHeadset.ai');E.LuaUserData={IsTargetType=function(o,t) return o.character==true end}
            other={character=true};battery.ParentInventory={Owner=other};battery.WorldPosition={X=0,Y=0}
            battery.HasAccess=function() return true end;E.Item={ItemList={battery}};char.character=true
            assert(AI.candidate(E,char,item,20)==nil)
            battery.ParentInventory={Owner=char};assert(AI.candidate(E,char,item,20)==battery)
        """)

    def test_partial_attack_reenters_native_method_without_raw_scalar_casts(self):
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")
        self.lua.execute("""
            battery.Condition=5
            a=add('burn',20,false);a.CreateMultiplied=function(f) return {Strength=20*f,Prefab=a.Prefab} end
            local params={afflictions={a},stun=0,damageMultiplier=1,attackImpulse=0}
            local calls=0
            char.DamageLimb=function(pos,limb,afflictions,stun)
                calls=calls+1;assert(afflictions[1].Strength==10)
                assert(G.intercept(char,params,function() return {} end)==nil,'nested attack double charged')
                return {Damage=10}
            end
            local result=G.intercept(char,params,function() return {} end)
            assert(result.Damage==10 and params.PreventExecution and calls==1 and battery.Condition==0)
            assert(params.afflictions[1]==a,'hook parameters mutated across CLR boundary')
        """)

    def test_refunded_failed_attack_does_not_report_power_drain_or_shield_flash(self):
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")
        self.lua.execute("""
            battery.Condition=5
            a=add('burn',20,false);a.CreateMultiplied=function(f) return {Strength=20*f,Prefab=a.Prefab} end
            char.DamageLimb=function() error('native binding failure') end
            local flashes=0;G.emit=function() flashes=flashes+1 end
            local p={afflictions={a},stun=0,damageMultiplier=1,attackImpulse=0}
            G.intercept(char,p,function() return {} end)
            assert(battery.Condition==5 and not p.PreventExecution)
            assert(not G.state(item).debits and flashes==0,'refunded power use is still presented as a real debit')
        """)

    def test_neurotrauma_open_surgery_closes_as_one_paid_job(self):
        self.lua.execute("""
            E.NT={};a=add('surgeryincision',100,true);b=add('retractedskin',100,true)
            char.CharacterHealth.GetAfflictionLimb=function() return {HealthIndex=3} end
            for i=1,4 do G.heal(char,item,1);assert(a.Strength==100 and b.Strength==100) end
            G.heal(char,item,1);assert(a.Strength==0 and b.Strength==0 and battery.Condition==92.5)
        """)

    def test_provider_can_treat_future_mod_health_outside_afflictions(self):
        self.lua.execute("""
            external=20
            G.registerProvider('future-anatomy',function()
                return {{id='custom_organ_failure',strength=external,policy={target=0},
                    apply=function(value) external=value end}}
            end)
            G.heal(char,item,1);assert(external==15 and battery.Condition==99.375)
        """)

    def test_optional_nt_protective_and_mechanical_states_are_preserved(self):
        self.lua.execute("""
            E.NT={}
            for _,id in ipairs({'luabotomy','luabotomypurger','stopcreatureabuse','tshocktimeout',
                'onwheelchair','stasisbagoverlay','bodybagoverlay','afstreptokinase'}) do add(id,10,false) end
            G.heal(char,item,1)
            for _,a in ipairs(entries) do assert(a.Strength==10) end
            assert(battery.Condition==100)
        """)

    def test_normal_nt_physiology_does_not_trigger_passive_power_use(self):
        self.lua.execute("""
            E.NT={}
            local immunity=add('immunity',45,true)
            local pressure=add('bloodpressure',98.5,true)
            local blood=add('bloodamount',99.5,true)
            for i=1,300 do G.heal(char,item,.2) end
            assert(battery.Condition==100,'normal physiology is being charged as regeneration')
            assert(immunity.Strength==45 and pressure.Strength==98.5 and blood.Strength==99.5)
        """)

    def test_actual_nt_low_blood_pressure_is_still_treated_with_energy(self):
        self.lua.execute("""
            E.NT={};a=add('bloodpressure',60,true);G.heal(char,item,1)
            assert(a.Strength==65 and battery.Condition==99.375)
        """)

    def test_neurotrauma_cs_is_detected_without_legacy_lua_globals(self):
        self.lua.execute("""
            a=add('heartremoved',100,false);a.Prefab.ContentPackage={Name='Neurotrauma CS'}
            for i=1,4 do G.heal(char,item,1);assert(a.Strength==100) end
            G.heal(char,item,1);assert(a.Strength==0 and battery.Condition==92.5)
        """)

    def test_zero_probability_and_fully_resisted_hits_do_not_charge(self):
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")
        self.lua.execute("""
            a=add('burn',20,false);a.Probability=0
            assert(G.absorb(char,{a},0,1)==nil and battery.Condition==100)
            a.Probability=1;char.CharacterHealth.GetResistance=function() return 1 end
            assert(G.absorb(char,{a},0,1,nil,{type=0})==nil and battery.Condition==100)
        """)

    def test_fully_protective_armor_does_not_charge(self):
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")
        self.lua.execute("""
            a=add('burn',20,false)
            local armor={DamageMultiplier=0,MatchesAffliction=function() return true end}
            local limb={DamageModifiers={armor},WearingItems={},SectorHit=function() return true end,type=0}
            assert(G.absorb(char,{a},0,1,nil,limb)==nil and battery.Condition==100)
        """)

    def test_bot_does_not_take_battery_from_sonar(self):
        self.lua.execute("""
            AI=require('AegisHeadset.ai')
            E.LuaUserData={IsTargetType=function(o,t) return (o.character and t=='Barotrauma.Character') or (o.item and t=='Barotrauma.Item') end}
            local sonar={item=true,Components={{Name='ItemContainer'},{Name='Sonar'}},HasTag=function() return false end}
            battery.ParentInventory={Owner=sonar};battery.WorldPosition={X=0,Y=0};battery.HasAccess=function() return true end
            E.Item={ItemList={battery}};assert(AI.candidate(E,char,item,20)==nil)
        """)

    def test_failed_resupply_candidate_has_cooldown(self):
        self.lua.execute("""
            AI=require('AegisHeadset.ai');E.LuaUserData={IsTargetType=function() return true end}
            battery.WorldPosition={X=0,Y=0};battery.HasAccess=function() return true end
            E.Item={ItemList={battery}}
            assert(AI.candidate(E,char,item,20,{[battery]=60},1)==nil)
            assert(AI.candidate(E,char,item,20,{[battery]=60},61)==battery)
        """)

    def test_completed_resupply_is_not_written_again_during_cleanup(self):
        self.lua.execute("""
            local done=setmetatable({},{__index={IsCompleted=true},__newindex=function() error('protected setter') end})
            require('AegisHeadset.ai').cancel({resupply=done})
        """)

    def test_full_block_suppresses_severance_only_inside_its_attack(self):
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")
        self.lua.execute("""
            a=add('burn',20,false);G.beginAttack(char)
            local p={afflictions={a},stun=0,damageMultiplier=1}
            G.intercept(char,p,function() return {} end)
            assert(G.shouldBlockSever(char))
            G.endAttack(char);assert(not G.shouldBlockSever(char))
        """)
