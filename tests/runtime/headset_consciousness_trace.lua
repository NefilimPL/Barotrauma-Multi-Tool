-- Disposable diagnostic; keep a single patient inside a safe hull.
local G=BMTHeadsets
LuaUserData.RegisterType('Neurotrauma.NTHuman')
local NT=LuaUserData.CreateStatic('Neurotrauma.NTHuman')
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end end
assert(room);room.WaterVolume=0;room.Oxygen=100000000
local c=Character.Create('human',room.WorldPosition,'single-consciousness',nil,0,false,true,true,nil,true,false)
c.TeamID=CharacterTeamType.Team1;c.AIController.Enabled=false
local item=Item(ItemPrefab.Prefabs['aegisheadsetmk2'],room.WorldPosition,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
for i=1,2 do Character.Create('crawler',Vector2(room.WorldPosition.X+100000,room.WorldPosition.Y),'single-sentinel'..i,nil,0,false,true,true,nil,true,false) end
local rows,nt,ticks={},nil,0
Hook.Patch('bmt.test.single-enable','Barotrauma.Character','Update',function(char)
    if char==c then c.Enabled=true;c.TeleportTo(room.WorldPosition) end
end,Hook.HookMethodType.Before)
Hook.Patch('bmt.test.single-nt-post','Neurotrauma.NTHuman','PostHook',function(h)
    if h.Human==c then ticks=ticks+1 end
end,Hook.HookMethodType.After)
local debit=G.recordDebit
G.recordDebit=function(device,amount,reason)
    debit(device,amount,reason)
    if device==item and amount>1e-7 then rows[#rows+1]=string.format('%.3f %s %.6f',G.now,reason,amount) end
end
local function sample(t)
    rows[#rows+1]=string.format('SAMPLE %ds power=%.3f vitality=%.3f stun=%.3f down=%s dead=%s NTticks=%d token=%s hull=%s',t,G.energy(item),c.Vitality,c.Stun,tostring(c.IsKnockedDown),tostring(c.IsDead),ticks,tostring(nt.HasSymptom('unconsciousness',LimbType.None)),tostring(c.AnimController.CurrentHull))
    for a in c.CharacterHealth.GetAllAfflictions() do if a.Strength>0 then rows[#rows+1]='state '..tostring(a.Prefab.Identifier)..' '..a.Strength end end
    File.Write('LocalMods/MULTI-TOOL-V2/headset-consciousness-trace.txt',table.concat(rows,'\n'))
end
Timer.Wait(function()
    nt=NT.getNTHumanFromCharacter(c);assert(nt,'no NT patient')
    c.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
    c.CharacterHealth.ApplyAffliction(c.AnimController.MainLimb,AfflictionPrefab.Prefabs['unconsciousness'].Instantiate(100),false,true)
    c.SetStun(5,true);sample(0)
    for _,t in ipairs({1,2,4,6,8,10,12,15}) do Timer.Wait(function() sample(t) end,t*1000) end
    Timer.Wait(function()
        G.recordDebit=debit
        Hook.RemovePatch('bmt.test.single-enable','Barotrauma.Character','Update',Hook.HookMethodType.Before)
        Hook.RemovePatch('bmt.test.single-nt-post','Neurotrauma.NTHuman','PostHook',Hook.HookMethodType.After)
        c.Remove()
    end,16000)
end,3000)
