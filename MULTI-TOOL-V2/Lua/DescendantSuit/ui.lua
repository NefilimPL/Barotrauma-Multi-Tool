local C=require('DescendantSuit.config')
local M={}
function M.layout(powered,expanded,width,height)
    local side=math.floor(math.min(240,width*.22,height*.27))
    return {visible=expanded or powered,controls=expanded,width=expanded and math.min(340,width*.28) or side,
        height=expanded and math.min(400,height*.50) or side}
end
function M.install(G,E)
    local UI=E.GUI;local gui=UI.GUI
    local function text(id) return tostring(E.TextManager.Get('descendant.'..id)) end
    local function rect(parent,x,y,w,h)
        local t=UI.RectTransform(E.Vector2(w,h),parent.RectTransform,UI.Anchor.TopLeft,UI.Pivot.TopLeft)
        t.RelativeOffset=E.Vector2(x,y);return t
    end
    local function button(parent,x,y,w,h,label,fn)
        local b=UI.Button(rect(parent,x,y,w,h),label)
        b.SelectedColor=E.Color(95,150,125,255)
        b.OnClicked=function() fn();return true end
        return b
    end
    local function equipped() return G.equipped(E.Character.Controlled) end
    local panel=UI.Frame(UI.RectTransform(E.Vector2(.24,.40),gui.Canvas,UI.Anchor.CenterRight),'GUIFrame')
    G.panel=panel
    local panelOpen,sonarOpen=true,false
    UI.TextBlock(rect(panel,.05,.02,.79,.10),text('title'))
    G.panelHideButton=button(panel,.87,.02,.10,.10,'»',function() panelOpen=false end)
    G.panelHideButton.ToolTip=text('hide_panel')
    local rightTab=UI.Button(UI.RectTransform(E.Vector2(.075,.052),gui.Canvas,UI.Anchor.CenterRight),text('arm_tab'))
    G.panelShowButton=rightTab
    rightTab.OnClicked=function() panelOpen=true;return true end
    local buttons={}
    for n,mode in ipairs({'off','repair','combat','grab'}) do
        buttons[mode]=button(panel,.05,.15+(n-1)*.115,.90,.10,text(mode),function()
            local item=equipped()
            if item then G.requestMode(item,mode=='off' and 'toggle' or mode) end
        end)
    end
    buttons.grab.ToolTip=E.InputTypeLString(E.TextManager.Get('descendant.grab_help'),false)
    buttons.sonar=button(panel,.05,.61,.90,.10,text('sonar'),function() sonarOpen=not sonarOpen end)
    G.panelButtons=buttons
    local status=UI.TextBlock(rect(panel,.05,.74,.90,.24),'')
    G.panelStatus=status

    local sonarPanel=UI.Frame(UI.RectTransform(E.Vector2(.37,.54),gui.Canvas,UI.Anchor.CenterLeft),'GUIFrame')
    sonarPanel.RectTransform.RelativeOffset=E.Vector2(.008,0)
    G.sonarPanel=sonarPanel
    local panelColor=sonarPanel.Color
    local leftTab=UI.Button(UI.RectTransform(E.Vector2(.075,.052),gui.Canvas,UI.Anchor.CenterLeft),text('sonar'))
    G.sonarShowButton=leftTab
    leftTab.OnClicked=function() sonarOpen=true;return true end
    G.sonarPowerButton=button(sonarPanel,.04,.02,.78,.10,text('sonar_off'),function()
        local item=equipped();if item then G.requestMode(item,'sonar') end
    end)
    G.sonarHideButton=button(sonarPanel,.87,.02,.09,.10,'«',function() sonarOpen=false end)
    G.sonarHideButton.ToolTip=text('hide_panel')
    G.sonarActiveButton=button(sonarPanel,.04,.15,.44,.09,text('sonar_active'),function()
        local item=equipped();if item then G.requestMode(item,'sonaractive') end
    end)
    G.sonarPassiveButton=button(sonarPanel,.52,.15,.44,.09,text('sonar_passive'),function()
        local item=equipped();if item then G.requestMode(item,'sonarpassive') end
    end)
    G.sonarMineralButton=button(sonarPanel,.04,.26,.92,.08,text('minerals'),function()
        local item=equipped();if item then G.requestMode(item,'minerals') end
    end)
    local sonarBody=UI.Frame(rect(sonarPanel,.025,.36,.95,.62),nil)
    local expand=button(sonarPanel,.88,0,.12,.12,'+',function() sonarOpen=true end)
    G.sonarExpandButton=expand
    local sonarStatus=UI.TextBlock(rect(sonarBody,.04,.35,.92,.30),text('sonar_off'))
    G.sonarStatus=sonarStatus
    local descriptor=E.LuaUserData.RegisterType('Barotrauma.Items.Components.Sonar')
    E.LuaUserData.MakeFieldAccessible(descriptor,'controlContainer')
    E.LuaUserData.MakeFieldAccessible(descriptor,'sonarView')
    local hosted
    local function detach()
        if not hosted then return end
        hosted.frame.Visible=false;hosted.frame.RemoveFromGUIUpdateList()
        hosted.frame.RectTransform.Parent=gui.Canvas
        hosted=nil
    end
    local function attach(item,sonar)
        local frame=sonar.GuiFrame
        if not frame then return end
        if hosted and hosted.frame==frame then return end
        detach();hosted={item=item,frame=frame,sonar=sonar}
        frame.RectTransform.Parent=sonarBody.RectTransform
        frame.RectTransform.Resize(E.Vector2(1,1))
        frame.RectTransform.SetPosition(UI.Anchor.Center)
        frame.RectTransform.RelativeOffset=E.Vector2(0,0)
        sonar.controlContainer.Visible=false
        local view=sonar.sonarView
        view.RectTransform.RelativeOffset=E.Vector2(0,0)
        view.RectTransform.SetPosition(UI.Anchor.Center)
        view.RectTransform.Resize(E.Vector2(1,1))
        G.sonarView=view
    end
    local panelMode,grabHint,nextHint=nil,'',0
    function G.updateSuitUI(dt)
        local item=equipped()
        panel.Visible=item~=nil and panelOpen;rightTab.Visible=item~=nil and not panelOpen
        sonarPanel.Visible=false;leftTab.Visible=false
        if not item then detach();return end
        local s=G.state(item)
        if panelMode~=s.mode then
            panel.RectTransform.Resize(E.Vector2(.24,s.mode=='grab' and .45 or .40));panelMode=s.mode
        end
        if s.mode=='grab' and G.now>=nextHint then
            grabHint=tostring(E.InputTypeLString(E.TextManager.Get('descendant.grab_short'),false))
            buttons.grab.ToolTip=E.InputTypeLString(E.TextManager.Get('descendant.grab_help'),false)
            nextHint=G.now+1
        end
        for _,mode in ipairs({'repair','combat','grab'}) do buttons[mode].Selected=s.mode==mode end
        buttons.off.Selected=s.mode~='off'
        buttons.off.Text=text(s.mode=='off' and 'off' or 'on');buttons.sonar.Selected=s.sonar==true
        local ammo=G.ammo(item)
        status.Text=text('power')..': '..math.floor(s.charge or G.energy(item))..'%  |  '..
            text('ammo')..': '..math.floor((ammo and ammo.Condition or 0)/C.ammoCost)..'\n'..
            text(s.open and 'air' or 'closedloop')..(s.mode=='grab' and '\n'..grabHint or '')
        local sonar,powered=G.syncSonar(item,s)
        local bounds=gui.Canvas.Rect
        local layout=M.layout(powered,sonarOpen,bounds.Width,bounds.Height)
        sonarPanel.Visible=layout.visible
        sonarPanel.RectTransform.Resize(E.Vector2(layout.width/bounds.Width,layout.height/bounds.Height))
        sonarPanel.Color=sonarOpen and panelColor or E.Color.Transparent
        sonarBody.RectTransform.RelativeOffset=sonarOpen and E.Vector2(.025,.36) or E.Vector2.Zero
        sonarBody.RectTransform.Resize(sonarOpen and E.Vector2(.95,.62) or E.Vector2.One)
        expand.Visible=not sonarOpen and powered
        for _,b in ipairs({G.sonarPowerButton,G.sonarHideButton,G.sonarActiveButton,G.sonarPassiveButton,G.sonarMineralButton}) do b.Visible=sonarOpen end
        if sonar then attach(item,sonar) else detach() end
        G.sonarPowerButton.Text=text(s.sonar and 'sonar_on' or 'sonar_off')
        G.sonarPowerButton.Selected=powered
        G.sonarActiveButton.Selected=s.sonar==true and s.sonarActive~=false
        G.sonarPassiveButton.Selected=s.sonar==true and s.sonarActive==false
        G.sonarMineralButton.Selected=powered and s.minerals==true and s.sonarActive~=false
        sonarStatus.Visible=not powered
        sonarStatus.Text=text(s.sonar and 'no_power' or 'sonar_off')
        if hosted then
            hosted.frame.Visible=layout.visible and powered
            if layout.visible and powered then sonar.UpdateHUDComponentSpecific(E.Character.Controlled,dt,E.Game.GameScreen.Cam) end
        end
        if panel.Visible then panel.AddToGUIUpdateList(false,8) else rightTab.AddToGUIUpdateList(false,9) end
        if sonarPanel.Visible then sonarPanel.AddToGUIUpdateList(false,8) end
    end
    function G.clearSuitUI()
        detach()
        for _,frame in ipairs({panel,rightTab,sonarPanel,leftTab}) do frame.Visible=false;frame.RemoveFromGUIUpdateList() end
    end
    function G.disposeSuitUI()
        G.clearSuitUI()
        for _,frame in ipairs({panel,rightTab,sonarPanel,leftTab}) do frame.RectTransform.Parent=nil end
    end
    G.clearSuitUI()
end
return M
