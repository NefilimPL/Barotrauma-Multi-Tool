local U=require('CombatTool.util')
local C=require('AegisHeadset.config')
local M={}
function M.install(G,E)
    E.LuaUserData.MakeFieldAccessible(E.LuaUserData.RegisterType('Barotrauma.AIObjectiveContainItem'),'item')
    local function reserve(_,p)
        if U.reservedHeadsetCell(E,p['item']) then p.PreventExecution=true;return false end
    end
    G.patch('reserve-search','Barotrauma.AIObjectiveGetItem','CheckItem',reserve)
    G.patch('reserve-contain-search','Barotrauma.AIObjectiveContainItem','CheckItem',reserve)
    G.patch('reserve-take','Barotrauma.AIController','TakeItem',function(controller,p)
        if controller.Character.IsBot then return reserve(controller,p) end
    end)
    G.patch('reserve-contain','Barotrauma.AIObjectiveContainItem','Act',function(objective,p)
        if U.reservedHeadsetCell(E,objective.item) then
            objective.Abandon=true;p.PreventExecution=true
        end
    end)
    G.patch('reserve-unload','Barotrauma.AIController','UnequipContainedItems',function(controller,p)
        local character=controller and controller.Character or p['character']
        local item=p['parentItem']
        if character and character.IsBot and item and item.HasTag('aegisheadset') then p.PreventExecution=true end
    end,false,{'Barotrauma.Character','Barotrauma.Item',
        'System.Func`2[Barotrauma.Item,System.Boolean]',
        'System.Boolean','System.Boolean','System.Nullable`1[System.Int32]'})
end
function M.candidate(E,character,item,current,failed,now)
    local best,score=nil,math.huge
    U.each(E.Item.ItemList,function(cell)
        if cell.Removed or cell.Illegitimate or cell==item or not cell.HasTag('mobilebattery') or cell.MaxCondition<=0 then return end
        if failed and (failed[cell] or 0)>(now or 0) then return end
        local charge=cell.Condition/cell.MaxCondition*100
        if charge<=math.max(C.botThreshold,current+1) or not cell.HasAccess(character) then return end
        local parent=cell.ParentInventory and cell.ParentInventory.Owner
        local allowed,depth=true,0
        while parent and depth<16 do
            depth=depth+1
            if E.LuaUserData.IsTargetType(parent,'Barotrauma.Character') then
                if parent~=character then allowed=false end
                break
            elseif E.LuaUserData.IsTargetType(parent,'Barotrauma.Item') then
                if U.component(parent,'Reactor') or U.component(parent,'PowerContainer') or
                    U.component(parent,'RangedWeapon') or C.identifiers[U.itemId(parent)] or
                    parent.HasTag('tool') or parent.HasTag('weapon') then allowed=false;break end
                -- Ordinary storage has only container/equip/repair components.
                -- Unknown operational components (including sonar/beacons)
                -- make this a device, not a source of spare cells.
                local storage={itemcontainer=true,holdable=true,pickable=true,wearable=true,repairable=true,quality=true}
                U.each(parent.Components,function(component)
                    if not storage[tostring(component.Name):lower()] then allowed=false end
                end)
                if not allowed then break end
                parent=parent.ParentInventory and parent.ParentInventory.Owner
            else allowed=false;break end
        end
        if depth>=16 then allowed=false end
        local dx,dy=cell.WorldPosition.X-character.WorldPosition.X,cell.WorldPosition.Y-character.WorldPosition.Y
        local distance=dx*dx+dy*dy
        if cell.ParentInventory==character.Inventory then distance=-1 end
        if allowed and distance<4000*4000 and distance<score then best,score=cell,distance end
    end)
    return best
end
function M.cancel(s)
    if s.resupply and not s.resupply.IsCompleted then s.resupply.IsCompleted=true end
    s.resupply=nil;s.resupplyRoot=nil;s.pendingCell=nil
end
function M.update(G,E,character,item)
    if not character.IsBot or not character.AIController then return end
    local s=G.state(item)
    local manager=character.AIController.ObjectiveManager
    local parent=manager and manager.CurrentObjective
    if s.resupply and (s.resupply.IsCompleted or s.resupply.Abandon or s.resupplyRoot~=parent or G.now>s.deadline) then
        if (s.resupply.Abandon or G.now>s.deadline) and s.resupplyCell and not s.resupply.IsCompleted then
            s.failedCells=s.failedCells or {};s.failedCells[s.resupplyCell]=G.now+C.failedSupplyCooldown
        end
        M.cancel(s)
    end
    if s.resupply or G.now<(s.nextResupply or 0) or G.energy(item)>C.botThreshold then return end
    s.nextResupply=G.now+C.resupplyInterval
    local cell=M.candidate(E,character,item,G.energy(item),s.failedCells,G.now)
    if not cell then return end
    if character.CanInteractWith(cell) then
        -- Native swapping is atomic: failure leaves the old cell in place.
        -- Pick up a floor spare first so the old cell has a destination.
        if not cell.ParentInventory then
            if not character.Inventory.TryPutItem(cell,character,{E.InvSlotType.Any}) then return end
        end
        if item.OwnInventory.TryPutItem(cell,0,true,false,character) then
            s.resupplyCell=nil
        end
        return
    end
    if not parent then return end
    -- Fetch before touching a still functioning battery. A distant supply is
    -- never permission to leave the bot unprotected during the journey.
    local fetch=E.AIObjectiveGetItem(character,cell,manager,false)
    fetch.AllowStealing=false
    parent.AddSubObjective(fetch,true)
    s.resupply=fetch;s.resupplyRoot=parent;s.deadline=G.now+C.resupplyTimeout
    s.resupplyCell=cell
end
return M
