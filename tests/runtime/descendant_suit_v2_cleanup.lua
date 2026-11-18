-- Native client-only observer for LuaCs stop. Never package.
local G=assert(BMTDescendantSuit)
local label=ServoV2CleanupContext or 'LuaCs stop'
local output=ServoV2CleanupFile or 'LocalMods/MULTI-TOOL-V2/servo-v2-light-cleanup.txt'
local tracked={};local expected,removed=0,0
for _,s in pairs(G.states) do
    if s.lights then
        tracked[s.lights.helmet]=true;tracked[s.lights.tool]=true;expected=expected+2
    end
end
local function save()
    File.Write(output,label..': expected native LightSource.Remove calls='..expected..' observed='..removed)
end
Hook.Patch('bmt.servo.v2.cleanup-observer','Barotrauma.Lights.LightSource','Remove',function(source)
    if tracked[source] then tracked[source]=nil;removed=removed+1;save() end
end,Hook.HookMethodType.Before)
save()
print('[SERVO V2] observing '..expected..' owned native lights until LuaCs stop')
