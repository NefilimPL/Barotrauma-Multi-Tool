local U=require('AegisCombat.util')
local M={}
function M.new(E)
    local descriptor=E.LuaUserData.RegisterType('Barotrauma.Items.Components.CustomInterface')
    E.LuaUserData.MakeFieldAccessible(descriptor,'uiElements')
    local R={}
    local function controls(item)
        local component=U.component(item,'CustomInterface')
        if not component then return end
        local widgets={};U.each(component.uiElements,function(w) widgets[#widgets+1]=w end)
        if #widgets<3 then return end
        return widgets,component
    end
    local function set(widget,value)
        -- The native Selected setter invokes CustomInterface's original
        -- prediction, property update and client event. Never mutate properties
        -- or synthesize an unvalidated control packet from this panel.
        if widget.Selected~=value then widget.Selected=value end
    end
    function R.flags(item)
        local widgets=controls(item)
        if not widgets then return end
        return {cutter=widgets[1].Selected,extinguisher=widgets[2].Selected,damage=widgets[3].Selected}
    end
    function R.setMode(item,mode)
        if mode~='weld' and mode~='cut' and mode~='extinguish' and mode~='combat' then return false end
        local combat=U.itemId(item)=='aegiscombattool'
        if mode=='combat' and not combat then return false end
        local widgets=controls(item)
        if not widgets then return false end
        set(widgets[1],mode=='cut');set(widgets[2],mode=='extinguish')
        if combat then set(widgets[3],mode=='combat') end
        return true
    end
    function R.setDamage(item,value)
        local widgets=controls(item)
        if not widgets then return false end
        set(widgets[3],value==true);return true
    end
    function R.refresh(item,owner,dt,cam)
        local _,component=controls(item)
        if not component then return false end
        component.UpdateHUDComponentSpecific(owner,dt,cam)
        if component.GuiFrame then
            component.GuiFrame.Visible=false;component.GuiFrame.RemoveFromGUIUpdateList()
        end
        return true
    end
    return R
end
return M
