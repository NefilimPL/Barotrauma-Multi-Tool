local G=BMTHeadsets
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
end
assert(room)
room.WaterVolume=0;room.Oxygen=100000000
local c=Character.Create('human',room.WorldPosition,'headset-idle-probe',nil,0,false,true,true,nil,true,false)
c.AIController.Enabled=false
Hook.Patch('bmt.test.idle-enabled','Barotrauma.Character','Update',function(char) if char==c then char.Enabled=true end end,Hook.HookMethodType.Before)
Timer.Wait(function()
    local item=Item(ItemPrefab.Prefabs['aegisheadsetmk2'],c.WorldPosition,nil)
    local cell=Item(ItemPrefab.Prefabs['batterycell'],c.WorldPosition,nil)
    assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
    assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
    local original=G.heal
    local records={}
    G.heal=function(character,device,dt)
        if character~=c then return original(character,device,dt) end
        local entries=require('AegisHeadset.medical').entries(_G,c)
        local before=G.energy(device)
        original(character,device,dt)
        if G.energy(device)<before then
            for _,e in ipairs(entries) do
                if e.ref.Strength~=e.strength then
                    local row=e.id..' '..e.strength..' -> '..e.ref.Strength..' target='..tostring(e.policy and e.policy.target)
                    records[#records+1]=row;print('[HEADSET IDLE] '..row)
                end
            end
            records[#records+1]='energy '..before..' -> '..G.energy(device)
        end
    end
    Timer.Wait(function()
        local idle=math.abs(G.energy(item)-100)<.0001 and math.abs(c.Vitality-100)<.0001
        records[#records+1]=(idle and 'PASS ' or 'FAIL ')..'healthy idle energy='..G.energy(item)..' vitality='..c.Vitality..' hull='..tostring(c.CurrentHull)..' pressure='..tostring(c.CurrentHull and c.CurrentHull.LethalPressure)
        print('[HEADSET IDLE] '..records[#records])
        File.Write('LocalMods/MULTI-TOOL-V2/headset-idle-results.txt',table.concat(records,'\n'))
        G.heal=original
        c.CharacterHealth.ApplyAffliction(c.AnimController.MainLimb,AfflictionPrefab.Prefabs['burn'].Instantiate(10))
        G.heal(c,item,.2)
        G.printStatus()
        Hook.RemovePatch('bmt.test.idle-enabled','Barotrauma.Character','Update',Hook.HookMethodType.Before)
        c.Remove()
    end,5000)
end,2000)
