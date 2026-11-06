local Core=require('SalvageVacuum.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local items,vacuums={},{}
    local refreshAt,lootAt,scanAt,salvageAt=0,0,0,0
    local refresh
    local function updateLoot(origins)
        if #origins==0 then refresh=nil;return end
        if not refresh and G.now>=lootAt then
            lootAt=G.now+C.refreshInterval
            refresh={source=E.Item.ItemList,cursor=1,items={},roots={}}
        end
        if not refresh then return end
        local source=refresh.source
        local luaList=type(source)=='table'
        local count=luaList and #source or source.Count
        for n=1,C.refreshBudget do
            if refresh.cursor>count then items=refresh.items;refresh=nil;return end
            local item=source[luaList and refresh.cursor or refresh.cursor-1]
            refresh.cursor=refresh.cursor+1
            if item and not item.Removed then
                local root=item.RootContainer
                local stored=root and refresh.roots[root]
                if root and stored==nil then stored=G.is(root,C.pack);refresh.roots[root]=stored end
                if not stored and G.id(item)~=C.page then
                    local point=item.WorldPosition
                    for _,source in ipairs(origins) do
                        local origin=source.point
                        local dx,dy=point.X-origin.x,point.Y-origin.y
                        -- Keep a margin for walking and turning between refreshes.
                        -- Distant level items must not consume the suction cursor budget.
                        if dx*dx+dy*dy<=(C.range*2)^2 then
                            local nearby=refresh.items[source.vacuum]
                            if not nearby then nearby={};refresh.items[source.vacuum]=nearby end
                            nearby[#nearby+1]=item
                        end
                    end
                end
            end
        end
    end
    function G.resetRuntime()
        items,vacuums={},{}
        refresh=nil
        refreshAt,lootAt,scanAt,salvageAt=0,0,0,0
    end
    function G.portable(item)
        if not item or item.Removed or G.id(item)==C.page then return false end
        -- Match FastLoot: CanBePicked alone also describes crowbar-operated doors.
        local slotted=false
        U.each(item.AllowedSlots,function(slot)
            local name=tostring(slot):lower()
            if name~='none' and name~='0' and name~='' then slotted=true end
        end)
        if not slotted or U.component(item,'Door') then return false end
        local wire=U.component(item,'Wire')
        if wire then
            local connections=wire.Connections
            local connected=false
            -- LuaCs marshals Connection[] as a sparse one-based Lua table.
            -- ipairs stops at a missing first end, so inspect every present value.
            if type(connections)=='table' then
                for _,connection in pairs(connections) do if connection then connected=true end end
            else U.each(connections,function(connection) if connection then connected=true end end) end
            if connected then return false end
            local routed=false;U.each(wire.GetNodes(),function() routed=true end)
            if routed then return false end
        end
        local pick
        U.each(item.Components,function(component)
            if E.LuaUserData.IsTargetType(component,'Barotrauma.Items.Components.Pickable') then pick=component end
        end)
        return pick and pick.CanBePicked and not pick.IsAttached
            and pick.PickingTime<2147483647
    end
    local function safeContents(item,ctx,seen,budget,pageAllowed)
        if seen[item] or budget.count>=C.pickupTreeLimit then return false end
        seen[item]=true;budget.count=budget.count+1
        local internalPage=pageAllowed and G.is(item,C.page)
        local locked=false
        U.each(item.Components,function(component)
            if tostring(component.Name):lower()=='itemcontainer' and component.Inventory and component.Inventory.Locked then locked=true end
        end)
        if (not internalPage and not G.portable(item)) or not item.HasAccess(ctx.owner) or item==ctx.pack or item==ctx.vacuum or locked
            or (item.ParentInventory and item.ParentInventory.Locked)
            or (item.OwnInventory and item.OwnInventory.Locked) then return false end
        for _,child in ipairs(G.children(item)) do
            if not safeContents(child,ctx,seen,budget,G.is(item,C.pack)) then return false end
        end
        return true
    end
    function G.safeStorageInput(item,ctx) return safeContents(item,ctx,{},{count=0}) end
    function G.pickupTarget(item,ctx)
        if not item or item.Removed then return nil end
        if G.looseOnly and G.looseOnly(ctx.pack) and (item.ParentInventory or #G.children(item)>0) then return nil end
        local candidates,node,seen={},item,{}
        while node do
            if seen[node] then return nil end
            seen[node]=true
            if node==ctx.pack or node==ctx.vacuum or G.is(node,C.page) then return nil end
            if not node.HasAccess(ctx.owner) then return nil end
            if G.portable(node) then candidates[#candidates+1]=node end
            local inv=node.ParentInventory
            if not inv then break end
            if inv.Locked then return nil end
            local owner=inv.Owner
            if E.LuaUserData.IsTargetType(owner,'Barotrauma.Character') then
                if owner==ctx.owner or not owner.IsDead then return nil end
                break
            end
            if not E.LuaUserData.IsTargetType(owner,'Barotrauma.Item') then return nil end
            node=owner
        end
        for i=#candidates,1,-1 do
            local target=candidates[i]
            if safeContents(target,ctx,{},{count=0})
                and (not G.acceptsLoot or G.acceptsLoot(ctx.pack,target)) then return target end
        end
        return nil
    end
    G.patch('suction-use','Barotrauma.Items.Components.RangedWeapon','Use',function(component,p)
        if not G.is(component.Item,C.vacuum) then return end
        p.PreventExecution=true
        local ctx=G.context(component.Item,p['character'])
        if not ctx.valid or not ctx.aim then return false end
        local state=G.states[component.Item] or {cursor=1}
        G.states[component.Item]=state
        state.usedAt=G.now
        return true
    end)
    function G.update(dt)
        G.now=G.now+math.min(dt,.1)
        if G.updateTrash then G.updateTrash() end
        if G.now>=refreshAt then
            refreshAt=G.now+C.refreshInterval;vacuums={}
            -- LuaCs maintains this index on item.created and clears it at round end.
            -- Discover equipment without crossing into every native item twice a second.
            U.each(E.Util.GetItemsById(C.vacuum),function(item)
                local root=item.RootContainer
                if not item.Removed and not (root and G.is(root,C.pack)) then
                    vacuums[#vacuums+1]=item
                    G.states[item]=G.states[item] or {cursor=1}
                end
            end)
            for item in pairs(G.states) do if item.Removed then G.states[item]=nil;G.selected[item.ID]=nil end end
            for pack in pairs(G.salvageResults or {}) do if pack.Removed then G.salvageResults[pack]=nil end end
        end
        if G.authoritative and G.now>=scanAt then
            scanAt=G.now+C.scanInterval
            for _,vacuum in ipairs(vacuums) do
                local state=G.states[vacuum] or {cursor=1}
                G.states[vacuum]=state
                local ctx=G.context(vacuum)
                state.active=ctx.valid and ctx.aim and G.now-(state.usedAt or -100)<.15
                    and G.charge(vacuum)>0 and not G.pending[ctx.pack]
                if G.sendActivity then G.sendActivity(vacuum,state.active) end
                if state.active and G.spend(vacuum,C.suctionCost*C.scanInterval) then
                    local origin,direction=G.muzzle(vacuum),G.direction(vacuum)
                    local picked,seen=0,{}
                    local nearby=items[vacuum] or {}
                    for n=1,math.min(#nearby,C.scanBudget) do
                        if state.cursor>#nearby then state.cursor=1 end
                        local item=nearby[state.cursor];state.cursor=state.cursor+1
                        -- Cheap geometry rejection before inspecting inventory ancestry.
                        if item and not item.Removed and Core.inCone(origin,direction,U.point(item.WorldPosition)) then
                            local target=G.pickupTarget(item,ctx)
                            if target and not seen[target] and not G.reserved[target] then
                                seen[target]=true
                                local point=U.point(target.WorldPosition)
                                if Core.inCone(origin,direction,point) and not G.cast(origin,point,0,ctx.owner,true)
                                    and G.charge(vacuum)>=C.pickupCost then
                                    if G.insert(ctx.pack,target,ctx.owner) then
                                        G.spend(vacuum,C.pickupCost);picked=picked+1
                                        if G.transferEffect then G.transferEffect(vacuum,point) end
                                    end
                                end
                            end
                        end
                        if picked>=C.pickupsPerTick then break end
                    end
                end
            end
        end
        if G.authoritative then
            local origins={}
            for _,vacuum in ipairs(vacuums) do
                local state=G.states[vacuum]
                if state and state.active and G.now-(state.usedAt or -100)<.15 then
                    origins[#origins+1]={vacuum=vacuum,point=G.muzzle(vacuum)}
                end
            end
            updateLoot(origins)
        end
        if G.authoritative and G.now>=salvageAt then
            salvageAt=G.now+C.salvageInterval
            local jobs={};for _,job in pairs(G.jobs) do jobs[#jobs+1]=job end
            for _,job in ipairs(jobs) do G.processSalvage(job) end
        end
        if G.updateClient then G.updateClient(dt) end
        if G.updateVisuals then G.updateVisuals(dt) end
        if G.updateAudio then G.updateAudio(dt) end
    end
    E.Hook.Add('think','bmt.vacuum.think',function() G.update(1/60) end)
    E.Hook.Add('roundEnd','bmt.vacuum.roundEnd',G.reset)
    E.Hook.Add('stop','bmt.vacuum.stop',function() G.alive=false;G.reset() end)
end
return M
