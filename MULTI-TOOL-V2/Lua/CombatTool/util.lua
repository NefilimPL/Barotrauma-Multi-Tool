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
