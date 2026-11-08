-- Native singleplayer integration probe. Disposable .runtime client only.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local U=require('CombatTool.util')
local G=BMTVacuum
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BACKPACK] '..results[#results])
    File.Write('LocalMods/MULTI-TOOL-V2/backpack-workflow-results.txt',table.concat(results,'\n'))
end
local room
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then room=hull;break end end
assert(room)
local c=Character.Create('human',room.WorldPosition,'bmt-backpack-test',nil,0,false,true,true,nil,true,false)
c.GodMode=true;c.AIController.Enabled=false;c.TeamID=CharacterTeamType.Team1
Character.Controlled=c
local function create(kind) return Item(ItemPrefab.Prefabs[kind],room.WorldPosition,nil) end
local pack,page=create('aegisvacuumpack'),create('aegisvacuumpage')
assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
assert(pack.OwnInventory.TryPutItem(page,c))
local ctx=G.context(pack,c)
local iron=create('iron');assert(G.insert(pack,iron,c))
check('native batch takes multiple unstackable welders and preserves overflow',function()
    local welders={}
    for i=1,40 do
        local item=create('weldingtool');item.Condition=30+i;welders[#welders+1]=item
        assert(G.insert(pack,item,c))
    end
    local ok,moved=G.withdrawBatch(ctx,{welders[1].ID,welders[1].ID,65534},true)
    assert(ok and moved>1 and moved<40,'unexpected native carry count '..tostring(moved))
    local carried,stored=0,0
    for i,item in ipairs(welders) do
        assert(math.abs(item.Condition-(30+i))<.01,'item condition changed')
        if G.has(pack,item) then stored=stored+1 else assert(item.ParentInventory==c.Inventory);carried=carried+1 end
    end
    assert(carried==moved and stored==40-moved and G.has(pack,iron))
    for _,item in ipairs(welders) do if item.ParentInventory==c.Inventory then item.Remove() end end
end)
check('native floor filter skips contents and collects loaded floor bags intact',function()
    local bag,copper=create('duffelbag'),create('copper')
    assert(bag.OwnInventory.TryPutItem(copper,c))
    assert(G.setLooseOnly(ctx,true) and G.looseOnly(pack))
    assert(not G.pickupTarget(copper,ctx) and G.pickupTarget(bag,ctx)==bag)
    local wrench=create('wrench');assert(G.pickupTarget(wrench,ctx)==wrench)
    assert(G.setLooseOnly(ctx,false) and G.pickupTarget(copper,ctx)==bag)
end)
check('native merchant lists real stored iron and keeps condition/theft/lock rules',function()
    LuaUserData.RegisterType('Barotrauma.CargoManager')
    local Manager=LuaUserData.CreateStatic('Barotrauma.CargoManager')
    local manager=Manager(nil)
    local function listed(item)
        local found=false;U.each(manager.GetSellableItems(c),function(it) if it==item then found=true end end);return found
    end
    assert(listed(iron),'stored iron absent from character selling list')
    assert(not pack.OwnInventory.Container.DrawInventory and not page.OwnInventory.Container.DrawInventory)
    iron.Condition=10;assert(not listed(iron),'damaged item bypassed merchant rules');iron.Condition=iron.MaxCondition
    iron.SpawnedInCurrentOutpost=true;assert(not listed(iron),'outpost stock bypassed merchant rules');iron.SpawnedInCurrentOutpost=false
    LuaUserData.RegisterType('System.Collections.Generic.List`1[[Barotrauma.CargoManager+SoldEntity, Barotrauma]]')
    LuaUserData.MakePropertyAccessible(LuaUserData.RegisterType('Barotrauma.CargoManager'),'SoldEntities')
    local SoldEntity=LuaUserData.CreateStatic('Barotrauma.CargoManager+SoldEntity')
    local Status=LuaUserData.CreateEnumTable('Barotrauma.CargoManager+SoldEntity+SellStatus')
    manager.SoldEntities.Add(SoldEntity(iron,Status.Confirmed));assert(not listed(iron),'confirmed item sold twice')
    manager.SoldEntities.Clear()
    G.pending[pack]={};assert(not listed(iron));G.pending[pack]=nil
    page.OwnInventory.Locked=true;assert(not listed(iron));page.OwnInventory.Locked=false
    assert(listed(iron) and not listed(page),'internal page leaked into the shop')
end)
check('native drag slot path inserts the original item without swapping worn pack',function()
    local incoming=create('copper');assert(c.Inventory.TryPutItem(incoming,c,{InvSlotType.Any}))
    local env={CLIENT=true,Character=Character,Entity=Entity,LuaUserData=LuaUserData,Timer=Timer,
        Inventory={DraggingItems={incoming}},PlayerInput={PrimaryMouseButtonReleased=function() return true end}}
    require('SalvageVacuum.manual').install(G,env)
    G.lastRequest[c]=nil
    local slot=c.Inventory.FindIndex(pack)
    assert(slot>=0 and c.Inventory.TryPutItem(incoming,slot,false,true,c))
    assert(G.has(pack,incoming) and c.Inventory.GetItemInLimbSlot(InvSlotType.Bag)==pack,'drag swapped the pack or lost incoming item')
    require('SalvageVacuum.manual').install(G,_G)
end)
check('real localized GUI shows batch action and floor toggle',function()
    local panel=G.openPanel(pack)
    G.onSnapshot(G.snapshot(ctx,{}));G.updateClient()
    local batch,loose,names=false,false,{}
    U.each(panel.GetAllChildren(),function(w)
        if LuaUserData.IsTargetType(w,'Barotrauma.GUIButton') then
            names[#names+1]=tostring(w.Text)
            if tostring(w.Text):lower()==tostring(TextManager.Get('vacuum.takeselected')):lower() then batch=true end
            if tostring(w.Text):lower()==tostring(TextManager.Get('vacuum.looseonly')):lower() then loose=true end
        end
    end)
    assert(batch and loose and not G.visualError,'batch='..tostring(batch)..' loose='..tostring(loose)..' visual='..tostring(G.visualError)..' labels='..table.concat(names,','))
end)
check('native container inventory drag uses the matching overload and slot parameter',function()
    local cabinet=create('mediumsteelcabinet')
    assert(cabinet.OwnInventory.TryPutItem(pack,c))
    c.SelectedItem=cabinet
    local incoming=create('copper');assert(c.Inventory.TryPutItem(incoming,c,{InvSlotType.Any}))
    local env={CLIENT=true,Character=Character,Entity=Entity,LuaUserData=LuaUserData,Timer=Timer,
        Inventory={DraggingItems={incoming}},PlayerInput={PrimaryMouseButtonReleased=function() return true end}}
    require('SalvageVacuum.manual').install(G,env);G.lastRequest[c]=nil
    local slot=cabinet.OwnInventory.FindIndex(pack)
    assert(slot>=0 and cabinet.OwnInventory.TryPutItem(incoming,slot,false,true,c))
    assert(G.has(pack,incoming) and pack.ParentInventory==cabinet.OwnInventory)
    require('SalvageVacuum.manual').install(G,_G)
    assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}));c.SelectedItem=nil
end)
local empty=create('aegisvacuumpack')
local tool=create('wrench')
check('empty native pack accepts manual request before first storage page exists',function()
    assert(c.Inventory.TryPutItem(empty,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
    assert(c.Inventory.TryPutItem(tool,c,{InvSlotType.Any}))
    assert(G.insertBatch(G.context(empty,c),{tool.ID}))
end)
Timer.Wait(function()
    check('first-page spawn retry finishes and preserves the original tool',function()
        assert(G.has(empty,tool) and not tool.Removed and #G.pages(empty)==1)
    end)
end,1500)
