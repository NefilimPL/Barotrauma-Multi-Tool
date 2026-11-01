-- Disposable NT CS server: allow real simulation/NT ticks after leg loss.
local G=BMTHeadsets
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end end
assert(room)
room.WaterVolume=0;room.Oxygen=100000000
local c=Character.Create('human',room.WorldPosition,'headset-amputation-live',nil,0,false,true,true,nil,true,false)
c.TeamID=CharacterTeamType.Team1;c.AIController.Enabled=false
local item=Item(ItemPrefab.Prefabs['aegisheadsetmk2'],room.WorldPosition,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
local rows={}
local hitCost,limbCost=0,0
Hook.Patch('bmt.test.amputation-source','Barotrauma.StatusEffect','GetMultipliedAffliction',function(effect,p)
    if p['targetCharacter']==c and p.ReturnValue then
        rows[#rows+1]='EFFECT '..tostring(p.ReturnValue.Prefab.Identifier)..' '..p.ReturnValue.Strength..' ownBody='..tostring(p['entity']==c)
    end
end,Hook.HookMethodType.After)
local debit=G.recordDebit
G.recordDebit=function(device,amount,reason)
    debit(device,amount,reason)
    if device==item and amount>1e-7 then
        if reason=='hit' then hitCost=hitCost+amount end
        if reason=='regenerate:limb:LeftLeg' then limbCost=limbCost+amount end
        rows[#rows+1]=string.format('%.3f %s %.6f energy=%.4f',G.now,reason,amount,G.energy(item))
    end
end
Hook.Patch('bmt.test.live-amputation','Barotrauma.Character','Update',function(character) if character==c then character.Enabled=true end end,Hook.HookMethodType.Before)
Timer.Wait(function()
    c.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
    local limb=c.AnimController.GetLimb(LimbType.LeftLeg)
    c.CharacterHealth.ApplyAffliction(limb,AfflictionPrefab.Prefabs['gate_ta_ll'].Instantiate(1),false,true)
    rows[#rows+1]='applied actual NT gate_ta_ll amputation'
    Timer.Wait(function()
        local marker=c.CharacterHealth.GetAffliction('tll_amputation')
        local passed=not c.IsDead and G.energy(item)>50 and hitCost==0 and
            math.abs(limbCost-12.5)<.001 and (not marker or marker.Strength==0)
        rows[#rows+1]=(passed and 'PASS ' or 'FAIL ')..'delayed NT amputation: hitCost='..hitCost..' limbCost='..limbCost
        rows[#rows+1]='FINAL energy='..G.energy(item)..' dead='..tostring(c.IsDead)..' vitality='..c.Vitality
        for a in c.CharacterHealth.GetAllAfflictions() do if a.Strength>0 then rows[#rows+1]='state '..tostring(a.Prefab.Identifier)..' '..a.Strength end end
        File.Write('LocalMods/MULTI-TOOL-V2/headset-amputation-trace.txt',table.concat(rows,'\n'))
        G.recordDebit=debit
        Hook.RemovePatch('bmt.test.live-amputation','Barotrauma.Character','Update',Hook.HookMethodType.Before)
        Hook.RemovePatch('bmt.test.amputation-source','Barotrauma.StatusEffect','GetMultipliedAffliction',Hook.HookMethodType.After)
        c.Remove()
    end,16000)
end,2500)
