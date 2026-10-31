local U=require('CombatTool.util')
local C=require('AegisHeadset.config')
local M={}
function M.candidate(E,character,item,current,failed,now)
    local best,score=nil,math.huge
    U.each(E.Item.ItemList,function(cell)
        if cell.Removed or cell==item or not cell.HasTag('mobilebattery') or cell.MaxCondition<=0 then return end
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
    if not parent or s.resupply or G.now<(s.nextResupply or 0) or G.energy(item)>=C.botThreshold then return end
    s.nextResupply=G.now+C.resupplyInterval
    local cell=M.candidate(E,character,item,G.energy(item),s.failedCells,G.now)
    if not cell then return end
    -- Fetch before touching a still functioning battery. A distant supply is
    -- never permission to leave the bot unprotected during the journey.
    if not character.CanInteractWith(cell) then
        local fetch=E.AIObjectiveGetItem(character,cell,manager,false)
        fetch.AllowStealing=false
        parent.AddSubObjective(fetch,true)
        s.resupply=fetch;s.resupplyRoot=parent;s.deadline=G.now+C.resupplyTimeout
        s.resupplyCell=cell
        return
    end
    local container=U.component(item,'ItemContainer')
    if not container then return end
    local objective=E.AIObjectiveContainItem(character,cell,container,manager,1)
    objective.TargetSlot=0;objective.ItemCount=1;objective.RemoveEmpty=false
    objective.MoveWholeStack=false;objective.AllowStealing=false
    local previous=G.source(item)
    if previous and not character.Inventory.TryPutItem(previous,character,{E.InvSlotType.Any}) then previous.Drop(character) end
    local deadline=G.now+C.resupplyTimeout
    objective.AbortCondition=function()
        return item.Removed or cell.Removed or character.IsDead or G.equipped(character)~=item or G.now>deadline
    end
    parent.AddSubObjective(objective,true)
    s.resupply=objective;s.resupplyRoot=parent;s.deadline=deadline
    s.resupplyCell=cell
end
return M
