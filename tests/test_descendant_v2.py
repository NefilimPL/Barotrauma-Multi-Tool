from lua_support import LuaCase


class DescendantV2Tests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E={SERVER=true,Game={IsSingleplayer=false},InvSlotType={OuterClothes=9}}
            E.LuaUserData={IsTargetType=function(v,t) return v.character==true end}
            cell={Condition=80,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            box={Condition=100,MaxCondition=100,HasTag=function(t) return t=='pulselaserammo' end}
            slots={[0]=cell,[1]=box}
            suit={Condition=100,Prefab={Identifier={Value='descendantservosuit'}},Components={
                {Name='ItemContainer',Inventory={GetItemAt=function(i) return slots[i] end}}}}
            owner={character=true,NeedsAir=true,Inventory={GetItemInLimbSlot=function() return suit end},
                AnimController={HeadInWater=false,CurrentHull={OxygenPercentage=100,LethalPressure=0}}}
            suit.ParentInventory={Owner=owner}
            G=require('DescendantSuit.game').new(E)
        """)

    def test_one_inventory_has_separate_power_and_ammo_roles(self):
        self.lua.execute("""
            assert(G.source(suit)==cell and G.ammo(suit)==box)
            slots[0]=box;slots[1]=cell
            assert(not G.source(suit) and not G.ammo(suit))
        """)

    def test_closed_loop_consumes_nothing_for_a_species_that_needs_no_air(self):
        self.lua.execute("""
            owner.NeedsAir=false;owner.AnimController.HeadInWater=true
            G.breathe(owner,suit,.1);assert(cell.Condition==80)
        """)

    def test_pulse_cost_is_atomic_when_either_resource_is_missing(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core');local config=C.config
            local s={}
            assert(not C.payPulse(s,0,100,0));assert(s.nextPulse==nil)
            assert(not C.payPulse(s,100,0,0));assert(s.nextPulse==nil)
            local ok,power,ammo=C.payPulse(s,config.shotPower/2,100,0)
            assert(not ok and power==nil and ammo==nil and s.nextPulse==nil)
            ok,power,ammo=C.payPulse(s,100,config.ammoCost/2,0)
            assert(not ok and s.nextPulse==nil)
        """)

    def test_pulses_have_a_cooldown_and_use_native_box_units(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core');local s={}
            local ok,power,ammo=C.payPulse(s,100,100,5)
            assert(ok and power<100 and ammo==97.75)
            assert(not C.payPulse(s,power,ammo,5.1))
            assert(C.payPulse(s,power,ammo,5.41))
            assert(C.config.combatRange>=1500 and C.config.shotDamage>=20)
        """)

    def test_power_toggle_restores_last_selected_single_mode(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core');local s={mode='repair',target={id=4}}
            assert(C.toggle(s));assert(s.mode=='off' and not s.target)
            assert(C.toggle(s));assert(s.mode=='repair' and not s.target)
            C.setMode(s,'combat');C.toggle(s);C.toggle(s);assert(s.mode=='combat')
        """)

    def test_resupply_never_takes_a_cell_from_another_character_or_installed_device(self):
        self.lua.execute("""
            local A=require('DescendantSuit.supplies')
            E.LuaUserData.IsTargetType=function(v,t)
                return (t=='Barotrauma.Character' and v.character) or (t=='Barotrauma.Item' and v.item)
            end
            local other={character=true}
            cell.ParentInventory={Owner=other};assert(not A.allowed(E,cell,owner,suit))
            local reactor={item=true,Components={{Name='Reactor'}},HasTag=function() return false end}
            cell.ParentInventory={Owner=reactor};assert(not A.allowed(E,cell,owner,suit))
            local storage={item=true,Components={{Name='ItemContainer'}},HasTag=function() return false end}
            cell.ParentInventory={Owner=storage};assert(A.allowed(E,cell,owner,suit))
            cell.ParentInventory={Owner=owner};assert(A.allowed(E,cell,owner,suit))
        """)

    def test_resupply_does_not_extract_from_installed_tools_or_other_suits(self):
        self.lua.execute("""
            local A=require('DescendantSuit.supplies')
            E.LuaUserData.IsTargetType=function(v,t) return v.item and t=='Barotrauma.Item' end
            for _,component in ipairs({'PowerContainer','RangedWeapon','Sonar','LightComponent'}) do
                local device={item=true,Components={{Name=component}},HasTag=function() return false end}
                cell.ParentInventory={Owner=device};assert(not A.allowed(E,cell,owner,suit))
            end
            cell.ParentInventory={Owner=suit};suit.item=true
            assert(not A.allowed(E,cell,owner,suit))
        """)

    def test_ai_recognizes_the_powered_closed_loop_instead_of_searching_for_a_tank(self):
        self.lua.execute("""
            E.LuaUserData.RegisterType=function(x) return x end
            local properties={}
            E.LuaUserData.MakePropertyAccessible=function(c,p) properties[c..p]=true end
            E.Util={RegisterItemGroup=function() end}
            local gearHook
            G.patch=function(name,class,method,fn) gearHook=fn end
            require('DescendantSuit.supplies').install(G,E)
            assert(gearHook,'no closed-loop gear integration')
            local objective=setmetatable({character=owner},{__newindex=function(t,k,v)
                if k=='IsCompleted' then assert(properties['Barotrauma.AIObjectiveFindDivingGearIsCompleted'],'inherited completion setter unavailable') end
                rawset(t,k,v)
            end});local p={}
            gearHook(objective,p)
            assert(p.PreventExecution and objective.IsCompleted)
            cell.Condition=0;objective.IsCompleted=false;p={}
            gearHook(objective,p)
            assert(p.PreventExecution and not objective.IsCompleted)
        """)

    def test_luacs_stop_disposes_client_resources_once(self):
        self.lua.execute("""
            local handlers={};local disposed=0
            E.Util={RegisterItemGroup=function() end}
            E.Hook={Add=function(event,id,fn) handlers[event]=fn end,Remove=function() end}
            G.patch=function() end
            G.disposeClient=function() disposed=disposed+1 end
            G.install();assert(handlers.stop,'missing LuaCs stop handler')
            handlers.stop();handlers.stop()
            assert(not G.alive and disposed==1)
        """)

    def test_unequipping_the_suit_cancels_its_pending_native_fetch(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;G.nextOwners=100
            local fetch={IsCompleted=false};local s=G.state(suit);s.owner=owner;s.resupply=fetch
            G.cancelSupplies=function(state) state.resupply.IsCompleted=true;state.resupply=nil end
            owner.Inventory.GetItemInLimbSlot=function() return nil end
            G.update(.1)
            assert(fetch.IsCompleted and not G.states[suit])
        """)

    def test_paused_round_cleanup_keeps_states_available_until_lights_are_removed(self):
        self.lua.execute("""
            local removed=0
            G.state(suit).lights={}
            G.pauseClient=function() end
            G.clearClient=function()
                for _,s in pairs(G.states) do if s.lights then removed=removed+2;s.lights=nil end end
            end
            E.Game.Paused=true;G.update(.1);G.clear()
            assert(removed==2 and next(G.states)==nil)
        """)


class DescendantNativeRepairTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            hooks={};fields={};E={SERVER=true}
            E.LuaUserData={RegisterType=function(x) return x end,MakeFieldAccessible=function(c,f) fields[c..f]=true end,
                MakeMethodAccessible=function() end,CreateEnumTable=function(t)
                    return {Repair=1,OnRepairedOutsideLeak=2,RepairToolStructureRepairMultiplier=3}
                end}
            E.Hook={HookMethodType={Before=1,After=2},Patch=function(id,class,method,...)
                local args={...};hooks[method]=args[#args-1]
            end}
            owner=setmetatable({_selectedItem={id='own selected item'},AnimController={},GetStatValue=function() return 0 end},
                {__index=function(t,k)
                    if k=='_selectedItem' and t.nativeAI then assert(fields['Barotrauma.AICharacter_selectedItem'],'private inherited AI field unavailable') end
                    if k=='SelectedItem' then return rawget(t,'_selectedItem') end
                end})
            suit={Condition=100}
            G={authoritative=true,now=0,states={[suit]={mode='repair',owner=owner}},patches={}}
            G.state=function() return G.states[suit] end
            G.equipped=function(c) return c==owner and suit end
            G.energy=function() return 100 end
            G.spend=function() return 1 end
            G.patch=function(name,class,method,fn) hooks[method]=fn end
            device={Condition=10,MaxCondition=100}
            repairs=0;stops=0
            repairable={Name='Repairable',Item=device,StartRepairing=function(c)
                repairable.CurrentFixer=c;return true
            end,StopRepairing=function(c) stops=stops+1;repairable.CurrentFixer=nil end,
            Update=function(dt)
                assert(owner.SelectedItem==device and repairable.currentRepairItem==suit)
                repairs=repairs+1;device.Condition=device.Condition+dt*20
            end}
            device.Components={repairable}
            target={id='i1',kind='repair',entity=device}
            G.states[suit].target=target
            require('DescendantSuit.repair').install(G,E)
        """)

    def test_native_update_runs_with_suit_tool_and_restores_player_selection(self):
        self.lua.execute("""
            local selected=owner.SelectedItem
            assert(G.repairDevice(owner,suit,target,.1))
            assert(repairs==1 and device.Condition>10 and owner.SelectedItem==selected)
            local p={};hooks.Update(repairable,p);assert(p.PreventExecution)
        """)

    def test_servo_does_not_take_a_repair_away_from_another_player(self):
        self.lua.execute("""
            local other={};repairable.CurrentFixer=other
            assert(not G.repairDevice(owner,suit,target,.1))
            assert(repairs==0 and repairable.CurrentFixer==other)
        """)

    def test_repair_session_is_stopped_on_mode_change_and_round_cleanup(self):
        self.lua.execute("""
            assert(G.repairDevice(owner,suit,target,.1));G.states[suit].mode='combat'
            G.pruneRepairs();assert(stops==1 and not repairable.CurrentFixer)
            G.states[suit].mode='repair';assert(G.repairDevice(owner,suit,target,.1))
            G.clearRepairs();assert(stops==2)
        """)

    def test_native_exception_restores_selection_and_clears_scope(self):
        self.lua.execute("""
            local selected=owner.SelectedItem
            repairable.Update=function() error('native failure') end
            assert(not pcall(G.repairDevice,owner,suit,target,.1))
            assert(owner.SelectedItem==selected and not G.repairScope)
        """)

    def test_native_ai_subclass_can_use_the_same_private_selection_bridge(self):
        self.lua.execute("""
            owner._selectedItem=nil;owner.nativeAI=true
            assert(G.repairDevice(owner,suit,target,.1))
            assert(repairs==1 and owner._selectedItem==nil)
        """)


class DescendantLightTests(LuaCase):
    def test_lights_wait_for_owner_replication_and_can_resolve_the_inventory_owner(self):
        self.lua.execute("""
            local count=0;local owner
            E={Vector2=function(x,y) return {X=x,Y=y} end,Color=function(...) return {...} end}
            E.LuaUserData={RegisterType=function() end,CreateStatic=function()
                return function() count=count+1;return {Remove=function() end} end
            end}
            G={now=0,owner=function() return owner end,energy=function() return 100 end,
                attachment=function(c) assert(c);return {x=1,y=2} end,
                restGoal=function(c) assert(c);return {x=1,y=2} end,
                mount=function(c) assert(c);return {x=1,y=2} end}
            require('DescendantSuit.lights').install(G,E)
            local s={item={}}
            G.updateLights(s);assert(count==0)
            owner={};G.updateLights(s);assert(count==2)
        """)

    def test_lights_go_dark_without_power_and_are_removed_when_cleared(self):
        self.lua.execute("""
            local count,removed=0,0
            E={Vector2=function(x,y) return {X=x,Y=y} end,Color=function(...) return {...} end}
            E.LuaUserData={RegisterType=function() end,CreateStatic=function()
                return function() count=count+1;return {Remove=function() removed=removed+1 end} end
            end}
            local owner={};local suit={}
            G={now=0,attachment=function() return {x=10,y=20} end,
                restGoal=function() return {x=10,y=20} end,
                mount=function() return {x=10,y=20} end,energy=function() return 100 end}
            require('DescendantSuit.lights').install(G,E)
            local s={item=suit,owner=owner,mode='off'}
            G.updateLights(s);assert(count==2 and s.lights.helmet.Range>0)
            G.energy=function() return 0 end
            G.updateLights(s);assert(count==2 and s.lights.helmet.Range==0 and s.lights.tool.Range==0)
            G.removeLights(s);assert(removed==2 and s.lights==nil)
            G.removeLights(s);assert(removed==2)
        """)
