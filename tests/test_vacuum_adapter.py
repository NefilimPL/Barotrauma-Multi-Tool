from lua_support import LuaCase


class VacuumAdapterTests(LuaCase):
    def test_overloaded_inventory_patch_is_installed_and_removed_with_its_signature(self):
        self.lua.execute('''
            local installed,removed
            env.Hook={HookMethodType={Before=1,After=2},Remove=function() end,
                Patch=function(id,class,method,types,fn,phase)
                    assert(type(types)=='table' and types[2]=='System.Int32','ambiguous inventory hook')
                    installed=types
                end,
                RemovePatch=function(id,class,method,types,phase) removed=types end}
            local signature={'Barotrauma.Item','System.Int32'}
            G.patch('drag','Barotrauma.CharacterInventory','TryPutItem',function() end,false,signature)
            G.dispose();assert(installed==signature and removed==signature)
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute("""
            local function inv(owner,items)
                return {Owner=owner,AllItems=items or {},GetItemAt=function(i) return (items or {})[i+1] end,
                    GetItemInLimbSlot=function(slot) return owner.hands and owner.hands[slot] end}
            end
            owner={ID=1,IsDead=false,IsUnconscious=false,Removed=false}
            owner.IsKeyDown=function() return true end
            pack={ID=2,Prefab={Identifier='aegisvacuumpack'},Condition=100,Removed=false}
            vacuum={ID=3,Prefab={Identifier='aegisvacuum'},Condition=100,Removed=false}
            battery={ID=4,Condition=80,MaxCondition=100,Removed=false,HasTag=function(t) return t=='mobilebattery' end}
            owner.Inventory=inv(owner,{pack,vacuum});owner.hands={right=vacuum,left=vacuum}
            vacuum.ParentInventory=owner.Inventory;pack.ParentInventory=owner.Inventory
            vacuum.OwnInventory=inv(vacuum,{battery});pack.OwnInventory=inv(pack,{})
            env={SERVER=true,Game={IsSingleplayer=false},InvSlotType={RightHand='right',LeftHand='left'},
                InputType={Aim='aim',Use='use'},LuaUserData={IsTargetType=function(x,t) return x==owner end}}
            G=require('SalvageVacuum.game').new(env)
        """)

    def test_battery_is_read_from_vacuum_not_pack(self):
        self.lua.execute("""
            assert(G.context(vacuum).valid)
            assert(G.source(vacuum)==battery)
            assert(G.spend(vacuum,2) and battery.Condition==78)
            vacuum.OwnInventory={GetItemAt=function() end}
            pack.OwnInventory={GetItemAt=function() return battery end}
            assert(not G.spend(vacuum,1))
        """)

    def test_requires_both_hands_and_pack_on_same_character(self):
        self.lua.execute("""
            owner.hands.left=nil;assert(not G.context(vacuum).valid)
            owner.hands.left=vacuum
            owner.Inventory.AllItems={vacuum};assert(not G.context(vacuum).valid)
        """)

    def test_foreign_character_cannot_use_vacuum(self):
        self.lua.execute("assert(not G.context(vacuum,{ID=99}).valid)")

    def test_dead_unconscious_or_broken_owner_cannot_operate(self):
        self.lua.execute("""
            owner.IsDead=true;assert(not G.context(vacuum).valid);owner.IsDead=false
            owner.IsUnconscious=true;assert(not G.context(vacuum).valid);owner.IsUnconscious=false
            vacuum.Condition=0;assert(not G.context(vacuum).valid)
        """)

    def test_power_failure_does_not_partially_consume_charge(self):
        self.lua.execute("battery.Condition=.2;assert(not G.spend(vacuum,1));assert(battery.Condition==.2)")

    def test_backpack_contents_remain_accessible_without_holding_vacuum(self):
        self.lua.execute("""
            owner.hands={}
            local ctx=G.context(pack,owner)
            assert(ctx.valid and ctx.pack==pack)
            assert(G.source(pack)==nil)
        """)

    def test_equipped_bag_is_preferred_to_an_old_pack_in_a_pocket(self):
        self.lua.execute("""
            local worn={ID=20,Prefab={Identifier='aegisvacuumpack'},Condition=100,Removed=false}
            env.InvSlotType.Bag='bag';owner.hands.bag=worn
            owner.Inventory.AllItems={pack,worn,vacuum};worn.ParentInventory=owner.Inventory
            assert(G.context(vacuum).pack==worn)
            G.selected[vacuum.ID]=pack.ID;assert(G.context(vacuum).pack==pack)
        """)

    def test_pack_in_selected_cabinet_requires_range_access_and_unlocked_ancestors(self):
        self.lua.execute("""
            local cabinet={Prefab={Identifier='steelcabinet'},HasAccess=function() return allowed end}
            env.LuaUserData.IsTargetType=function(x,t)
                return t=='Barotrauma.Character' and x==owner or t=='Barotrauma.Item' and x and x.Prefab~=nil
            end
            allowed=true;inRange=true;owner.SelectedItem=cabinet
            owner.CanInteractWith=function(i) return i==cabinet and inRange end
            cabinet.OwnInventory={Owner=cabinet,AllItems={pack}}
            pack.ParentInventory=cabinet.OwnInventory;pack.HasAccess=cabinet.HasAccess
            assert(G.context(pack,owner).valid)
            cabinet.OwnInventory.Locked=true;assert(not G.context(pack,owner).valid)
            cabinet.OwnInventory.Locked=false;inRange=false;assert(not G.context(pack,owner).valid)
            inRange=true;allowed=false;assert(not G.context(pack,owner).valid)
            allowed=true;owner.SelectedItem=nil;assert(not G.context(pack,owner).valid)
        """)

    def test_locked_backpack_is_not_accessible_or_operable(self):
        self.lua.execute("""
            pack.OwnInventory.Locked=true
            assert(not G.context(pack,owner).valid)
            assert(not G.context(vacuum,owner).valid)
        """)

    def test_stunned_or_hands_locked_character_cannot_operate(self):
        self.lua.execute("owner.CanInteract=false;assert(not G.context(vacuum).valid)")

    def test_request_authentication_rejects_forged_or_dead_client(self):
        self.lua.execute("""
            assert(G.authorize({Character=owner},vacuum))
            assert(not G.authorize({Character={ID=99}},vacuum))
            assert(not G.authorize({},vacuum))
            owner.IsDead=true;assert(not G.authorize({Character=owner},vacuum))
        """)
