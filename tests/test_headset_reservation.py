from lua_support import LuaCase


class HeadsetReservationTests(LuaCase):
    def test_explicit_overload_signature_is_used_for_install_and_disposal(self):
        self.lua.execute('''
            local patched,removed
            local env={SERVER=true,Game={IsSingleplayer=false},Hook={HookMethodType={Before=1,After=2},
                Patch=function(...) patched={...} end,RemovePatch=function(...) removed={...} end,Remove=function() end}}
            local runtime=require('AegisHeadset.game').new(env)
            runtime.patch('overload','Class','Method',function() end,false,{'System.String'})
            assert(type(patched[4])=='table' and patched[4][1]=='System.String')
            runtime.dispose()
            assert(type(removed[4])=='table' and removed[4][1]=='System.String' and removed[5]==1)
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            hooks={}
            E={LuaUserData={IsTargetType=function(o,t) return o.kind==t end,
                RegisterType=function() return {} end,MakeFieldAccessible=function() end}}
            G={patch=function(name,class,method,fn) hooks[name]=fn end}
            AI=require('AegisHeadset.ai')
            headset={kind='Barotrauma.Item',HasTag=function(t) return t=='aegisheadset' end}
            cell={Condition=90,ParentInventory={Owner=headset}}
            bot={IsBot=true};controller={Character=bot}
        ''')

    def test_native_ai_cannot_take_or_select_reserved_headset_cell(self):
        self.lua.execute('''
            AI.install(G,E)
            for _,name in ipairs({'reserve-take','reserve-search','reserve-contain-search'}) do
                local p={item=cell}
                assert(hooks[name](controller,p)==false and p.PreventExecution)
            end
        ''')

    def test_explicit_containment_and_unloading_cannot_remove_headset_cell(self):
        self.lua.execute('''
            AI.install(G,E)
            local objective={item=cell,character=bot}
            local p={};hooks['reserve-contain'](objective,p)
            assert(p.PreventExecution and objective.Abandon)
            p={parentItem=headset,character=bot};hooks['reserve-unload'](nil,p)
            assert(p.PreventExecution)
        ''')

    def test_manual_player_and_loose_spares_remain_available(self):
        self.lua.execute('''
            AI.install(G,E)
            local p={item=cell};hooks['reserve-take']({Character={IsBot=false}},p)
            assert(not p.PreventExecution)
            cell.ParentInventory={Owner={kind='Barotrauma.Character'}}
            p={item=cell};hooks['reserve-take'](controller,p)
            assert(not p.PreventExecution)
        ''')
