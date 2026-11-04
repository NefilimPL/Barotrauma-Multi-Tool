local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local UI=E.GUI
    local panel,rowsFrame,search,status,packButton,pageLabel,salvageButton
    local vacuum,view,snapshot,nextRefresh=nil,{page=0,group=0,search=''},nil,0
    local suppress=false
    local function text(id) return tostring(E.TextManager.Get('vacuum.'..id)) end
    local function rect(parent,x,y,w,h)
        local r=UI.RectTransform(E.Vector2(w,h),parent,UI.Anchor.TopLeft,UI.Pivot.TopLeft)
        r.RelativeOffset=E.Vector2(x,y)
        return r
    end
    local function button(parent,x,y,w,h,label,fn)
        local b=UI.Button(rect(parent,x,y,w,h),label)
        b.OnClicked=function() fn();return true end
        return b
    end
    local function request(action,id)
        if vacuum and not vacuum.Removed then G.request(action or 'open',vacuum,id or 0,view) end
        nextRefresh=G.now+.5
    end
    function G.closePanel()
        if panel then panel.Visible=false;panel.RemoveFromGUIUpdateList();panel.RectTransform.Parent=nil;panel=nil end
        snapshot=nil;vacuum=nil
    end
    function G.onSnapshot(s)
        if not panel or not vacuum or s.vacuum~=vacuum.ID then return end
        snapshot=s;view.page=s.page
        status.Text=string.format('%s: %.1f%% | %d / 100 | %d / 10000%s',text('power'),s.charge,s.groups,s.count,
            s.busy and (' | '..text('busy')) or '')
        packButton.Text=text('pack')..' #'..s.pack..' >'
        pageLabel.Text=string.format('%d / %d',s.page+1,s.pages)
        salvageButton.Enabled=G.is(vacuum,C.vacuum) and not s.busy and s.charge>0
        rowsFrame.ClearChildren()
        for index,row in ipairs(s.rows) do
            local y=(index-1)/8
            local info=string.format('%s ×%d | %.0f%% | Q%d',row.name,row.count,row.condition,row.quality)
            local details=button(rowsFrame.RectTransform,0,y,.62,.115,info,function()
                view.group=view.group==0 and row.group or 0;view.page=0;request()
            end)
            details.ToolTip='#'..row.id..' | '..info
            local take=button(rowsFrame.RectTransform,.64,y,.17,.115,text('take'),function() request('withdraw',row.id) end)
            take.Enabled=not s.busy
            local drop=button(rowsFrame.RectTransform,.83,y,.17,.115,text('drop'),function() request('drop',row.id) end)
            drop.Enabled=not s.busy
        end
    end
    function G.openPanel(item)
        G.closePanel();vacuum=item;view={page=0,group=0,search=''}
        panel=UI.Frame(UI.RectTransform(E.Vector2(.46,.72),UI.GUI.Canvas,UI.Anchor.Center), 'GUIFrame')
        UI.TextBlock(rect(panel.RectTransform,.04,.025,.75,.06),text('title'))
        button(panel.RectTransform,.82,.025,.14,.06,text('close'),G.closePanel)
        status=UI.TextBlock(rect(panel.RectTransform,.04,.10,.92,.06),'…')
        search=UI.TextBox(rect(panel.RectTransform,.04,.18,.63,.065),'')
        search.ToolTip=text('search')
        search.OnTextChangedDelegate=function(_,value)
            if not suppress then view.search=value:sub(1,64);view.page=0;view.group=0;nextRefresh=0 end
            return true
        end
        packButton=button(panel.RectTransform,.70,.18,.26,.065,text('pack'),function()
            if snapshot and #snapshot.packs>1 then
                for i,id in ipairs(snapshot.packs) do
                    if id==snapshot.pack then request('select',snapshot.packs[i%#snapshot.packs+1]);break end
                end
            end
        end)
        rowsFrame=UI.Frame(rect(panel.RectTransform,.04,.27,.92,.51),nil)
        button(panel.RectTransform,.04,.80,.14,.06,'<',function() view.page=math.max(0,view.page-1);request() end)
        pageLabel=UI.TextBlock(rect(panel.RectTransform,.21,.80,.25,.06),'1 / 1')
        button(panel.RectTransform,.48,.80,.14,.06,'>',function()
            view.page=math.min((snapshot and snapshot.pages or 1)-1,view.page+1);request()
        end)
        button(panel.RectTransform,.65,.80,.31,.06,text('groups'),function() view.group=0;view.page=0;request() end)
        salvageButton=button(panel.RectTransform,.04,.89,.92,.07,text('salvage'),function() request('salvage') end)
        salvageButton.Enabled=G.is(item,C.vacuum)
        salvageButton.ToolTip=text('salvagehelp')
        request()
        return panel
    end
    local function deviceFor(character)
        local held=character and character.Inventory and character.Inventory.GetItemInLimbSlot(E.InvSlotType.RightHand)
        if held and G.is(held,C.vacuum) and G.context(held,character).valid then return held end
        for _,pack in ipairs(G.packs(character)) do
            if G.context(pack,character).valid then return pack end
        end
    end
    local launcher=UI.Button(UI.RectTransform(E.Vector2(.20,.045),UI.GUI.Canvas,UI.Anchor.BottomCenter),text('open'))
    launcher.RectTransform.RelativeOffset=E.Vector2(0,-.13)
    launcher.Visible=false;launcher.ToolTip=text('openhelp')
    launcher.OnClicked=function()
        local device=deviceFor(E.Character.Controlled)
        if device then if panel then G.closePanel() else G.openPanel(device) end end
        return true
    end
    G.storageButton=launcher
    function G.disposeClient()
        G.closePanel();launcher.Visible=false;launcher.RemoveFromGUIUpdateList();launcher.RectTransform.Parent=nil
    end
    function G.updateClient()
        local character=E.Character.Controlled
        local device=(not E.Game or E.Game.RoundStarted) and deviceFor(character)
        if panel and vacuum and G.context(vacuum,character).valid then device=vacuum end
        local ctx=device and G.context(device,character)
        if panel and (not ctx or not ctx.valid or device~=vacuum) then G.closePanel() end
        -- Text inputs retain F; opening storage never steals typing from chat.
        local typing=UI.GUI.KeyboardDispatcher.Subscriber~=nil
        if not typing and E.PlayerInput.KeyHit(E.Keys.F) and ctx and ctx.valid then
            if panel then G.closePanel() else G.openPanel(device) end
        end
        -- Native storage pages stay hidden; right-click the actual owned bag icon instead.
        local selected=E.Inventory and E.Inventory.SelectedSlot
        if not typing and selected and G.is(selected.Item,C.pack)
            and G.context(selected.Item,character).valid and E.PlayerInput.SecondaryMouseButtonClicked() then
            if panel and vacuum==selected.Item then G.closePanel() else G.openPanel(selected.Item) end
        end
        if panel and G.now>=nextRefresh then request() end
        -- Queue the panel during think, after the native screen rebuilds its list.
        if panel then panel.AddToGUIUpdateList() end
        launcher.Visible=ctx~=nil and ctx.valid and not panel
        if launcher.Visible then launcher.AddToGUIUpdateList() end
    end
end
return M
