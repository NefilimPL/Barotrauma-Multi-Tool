-- Real isolated multiplayer fixture. Native spawner publishes every entity to clients.
assert(SERVER and Game.RoundStarted)
local G=BMTVacuum
local R={rows={},spawned=0,sources={}};VacuumGridServer=R
function R.check(name,fn)
    local ok,err=pcall(fn)
    R.rows[#R.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM GRID MP] '..R.rows[#R.rows])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-grid-server-results.txt',table.concat(R.rows,'\n'))
end
local client;for player in Client.ClientList do if player.Name=='VacuumGrid' then client=player end end
assert(client and client.Character)
R.client=client;local c=client.Character
if c.IsDead then c.Revive(true,true) end
c.GodMode=true;c.Oxygen=100;c.SetAllDamage(0,0,0)
local old=c.Inventory.GetItemInLimbSlot(InvSlotType.Bag);if old then old.Drop(c) end
local function spawn(kind,inventory,callback)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],inventory,nil,nil,callback,false)
end
local palette={'iron','copper','zinc','tin','lead','steel','carbon','aluminium','titanium','plastic','rubber',
    'organicfiber','titaniumaluminiumalloy','fulgurium','stabilozine','morphine','opium','antibiotics',
    'chlorine','sodium','potassium','sulphur','phosphorus','lithium','uranium','thorium','calcium','silicon',
    'ethanol','screwdriver','wrench','redwire','bluewire','batterycell','oxygentank','antibleeding1'}
local kinds={}
for _,kind in ipairs(palette) do local ok,p=pcall(function() return ItemPrefab.Prefabs[kind] end);if ok and p then kinds[#kinds+1]=kind end end
local expected=700+#kinds;R.expected=expected
local function done(item)
    R.sources[#R.sources+1]=item
    if G.id(item)=='iron' and not R.iron then R.iron=item end
    R.spawned=R.spawned+1
    if R.spawned==expected then
        R.check('authoritative native fixture has more than forty groups',function()
            local s=G.snapshot(G.context(R.pack,c),{})
            assert(s.count==expected and s.groups>40 and #s.rows==40 and s.pages==2)
        end)
        print('[VACUUM GRID MP] FIXTURE READY '..expected)
    end
end
spawn('aegisvacuumpack',c.Inventory,function(pack)
    R.pack=pack;pack.AddTag('bmtgrid_mp_pack');assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
    local pageNumber=0
    local function nextPage()
        pageNumber=pageNumber+1
        local number=pageNumber
        spawn('aegisvacuumpage',pack.OwnInventory,function(page)
            if number<=7 then for i=1,100 do spawn('iron',page.OwnInventory,done) end
            else for _,kind in ipairs(kinds) do spawn(kind,page.OwnInventory,done) end end
            if number<8 then Timer.Wait(nextPage,100) end
        end)
    end
    nextPage()
end)
function R.verifyTransfer()
    R.check('remote stack preserves all original entities under native capacity limits',function()
        local stored,moved=0,0
        for _,item in ipairs(R.sources) do
            assert(not item.Removed,'source entity removed')
            if G.has(R.pack,item) then stored=stored+1
            elseif item.ParentInventory==R.client.Character.Inventory then moved=moved+1
            else error('source moved outside allowed inventories') end
        end
        assert(moved>0 and moved<=100 and stored+moved==R.expected)
        assert(#G.contents(R.pack)==stored)
    end)
end
