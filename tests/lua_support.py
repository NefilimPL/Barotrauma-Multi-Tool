import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.local-tools/python'))
from lupa.lua52 import LuaRuntime

class LuaCase(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("package.path = ... .. '/?.lua;' .. package.path",(ROOT/'MULTI-TOOL-V2/Lua').as_posix())
        self.core=self.lua.eval("require('CombatTool.core')")

    def t(self,**kwargs):
        return self.lua.table_from(kwargs)

    def item_groups(self, environment):
        """The LuaCs item-group boundary: initial enumeration, creation and round reset."""
        self.lua.execute("""
            local E=...
            local groups={}
            local lifecycle={}
            E.Util=E.Util or {}
            E.Util.RegisterItemGroup=function(name,predicate)
                local group={predicate=predicate,items={}};groups[name]=group
                for _,item in ipairs(E.Item and E.Item.ItemList or {}) do
                    if predicate(item) then group.items[#group.items+1]=item end
                end
            end
            E.Util.GetItemGroup=function(name) return assert(groups[name]).items end
            E.Util.created=function(item)
                for _,group in pairs(groups) do
                    if group.predicate(item) then group.items[#group.items+1]=item end
                end
            end
            E.Util.roundEnd=function()
                for _,group in pairs(groups) do group.items={} end
                if lifecycle.roundEnd then lifecycle.roundEnd() end
            end
            local tagHooks={}
            E.Hook=E.Hook or {}
            E.Hook.HookMethodType={After=2}
            E.Hook.Add=function(event,id,fn) lifecycle[event]=fn end
            E.Hook.Patch=function(id,class,method,...)
                local args={...};tagHooks[method]=args[#args-1]
            end
            E.Util.tagsChanged=function(method,item,parameters)
                if tagHooks[method] then tagHooks[method](item,parameters) end
            end
        """, self.lua.eval(environment))
