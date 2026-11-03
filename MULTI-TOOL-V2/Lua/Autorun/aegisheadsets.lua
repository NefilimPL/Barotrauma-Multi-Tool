local root=...
if BMTHeadsets and BMTHeadsets.dispose then BMTHeadsets.dispose() end
for name in pairs(package.loaded) do
    if name:match('^AegisHeadset%.') then package.loaded[name]=nil end
end
local G=require('AegisHeadset.game').new(_G)
G.modPath=root
BMTHeadsets=G
local ok,err=pcall(function()
    require('AegisHeadset.effects').install(G,_G)
    G.install()
end)
if not ok then G.dispose();error('[Aegis headsets] Initialization failed: '..tostring(err)) end
print('[Aegis headsets] Loaded; medical mods optional; authority='..tostring(G.authoritative))
