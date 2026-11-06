from test_vacuum_adapter import VacuumAdapterTests


class VacuumNetworkTests(VacuumAdapterTests):
    def test_batch_insert_and_floor_mode_cross_the_actual_wire_format(self):
        self.lua.execute('''
            local receive={};env.CLIENT=true;env.Character={Controlled=owner}
            local function reader(values)
                local i=0;local function read() i=i+1;return values[i] end
                return {ReadByte=read,ReadUInt16=read,ReadUInt32=read,ReadSingle=read,ReadBoolean=read,ReadString=read}
            end
            env.Entity={FindEntityByID=function(id) if id==vacuum.ID then return vacuum end end}
            env.Networking.Receive=function(name,fn) receive[name]=fn end
            env.Networking.Start=function(name)
                local values={};local function write(v) values[#values+1]=v end
                return {name=name,values=values,WriteByte=write,WriteUInt16=write,WriteUInt32=write,
                    WriteSingle=write,WriteBoolean=write,WriteString=write}
            end
            env.Networking.Send=function(m)
                local old=G.authoritative;G.authoritative=true
                receive[m.name](reader(m.values),{Character=owner});G.authoritative=old
            end
            local withdrawn,inserted,loose,snapshot
            G.withdrawBatch=function(ctx,ids,groups) withdrawn={ids=ids,groups=groups};return true end
            G.insertBatch=function(ctx,ids) inserted=ids;return true end
            G.setLooseOnly=function(ctx,value) loose=value;return true end
            G.looseOnly=function() return loose==true end
            G.onSnapshot=function(value) snapshot=value end
            require('SalvageVacuum.network').install(G,env);G.authoritative=false
            G.request('batch',vacuum,0,{targets={11,11,12},group=1})
            assert(withdrawn and #withdrawn.ids==2 and withdrawn.ids[2]==12 and not withdrawn.groups)
            G.now=G.now+1;G.request('insert',vacuum,0,{targets={21,22}})
            assert(inserted and #inserted==2 and inserted[1]==21 and inserted[2]==22)
            G.now=G.now+1;G.request('loose',vacuum,1,{})
            assert(loose and snapshot.looseOnly==true)
        ''')

    def test_batch_request_validates_access_and_deduplicates_bounded_selection(self):
        self.lua.execute('''
            local received
            G.withdrawBatch=function(ctx,ids,groups) received={ctx=ctx,ids=ids,groups=groups};return true end
            assert(not G.handleRequest({Character={}},'batch',vacuum,0,{targets={3,4}}))
            assert(not received)
            assert(G.handleRequest({Character=owner},'batch',vacuum,0,{targets={3,3,4},group=0}))
            assert(#received.ids==2 and received.ids[1]==3 and received.ids[2]==4 and received.groups)
            G.now=G.now+1;local ids={};for i=1,101 do ids[i]=i end
            received=nil
            assert(not G.handleRequest({Character=owner},'batch',vacuum,0,{targets=ids}))
            assert(not received,'oversized mutation was partially accepted')
        ''')

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

    def test_salvage_stop_reason_and_counts_survive_server_client_wire_roundtrip(self):
        self.lua.execute("""
            local receive={};env.CLIENT=true
            local function reader(values)
                local index=0;local function nextValue() index=index+1;return values[index] end
                return {ReadByte=nextValue,ReadUInt16=nextValue,ReadUInt32=nextValue,
                    ReadSingle=nextValue,ReadBoolean=nextValue,ReadString=nextValue}
            end
            env.Entity={FindEntityByID=function(id) if id==vacuum.ID then return vacuum end end}
            env.Networking.Receive=function(name,fn) receive[name]=fn end
            env.Networking.Start=function(name)
                local values={};local function write(v) values[#values+1]=v end
                return {name=name,values=values,WriteByte=write,WriteUInt16=write,WriteUInt32=write,
                    WriteSingle=write,WriteBoolean=write,WriteString=write}
            end
            env.Networking.Send=function(message) receive[message.name](reader(message.values)) end
            G.salvageProgress=function() return {phase='power',total=598,processed=9,done=7,skipped=2} end
            local result;G.onSnapshot=function(s) result=s end
            require('SalvageVacuum.network').install(G,env)
            local protocol=require('SalvageVacuum.config').protocol
            receive[protocol..'.request'](reader({1,vacuum.ID,0,0,0,'',false,'all','',0}),{Character=owner})
            assert(result and result.salvage and result.salvage.phase=='power')
            assert(result.salvage.total==598 and result.salvage.processed==9 and result.salvage.done==7 and result.salvage.skipped==2)
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
