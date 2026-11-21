local U=require('AegisCombat.util')
local C=require('AegisSuit.config')
local M={}
function M.install(G,E)
    function G.updateDocked(item,dt)
        if not G.authoritative or item.Removed then return false end
        local holder=item.ParentInventory and item.ParentInventory.Owner
        if not holder or not E.LuaUserData.IsTargetType(holder,'Barotrauma.Item') or holder.Removed or
            not holder.HasTag('divingsuitcontainer') or holder.Condition<=0 then return false end
        local powered=U.component(holder,'Powered')
        if not powered or not powered.IsActive or powered.Voltage<=.1 then return false end
        local source=G.source(item)
        if not source or source.Condition>=source.MaxCondition then return false end
        source.Condition=math.min(source.MaxCondition,source.Condition+source.MaxCondition*C.dockChargeRate/100*dt)
        return true
    end
end
return M
