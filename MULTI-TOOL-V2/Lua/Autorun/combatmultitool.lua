local modPath=...
-- Stable patch identifiers plus explicit disposal make hot reload idempotent.
if BMTCombat and BMTCombat.dispose then BMTCombat.dispose() end
for name in pairs(package.loaded) do
    if name:match('^CombatTool%.') then package.loaded[name]=nil end
end
local G=require('CombatTool.game').new(_G)
G.modPath=modPath
BMTCombat=G
local ok,err=pcall(function()
    require('CombatTool.physics').install(G,_G)
    require('CombatTool.network').install(G,_G)
    if G.authoritative then
        require('CombatTool.shield').install(G,_G)
        require('CombatTool.projectiles').install(G,_G)
    end
    if CLIENT then require('CombatTool.visuals').install(G,_G,modPath) end
    require('CombatTool.runtime').install(G,_G)
    require('CombatTool.diagnostics').install(G,_G)
end)
if not ok then
    G.dispose()
    error('[Aegis] Initialization failed; combat system disabled: '..tostring(err))
end
print('[Aegis] Combat multitool loaded (server authority: '..tostring(G.authoritative)..').')
