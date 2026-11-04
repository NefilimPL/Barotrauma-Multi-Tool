from lua_support import LuaCase


class VacuumCraftingTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            local function item(kind,id) return {Prefab={Identifier=kind},ID=id,HasAccess=function() return true end} end
            pack=item('aegisvacuumpack',1);ore=item('iron',2);other=item('iron',3)
            page=item('aegisvacuumpage',4);machine=item('fabricator',5)
            owner={SelectedItem=machine,Inventory={GetItemInLimbSlot=function() return pack end}}
            pack.ParentInventory={Owner=owner};pack.OwnInventory={};page.ParentInventory={Owner=pack}
            records={{kind='iron',id=ore.ID,item=ore}}
            d={ContainsKey=function(k) return d[k]~=nil end}
            fab={Item=machine,user=owner,availableIngredients=d}
            E={Character={Controlled=owner},InvSlotType={Bag='bag'},LuaUserData={
                RegisterType=function(n) return n end,MakeFieldAccessible=function() end,
                IsTargetType=function(o,t) return o==owner and t=='Barotrauma.Character' or o and o.Prefab and t=='Barotrauma.Item' end}}
            G={jobs={},pending={},reserved={},patch=function() end,
                is=function(i,k) return i and i.Prefab and i.Prefab.Identifier==k end,
                id=function(i) return i.Prefab.Identifier end,
                pages=function() return {page} end,
                has=function(p,i) return p==pack and i==page end,
                materialRecords=function() return records end,
                materialContainers=function() return {} end}
            require('SalvageVacuum.crafting').install(G,E)
        """)

    def test_worn_backpack_supplies_real_instances_and_preserves_other_sources(self):
        self.lua.execute("""
            d.iron={other};G.refreshCrafting(fab)
            assert(#d.iron==2 and d.iron[1]==other and d.iron[2]==ore)
        """)

    def test_no_materials_after_deselecting_or_without_worn_bag(self):
        self.lua.execute("""
            owner.SelectedItem=nil;G.refreshCrafting(fab);assert(d.iron==nil)
            owner.SelectedItem=machine;owner.Inventory.GetItemInLimbSlot=function() end
            G.refreshCrafting(fab);assert(d.iron==nil)
        """)

    def test_already_expanded_native_backpack_is_not_added_twice(self):
        self.lua.execute("""
            d.aegisvacuumpage={page};d.iron={ore};G.refreshCrafting(fab);assert(#d.iron==1)
        """)

    def test_busy_linked_pack_is_removed_from_native_ingredients(self):
        self.lua.execute("""
            d.aegisvacuumpack={pack};d.iron={ore,other};G.jobs[pack]={}
            G.refreshCrafting(fab);assert(#d.iron==1 and d.iron[1]==other)
        """)

    def test_pending_products_and_reserved_sources_cannot_be_used_from_input_either(self):
        self.lua.execute("""
            local product={ID=8,Prefab={Identifier='iron'}}
            d.iron={ore,product,other};G.reserved[ore]=true
            G.pending[pack]={item=ore,products={product}}
            G.refreshCrafting(fab);assert(#d.iron==1 and d.iron[1]==other)
        """)

    def test_locked_pack_is_not_a_source(self):
        self.lua.execute("""
            pack.OwnInventory.Locked=true;d.aegisvacuumpack={pack};d.iron={ore,other}
            G.refreshCrafting(fab);assert(#d.iron==1 and d.iron[1]==other)
        """)

    def test_dedicated_server_registers_its_own_item_assembly(self):
        self.lua.execute("""
            E.SERVER=true;local registered
            E.LuaUserData.RegisterType=function(name) registered=name;return name end
            require('SalvageVacuum.crafting').install(G,E)
            assert(registered:find('Barotrauma.Item, DedicatedServer',1,true))
        """)

    def test_removed_old_transaction_does_not_block_a_reused_entity_id(self):
        self.lua.execute("""
            owner.SelectedItem=nil
            local old={ID=other.ID,Prefab={Identifier='iron'},Removed=true}
            G.pending[{}]={products={old}};G.reserved[old]=true;d.iron={other}
            G.refreshCrafting(fab);assert(#d.iron==1 and d.iron[1]==other)
        """)
