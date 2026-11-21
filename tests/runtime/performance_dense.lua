-- TEST ONLY: far damaged native repairables, prepared before any timing phase.
assert(SERVER and Game.RoundStarted and AegisPerformance and not AegisPerformance.phases)
local root='LocalMods/System-Aegis/'
local count,complete,ids,created=300,0,{},{}
for i=1,count do
    local point=AegisPerformance.base+Vector2(2500+(i%30)*100,-1000-math.floor(i/30)*100)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['junctionbox'],point,nil,nil,nil,function(item)
        item.Condition=item.MaxCondition*.5
        item.GetComponentString('Repairable').DeteriorationSpeed=0
        created[item]=true;ids[#ids+1]=tostring(item.ID);complete=complete+1
    end)
end
local function ready()
    if complete<count then Timer.Wait(ready,100);return end
    local indexed=0
    require('AegisCombat.util').each(Util.GetItemGroup('aegis.suit.repairables'),function(item)
        if created[item] then indexed=indexed+1 end
    end)
    assert(indexed==count,'native dense items are missing from the production repairable index')
    local total=0;for _ in Item.ItemList do total=total+1 end
    local scene=File.Read(root..'aegis-perf-scene.json')
    scene=scene:gsub('"items":%d+','"items":'..total)
    scene=scene:gsub('^{','{"dense_damaged_repairables":'..count..',',1)
    File.Write(root..'aegis-perf-scene.json',scene)
    File.Write(root..'aegis-dense-ids.txt',table.concat(ids,','))
    File.Write(root..'aegis-dense-ready.txt',tostring(indexed))
end
Timer.Wait(ready,100)
