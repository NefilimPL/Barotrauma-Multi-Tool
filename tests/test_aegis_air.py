from lua_support import LuaCase


class SuitFetchInterruptionTests(LuaCase):
    def test_stock_stays_available_when_bot_changes_its_current_objective(self):
        self.lua.execute('''
            local G={authoritative=true,now=10,patch=function() end,energy=function() return 0 end,
                tank=function() end}
            local E={LuaUserData={RegisterType=function() end,MakePropertyAccessible=function() end},
                Util={RegisterItemGroup=function() end,GetItemGroup=function() return {} end}}
            local oldObjective={}
            local manager={CurrentObjective={}}
            local owner={IsBot=true,AIController={ObjectiveManager=manager}}
            local fetch={IsCompleted=false}
            local s={resupply=fetch,supplyRoot=oldObjective,supplyTarget={ID=9},supplySlot=0,
                supplyDeadline=20,supplyOwner=owner,nextResupply=11}
            require('AegisSuit.supplies').install(G,E)
            G.updateSupplies(owner,{},s)
            assert(fetch.IsCompleted and not s.resupply,'obsolete fetch stayed active')
            assert(not s.failedSupplies or not s.failedSupplies[9],'an interruption blacklisted usable stock')
        ''')


class ModularSuitFetchInterruptionTests(SuitFetchInterruptionTests):
    mod_directory = 'System-Aegis-No-Headsets'


class SuitAirTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def setUp(self):
        super().setUp()
        self.lua.execute("""
            slots={}
            function part(id,tags,condition)
                return {Prefab={Identifier={Value=id}},Condition=condition,MaxCondition=100,
                    HasTag=function(tag) return tags[tag]==true end}
            end
            battery=part('batterycell',{mobilebattery=true},50)
            tank=part('oxygentank',{oxygensource=true,refillableoxygensource=true},40)
            compressor=part('aegiscompressormodule',{},100)
            slots[0]=battery
            inv={GetItemAt=function(index) return slots[index] end}
            suit={Components={{Name='ItemContainer',Inventory=inv}}}
            wearer={NeedsAir=true,AnimController={HeadInWater=true,
                CurrentHull={OxygenPercentage=100,LethalPressure=0}}}
            E={SERVER=true,Game={IsSingleplayer=false}}
            G=require('AegisSuit.game').new(E)
        """)

    def test_battery_cannot_supply_oxygen_but_tank_works_without_battery(self):
        self.lua.execute("""
            G.breathe(wearer,suit,.1)
            assert(wearer.OxygenAvailable==0 and not wearer.UseHullOxygen)
            slots[0]=nil;slots[5]=tank
            G.breathe(wearer,suit,.1)
            assert(wearer.OxygenAvailable==100 and tank.Condition<40)
            tank.Condition=0;G.breathe(wearer,suit,.1)
            assert(wearer.OxygenAvailable==0)
        """)

    def test_compressor_refills_only_with_safe_air_and_battery(self):
        self.lua.execute("""
            slots[4]=compressor;slots[5]=tank
            G.breathe(wearer,suit,.1)
            assert(tank.Condition<40 and battery.Condition==50)
            wearer.AnimController.HeadInWater=false
            local before=tank.Condition
            slots[0]=nil;G.breathe(wearer,suit,.1)
            assert(tank.Condition==before and wearer.UseHullOxygen)
            slots[0]=battery;G.breathe(wearer,suit,.1)
            assert(tank.Condition>before and battery.Condition<50)
            tank.Condition=100;before=battery.Condition;G.breathe(wearer,suit,.1)
            assert(tank.Condition==100 and battery.Condition==before)
        """)

    def test_network_client_reads_breathing_state_without_mutating_supplies(self):
        self.lua.execute("""
            E.SERVER=false;G=require('AegisSuit.game').new(E)
            slots[4]=compressor;slots[5]=tank
            G.breathe(wearer,suit,.1)
            assert(wearer.OxygenAvailable==100 and tank.Condition==40)
            wearer.AnimController.HeadInWater=false
            G.breathe(wearer,suit,.1)
            assert(wearer.UseHullOxygen and tank.Condition==40 and battery.Condition==50)
        """)

    def test_bot_replaces_low_tank_then_installs_modules_from_available_supplies(self):
        self.lua.execute("""
            local better=part('oxygentank',{oxygensource=true},90)
            local worse=part('oxygentank',{oxygensource=true},2)
            local servo=part('aegisservomodulecoalition',{},100)
            local impeller=part('aegisimpellermodulehusk',{},100)
            local supplies={worse,better,servo,impeller,compressor}
            tank.Condition=5;slots[5]=tank
            wearer.IsBot=true;wearer.Inventory={Owner=wearer}
            wearer.CanInteractWith=function() return true end
            E.LuaUserData={IsTargetType=function(entity,name) return entity==wearer and name=='Barotrauma.Character' end}
            E.LuaUserData.RegisterType=function() end
            E.LuaUserData.MakePropertyAccessible=function() end
            E.Util={RegisterItemGroup=function() end,GetItemGroup=function() return supplies end}
            G.patch=function() end
            suit.OwnInventory=inv;inv.Owner=suit
            for _,item in ipairs(supplies) do item.ParentInventory=wearer.Inventory;item.HasAccess=function() return true end end
            inv.TryPutItem=function(item,slot,swap,combine,user)
                assert(swap and not combine and user==wearer)
                if slots[slot] then slots[slot].ParentInventory=wearer.Inventory end
                slots[slot]=item;item.ParentInventory=inv
                return true
            end
            require('AegisSuit.supplies').install(G,E)
            local state=G.state(suit)
            G.updateSupplies(wearer,suit,state)
            assert(slots[5]==better and tank.ParentInventory==wearer.Inventory)
            for time=1,3 do G.now=time;G.updateSupplies(wearer,suit,state) end
            assert(slots[2]==servo and slots[3]==impeller and slots[4]==compressor)
            assert(slots[0]==battery and slots[5]==better)
        """)
