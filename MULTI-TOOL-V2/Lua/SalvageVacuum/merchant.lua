local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    if E.SERVER then
        E.LuaUserData.RegisterType('Barotrauma.SoldItem')
        local listType='System.Collections.Generic.List`1[[Barotrauma.SoldItem, DedicatedServer]]'
        E.LuaUserData.RegisterType(listType)
        local SaleList=E.LuaUserData.CreateStatic(listType)
        local origins=E.LuaUserData.CreateEnumTable('Barotrauma.SoldItem+SellOrigin')
        local function allowed(item,sale,client)
            if not item then return true end -- Ordinary native handling, including ID-less sub sales.
            if G.is(item,C.page) or G.reserved[item] then return false end
            local node,pack,seen=item,nil,{}
            while node do
                if seen[node] then return false end;seen[node]=true
                if G.reserved[node] then return false end
                if G.is(node,C.pack) then
                    pack=node
                    if G.pending[node] or G.jobs[node] then return false end
                end
                node=node.Container
            end
            if not pack then return true end
            node=item;seen={}
            while node do
                if seen[node] then return false end;seen[node]=true
                if node.OwnInventory and node.OwnInventory.Locked then return false end
                local inv=node.ParentInventory
                if not inv then return sale.Origin~=origins.Character end
                if inv.Locked then return false end
                local owner=inv.Owner
                if E.LuaUserData.IsTargetType(owner,'Barotrauma.Character') then
                    return sale.Origin==origins.Character and client and owner==client.Character
                end
                if not E.LuaUserData.IsTargetType(owner,'Barotrauma.Item') then return false end
                node=owner
            end
            return false
        end
        G.patch('merchant-server-sales','Barotrauma.CargoManager','SellItems',function(_,p)
            local filtered=SaleList()
            local function include(sale)
                local item=E.Entity.FindEntityByID(sale.ID)
                if allowed(item,sale,p['client']) then filtered.Add(sale) end
            end
            local sales=p['itemsToSell']
            if type(sales)=='table' then U.each(sales,include)
            else for i=0,sales.Count-1 do include(sales[i]) end end
            p['itemsToSell']=filtered
        end)
    end
    if not E.CLIENT then return end
    local class='Barotrauma.CargoManager'
    local descriptor=E.LuaUserData.RegisterType(class)
    E.LuaUserData.RegisterType('Barotrauma.CargoManager+SoldEntity')
    E.LuaUserData.MakeMethodAccessible(descriptor,'IsItemSellable')
    local inside=false
    function G.sellableStored(manager,item,confirmed)
        if G.is(item,C.page) then return false end
        local chain,node,pack,seen={},item.Container,nil,{}
        while node do
            if seen[node] then return false end
            seen[node]=true;chain[#chain+1]=node
            if G.is(node,C.pack) then pack=node end
            node=node.Container
        end
        if not pack then return nil end
        if G.pending[pack] or G.jobs[pack] or G.reserved[item] then return false end
        local changed={}
        for _,container in ipairs(chain) do
            if container.OwnInventory and container.OwnInventory.Locked then return false end
        end
        -- Native eligibility is synchronous. Relax only Aegis' presentation flag
        -- for this call, retaining every native theft/condition/sold/container rule.
        for _,container in ipairs(chain) do
            if G.is(container,C.pack) or G.is(container,C.page) then
                local component=container.OwnInventory and container.OwnInventory.Container
                if component and not component.DrawInventory then
                    changed[#changed+1]=component;component.DrawInventory=true
                end
            end
        end
        inside=true
        local ok,result=pcall(function()
            -- Hook arguments expose IEnumerable as a MoonSharp wrapper, which
            -- cannot be passed back to a managed IEnumerable parameter directly.
            local sold={};U.each(confirmed,function(value) sold[#sold+1]=value end)
            return manager.IsItemSellable(item,sold)
        end)
        inside=false
        for _,component in ipairs(changed) do component.DrawInventory=false end
        if not ok then error(result) end
        return result
    end
    G.patch('merchant-storage',class,'IsItemSellable',function(manager,p)
        if inside then return end
        local result=G.sellableStored(manager,p['item'],p['confirmedItems'])
        if result~=nil then p.PreventExecution=true;return result end
    end)
end
return M
