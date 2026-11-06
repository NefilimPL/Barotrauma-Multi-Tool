from test_headset_adapter import HeadsetAdapterTests
from test_review_regressions import ReviewRegressionTests
import unittest


def load_tests(loader, tests, pattern):
    return unittest.TestSuite([
        HeadsetSupplyPerformanceTests('test_warm_battery_search_does_not_rescan_unrelated_world_items'),
        HeadsetSupplyPerformanceTests('test_existing_items_gaining_source_tags_are_found_across_util_reload'),
        HeadsetSupplyPerformanceTests('test_large_source_spawn_batch_keeps_search_linear'),
        HeadsetSupplyPerformanceTests('test_round_end_does_not_reintroduce_pending_old_sources'),
        CombatSupplyPerformanceTests('test_failed_resupply_retries_only_indexed_sources'),
    ])


class HeadsetSupplyPerformanceTests(HeadsetAdapterTests):
    def test_large_source_spawn_batch_keeps_search_linear(self):
        self.lua.execute("""
            local AI=require('AegisHeadset.ai')
            E.Item={ItemList={}}
            assert(AI.candidate(E,char,item,20)==nil)
            local comparisons=0
            local mt={__eq=function() comparisons=comparisons+1;return false end}
            for i=1,1000 do
                local cell=setmetatable({Condition=0,MaxCondition=100,
                    HasTag=function(t) return t=='mobilebattery' end},mt)
                E.Util.created(cell)
                E.Util.tagsChanged('set_Tags',cell,{value='mobilebattery'})
            end
            assert(AI.candidate(E,char,item,20)==nil)
            assert(comparisons<10000,'source batch made '..comparisons..' equality comparisons')
        """)

    def test_round_end_does_not_reintroduce_pending_old_sources(self):
        self.lua.execute("""
            local AI=require('AegisHeadset.ai');local powered=false
            E.LuaUserData={IsTargetType=function() return false end}
            local cell={Condition=100,MaxCondition=100,WorldPosition={X=0,Y=0},
                HasAccess=function() return true end,HasTag=function() return powered end}
            E.Item={ItemList={cell}};assert(AI.candidate(E,char,item,20)==nil)
            powered=true;E.Util.tagsChanged('AddTag',cell,{tag='mobilebattery'})
            E.Util.roundEnd()
            assert(AI.candidate(E,char,item,20)==nil,'pending old source survived round end')
        """)

    def test_existing_items_gaining_source_tags_are_found_across_util_reload(self):
        self.lua.execute("""
            local AI=require('AegisHeadset.ai')
            E.LuaUserData={IsTargetType=function() return false end}
            local methods={'AddTag','ReplaceTag','set_Tags'}
            for _,method in ipairs(methods) do
                local tags={}
                local cell={Condition=100,MaxCondition=100,WorldPosition={X=0,Y=0},
                    HasAccess=function() return true end,HasTag=function(tag) return tags[tag] end}
                E.Item={ItemList={cell}};E.Util.created(cell)
                assert(AI.candidate(E,char,item,20)==nil)
                -- Combat autorun reloads the shared module; headset keeps its older reference.
                package.loaded['CombatTool.util']=nil
                require('CombatTool.util').powerSources(E)
                tags.mobilebattery=true
                E.Util.tagsChanged(method,cell,{tag='mobilebattery',newTag='mobilebattery',value='misc, mobilebattery '})
                assert(AI.candidate(E,char,item,20)==cell,method..' failed to update source membership')
                tags.mobilebattery=nil
                assert(AI.candidate(E,char,item,20)==nil,'removed source tag remained usable')
                cell.Removed=true
            end
        """)

    def test_warm_battery_search_does_not_rescan_unrelated_world_items(self):
        self.lua.execute("""
            local AI=require('AegisHeadset.ai')
            local world={};for i=1,10000 do world[i]={HasTag=function() return false end} end
            E.LuaUserData={IsTargetType=function() return false end}
            local reads=0
            E.Item=setmetatable({},{__index=function(_,key)
                if key=='ItemList' then reads=reads+1;return world end
            end})
            assert(AI.candidate(E,char,item,20)==nil)
            reads=0
            for i=1,20 do assert(AI.candidate(E,char,item,20)==nil) end
            assert(reads==0,'headset battery search rescanned world '..reads..' times')
            local cell={Condition=100,MaxCondition=100,WorldPosition={X=0,Y=0},
                HasAccess=function() return true end,HasTag=function(t) return t=='mobilebattery' end}
            E.Util.created(cell)
            assert(AI.candidate(E,char,item,20)==cell,'new battery absent from supply index')
            cell.Removed=true;assert(AI.candidate(E,char,item,20)==nil)
            cell.Removed=false;E.Util.roundEnd()
            assert(AI.candidate(E,char,item,20)==nil,'old level supply survived round end')
            E.Util.created(cell);assert(AI.candidate(E,char,item,20)==cell)
        """)


class CombatSupplyPerformanceTests(ReviewRegressionTests):
    def test_failed_resupply_retries_only_indexed_sources(self):
        self.lua.execute("""
            local world={};for i=1,10000 do world[i]={HasTag=function() return false end} end
            local reads=0
            env.Item=setmetatable({},{__index=function(_,key)
                if key=='ItemList' then reads=reads+1;return world end
            end})
            assert(not A.resupply(bot,gun,0,currentParent));reads=0
            for i=1,20 do
                G.now=i*2;assert(not A.resupply(bot,gun,0,currentParent))
            end
            assert(reads==0,'combat battery search rescanned world '..reads..' times')
            env.Util.created(source);G.now=100
            assert(A.resupply(bot,gun,0,currentParent),'new indexed battery was not found')
        """)
