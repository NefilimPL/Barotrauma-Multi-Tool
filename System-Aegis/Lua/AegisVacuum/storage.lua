local Core=require('AegisVacuum.core')
local C=Core.config
local U=require('AegisCombat.util')
local M={}
function M.install(G,E)
    local spawnBudget={pending=0}
    function G.hasSpawnRoom(count)
        local entity=E.Entity
        return entity.EntityCount+spawnBudget.pending+count<=entity.MaxEntityCount
    end
    function G.reserveSpawns(count)
        if not G.hasSpawnRoom(count) then return end
        local budget=spawnBudget
        budget.pending=budget.pending+count
        return function(amount) budget.pending=budget.pending-(amount or 1) end
    end
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
    local indexes,records,listIndexes={},{},{}
    local function record(item)
        local id=item.ID
        local r=records[id]
        if not r or r.item~=item then r={kind=G.id(item),item=item,id=id};records[id]=r end
        return r
    end
    local function countKind(index,kind,delta)
        if not index.kindCounts then return end
        local previous=index.kindCounts[kind] or 0
        local count=previous+delta
        index.kindCounts[kind]=count>0 and count or nil
        index.groupCount=index.groupCount+math.ceil(count/C.groupSize)-math.ceil(previous/C.groupSize)
    end
    local function add(index,item,page)
        local id=item.ID
        if not item.Removed and not index.positions[id] then
            index.items[#index.items+1]=item;index.positions[id]=#index.items
            local row=record(item)
            index.records[#index.records+1]=row
            countKind(index,row.kind,1)
            if page then
                index.itemPages[id]=page
                index.pageCounts[page]=(index.pageCounts[page] or 0)+1
            end
            index.view=nil
        end
    end
    local function remove(index,item)
        local id=item.ID
        local position=index.positions[id]
        if not position or index.items[position]~=item then return end
        countKind(index,index.records[position].kind,-1)
        local page=index.itemPages and index.itemPages[id]
        if page then
            index.itemPages[id]=nil
            local count=index.pageCounts[page]-1
            index.pageCounts[page]=count>0 and count or nil
        end
        local last=index.items[#index.items]
        index.items[position]=last;index.positions[last.ID]=position
        index.records[position]=index.records[#index.records]
        index.items[#index.items]=nil;index.records[#index.records]=nil;index.positions[id]=nil
        records[id]=nil;index.view=nil
    end
    local function indexFor(pack)
        if not indexes[pack] then
            local index={items={},positions={},records={},kindCounts={},groupCount=0,itemPages={},pageCounts={}}
            indexes[pack]=index;listIndexes[index.items]=index
            for _,page in ipairs(G.pages(pack)) do U.each(page.OwnInventory.AllItems,function(item) add(index,item,page) end) end
        end
        return indexes[pack]
    end
    local function materialTree(index,item,inserted,seen)
        if seen[item] then return end;seen[item]=true
        local id=item.ID
        if inserted then
            if item.OwnInventory then index.containers[id]=item end
            if not G.is(item,C.page) then add(index,item) end
        else index.containers[id]=nil;remove(index,item) end
        for _,child in ipairs(G.children(item)) do materialTree(index,child,inserted,seen) end
    end
    local function materialsFor(pack)
        local root=indexFor(pack)
        if not root.materials then
            local index={items={},positions={},records={},containers={}};root.materials=index
            for _,page in ipairs(G.pages(pack)) do materialTree(index,page,true,{}) end
        end
        return root.materials
    end
    function G.materialRecords(pack) return materialsFor(pack).records end
    function G.materialContainers(pack) return materialsFor(pack).containers end
    function G.contents(pack)
        local items=indexFor(pack).items
        if not G.pending[pack] then return items end
        local available={}
        for _,item in ipairs(items) do if not G.reserved[item] then available[#available+1]=item end end
        return available
    end
    function G.records(items)
        local out={}
        local index=listIndexes[items]
        if index then
            for i,r in ipairs(index.records) do out[i]=r end
        else
            for _,item in ipairs(items) do out[#out+1]=record(item) end
        end
        return out
    end
    function G.storageView(pack)
        if G.pending[pack] then return nil end
        local index=indexFor(pack)
        if not index.view then
            local sorted=G.records(index.items)
            table.sort(sorted,function(a,b) return a.kind==b.kind and a.id<b.id or a.kind<b.kind end)
            index.view={groups=Core.groups(sorted),count=#index.items}
        end
        return index.view
    end
    function G.canSalvageFit(pack,item,additions)
        local index=indexFor(pack)
        local changes={}
        local position=index.positions[item.ID]
        if position and index.items[position]==item then changes[index.records[position].kind]=-1 end
        for _,row in ipairs(additions) do changes[row.kind]=(changes[row.kind] or 0)+1 end
        local groups=index.groupCount
        for kind,delta in pairs(changes) do
            local count=index.kindCounts[kind] or 0
            groups=groups+math.ceil((count+delta)/C.groupSize)-math.ceil(count/C.groupSize)
        end
        return groups<=C.groups
    end
    function G.clearStorageCache()
        indexes={};records={};listIndexes={};spawnBudget={pending=0};G.pageSpawning={}
    end
    local function changed(container,p,inserted)
        local parent,item=container.Item,p['containedItem']
        if not parent or not item then return end
        if G.is(parent,C.pack) then
            local index=indexes[parent]
            if index and item.OwnInventory then U.each(item.OwnInventory.AllItems,function(child)
                if inserted then add(index,child,item) else remove(index,child) end
            end) end
        elseif G.is(parent,C.page) then
            local inv=parent.ParentInventory
            local pack=inv and inv.Owner
            if pack and E.LuaUserData.IsTargetType(pack,'Barotrauma.Item') and G.is(pack,C.pack) then
                local index=indexFor(pack)
                if inserted then add(index,item,parent) else remove(index,item) end
            end
        end
        -- Any nested container can supply a machine; keep that lazy index current too.
        local node,seen=parent,{}
        while node and not seen[node] do
            seen[node]=true
            if G.is(node,C.pack) and indexes[node] and indexes[node].materials then
                materialTree(indexes[node].materials,item,inserted,{})
            end
            local inv=node.ParentInventory;node=inv and inv.Owner
            if node and not E.LuaUserData.IsTargetType(node,'Barotrauma.Item') then break end
        end
    end
    if G.patch then
        G.patch('stored-add','Barotrauma.Items.Components.ItemContainer','OnItemContained',function(container,p) changed(container,p,true) end,true)
        G.patch('stored-remove','Barotrauma.Items.Components.ItemContainer','OnItemRemoved',function(container,p) changed(container,p,false) end,true)
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
    function G.freeSlots(pack,limit)
        local out={}
        local counts=indexFor(pack).pageCounts
        for _,page in ipairs(G.pages(pack)) do
            local inv=page.OwnInventory
            local capacity=inv.Capacity
            if (counts[page] or 0)<capacity then
                for i=0,capacity-1 do if not inv.GetItemAt(i) then
                    out[#out+1]={inv=inv,slot=i,page=page}
                    if limit and #out>=limit then return out end
                end end
            end
        end
        return out
    end
    function G.ensureSpace(pack,count)
        local pages=G.pages(pack)
        local capacity=0
        for _,page in ipairs(pages) do capacity=capacity+page.OwnInventory.Capacity end
        if capacity-#indexFor(pack).items>=count then return true end
        if not G.authoritative or pack.Removed or G.pageSpawning and G.pageSpawning[pack] then return false end
        if #pages>=C.pages then return false end
        local release=G.reserveSpawns(1)
        if not release then return false end
        G.pageSpawning=G.pageSpawning or {}
        local spawning=G.pageSpawning;spawning[pack]=true
        E.Entity.Spawner.AddItemToSpawnQueue(E.ItemPrefab.Prefabs[C.page],pack.OwnInventory,nil,nil,function(page)
            release();spawning[pack]=nil
            if pack.Removed or page.ParentInventory~=pack.OwnInventory then E.Entity.Spawner.AddItemToRemoveQueue(page) end
        end,false)
        return false
    end
    function G.insert(pack,item,user,internal)
        if not pack or pack.Removed or not item or item.Removed or item==pack or G.id(item)==C.page then return false end
        -- Only the atomic output spawn reserves insertion capacity. A running
        -- job owns its input snapshot, so newly collected loot remains intact.
        if not internal and (G.pending[pack] or G.reserved[item]) then return false end
        if G.has(item,pack) then return false end
        local index=indexFor(pack)
        local count=index.kindCounts[G.id(item)] or 0
        if count%C.groupSize==0 and index.groupCount>=C.groups then return false end
        if not G.ensureSpace(pack,1) then return false end
        for _,s in ipairs(G.freeSlots(pack,1)) do
            if s.inv.TryPutItem(item,s.slot,false,false,user,true,true,false) then add(index,item,s.page);return true end
        end
        return false
    end
    local function take(item,owner)
        if owner.Inventory.TryPutItem(item,owner,{E.InvSlotType.Any},true,false,false) then return true end
        local right,left=E.InvSlotType.RightHand,E.InvSlotType.LeftHand
        if right and left then return owner.Inventory.TryPutItem(item,owner,{right+left,right,left},true,false,false) end
        return false
    end
    function G.withdraw(ctx,id)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] then return false end
        for _,item in ipairs(G.contents(ctx.pack)) do
            if item.ID==id then
                -- Native slots and stack restrictions determine what the user can carry.
                return take(item,ctx.owner)
            end
        end
        return false
    end
    function G.withdrawBatch(ctx,ids,wholeGroups)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] or type(ids)~='table' or #ids>100 then return false,0 end
        local selected={};for _,id in ipairs(ids) do selected[id]=true end
        local items={}
        if wholeGroups then
            for _,group in ipairs(G.storageView(ctx.pack).groups) do
                local chosen=false
                for _,r in ipairs(group.items) do if selected[r.id] then chosen=true;break end end
                if chosen then for _,r in ipairs(group.items) do items[#items+1]=r.item end end
            end
        else
            for _,item in ipairs(G.contents(ctx.pack)) do if selected[item.ID] then items[#items+1]=item end end
        end
        local moved=0
        for _,item in ipairs(items) do
            if not item.Removed and not G.reserved[item] and G.has(ctx.pack,item) and take(item,ctx.owner) then moved=moved+1 end
        end
        return moved>0,moved
    end
    function G.withdrawStack(ctx,id)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] then return false end
        local group,selected
        for _,candidate in ipairs(G.storageView(ctx.pack).groups) do
            for _,r in ipairs(candidate.items) do if r.id==id then group=candidate;selected=r.item;break end end
            if group then break end
        end
        if not group then return false end
        local inv,slot=ctx.owner.Inventory,nil
        -- Choose one ordinary slot, preferring an existing compatible partial stack.
        -- Native checks preserve quality/condition restrictions and talent stack bonuses.
        for pass=1,2 do
            for i=0,inv.Capacity-1 do
                if inv.SlotTypes[i]==E.InvSlotType.Any and (inv.GetItemAt(i)~=nil)==(pass==1)
                    and inv.CanBePutInSlot(selected,i,false) then slot=i;break end
            end
            if slot then break end
        end
        if slot==nil then
            -- Large crates/suits can require hands; a single item is a whole stack.
            local ok=take(selected,ctx.owner);return ok,ok and 1 or 0
        end
        if not inv.TryPutItem(selected,slot,false,false,ctx.owner,true,false,false) then return false end
        local moved=1
        for _,r in ipairs(group.items) do
            if r.item~=selected and not r.item.Removed and G.has(ctx.pack,r.item)
                and inv.CanBePutInSlot(r.item,slot,false)
                and inv.TryPutItem(r.item,slot,false,false,ctx.owner,true,false,false) then moved=moved+1 end
        end
        return moved>0,moved
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
