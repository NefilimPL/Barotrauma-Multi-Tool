local U=require('CombatTool.util')
local M={}
local profiles={
    pulselaserammobox={projectile='descendantpulsebolt',nativeCost=2.25},
    pulselaserammoboxtrilaser={projectile='descendanttribolt',nativeCost=3.5},
    coilgunammobox={projectile='descendantgaussbolt',nativeCost=.5,ballistic=true},
    physicoriumammobox={projectile='descendantphysicoriumbolt',nativeCost=.5,ballistic=true},
    coilgunammoboxexplosive={projectile='descendantexplosivebolt',nativeCost=1,ballistic=true},
    coilgunammoboxpiercing={projectile='descendantpiercingbolt',nativeCost=.67,ballistic=true},
}

function M.profile(box)
    if box and not box.Removed and box.MaxCondition>0 then return profiles[U.itemId(box)] end
end

function M.status(box,profile)
    if not profile then return 0 end
    local capacity=3*math.floor(box.MaxCondition/profile.nativeCost)
    if capacity==0 then return 0 end
    local cost=box.MaxCondition/capacity
    local shots=box.Condition/cost
    -- Condition crosses a native float boundary. Snap to a whole shot only
    -- within that precision so repeated debits do not accumulate rounding error.
    local nearest=math.floor(shots+.5)
    if math.abs(shots-nearest)<=math.max(1,nearest)*.0000001 then shots=nearest end
    return math.floor(shots),cost,shots*cost
end

return M
