from lua_support import LuaCase


class CombatDiagnosticTests(LuaCase):
    def test_status_reports_native_cell_restrictions_without_mutating_item(self):
        self.lua.execute('''
            local gun={ID=42,Components={{Name='ItemContainer',CanBeContained=function(prefab,slot)
                assert(prefab=='cell');return slot==0
            end}}}
            local G={authoritative=true,states={[gun]={shield={}}},rings={},
                context=function() return {mode='combat',valid=true,aim=true,damage=true,bot=false} end,
                source=function(_,slot) return {item={Prefab={Identifier={Value='fuelrod'}}},condition=50} end}
            local E={ItemPrefab={Prefabs={batterycell='cell'}},
                print=function(line) output=(output or '')..line..'\\n' end,
                Game={AddCommand=function(name,_,fn) commandName=name;runStatus=fn end,
                    RemoveCommand=function(name) removed=name end}}
            require('CombatTool.diagnostics').install(G,E)
            runStatus()
            G.disposeDiagnostics()
        ''')
        self.assertEqual(self.lua.globals().commandName,'aegis_status')
        self.assertIn('batterycell allowed=true',self.lua.globals().output)
        self.assertIn('mode=combat',self.lua.globals().output)
        self.assertIn('slot1=fuelrod:50',self.lua.globals().output)
        self.assertEqual(self.lua.globals().removed,'aegis_status')
