-- Disposable singleplayer client only; test native Bag, GUI and FastLoot safety.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTVacuum
local U=require('CombatTool.util')
LuaUserData.RegisterType('Barotrauma.GameMain')
local Main=LuaUserData.CreateStatic('Barotrauma.GameMain')
LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
local R={rows={}}
VacuumBagTest=R
local function check(name,fn)
    local ok,err=pcall(fn)
    R.rows[#R.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM BAG] '..R.rows[#R.rows])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-bag-results.txt',table.concat(R.rows,'\n'))
end
local room;for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then room=hull;break end end
assert(room)
local c=Character.Create('human',room.WorldPosition,'vacuum-bag-test',nil,0,false,true,true,nil,true,false)
c.GodMode=true;c.AIController.Enabled=false;c.TeamID=CharacterTeamType.Team1
for other in Character.CharacterList do if other.AIController then other.AIController.Enabled=false end end
Character.Controlled=c
local function create(id) return Item(assert(ItemPrefab.Prefabs[id],id),room.WorldPosition,nil) end
local pack,vacuum,battery,page=create('aegisvacuumpack'),create('aegisvacuum'),create('batterycell'),create('aegisvacuumpage')
R.character,R.pack,R.vacuum=c,pack,vacuum
check('native backpack equips in Bag while vacuum occupies both hands',function()
    assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
    assert(c.Inventory.GetItemInLimbSlot(InvSlotType.Bag)==pack)
    assert(c.Inventory.TryPutItem(vacuum,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
    assert(c.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)==vacuum)
    assert(c.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)==vacuum)
    assert(U.component(pack,'Wearable') and c.HasEquippedItem(pack))
    assert(vacuum.OwnInventory.TryPutItem(battery,0,false,false,c))
    assert(G.context(vacuum,c).valid)
end)
assert(pack.OwnInventory.TryPutItem(page,c))
local wrench,crate,ammo,suit,tank=create('wrench'),create('metalcrate'),create('smgmagazine'),create('divingsuit'),create('oxygentank')
ammo.Condition=37.25;tank.Condition=46.75;wrench.Quality=3
assert(crate.OwnInventory.TryPutItem(ammo,c));assert(suit.OwnInventory.TryPutItem(tank,c))
for _,item in ipairs({wrench,crate,suit}) do assert(G.insert(pack,item,c)) end
check('real portable tools, loaded ammunition crates and suits remain loot',function()
    for _,item in ipairs({wrench,crate,suit}) do assert(G.portable(item),G.id(item)) end
    assert(#G.contents(pack)==3 and ammo.ParentInventory==crate.OwnInventory and tank.ParentInventory==suit.OwnInventory)
end)
check('native hatch and stationary junction box are never loot',function()
    for _,id in ipairs({'hatch','junctionbox'}) do
        local item=create(id)
        assert(not G.portable(item),id)
        assert(G.pickupTarget(item,G.context(vacuum,c))==nil,id)
    end
end)
check('loose wire is loot, an actually connected wire is protected',function()
    local item=create('redwire');local wire=U.component(item,'Wire')
    assert(wire and G.portable(item))
    local box=create('junctionbox');local connection
    U.each(U.component(box,'ConnectionPanel').Connections,function(pin) connection=connection or pin end)
    assert(connection)
    assert(wire.TryConnect(connection,false,false))
    assert(not G.portable(item))
    assert(G.pickupTarget(item,G.context(vacuum,c))==nil)
end)
check('spare backpack audits its native storage pages and rejects structural contents',function()
    local spare,storage,tool=create('aegisvacuumpack'),create('aegisvacuumpage'),create('wrench')
    assert(spare.OwnInventory.TryPutItem(storage,c))
    assert(storage.OwnInventory.TryPutItem(tool,c))
    assert(G.pickupTarget(spare,G.context(vacuum,c))==spare)
    local door=create('hatch')
    assert(storage.OwnInventory.TryPutItem(door,1,false,false,c))
    assert(G.pickupTarget(spare,G.context(vacuum,c))==nil)
end)
vacuum.Drop(c)
G.closePanel();G.updateClient()
check('visible native storage button works with backpack only',function()
    assert(G.storageButton.Visible and G.storageButton.Rect.Width>0)
    assert(G.storageButton.Rect.Y>=0 and G.storageButton.Rect.Bottom<=Main.GraphicsHeight)
end)
Timer.Wait(function()
    check('native button opens populated window without a held vacuum',function()
        assert(G.storageButton.OnClicked.Invoke(G.storageButton,nil))
        G.updateClient()
        assert(not G.storageButton.Visible)
        assert(#G.contents(pack)==3)
    end)
end,1800)
