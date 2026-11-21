local root=...
if AegisSuit and AegisSuit.dispose then AegisSuit.dispose() end
for name in pairs(package.loaded) do if name:match('^AegisSuit%.') then package.loaded[name]=nil end end
local G=require('AegisSuit.game').new(_G)
G.modPath=root
AegisSuit=G
local ok,err=pcall(function()
    require('AegisCombat.physics').install(G,_G)
    require('AegisSuit.motion').install(G,_G)
    require('AegisSuit.aim').install(G,_G)
    require('AegisSuit.grip').install(G,_G)
    require('AegisSuit.dock').install(G,_G)
    require('AegisSuit.sonar').install(G,_G)
    require('AegisSuit.network').install(G,_G)
    require('AegisSuit.repair').install(G,_G)
    require('AegisSuit.supplies').install(G,_G)
    require('AegisSuit.pulse').install(G,_G)
    if CLIENT then require('AegisSuit.client').install(G,_G,root) end
    G.install()
end)
if not ok then G.dispose();error('[Aegis suit] Initialization failed: '..tostring(err)) end
print('[Aegis suit] Loaded; authority='..tostring(G.authoritative))
