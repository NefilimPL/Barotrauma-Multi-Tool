local C=require('AegisHeadset.config')
local M={}
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<math.huge end
function M.debit(energy,cost)
    energy=finite(energy) and math.max(0,energy) or 0
    if not finite(cost) or cost<=0 then return energy,0 end
    local paid=math.min(energy,cost)
    return math.max(0,energy-paid),paid/cost
end
function M.absorb(energy,damage)
    if not finite(damage) or damage<=0 then return energy,0 end
    local remaining,fraction=M.debit(energy,math.max(C.hitMinimum,damage*C.hitMultiplier))
    return remaining,damage*(1-fraction)
end
function M.advanceJob(job,energy,dt,cost,seconds)
    local requested=math.min(math.max(0,cost-(job.paid or 0)),cost*math.max(0,dt)/seconds)
    if requested>0 then
        local left,fraction=M.debit(energy,requested)
        job.paid=(job.paid or 0)+requested*fraction
        energy=left
    end
    return energy,(job.paid or 0)>=cost-1e-6
end
return M
