if not CLIENT then return end
if AegisHUD and AegisHUD.dispose then AegisHUD.dispose() end
for name in pairs(package.loaded) do if name:match('^AegisHUD%.') then package.loaded[name]=nil end end
AegisHUD=require('AegisHUD.client').install(_G)
