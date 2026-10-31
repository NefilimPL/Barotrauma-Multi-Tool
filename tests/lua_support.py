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
