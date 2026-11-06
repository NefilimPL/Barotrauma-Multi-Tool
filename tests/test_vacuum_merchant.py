from lua_support import LuaCase


class VacuumMerchantTests(LuaCase):
    def test_server_rejects_busy_reserved_and_foreign_backpack_sales_before_native_removal(self):
        self.lua.execute('''
            E.CLIENT=false;E.SERVER=true
            local owner={};local client={Character=owner}
            pack.ParentInventory={Owner=owner}
            item.ParentInventory=page.OwnInventory;page.OwnInventory.Owner=page
            page.ParentInventory=pack.OwnInventory;pack.OwnInventory.Owner=pack
            E.LuaUserData.IsTargetType=function(v,t)
                if t=='Barotrauma.Character' then return v==owner or v==foreign end
                return v==item or v==page or v==pack
            end
            E.Entity={FindEntityByID=function(id) if id==9 then return item elseif id==8 then return page end end}
            E.LuaUserData.CreateEnumTable=function() return {Character=1,Submarine=2} end
            E.LuaUserData.CreateStatic=function() return function()
                local list={};list.Add=function(value) list[#list+1]=value end;return list
            end end
            local sales={{ID=9,Origin=1},{ID=77,Origin=1},{ID=8,Origin=1}}
            require('SalvageVacuum.merchant').install(G,E)
            local function filtered()
                local p={itemsToSell=sales,client=client};hooks['merchant-server-sales']({},p);return p.itemsToSell
            end
            local open=filtered();assert(#open==2 and open[1].ID==9 and open[2].ID==77)
            G.pending[pack]={};local blocked=filtered();assert(#blocked==1 and blocked[1].ID==77);G.pending[pack]=nil
            G.jobs[pack]={};assert(#filtered()==1);G.jobs[pack]=nil
            G.reserved[item]=true;assert(#filtered()==1);G.reserved[item]=nil
            foreign={};pack.ParentInventory.Owner=foreign;assert(#filtered()==1)
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            hooks={}
            E={CLIENT=true,LuaUserData={RegisterType=function() return {} end,
                MakeMethodAccessible=function() end}}
            pack={kind='aegisvacuumpack'};page={kind='aegisvacuumpage',Container=pack}
            item={kind='iron',Container=page,Prefab={CanBeSold=true,AllowSellingWhenBroken=false},
                ConditionPercentage=100,ContainedItems={}}
            function container(i,visible,accessible)
                i.OwnInventory={Container={DrawInventory=visible,IsAccessible=function() return accessible end}}
            end
            container(pack,false,true);container(page,false,true)
            G={pending={},jobs={},reserved={},is=function(i,k) return i and i.kind==k end,
                patch=function(n,c,m,fn) hooks[n]=fn end}
            manager={UndeterminedSoldEntities={TryGetValue=function() return false,0 end}}
            manager.IsItemSellable=function(it,confirmed)
                if it.Removed or not it.Prefab.CanBeSold or it.SpawnedInCurrentOutpost or
                    (not it.Prefab.AllowSellingWhenBroken and it.ConditionPercentage<90) then return false end
                for _,sold in ipairs(confirmed) do if sold.Item==it then return false end end
                local node=it.Container
                while node do
                    local c=node.OwnInventory and node.OwnInventory.Container
                    if c and (not c.DrawInventory or not c.IsAccessible()) then return false end
                    node=node.Container
                end
                return true
            end
            require('SalvageVacuum.merchant').install(G,E)
        ''')

    def test_hidden_aegis_pages_are_sellable_but_native_exclusions_remain(self):
        self.lua.execute('''
            assert(G.sellableStored(manager,item,{}))
            item.SpawnedInCurrentOutpost=true;assert(not G.sellableStored(manager,item,{}));item.SpawnedInCurrentOutpost=false
            item.ConditionPercentage=89;assert(not G.sellableStored(manager,item,{}));item.ConditionPercentage=100
            assert(not G.sellableStored(manager,item,{{Item=item}}))
            G.pending[pack]={};assert(not G.sellableStored(manager,item,{}));G.pending[pack]=nil
            G.reserved[item]=true;assert(not G.sellableStored(manager,item,{}));G.reserved[item]=nil
            item.Prefab.CanBeSold=false;assert(not G.sellableStored(manager,item,{}))
        ''')

    def test_other_hidden_or_inaccessible_nested_containers_stay_blocked(self):
        self.lua.execute('''
            local box={kind='box',Container=page};container(box,false,true);item.Container=box
            assert(not G.sellableStored(manager,item,{}))
            box.OwnInventory.Container.DrawInventory=true;assert(G.sellableStored(manager,item,{}))
            box.OwnInventory.Container.IsAccessible=function() return false end
            assert(not G.sellableStored(manager,item,{}))
            item.Container=nil;assert(G.sellableStored(manager,item,{})==nil,'ordinary shop rules must remain native')
        ''')

    def test_pack_and_internal_pages_never_become_sellable_through_override(self):
        self.lua.execute('''
            assert(G.sellableStored(manager,page,{})==false)
            assert(G.sellableStored(manager,pack,{})==nil)
        ''')

    def test_native_failure_always_restores_hidden_inventory_flags(self):
        self.lua.execute('''
            manager.IsItemSellable=function() error('native failure') end
            local ok=pcall(G.sellableStored,manager,item,{})
            assert(not ok and not pack.OwnInventory.Container.DrawInventory and not page.OwnInventory.Container.DrawInventory)
        ''')

    def test_native_confirmed_sales_enumerable_preserves_sold_item_exclusion(self):
        self.lua.execute('''
            local done=false
            local sold=function() if not done then done=true;return {Item=item} end end
            assert(not G.sellableStored(manager,item,sold))
            assert(not pack.OwnInventory.Container.DrawInventory and not page.OwnInventory.Container.DrawInventory)
        ''')
