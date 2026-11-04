local Core=require('SalvageVacuum.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
function M.new(E)
    local G={env=E,authoritative=E.SERVER or E.Game.IsSingleplayer,now=0,alive=true,
        selected={},states={},jobs={},pending={},patches={},reserved={},lastRequest={}}
    function G.id(item) return item and tostring(item.Prefab.Identifier):lower() or '' end
    function G.is(item,id) return item and not item.Removed and G.id(item)==id end
    function G.owner(item)
        local owner=item and item.ParentInventory and item.ParentInventory.Owner
        return owner and E.LuaUserData.IsTargetType(owner,'Barotrauma.Character') and owner or nil
    end
    function G.packs(owner)
        local out={}
        if owner and owner.Inventory then U.each(owner.Inventory.AllItems,function(i)
            if G.is(i,C.pack) then out[#out+1]=i end
        end) end
        local worn=owner and owner.Inventory and E.InvSlotType.Bag
            and owner.Inventory.GetItemInLimbSlot(E.InvSlotType.Bag)
        table.sort(out,function(a,b)
            if a==worn or b==worn then return a==worn end
            return a.ID<b.ID
        end)
        return out
    end
    function G.context(vacuum,character)
        local owner=G.owner(vacuum)
        local ctx={vacuum=vacuum,owner=owner,valid=false}
        if not owner or (character and owner~=character) or owner.Removed or owner.IsDead
            or owner.IsUnconscious or owner.CanInteract==false or vacuum.Condition<=0 then return ctx end
        if G.is(vacuum,C.pack) then ctx.pack=vacuum;ctx.valid=true;return ctx end
        if not G.is(vacuum,C.vacuum) then return ctx end
        local packs=G.packs(owner)
        for _,pack in ipairs(packs) do if pack.ID==G.selected[vacuum.ID] then ctx.pack=pack end end
        ctx.pack=ctx.pack or packs[1]
        ctx.valid=ctx.pack~=nil and owner.Inventory.GetItemInLimbSlot(E.InvSlotType.RightHand)==vacuum
            and owner.Inventory.GetItemInLimbSlot(E.InvSlotType.LeftHand)==vacuum
        ctx.aim=owner.IsKeyDown(E.InputType.Aim)
        return ctx
    end
    function G.source(vacuum)
        if not G.is(vacuum,C.vacuum) then return nil end
        local source=vacuum and vacuum.OwnInventory and vacuum.OwnInventory.GetItemAt(0)
        if source and not source.Removed and source.MaxCondition>0 and source.HasTag('mobilebattery') then return source end
    end
    function G.charge(vacuum)
        local source=G.source(vacuum)
        return source and source.Condition/source.MaxCondition*100 or 0
    end
    function G.spend(vacuum,cost)
        local source=G.source(vacuum)
        if not source then return false end
        local value,paid=Core.debit(G.charge(vacuum),cost)
        if paid then source.Condition=value/100*source.MaxCondition end
        return paid
    end
    function G.authorize(client,vacuum)
        if not client or not client.Character then return false end
        local ctx=G.context(vacuum,client.Character)
        return ctx.valid and ctx.owner==client.Character
    end
    function G.children(item)
        local out,seen={},{}
        U.each(item.Components,function(component)
            if component.Name:lower()=='itemcontainer' and component.Inventory then
                U.each(component.Inventory.AllItems,function(child)
                    if not seen[child] and not child.Removed then seen[child]=true;out[#out+1]=child end
                end)
            end
        end)
        return out
    end
    function G.patch(name,class,method,fn,after)
        local id='bmt.vacuum.'..name
        local phase=after and E.Hook.HookMethodType.After or E.Hook.HookMethodType.Before
        E.Hook.Patch(id,class,method,fn,phase)
        G.patches[#G.patches+1]={id,class,method,phase}
    end
    function G.reset()
        if G.closePanel then G.closePanel() end
        for _,tx in pairs(G.pending) do tx.cancelled=true end
        G.states={};G.jobs={};G.selected={};G.reserved={};G.lastRequest={}
        if G.clearStorageCache then G.clearStorageCache() end
        if G.resetRuntime then G.resetRuntime() end
    end
    function G.dispose()
        G.alive=false;G.reset()
        if G.disposeClient then G.disposeClient() elseif G.closePanel then G.closePanel() end
        if G.disposeVisuals then G.disposeVisuals() end
        for _,event in ipairs({'think','roundEnd','stop','draw','keyUpdate','GUI.AddToGUIUpdateList'}) do
            E.Hook.Remove(event,'bmt.vacuum.'..event)
        end
        for _,p in ipairs(G.patches) do E.Hook.RemovePatch(p[1],p[2],p[3],p[4]) end
    end
    return G
end
return M
