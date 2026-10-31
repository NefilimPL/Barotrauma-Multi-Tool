from test_headset_adapter import HeadsetAdapterTests
from test_headset_visuals import HeadsetVisualTests
from lua_support import LuaCase


def load_tests(loader, tests, pattern):
    import unittest
    return unittest.TestSuite([
        HeadsetClientBoundaryTests('test_singleplayer_hit_never_reads_server_only_luagame_field'),
        HeadsetColorTests('test_healing_light_is_blue_and_hit_light_is_red'),
        HeadsetClientBoundaryTests('test_inactive_oxygen_trace_does_not_cost_power'),
        HeadsetClientBoundaryTests('test_no_op_affliction_setter_does_not_cost_power'),
        HeadsetBotInsertionTests('test_idle_bot_inserts_local_spare_without_current_objective'),
        HeadsetBotInsertionTests('test_low_battery_is_swapped_without_first_removing_it'),
        HeadsetBotInsertionTests('test_failed_swap_keeps_old_battery_in_headset'),
        HeadsetClientBoundaryTests('test_power_budget_allows_forty_seconds_pressure_and_longer_healing'),
        HeadsetColorTests('test_hit_flash_remains_red_when_healing_arrives_during_blink'),
        HeadsetBotInsertionTests('test_interrupted_remote_fetch_keeps_old_cell_and_can_retry'),
        HeadsetClientBoundaryTests('test_active_disease_at_exact_threshold_is_treated'),
        HeadsetClientBoundaryTests('test_no_op_does_not_temporarily_exhaust_battery'),
        HeadsetBotInsertionTests('test_bot_does_not_take_illegitimate_outpost_cell'),
    ])


class HeadsetClientBoundaryTests(HeadsetAdapterTests):
    def test_active_disease_at_exact_threshold_is_treated(self):
        self.lua.execute('''
            a=add('futuremod_binary_disease',1,false);a.Prefab.ActivationThreshold=1
            a.GetVitalityDecrease=function() return 5 end
            G.heal(char,item,1)
            assert(a.Strength==0 and battery.Condition<100,'active disease at its threshold was skipped')
        ''')

    def test_no_op_does_not_temporarily_exhaust_battery(self):
        self.lua.execute('''
            local charge=.01;local broken=0
            battery.Condition=nil
            setmetatable(battery,{__index=function(_,k) if k=='Condition' then return charge end end,
                __newindex=function(_,k,v) if k=='Condition' then charge=v;if v==0 then broken=broken+1 end
                    else rawset(battery,k,v) end end})
            a=add('readonly_state',10,false);a.Strength=nil
            setmetatable(a,{__index=function(_,k) if k=='Strength' then return 10 end end,
                __newindex=function(_,k,v) if k~='Strength' then rawset(a,k,v) end end})
            G.heal(char,item,1)
            assert(broken==0 and charge==.01,'a refunded no-op fired battery OnBroken effects')
        ''')

    def test_power_budget_allows_forty_seconds_pressure_and_longer_healing(self):
        self.lua.execute('''
            local C=require('AegisHeadset.config')
            assert(C.pressureCost==2.5 and C.healCost==.125)
            assert(C.hitMinimum==.25 and C.hitMultiplier==.125)
            assert(C.organCost==7.5 and C.limbCost==12.5 and C.surgeryCost==7.5)
        ''')
    def test_inactive_oxygen_trace_does_not_cost_power(self):
        self.lua.execute('''
            a=add('oxygenlow',.5,false);a.Prefab.ActivationThreshold=1
            for i=1,300 do G.heal(char,item,.2) end
            assert(battery.Condition==100,'inactive physiology is charged as healing')
            a.Strength=5;G.heal(char,item,.2)
            assert(a.Strength<5 and battery.Condition<100,'active suffocation is not treated')
        ''')

    def test_no_op_affliction_setter_does_not_cost_power(self):
        self.lua.execute('''
            a=add('mod_readonly_health_marker',10,false)
            a.Strength=nil
            setmetatable(a,{__index=function(_,k) if k=='Strength' then return 10 end end,
                __newindex=function(_,k,v) if k~='Strength' then rawset(a,k,v) end end})
            G.heal(char,item,1)
            assert(battery.Condition==100,'unchanged state still consumed energy')
            assert(not G.state(item).debits,'no-op treatment recorded as paid regeneration')
        ''')

    def test_singleplayer_hit_never_reads_server_only_luagame_field(self):
        self.lua.execute('''
            E.SERVER=false;E.CLIENT=true
            E.Game=setmetatable({IsSingleplayer=true},{__index=function(_,key)
                error('cannot access field '..key..' of LuaGame client')
            end})
            G=require('AegisHeadset.game').new(E)
            a=add('burn',20,false)
            local p={afflictions={a},stun=0,damageMultiplier=1}
            G.intercept(char,p,function() return {} end)
            assert(p.PreventExecution and battery.Condition<100)
        ''')


class HeadsetColorTests(HeadsetVisualTests):
    def test_hit_flash_remains_red_when_healing_arrives_during_blink(self):
        self.lua.execute('''
            G.emit(char,item,'hit');G.updateEffects(.2);G.now=.2
            G.emit(char,item,'heal');G.drawEffects({},cam)
            assert(#lines>0)
            for _,line in ipairs(lines) do assert(line.color.R>line.color.B,'healing interrupted impact flash') end
            lines={};G.updateEffects(.2);G.now=.4
            G.emit(char,item,'heal');G.drawEffects({},cam)
            assert(#lines>0,'impact blink is too short to see')
        ''')

    def test_healing_light_is_blue_and_hit_light_is_red(self):
        self.lua.execute('''
            G.emit(char,item,'heal');G.drawEffects({},cam)
            assert(#lines>0)
            for _,line in ipairs(lines) do assert(line.color.B>line.color.R,'healing must be blue') end
            G.now=1;G.emit(char,item,'hit');lines={};G.drawEffects({},cam)
            for _,line in ipairs(lines) do assert(line.color.R>line.color.B,'impact must be red') end
        ''')


class HeadsetBotInsertionTests(LuaCase):
    def test_bot_does_not_take_illegitimate_outpost_cell(self):
        self.lua.execute('''
            spare.Illegitimate=true
            AI.update(G,E,char,item)
            assert(current==old,'bot stole an outpost battery')
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            E={SERVER=true,InvSlotType={Headset=4,Any=0},Game={IsSingleplayer=false},
                LuaUserData={IsTargetType=function(o,t) return o.character and t=='Barotrauma.Character' end}}
            G=require('AegisHeadset.game').new(E);AI=require('AegisHeadset.ai')
            old={Condition=10,MaxCondition=100,HasTag=function() return true end}
            spare={Condition=100,MaxCondition=100,HasTag=function() return true end,
                WorldPosition={X=0,Y=0},HasAccess=function() return true end}
            current=old;allowSwap=true;dropCount=0
            old.Drop=function() dropCount=dropCount+1;current=nil end
            item={Condition=100,Prefab={Identifier={Value='aegisheadset'}},
                Components={{Name='ItemContainer'}},OwnInventory={GetItemAt=function() return current end,
                    TryPutItem=function(cell,slot,swap,combine,user)
                        assert(cell==spare and slot==0 and swap and not combine)
                        if not allowSwap then return false end
                        current=spare;return true
                    end}}
            char={IsBot=true,character=true,WorldPosition={X=0,Y=0},
                AIController={ObjectiveManager={CurrentObjective={AddSubObjective=function() error('queued local insertion') end}}},
                CanInteractWith=function() return true end,
                Inventory={GetItemInLimbSlot=function() return item end,TryPutItem=function() current=nil;return true end}}
            spare.ParentInventory={Owner=char}
            E.Item={ItemList={spare}}
            E.AIObjectiveContainItem=function() return {} end
        ''')

    def test_idle_bot_inserts_local_spare_without_current_objective(self):
        self.lua.execute('''
            current=nil;char.AIController.ObjectiveManager.CurrentObjective=nil
            AI.update(G,E,char,item);assert(current==spare,'idle bot left its headset empty')
        ''')

    def test_low_battery_is_swapped_without_first_removing_it(self):
        self.lua.execute('''
            AI.update(G,E,char,item)
            assert(current==spare and dropCount==0,'replacement is deferred after removing the old cell')
        ''')

    def test_failed_swap_keeps_old_battery_in_headset(self):
        self.lua.execute('''
            allowSwap=false;AI.update(G,E,char,item)
            assert(current==old and dropCount==0,'failed insertion left the headset empty')
        ''')

    def test_interrupted_remote_fetch_keeps_old_cell_and_can_retry(self):
        self.lua.execute('''
            char.CanInteractWith=function() return false end
            local count=0
            local parent={AddSubObjective=function() count=count+1 end}
            char.AIController.ObjectiveManager.CurrentObjective=parent
            E.AIObjectiveGetItem=function() return {} end
            AI.update(G,E,char,item);local first=G.state(item).resupply
            assert(first and current==old)
            char.AIController.ObjectiveManager.CurrentObjective={AddSubObjective=parent.AddSubObjective}
            G.now=.2;AI.update(G,E,char,item)
            assert(first.IsCompleted and current==old and not G.state(item).resupply)
            G.now=2;AI.update(G,E,char,item)
            assert(count==2 and G.state(item).resupply and current==old)
        ''')
