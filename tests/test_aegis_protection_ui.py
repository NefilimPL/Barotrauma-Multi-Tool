import test_vacuum_client
import test_vacuum_filters
import test_vacuum_network


class ProtectionListClientTests(test_vacuum_client.VacuumClientTests):
    mod_directory = 'System-Aegis-No-Headsets'

    def catalog(self, blocked=False):
        self.lua.execute("""
            G.openPanel(pack);button('aegisvacuum.filters').OnClicked()
            row={id=0,kind='iron',name='Iron',count=1,condition=0,quality=0,group=0,blocked=...}
            snapshot={vacuum=pack.ID,pack=pack.ID,charge=0,groups=0,count=0,busy=false,
                page=0,pages=1,packs={pack.ID},rows={row},group=0,filters=true,category='all',search=''}
            G.onSnapshot(snapshot)
        """, blocked)

    def test_filter_controls_protect_and_allow_independently_on_blocked_catalog_rows(self):
        self.catalog(True)
        self.lua.execute("""
            local r=G.ruleRows[1]
            assert(r.name.Text=='Iron' and r.protect.Enabled and not r.collect.Enabled and r.allow.Enabled)
            r.protect.OnClicked()
            assert(requests[#requests].action=='protect' and requests[#requests].kind=='iron' and requests[#requests].target==1)
            row.protected=true;G.onSnapshot(snapshot)
            assert(r.protect.Selected and r.protect.Text:find('aegisvacuum.yes',1,true))
            assert(not row.excluded and not row.allowed)
            r.allow.OnClicked();assert(requests[#requests].action=='allow')
        """)

    def test_category_and_filter_mode_request_the_selected_catalog(self):
        self.lua.execute("""
            G.openPanel(pack)
            local d;for _,w in ipairs(widgets) do if w.kind=='dropdown' then d=w end end
            d.OnSelected(nil,'medical');button('aegisvacuum.filters').OnClicked()
            assert(requests[#requests].filters and requests[#requests].category=='medical')
            G.onSnapshot({vacuum=pack.ID,pack=pack.ID,charge=0,groups=0,count=0,busy=false,page=0,pages=1,
                packs={pack.ID},rows={{id=0,kind='iron',name='Iron',count=1,condition=0,quality=0,group=0}},
                group=0,filters=true,category='medical',search=''})
            G.ruleRows[1].collect.OnClicked()
            assert(requests[#requests].action=='filter' and requests[#requests].target==1)
        """)

    def test_selected_storage_type_has_direct_protection_action(self):
        self.lua.execute("""
            G.openPanel(pack)
            G.onSnapshot({vacuum=pack.ID,pack=pack.ID,charge=0,groups=1,count=20,busy=false,page=0,pages=1,
                packs={pack.ID},rows={{id=11,kind='iron',name='Iron',count=20,condition=100,quality=0,group=1}}})
            for _,w in ipairs(widgets) do if w.kind=='button' and (w.ToolTip or ''):find('Iron',1,true) then w.OnClicked();break end end
            assert(G.protectTypeButton.Enabled);G.protectTypeButton.OnClicked()
            local r=requests[#requests];assert(r.action=='protect' and r.kind=='iron' and r.target==1)
        """)

    def test_busy_or_hidden_rules_cannot_modify_types(self):
        self.catalog()
        self.lua.execute("""
            snapshot.busy=true;G.onSnapshot(snapshot);local n=#requests
            G.ruleRows[1].protect.OnClicked();assert(#requests==n)
            snapshot.busy=false;G.onSnapshot(snapshot)
            button('aegisvacuum.contents').OnClicked();n=#requests
            G.ruleRows[1].protect.OnClicked();assert(#requests==n)
        """)

    def test_reused_row_buttons_act_on_current_named_type(self):
        self.catalog()
        self.lua.execute("""
            local b=G.ruleRows[1].protect
            snapshot.rows={{id=0,kind='copper',name='Copper',count=1,condition=0,quality=0,group=0}}
            G.onSnapshot(snapshot);b.OnClicked()
            assert(G.ruleRows[1].name.Text=='Copper' and requests[#requests].kind=='copper')
        """)


class ProtectionRulesPersistenceTests(test_vacuum_filters.VacuumFilterTests):
    mod_directory = 'System-Aegis-No-Headsets'

    def test_saved_type_protection_covers_future_instances_without_blocking_collection(self):
        self.lua.execute("""
            assert(G.setProtected(ctx,'iron',true));G.clearFilters()
            local old={Prefab=iron};local future={Prefab=iron}
            assert(G.filterRules(pack).protected[G.id(old)] and G.filterRules(pack).protected[G.id(future)])
            assert(G.acceptsLoot(pack,old) and G.acceptsLoot(pack,future))
            assert(not G.filterRules(pack).excluded.iron and not G.filterRules(pack).allowed.iron)
        """)


class ProtectionCatalogNetworkTests(test_vacuum_network.VacuumNetworkTests):
    mod_directory = 'System-Aegis-No-Headsets'

    def test_named_rule_rows_are_paginated_without_losing_catalog_entries(self):
        self.lua.execute("""
            G.filterCatalog=function()
                local rows={};for i=1,13 do rows[i]={kind='type'..i,name='Type '..i} end;return rows
            end
            local ctx=G.context(vacuum,owner);local all={}
            for page=0,2 do
                local s=G.snapshot(ctx,{filters=true,page=page})
                assert(s.pages==3 and #s.rows<=6)
                for _,r in ipairs(s.rows) do assert(not all[r.kind]);all[r.kind]=true end
            end
            for i=1,13 do assert(all['type'..i]) end
        """)
