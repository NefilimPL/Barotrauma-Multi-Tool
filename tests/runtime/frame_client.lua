-- Disposable singleplayer client only, with the real GUI and graphics device.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local U=require('CombatTool.util')
local G=BMTVacuum
local c=assert(Character.Controlled)
local created={}
local function create(kind)
    local item=Item(ItemPrefab.Prefabs[kind],c.WorldPosition,nil);created[#created+1]=item;return item
end
local pack=create('aegisvacuumpack')
assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag,InvSlotType.Any}))
local page=create('aegisvacuumpage')
assert(pack.OwnInventory.TryPutItem(page,c))
assert(G.insert(pack,create('iron'),c))
local panel=G.openPanel(pack)
local function count()
    local n=0;U.each(panel.GetAllChildren(),function() n=n+1 end);return n
end
local initial=count()
for i=1,120 do G.onSnapshot(G.snapshot(G.context(pack,c),{})) end
assert(count()==initial,'native GUI controls were rebuilt on repeated snapshots')
assert(G.insert(pack,create('copper'),c))
G.onSnapshot(G.snapshot(G.context(pack,c),{}))
assert(count()==initial,'native icon replacement allocated new controls')
assert(not G.visualError,tostring(G.visualError))
File.Write('LocalMods/MULTI-TOOL-V2/frame-client-results.txt',
    'PASS native GUI image construction, sprite replacement and 120 reused snapshots; controls='..initial)
print('[FRAME CLIENT] PASS native GUI reuse; controls='..initial)
G.closePanel()
for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/shield_client.lua')
