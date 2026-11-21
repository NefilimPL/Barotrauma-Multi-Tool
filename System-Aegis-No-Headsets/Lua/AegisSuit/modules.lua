local C=require('AegisSuit.config')
local U=require('AegisCombat.util')
local M={}
function M.install(G,E)
    local function present(item,slot,id)
        local inv=G.container(item,1)
        local part=inv and inv.GetItemAt(slot)
        return part~=nil and not part.Removed and part.Condition>0 and U.itemId(part)==id
    end
    function G.hasArm(item) return present(item,C.servoSlot,C.servoModule) end
    function G.hasImpeller(item) return present(item,C.impellerSlot,C.impellerModule) end
    function G.updateModules(item,s)
        s.hasArm=G.hasArm(item);s.hasImpeller=G.hasImpeller(item)
        if not s.hasArm then
            if G.releaseGrip then G.releaseGrip(s) end
            s.target=nil;s.active=false;s.acquireGrab=nil;s.mode='off'
        end
        if not s.hasImpeller then s.swimming=false end
    end
end
return M
