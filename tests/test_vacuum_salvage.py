from lua_support import LuaCase


class VacuumSalvageTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            R=require('SalvageVacuum.recipes')
            iron={Identifier='iron',Health=100};copper={Identifier='copper',Health=100}
            E={ItemPrefab={Prefabs={iron=iron,copper=copper}}}
            function recipe(id,amount,min,max)
                return {ItemIdentifier=id,Amount=amount or 1,MinCondition=min or -.1,MaxCondition=max or 1,
                    OutConditionMin=1,OutConditionMax=1,CopyCondition=false,RequiredOtherItem={},
                    Commonness=1,IsValidDeconstructor=function() return true end}
            end
            item={Condition=50,MaxCondition=100,AllowDeconstruct=true,
                Prefab={DeconstructItems={},RandomDeconstructionOutput=false}}
        """)

    def test_no_recipe_and_forbidden_deconstruction_leave_item_intact(self):
        self.lua.execute("""
            assert(R.plan(E,item,{})==nil)
            item.Prefab.DeconstructItems={recipe('iron')};item.AllowDeconstruct=false
            assert(R.plan(E,item,{})==nil)
        """)

    def test_amount_condition_and_copy_condition_match_recipe(self):
        self.lua.execute("""
            local r=recipe('iron',2);r.CopyCondition=true;r.OutConditionMax=.8
            item.Prefab.DeconstructItems={r,recipe('copper',1,.8,1)}
            local p=R.plan(E,item,{})
            assert(#p==2 and p[1].kind=='iron' and p[1].condition==40)
            assert(item.Condition==50)
        """)

    def test_missing_prefab_or_required_other_item_never_destroys_source(self):
        self.lua.execute("""
            item.Prefab.DeconstructItems={recipe('missing')};assert(R.plan(E,item,{})==nil)
            local r=recipe('iron');r.RequiredOtherItem={'gene'}
            item.Prefab.DeconstructItems={r};assert(R.plan(E,item,{})==nil)
        """)

    def test_random_output_is_weighted_without_replacement(self):
        self.lua.execute("""
            item.Prefab.DeconstructItems={recipe('iron',2),recipe('copper',1)}
            item.Prefab.RandomDeconstructionOutput=true;item.Prefab.RandomDeconstructionOutputAmount=1
            local p=R.plan(E,item,{},function() return .99 end)
            assert(#p==1 and p[1].kind=='copper')
        """)

    def test_no_output_for_current_condition_does_not_remove_item(self):
        self.lua.execute("item.Prefab.DeconstructItems={recipe('iron',1,.8,1)};assert(R.plan(E,item,{})==nil)")
