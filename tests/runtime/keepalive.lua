-- TEST ONLY: copy to the isolated mod's Lua/Autorun/zz_testkeepalive.lua.
-- Never ship this script. It keeps an empty local test server's round alive.
LuaUserData.MakePropertyAccessible(LuaUserData.RegisterType('Barotrauma.Networking.GameServer'),'EndRoundTimer')
Hook.Add('think','aegis.test.keepalive',function() Game.Server.EndRoundTimer=1 end)
