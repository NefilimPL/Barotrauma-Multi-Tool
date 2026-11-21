local C=require('AegisSuit.config')
local Factions=require('AegisSuit.factions')
local M={}
function M.install(G,E)
    function G.module(item,kind)
        local slot=kind=='servo' and C.servoSlot or kind=='impeller' and C.impellerSlot or nil
        if not slot then return nil end
        local inv=G.container(item,1)
        local part=inv and inv.GetItemAt(slot)
        if part and not part.Removed and part.Condition>0 and Factions.is(part,kind) then return part end
    end
    function G.hasArm(item) return G.module(item,'servo')~=nil end
    function G.hasImpeller(item) return G.module(item,'impeller')~=nil end
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
