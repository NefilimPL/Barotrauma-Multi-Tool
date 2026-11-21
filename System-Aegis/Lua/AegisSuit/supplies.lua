local U=require('AegisCombat.util')
local Ammo=require('AegisSuit.ammo')
local M={}
function M.allowed(E,source,owner,suit)
    if not source or source.Removed or source==suit then return false end
    local parent=source.ParentInventory and source.ParentInventory.Owner
    local depth=0
    while parent do
        depth=depth+1;if depth>16 or parent==suit then return false end
        if E.LuaUserData.IsTargetType(parent,'Barotrauma.Character') then return parent==owner end
        if not E.LuaUserData.IsTargetType(parent,'Barotrauma.Item') then return false end
        if parent.HasTag and (parent.HasTag('tool') or parent.HasTag('weapon') or parent.HasTag('diving')) then return false end
        local storage={itemcontainer=true,holdable=true,pickable=true,wearable=true,repairable=true,quality=true}
        local allowed=true
        U.each(parent.Components,function(c) if not storage[tostring(c.Name):lower()] then allowed=false end end)
        if not allowed then return false end
        parent=parent.ParentInventory and parent.ParentInventory.Owner
    end
    return true
end
function M.install(G,E)
    if not G.authoritative then return end
    for _,class in ipairs({'AIObjective','AIObjectiveGetItem','AIObjectiveFindDivingGear'}) do
        E.LuaUserData.MakePropertyAccessible(E.LuaUserData.RegisterType('Barotrauma.'..class),'IsCompleted')
    end
    G.patch('closed-loop-ai','Barotrauma.AIObjectiveFindDivingGear','Act',function(objective,p)
        local owner=objective.character
        local item=G.equipped(owner)
        if not item then return end
        p.PreventExecution=true
        -- An unpowered suit waits for our battery fetch instead of trying to
        -- put an oxygen tank into its restricted supply slots.
        if G.energy(item)>0 then objective.IsCompleted=true end
    end)
    E.Util.RegisterItemGroup('aegis.suit.supplies',function(item)
        return item.HasTag('mobilebattery') or item.HasTag('reactorfuel') or Ammo.profile(item)~=nil
    end)
    local function cancel(s)
        if s.resupply then s.resupply.IsCompleted=true end
        s.resupply=nil;s.supplyTarget=nil;s.supplyRoot=nil;s.supplyDeadline=nil;s.supplyOwner=nil
    end
    G.cancelSupplies=cancel
    local function candidate(owner,item,slot,s)
        local best,score
        U.each(E.Util.GetItemGroup('aegis.suit.supplies'),function(source)
            local usable=slot==0 and source.Condition>=1 and (source.HasTag('mobilebattery') or source.HasTag('reactorfuel')) or
                slot==1 and Ammo.status(source,Ammo.profile(source))>=1
            if not usable or
                not M.allowed(E,source,owner,item) or not source.HasAccess(owner) or
                U.reservedHeadsetCell(E,source) or (s.failedSupplies and (s.failedSupplies[source.ID] or 0)>G.now) then return end
            if source.Submarine~=owner.Submarine and source.ParentInventory~=owner.Inventory then return end
            local distance=(source.WorldPosition-owner.WorldPosition).LengthSquared()
            if source.ParentInventory==owner.Inventory then distance=-1 end
            if distance<4000*4000 and (not score or distance<score) then best,score=source,distance end
        end)
        return best
    end
    function G.updateSupplies(owner,item,s)
        if s.supplyOwner and s.supplyOwner~=owner then cancel(s) end
        if not owner.IsBot or owner.IsUnconscious then cancel(s);return end
        local manager=owner.AIController and owner.AIController.ObjectiveManager
        if s.resupply then
            if s.resupply.IsCompleted or s.resupply.Abandon then cancel(s)
            elseif G.now>s.supplyDeadline or not manager or manager.CurrentObjective~=s.supplyRoot then
                s.failedSupplies=s.failedSupplies or {};s.failedSupplies[s.supplyTarget.ID]=G.now+30
                cancel(s)
            else return end
        end
        if G.now<(s.nextResupply or 0) then return end
        s.nextResupply=G.now+1
        local slot=G.energy(item)<=0 and 0 or Ammo.status(G.ammo(item))<1 and 1 or nil
        if slot==nil then return end
        local source=candidate(owner,item,slot,s)
        if not source then return end
        if owner.CanInteractWith(source) then
            if not source.ParentInventory and not owner.Inventory.TryPutItem(source,owner,{E.InvSlotType.Any}) then return end
            -- Native inventory swapping preserves the other slot and the old
            -- source if insertion fails. Never drop a working source first.
            G.container(item,1).TryPutItem(source,slot,true,false,owner)
            return
        end
        local parent=manager and manager.CurrentObjective
        if not parent then return end
        local fetch=E.AIObjectiveGetItem(owner,source,manager,false)
        fetch.AllowStealing=false;fetch.AllowToFindDivingGear=false
        parent.AddSubObjective(fetch,true)
        s.resupply=fetch;s.supplyTarget=source;s.supplyRoot=parent;s.supplyOwner=owner;s.supplyDeadline=G.now+25
    end
    function G.clearSupplies() for _,s in pairs(G.states) do cancel(s) end end
end
return M
