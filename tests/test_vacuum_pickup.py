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
            item={id='wrench',Components={pick},HasAccess=function() return true end}
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
