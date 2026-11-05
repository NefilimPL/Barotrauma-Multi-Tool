local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local class='Barotrauma.Items.Components.Fabricator'
    local descriptor=E.LuaUserData.RegisterType(class)
    E.LuaUserData.MakeFieldAccessible(descriptor,'availableIngredients')
    E.LuaUserData.MakeFieldAccessible(descriptor,'user')
    -- Register only this dictionary: unregistered dictionaries are copied to Lua.
    -- Keep List<Item> conversions unchanged for the rest of LuaCs and other mods.
    local assembly=E.SERVER and 'DedicatedServer' or 'Barotrauma'
    E.LuaUserData.RegisterType('System.Collections.Generic.Dictionary`2[[Barotrauma.Identifier, BarotraumaCore],[System.Collections.Generic.List`1[[Barotrauma.Item, '..assembly..']], System.Private.CoreLib]]')
    local function usable(pack,character)
        if G.jobs[pack] or G.pending[pack] or not pack.OwnInventory or pack.OwnInventory.Locked then return false end
        local node,seen=pack,{}
        while node and not seen[node] do
            seen[node]=true
            if character and node.HasAccess and not node.HasAccess(character) then return false end
            local inv=node.ParentInventory
            if not inv then break end
            if inv.Locked then return false end
            local parent=inv.Owner
            if E.LuaUserData.IsTargetType(parent,'Barotrauma.Character') then
                if character and parent~=character then return false end
                break
            end
            if not E.LuaUserData.IsTargetType(parent,'Barotrauma.Item') then return false end
            node=parent
        end
        for _,container in pairs(G.materialContainers(pack)) do
            if character and container.HasAccess and not container.HasAccess(character) then return false end
            if container.OwnInventory and container.OwnInventory.Locked then return false end
            local locked=false
            U.each(container.Components,function(component)
                if tostring(component.Name):lower()=='itemcontainer' and component.Inventory and component.Inventory.Locked then locked=true end
            end)
            if locked then return false end
        end
        return true
    end
    function G.refreshCrafting(fabricator)
        local dictionary=fabricator.availableIngredients
        local character=fabricator.user or E.Character.Controlled
        local forbidden,additions={},{}
        local function forbid(kind,id)
            forbidden[kind]=forbidden[kind] or {};forbidden[kind][id]=true
        end
        local worn=character and character.Inventory and character.Inventory.GetItemInLimbSlot(E.InvSlotType.Bag)
        local packs,seen={},{}
        if dictionary.ContainsKey(C.pack) then U.each(dictionary[C.pack],function(pack)
            if not seen[pack] then packs[#packs+1]=pack;seen[pack]=true end
        end) end
        if G.is(worn,C.pack) and not seen[worn] then packs[#packs+1]=worn end
        local canUseWorn=character and not character.IsDead and not character.IsUnconscious
            and character.CanInteract~=false and character.SelectedItem==fabricator.Item
        local expanded=false
        if G.is(worn,C.pack) and dictionary.ContainsKey(C.page) then
            U.each(dictionary[C.page],function(page) if G.has(worn,page) then expanded=true end end)
        end
        for _,pack in ipairs(packs) do
            local allowed=usable(pack,character)
            if not allowed or (pack==worn and canUseWorn and not expanded) then
                for _,record in ipairs(G.materialRecords(pack)) do
                    if not allowed then forbid(record.kind,record.id)
                    else
                        additions[record.kind]=additions[record.kind] or {}
                        additions[record.kind][#additions[record.kind]+1]=record.item
                    end
                end
            end
        end
        -- Pending products may already have moved to a machine input; keep them reserved too.
        for item in pairs(G.reserved) do if not item.Removed then forbid(G.id(item),item.ID) end end
        for _,tx in pairs(G.pending) do
            for _,product in ipairs(tx.products or {}) do if not product.Removed then forbid(G.id(product),product.ID) end end
        end
        local kinds={};for kind in pairs(forbidden) do kinds[kind]=true end
        for kind in pairs(additions) do kinds[kind]=true end
        for kind in pairs(kinds) do
            local merged={}
            if dictionary.ContainsKey(kind) then U.each(dictionary[kind],function(item)
                if not forbidden[kind] or not forbidden[kind][item.ID] then merged[#merged+1]=item end
            end) end
            for _,item in ipairs(additions[kind] or {}) do
                if not forbidden[kind] or not forbidden[kind][item.ID] then merged[#merged+1]=item end
            end
            dictionary[kind]=merged
        end
    end
    G.patch('fabricator-materials',class,'RefreshAvailableIngredients',function(fabricator) G.refreshCrafting(fabricator) end,true)
end
return M
