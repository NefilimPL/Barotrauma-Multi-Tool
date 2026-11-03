from lua_support import LuaCase


class VacuumCoreTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("V=require('SalvageVacuum.core')")

    def test_groups_split_at_100_and_keep_actual_instances(self):
        self.lua.execute("""
            local items={}
            for i=1,101 do items[i]={id=i,kind='suit',condition=i,contents={i}} end
            local groups=V.groups(items)
            assert(#groups==2 and #groups[1].items==100 and #groups[2].items==1)
            assert(groups[1].items[1]==items[1] and groups[2].items[1]==items[101])
            assert(items[42].condition==42 and items[42].contents[1]==42)
        """)

    def test_capacity_counts_groups_instead_of_only_number_of_items(self):
        self.lua.execute("""
            local items={}
            for i=1,100 do items[i]={kind='type'..i} end
            assert(not V.canAccept(items,{kind='newtype'}))
            assert(V.canAccept(items,{kind='type1'}))
            for i=2,100 do items[#items+1]={kind='type1'} end
            assert(not V.canAccept(items,{kind='type1'}))
        """)

    def test_batch_capacity_reserves_all_products_together(self):
        self.lua.execute("""
            local items={}
            for i=1,99 do items[i]={kind='type'..i} end
            assert(V.canFit(items,{{kind='iron'},{kind='iron'}}))
            assert(not V.canFit(items,{{kind='iron'},{kind='copper'}}))
        """)

    def test_snapshot_is_postorder_and_cycle_safe(self):
        self.lua.execute("""
            local a={id=1};local b={id=2};local c={id=3}
            a.children={b};b.children={c};c.children={a}
            local out=V.snapshot({a,b},function(i) return i.children or {} end)
            assert(#out==3 and out[1]==c and out[2]==b and out[3]==a)
        """)

    def test_power_requires_full_payment_and_never_increases_charge(self):
        self.lua.execute("""
            local charge,paid=V.debit(1,2);assert(charge==1 and not paid)
            charge,paid=V.debit(5,2);assert(charge==3 and paid)
            charge,paid=V.debit(5,-2);assert(charge==5 and not paid)
            charge,paid=V.debit(5,0/0);assert(charge==5 and not paid)
        """)

    def test_cone_rejects_behind_far_and_nan_targets(self):
        self.lua.execute("""
            local o={x=0,y=0};local d={x=1,y=0}
            assert(V.inCone(o,d,{x=250,y=0}))
            assert(not V.inCone(o,d,{x=-20,y=0}))
            assert(not V.inCone(o,d,{x=351,y=0}))
            assert(not V.inCone(o,d,{x=40,y=200}))
            assert(not V.inCone(o,d,{x=0/0,y=0}))
        """)

    def test_recipe_policy_skips_missing_and_unsupported_without_fallback(self):
        self.lua.execute("""
            assert(not V.supportedRecipe({outputs={}}))
            assert(not V.supportedRecipe({outputs={{id='iron'}},requiresOther=true}))
            assert(V.supportedRecipe({outputs={{id='iron'}}}))
        """)
