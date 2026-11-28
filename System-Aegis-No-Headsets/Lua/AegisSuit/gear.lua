local M={}
function M.install(G,E)
    if not G.authoritative then return end
    local class='Barotrauma.AIObjectiveGetItem'
    E.LuaUserData.MakePropertyAccessible(E.LuaUserData.RegisterType('Barotrauma.ItemPrefab'),'BotPriority')
    E.LuaUserData.MakeFieldAccessible(E.LuaUserData.RegisterType(class),'currentSearchIndex')
    local group='aegis.suit.locker-gear'
    E.Util.RegisterItemGroup(group,G.is)
    local lockerSearches=setmetatable({},{__mode='k'})
    local function lockerOf(item)
        local locker=not item.Removed and item.Container
        if locker and not item.ParentInventory.Locked and locker.HasTag('divingsuitcontainer') then return locker end
    end
    local function hasLockerGear(owner)
        local submarine=owner and owner.Submarine
        if not submarine then return false end
        for _,item in ipairs(E.Util.GetItemGroup(group)) do
            local locker=lockerOf(item)
            if locker and locker.Submarine and submarine.IsConnectedTo(locker.Submarine) and item.HasAccess(owner) then
                return true
            end
        end
        return false
    end
    local pathsField
    local search,nativePaths,prefab,priority
    local function restore()
        if not prefab then return end
        prefab.BotPriority=priority
        prefab,priority=nil,nil
    end
    local function finishSearch()
        restore()
        if search then search[pathsField]=nativePaths end
        search,nativePaths=nil,nil
    end
    G.patch('locker-search-start',class,'FindTargetItem',function(objective)
        if not objective.IsFindDivingGearSubObjective or not objective.Wear then return end
        if objective.currentSearchIndex==0 then lockerSearches[objective]=hasLockerGear(objective.character) end
        if not lockerSearches[objective] then return end
        pathsField=pathsField or (E.LuaUserData.HasMember(objective,'EvaluateAllItems')
            and 'EvaluateAllItems' or 'CheckPathForEachItem')
        search,nativePaths=objective,objective[pathsField]
        -- Let the native search check reachability before choosing a suit.
        -- Apply this only during the scan so Act can still check carried gear.
        objective[pathsField]=true
    end)
    G.patch('locker-search-end',class,'FindTargetItem',function(objective)
        if search==objective then finishSearch() end
    end,true)
    G.patch('locker-suit-candidate',class,'CheckItem',function(objective,p)
        if search~=objective or not p.ReturnValue then return end
        restore()
        local item=p['item']
        if not G.is(item) or not lockerOf(item) then return end
        -- The engine reads this weight immediately after checking the candidate.
        -- Restore it before scoring the next candidate, including another suit of this prefab.
        prefab=item.Prefab
        priority=prefab.BotPriority
        prefab.BotPriority=priority*40
    end,true)
    G.clearGear=finishSearch
end
return M
