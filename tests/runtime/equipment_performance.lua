-- Disposable server round only. Measure the remaining equipment paths on native objects.
assert(SERVER and Game.RoundStarted)
local U=require('CombatTool.util')
local H=BMTHeadsets
local AI=require('AegisHeadset.ai')
local owned,results={},{}
local position=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then position=hull.WorldPosition;break end end
local function create(kind)
    local item=Item(ItemPrefab.Prefabs[kind],position,nil);owned[#owned+1]=item;return item
end
local actor=Character.Create('human',position,'bmt-equipment-perf',nil,0,false,true,true,nil,true,false)
actor.GodMode=true;actor.AIController.Enabled=false
local headset=create('aegisheadsetmk2')
local battery=create('batterycell')
assert(actor.Inventory.TryPutItem(headset,actor,{InvSlotType.Headset}))
assert(headset.OwnInventory.TryPutItem(battery,0,false,false,actor))
local small=create('multi-toolset')
local wrench=create('wrenchscrewdrivertwoinoneset')
for i=1,3000 do create('iron') end
local count=0;U.each(Item.ItemList,function() count=count+1 end)
results[#results+1]='world items='..count..'; 3000 added native iron items; native human and equipment'
local function measure(label,fn)
    fn() -- initialize lazy state outside samples
    local samples={}
    for n=1,5 do
        local start=os.clock()
        for i=1,20 do fn() end
        samples[n]=(os.clock()-start)*1000
    end
    table.sort(samples)
    local row=string.format('%s: 20 calls, n=5 median=%.2fms max=%.2fms',label,samples[3],samples[5])
    results[#results+1]=row;print('[EQUIPMENT PERF] '..row)
end
measure('headset bot battery search',function() AI.candidate(_G,actor,headset,0) end)
measure('healthy headset medical check',function() H.heal(actor,headset,.2) end)
measure('ordinary multitool native idle update',function() small.Update(1/60,nil) end)
measure('wrench/screwdriver native idle update',function() wrench.Update(1/60,nil) end)
if U.powerSources then
    U.powerSources(_G) -- also exercise the util instance loaded by the combat module
    local cell=create('batterycell')
    local rod=create('fuelrod')
    local unrelated=create('iron')
    local found={}
    U.each(U.powerSources(_G),function(item) found[item]=true end)
    assert(found[cell] and found[rod] and not found[unrelated], 'native source index missed item.created')
    results[#results+1]='PASS native item.created indexes new batteries and fuel rods, excludes iron'
    print('[EQUIPMENT PERF] '..results[#results])
    local function contains(target)
        for _,item in ipairs(U.powerSources(_G)) do if item==target then return true end end
        return false
    end
    unrelated.AddTag('mobilebattery')
    assert(contains(unrelated),'AddTag did not refresh native source membership')
    local replaced=create('iron');replaced.AddTag('before_power')
    replaced.ReplaceTag('before_power','reactorfuel')
    assert(contains(replaced),'ReplaceTag did not refresh native source membership')
    local assigned=create('iron');assigned.Tags='misc, mobilebattery '
    assert(contains(assigned),'Tags setter did not refresh native source membership')
    results[#results+1]='PASS native AddTag, ReplaceTag and Tags setter update existing source membership'
    print('[EQUIPMENT PERF] '..results[#results])
end
for i=#owned,1,-1 do if not owned[i].Removed then owned[i].Remove() end end
-- Neurotrauma schedules initialization after character creation.
-- Let it finish before removing this test-owned character.
Timer.Wait(function() if not actor.Removed then actor.Remove() end end,3000)
File.Write('LocalMods/MULTI-TOOL-V2/equipment-performance-'..tostring(_G.EquipmentPerformanceLabel or 'before')..'.txt',table.concat(results,'\n'))
