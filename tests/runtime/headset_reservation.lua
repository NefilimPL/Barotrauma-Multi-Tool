-- Disposable runtime only. Full-stack technical marker and native AI guards.
local G=BMTHeadsets
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub then room=h;break end end
assert(room)
local bot=Character.Create('human',room.WorldPosition,'headset-reservation',nil,0,false,true,true,nil,true,false)
bot.TeamID=CharacterTeamType.Team1
bot.GodMode=true;bot.AIController.Enabled=true
local device=Item(ItemPrefab.Prefabs['aegisheadsetmk2'],room.WorldPosition,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
local spare=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
assert(bot.Inventory.TryPutItem(device,bot,{InvSlotType.Headset}))
assert(device.OwnInventory.TryPutItem(cell,0,false,false,bot))
assert(bot.Inventory.TryPutItem(spare,bot,{InvSlotType.Any}))
cell.Condition=80
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and (err=='SKIP' and 'SKIP ' or 'PASS ') or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    File.Write('LocalMods/MULTI-TOOL-V2/headset-reservation-results.txt',table.concat(results,'\n'))
end
check('native AI TakeItem cannot steal 80 percent headset cell',function()
    assert(bot.IsBot)
    assert(not bot.AIController.TakeItem(cell,bot.Inventory,false))
    assert(G.source(device)==cell)
end)
check('native AI unloading leaves headset cell in place',function()
    bot.AIController.UnequipContainedItems(device,nil)
    assert(G.source(device)==cell)
end)
check('headset keeps 80 percent cell and replaces at exactly 10',function()
    local ai=require('AegisHeadset.ai')
    ai.update(G,_G,bot,device);assert(G.source(device)==cell)
    cell.Condition=10;G.now=G.now+2
    ai.update(G,_G,bot,device);assert(G.source(device)==spare)
end)
check('actual Real Sonar control flag remains unchanged and free',function()
    local exists,prefab=pcall(function() return AfflictionPrefab.Prefabs['serversidelua'] end)
    if not exists or not prefab then return 'SKIP' end
    bot.GodMode=false
    bot.CharacterHealth.ApplyAffliction(bot.AnimController.MainLimb,prefab.Instantiate(1))
    bot.GodMode=true
    local before=G.energy(device)
    for i=1,100 do G.heal(bot,device,.2) end
    assert(bot.CharacterHealth.GetAfflictionStrengthByIdentifier('serversidelua',true)==1)
    assert(math.abs(G.energy(device)-before)<.0001)
end)
Timer.Wait(function() if not bot.Removed then bot.Remove() end end,3000)
