local root=...
if BMTDescendantSuit and BMTDescendantSuit.dispose then BMTDescendantSuit.dispose() end
for name in pairs(package.loaded) do if name:match('^DescendantSuit%.') then package.loaded[name]=nil end end
local G=require('DescendantSuit.game').new(_G)
G.modPath=root
BMTDescendantSuit=G
local ok,err=pcall(function()
    require('CombatTool.physics').install(G,_G)
    require('DescendantSuit.motion').install(G,_G)
    require('DescendantSuit.grip').install(G,_G)
    require('DescendantSuit.dock').install(G,_G)
    require('DescendantSuit.sonar').install(G,_G)
    require('DescendantSuit.network').install(G,_G)
    require('DescendantSuit.repair').install(G,_G)
    require('DescendantSuit.supplies').install(G,_G)
    require('DescendantSuit.pulse').install(G,_G)
    if CLIENT then require('DescendantSuit.client').install(G,_G,root) end
    G.install()
end)
if not ok then G.dispose();error('[Descendant suit] Initialization failed: '..tostring(err)) end
print('[Descendant suit] Loaded; authority='..tostring(G.authoritative))
