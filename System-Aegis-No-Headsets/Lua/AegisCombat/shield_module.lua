local C=require('AegisCombat.config')
local U=require('AegisCombat.util')
local M={}
function M.install(G,E)
    function G.shieldModule(item)
        local inv=item and item.OwnInventory
        local part=inv and inv.GetItemAt(C.shieldModuleSlot)
        if part and not part.Removed and part.MaxCondition>0 and U.itemId(part)==C.shieldModule then return part end
    end
    function G.shieldCharges(item)
        local part=G.shieldModule(item)
        if not part then return 0 end
        return math.max(0,math.min(C.shieldCharges,math.floor(part.Condition/part.MaxCondition*C.shieldCharges+1e-4)))
    end
    function G.consumeShieldCharge(item)
        local part=G.shieldModule(item)
        if not part or G.shieldCharges(item)<1 then return false end
        part.Condition=math.max(0,part.Condition-part.MaxCondition/C.shieldCharges)
        return true
    end
    function G.updateShieldModule(item,dt)
        if not G.authoritative or dt<=0 or E.Game.Paused or item.Removed or item.Condition<=0 or not G.powered(item,0) then return end
        local part=G.shieldModule(item)
        if part and part.Condition<part.MaxCondition then
            -- Condition holds partial recharge too: no reset/refill on transfer or save.
            part.Condition=math.min(part.MaxCondition,part.Condition+part.MaxCondition/C.shieldCharges*dt/C.shieldRechargeSeconds)
        end
    end
end
return M
