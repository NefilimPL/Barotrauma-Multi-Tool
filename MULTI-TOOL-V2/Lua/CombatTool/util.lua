local U={}
function U.each(collection,fn)
    if not collection then return end
    if type(collection)=='table' then for _,value in ipairs(collection) do fn(value) end
    else for value in collection do fn(value) end end
end
function U.id(entity)
    if not entity then return '' end
    local id=entity.Identifier
    return id and tostring(id.Value or id):lower() or ''
end
function U.itemId(item)
    return item and item.Prefab and tostring(item.Prefab.Identifier.Value):lower() or ''
end
function U.powerSources(E)
    local api=E.Util
    -- Share state across the headset's and combat autorun's module instances.
    local state=api.__bmtPowerSources
    if not state then
        state={pending={}};api.__bmtPowerSources=state
        -- LuaCs adds new items to registered groups and clears them at round end.
        -- Build once, rather than walking the entire level for every low-power bot.
        api.RegisterItemGroup('bmt.powerSources',function(item)
            return not item.Removed and (item.HasTag('mobilebattery') or item.HasTag('reactorfuel'))
        end)
        E.Hook.Add('roundEnd','bmt.sources.clear',function() state.pending={} end)
        for _,change in ipairs({
            {'AddTag','tag',{'Barotrauma.Identifier'}},
            {'ReplaceTag','newTag',{'Barotrauma.Identifier','Barotrauma.Identifier'}},
            {'set_Tags','value',{'System.String'}},
        }) do
            E.Hook.Patch('bmt.sources.'..change[1],'Barotrauma.Item',change[1],change[3],function(item,p)
                for tag in tostring(p[change[2]] or ''):lower():gmatch('[^,]+') do
                    tag=tag:match('^%s*(.-)%s*$')
                    if tag=='mobilebattery' or tag=='reactorfuel' then state.pending[item]=true end
                end
            end,E.Hook.HookMethodType.After)
        end
    end
    local sources=api.GetItemGroup('bmt.powerSources')
    local known
    if next(state.pending) then
        known={};for _,source in ipairs(sources) do known[source]=true end
    end
    for item in pairs(state.pending) do
        state.pending[item]=nil
        if not item.Removed and (item.HasTag('mobilebattery') or item.HasTag('reactorfuel')) then
            -- Defer until after item.created so changes during construction cannot duplicate entries.
            if not known[item] then sources[#sources+1]=item;known[item]=true end
        end
    end
    return sources
end
function U.reservedHeadsetCell(E,cell)
    local owner=cell and cell.ParentInventory and cell.ParentInventory.Owner
    return owner and E.LuaUserData.IsTargetType(owner,'Barotrauma.Item') and owner.HasTag('aegisheadset') or false
end
function U.component(item,name,index)
    local result,n=nil,0
    U.each(item and item.Components,function(c)
        if tostring(c.Name):lower()==name:lower() then
            n=n+1;if n==(index or 1) then result=c end
        end
    end)
    return result
end
function U.point(v) return {x=v.X,y=v.Y} end
return U
