from lua_support import LuaCase


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
