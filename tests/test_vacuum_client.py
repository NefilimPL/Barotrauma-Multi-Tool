from lua_support import LuaCase


class VacuumClientTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            widgets={};requests={};patches={}
            local function widget(kind,rt,label)
                local w={kind=kind,RectTransform=rt,Text=label,Visible=true}
                w.AddToGUIUpdateList=function(_,order) w.queued=true;w.UpdateOrder=order or 0 end
                w.RemoveFromGUIUpdateList=function() w.queued=false end
                w.ClearChildren=function() end
                widgets[#widgets+1]=w;return w
            end
            local ui={Anchor={TopLeft=1,Center=2,BottomCenter=3},Pivot={TopLeft=1},
                GUI={Canvas={},KeyboardDispatcher={}},RectTransform=function(v,p,a) return {Parent=p} end}
            ui.Button=function(r,t) return widget('button',r,t) end
            ui.Frame=function(r,t) return widget('frame',r,t) end
            ui.TextBlock=function(r,t) return widget('text',r,t) end
            ui.TextBox=function(r,t) return widget('input',r,t) end
            ui.Image=function(r,s) local w=widget('image',r,'');w.Sprite=s;return w end
            ui.DropDown=function(r,t)
                local w=widget('dropdown',r,t);w.items={};w.ListBox=widget('listbox',r,'')
                w.AddItem=function(label,data) w.items[#w.items+1]={label=label,data=data} end
                return w
            end
            owner={Inventory={GetItemInLimbSlot=function() return held end}}
            pack={ID=2,kind='aegisvacuumpack'};vacuum={ID=3,kind='aegisvacuum'}
            owned={pack};handsValid=true
            E={GUI=ui,TextManager={Get=function(s) return s end},
                Vector2=function(x,y) return {X=x,Y=y} end,Character={Controlled=owner},
                InvSlotType={RightHand=1},Keys={F=1},Inventory={},
                ItemPrefab={Prefabs={iron={InventoryIcon={}}}},
                PlayerInput={KeyHit=function() return hitF end,
                    SecondaryMouseButtonClicked=function() return rightClick end}}
            G={now=0,is=function(i,k) return i and i.kind==k end,
                packs=function() return owned end,
                context=function(i,c)
                    local own=false;for _,p in ipairs(owned) do if i==p then own=true end end
                    return {valid=c==owner and (own or (i==vacuum and handsValid)),pack=own and i or pack,owner=owner}
                end,
                request=function(a,i,t,v) requests[#requests+1]={action=a,item=i,target=t,
                    filters=v.filters,category=v.category,kind=v.kind,confirm=v.confirm} end,
                patch=function(n,c,m,fn) patches[n]=fn end}
            require('SalvageVacuum.client').install(G,E)
            function button(label)
                for _,w in ipairs(widgets) do if w.kind=='button' and w.Text==label then return w end end
                error('missing button '..label)
            end
        """)

    def test_visible_storage_button_opens_backpack_without_nozzle(self):
        self.lua.execute("""
            G.updateClient();local b=button('vacuum.open');assert(b.Visible)
            b.OnClicked();assert(requests[#requests].action=='open' and requests[#requests].item==pack)
        """)

    def test_dropped_categories_are_above_panel_and_release_keyboard_on_close(self):
        self.lua.execute("""
            local panel=G.openPanel(pack);local dropdown
            for _,w in ipairs(widgets) do if w.kind=='dropdown' then dropdown=w end end
            dropdown.Dropped=true;E.GUI.GUI.KeyboardDispatcher.Subscriber=dropdown
            G.updateClient()
            assert(dropdown.ListBox.queued and dropdown.ListBox.UpdateOrder>panel.UpdateOrder,
                'category list is covered by the panel and item tiles')
            dropdown.OnSelected(nil,'medical')
            assert(requests[#requests].category=='medical')
            G.closePanel()
            assert(not dropdown.Dropped and E.GUI.GUI.KeyboardDispatcher.Subscriber==nil,
                'closed dropdown retained keyboard focus')
        """)

    def test_visible_button_prefers_operational_two_handed_nozzle(self):
        self.lua.execute("""
            held=vacuum;G.updateClient();button('vacuum.open').OnClicked()
            assert(requests[#requests].item==vacuum)
        """)

    def test_one_handed_nozzle_does_not_hide_backpack_access(self):
        self.lua.execute("""
            held=vacuum;handsValid=false;hitF=true;G.updateClient()
            assert(requests[#requests].item==pack)
        """)

    def test_right_click_on_own_pack_opens_its_window(self):
        self.lua.execute("""
            E.Inventory.SelectedSlot={Item=pack};rightClick=true;G.updateClient()
            assert(requests[#requests].item==pack)
        """)

    def test_right_click_on_current_pack_uses_held_nozzle_for_salvage(self):
        self.lua.execute("""
            held=vacuum;E.Inventory.SelectedSlot={Item=pack};rightClick=true;G.updateClient()
            assert(requests[#requests].item==vacuum)
        """)

    def test_typing_does_not_trigger_storage_shortcuts(self):
        self.lua.execute("""
            E.GUI.GUI.KeyboardDispatcher.Subscriber={};hitF=true
            G.updateClient();assert(#requests==0)
        """)

    def test_inventory_button_is_hidden_without_a_pack(self):
        self.lua.execute("""
            owned={};G.updateClient();assert(not button('vacuum.open').Visible)
        """)

    def test_dispose_removes_button_and_open_window_from_gui(self):
        self.lua.execute("""
            G.updateClient();local b=button('vacuum.open');b.OnClicked()
            G.disposeClient();assert(not b.Visible and not b.queued and b.RectTransform.Parent==nil)
        """)

    def test_ending_round_hides_launcher_and_closes_window_with_old_character_remaining(self):
        self.lua.execute("""
            E.Game={RoundStarted=true};G.updateClient();button('vacuum.open').OnClicked()
            G.onSnapshot({vacuum=pack.ID,pack=pack.ID,charge=0,groups=0,count=0,
                busy=false,page=0,pages=1,packs={pack.ID},rows={}})
            E.Game.RoundStarted=false;G.updateClient()
            assert(not button('vacuum.open').Visible)
            for _,w in ipairs(widgets) do if w.kind=='frame' and w.RectTransform.Parent==E.GUI.GUI.Canvas then
                assert(not w.Visible)
            end end
        """)

    def test_pack_window_switches_to_another_owned_backpack_without_nozzle(self):
        self.lua.execute("""
            local second={ID=20,kind='aegisvacuumpack'};owned={pack,second}
            E.Entity={FindEntityByID=function(id) if id==20 then return second end end}
            G.openPanel(pack)
            G.onSnapshot({vacuum=pack.ID,pack=pack.ID,charge=0,groups=0,count=0,
                busy=false,page=0,pages=1,packs={pack.ID,second.ID},rows={}})
            button('vacuum.pack 1/2').OnClicked()
            assert(requests[#requests].action=='open' and requests[#requests].item==second)
        """)

    def test_icons_tooltips_stack_action_and_single_pack_selector(self):
        self.lua.execute("""
            G.openPanel(pack)
            G.onSnapshot({vacuum=pack.ID,pack=pack.ID,charge=0,groups=1,count=100,busy=false,
                page=0,pages=1,packs={pack.ID},rows={{id=10,kind='iron',name='Iron',count=100,condition=80,quality=3,group=1}}})
            local icon,tile
            for _,w in ipairs(widgets) do
                assert(w.Text~='vacuum.drop')
                if w.kind=='image' then icon=w end
                if w.kind=='button' and w.ToolTip and w.ToolTip:find('Iron',1,true) then tile=w end
                if w.kind=='button' and w.Text and w.Text:find('vacuum.pack',1,true) then assert(not w.Visible) end
            end
            assert(icon and tile and tile.Text=='')
            tile.OnClicked();button('vacuum.stack').OnClicked()
            assert(requests[#requests].action=='stack' and requests[#requests].target==10)
        """)

    def test_pause_hides_custom_window_instead_of_covering_native_menu(self):
        self.lua.execute("""
            G.openPanel(pack);E.GUI.GUI.PauseMenuOpen=true;G.updateClient()
            assert(not button('vacuum.open').Visible)
            for _,w in ipairs(widgets) do if w.kind=='frame' and w.RectTransform.Parent==E.GUI.GUI.Canvas then
                assert(not w.Visible)
            end end
        """)

    def test_category_and_filter_mode_request_the_selected_catalog(self):
        self.lua.execute("""
            G.openPanel(pack)
            local dropdown;for _,w in ipairs(widgets) do if w.kind=='dropdown' then dropdown=w end end
            assert(dropdown and #dropdown.items==10)
            dropdown.OnSelected(nil,'medical')
            assert(requests[#requests].category=='medical')
            button('vacuum.filters').OnClicked()
            assert(requests[#requests].filters)
            G.onSnapshot({vacuum=pack.ID,pack=pack.ID,charge=0,groups=0,count=0,busy=false,page=0,pages=1,
                filters=true,category='medical',search='',group=0,packs={pack.ID},rows={{id=0,kind='iron',name='Iron',count=1,condition=0,quality=0,group=0,excluded=false}}})
            for _,w in ipairs(widgets) do if w.kind=='button' and w.ToolTip and w.ToolTip:find('Iron',1,true) then w.OnClicked();break end end
            assert(requests[#requests].action=='filter' and requests[#requests].kind=='iron' and requests[#requests].target==1)
        """)

    def test_trash_needs_server_preview_before_confirmation_click(self):
        self.lua.execute("""
            G.openPanel(pack)
            local s={vacuum=pack.ID,pack=pack.ID,charge=0,groups=1,count=1,busy=false,page=0,pages=1,packs={pack.ID},
                rows={{id=10,kind='iron',name='Iron',count=1,condition=100,quality=0,group=1}}}
            G.onSnapshot(s)
            for _,w in ipairs(widgets) do if w.kind=='button' and w.ToolTip and w.ToolTip:find('Iron',1,true) then w.OnClicked();break end end
            button('vacuum.trash').OnClicked();assert(requests[#requests].action=='preparetrash')
            s.trashTarget=10;s.trashToken=7;s.trashCount=1;G.onSnapshot(s)
            button('vacuum.trashconfirm 1').OnClicked()
            assert(requests[#requests].action=='trash' and requests[#requests].confirm==7)
        """)
