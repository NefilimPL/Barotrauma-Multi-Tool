-- Disposable server round only: native inventory moves require a network event manager.
assert(SERVER and Game.RoundStarted)
local U=require('AegisCombat.util')
local owned={}
local position=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then position=hull.WorldPosition;break end end
local function create(kind)
    local item=Item(ItemPrefab.Prefabs[kind],position,nil)
    owned[#owned+1]=item
    local found=false
    U.each(Util.GetItemsById(kind),function(candidate) if candidate==item then found=true end end)
    assert(found,'item.created did not populate index for '..kind)
    return item
end
local nozzle=create('aegisvacuum')
local tool=create('aegiscombattool')
local pack=create('aegisvacuumpack')
local page=create('aegisvacuumpage')
local spare=create('aegisvacuum')
assert(pack.OwnInventory.TryPutItem(page,nil))
assert(page.OwnInventory.TryPutItem(spare,nil))
for i=1,40 do AegisVacuum.update(.02);AegisCombat.update(.02) end
assert(AegisVacuum.states[nozzle] and not AegisVacuum.states[spare])
assert(AegisCombat.states[tool])
nozzle.Remove();tool.Remove()
for i=1,40 do AegisVacuum.update(.02);AegisCombat.update(.02) end
assert(not AegisVacuum.states[nozzle] and not AegisCombat.states[tool])
for i=#owned,1,-1 do if not owned[i].Removed then owned[i].Remove() end end
local result='PASS native item.created index, device discovery, stored spare exclusion and removal'
print('[IDLE PERF] '..result)
File.Write('LocalMods/System-Aegis/idle-devices-results.txt',result)
