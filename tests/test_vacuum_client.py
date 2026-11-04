from lua_support import LuaCase


class VacuumClientTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            widgets={};requests={};patches={}
            local function widget(kind,rt,label)
                local w={kind=kind,RectTransform=rt,Text=label,Visible=true}
                w.AddToGUIUpdateList=function() w.queued=true end
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
            owner={Inventory={GetItemInLimbSlot=function() return held end}}
            pack={ID=2,kind='aegisvacuumpack'};vacuum={ID=3,kind='aegisvacuum'}
            owned={pack};handsValid=true
            E={GUI=ui,TextManager={Get=function(s) return s end},
                Vector2=function(x,y) return {X=x,Y=y} end,Character={Controlled=owner},
                InvSlotType={RightHand=1},Keys={F=1},Inventory={},
                PlayerInput={KeyHit=function() return hitF end,
                    SecondaryMouseButtonClicked=function() return rightClick end}}
            G={now=0,is=function(i,k) return i and i.kind==k end,
                packs=function() return owned end,
                context=function(i,c)
                    return {valid=c==owner and (i==pack or (i==vacuum and handsValid)),pack=pack,owner=owner}
                end,
                request=function(a,i,t,v) requests[#requests+1]={action=a,item=i,target=t} end,
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
