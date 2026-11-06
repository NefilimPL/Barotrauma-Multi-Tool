from test_vacuum_storage_cache import VacuumStorageCacheTests


class VacuumStackTests(VacuumStorageCacheTests):
    def test_batch_groups_spread_unstackable_items_and_leave_overflow(self):
        self.lua.execute('''
            capacity=1
            for i=5,44 do page.OwnInventory.items[#page.OwnInventory.items+1]={kind='iron',ID=i,ParentInventory=page.OwnInventory} end
            local ok,moved=G.withdrawBatch(ctx,{a.ID,a.ID,999},true)
            assert(ok and moved==4 and #taken==4)
            assert(#G.contents(pack)==38,'overflow was lost or foreign item moved')
            for _,it in ipairs(taken) do assert(it.kind=='iron') end
        ''')

    def test_batch_details_only_move_selected_instances_and_obey_busy_state(self):
        self.lua.execute('''
            G.pending[pack]={};assert(not G.withdrawBatch(ctx,{a.ID,b.ID},false));G.pending[pack]=nil
            local ok,moved=G.withdrawBatch(ctx,{b.ID,b.ID,999},false)
            assert(ok and moved==1 and taken[1]==b and G.has(pack,a))
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E.InvSlotType={Any='any',RightHand=1,LeftHand=2}
            ctx={valid=true,pack=pack,owner={Inventory={Capacity=4,SlotTypes={[0]='any',[1]='any',[2]='any',[3]='any'}}}}
            capacity=8;taken={};dest={[0]={},[1]={},[2]={},[3]={}}
            local inv=ctx.owner.Inventory
            inv.GetItemAt=function(i) return dest[i][1] end
            inv.CanBePutInSlot=function(item,i)
                local first=dest[i][1]
                return #dest[i]<capacity and (not first or
                    (first.kind==item.kind and first.Quality==item.Quality and first.Condition==item.Condition))
            end
            inv.TryPutItem=function(item,slot,slots)
                if type(slot)~='number' then
                    slot=nil;for i=0,3 do if inv.CanBePutInSlot(item,i) then slot=i;break end end
                end
                if slot==nil or not inv.CanBePutInSlot(item,slot) then return false end
                dest[slot][#dest[slot]+1]=item
                taken[#taken+1]=item
                for i,it in ipairs(page.OwnInventory.items) do if it==item then table.remove(page.OwnInventory.items,i);break end end
                item.ParentInventory=ctx.owner.Inventory
                hooks['stored-remove']({Item=page},{containedItem=item});return true
            end
        """)

    def test_take_stack_fills_only_one_native_slot_and_preserves_instances(self):
        self.lua.execute("""
            for i=5,103 do local it={kind='iron',ID=i,ParentInventory=page.OwnInventory}
                page.OwnInventory.items[#page.OwnInventory.items+1]=it end
            assert(G.withdrawStack(ctx,a.ID));assert(#taken==8,'one click must take one native stack')
            assert(#G.contents(pack)==93 and #dest[1]==0 and #dest[2]==0)
            assert(taken[1]==a and taken[2].ID==5)
        """)

    def test_partial_capacity_leaves_remainder_in_backpack(self):
        self.lua.execute("""
            capacity=1;page.OwnInventory.items[3]={kind='iron',ID=8,ParentInventory=page.OwnInventory}
            assert(G.withdrawStack(ctx,a.ID));assert(#taken==1 and #G.contents(pack)==2)
        """)

    def test_partial_existing_stack_is_topped_up_without_spreading(self):
        self.lua.execute("""
            for i=1,6 do dest[2][i]={kind='iron'} end
            for i=5,15 do page.OwnInventory.items[#page.OwnInventory.items+1]={kind='iron',ID=i,ParentInventory=page.OwnInventory} end
            assert(G.withdrawStack(ctx,a.ID));assert(#taken==2 and #dest[2]==8 and #dest[0]==0)
        """)

    def test_quality_and_condition_do_not_create_extra_stacks(self):
        self.lua.execute("""
            page.OwnInventory.items[3]={kind='iron',ID=5,Quality=3,ParentInventory=page.OwnInventory}
            page.OwnInventory.items[4]={kind='iron',ID=6,Condition=20,ParentInventory=page.OwnInventory}
            assert(G.withdrawStack(ctx,5));assert(#taken==1 and taken[1].ID==5)
            assert(#G.contents(pack)==3)
        """)

    def test_busy_and_foreign_targets_do_not_move_anything(self):
        self.lua.execute("""
            G.jobs[pack]={};assert(not G.withdrawStack(ctx,a.ID));G.jobs[pack]=nil
            assert(not G.withdrawStack(ctx,999));ctx.valid=false;assert(not G.withdrawStack(ctx,a.ID))
            assert(#taken==0)
        """)
