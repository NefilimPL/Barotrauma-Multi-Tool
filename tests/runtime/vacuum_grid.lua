-- Isolated singleplayer only: genuine cabinet, materials, fabrication and icon grid.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTVacuum
local U=require('CombatTool.util')
local R={rows={}}
VacuumGridTest=R
function R.check(name,fn)
    local ok,err=pcall(fn)
    R.rows[#R.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM GRID] '..R.rows[#R.rows])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-grid-results.txt',table.concat(R.rows,'\n'))
    return ok
end
local room;for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then room=hull;break end end
assert(room)
local function create(kind) return Item(assert(ItemPrefab.Prefabs[kind],kind),room.WorldPosition,nil) end
local c=Character.Create('human',room.WorldPosition,'vacuum-grid',nil,0,false,true,true,nil,true,false)
c.GodMode=true;c.TeamID=CharacterTeamType.Team1;c.AIController.Enabled=false
for other in Character.CharacterList do if other.AIController then other.AIController.Enabled=false end end
Character.Controlled=c;R.character=c
local pack=create('aegisvacuumpack');R.pack=pack
assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
for i=1,4 do assert(pack.OwnInventory.TryPutItem(create('aegisvacuumpage'),c)) end
local function add(kind,amount)
    local items={}
    for i=1,(amount or 1) do local item=create(kind);assert(G.insert(pack,item,c));items[#items+1]=item end
    return items
end
local iron=add('iron',10);add('copper',2);add('organicfiber',1)
local fabricatorItem=create('fabricator');local f=U.component(fabricatorItem,'Fabricator');R.fabricator=f
if not f.InputContainer then f.OnItemLoaded() end
local descriptor=LuaUserData.RegisterType('Barotrauma.Items.Components.Fabricator')
for _,name in ipairs({'RefreshAvailableIngredients','StartFabricating','Fabricate'}) do LuaUserData.MakeMethodAccessible(descriptor,name) end
LuaUserData.MakeFieldAccessible(descriptor,'fabricationRecipes')
LuaUserData.RegisterType('System.Collections.Generic.List`1[[Barotrauma.MapEntity, Barotrauma]]') -- test links only
c.SelectedItem=fabricatorItem;f.user=c
R.check('native fabricator sees actual materials inside worn backpack',function()
    f.RefreshAvailableIngredients()
    assert(f.availableIngredients.ContainsKey('iron') and #f.availableIngredients['iron']==10)
    local found=false;for _,item in ipairs(f.availableIngredients['iron']) do if item==iron[1] then found=true end end
    assert(found)
end)
R.check('deselecting fabricator removes personal backpack materials',function()
    c.SelectedItem=nil;f.RefreshAvailableIngredients()
    assert(not f.availableIngredients.ContainsKey('iron'))
    c.SelectedItem=fabricatorItem;f.RefreshAvailableIngredients()
end)
R.check('normal fabrication moves genuine backpack ingredients into input',function()
    local recipe
    local recipes=f.fabricationRecipes
    if type(recipes)=='table' then
        for _,value in pairs(recipes) do if tostring(value.TargetItem.Identifier)=='wrench' then recipe=value end end
    else U.each(recipes.Values,function(value) if tostring(value.TargetItem.Identifier)=='wrench' then recipe=value end end) end
    assert(recipe,'no wrench recipe')
    local sources={}
    U.each(recipe.RequiredItems,function(required)
        local prefab;U.each(required.ItemPrefabs,function(p) prefab=prefab or p end)
        assert(prefab)
        for _,item in ipairs(add(tostring(prefab.Identifier),required.Amount)) do sources[#sources+1]=item end
    end)
    f.StartFabricating(recipe,c,false)
    R.consumed={}
    for item in f.InputContainer.Inventory.AllItems do R.consumed[#R.consumed+1]=item end
    assert(#R.consumed>0,'no genuine ingredients moved')
    f.Fabricate() -- advance the native completion step without waiting for the power/timer simulation
end)
function R.finish()
    R.check('native fabrication consumes inputs and creates actual output',function()
        assert(R.consumed and #R.consumed>0)
        for _,item in ipairs(R.consumed) do assert(item.Removed) end
        local found=false
        for item in f.OutputContainer.Inventory.AllItems do if G.id(item)=='wrench' then found=true end end
        assert(found,'no native output wrench')
    end)
    R.check('medical fabricator sees worn backpack contents too',function()
        local medItem=create('medicalfabricator');local med=U.component(medItem,'Fabricator')
        if not med.InputContainer then med.OnItemLoaded() end
        c.SelectedItem=medItem;med.user=c;med.RefreshAvailableIngredients()
        assert(med.availableIngredients.ContainsKey('organicfiber'))
    end)
    local cabinet=create('steelcabinet');R.cabinet=cabinet
    R.check('backpack and nozzle fit native large steel cabinet slots',function()
        assert(cabinet.OwnInventory.TryPutItem(pack,c))
        assert(pack.ParentInventory==cabinet.OwnInventory)
        local nozzle=create('aegisvacuum');assert(cabinet.OwnInventory.TryPutItem(nozzle,c))
    end)
    R.check('selected cabinet grants backpack access and distance is enforced',function()
        c.SelectedItem=cabinet
        assert(G.context(pack,c).valid)
        c.SelectedItem=nil;assert(not G.context(pack,c).valid)
    end)
    R.check('linked cabinet supplies real backpack materials without duplicates',function()
        c.SelectedItem=fabricatorItem;f.Item.linkedTo.Add(cabinet);f.user=c
        f.RefreshAvailableIngredients()
        local count=0;for _,r in ipairs(G.materialRecords(pack)) do if r.kind=='iron' then count=count+1 end end
        assert(f.availableIngredients.ContainsKey('iron') and #f.availableIngredients['iron']==count)
    end)
    R.check('pending salvage in linked cabinet cannot supply ingredients',function()
        G.pending[pack]={products={}}
        f.RefreshAvailableIngredients()
        assert(not f.availableIngredients.ContainsKey('iron') or #f.availableIngredients['iron']==0)
        G.pending[pack]=nil;f.RefreshAvailableIngredients()
    end)
    R.check('native stack withdrawal respects capacity and exact item counts',function()
        c.SelectedItem=cabinet
        local items=add('iron',100)
        local before=#G.contents(pack)
        local ok,moved=G.withdrawStack(G.context(pack,c),items[1].ID)
        assert(ok and moved>0 and moved<=100)
        assert(before-#G.contents(pack)==moved)
        assert(not G.withdrawStack(G.context(pack,c),items[1].ID),'stale source moved twice')
    end)
    local palette={'iron','copper','zinc','tin','lead','steel','carbon','aluminium','titanium','plastic','rubber',
        'organicfiber','titaniumaluminiumalloy','oxygenite','fulgurium','stabilozine','morphine','opium','antibiotics',
        'chlorine','sodium','potassium','sulphur','phosphorus','lithium','uranium','thorium','calcium','silicon',
        'ethanol','screwdriver','wrench','wire','redwire','bluewire','batterycell','oxygentank','bandage','antibleeding1'}
    for _,kind in ipairs(palette) do
        local ok,prefab=pcall(function() return ItemPrefab.Prefabs[kind] end)
        if ok and prefab then add(kind,1) end
    end
    c.SelectedItem=cabinet;G.openPanel(pack);G.updateClient()
    R.check('native icon window has forty slots and metadata for tooltips',function()
        local s=G.snapshot(G.context(pack,c),{})
        assert(#s.rows>8 and #s.rows<=40)
        for _,row in ipairs(s.rows) do assert(row.kind and ItemPrefab.Prefabs[row.kind]) end
        assert(#s.packs==1 and s.packs[1]==pack.ID)
    end)
end
Timer.Wait(R.finish,1000)
