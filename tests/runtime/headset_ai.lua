-- Isolated server only: actual native AI resupply, 8 seconds.
local G=BMTHeadsets
local room
for hull in Hull.HullList do
    if hull.Submarine==Submarine.MainSub and (not room or hull.Rect.Width>room.Rect.Width) then room=hull end
end
assert(room)
local bot=Character.Create('human',room.WorldPosition,'headset-bot',nil,0,false,true,true,nil,true,false)
bot.TeamID=CharacterTeamType.Team1;bot.GodMode=true
local item=Item(ItemPrefab.Prefabs['aegisheadset'],room.WorldPosition,nil)
local old=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
local spare=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
assert(bot.Inventory.TryPutItem(item,bot,{InvSlotType.Headset}))
assert(item.OwnInventory.TryPutItem(old,0,false,false,bot))
assert(bot.Inventory.TryPutItem(spare,bot,{InvSlotType.Any}))
old.Condition=10
Hook.Patch('bmt.test.headset.ai-enabled','Barotrauma.Character','Update',function(c)
    if c==bot then c.Enabled=true end
end,Hook.HookMethodType.Before)
Timer.Wait(function()
    local ok=G.source(item)==spare and not old.Removed and old.Condition>0
    local manager=bot.AIController.ObjectiveManager
    local message=(ok and 'PASS' or 'FAIL')..' native bot swaps low battery; source='..tostring(G.source(item))..
        ' current='..tostring(manager.CurrentObjective)..' resupply='..tostring(G.state(item).resupply)
    print('[HEADSET AI] '..message)
    File.Write('LocalMods/MULTI-TOOL-V2/headset-ai-results.txt',message)
    Hook.RemovePatch('bmt.test.headset.ai-enabled','Barotrauma.Character','Update',Hook.HookMethodType.Before)
    bot.Remove()
end,8000)
