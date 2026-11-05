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

    def test_activity_sends_heartbeats_only_while_active_and_one_stop(self):
        self.lua.execute("""
            local sent=0
            env.Networking.Start=function() return {WriteUInt16=function() end,WriteBoolean=function() end} end
            env.Networking.Send=function() sent=sent+1 end
            for i=1,60 do G.sendActivity(vacuum,false) end
            assert(sent==0,'idle nozzle sent '..sent..' packets')
            G.sendActivity(vacuum,true);G.sendActivity(vacuum,true)
            assert(sent==2,'active heartbeat must keep remote effects alive')
            for i=1,60 do G.sendActivity(vacuum,false) end
            assert(sent==3,'release must send exactly one stop packet')
            G.sendActivity(vacuum,true);assert(sent==4)
        """)

    def test_round_reset_discards_outgoing_activity_and_remote_timeouts(self):
        self.lua.execute("""
            local sent=0
            env.Networking.Start=function() return {WriteUInt16=function() end,WriteBoolean=function() end} end
            env.Networking.Send=function() sent=sent+1 end
            G.sendActivity(vacuum,true);G.remoteActiveUntil[vacuum.ID]=10
            G.reset();G.sendActivity(vacuum,false)
            assert(sent==1 and next(G.remoteActiveUntil)==nil)
            G.sendActivity(vacuum,true);assert(sent==2)
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

    def test_background_poll_does_not_swallow_a_stack_click(self):
        self.lua.execute("""
            G.withdrawStack=function() calls=calls+1;return true end
            assert(G.handleRequest({Character=owner},'open',vacuum,0,{}))
            assert(G.handleRequest({Character=owner},'stack',vacuum,10,{}))
            assert(not G.handleRequest({Character=owner},'stack',vacuum,10,{}))
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
            assert(view.page==10000 and view.group==0 and #view.search==64)
            local s=G.snapshot(G.context(vacuum),view)
            assert(#s.rows<=40 and s.pack==pack.ID)
        """)

    def test_snapshot_contains_forty_icons_and_two_pages_for_fifty_one_groups(self):
        self.lua.execute("""
            local items={}
            for i=1,51 do items[i]={ID=i,Name='item'..i,kind='kind'..i,Condition=100,MaxCondition=100,Quality=0} end
            G.contents=function() return items end
            G.records=function(list) local rows={};for _,i in ipairs(list) do rows[#rows+1]={item=i,id=i.ID,kind=i.kind} end;return rows end
            local s=G.snapshot(G.context(vacuum),{})
            assert(#s.rows==40 and s.pages==2 and s.rows[1].kind)
            local next=G.snapshot(G.context(vacuum),{page=1})
            assert(#next.rows==11)
        """)

    def test_category_search_and_filter_catalog_are_separate_from_contents(self):
        self.lua.execute("""
            env.ItemPrefab={Prefabs={}};require('SalvageVacuum.filters').install(G,env)
            local item={ID=20,Name='Iron',Prefab={Category='Material'},kind='iron',Condition=100,MaxCondition=100,Quality=0}
            G.contents=function() return {item} end
            G.records=function() return {{item=item,id=20,kind='iron'}} end
            assert(#G.snapshot(G.context(vacuum),{category='medical'}).rows==0)
            assert(#G.snapshot(G.context(vacuum),{category='material',search='iron'}).rows==1)
            local s=G.snapshot(G.context(vacuum),{filters=true})
            assert(#s.rows==0 and s.count==1 and s.filters)
            assert(G.normalizeView({category='forged'}).category=='all')
        """)

    def test_filter_request_uses_authorized_pack_and_never_accepts_unknown_action(self):
        self.lua.execute("""
            G.setExcluded=function(ctx,kind,excluded)
                assert(ctx.pack==pack and kind=='iron' and excluded==true);calls=calls+1;return true
            end
            assert(G.handleRequest({Character=owner},'filter',vacuum,1,{kind='iron'}))
            assert(calls==1)
            G.now=2;assert(not G.handleRequest({Character={}},'filter',vacuum,1,{kind='iron'}))
            assert(not G.handleRequest({Character=owner},'hack',vacuum,0,{}))
        """)
