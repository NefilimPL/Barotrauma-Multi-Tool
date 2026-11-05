from lua_support import LuaCase


class VacuumStorageCacheTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            reads=0;idReads=0;hooks={}
            function inventory(owner,items,capacity)
                local inv={Owner=owner,items=items,Capacity=capacity or 100}
                inv.GetItemAt=function(i) reads=reads+1;return inv.items[i+1] end
                inv.IsFull=function() return #inv.items>=inv.Capacity end
                return setmetatable(inv,{__index=function(t,k)
                    if k=='AllItems' then reads=reads+1;return t.items end
                end})
            end
            pack={kind='aegisvacuumpack',ID=1}
            page={kind='aegisvacuumpage',ID=2,ParentInventory=inventory(pack,{})}
            a={kind='iron',ID=3};b={kind='copper',ID=4}
            pack.OwnInventory=inventory(pack,{page})
            page.ParentInventory=pack.OwnInventory;page.OwnInventory=inventory(page,{a,b})
            a.ParentInventory=page.OwnInventory;b.ParentInventory=page.OwnInventory
            G={reserved={},pending={},jobs={},authoritative=true,
                id=function(i) idReads=idReads+1;return i.kind end,
                is=function(i,id) return i and not i.Removed and i.kind==id end,
                patch=function(name,class,method,fn) hooks[name]=fn end}
            E={LuaUserData={IsTargetType=function(i,name) return i and i.kind~=nil end}}
            require('SalvageVacuum.storage').install(G,E)
            G.children=function(item) return item.OwnInventory and item.OwnInventory.AllItems or {} end
        """)

    def test_unchanged_contents_and_records_do_not_reenter_native_items(self):
        self.lua.execute("""
            G.records(G.contents(pack));reads=0;idReads=0
            for i=1,10 do local r=G.records(G.contents(pack));assert(#r==2 and r[1].kind=='iron') end
            assert(reads==0 and idReads==0,'unchanged storage was rescanned')
        """)

    def test_material_records_include_nested_contents_and_stay_cached(self):
        self.lua.execute("""
            local nested={kind='copper',ID=30};b.OwnInventory=inventory(b,{nested});nested.ParentInventory=b.OwnInventory
            assert(#G.materialRecords(pack)==3);reads=0;idReads=0
            for i=1,10 do assert(#G.materialRecords(pack)==3) end
            assert(reads==0 and idReads==0)
            b.OwnInventory.items={};nested.ParentInventory=nil
            hooks['stored-remove']({Item=b},{containedItem=nested})
            assert(#G.materialRecords(pack)==2)
        """)

    def test_material_records_keep_reserved_sources_for_machine_exclusion(self):
        self.lua.execute("""
            assert(#G.materialRecords(pack)==2);G.pending[pack]={};G.reserved[a]=true
            assert(#G.contents(pack)==1 and #G.materialRecords(pack)==2)
        """)

    def test_native_add_remove_events_keep_contents_and_types_current(self):
        self.lua.execute("""
            assert(#G.contents(pack)==2)
            local c={kind='iron',ID=5,ParentInventory=page.OwnInventory}
            page.OwnInventory.items[3]=c
            hooks['stored-add']({Item=page},{containedItem=c})
            assert(#G.contents(pack)==3)
            table.remove(page.OwnInventory.items,1);a.ParentInventory=nil
            hooks['stored-remove']({Item=page},{containedItem=a})
            local list=G.contents(pack)
            assert(#list==2 and list[1]~=a and list[2]~=a)
        """)

    def test_reserved_sources_are_not_exposed_as_available_contents(self):
        self.lua.execute("""
            G.contents(pack);G.pending[pack]={};G.reserved[a]=true
            local list=G.contents(pack);assert(#list==1 and list[1]==b)
            G.pending[pack]=nil;G.reserved[a]=nil;assert(#G.contents(pack)==2)
        """)

    def test_slot_lookup_skips_full_pages_and_stops_at_requested_count(self):
        self.lua.execute("""
            local pages={}
            for n=1,3 do
                local p={kind='aegisvacuumpage',ID=n,ParentInventory=pack.OwnInventory}
                local items={};for i=1,(n==3 and 99 or 100) do items[i]={kind='iron',ID=n*100+i} end
                p.OwnInventory=inventory(p,items);pages[n]=p
            end
            pack.OwnInventory.items=pages;reads=0
            local slots=G.freeSlots(pack,1)
            assert(#slots==1 and slots[1].slot==99)
            assert(reads<=101,'queried full pages slot by slot: '..reads)
        """)

    def test_reset_discards_storage_references_and_rebuilds_native_state(self):
        self.lua.execute("""
            G.contents(pack);page.OwnInventory.items={b}
            G.clearStorageCache()
            local list=G.contents(pack);assert(#list==1 and list[1]==b)
        """)

    def test_whole_page_moves_update_only_affected_page(self):
        self.lua.execute("""
            G.contents(pack)
            local p={kind='aegisvacuumpage',ID=10,ParentInventory=pack.OwnInventory}
            local c={kind='iron',ID=11};p.OwnInventory=inventory(p,{c});c.ParentInventory=p.OwnInventory
            pack.OwnInventory.items[2]=p;reads=0
            hooks['stored-add']({Item=pack},{containedItem=p})
            assert(#G.contents(pack)==3 and reads<=1,'new page rebuilt all previous pages')
            table.remove(pack.OwnInventory.items,2);p.ParentInventory=nil
            hooks['stored-remove']({Item=pack},{containedItem=p})
            assert(#G.contents(pack)==2)
        """)

    def test_snapshot_view_is_reused_until_actual_membership_changes(self):
        self.lua.execute("""
            local first=G.storageView(pack)
            assert(first.count==2 and #first.groups==2)
            assert(G.storageView(pack)==first)
            local c={kind='iron',ID=5,ParentInventory=page.OwnInventory}
            page.OwnInventory.items[3]=c
            hooks['stored-add']({Item=page},{containedItem=c})
            local nextView=G.storageView(pack)
            assert(nextView~=first and nextView.count==3 and #nextView.groups==2)
            G.pending[pack]={};G.reserved[c]=true
            assert(G.storageView(pack)==nil)
        """)

    def test_sorted_record_copies_do_not_corrupt_removal_alignment(self):
        self.lua.execute("""
            local r=G.records(G.contents(pack))
            table.sort(r,function(x,y) return x.kind<y.kind end)
            table.remove(page.OwnInventory.items,1);a.ParentInventory=nil
            hooks['stored-remove']({Item=page},{containedItem=a})
            local items=G.contents(pack);local records=G.records(items)
            assert(#items==1 and records[1].item==items[1] and records[1].kind=='copper')
        """)

    def test_reused_native_id_does_not_reuse_old_item_metadata(self):
        self.lua.execute("""
            G.records({a})
            local replacement={kind='new_mod_item',ID=a.ID}
            local r=G.records({replacement})[1]
            assert(r.kind=='new_mod_item' and r.item==replacement)
        """)
