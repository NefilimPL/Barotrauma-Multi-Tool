from xml.etree import ElementTree as ET

from lua_support import ROOT, LuaCase


class CabinetPackDiscoveryTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def test_discovery_uses_pack_index_and_checks_current_cabinet_access(self):
        self.lua.execute("""
            local function item(id)
                return {nativeItem=true,Prefab={Identifier=id},HasAccess=function() return true end}
            end
            local cabinet,crate,other=item('steelcabinet'),item('metalcrate'),item('steelcabinet')
            local available,elsewhere,removed=item('aegisvacuumpack'),item('aegisvacuumpack'),item('aegisvacuumpack')
            local nested={Owner=crate}
            available.ParentInventory=nested
            crate.ParentInventory={Owner=cabinet}
            available.GetRootInventoryOwner=function() return crate.ParentInventory.Owner end
            elsewhere.GetRootInventoryOwner=function() return other end
            removed.Removed=true
            local character={SelectedItem=cabinet,Inventory={AllItems={}},CanInteractWith=function() return true end}
            local E={Game={IsSingleplayer=true},InvSlotType={},Util={GetItemsById=function(id)
                assert(id=='aegisvacuumpack')
                return {elsewhere,available,removed}
            end},LuaUserData={IsTargetType=function(entity,name)
                if name=='Barotrauma.Item' then return entity.nativeItem==true end
                return entity==character
            end}}
            local G=require('AegisVacuum.game').new(E)
            G.children=function() error('must not traverse cabinet contents') end
            local packs=G.availablePacks(character)
            assert(#packs==1 and packs[1]==available)
            nested.Locked=true
            assert(#G.availablePacks(character)==0)
            nested.Locked=false;crate.ParentInventory.Owner=other
            assert(#G.availablePacks(character)==0,'stale cabinet permission')
            character.SelectedItem=other
            packs=G.availablePacks(character)
            assert(#packs==1 and packs[1]==available)
        """)


class SuitCabinetTests(LuaCase):
    def test_all_aegis_families_can_be_returned_to_a_dive_locker(self):
        for filename in ('System-Aegis/aegis_suit.xml',
                         'System-Aegis-No-Headsets/aegis_suit.xml',
                         'System-Aegis-No-Headsets/aegis_factions.xml'):
            for suit in ET.parse(ROOT / filename).getroot().findall('Item'):
                identifier = suit.get('identifier', '')
                if not identifier.startswith('aegisservosuit'):
                    continue
                with self.subTest(filename=filename, suit=identifier):
                    choice = suit.find("PreferredContainer[@primary='divingsuitcontainer']")
                    self.assertIsNotNone(choice)
                    self.assertEqual(choice.get('spawnprobability'), '0')

    def test_gear_search_prefers_aegis_in_a_locker_but_keeps_native_fallbacks(self):
        self.lua.execute('''
            local G={authoritative=true,is=function(item) return item.aegis end}
            local hooks,stock={},{}
            G.patch=function(name,_,_,hook) hooks[name]=hook end
            local E={LuaUserData={RegisterType=function() end,MakePropertyAccessible=function() end,
                MakeFieldAccessible=function() end,HasMember=function(o,k) return o[k]~=nil end},
                Util={RegisterItemGroup=function() end,GetItemGroup=function() return stock end}}
            require('AegisSuit.gear').install(G,E)
            local sub={IsConnectedTo=function() return true end}
            local locker={HasTag=function(tag) return tag=='divingsuitcontainer' end,Submarine=sub}
            local prefab={BotPriority=2}
            local floor={aegis=true,Prefab=prefab}
            local stored={aegis=true,Container=locker,ParentInventory={},Prefab=prefab,HasAccess=function() return true end}
            local locked={aegis=true,Container=locker,ParentInventory={Locked=true},Prefab=prefab}
            local objective={IsFindDivingGearSubObjective=true,Wear=true,EvaluateAllItems=false,
                currentSearchIndex=0,character={Submarine=sub}}
            local function score(item,accepted)
                hooks['locker-suit-candidate'](objective,{item=item,ReturnValue=accepted})
                return prefab.BotPriority
            end
            hooks['locker-search-start'](objective)
            assert(not objective.EvaluateAllItems and score(stored,true)==2,
                'a search without stored gear changed the native path')
            stock[1]=stored
            hooks['locker-search-start'](objective)
            assert(objective.EvaluateAllItems)
            assert(score(stored,true)>2)
            assert(score(floor,true)==2 and score(stored,false)==2 and score(locked,true)==2)
            assert(score(stored,true)>2)
            hooks['locker-search-end'](objective)
            assert(prefab.BotPriority==2 and objective.EvaluateAllItems==false)
            require('AegisSuit.gear').install(G,E)
            objective.EvaluateAllItems=nil
            objective.CheckPathForEachItem=false
            hooks['locker-search-start'](objective)
            assert(objective.CheckPathForEachItem and objective.EvaluateAllItems==nil)
            hooks['locker-search-end'](objective)
            assert(objective.CheckPathForEachItem==false)
        ''')
