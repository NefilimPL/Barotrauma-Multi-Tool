local U=require('CombatTool.util')
local C=require('CombatTool.config')
local AI=require('CombatTool.ai')
local M={}
function M.install(G,E)
    local both=E.LuaUserData.CreateEnumTable('Barotrauma.Items.Components.RepairTool+UseEnvironment').Both
    local function activate(item)
        G.state(item)
        U.each(item.Components,function(c)
            if c.Name:lower()=='repairtool' then c.UsableIn=both;c.CharacterUsable=true end
        end)
    end
    G.patch('ranged-use','Barotrauma.Items.Components.RangedWeapon','Use',function(component,p)
        if not G.isWeapon(component.Item) then return end
        p.PreventExecution=true
        if G.authoritative then return G.use(component,p['character'],p['deltaTime']) end
        return false
    end)
    G.patch('tool-use','Barotrauma.Items.Components.RepairTool','Use',function(component,p)
        if not G.isWeapon(component.Item) then return end
        if G.authoritative then
            if not G.use(component,p['character'],p['deltaTime']) then p.PreventExecution=true;return false end
        else
            local ctx=G.context(component.Item,p['character'])
            if not ctx.valid or not ctx.aim or component~=G.toolComponent(component.Item,ctx.mode) then
                p.PreventExecution=true;return false
            end
        end
    end)
    G.patch('empty','Barotrauma.Items.Components.ItemComponent','IsEmpty',function(component,p)
        if G.isWeapon(component.Item) and (component.Name:lower()=='rangedweapon' or component.Name:lower()=='repairtool') then
            p.PreventExecution=true
            if component.Name:lower()=='rangedweapon' then return not G.canSpend(component.Item,0,C.shotCost) end
            return not G.powered(component.Item,0)
        end
    end)
    G.patch('contained','Barotrauma.Items.Components.ItemComponent','HasRequiredContainedItems',function(component,p)
        if G.isWeapon(component.Item) and (component.Name:lower()=='rangedweapon' or component.Name:lower()=='repairtool') then
            p.PreventExecution=true;return G.powered(component.Item,0)
        end
    end)
    local repairableDescriptor=E.LuaUserData.RegisterType('Barotrauma.Items.Components.Repairable')
    E.LuaUserData.MakeFieldAccessible(repairableDescriptor,'currentRepairItem')
    if G.authoritative then
        G.patch('device-repair','Barotrauma.Items.Components.Repairable','Update',function(repairable,p)
            local item=repairable.currentRepairItem
            local character=repairable.CurrentFixer
            if not character or not G.isWeapon(item) then return end
            local ctx=G.context(item,character)
            local s=G.state(item)
            if character.IsBot and (s.lastCombatIntentFrame or -100)>=G.frame-1 then
                repairable.StopRepairing(character);return
            end
            if not ctx.valid or ctx.mode~='repair' or not G.powered(item,0) or not G.claimAction(s,'repair') then
                repairable.StopRepairing(character);return
            end
            if s.lastRepairFrame~=G.frame then
                if not G.spend(item,0,C.toolCost*math.min(p['deltaTime'],.1)) then repairable.StopRepairing(character);return end
                s.lastRepairFrame=G.frame
            end
            G.transition(s,ctx)
        end)
        AI.install(G,E)
    end
    local scanAt=0
    function G.update(dt)
        G.now=G.now+dt;G.frame=G.frame+1
        if G.now>=scanAt then
            scanAt=G.now+.5
            U.each(E.Item.ItemList,function(item) if G.isWeapon(item) then activate(item) end end)
            if G.pruneShieldTracking then G.pruneShieldTracking() end
        end
        for item,s in pairs(G.states) do
            if item.Removed then
                if s.resupply then s.resupply.Abandon=true end
                G.states[item]=nil
            else
                local ctx=G.context(item)
                G.transition(s,ctx,true)
                if not ctx.valid or not ctx.aim or s.lastUseFrame<G.frame-2 then s.chargeStarted=nil end
                local light=U.component(item,'LightComponent',2)
                local lit=ctx.valid and ctx.aim and G.powered(item,0)
                if G.authoritative and lit then lit=G.spend(item,0,C.lightCost*dt) end
                if light then light.IsOn=lit;light.IsActive=lit end
                if G.authoritative then
                    G.updateShield(s,ctx,dt)
                    AI.update(s,ctx)
                end
            end
        end
        if G.authoritative then G.updateRings(dt);G.sendSnapshot() end
        if G.updateVisuals then G.updateVisuals(dt) end
    end
    E.Hook.Add('think','bmt.combat.update',function() G.update(1/60) end)
    E.Hook.Add('roundEnd','bmt.combat.reset',function()
        G.cleanup();if G.clearShieldTracking then G.clearShieldTracking() end
        if G.clearVisuals then G.clearVisuals() end
    end)
end
return M
