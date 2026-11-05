-- Run only in a disposable singleplayer client with production 1.3.4 loaded.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTVacuum
local U=require('CombatTool.util')
local R={rows={}}
Vacuum134=R
function R.check(name,fn)
    local ok,err=pcall(fn)
    R.rows[#R.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM 134] '..R.rows[#R.rows])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-134-results.txt',table.concat(R.rows,'\n'))
end
local room;for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then room=hull;break end end
assert(room)
local function create(kind) return Item(ItemPrefab.Prefabs[kind],room.WorldPosition,nil) end
local c=Character.Create('human',room.WorldPosition,'vacuum-134',nil,0,false,true,true,nil,true,false)
c.GodMode=true;c.TeamID=CharacterTeamType.Team1;c.AIController.Enabled=false
for other in Character.CharacterList do if other.AIController then other.AIController.Enabled=false end end
Character.Controlled=c;R.character=c
local pack=create('aegisvacuumpack');R.pack=pack
assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
for i=1,2 do assert(pack.OwnInventory.TryPutItem(create('aegisvacuumpage'),c)) end
local function add(kind,n)
    local out={};for i=1,(n or 1) do local it=create(kind);assert(G.insert(pack,it,c));out[#out+1]=it end;return out
end
R.iron=add('iron',50)
local ctx=G.context(pack,c)
R.check('one click fills exactly one native inventory slot',function()
    local ok,moved=G.withdrawStack(ctx,R.iron[1].ID)
    local limit=R.iron[1].Prefab.GetMaxStackSize(c.Inventory)
    assert(ok and moved==limit,'moved '..tostring(moved)..' limit '..tostring(limit))
    local occupied=0
    for i=0,c.Inventory.Capacity-1 do
        if c.Inventory.SlotTypes[i]==InvSlotType.Any and c.Inventory.GetItemAt(i) then occupied=occupied+1;R.slot=i end
    end
    assert(occupied==1,'stack spread to '..occupied..' slots')
    R.limit=limit
end)
R.check('partial native stack is filled without opening another slot',function()
    local movedBack={};U.each(c.Inventory.GetItemsAt(R.slot),function(it) movedBack[#movedBack+1]=it end)
    for i=1,#movedBack-2 do assert(G.insert(pack,movedBack[i],c)) end
    local target;for _,it in ipairs(G.contents(pack)) do if G.id(it)=='iron' then target=it;break end end
    local ok,moved=G.withdrawStack(ctx,target.ID)
    assert(ok and moved==R.limit-2)
    local occupied=0
    for i=0,c.Inventory.Capacity-1 do
        if c.Inventory.SlotTypes[i]==InvSlotType.Any and c.Inventory.GetItemAt(i) then occupied=occupied+1 end
    end
    assert(occupied==1)
end)
add('antibleeding1',2);add('wrench',1);add('oxygentank',1)
R.check('native prefab category works with combined search',function()
    local s=G.snapshot(ctx,{category='material',search='iron'})
    assert(#s.rows==1 and s.rows[1].kind=='iron','category '..tostring(R.iron[1].Prefab.Category))
    assert(#G.snapshot(ctx,{category='medical',search='iron'}).rows==0)
end)
R.check('native filter catalog and nested crate exclusion',function()
    assert(#G.filterCatalog({category='all',search=''})>100)
    assert(G.setExcluded(ctx,'iron',true) and G.filter(pack).iron)
    local crate=create('metalcrate');local nested=create('iron')
    assert(crate.OwnInventory.TryPutItem(nested,c))
    assert(not G.acceptsLoot(pack,crate) and not G.pickupTarget(crate,{owner=c,pack=pack}))
    R.crate=crate;R.nested=nested
    G.clearFilters();assert(G.filter(pack).iron)
    assert(G.setExcluded(ctx,'iron',false) and G.acceptsLoot(pack,crate))
end)
R.check('native dropdown, icons and filter panel construct successfully',function()
    local frame=G.openPanel(pack);assert(frame)
    local dropdown
    U.each(frame.Children,function(child)
        if LuaUserData.IsTargetType(child,'Barotrauma.GUIDropDown') then dropdown=child end
    end)
    assert(dropdown,'missing category dropdown')
    LuaUserData.RegisterType('Barotrauma.GUIDropDown+OnSelectedHandler')
    dropdown.OnSelected.Invoke(nil,'medical')
    G.now=G.now+1
    local s=G.snapshot(ctx,{filters=true,category='medical',search=''})
    assert(#s.rows>0 and s.rows[1].kind and s.filters)
end)
R.check('native suction loop and grinder sound channels start and stop',function()
    local channel=SoundPlayer.PlaySound('aegis_vacuum_suction',c.WorldPosition)
    assert(channel and channel.IsPlaying,'suction sound missing')
    channel.Looping=true;channel.Position=Vector3(c.WorldPosition.X,c.WorldPosition.Y,0)
    channel.FadeOutAndDispose()
    channel=SoundPlayer.PlaySound('aegis_vacuum_salvage',c.WorldPosition)
    assert(channel and channel.IsPlaying,'salvage sound missing');channel.FadeOutAndDispose()
    local nozzle=create('aegisvacuum');assert(c.Inventory.TryPutItem(nozzle,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
    assert(nozzle.OwnInventory.TryPutItem(create('batterycell'),c));R.nozzle=nozzle
    G.onSalvage(nozzle.ID);G.updateAudio();G.clearAudio()
end)
R.check('native trash preview includes nested contents and needs exact confirmation',function()
    assert(G.insert(pack,R.crate,c))
    local ticket=G.prepareTrash(ctx,R.crate.ID,false)
    assert(ticket and ticket.count==2 and not R.crate.Removed)
    assert(not G.confirmTrash(ctx,R.crate.ID,ticket.token+1))
    assert(G.confirmTrash(ctx,R.crate.ID,ticket.token))
    R.deleted=R.crate
end)
function R.finish()
    R.check('native remove queue deletes both crate and nested item completely',function()
        assert(R.deleted and R.deleted.Removed and R.nested.Removed)
        assert(not G.pending[pack] and not G.reserved[R.nested])
    end)
    G.openPanel(pack)
    G.updateClient()
end
Timer.Wait(R.finish,1000)
