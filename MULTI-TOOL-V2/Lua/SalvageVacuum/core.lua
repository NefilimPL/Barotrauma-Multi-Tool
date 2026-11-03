local C=require('SalvageVacuum.config')
local M={config=C}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.groups(items)
    local out,buckets={},{}
    for _,item in ipairs(items) do
        local key=item.kind
        local group=buckets[key]
        if not group or #group.items>=C.groupSize then
            group={kind=key,items={}};buckets[key]=group;out[#out+1]=group
        end
        group.items[#group.items+1]=item
    end
    return out
end
function M.canFit(items,additional)
    local counts={}
    for _,list in ipairs({items,additional}) do
        for _,item in ipairs(list) do counts[item.kind]=(counts[item.kind] or 0)+1 end
    end
    local groups=0
    for _,count in pairs(counts) do groups=groups+math.ceil(count/C.groupSize) end
    return groups<=C.groups
end
function M.canAccept(items,item) return M.canFit(items,{item}) end
function M.snapshot(items,children)
    local out,seen={},{}
    local function visit(item)
        if seen[item] then return end
        seen[item]=true
        for _,child in ipairs(children(item)) do visit(child) end
        out[#out+1]=item
    end
    for _,item in ipairs(items) do visit(item) end
    return out
end
function M.debit(energy,cost)
    if not finite(energy) or not finite(cost) or cost<0 or energy<cost or energy<=0 then return energy,false end
    return energy-cost,true
end
function M.inCone(origin,direction,target)
    local x,y=target.x-origin.x,target.y-origin.y
    if not finite(x) or not finite(y) then return false end
    local distance=math.sqrt(x*x+y*y)
    return distance<=C.range and (distance<.001 or (x*direction.x+y*direction.y)/distance>=math.cos(C.halfAngle))
end
function M.supportedRecipe(recipe)
    return recipe and not recipe.requiresOther and recipe.outputs and #recipe.outputs>0 or false
end
return M
