-- Continue vacuum_grid.lua in the same isolated SP session.
local R=assert(VacuumGridTest)
local G=BMTVacuum
local c,pack,f=R.character,R.pack,R.fabricator
if not _G.VacuumGridMetricsOnly then
assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
c.SelectedItem=f.Item;f.user=c
for i=1,6 do
    local page=Item(ItemPrefab.Prefabs['aegisvacuumpage'],c.WorldPosition,nil)
    assert(pack.OwnInventory.TryPutItem(page,c))
end
for i=1,500 do
    local item=Item(ItemPrefab.Prefabs['iron'],c.WorldPosition,nil)
    assert(G.insert(pack,item,c))
end
end
f.RefreshAvailableIngredients() -- warm the material cache
local values={}
for i=1,10 do
    local start=os.clock();f.RefreshAvailableIngredients()
    values[#values+1]=math.floor((os.clock()-start)*1000+.5)
end
table.sort(values)
local total=0;for _,v in ipairs(values) do total=total+v end
local result=string.format('native material refresh with %d actual root items: n=10 median=%dms max=%dms mean=%.2fms',
    #G.contents(pack),values[5],values[10],total/10)
print('[VACUUM GRID] '..result)
File.Write('LocalMods/MULTI-TOOL-V2/vacuum-grid-metrics.txt',result)
R.check('native cached material index follows inserts and does not duplicate sources',function()
    local expected=0
    for _,r in ipairs(G.materialRecords(pack)) do if r.kind=='iron' then expected=expected+1 end end
    for item in c.Inventory.AllItems do if G.id(item)=='iron' then expected=expected+1 end end
    assert(#f.availableIngredients['iron']==expected)
end)
