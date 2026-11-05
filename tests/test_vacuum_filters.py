from lua_support import LuaCase


class VacuumFilterTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            function prefab(id,name,category,slots)
                local element={Name='Holdable',GetAttributeString=function(_,default) return slots or default end,
                    GetAttributeBool=function(_,default) return default end}
                return {Identifier=id,Name=name,Category=category,ConfigElement={Elements=function() return {element} end}}
            end
            iron=prefab('iron','Iron','Material');suit=prefab('suit','Suit','Diving, Equipment')
            gun=prefab('gun','Gun','Weapon');door=prefab('door','Door','Structure','None')
            pack={Tags='mobilecontainer,custom.tag'}
            E={ItemPrefab={Prefabs={iron,suit,gun,door}}}
            G={jobs={},pending={},children=function(i) return i.children or {} end,
                id=function(i) return tostring(i.Prefab.Identifier) end}
            require('SalvageVacuum.filters').install(G,E)
            ctx={valid=true,pack=pack}
        """)

    def test_exclusions_survive_reload_without_erasing_other_tags(self):
        self.lua.execute("""
            assert(G.setExcluded(ctx,'iron',true));assert(G.filter(pack).iron)
            assert(pack.Tags:find('custom.tag',1,true))
            G.clearFilters();assert(G.filter(pack).iron)
            assert(G.setExcluded(ctx,'iron',false));assert(not G.filter(pack).iron)
            assert(pack.Tags=='mobilecontainer,custom.tag')
        """)

    def test_catalog_combines_search_category_and_blocked_defaults(self):
        self.lua.execute("""
            local rows=G.filterCatalog({category='diving',search='sui'})
            assert(#rows==1 and rows[1].kind=='suit')
            assert(#G.filterCatalog({category='weapon',search='sui'})==0)
            local all=G.filterCatalog({});local found=false
            for _,r in ipairs(all) do if r.kind=='door' then assert(r.blocked);found=true end end
            assert(found and not G.setExcluded(ctx,'door',false))
            assert(not G.setExcluded(ctx,'unknown',true))
        """)

    def test_category_flags_match_multiple_categories_and_unknowns_fall_back(self):
        self.lua.execute("""
            assert(G.categoryMatches(suit,'equipment') and G.categoryMatches(suit,'diving'))
            assert(not G.categoryMatches(suit,'medical'))
            assert(G.categoryMatches(prefab('x','X','Structure'),'misc'))
        """)

    def test_native_luacs_numeric_category_flags(self):
        self.lua.execute("""
            assert(G.categoryMatches(prefab('iron','Iron',1024),'material'))
            local mixed=prefab('suit','Suit',32+64)
            assert(G.categoryMatches(mixed,'diving') and G.categoryMatches(mixed,'equipment'))
            assert(not G.categoryMatches(mixed,'medical') and not G.categoryMatches(mixed,'misc'))
            assert(G.categoryMatches(prefab('x','X',1),'misc'))
        """)

    def test_filtered_descendant_blocks_whole_crate_and_cycle_is_rejected(self):
        self.lua.execute("""
            assert(G.setExcluded(ctx,'iron',true))
            local item={Prefab=suit,children={{Prefab=iron}}}
            assert(not G.acceptsLoot(pack,item));item.children={};assert(G.acceptsLoot(pack,item))
            item.children={item};assert(not G.acceptsLoot(pack,item))
        """)

    def test_busy_invalid_context_cannot_change_filters(self):
        self.lua.execute("""
            G.jobs[pack]={};assert(not G.setExcluded(ctx,'iron',true));G.jobs[pack]=nil
            ctx.valid=false;assert(not G.setExcluded(ctx,'iron',true))
            assert(not G.filter(pack).iron)
        """)

    def test_server_publishes_saved_tags_to_other_clients(self):
        self.lua.execute("""
            local events=0;E.SERVER=true;pack.SerializableProperties={Tags={}}
            E.Identifier=function(s) return s end
            E.Item={ChangePropertyEventData=function(property,item) assert(property==pack.SerializableProperties.Tags and item==pack);return 'tags' end}
            E.Networking={CreateEntityEvent=function(item,data) assert(item==pack and data=='tags');events=events+1 end}
            assert(G.setExcluded(ctx,'iron',true) and events==1)
        """)
