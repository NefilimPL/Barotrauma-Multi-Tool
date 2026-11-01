-- Disposable NT CS server. Synchronous comparison isolates the price/rate.
local G=BMTHeadsets
local Medical=require('AegisHeadset.medical')
local rows={}
local function check(name,fn)
    local ok,err=pcall(fn)
    rows[#rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[HEADSET PROFILE] '..rows[#rows])
end
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub then room=h;break end end
assert(room and AfflictionPrefab.Prefabs['tll_amputation'])
local c=Character.Create('human',room.WorldPosition,'headset-medical-profiles',nil,0,false,true,true,nil,true,false)
c.AIController.Enabled=false
for _,id in ipairs({'aegisheadset','aegisheadsetmk2'}) do
    local item=Item(ItemPrefab.Prefabs[id],room.WorldPosition,nil)
    local cell=Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil)
    assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
    assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
    check(id..' native healing speed and unit price',function()
        c.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
        local limb=c.AnimController.MainLimb
        c.CharacterHealth.ApplyAffliction(limb,AfflictionPrefab.Prefabs['burn'].Instantiate(30),false,true)
        local a=c.CharacterHealth.GetAffliction('burn',limb)
        G.heal(c,item,1)
        local amount=id=='aegisheadset' and 5 or 20
        assert(math.abs(a.Strength-(30-amount))<.001,'healing amount '..a.Strength)
        assert(math.abs(G.energy(item)-(100-amount*.125))<.001,'unit price '..G.energy(item))
    end)
    check(id..' two actual NT injuries heal at shared rate and fixed total price',function()
        c.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
        local limb=c.AnimController.GetLimb(LimbType.LeftLeg)
        c.CharacterHealth.ApplyAffliction(limb,AfflictionPrefab.Prefabs['fracturedextremity'].Instantiate(100),false,true)
        c.CharacterHealth.ApplyAffliction(limb,AfflictionPrefab.Prefabs['arterialcut'].Instantiate(100),false,true)
        local fracture=c.CharacterHealth.GetAffliction('fracturedextremity',limb)
        local artery=c.CharacterHealth.GetAffliction('arterialcut',limb)
        local steps=id=='aegisheadset' and 40 or 10
        for i=1,steps-1 do G.heal(c,item,1) end
        local remaining=id=='aegisheadset' and 5 or 20
        assert(math.abs(fracture.Strength+artery.Strength-remaining)<.001,'wrong shared rate')
        G.heal(c,item,1)
        assert(fracture.Strength<.001 and artery.Strength<.001,'NT effects not cured')
        assert(math.abs(G.energy(item)-75)<.001,'different total price '..G.energy(item))
    end)
    check(id..' NT and native limb share one paid restoration',function()
        c.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
        local limb=c.AnimController.GetLimb(LimbType.LeftLeg)
        c.CharacterHealth.ApplyAffliction(limb,AfflictionPrefab.Prefabs['tll_amputation'].Instantiate(1),false,true)
        local a=c.CharacterHealth.GetAffliction('tll_amputation')
        assert(a,'NT amputation marker not applied')
        local selected,index=nil,0
        for joint in c.AnimController.LimbJoints do
            index=index+1
            if not selected and joint.CanBeSevered and (joint.LimbA.type==LimbType.LeftThigh or joint.LimbB.type==LimbType.LeftThigh) then
                selected=index;c.AnimController.SeverLimbJoint(joint)
            end
        end
        assert(selected,'no severable left thigh joint')
        local jobs=Medical.jobs(c,Medical.entries(_G,c),LimbType);local count=0
        for _ in pairs(jobs) do count=count+1 end
        assert(count==1 and jobs['limb:LeftLeg'].jointIndices[1]==selected,'duplicate limb job')
        G.patients[c]=nil
        local steps=id=='aegisheadset' and 10 or 7
        for i=1,steps-1 do G.heal(c,item,1);assert(a.Strength>0,'premature restoration') end
        G.heal(c,item,1)
        assert(a.Strength==0 and math.abs(G.energy(item)-87.5)<.001,'price '..G.energy(item))
        index=0
        for joint in c.AnimController.LimbJoints do
            index=index+1
            if index==selected then assert(not joint.IsSevered and joint.Enabled,'native joint not restored') end
        end
    end)
    item.Drop(c)
end
File.Write('LocalMods/MULTI-TOOL-V2/headset-profile-results.txt',table.concat(rows,'\n'))
Timer.Wait(function() if not c.Removed then c.Remove() end end,3000)
