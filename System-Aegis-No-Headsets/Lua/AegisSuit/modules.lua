local C=require('AegisSuit.config')
local Factions=require('AegisSuit.factions')
local U=require('AegisCombat.util')
local M={}
local slots={servo=C.servoSlot,impeller=C.impellerSlot,compressor=C.compressorSlot}
function M.matches(part,kind)
    if not part or part.Removed then return false end
    if kind=='compressor' then return U.itemId(part)=='aegiscompressormodule' end
    return Factions.is(part,kind)
end
function M.is(part,kind)
    return M.matches(part,kind) and part.Condition>0
end
function M.install(G,E)
    function G.module(item,kind)
        local slot=slots[kind]
        if not slot then return nil end
        local inv=G.container(item,1)
        local part=inv and inv.GetItemAt(slot)
        if M.is(part,kind) then return part end
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
