from test_vacuum_adapter import VacuumAdapterTests


class VacuumNetworkTests(VacuumAdapterTests):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            G.contents=function() return {} end;G.records=function() return {} end
            local callbacks={}
            env.Networking={Receive=function(name,fn) callbacks[name]=fn end}
            require('SalvageVacuum.network').install(G,env)
            calls=0;G.withdraw=function(ctx,id) calls=calls+1;return true end
            G.startSalvage=function(ctx) calls=calls+1;return true end
        """)

    def test_invalid_request_never_mutates(self):
        self.lua.execute("""
            assert(not G.handleRequest({Character={}},'salvage',vacuum,0,{}))
            assert(calls==0)
        """)

    def test_duplicate_mutation_is_rate_limited(self):
        self.lua.execute("""
            assert(G.handleRequest({Character=owner},'salvage',vacuum,0,{}))
            assert(not G.handleRequest({Character=owner},'salvage',vacuum,0,{}))
            assert(calls==1)
        """)

    def test_pack_selection_cannot_choose_foreign_or_busy_pack(self):
        self.lua.execute("""
            assert(not G.handleRequest({Character=owner},'select',vacuum,99,{}))
            G.now=1;G.jobs[pack]={}
            assert(not G.handleRequest({Character=owner},'select',vacuum,pack.ID,{}))
        """)

    def test_snapshot_limits_page_size_and_search_length(self):
        self.lua.execute("""
            local view=G.normalizeView({page=10000,group=-1,search=string.rep('x',500)})
            assert(view.page==99 and view.group==0 and #view.search==64)
            local s=G.snapshot(G.context(vacuum),view)
            assert(#s.rows<=8 and s.pack==pack.ID)
        """)
