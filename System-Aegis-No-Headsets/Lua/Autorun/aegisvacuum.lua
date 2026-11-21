local modPath=...
if AegisVacuum and AegisVacuum.dispose then AegisVacuum.dispose() end
for name in pairs(package.loaded) do if name:match('^AegisVacuum%.') then package.loaded[name]=nil end end
local G=require('AegisVacuum.game').new(_G)
AegisVacuum=G
local ok,err=pcall(function()
    for _,typeName in ipairs({'Barotrauma.DeconstructItem','Barotrauma.Items.Components.Pickable'}) do
        LuaUserData.RegisterType(typeName)
    end
    require('AegisVacuum.storage').install(G,_G)
    require('AegisVacuum.filters').install(G,_G)
    require('AegisVacuum.trash').install(G,_G)
    require('AegisVacuum.salvage').install(G,_G)
    require('AegisVacuum.crafting').install(G,_G)
    require('AegisCombat.physics').install(G,_G)
    require('AegisVacuum.network').install(G,_G)
    require('AegisVacuum.manual').install(G,_G)
    require('AegisVacuum.merchant').install(G,_G)
    if CLIENT then
        require('AegisVacuum.client').install(G,_G)
        require('AegisVacuum.audio').install(G,_G)
        require('AegisVacuum.visuals').install(G,_G,modPath)
    end
    require('AegisVacuum.runtime').install(G,_G)
end)
if not ok then G.dispose();error('[Aegis Vacuum] Initialization failed: '..tostring(err)) end
print('[Aegis Vacuum] Loaded; battery is in vacuum, storage is in backpack.')
