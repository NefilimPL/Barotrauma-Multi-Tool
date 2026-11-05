from lua_support import LuaCase


class IdlePerformanceTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            worldReads=0;indexed={};world={};hooks={}
            E={Item=setmetatable({},{__index=function(_,key)
                    if key=='ItemList' then worldReads=worldReads+1;return world end
                end}),
                Util={GetItemsById=function(id) return indexed[id] end},
                Hook={Add=function(event,id,fn) hooks[event]=fn end},
                LuaUserData={CreateEnumTable=function() return {Both=1} end,
                    RegisterType=function() return {} end,MakeFieldAccessible=function() end}}
            function vacuumRuntime(authoritative)
                G={now=0,states={},jobs={},selected={},pending={},reserved={},authoritative=authoritative,
                    patch=function() end,id=function(i) return i.kind end,
                    is=function(i,id) return i and not i.Removed and i.kind==id end,
                    context=function() return {valid=false} end}
                require('SalvageVacuum.runtime').install(G,E)
            end
            function worldItems(count)
                for i=1,count do world[i]={ID=i,kind='iron'} end
            end
        """)

    def test_idle_vacuum_does_not_scan_world_on_server_or_client(self):
        self.lua.execute("""
            worldItems(10000)
            for _,authority in ipairs({true,false}) do
                vacuumRuntime(authority);worldReads=0
                for i=1,300 do G.update(1/60) end
                assert(worldReads==0,'idle vacuum scanned the world '..worldReads..' times')
            end
        """)

    def test_indexed_nozzles_are_discovered_but_stored_spares_are_not_active(self):
        self.lua.execute("""
            vacuumRuntime(false);G.update(.01)
            local nozzle={ID=1,kind='aegisvacuum'}
            local spare={ID=2,kind='aegisvacuum',RootContainer={kind='aegisvacuumpack'}}
            indexed.aegisvacuum={nozzle,spare};world={nozzle,spare}
            for i=1,40 do G.update(.02) end
            assert(G.states[nozzle] and not G.states[spare])
            nozzle.Removed=true
            for i=1,40 do G.update(.02) end
            assert(not G.states[nozzle]);assert(worldReads==0)
        """)

    def test_only_authoritative_suction_refreshes_loot_and_finds_new_world_items(self):
        self.lua.execute("""
            local nozzle={ID=1,kind='aegisvacuum',WorldPosition={X=-10000,Y=0}}
            indexed.aegisvacuum={nozzle}
            local pack={};local picked={}
            for _,authority in ipairs({true,false}) do
                vacuumRuntime(authority);worldReads=0;picked={};world={nozzle}
                G.context=function() return {valid=true,aim=true,pack=pack,owner={}} end
                G.charge=function() return 100 end;G.spend=function() return true end
                G.muzzle=function() return {x=0,y=0} end
                G.direction=function() return {x=1,y=0} end
                G.cast=function() end
                G.insert=function(_,item) picked[item.ID]=true;item.Removed=true;return true end
                G.update(.01)
                G.pickupTarget=function(item) return item end
                for i=1,90 do
                    if i==2 then world[2]={ID=2,kind='iron',WorldPosition={X=10,Y=0}} end
                    if i==45 then world[3]={ID=3,kind='copper',WorldPosition={X=20,Y=0}} end
                    G.states[nozzle].usedAt=G.now;G.update(1/60)
                end
                if authority then
                    assert(picked[2] and picked[3],'active suction missed new loot')
                    assert(worldReads>0 and worldReads<=5,'loot refresh is not bounded')
                else assert(worldReads==0 and next(picked)==nil,'client scanned authoritative loot') end
                local reads=worldReads
                for i=1,90 do G.update(1/60) end
                assert(worldReads<=reads+1,'loot scanning continued after trigger release')
            end
        """)

    def test_idle_combat_tool_uses_index_instead_of_scanning_world(self):
        self.lua.execute("""
            worldItems(10000)
            local activations=0
            local tool={ID=11000,Components={}}
            G={now=0,frame=0,states={},authoritative=false,patch=function() end,
                isWeapon=function(i) return i==tool end,
                state=function() activations=activations+1;return {} end}
            require('CombatTool.runtime').install(G,E)
            for i=1,60 do G.update(1/60) end
            indexed.combatmultitool={tool};world[#world+1]=tool
            for i=1,60 do G.update(1/60) end
            assert(activations>0,'new indexed tool was not activated')
            assert(worldReads==0,'idle combat tool scanned the world '..worldReads..' times')
        """)

    def test_idle_audio_does_not_resolve_inventory_context(self):
        self.lua.execute("""
            local nozzle={ID=1};local contexts=0
            G={now=10,states={[nozzle]={}},remoteActiveUntil={},jobs={},pending={},
                context=function() contexts=contexts+1;return {valid=false} end}
            require('SalvageVacuum.audio').install(G,{})
            for i=1,60 do G.updateAudio() end
            assert(contexts==0,'idle audio resolved inventories '..contexts..' times')
        """)
