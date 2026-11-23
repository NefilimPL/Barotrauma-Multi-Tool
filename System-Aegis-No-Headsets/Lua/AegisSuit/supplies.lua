local U=require('AegisCombat.util')
local Ammo=require('AegisSuit.ammo')
local C=require('AegisSuit.config')
local Modules=require('AegisSuit.modules')
local M={}
local moduleSlots={[C.servoSlot]='servo',[C.impellerSlot]='impeller',[C.compressorSlot]='compressor'}
local function tankCharge(item)
    if not item or item.Removed or item.MaxCondition<=0 or not item.HasTag('oxygensource') then return 0 end
    return item.Condition/item.MaxCondition*100
end
function M.allowed(E,source,owner,suit)
    if not source or source.Removed or source==suit then return false end
    local parent=source.ParentInventory and source.ParentInventory.Owner
    local depth=0
    while parent do
        depth=depth+1;if depth>16 or parent==suit then return false end
        if E.LuaUserData.IsTargetType(parent,'Barotrauma.Character') then return parent==owner,parent==owner end
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
    for _,class in ipairs({'AIObjective','AIObjectiveGetItem'}) do
        E.LuaUserData.MakePropertyAccessible(E.LuaUserData.RegisterType('Barotrauma.'..class),'IsCompleted')
    end
    E.Util.RegisterItemGroup('aegis.suit.supplies',function(item)
        return item.HasTag('mobilebattery') or item.HasTag('oxygensource') or Ammo.profile(item)~=nil or
            Modules.matches(item,'servo') or Modules.matches(item,'impeller') or Modules.matches(item,'compressor')
    end)
    local function cancel(s)
        if s.resupply then s.resupply.IsCompleted=true end
        s.resupply=nil;s.supplyTarget=nil;s.supplyRoot=nil;s.supplyDeadline=nil;s.supplyOwner=nil;s.supplySlot=nil
    end
    G.cancelSupplies=cancel
    local function candidate(owner,item,slot,s,remaining)
        local best,score
        U.each(E.Util.GetItemGroup('aegis.suit.supplies'),function(source)
            if source.Removed then return end
            local usable=slot==0 and source.Condition>=1 and source.HasTag('mobilebattery') or
                slot==1 and Ammo.status(source,Ammo.profile(source))>=1 or
                slot==C.tankSlot and tankCharge(source)>=math.max(1,remaining+5) or
                moduleSlots[slot] and Modules.is(source,moduleSlots[slot])
            if not usable then return end
            local allowed,carried=M.allowed(E,source,owner,item)
            if not allowed or not source.HasAccess(owner) or
                (s.failedSupplies and (s.failedSupplies[source.ID] or 0)>G.now) then return end
            if not carried and source.Submarine~=owner.Submarine then return end
            local distance=carried and -1 or (source.WorldPosition-owner.WorldPosition).LengthSquared()
            if distance<4000*4000 and (not score or distance<score) then best,score=source,distance end
        end)
        return best
    end
    local function backOff(s,source)
        s.failedSupplies=s.failedSupplies or {};s.failedSupplies[source.ID]=G.now+30
    end
    local function needed(item,slot,remaining)
        if slot==C.tankSlot then return remaining<=C.tankSwapAt end
        if slot==0 then return G.energy(item)<=0 end
        if slot==1 then return Ammo.status(G.ammo(item))<1 end
        return not G.module(item,moduleSlots[slot])
    end
    local priority={C.tankSlot,0,C.servoSlot,C.impellerSlot,C.compressorSlot,1}
    function G.updateSupplies(owner,item,s)
        if s.supplyOwner and s.supplyOwner~=owner then cancel(s) end
        if not owner.IsBot or owner.IsUnconscious then cancel(s);return end
        local manager=owner.AIController and owner.AIController.ObjectiveManager
        local remaining=tankCharge(G.tank(item))
        if s.resupply then
            if s.resupply.IsCompleted or not needed(item,s.supplySlot,remaining) then cancel(s)
            elseif G.now>s.supplyDeadline or not manager or manager.CurrentObjective~=s.supplyRoot then
                backOff(s,s.supplyTarget)
                cancel(s)
            elseif s.resupply.Abandon then backOff(s,s.supplyTarget);cancel(s) end
        end
        if G.now<(s.nextResupply or 0) then return end
        s.nextResupply=G.now+1
        local slot,source
        if s.resupply then
            if s.supplySlot==C.tankSlot or remaining>C.tankSwapAt then return end
            slot=C.tankSlot;source=candidate(owner,item,slot,s,remaining)
            if not source then return end
            cancel(s)
        else
            for _,index in ipairs(priority) do
                if needed(item,index,remaining) then
                    source=candidate(owner,item,index,s,remaining)
                    if source then slot=index;break end
                end
            end
        end
        if not source then return end
        if owner.CanInteractWith(source) then
            if not source.ParentInventory and not owner.Inventory.TryPutItem(source,owner,{E.InvSlotType.Any}) then return end
            -- Native inventory swapping preserves the other slot and the old
            -- source if insertion fails. Never drop a working source first.
            if not G.container(item,1).TryPutItem(source,slot,true,false,owner) then backOff(s,source) end
            return
        end
        local parent=manager and manager.CurrentObjective
        if not parent then return end
        local fetch=E.AIObjectiveGetItem(owner,source,manager,false)
        fetch.AllowStealing=false;fetch.AllowToFindDivingGear=false
        parent.AddSubObjective(fetch,true)
        s.resupply=fetch;s.supplyTarget=source;s.supplyRoot=parent;s.supplyOwner=owner;s.supplyDeadline=G.now+25
        s.supplySlot=slot
    end
    function G.clearSupplies() for _,s in pairs(G.states) do cancel(s) end end
end
return M
