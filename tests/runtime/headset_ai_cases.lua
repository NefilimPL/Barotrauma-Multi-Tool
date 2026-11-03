-- Disposable native server/client: multiple automatic battery insertion cases.
local G=BMTHeadsets
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
end
assert(room)
local cases={}
for _,kind in ipairs({'empty headset / carried spare','low cell / carried spare','low cell / floor spare'}) do
    local bot=Character.Create('human',room.WorldPosition,'headset-ai-case',nil,0,false,true,true,nil,true,false)
    bot.GodMode=true;bot.TeamID=CharacterTeamType.Team1
    local device=Item(ItemPrefab.Prefabs['aegisheadsetmk2'],room.WorldPosition,nil)
    local spare=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
    assert(bot.Inventory.TryPutItem(device,bot,{InvSlotType.Headset}))
    local old
    if kind~='empty headset / carried spare' then
        old=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
        assert(device.OwnInventory.TryPutItem(old,0,false,false,bot));old.Condition=10
    end
    if kind~='low cell / floor spare' then assert(bot.Inventory.TryPutItem(spare,bot,{InvSlotType.Any})) end
    cases[#cases+1]={kind=kind,bot=bot,device=device,spare=spare,old=old}
end
Hook.Patch('bmt.test.ai-cases','Barotrauma.Character','Update',function(c)
    for _,case in ipairs(cases) do if c==case.bot then c.Enabled=true end end
end,Hook.HookMethodType.Before)
Timer.Wait(function()
    local lines={}
    for _,case in ipairs(cases) do
        local ok=G.source(case.device)==case.spare and (not case.old or not case.old.Removed)
        lines[#lines+1]=(ok and 'PASS ' or 'FAIL ')..case.kind
        case.bot.Remove()
    end
    File.Write('LocalMods/MULTI-TOOL-V2/headset-ai-cases.txt',table.concat(lines,'\n'))
    print('[HEADSET AI CASES] '..table.concat(lines,'; '))
    Hook.RemovePatch('bmt.test.ai-cases','Barotrauma.Character','Update',Hook.HookMethodType.Before)
end,8000)
