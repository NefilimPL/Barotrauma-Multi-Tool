from lua_support import LuaCase


class VacuumRoundResetTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            item={kind='aegisvacuum',ID=1}
            env={Item={ItemList={item}},Hook={Add=function() end}}
            G={now=0,states={},jobs={},selected={},pending={},authoritative=true,
                patch=function() end,
                id=function(i) return i.kind end,
                is=function(i,id) return i and i.kind==id end,
                context=function() return {valid=false} end}
            require('SalvageVacuum.runtime').install(G,env)
        """)

    def test_round_reset_during_scan_interval_does_not_reuse_missing_state(self):
        self.lua.execute("""
            G.update(.01)
            G.states={}
            for i=1,20 do G.update(.02) end
        """)

    def test_runtime_reset_discards_old_world_candidates_immediately(self):
        self.lua.execute("""
            G.update(.01);G.states={};env.Item.ItemList={}
            G.resetRuntime();G.update(.02)
            assert(next(G.states)==nil)
        """)

    def test_stored_items_share_root_classification_and_spare_nozzle_stays_idle(self):
        self.lua.execute("""
            local pack={kind='aegisvacuumpack'}
            env.Item.ItemList={};probes=0
            G.is=function(i,id) probes=probes+1;return i and i.kind==id end
            for i=1,10000 do env.Item.ItemList[i]={kind='iron',RootContainer=pack,ID=i} end
            local spare={kind='aegisvacuum',RootContainer=pack,ID=10001}
            env.Item.ItemList[10001]=spare
            G.update(.01)
            assert(probes<50,'reclassified the same backpack for every stored item: '..probes)
            assert(G.states[spare]==nil,'stored spare nozzle was treated as active equipment')
        """)
