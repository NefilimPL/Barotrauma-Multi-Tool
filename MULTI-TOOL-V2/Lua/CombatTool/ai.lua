local U=require('CombatTool.util')
local C=require('CombatTool.config')
local A={executing={}}
-- Follow only the selected chain. Queued orders never authorize an action.
function A.task(character,item)
    local scoped=A.executing[character]
    if scoped then return scoped.item==item and scoped.task or 'idle' end
    local manager=character.AIController and character.AIController.ObjectiveManager
    local node=manager and manager.CurrentObjective
    local task='idle'
    local depth=0
    while node and depth<24 do
        depth=depth+1
        local id=U.id(node)
        if id=='combat' then
            if node.Weapon~=item or not node.Enemy then return 'idle' end
            task='combat'
        elseif id=='fix leak' then task='weld'
        elseif id=='repair item' then task='repair'
        elseif id=='extinguish fire' then task='extinguish'
        elseif id=='operate item' then
            if node.Component and node.Component.Item~=item then return 'idle' end
            if task=='idle' and node.Component and node.Component.Name=='RepairTool' then
                if node.Component.ExtinguishAmount>0 then task='extinguish'
                elseif node.Component.StructureFixAmount<0 then task='cut'
                elseif node.Component.StructureFixAmount>0 then task='weld' end
            end
            if task=='idle' then return 'idle' end
        elseif id=='contain item' or id=='get item' or id=='go to' then return 'idle' end
        node=node.CurrentSubObjective
    end
    return task
end

function A.install(G,E)
    local function candidate(character,item)
        local best,score=nil,math.huge
        U.each(E.Item.ItemList,function(source)
            if source~=item and (source.HasTag('mobilebattery') or source.HasTag('reactorfuel')) and source.ConditionPercentage>=1 then
                local parent=source.ParentInventory and source.ParentInventory.Owner
                local allowed,depth=true,0
                -- Check the entire ownership chain, including bags in another
                -- person's inventory. Do not drain other tools or reactors.
                while parent and depth<16 do
                    depth=depth+1
                    if E.LuaUserData.IsTargetType(parent,'Barotrauma.Character') then
                        if parent~=character then allowed=false end
                        break
                    elseif E.LuaUserData.IsTargetType(parent,'Barotrauma.Item') then
                        if U.component(parent,'Reactor') or parent.HasTag('weapon') or parent.HasTag('tool') or parent==item then allowed=false end
                        parent=parent.ParentInventory and parent.ParentInventory.Owner
                    else break end
                end
                if allowed and source.HasAccess(character) and not source.Removed then
                    local d=source.WorldPosition-character.WorldPosition
                    local distance=d.LengthSquared()
                    if source.ParentInventory==character.Inventory then distance=-1 end
                    if distance<score and distance<4000*4000 then best,score=source,distance end
                end
            end
        end)
        return best
    end
    local function cancelResupply(s)
        -- Completing our own canceled container child lets its old parent
        -- remove it without abandoning an otherwise valid repair/idle order.
        if s.resupply then s.resupply.IsCompleted=true end
        s.resupply=nil;s.resupplyParent=nil;s.resupplyRoot=nil;s.resupplyDeadline=nil
        s.nextResupply=0
    end
    function A.resupply(character,item,slot,parent,minimum)
        if not character or not character.IsBot or G.canSpend(item,slot,minimum or 0.000001) or not parent then return false end
        local s=G.state(item)
        local manager=character.AIController.ObjectiveManager
        if s.resupply and not s.resupply.IsCompleted and not s.resupply.Abandon then
            local stale=(s.resupplyRoot or s.resupplyParent)~=(manager.CurrentObjective or parent)
                or (s.resupplyDeadline and G.now>s.resupplyDeadline)
            if stale or (slot==0 and s.resupplySlot==1) then cancelResupply(s)
            else return true end
        end
        if G.now<(s.nextResupply or 0) then return false end
        s.nextResupply=G.now+C.resupplyInterval
        local source=candidate(character,item)
        if not source then return false end
        local objective=E.AIObjectiveContainItem(character,source,U.component(item,'ItemContainer'),manager,1)
        objective.TargetSlot=slot
        objective.ItemCount=1
        objective.RemoveEmpty=false
        local previous=G.source(item,slot)
        if previous then
            -- LuaCs cannot marshal Func<Item,bool> for RemoveExistingPredicate.
            -- Clear only this slot using ordinary inventory movement instead;
            -- the source in the other slot must never be unequipped implicitly.
            if not character.Inventory.TryPutItem(previous.item,character,{E.InvSlotType.Any}) then
                previous.item.Drop(character)
            end
        end
        objective.MoveWholeStack=false
        objective.AllowStealing=false
        local deadline=G.now+C.resupplyTimeout
        objective.AbortCondition=function()
            return item.Removed or character.IsDead or item.ParentInventory~=character.Inventory
                or G.now>deadline or source.Removed
        end
        -- Containment with a specific item does not pathfind to that source.
        -- Fetch it first, keeping exact source identity and the other slot intact.
        if not character.CanInteractWith(source) then
            local fetch=E.AIObjectiveGetItem(character,source,manager,false)
            fetch.AllowStealing=false
            objective.AddSubObjective(fetch,true)
        end
        parent.AddSubObjective(objective,true)
        s.resupply=objective
        s.resupplyParent=parent;s.resupplyRoot=manager.CurrentObjective or parent
        s.resupplySlot=slot;s.resupplyDeadline=deadline
        return true
    end
    local function heldOrOwned(character,tag)
        return character.Inventory and character.Inventory.FindItemByTag(tag,true)
    end
    -- Leak AI hard-codes a welding-fuel tag in OwnInventory (the first
    -- container). Use its ordinary movement/operation objectives with electric
    -- power instead; hidden fuel probes would never satisfy that check.
    G.patch('ai-electric-welder','Barotrauma.AIObjectiveFixLeak','Act',function(o,p)
        local character=o.character
        local item=heldOrOwned(character,'weldingequipment')
        if not G.isWeapon(item) then return end
        p.PreventExecution=true
        if not G.canSpend(item,0,C.toolCost/60) then A.resupply(character,item,0,o,C.toolCost/60);return end
        local tool=U.component(item,'RepairTool')
        local reach=E.AIObjectiveFixLeak.CalculateReach(tool,character)
        local delta=o.Leak.WorldPosition-character.AnimController.AimSourceWorldPos
        local objective
        if delta.LengthSquared()>reach*reach then
            objective=E.AIObjectiveGoTo(o.Leak,character,o.objectiveManager)
            objective.UseDistanceRelativeToAimSourcePos=true
            objective.CloseEnough=reach*.9
        else
            objective=E.AIObjectiveOperateItem(tool,character,o.objectiveManager,E.Identifier.Empty,true,o.Leak)
        end
        objective.AbortCondition=function()
            return item.Removed or o.Leak.Removed or o.Leak.Open<=0 or not G.powered(item,0)
        end
        o.AddSubObjective(objective,true)
    end)
    for _,definition in ipairs({{'AIObjectiveExtinguishFire','fireextinguisher'}, {'AIObjectiveRepairItem','mechanicalrepairtool'}}) do
        G.patch('ai-fuel-'..definition[1],'Barotrauma.'..definition[1],'Act',function(o,p)
            local character=o.character
            local item=heldOrOwned(character,definition[2])
            if G.isWeapon(item) and not G.canSpend(item,0,C.toolCost/60) then
                A.resupply(character,item,0,o,C.toolCost/60)
                p.PreventExecution=true
            end
        end)
    end
    G.patch('ai-reload','Barotrauma.AIObjectiveCombat','Reload',function(o,p)
        if not G.isWeapon(o.Weapon) then return end
        p.PreventExecution=true
        if G.canSpend(o.Weapon,0,C.shotCost) then return true end
        A.resupply(o.character,o.Weapon,0,o,C.shotCost)
        return false
    end)
    G.patch('ai-priority','Barotrauma.AIObjectiveCombat','GetWeaponPriority',function(o,p)
        local component=p['weapon']
        if component and G.isWeapon(component.Item) and not G.flags(component.Item).damage then
            p.PreventExecution=true
            return 0
        end
    end)
    -- Concurrent combat can execute while a repair order remains selected.
    -- Scope permission to the actual weapon operation, never just the order queue.
    G.patch('ai-combat-enter','Barotrauma.AIObjectiveCombat','UseWeapon',function(o,p)
        if G.isWeapon(o.Weapon) then A.executing[o.character]={item=o.Weapon,task='combat'} end
    end)
    G.patch('ai-combat-leave','Barotrauma.AIObjectiveCombat','UseWeapon',function(o,p)
        A.executing[o.character]=nil
    end,true)
    function A.update(s,ctx)
        if not ctx.bot or not ctx.owner or ctx.owner.Removed or ctx.owner.IsDead then return end
        local manager=ctx.owner.AIController.ObjectiveManager
        local parent=manager.CurrentObjective
        if s.resupply and not s.resupply.IsCompleted and
            ((s.resupplyDeadline and G.now>s.resupplyDeadline) or s.resupplyRoot~=parent) then cancelResupply(s) end
        if not G.canSpend(s.item,0,C.toolCost/60) then A.resupply(ctx.owner,s.item,0,parent,C.toolCost/60)
        elseif ctx.mode~='combat' and ctx.mode=='idle' and ctx.damage then
            A.resupply(ctx.owner,s.item,1,parent)
        end
    end
end
return A
