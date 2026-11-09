local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local generation=0
    function G.clearManual() generation=generation+1 end
    local function allowed(item,ctx)
        if not item or item.Removed or G.reserved[item] or not G.safeStorageInput(item,ctx) then return false end
        local node,seen,budget=item,{},0
        while node do
            budget=budget+1
            if seen[node] or budget>C.pickupTreeLimit or node==ctx.pack then return false end
            seen[node]=true
            if node.HasAccess and not node.HasAccess(ctx.owner) then return false end
            if G.is(node,C.pack) and (G.pending[node] or G.jobs[node]) then return false end
            local inv=node.ParentInventory
            if not inv then return ctx.owner.CanInteractWith and ctx.owner.CanInteractWith(node,false) end
            if inv.Locked then return false end
            local owner=inv.Owner
            if E.LuaUserData.IsTargetType(owner,'Barotrauma.Character') then return owner==ctx.owner end
            if not E.LuaUserData.IsTargetType(owner,'Barotrauma.Item') then return false end
            node=owner
        end
        return false
    end
    function G.insertBatch(ctx,ids,attempt)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] or type(ids)~='table' or #ids>100 then return false,0 end
        local moved,seen,retry=0,{},{}
        for _,id in ipairs(ids) do
            if not seen[id] then
                seen[id]=true
                local item=E.Entity.FindEntityByID(id)
                if allowed(item,ctx) then
                    if G.insert(ctx.pack,item,ctx.owner) then moved=moved+1
                    elseif G.pageSpawning and G.pageSpawning[ctx.pack] then
                        retry[#retry+1]={item=item,parent=item.ParentInventory}
                    end
                end
            end
        end
        local queued=#retry>0 and E.Timer and E.Timer.Wait and (attempt or 0)<10
        if queued then
            local token=generation
            E.Timer.Wait(function()
                if not G.alive or token~=generation then return end
                local fresh=G.context(ctx.pack,ctx.owner)
                if not fresh.valid then return end
                local remaining={}
                for _,r in ipairs(retry) do
                    if not r.item.Removed and r.item.ParentInventory==r.parent and E.Entity.FindEntityByID(r.item.ID)==r.item then
                        remaining[#remaining+1]=r.item.ID
                    end
                end
                G.insertBatch(fresh,remaining,(attempt or 0)+1)
            end,100)
        end
        return moved>0 or queued==true,moved
    end
    if not E.CLIENT then return end
    local submitted=false
    G.patch('manual-drag-start','Barotrauma.Inventory','UpdateDragging',function() submitted=false end)
    local function drop(inventory,p,slotName)
        local index=p[slotName]
        local user,item=p['user'],p['item']
        if type(index)~='number' or not user or user~=E.Character.Controlled
            or not E.PlayerInput.PrimaryMouseButtonReleased() then return end
        local pack=inventory.GetItemAt(index)
        if not G.is(pack,C.pack) or not G.context(pack,user).valid then return end
        local targets,contains={},false
        U.each(E.Inventory.DraggingItems,function(dragged)
            if #targets<100 then targets[#targets+1]=dragged.ID end
            if dragged==item then contains=true end
        end)
        if not contains then return end
        -- Report handled so native drag cleanup runs, without swapping the pack.
        -- The server moves the real items only after checking the whole context.
        p.PreventExecution=true
        if not submitted then submitted=true;G.request('insert',pack,0,{targets=targets}) end
        return true
    end
    local signature={'Barotrauma.Item','System.Int32','System.Boolean','System.Boolean','Barotrauma.Character',
        'System.Boolean','System.Boolean','System.Boolean'}
    G.patch('manual-drag-character','Barotrauma.CharacterInventory','TryPutItem',function(inv,p) return drop(inv,p,'index') end,false,signature)
    G.patch('manual-drag-container','Barotrauma.ItemInventory','TryPutItem',function(inv,p) return drop(inv,p,'i') end,false,signature)
end
return M
