local C=require('AegisHeadset.config')
local Core=require('AegisHeadset.core')
local M={}
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<math.huge end

function M.new()
    -- Keep native cells referenced until removed: a weak userdata key could
    -- disappear between frames while its physical item is still in the game.
    local sources={}
    local ledger={}
    function ledger.reserve(cell,now,energy,cost)
        local payment={cell=cell,amount=0,fraction=0}
        if not cell or not finite(energy) or energy<=0 or not finite(cost) or cost<=0 then return payment end
        local budget=sources[cell]
        if not budget then
            budget={available=C.powerBurst,time=now,reserved=0};sources[cell]=budget
        end
        budget.available=math.min(C.powerBurst,budget.available+math.max(0,now-budget.time)*C.powerRate)
        budget.time=math.max(budget.time,now)
        payment.budget=budget
        local available=math.max(0,energy-budget.reserved)
        if available<=0 then return payment end
        local price=math.min(cost,math.max(0,budget.available))
        if price<=0 then payment.fraction=1;return payment end
        local left,fraction=Core.debit(available,price)
        payment.amount=available-left;payment.fraction=fraction
        budget.available=math.max(0,budget.available-payment.amount)
        budget.reserved=budget.reserved+payment.amount
        return payment
    end
    function ledger.finish(payment,used)
        if payment.finished then return 0 end
        payment.finished=true
        used=finite(used) and math.max(0,math.min(payment.amount,used)) or 0
        if payment.budget then
            local budget=payment.budget
            budget.reserved=math.max(0,budget.reserved-payment.amount)
            budget.available=math.min(C.powerBurst,budget.available+payment.amount-used)
        end
        payment.used=used
        return used
    end
    function ledger.refund(payment)
        local used=payment.used or 0
        if payment.budget then
            payment.budget.available=math.min(C.powerBurst,payment.budget.available+used)
        end
        payment.used=0
        return used
    end
    function ledger.prune()
        for cell in pairs(sources) do if cell.Removed then sources[cell]=nil end end
    end
    return ledger
end
return M
