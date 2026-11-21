local modPath=...
-- Stable patch identifiers plus explicit disposal make hot reload idempotent.
if AegisCombat and AegisCombat.dispose then AegisCombat.dispose() end
for name in pairs(package.loaded) do
    if name:match('^AegisCombat%.') then package.loaded[name]=nil end
end
local G=require('AegisCombat.game').new(_G)
G.modPath=modPath
AegisCombat=G
local ok,err=pcall(function()
    require('AegisCombat.physics').install(G,_G)
    require('AegisCombat.network').install(G,_G)
    if G.authoritative then
        require('AegisCombat.passive_skills').install(G,_G)
        require('AegisCombat.shield').install(G,_G)
        require('AegisCombat.projectiles').install(G,_G)
    end
    if CLIENT then
        require('AegisCombat.audio').install(G,_G)
        require('AegisCombat.visuals').install(G,_G,modPath)
        require('AegisCombat.shield_client').install(G,_G)
    end
    require('AegisCombat.runtime').install(G,_G)
    require('AegisCombat.diagnostics').install(G,_G)
end)
if not ok then
    G.dispose()
    error('[Aegis] Initialization failed; combat system disabled: '..tostring(err))
end
print('[Aegis] Combat multitool loaded (server authority: '..tostring(G.authoritative)..').')
