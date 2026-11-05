from test_vacuum_storage_cache import VacuumStorageCacheTests


class VacuumTrashTests(VacuumStorageCacheTests):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            removed={};G.now=10
            E.Entity={Spawner={AddItemToRemoveQueue=function(item) removed[#removed+1]=item end}}
            require('SalvageVacuum.trash').install(G,E)
            owner={};ctx={valid=true,pack=pack,owner=owner}
        """)

    def test_two_step_trash_deletes_selected_group_and_nested_contents(self):
        self.lua.execute("""
            local child={kind='fuel',ID=30};a.OwnInventory=inventory(a,{child})
            child.ParentInventory=a.OwnInventory
            local ticket=G.prepareTrash(ctx,a.ID,false)
            assert(ticket.count==2 and #removed==0)
            assert(G.confirmTrash(ctx,a.ID,ticket.token))
            assert(#removed==2 and removed[1]==child and removed[2]==a)
            assert(G.reserved[a] and G.reserved[child] and not G.reserved[b])
            assert(not G.confirmTrash(ctx,a.ID,ticket.token))
        """)

    def test_individual_view_only_deletes_selected_instance(self):
        self.lua.execute("""
            page.OwnInventory.items[3]={kind='iron',ID=5,ParentInventory=page.OwnInventory}
            local ticket=G.prepareTrash(ctx,a.ID,true)
            assert(G.confirmTrash(ctx,a.ID,ticket.token) and #removed==1)
        """)

    def test_expired_foreign_changed_or_busy_ticket_never_deletes(self):
        self.lua.execute("""
            local t=G.prepareTrash(ctx,a.ID,false);G.now=30
            assert(not G.confirmTrash(ctx,a.ID,t.token))
            t=G.prepareTrash(ctx,a.ID,false);local other={valid=true,pack=pack,owner={}}
            assert(not G.confirmTrash(other,a.ID,t.token))
            a.ParentInventory=nil;assert(not G.confirmTrash(ctx,a.ID,t.token));a.ParentInventory=page.OwnInventory
            t=G.prepareTrash(ctx,a.ID,false);G.pending[pack]={}
            assert(not G.confirmTrash(ctx,a.ID,t.token) and #removed==0)
        """)
