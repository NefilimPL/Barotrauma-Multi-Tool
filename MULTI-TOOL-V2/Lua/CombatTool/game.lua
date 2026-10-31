local Core=require('CombatTool.core')
local C=Core.config
local U=require('CombatTool.util')
local AI=require('CombatTool.ai')
local Module={}
function Module.new(E)
    E=E or _G
    local G={states={},now=0,frame=0,patches={},env=E}
    function G.isWeapon(item) return item and not item.Removed and U.itemId(item)==C.identifier end
    function G.state(item)
        local s=G.states[item]
        if not s then
            s={item=item,mode='idle',brokenUntil=0,nextShot=0,contactTimes={},lastUseFrame=-100,lastToolFrame=-100}
            G.states[item]=s
        end
        return s
    end
    function G.flags(item)
        local cutter,ext,damage=U.component(item,'Pump'),U.component(item,'Controller'),U.component(item,'LightComponent')
        return {cutter=cutter and cutter.IsOn or false,extinguisher=ext and ext.State or false,damage=damage and damage.IsOn or false}
    end
    function G.source(item,slot)
        local source=item.OwnInventory and item.OwnInventory.GetItemAt(slot)
        if not source or source.Removed or source.MaxCondition<=0 then return nil end
        if not source.HasTag('mobilebattery') and not source.HasTag('reactorfuel') then return nil end
        return {item=source,condition=source.Condition/source.MaxCondition*100,
            multiplier=source.HasTag('reactorfuel') and C.rodMultiplier or 1}
    end
    function G.powered(item,slot) local source=G.source(item,slot);return source~=nil and source.condition>0 end
    function G.canSpend(item,slot,cost)
        local source=G.source(item,slot)
        return source~=nil and source.condition>0 and source.condition+1e-7>=cost*source.multiplier
    end
    function G.spend(item,slot,cost)
        local source=G.source(item,slot)
        if not Core.spend(source,cost) then return false end
        source.item.Condition=source.condition*source.item.MaxCondition/100
        return true
    end
    function G.shieldDebit(item,cost)
        local source=G.source(item,1)
        local blocked,broken=Core.shieldHit(source,cost)
        if source then source.item.Condition=source.condition*source.item.MaxCondition/100 end
        return blocked,broken
    end
    function G.owner(item)
        local owner=item.ParentInventory and item.ParentInventory.Owner
        return owner and E.LuaUserData.IsTargetType(owner,'Barotrauma.Character') and owner or nil
    end
    function G.context(item,character)
        local ctx=G.flags(item)
        local owner=character or G.owner(item)
        ctx.owner=owner
        ctx.bot=owner and owner.IsBot or false
        ctx.valid=false
        if owner and not owner.Removed and not owner.IsDead and not owner.IsUnconscious and item.Condition>0 then
            local inv=owner.Inventory
            ctx.valid=inv and inv.GetItemInLimbSlot(E.InvSlotType.RightHand)==item
                and inv.GetItemInLimbSlot(E.InvSlotType.LeftHand)==item or false
            ctx.aim=owner.IsKeyDown(E.InputType.Aim)
            ctx.repairing=false
            if owner.SelectedItem then
                U.each(owner.SelectedItem.Repairables,function(r) if r.CurrentFixer==owner then ctx.repairing=true end end)
            end
            ctx.task=ctx.bot and AI.task(owner,item) or nil
        end
        ctx.mode=Core.mode(ctx)
        return ctx
    end
    function G.transition(s,ctx,passive)
        if s.owner~=ctx.owner or (not passive and s.mode~=ctx.mode) then s.chargeStarted=nil end
        if s.owner~=ctx.owner then
            s.shield=nil;s.contactTimes={}
            if s.resupply then s.resupply.Abandon=true;s.resupply=nil end
        end
        if s.damage and not ctx.damage then
            s.chargeStarted=nil;s.shield=nil
            if G.cancelRings then G.cancelRings(s.item) end
        end
        s.owner,s.damage=ctx.owner,ctx.damage
        if not passive then s.mode=ctx.mode end
    end
    function G.use(component,character,dt)
        local item=component.Item
        local s,ctx=G.state(item),G.context(item,character)
        G.transition(s,ctx,true)
        if not ctx.valid or not ctx.aim then s.chargeStarted=nil;return false end
        if component.Name:lower()=='rangedweapon' then
            if ctx.mode~='combat' or not ctx.damage or not G.canSpend(item,0,C.shotCost) then return false end
            s.lastCombatIntentFrame=G.frame
            if not G.claimAction(s,ctx.mode) then return false end
            G.transition(s,ctx)
            s.lastUseFrame=G.frame
            if G.now<s.nextShot then return false end
            if not s.chargeStarted then
                s.chargeStarted=G.now
                if G.event then G.event('charge',s,G.muzzle and G.muzzle(item) or item.WorldPosition) end
                return false
            end
            if G.now-s.chargeStarted<C.chargeTime then return false end
            if G.rings and #G.rings>=C.maxRings then return false end
            if G.fire and G.spend(item,0,C.shotCost) then
                s.nextShot=G.now+C.reloadTime;s.chargeStarted=nil
                G.fire(s,ctx)
                return true
            end
            return false
        end
        local chosen=G.toolComponent(item,ctx.mode)
        if not chosen or s.lastToolFrame==G.frame then return false end
        if component~=chosen then
            -- Native fire/leak objectives request the first RepairTool. Redirect
            -- to the selected one once; Item.Use also enumerates all components.
            if ctx.bot and component==U.component(item,'RepairTool') then chosen.Use(dt,character) end
            return false
        end
        if not G.claimAction(s,ctx.mode) then return false end
        G.transition(s,ctx)
        if not G.spend(item,0,C.toolCost*math.min(dt or 1/60,.1)) then return false end
        s.lastToolFrame=G.frame
        return true
    end
    function G.claimAction(s,mode)
        if s.actionFrame==G.frame and s.actionMode~=mode then return false end
        s.actionFrame=G.frame;s.actionMode=mode
        return true
    end
    function G.toolComponent(item,mode)
        local index=mode=='weld' and 1 or mode=='cut' and 2 or mode=='extinguish' and 3 or nil
        return index and U.component(item,'RepairTool',index) or nil
    end
    function G.patch(name,class,method,fn,after,types)
        local id='bmt.combat.'..name
        local phase=after and E.Hook.HookMethodType.After or E.Hook.HookMethodType.Before
        if types then E.Hook.Patch(id,class,method,types,fn,phase)
        else E.Hook.Patch(id,class,method,fn,phase) end
        G.patches[#G.patches+1]={id,class,method,phase,types}
    end
    function G.cleanup()
        G.states={}
        AI.executing={}
        if G.clearProjectiles then G.clearProjectiles() end
        if G.clearShieldTracking then G.clearShieldTracking() end
        if G.clearVisuals then G.clearVisuals() end
    end
    function G.dispose()
        G.cleanup()
        if G.disposeDiagnostics then G.disposeDiagnostics() end
        if E.Hook and E.Hook.Remove then
            E.Hook.Remove('think','bmt.combat.update')
            E.Hook.Remove('roundEnd','bmt.combat.reset')
            E.Hook.Remove('draw','bmt.combat.draw')
        end
        for _,patch in ipairs(G.patches) do
            if patch[5] then E.Hook.RemovePatch(patch[1],patch[2],patch[3],patch[5],patch[4])
            else E.Hook.RemovePatch(patch[1],patch[2],patch[3],patch[4]) end
        end
        G.patches={}
    end
    return G
end
return Module
