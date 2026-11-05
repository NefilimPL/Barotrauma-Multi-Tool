local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local UI=E.GUI
    local panel,category,rowsFrame,search,status,packButton,pageLabel,salvageButton,takeButton,stackButton,detailsButton,trashButton,filterButton
    local selectedId,selectedRow,cells=nil,nil,{}
    local tiles={}
    local rowFields={'id','kind','name','count','condition','quality','excluded','blocked'}
    local placeholderPrefab=E.ItemPrefab and E.ItemPrefab.Prefabs[C.pack]
    local placeholder=placeholderPrefab and (placeholderPrefab.InventoryIcon or placeholderPrefab.Sprite)
    local vacuum,view,snapshot,nextRefresh=nil,{page=0,group=0,search='',category='all',filters=false},nil,0
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
        if category then
            category.Dropped=false
            if UI.GUI.KeyboardDispatcher.Subscriber==category then UI.GUI.KeyboardDispatcher.Subscriber=nil end
            category.ListBox.RemoveFromGUIUpdateList()
            category=nil
        end
        if panel then panel.Visible=false;panel.RemoveFromGUIUpdateList();panel.RectTransform.Parent=nil;panel=nil end
        snapshot=nil;vacuum=nil
        selectedId=nil;selectedRow=nil;cells={};tiles={}
    end
    local function updateActions()
        local ready=snapshot and not snapshot.busy and selectedRow~=nil and not view.filters
        takeButton.Enabled=ready or false;stackButton.Enabled=ready or false
        detailsButton.Enabled=(ready and view.group==0) or false
        trashButton.Enabled=ready or false
        local ticket=ready and snapshot.trashTarget==selectedId and snapshot.trashToken~=0
        trashButton.Text=ticket and (text('trashconfirm')..' '..snapshot.trashCount) or text('trash')
    end
    function G.onSnapshot(s)
        if not panel or not vacuum or s.vacuum~=vacuum.ID then return end
        -- Ignore in-flight replies from the previous search/category/mode.
        if s.filters~=nil and (s.filters~=view.filters or s.category~=view.category or s.search~=view.search or s.group~=view.group) then return end
        snapshot=s;view.page=s.page
        status.Text=string.format('%s: %.1f%% | %d / 100 | %d / 10000%s',text('power'),s.charge,s.groups,s.count,
            s.busy and (' | '..text('busy')) or '')
        status.ToolTip=view.filters and text('filterhelp') or ''
        if view.filters then status.Text=text('filterhelp') end
        filterButton.Text=text(view.filters and 'contents' or 'filters')
        local ordinal=1;for i,id in ipairs(s.packs) do if id==s.pack then ordinal=i end end
        packButton.Text=string.format('%s %d/%d',text('pack'),ordinal,#s.packs)
        packButton.Visible=#s.packs>1
        search.RectTransform.RelativeSize=E.Vector2(packButton.Visible and .63 or .92,.055)
        pageLabel.Text=string.format('%d / %d',s.page+1,s.pages)
        salvageButton.Enabled=not view.filters and G.is(vacuum,C.vacuum) and not s.busy and s.charge>0
        cells={};selectedRow=nil
        for index=1,C.viewColumns*C.viewRows do
            local row=s.rows[index]
            local tile=tiles[index]
            if not tile then
                tile={};tiles[index]=tile
                local x=((index-1)%C.viewColumns)/C.viewColumns
                local y=math.floor((index-1)/C.viewColumns)/C.viewRows
                tile.button=button(rowsFrame.RectTransform,x,y,.94/C.viewColumns,.94/C.viewRows,'',function()
                    local current=tile.row
                    if not current then return end
                    if view.filters then
                        if not current.blocked then view.kind=current.kind;request('filter',current.excluded and 0 or 1) end
                        return
                    end
                    selectedId=current.id;selectedRow=current
                    for id,cell in pairs(cells) do cell.Selected=id==selectedId end
                    updateActions()
                end)
                -- A real initial sprite enables native rescaling when the window changes size.
                tile.icon=UI.Image(rect(tile.button.RectTransform,.08,.04,.84,.74),placeholder,true,nil)
                tile.icon.CanBeFocused=false
                tile.missing=UI.TextBlock(rect(tile.button.RectTransform,.30,.08,.5,.60),'?')
                tile.missing.CanBeFocused=false
                tile.badge=UI.TextBlock(rect(tile.button.RectTransform,.35,.61,.60,.33),'')
                tile.badge.TextScale=.7;tile.badge.CanBeFocused=false
                if E.Color then
                    tile.button.HoverColor=E.Color(97,123,102,255)
                    tile.button.SelectedColor=E.Color(143,166,116,255)
                end
            end
            tile.row=row
            local cell=tile.button
            cell.Enabled=row~=nil and not (view.filters and (row.blocked or s.busy))
            cell.Selected=false
            if row then
                cells[view.filters and row.kind or row.id]=cell;cell.Selected=not view.filters and row.id==selectedId
                if cell.Selected then selectedRow=row end
                local changed=not tile.last or tile.filters~=view.filters
                for _,key in ipairs(rowFields) do
                    if not tile.last or tile.last[key]~=row[key] then changed=true end
                end
                if changed then
                    tile.last={};for key,value in pairs(row) do tile.last[key]=value end;tile.filters=view.filters
                    if E.Color then cell.Color=E.Color(53,72,65,230) end
                    cell.ToolTip=string.format('%s\n×%d | %.0f%% | Q%d',row.name,row.count,row.condition,row.quality)
                    if view.filters then
                        cell.ToolTip=row.name..'\n'..text(row.blocked and 'blocked' or (row.excluded and 'excluded' or 'included'))
                        if E.Color and row.excluded then cell.Color=E.Color(111,53,48,230) end
                    end
                    local ok,prefab=pcall(function() return E.ItemPrefab.Prefabs[row.kind] end)
                    if not ok then prefab=nil end
                    local sprite=prefab and (prefab.InventoryIcon or prefab.Sprite)
                    tile.inventoryIcon=prefab and prefab.InventoryIcon~=nil
                    tile.icon.Sprite=sprite;tile.icon.Visible=sprite~=nil;tile.missing.Visible=sprite==nil
                    tile.badge.Text=view.filters and (row.excluded and '−' or '+') or tostring(row.count)
                    tile.badge.Visible=true
                end
                if tile.icon.Visible then
                    local item=row.id>0 and E.Entity and E.Entity.FindEntityByID(row.id)
                    if item then tile.icon.Color=tile.inventoryIcon and item.GetInventoryIconColor() or item.GetSpriteColor()
                    elseif E.Color then tile.icon.Color=E.Color(255,255,255,255) end
                end
            else
                tile.last=nil;cell.ToolTip=''
                tile.icon.Visible=false;tile.missing.Visible=false;tile.badge.Visible=false
            end
        end
        updateActions()
    end
    function G.openPanel(item)
        G.closePanel();vacuum=item;view={page=0,group=0,search='',category='all',filters=false}
        panel=UI.Frame(UI.RectTransform(E.Vector2(.56,.86),UI.GUI.Canvas,UI.Anchor.Center), 'GUIFrame')
        UI.TextBlock(rect(panel.RectTransform,.04,.025,.75,.06),text('title'))
        button(panel.RectTransform,.82,.025,.14,.06,text('close'),G.closePanel)
        status=UI.TextBlock(rect(panel.RectTransform,.04,.09,.92,.052),'…')
        search=UI.TextBox(rect(panel.RectTransform,.04,.15,.92,.055),'')
        search.ToolTip=text('search')
        search.OnTextChangedDelegate=function(_,value)
            if not suppress then view.search=value:sub(1,64);view.page=0;view.group=0;selectedId=nil;nextRefresh=0 end
            return true
        end
        packButton=button(panel.RectTransform,.70,.15,.26,.055,text('pack'),function()
            if snapshot and #snapshot.packs>1 then
                for i,id in ipairs(snapshot.packs) do
                    if id==snapshot.pack then
                        local target=snapshot.packs[i%#snapshot.packs+1]
                        if G.is(vacuum,C.pack) then
                            local pack=E.Entity.FindEntityByID(target)
                            if G.is(pack,C.pack) and G.context(pack,E.Character.Controlled).valid then G.openPanel(pack) end
                        else request('select',target) end
                        break
                    end
                end
            end
        end)
        packButton.Visible=false
        category=UI.DropDown(rect(panel.RectTransform,.04,.225,.53,.055),text('category.all'),#C.categories)
        for _,name in ipairs(C.categories) do category.AddItem(text('category.'..name),name) end
        category.OnSelected=function(_,name)
            view.category=tostring(name);view.group=0;view.page=0;selectedId=nil;request();return true
        end
        filterButton=button(panel.RectTransform,.60,.225,.36,.055,text('filters'),function()
            view.filters=not view.filters;view.group=0;view.page=0;selectedId=nil;request()
        end)
        filterButton.ToolTip=text('filterhelp')
        rowsFrame=UI.Frame(rect(panel.RectTransform,.04,.30,.92,.41),nil)
        button(panel.RectTransform,.04,.73,.14,.055,'<',function() view.page=math.max(0,view.page-1);selectedId=nil;request() end)
        pageLabel=UI.TextBlock(rect(panel.RectTransform,.21,.73,.25,.055),'1 / 1')
        button(panel.RectTransform,.48,.73,.14,.055,'>',function()
            view.page=math.min((snapshot and snapshot.pages or 1)-1,view.page+1);selectedId=nil;request()
        end)
        button(panel.RectTransform,.65,.73,.31,.055,text('groups'),function() view.group=0;view.page=0;selectedId=nil;request() end)
        takeButton=button(panel.RectTransform,.04,.805,.20,.06,text('take'),function() if selectedRow then request('withdraw',selectedRow.id) end end)
        stackButton=button(panel.RectTransform,.26,.805,.22,.06,text('stack'),function() if selectedRow then request('stack',selectedRow.id) end end)
        stackButton.ToolTip=text('stackhelp')
        detailsButton=button(panel.RectTransform,.50,.805,.22,.06,text('details'),function()
            if selectedRow then view.group=selectedRow.group;view.page=0;selectedId=nil;request() end
        end)
        trashButton=button(panel.RectTransform,.74,.805,.22,.06,text('trash'),function()
            if not selectedRow then return end
            if snapshot and snapshot.trashTarget==selectedId and (snapshot.trashToken or 0)>0 then
                view.confirm=snapshot.trashToken;request('trash',selectedId)
            else request('preparetrash',selectedId) end
        end)
        trashButton.ToolTip=text('trashhelp');trashButton.Enabled=false
        takeButton.Enabled=false;stackButton.Enabled=false;detailsButton.Enabled=false
        salvageButton=button(panel.RectTransform,.04,.89,.92,.065,text('salvage'),function() request('salvage') end)
        salvageButton.Enabled=G.is(item,C.vacuum)
        salvageButton.ToolTip=text('salvagehelp')
        request()
        return panel
    end
    local function deviceFor(character)
        local held=character and character.Inventory and character.Inventory.GetItemInLimbSlot(E.InvSlotType.RightHand)
        if held and G.is(held,C.vacuum) and G.context(held,character).valid then return held end
        for _,pack in ipairs(G.availablePacks and G.availablePacks(character) or G.packs(character)) do
            if G.context(pack,character).valid then return pack end
        end
    end
    local launcher=UI.Button(UI.RectTransform(E.Vector2(.20,.045),UI.GUI.Canvas,UI.Anchor.BottomCenter),text('open'))
    launcher.RectTransform.RelativeOffset=E.Vector2(0,.20)
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
        local inRound=(not E.Game or E.Game.RoundStarted) and not UI.GUI.PauseMenuOpen and not UI.GUI.SettingsMenuOpen
        local device=inRound and deviceFor(character) or nil
        if inRound and panel and vacuum and G.context(vacuum,character).valid then device=vacuum end
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
            local target=selected.Item
            local held=deviceFor(character)
            if held and G.is(held,C.vacuum) and G.context(held,character).pack==target then target=held end
            if panel and vacuum==target then G.closePanel() else G.openPanel(target) end
        end
        if panel and G.now>=nextRefresh then request() end
        -- Queue the panel during think, after the native screen rebuilds its list.
        if panel then
            panel.AddToGUIUpdateList(false,10)
            -- Native GUIDropDown queues its popup at order 1, below this panel.
            if category.Dropped then category.ListBox.AddToGUIUpdateList(false,11) end
        end
        launcher.Visible=ctx~=nil and ctx.valid and not panel
        if launcher.Visible then launcher.AddToGUIUpdateList() end
    end
end
return M
