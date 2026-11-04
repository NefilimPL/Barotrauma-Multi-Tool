local modPath=...
if BMTVacuum and BMTVacuum.dispose then BMTVacuum.dispose() end
for name in pairs(package.loaded) do if name:match('^SalvageVacuum%.') then package.loaded[name]=nil end end
local G=require('SalvageVacuum.game').new(_G)
BMTVacuum=G
local ok,err=pcall(function()
    for _,typeName in ipairs({'Barotrauma.DeconstructItem','Barotrauma.Items.Components.Pickable'}) do
        LuaUserData.RegisterType(typeName)
    end
    require('SalvageVacuum.storage').install(G,_G)
    require('SalvageVacuum.salvage').install(G,_G)
    require('SalvageVacuum.crafting').install(G,_G)
    require('CombatTool.physics').install(G,_G)
    require('SalvageVacuum.network').install(G,_G)
    if CLIENT then
        require('SalvageVacuum.client').install(G,_G)
        require('SalvageVacuum.visuals').install(G,_G,modPath)
    end
    require('SalvageVacuum.runtime').install(G,_G)
end)
if not ok then G.dispose();error('[Aegis Vacuum] Initialization failed: '..tostring(err)) end
print('[Aegis Vacuum] Loaded; battery is in vacuum, storage is in backpack.')
