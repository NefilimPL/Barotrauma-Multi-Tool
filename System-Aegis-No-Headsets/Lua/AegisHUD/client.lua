local U=require('AegisCombat.util')
local Model=require('AegisHUD.model')
local M={}
function M.install(E)
    local UI=E.GUI;local canvas=UI.GUI.Canvas
    local R=require('AegisHUD.controls').new(E)
    local H={open=true,buttons={}}
    -- DrawHudWhenEquipped also authorizes native multiplayer events. Keep it
    -- enabled in XML; suppress only the old client's independent HUD.
    local nativeClass,nativeMethod='Barotrauma.Items.Components.ItemComponent','ShouldDrawHUD'
    local nativePhase=E.Hook.HookMethodType.Before
    E.Hook.Patch('aegis.hud.native',nativeClass,nativeMethod,function(component,p)
        local id=U.itemId(component.Item)
        if tostring(component.Name):lower()=='custominterface' and
            (id=='aegiscombattool' or id=='aegiscompositetool') then
            p.PreventExecution=true;return false
        end
    end,nativePhase)
    local function text(key) return tostring(E.TextManager.Get('aegishud.'..key)) end
    local function rect(parent,x,y,w,h)
        local r=UI.RectTransform(E.Vector2(w,h),parent,UI.Anchor.TopLeft,UI.Pivot.TopLeft)
        r.RelativeOffset=E.Vector2(x,y);return r
    end
    local panel=UI.Frame(UI.RectTransform(E.Vector2(.25,.5),canvas,UI.Anchor.CenterRight),'GUIFrame')
    panel.RectTransform.RelativeOffset=E.Vector2(.008,0)
    local tab=UI.Button(UI.RectTransform(E.Vector2(.23,.045),canvas,UI.Anchor.CenterRight),'AEGIS')
    H.panel,H.tab=panel,tab
    if tab.TextBlock then tab.TextBlock.AutoScaleHorizontal=true end
    H.toolHost=UI.Frame(rect(panel.RectTransform,0,.1,1,.35),nil)
    H.armHost=UI.Frame(rect(panel.RectTransform,0,.45,1,.55),nil)
    local title=UI.TextBlock(rect(panel.RectTransform,.05,.008,.78,.055),'AEGIS')
    local function button(parent,x,y,w,h,label,fn)
        local b=UI.Button(rect(parent,x,y,w,h),label)
        b.SelectedColor=E.Color(65,130,105,255)
        if b.TextBlock then b.TextBlock.AutoScaleHorizontal=true end
        b.OnClicked=function()
            if H.open and H.panel.Visible then fn() end
            return true
        end
        return b
    end
    H.hideButton=button(panel.RectTransform,.87,.008,.10,.055,'>',function() H.setOpen(false) end)
    H.hideButton.ToolTip=text('collapse')
    tab.OnClicked=function() H.setOpen(true);return true end
    local toolTitle=UI.TextBlock(rect(H.toolHost.RectTransform,.05,.025,.90,.13),text('tool'))
    for i,mode in ipairs({'weld','cut','extinguish','combat'}) do
        H.buttons[mode]=button(H.toolHost.RectTransform,.05+((i-1)%2)*.46,.18+math.floor((i-1)/2)*.24,.44,.20,'',function()
            if H.item then R.setMode(H.item,mode) end
        end)
    end
    H.damageButton=button(H.toolHost.RectTransform,.51,.42,.44,.20,'',function()
        local flags=H.item and R.flags(H.item)
        if flags then R.setDamage(H.item,not flags.damage) end
    end)
    local status=UI.TextBlock(rect(H.toolHost.RectTransform,.05,.73,.90,.25),'')
    status.TextScale=.8;status.Wrap=true;status.AutoScaleVertical=true
    H.status=status
    function H.setOpen(value) H.open=value==true end
    local function equipped(character)
        if not character or character.Removed or character.IsDead or character.IsUnconscious or not character.Inventory then return end
        local right=character.Inventory.GetItemInLimbSlot(E.InvSlotType.RightHand)
        local left=character.Inventory.GetItemInLimbSlot(E.InvSlotType.LeftHand)
        if right and not right.Removed and U.itemId(right)=='aegiscombattool' and left==right then return right end
        if right and not right.Removed and U.itemId(right)=='aegiscompositetool' then return right end
        if left and not left.Removed and U.itemId(left)=='aegiscompositetool' then return left end
    end
    local function hide()
        for _,w in ipairs({panel,tab,H.toolHost,H.armHost}) do w.Visible=false;w.RemoveFromGUIUpdateList() end
        H.item=nil;H.suit=nil
    end
    function H.update(dt)
        local owner=E.Character.Controlled
        local game=E.Game
        if not owner or owner.Removed or owner.IsDead or owner.IsUnconscious or
            (game and (not game.RoundStarted or game.Paused)) or UI.GUI.PauseMenuOpen or UI.GUI.SettingsMenuOpen then hide();return end
        local tool=equipped(owner)
        local suit=E.AegisSuit and E.AegisSuit.equipped(owner)
        H.item,H.suit=tool,suit
        if not tool and not suit then hide();return end
        local bounds=canvas.Rect
        local layout=Model.layout(tool~=nil,suit~=nil,bounds.Width,bounds.Height)
        panel.RectTransform.Resize(E.Vector2(layout.width/bounds.Width,layout.height/bounds.Height))
        H.toolHost.RectTransform.RelativeOffset=E.Vector2(0,layout.toolY)
        H.toolHost.RectTransform.Resize(E.Vector2(1,layout.toolH))
        H.armHost.RectTransform.RelativeOffset=E.Vector2(0,layout.armY)
        H.armHost.RectTransform.Resize(E.Vector2(1,layout.armH))
        H.toolHost.Visible=H.open and tool~=nil;H.armHost.Visible=H.open and suit~=nil
        panel.Visible=H.open;tab.Visible=not H.open
        local summary='AEGIS'
        if tool then
            R.refresh(tool,owner,dt,game and game.GameScreen and game.GameScreen.Cam)
            local flags=R.flags(tool)
            local combat=U.itemId(tool)=='aegiscombattool'
            local mode=flags and Model.mode(flags,combat) or nil
            summary=summary..' | '..text(mode or 'waiting')
            toolTitle.Text=text('tool')..': '..tostring(tool.Name or 'Aegis')
            for name,b in pairs(H.buttons) do
                b.Visible=name~='combat' or combat;b.Enabled=flags~=nil
                b.Selected=mode==name
                b.Text=text(name)..' ['..text(mode==name and 'on' or 'off')..']'
            end
            H.damageButton.Visible=not combat;H.damageButton.Enabled=flags~=nil
            H.damageButton.Selected=flags and flags.damage==true or false
            H.damageButton.Text=text('damage')..': '..text(flags and flags.damage and 'on' or 'off')
            local power=tool.OwnInventory and tool.OwnInventory.GetItemAt(0)
            local charge=power and power.MaxCondition>0 and math.floor(power.Condition/power.MaxCondition*100) or 0
            local statusText=text('power')..': '..tostring(charge)..'%'
            if combat then
                local cartridge=tool.OwnInventory and tool.OwnInventory.GetItemAt(1)
                local installed=U.itemId(cartridge)=='aegisshieldmodule'
                local charges=E.AegisCombat and E.AegisCombat.shieldCharges(tool) or 0
                statusText=statusText..' | '..text('shield')..': '..(installed and (tostring(charges)..'/5') or text('missing'))
                H.status.RectTransform.RelativeOffset=E.Vector2(.05,.72)
                H.status.RectTransform.Resize(E.Vector2(.90,.25))
            else
                H.status.RectTransform.RelativeOffset=E.Vector2(.05,.73)
                H.status.RectTransform.Resize(E.Vector2(.90,.25))
            end
            status.Text=statusText
        end
        if suit then
            local s=E.AegisSuit.state(suit)
            summary=summary..' | '..text('arm')..': '..tostring(E.TextManager.Get('aegis.'..(s.mode or 'off')))
        end
        tab.Text=summary;tab.ToolTip=text('expand')
        if panel.Visible then panel.AddToGUIUpdateList(false,8) else tab.AddToGUIUpdateList(false,9) end
    end
    H.clear=hide
    function H.dispose()
        hide()
        for _,event in ipairs({'think','roundEnd','stop'}) do E.Hook.Remove(event,'aegis.hud.'..event) end
        E.Hook.RemovePatch('aegis.hud.native',nativeClass,nativeMethod,nativePhase)
        panel.RectTransform.Parent=nil;tab.RectTransform.Parent=nil
    end
    E.Hook.Add('think','aegis.hud.think',function() H.update(1/60) end)
    E.Hook.Add('roundEnd','aegis.hud.roundEnd',hide)
    E.Hook.Add('stop','aegis.hud.stop',H.dispose)
    hide()
    return H
end
return M
