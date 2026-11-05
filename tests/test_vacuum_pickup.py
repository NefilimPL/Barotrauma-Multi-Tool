from lua_support import LuaCase


class VacuumPickupTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E={LuaUserData={IsTargetType=function(obj,name) return obj and obj.type==name end},
                Hook={Add=function() end}}
            G={patch=function() end}
            function G.id(item) return item.id end
            function G.is(item,id) return item.id==id end
            require('SalvageVacuum.runtime').install(G,E)
            pick={Name='MeleeWeapon',type='Barotrauma.Items.Components.Pickable',
                CanBePicked=true,IsAttached=false,PickingTime=0}
            item={id='wrench',Components={pick},AllowedSlots={'Any'},HasAccess=function() return true end}
            G.children=function(i) return i.children or {} end
            ctx={owner={}}
        """)

    def test_subclasses_of_pickable_are_supported(self):
        self.lua.execute("assert(G.portable(item));assert(G.pickupTarget(item,ctx)==item)")

    def test_locked_source_inventory_is_not_bypassed(self):
        self.lua.execute("""
            pick.Name='Holdable'
            local cabinet={id='cabinet',Components={},type='Barotrauma.Item',HasAccess=function() return true end}
            item.ParentInventory={Owner=cabinet,Locked=true}
            assert(G.pickupTarget(item,ctx)==nil)
            item.ParentInventory.Locked=false
            assert(G.pickupTarget(item,ctx)==item)
        """)

    def test_spare_vacuum_on_floor_is_collectable_but_active_one_is_not(self):
        self.lua.execute("""
            item.id='aegisvacuum';assert(G.pickupTarget(item,ctx)==item)
            ctx.vacuum=item;assert(G.pickupTarget(item,ctx)==nil)
        """)

    def test_pickable_door_with_inventory_slot_is_never_loot(self):
        self.lua.execute("""
            item.Components={pick,{Name='Door'}}
            assert(not G.portable(item))
            assert(G.pickupTarget(item,ctx)==nil)
        """)

    def test_items_without_real_inventory_slots_are_not_loot(self):
        self.lua.execute("""
            for _,slots in ipairs({{}, {'None'}, {0}, {'None',0}}) do
                item.AllowedSlots=slots;assert(not G.portable(item))
            end
            item.AllowedSlots=nil;assert(not G.portable(item))
            item.AllowedSlots={'RightHand, LeftHand'};assert(G.portable(item))
            item.AllowedSlots={'OuterClothes'};assert(G.portable(item))
        """)

    def test_connected_or_routed_wires_are_never_loot(self):
        self.lua.execute("""
            local wire={Name='Wire',Connections={},GetNodes=function() return {} end}
            item.Components={pick,wire}
            assert(G.portable(item))
            wire.Connections[0]={};assert(not G.portable(item))
            wire.Connections={[1]={}};assert(not G.portable(item))
            wire.Connections={};wire.GetNodes=function() return {{X=1,Y=2}} end
            assert(not G.portable(item))
        """)

    def test_portable_container_cannot_smuggle_structural_or_installed_contents(self):
        self.lua.execute("""
            local bad={id='hatch',Components={pick,{Name='Door'}},AllowedSlots={'Any'},HasAccess=item.HasAccess}
            item.children={bad};assert(G.pickupTarget(item,ctx)==nil)
            bad.Components={pick,{Name='Wire',Connections={[0]={}},GetNodes=function() return {} end}}
            assert(G.pickupTarget(item,ctx)==nil)
            bad.Components={pick};assert(G.pickupTarget(item,ctx)==item)
        """)

    def test_nested_locked_contents_cannot_be_taken_inside_a_container(self):
        self.lua.execute("""
            local child={id='iron',Components={pick},AllowedSlots={'Any'},HasAccess=item.HasAccess,
                ParentInventory={Locked=true}}
            item.children={child};assert(G.pickupTarget(item,ctx)==nil)
            child.ParentInventory.Locked=false;assert(G.pickupTarget(item,ctx)==item)
        """)

    def test_spare_pack_pages_are_audited_without_treating_them_as_loot(self):
        self.lua.execute("""
            local tool={id='wrench',Components={pick},AllowedSlots={'Any'},HasAccess=item.HasAccess}
            local page={id='aegisvacuumpage',Components={},children={tool},HasAccess=item.HasAccess}
            item.id='aegisvacuumpack';item.children={page}
            assert(G.pickupTarget(item,ctx)==item)
            tool.Components={pick,{Name='Door'}};assert(G.pickupTarget(item,ctx)==nil)
            tool.Components={pick,{Name='Wire',Connections={[0]={}},GetNodes=function() return {} end}}
            assert(G.pickupTarget(item,ctx)==nil)
            tool.Components={pick};page.OwnInventory={Locked=true};assert(G.pickupTarget(item,ctx)==nil)
            page.OwnInventory=nil;item.id='metalcrate';assert(G.pickupTarget(item,ctx)==nil)
        """)

    def test_locked_second_container_and_oversized_or_cyclic_trees_are_rejected(self):
        self.lua.execute("""
            item.Components={pick,{Name='ItemContainer',Inventory={Locked=true}}}
            assert(G.pickupTarget(item,ctx)==nil)
            item.Components={pick};item.children={}
            for i=1,256 do item.children[i]={id='iron',Components={pick},AllowedSlots={'Any'},HasAccess=item.HasAccess} end
            assert(G.pickupTarget(item,ctx)==nil)
            item.children={item};assert(G.pickupTarget(item,ctx)==nil)
        """)
