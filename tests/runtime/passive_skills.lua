-- Disposable server only. Accelerate the production timer, not native skill APIs.
local G=BMTCombat
local U=require('CombatTool.util')
assert(G.updatePassiveSkills,'passive skill system did not initialize')
local results,created={},{}
local function track(e) created[#created+1]=e;return e end
local function check(name,fn)
    G.clearPassiveSkills()
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BMT SKILLS] '..results[#results])
end
local pos=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then pos=hull.WorldPosition;break end end
local actor=track(Character.Create('human',pos,'bmt-skills',nil,0,false,true,true,nil,true,false))
actor.GodMode=true;actor.AIController.Enabled=false
assert(actor.Info and actor.Info.Job,'native human has no skill data')
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],pos,nil))
local cell=track(Item(ItemPrefab.Prefabs['batterycell'],pos,nil))
assert(gun.OwnInventory.TryPutItem(cell,0,false,false,actor))
local small=track(Item(ItemPrefab.Prefabs['Multi-toolSET'],pos,nil))
local rod=track(Item(ItemPrefab.Prefabs['fuelrod'],pos,nil))
assert(small.OwnInventory.TryPutItem(rod,0,false,false,actor))
local names={'helm','weapons','mechanical','electrical','medical'}
local function levels()
    local values={}
    for _,id in ipairs(names) do values[id]=actor.Info.Job.GetSkillLevel(id) end
    return values
end
local function delta(before,amount)
    for _,id in ipairs(names) do
        assert(math.abs(actor.Info.Job.GetSkillLevel(id)-before[id]-amount)<.001,'wrong native gain for '..id)
    end
end
local function equip(item,slots)
    local held={}
    U.each(actor.HeldItems,function(value) held[#held+1]=value end)
    for _,value in ipairs(held) do value.Drop(actor) end
    item.Drop(actor)
    assert(actor.Inventory.TryPutItem(item,actor,slots))
end
check('Aegis awards exactly two to all five skills after 300 seconds',function()
    equip(gun,{InvSlotType.RightHand+InvSlotType.LeftHand})
    local before=levels()
    G.updatePassiveSkills(299.9);delta(before,0)
    G.updatePassiveSkills(.1);delta(before,2)
end)
check('stowing pauses the common timer; switching to smaller tool preserves time',function()
    local before=levels()
    G.updatePassiveSkills(150)
    equip(gun,{InvSlotType.Any})
    G.updatePassiveSkills(300);delta(before,0)
    equip(small,{InvSlotType.RightHand})
    G.updatePassiveSkills(149.9);delta(before,0)
    G.updatePassiveSkills(.1);delta(before,2)
end)
check('fuel-rod repair gain buff does not multiply the fixed passive reward',function()
    actor.CharacterHealth.ApplyAffliction(nil,AfflictionPrefab.Prefabs['multitool_fuelrod_repairboost'].Instantiate(1))
    local before=levels()
    G.updatePassiveSkills(300);delta(before,2)
end)
check('empty source prevents progress and native skill cap is respected',function()
    local before=levels()
    rod.Condition=0;G.updatePassiveSkills(300);delta(before,0)
    rod.Condition=100
    actor.Info.SetSkillLevel('weapons',99,true)
    G.updatePassiveSkills(300)
    assert(actor.Info.Job.GetSkillLevel('weapons')==100,'native default cap was not respected')
end)
G.clearPassiveSkills()
for _,id in ipairs(names) do actor.Info.SetSkillLevel(id,20,true) end
local beforeTick=levels()
G.updatePassiveSkills(299)
Timer.Wait(function()
    check('native think loop completes the remaining second without manual timer calls',function()
        delta(beforeTick,2)
    end)
    G.clearPassiveSkills()
    for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
    File.Write('LocalMods/MULTI-TOOL-V2/skill-results.txt',table.concat(results,'\n'))
end,1500)
