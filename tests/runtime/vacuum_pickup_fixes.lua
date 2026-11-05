-- Regression probe in a disposable native singleplayer client only.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local U=require('CombatTool.util')
local G=BMTVacuum
local results,created={},{}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[PICKUP FIXES] '..results[#results])
    File.Write('LocalMods/MULTI-TOOL-V2/pickup-fixes-results.txt',table.concat(results,'\n'))
end
local c=Character.Controlled
local pos=c.WorldPosition
local function create(kind)
    local item=Item(ItemPrefab.Prefabs[kind],pos,nil);created[#created+1]=item;return item
end
local pack=create('aegisvacuumpack')
assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag,InvSlotType.Any}))
local page=create('aegisvacuumpage');assert(pack.OwnInventory.TryPutItem(page,c))
local ctx={valid=true,pack=pack,owner=c}
check('wire connected only at either native end cannot be collected',function()
    local box=create('junctionbox');local pin
    U.each(U.component(box,'ConnectionPanel').Connections,function(p) pin=pin or p end)
    for _,endpoint in ipairs({0,1}) do
        local item=create('redwire');local wire=U.component(item,'Wire')
        assert(G.portable(item),'loose wire rejected')
        assert(wire.Connect(pin,endpoint,false,false))
        assert(not G.portable(item),'connected native end '..endpoint..' was collected')
        assert(G.pickupTarget(item,ctx)==nil)
    end
end)
check('duffel bag retains excluded iron while copper is collected',function()
    local bag=create('duffelbag');local iron,copper=create('iron'),create('copper')
    assert(bag.OwnInventory.TryPutItem(iron,c));assert(bag.OwnInventory.TryPutItem(copper,c))
    assert(G.setExcluded(ctx,'iron',true))
    assert(G.pickupTarget(bag,ctx)==nil and G.pickupTarget(iron,ctx)==nil)
    assert(G.pickupTarget(copper,ctx)==copper)
    assert(G.insert(pack,copper,c))
    assert(G.has(pack,copper) and iron.ParentInventory==bag.OwnInventory and not bag.ParentInventory)
    assert(G.setExcluded(ctx,'iron',false))
    assert(G.pickupTarget(iron,ctx)==bag,'unfiltered bag was not kept intact')
end)
check('production suction collects floor loot and allowed bag contents',function()
    local bot=Character.Create('human',Submarine.MainSub.WorldPosition+Vector2(0,2500),'bmt-pickup-loop',nil,0,false,true,true,nil,true,false)
    created[#created+1]=bot;bot.GodMode=true;bot.AIController.Enabled=false
    local nozzle,battery,bagPack=create('aegisvacuum'),create('batterycell'),create('aegisvacuumpack')
    local storage=create('aegisvacuumpage')
    assert(bot.Inventory.TryPutItem(bagPack,bot,{InvSlotType.Bag}))
    assert(bot.Inventory.TryPutItem(nozzle,bot,{InvSlotType.RightHand+InvSlotType.LeftHand}))
    assert(nozzle.OwnInventory.TryPutItem(battery,0,false,false,bot))
    assert(bagPack.OwnInventory.TryPutItem(storage,bot))
    local p,d=G.muzzle(nozzle),G.direction(nozzle)
    local bag,iron,copper,wrench=create('duffelbag'),create('iron'),create('copper'),create('wrench')
    assert(bag.OwnInventory.TryPutItem(iron,bot));assert(bag.OwnInventory.TryPutItem(copper,bot))
    local ahead=Vector2(p.x+d.x*40,p.y+d.y*40)
    bag.Move(ahead-bag.WorldPosition,true);wrench.Move(ahead-wrench.WorldPosition,true)
    local context=G.context(nozzle,bot);assert(context.valid)
    assert(G.setExcluded(context,'iron',true))
    local pickup=G.pickupTarget
    local owned={[bag]=true,[iron]=true,[copper]=true,[wrench]=true}
    -- Keep this probe limited to its own fixtures while using the real world refresh.
    local examined=0
    G.pickupTarget=function(item,ctx) if owned[item] then examined=examined+1;return pickup(item,ctx) end end
    local ok,err=pcall(function()
        bot.SetInput(InputType.Aim,false,true)
        local ranged=U.component(nozzle,'RangedWeapon')
        for i=1,100 do
            ranged.Use(.1,bot);G.update(.1)
            if G.has(bagPack,copper) and G.has(bagPack,wrench) then break end
        end
        assert(G.has(bagPack,copper) and G.has(bagPack,wrench),
            'active suction missed nearby loot: copper='..tostring(G.has(bagPack,copper))..
            ' wrench='..tostring(G.has(bagPack,wrench))..' examined='..examined..
            ' aim='..tostring(G.context(nozzle).aim)..' active='..tostring(G.states[nozzle] and G.states[nozzle].active))
        assert(iron.ParentInventory==bag.OwnInventory and not bag.ParentInventory,
            'suction moved the excluded contents or the mixed bag')
    end)
    G.pickupTarget=pickup
    assert(ok,err)
end)
local panel=G.openPanel(pack)
local category
U.each(panel.GetAllChildren(),function(w)
    if LuaUserData.IsTargetType(w,'Barotrauma.GUIDropDown') then category=w end
end)
assert(category)
category.Dropped=true;GUI.GUI.KeyboardDispatcher.Subscriber=category
G.updateClient()
Timer.Wait(function()
    check('native category popup is above tiles and receives mouse focus',function()
        assert(category.ListBox.UpdateOrder>panel.UpdateOrder)
        local descriptor=LuaUserData.RegisterType('Barotrauma.PlayerInput')
        LuaUserData.MakeFieldAccessible(descriptor,'mouseState')
        local input=LuaUserData.CreateStatic('Barotrauma.PlayerInput')
        LuaUserData.RegisterType('Microsoft.Xna.Framework.Input.MouseState')
        local mouse=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Input.MouseState')
        local old=input.mouseState
        local rect=category.ListBox.Rect
        local ok,err=pcall(function()
            input.mouseState=mouse(rect.X+20,rect.Y+rect.Height/2,0,0,0,0,0,0)
            local focused=GUI.GUI.UpdateMouseOn()
            assert(focused and (focused==category.ListBox or category.ListBox.IsParentOf(focused)),
                'mouse hit an item tile under the category menu')
        end)
        input.mouseState=old
        assert(ok,err)
        category.ListBox.Select(2)
        assert(category.SelectedItemData=='medical','native category selection did not reach the panel')
    end)
    check('closing popup releases keyboard focus',function()
        category.Dropped=true;GUI.GUI.KeyboardDispatcher.Subscriber=category
        G.closePanel()
        assert(not category.Dropped and GUI.GUI.KeyboardDispatcher.Subscriber~=category)
    end)
    Timer.Wait(function()
        for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
    end,1500)
end,100)
