local U=require('CombatTool.util')
local M={}
function M.plan(E,item,vacuum,random)
    if not item.AllowDeconstruct or item.MaxCondition<=0 then return nil end
    random=random or math.random
    local entries,unsupported={},false
    U.each(item.Prefab.DeconstructItems,function(r)
        local other=false;U.each(r.RequiredOtherItem,function() other=true end)
        if other then unsupported=true;return end
        if not r.IsValidDeconstructor(vacuum) then unsupported=true;return end
        local condition=item.Condition/item.MaxCondition
        if condition>=r.MinCondition and condition<=r.MaxCondition then entries[#entries+1]=r end
    end)
    -- Refining/combining recipes require their native machine; never fake them.
    if unsupported or #entries==0 then return nil end
    if item.Prefab.RandomDeconstructionOutput then
        local chosen={}
        for i=1,math.min(#entries,item.Prefab.RandomDeconstructionOutputAmount) do
            local total=0;for _,r in ipairs(entries) do total=total+math.max(0,r.Commonness) end
            if total<=0 then break end
            local roll,index=random()*total,#entries
            for j,r in ipairs(entries) do roll=roll-math.max(0,r.Commonness);if roll<=0 then index=j;break end end
            chosen[#chosen+1]=table.remove(entries,index)
        end
        entries=chosen
    end
    local out={}
    for _,r in ipairs(entries) do
        local id=tostring(r.ItemIdentifier)
        local prefab=E.ItemPrefab.Prefabs[id]
        if not prefab or r.Amount<0 or r.Amount>1000 or #out+r.Amount>10000 then return nil end
        local fraction=r.CopyCondition and item.Condition/item.MaxCondition*r.OutConditionMax
            or r.OutConditionMin+random()*(r.OutConditionMax-r.OutConditionMin)
        for i=1,r.Amount do out[#out+1]={kind=id,prefab=prefab,condition=prefab.Health*fraction} end
    end
    return #out>0 and out or nil
end
return M
