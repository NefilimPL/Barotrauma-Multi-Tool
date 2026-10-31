from lua_support import LuaCase


class CombatAdapterTests(LuaCase):
    def test_shield_and_shot_spend_the_same_physical_source(self):
        self.lua.execute('insert(0,20,false);insert(1,60,true);G.spend(gun,0,1);G.shieldDebit(gun,4)')
        self.assertEqual(self.lua.eval('gun.OwnInventory.GetItemAt(0).Condition'),15)
        self.assertEqual(self.lua.eval('gun.OwnInventory.GetItemAt(1).Condition'),60)

    def test_bot_combat_permission_is_automatic_but_player_checkbox_is_preserved(self):
        self.lua.execute('''
            G=require('CombatTool.game').new({InvSlotType={RightHand=1,LeftHand=2},InputType={Aim=1}})
            local damage={Name='LightComponent',IsOn=false}
            gun.Components={damage}
            local combat={Identifier={Value='combat'},Weapon=gun,Enemy={}}
            bot={IsBot=true,Inventory={GetItemInLimbSlot=function() return gun end},
                IsKeyDown=function() return true end,AIController={ObjectiveManager={CurrentObjective=combat}}}
            local ctx=G.context(gun,bot)
            assert(ctx.damage and ctx.mode=='combat','bot still requires the player checkbox')
            assert(not damage.IsOn,'bot changed the saved player preference')
            AI.activeCombat[bot]=combat
            bot.AIController.ObjectiveManager.CurrentObjective={Identifier={Value='fix leak'}}
            ctx=G.context(gun,bot)
            assert(ctx.damage and ctx.mode=='weld','concurrent threat must not turn welding into firing')
            combat.IsCompleted=true
            assert(not G.context(gun,bot).damage,'completed combat still authorized shield')
            bot.IsBot=false
            assert(not G.context(gun,bot).damage,'player bypassed damage checkbox')
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            G = require('CombatTool.game').new({})
            AI = require('CombatTool.ai')
            gun = {Prefab={Identifier={Value='combatmultitool'}},ID=42,Condition=100,Components={}}
            local slots = {}
            gun.OwnInventory={GetItemAt=function(i) return slots[i] end}
            function insert(i,energy,rod)
                slots[i]={ConditionPercentage=energy,Condition=energy,MaxCondition=100,
                    HasTag=function(tag) return (rod and tag=='reactorfuel') or (not rod and tag=='mobilebattery') end}
            end
        ''')

    def test_debit_only_selected_inventory_slot(self):
        self.lua.execute('insert(0,20,false); insert(1,60,true); G.spend(gun,0,4)')
        self.assertEqual(self.lua.eval('gun.OwnInventory.GetItemAt(0).Condition'), 16)
        self.assertEqual(self.lua.eval('gun.OwnInventory.GetItemAt(1).Condition'), 60)

    def test_game_item_does_not_have_objective_identifier_property(self):
        self.lua.execute("setmetatable(gun,{__index=function(_,key) if key=='Identifier' then error('Item has no Identifier') end end})")
        self.assertTrue(self.lua.eval('G.isWeapon(gun)'))

    def test_slot_one_does_not_make_empty_gun_loaded(self):
        self.lua.execute('insert(1,100,false)')
        self.assertFalse(self.lua.eval('G.powered(gun,0)'))
        self.assertTrue(self.lua.eval('G.powered(gun,1)'))

    def test_partial_battery_cannot_fund_a_complete_shot(self):
        self.lua.execute('insert(0,.4,false)')
        self.assertFalse(self.lua.eval('G.canSpend(gun,0,1)'))
        self.assertTrue(self.lua.eval('G.canSpend(gun,0,.01)'))

    def test_owner_transition_cancels_partial_charge(self):
        self.lua.execute('''
            state=G.state(gun); state.owner={ID=1};state.chargeStarted=5
            G.transition(state,{owner={ID=2},mode='combat'})
        ''')
        self.assertIsNone(self.lua.globals().state.chargeStarted)

    def test_mode_transition_cancels_partial_charge(self):
        self.lua.execute('''
            state=G.state(gun);state.mode='combat';state.chargeStarted=5
            G.transition(state,{owner=nil,mode='weld'})
        ''')
        self.assertIsNone(self.lua.globals().state.chargeStarted)

    def test_stale_queued_combat_does_not_win_over_welding(self):
        self.lua.execute('''
            operator={IsBot=true,AIController={ObjectiveManager={CurrentObjective={
                Identifier={Value='fix leaks'},CurrentSubObjective={Identifier={Value='fix leak'},
                    CurrentSubObjective={Identifier={Value='operate item'},Component={Item=gun}}}}}}}
        ''')
        self.assertEqual(self.lua.eval('AI.task(operator,gun)'), 'weld')

    def test_resupply_subtask_prevents_firing(self):
        self.lua.execute('''
            operator={IsBot=true,AIController={ObjectiveManager={CurrentObjective={
                Identifier={Value='combat'},Weapon=gun,Enemy={},
                CurrentSubObjective={Identifier={Value='contain item'}}}}}}
        ''')
        self.assertEqual(self.lua.eval('AI.task(operator,gun)'), 'idle')

    def test_unknown_task_is_idle(self):
        self.lua.execute("operator={IsBot=true,AIController={ObjectiveManager={CurrentObjective={Identifier={Value='unknown'}}}}}")
        self.assertEqual(self.lua.eval('AI.task(operator,gun)'), 'idle')

    def test_actual_operate_cutter_task_is_recognized(self):
        self.lua.execute('''
            operator={AIController={ObjectiveManager={CurrentObjective={Identifier={Value='operate item'},
                Component={Item=gun,Name='RepairTool',StructureFixAmount=-.55,ExtinguishAmount=0}}}}}
        ''')
        self.assertEqual(self.lua.eval('AI.task(operator,gun)'),'cut')

    def test_separate_instances_have_separate_cooldowns(self):
        self.lua.execute("other={ID=43};G.state(gun).brokenUntil=12")
        self.assertEqual(self.lua.eval('G.state(other).brokenUntil'), 0)

    def test_one_tool_activation_and_debit_per_frame(self):
        self.lua.execute('''
            insert(0,20,false)
            weld={Item=gun,Name='RepairTool'};cut={Item=gun,Name='RepairTool'};ext={Item=gun,Name='RepairTool'}
            gun.Components={weld,cut,ext}
            G.context=function() return {valid=true,aim=true,mode='weld',damage=false} end
            assert(G.use(weld,nil,.1))
            assert(not G.use(weld,nil,.1))
            assert(not G.use(cut,nil,.1))
            assert(not G.use(ext,nil,.1))
        ''')
        self.assertAlmostEqual(self.lua.eval('gun.OwnInventory.GetItemAt(0).Condition'),19.98)

    def test_damage_disabled_never_starts_combat_charge(self):
        self.lua.execute('''
            insert(0,20,false)
            ranged={Item=gun,Name='RangedWeapon'}
            G.context=function() return {valid=true,aim=true,mode='idle',damage=false} end
            assert(not G.use(ranged,nil,1))
        ''')
        self.assertIsNone(self.lua.eval('G.state(gun).chargeStarted'))

    def test_same_frame_cannot_switch_from_welding_to_combat(self):
        self.lua.execute('''
            insert(0,20,false)
            weld={Item=gun,Name='RepairTool'};ranged={Item=gun,Name='RangedWeapon'}
            gun.Components={weld}
            G.context=function() return {valid=true,aim=true,mode='weld',damage=true} end
            assert(G.use(weld,nil,.1))
            G.context=function() return {valid=true,aim=true,mode='combat',damage=true} end
            G.use(ranged,nil,.1)
        ''')
        self.assertIsNone(self.lua.eval('G.state(gun).chargeStarted'))

    def test_charge_then_cooldown_prevents_replayed_use(self):
        self.lua.execute('''
            insert(0,20,false); shots=0
            ranged={Item=gun,Name='RangedWeapon'}
            G.context=function() return {valid=true,aim=true,mode='combat',damage=true} end
            G.fire=function() shots=shots+1 end
            G.use(ranged,nil,.01);G.now=.26;G.use(ranged,nil,.01)
            for i=1,20 do G.use(ranged,nil,.01) end
        ''')
        self.assertEqual(self.lua.globals().shots,1)
        self.assertEqual(self.lua.eval('gun.OwnInventory.GetItemAt(0).Condition'),19)

    def test_rejected_native_component_calls_do_not_cancel_bot_charge(self):
        self.lua.execute('''
            insert(0,20,false);shots=0
            ranged={Item=gun,Name='RangedWeapon'};weld={Item=gun,Name='RepairTool'}
            gun.Components={ranged,weld}
            G.fire=function() shots=shots+1 end
            G.context=function() return {bot=true,valid=true,aim=true,mode='combat',damage=true} end
            G.use(ranged,nil,.016)
            G.context=function() return {bot=true,valid=true,aim=true,mode='idle',damage=true} end
            G.use(weld,nil,.016);G.use(ranged,nil,.016)
            G.now=.26;G.frame=G.frame+1
            G.context=function() return {bot=true,valid=true,aim=true,mode='combat',damage=true} end
            G.use(ranged,nil,.016)
        ''')
        self.assertEqual(self.lua.globals().shots,1)

    def test_cleanup_clears_shield_tracking(self):
        self.lua.execute('G.clearShieldTracking=function() cleared=true end;G.cleanup()')
        self.assertTrue(self.lua.globals().cleared)

    def test_shield_behind_closed_wall_does_not_intercept(self):
        self.lua.execute('''
            G.patch=function() end
            G.friendly=function() return false end
            G.cast=function() return {t=.5,kind='wall'} end
            G.state(gun).shield={x=0,y=0,radius=10,angle=0,halfAngle=1.05}
            gun.WorldPosition={X=0,Y=0}
            require('CombatTool.shield').install(G,{})
            result=G.findShield({x=20,y=0},{x=0,y=0},nil,nil)
        ''')
        self.assertIsNone(self.lua.globals().result)
