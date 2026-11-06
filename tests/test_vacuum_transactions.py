from lua_support import LuaCase


class VacuumTransactionTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            local C=require('SalvageVacuum.config')
            pack={};vacuum={};battery={Condition=50,MaxCondition=100};owner={}
            ctx={valid=true,pack=pack,vacuum=vacuum,owner=owner}
            source={kind='source',Condition=100,MaxCondition=100,AllowDeconstruct=true,parent=pack,
                Prefab={DeconstructItems={{ItemIdentifier='copper',Amount=2,MinCondition=0,MaxCondition=1,
                    OutConditionMin=1,OutConditionMax=1,RequiredOtherItem={},Commonness=1,
                    IsValidDeconstructor=function() return true end}}}}
            loot={source};queue={};removed={};children={}
            G={alive=true,pending={},jobs={},reserved={}}
            G.context=function() return ctx end
            G.is=function(item,id) return item==vacuum and id==C.vacuum end
            G.charge=function() return battery.Condition end
            G.source=function() return battery end
            G.spend=function(_,cost) if battery.Condition<cost then return false end;battery.Condition=battery.Condition-cost;return true end
            G.has=function(p,item) return item.parent==p end
            G.contents=function() return loot end
            G.children=function(item) return item==source and children or {} end
            G.records=function(items) local out={};for _,i in ipairs(items) do out[#out+1]={kind=i.kind} end;return out end
            G.ensureSpace=function() return true end
            G.pages=function() return {} end
            G.freeSlots=function() return {{inv={}},{inv={}},{inv={}}} end
            G.insert=function(p,item) item.parent=p;loot[#loot+1]=item;return true end
            E={ItemPrefab={Prefabs={copper={Health=100}}},Entity={Spawner={
                AddItemToSpawnQueue=function(prefab,inv,condition,quality,callback)
                    queue[#queue+1]=function() local p={parent=pack,Condition=condition};callback(p);return p end
                end,
                AddItemToRemoveQueue=function(item) removed[item]=true end}}}
            require('SalvageVacuum.salvage').install(G,E)
            job={ctx=ctx,items={source},index=1,done=0,skipped=0};G.jobs[pack]=job
        """)

    def test_original_survives_until_all_products_exist(self):
        self.lua.execute("""
            G.processSalvage(job)
            assert(#queue==2 and not removed[source] and G.pending[pack])
            queue[1]();assert(not removed[source])
            queue[2]();assert(removed[source] and job.done==1 and not G.pending[pack])
        """)

    def test_salvage_effect_only_plays_after_successful_commit(self):
        self.lua.execute("""
            effects=0;G.salvageEffect=function(device) assert(device==vacuum);effects=effects+1 end
            G.processSalvage(job);assert(effects==0);queue[1]();queue[2]();assert(effects==1)
        """)

    def test_unequip_or_reload_rolls_back_products_and_refunds_battery(self):
        self.lua.execute("""
            G.processSalvage(job);local p1=queue[1]()
            G.alive=false
            local p2=queue[2]()
            assert(not removed[source] and removed[p1] and removed[p2])
            assert(battery.Condition==50 and not G.pending[pack] and not G.reserved[source])
        """)

    def test_unbreakable_nested_content_is_evacuated_before_casing_removal(self):
        self.lua.execute("""
            local child={kind='unbreakable',parent=source};children={child}
            G.processSalvage(job)
            assert(child.parent==pack and not removed[child] and not removed[source])
            queue[1]();queue[2]()
            assert(removed[source] and not removed[child] and child.parent==pack)
        """)

    def test_no_space_preserves_original_and_does_not_charge(self):
        self.lua.execute("""
            G.ensureSpace=function() return false end
            G.processSalvage(job)
            assert(#queue==0 and not removed[source] and battery.Condition==50)
        """)

    def test_skipped_recipes_advance_in_bounded_batches_with_visible_progress(self):
        self.lua.execute("""
            job.items={}
            for i=1,100 do job.items[i]={parent=pack,AllowDeconstruct=false,MaxCondition=100} end
            G.processSalvage(job)
            assert(job.index>2 and job.index<=33,'unsupported items still take one whole interval each')
            local p=G.salvageProgress(pack)
            assert(p.total==100 and p.processed==job.skipped and p.done==0 and p.phase=='working')
            for i=1,5 do G.processSalvage(job) end
            p=G.salvageProgress(pack)
            assert(not G.jobs[pack] and p.processed==100 and p.skipped==100 and p.phase=='complete')
            assert(#queue==0 and battery.Condition==50)
        """)

    def test_low_battery_retains_reason_and_completed_counts(self):
        self.lua.execute("""
            job.done=3;job.skipped=2;battery.Condition=0
            G.processSalvage(job)
            local p=G.salvageProgress(pack)
            assert(not G.jobs[pack] and p.phase=='power' and p.done==3 and p.skipped==2)
        """)

    def test_last_success_is_complete_even_when_it_spends_remaining_energy(self):
        self.lua.execute("""
            battery.Condition=require('SalvageVacuum.config').salvageCost
            G.processSalvage(job);queue[1]();queue[2]();G.processSalvage(job)
            local p=G.salvageProgress(pack)
            assert(p.phase=='complete' and p.done==1 and p.processed==p.total)
        """)

    def test_cancelled_old_callbacks_cannot_restore_cleared_results(self):
        self.lua.execute("""
            G.processSalvage(job)
            ctx.valid=false;G.processSalvage(job)
            assert(G.salvageProgress(pack).phase=='interrupted')
            G.salvageResults={};G.pending[pack].cancelled=true
            queue[1]();queue[2]()
            assert(G.salvageProgress(pack)==nil,'old callback restored reset status')
            assert(not removed[source] and battery.Condition==50)
        """)
