local Core=require('SalvageVacuum.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    function G.pages(pack)
        local out={}
        if pack and not pack.Removed and pack.OwnInventory then
            U.each(pack.OwnInventory.AllItems,function(page)
                if G.is(page,C.page) and page.OwnInventory then out[#out+1]=page end
            end)
        end
        table.sort(out,function(a,b) return a.ID<b.ID end)
        return out
    end
    function G.contents(pack)
        local out={}
        for _,page in ipairs(G.pages(pack)) do U.each(page.OwnInventory.AllItems,function(item)
            if not item.Removed and not G.reserved[item] then out[#out+1]=item end
        end) end
        return out
    end
    function G.records(items)
        local out={}
        for _,item in ipairs(items) do out[#out+1]={kind=G.id(item),item=item,id=item.ID} end
        return out
    end
    function G.has(pack,item)
        local seen={}
        while item and not seen[item] do
            if item==pack then return true end
            seen[item]=true
            local inv=item.ParentInventory
            item=inv and inv.Owner
            if item and not E.LuaUserData.IsTargetType(item,'Barotrauma.Item') then return false end
        end
        return false
    end
    function G.freeSlots(pack)
        local out={}
        for _,page in ipairs(G.pages(pack)) do
            local inv=page.OwnInventory
            for i=0,inv.Capacity-1 do if not inv.GetItemAt(i) then out[#out+1]={inv=inv,slot=i} end end
        end
        return out
    end
    function G.ensureSpace(pack,count)
        if #G.freeSlots(pack)>=count then return true end
        if not G.authoritative or pack.Removed or G.pageSpawning and G.pageSpawning[pack] then return false end
        if #G.pages(pack)>=C.pages then return false end
        G.pageSpawning=G.pageSpawning or {};G.pageSpawning[pack]=true
        E.Entity.Spawner.AddItemToSpawnQueue(E.ItemPrefab.Prefabs[C.page],pack.OwnInventory,nil,nil,function(page)
            G.pageSpawning[pack]=nil
            if pack.Removed or page.ParentInventory~=pack.OwnInventory then E.Entity.Spawner.AddItemToRemoveQueue(page) end
        end,false)
        return false
    end
    function G.insert(pack,item,user,internal)
        if not pack or pack.Removed or not item or item.Removed or item==pack or G.id(item)==C.page then return false end
        if not internal and (G.pending[pack] or G.jobs[pack] or G.reserved[item]) then return false end
        if G.has(item,pack) then return false end
        if not Core.canAccept(G.records(G.contents(pack)),{kind=G.id(item)}) then return false end
        if not G.ensureSpace(pack,1) then return false end
        for _,s in ipairs(G.freeSlots(pack)) do
            if s.inv.TryPutItem(item,s.slot,false,false,user,true,true,false) then return true end
        end
        return false
    end
    function G.withdraw(ctx,id)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] then return false end
        for _,item in ipairs(G.contents(ctx.pack)) do
            if item.ID==id then
                -- Native slots and stack restrictions determine what the user can carry.
                return ctx.owner.Inventory.TryPutItem(item,ctx.owner,{E.InvSlotType.Any},true,false,false)
            end
        end
        return false
    end
    function G.drop(ctx,id)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] then return false end
        for _,item in ipairs(G.contents(ctx.pack)) do
            if item.ID==id then
                item.Drop(ctx.owner,true)
                return item.ParentInventory==nil
            end
        end
        return false
    end
end
return M
