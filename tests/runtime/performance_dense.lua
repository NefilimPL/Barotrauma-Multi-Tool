-- TEST ONLY: far damaged native repairables, prepared before any timing phase.
assert(SERVER and Game.RoundStarted and BMTPerformance and not BMTPerformance.phases)
local root='LocalMods/MULTI-TOOL-V2/'
local count,complete,ids,created=300,0,{},{}
for i=1,count do
    local point=BMTPerformance.base+Vector2(2500+(i%30)*100,-1000-math.floor(i/30)*100)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['junctionbox'],point,nil,nil,nil,function(item)
        item.Condition=item.MaxCondition*.5
        item.GetComponentString('Repairable').DeteriorationSpeed=0
        created[item]=true;ids[#ids+1]=tostring(item.ID);complete=complete+1
    end)
end
local function ready()
    if complete<count then Timer.Wait(ready,100);return end
    local indexed=0
    require('CombatTool.util').each(Util.GetItemGroup('bmt.descendant.repairables'),function(item)
        if created[item] then indexed=indexed+1 end
    end)
    assert(indexed==count,'native dense items are missing from the production repairable index')
    local total=0;for _ in Item.ItemList do total=total+1 end
    local scene=File.Read(root..'bmt-perf-scene.json')
    scene=scene:gsub('"items":%d+','"items":'..total)
    scene=scene:gsub('^{','{"dense_damaged_repairables":'..count..',',1)
    File.Write(root..'bmt-perf-scene.json',scene)
    File.Write(root..'bmt-dense-ids.txt',table.concat(ids,','))
    File.Write(root..'bmt-dense-ready.txt',tostring(indexed))
end
Timer.Wait(ready,100)
