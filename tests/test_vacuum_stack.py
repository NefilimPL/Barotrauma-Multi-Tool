from test_vacuum_storage_cache import VacuumStorageCacheTests


class VacuumStackTests(VacuumStorageCacheTests):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E.InvSlotType={Any='any',RightHand=1,LeftHand=2}
            ctx={valid=true,pack=pack,owner={Inventory={}}};capacity=200;taken={}
            ctx.owner.Inventory.TryPutItem=function(item,user,slots)
                if #taken>=capacity then return false end
                taken[#taken+1]=item
                for i,it in ipairs(page.OwnInventory.items) do if it==item then table.remove(page.OwnInventory.items,i);break end end
                item.ParentInventory=ctx.owner.Inventory
                hooks['stored-remove']({Item=page},{containedItem=item});return true
            end
        """)

    def test_take_stack_preserves_instances_and_leaves_other_types(self):
        self.lua.execute("""
            for i=5,103 do local it={kind='iron',ID=i,Condition=i,ParentInventory=page.OwnInventory}
                page.OwnInventory.items[#page.OwnInventory.items+1]=it end
            assert(G.withdrawStack(ctx,a.ID));assert(#taken==100)
            assert(#G.contents(pack)==1 and G.contents(pack)[1]==b)
            assert(taken[1]==a and taken[2].Condition==5)
        """)

    def test_partial_capacity_leaves_remainder_in_backpack(self):
        self.lua.execute("""
            capacity=1;page.OwnInventory.items[3]={kind='iron',ID=8,ParentInventory=page.OwnInventory}
            assert(G.withdrawStack(ctx,a.ID));assert(#taken==1 and #G.contents(pack)==2)
        """)

    def test_busy_and_foreign_targets_do_not_move_anything(self):
        self.lua.execute("""
            G.jobs[pack]={};assert(not G.withdrawStack(ctx,a.ID));G.jobs[pack]=nil
            assert(not G.withdrawStack(ctx,999));ctx.valid=false;assert(not G.withdrawStack(ctx,a.ID))
            assert(#taken==0)
        """)
