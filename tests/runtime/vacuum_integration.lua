-- Test only, run on the disposable Sandbox server.
-- lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/vacuum_integration.lua')
local G=BMTVacuum
local U=require('CombatTool.util')
local Core=require('SalvageVacuum.core')
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM TEST] '..results[#results])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-results.txt',table.concat(results,'\n'))
end
local position=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then position=hull.WorldPosition;break end end
local bot=Character.Create('human',position,'bmt-vacuum-runtime',nil,0,false,true,true,nil,true,false)
bot.GodMode=true;bot.AIController.Enabled=false
local function create(id) return Item(ItemPrefab.Prefabs[id],position,nil) end
local pack=create('aegisvacuumpack')
local vacuum=create('aegisvacuum')
local battery=create('batterycell')
assert(bot.Inventory.TryPutItem(pack,bot,{InvSlotType.Any}))
assert(bot.Inventory.TryPutItem(vacuum,bot,{InvSlotType.RightHand+InvSlotType.LeftHand}))
assert(vacuum.OwnInventory.TryPutItem(battery,0,false,false,bot))
local page=create('aegisvacuumpage')
assert(pack.OwnInventory.TryPutItem(page,bot))
_G.VacuumTest={bot=bot,pack=pack,vacuum=vacuum,battery=battery,page=page,results=results,check=check,create=create}
check('separate parts, both hands and vacuum battery',function()
    local ctx=G.context(vacuum,bot)
    assert(ctx.valid and ctx.pack==pack)
    assert(G.source(vacuum)==battery and #G.contents(pack)==0)
    local before=battery.Condition;assert(G.spend(vacuum,1));assert(battery.Condition==before-1)
end)
check('100+1 actual items retain condition and group correctly',function()
    local page2=create('aegisvacuumpage');assert(pack.OwnInventory.TryPutItem(page2,bot))
    for i=1,101 do
        local item=create('iron');item.Condition=20+i%70
        assert(G.insert(pack,item,bot),'insert '..i)
    end
    local groups=Core.groups(G.records(G.contents(pack)))
    assert(#groups==2 and #groups[1].items==100 and #groups[2].items==1)
end)
check('loaded crate is stored whole and nested content is preserved',function()
    local crate=create('metalcrate');local ammo=create('smgmagazine')
    assert(crate.OwnInventory.TryPutItem(ammo,bot))
    local before=ammo.Condition;assert(G.insert(pack,crate,bot))
    assert(ammo.ParentInventory==crate.OwnInventory and ammo.Condition==before)
    assert(G.has(pack,ammo))
    _G.VacuumTest.crate=crate;_G.VacuumTest.ammo=ammo
end)
check('portable loot includes a worn suit on a corpse',function()
    local corpse=Character.Create('human',position,'bmt-vacuum-corpse',nil,0,false,true,true,nil,true,false)
    corpse.AIController.Enabled=false
    local suit=create('divingsuit')
    assert(corpse.Inventory.TryPutItem(suit,corpse,{InvSlotType.OuterClothes}))
    corpse.Kill(CauseOfDeathType.Unknown)
    assert(G.pickupTarget(suit,G.context(vacuum))==suit)
    assert(G.insert(pack,suit,bot))
    _G.VacuumTest.suit=suit
end)
check('live character gear cannot be suctioned',function()
    assert(G.pickupTarget(battery,G.context(vacuum))==nil)
end)
check('loaded crates and suits can be retrieved onto the ground',function()
    local crate,ammo,suit=_G.VacuumTest.crate,_G.VacuumTest.ammo,_G.VacuumTest.suit
    local ctx=G.context(vacuum)
    assert(G.drop(ctx,crate.ID) and crate.ParentInventory==nil)
    assert(ammo.ParentInventory==crate.OwnInventory)
    assert(G.insert(pack,crate,bot))
    assert(G.drop(ctx,suit.ID) and suit.ParentInventory==nil)
    assert(G.insert(pack,suit,bot))
end)
check('backpack is accessible with no held vacuum or charged battery',function()
    vacuum.Drop(bot);battery.Condition=0
    assert(G.context(pack,bot).valid and not G.context(vacuum).valid)
    assert(G.drop(G.context(pack,bot),_G.VacuumTest.crate.ID))
    assert(G.insert(pack,_G.VacuumTest.crate,bot))
    assert(bot.Inventory.TryPutItem(vacuum,bot,{InvSlotType.RightHand+InvSlotType.LeftHand}))
    assert(not G.startSalvage(G.context(vacuum)))
    battery.Condition=100
end)
check('locked source inventory cannot be emptied by suction',function()
    local crate=_G.VacuumTest.crate
    G.drop(G.context(pack,bot),crate.ID)
    crate.OwnInventory.Locked=true
    assert(G.pickupTarget(_G.VacuumTest.ammo,G.context(vacuum))==nil)
    crate.OwnInventory.Locked=false
    assert(G.insert(pack,crate,bot))
end)
check('one-button salvage uses recipe and keeps things without recipes',function()
    local unbreakable=create('aegisvacuumpack')
    assert(G.insert(pack,unbreakable,bot))
    _G.VacuumTest.unbreakable=unbreakable
    assert(G.startSalvage(G.context(vacuum)))
    assert(not G.startSalvage(G.context(vacuum)))
end)
Timer.Wait(function()
    check('salvage completes, keeps unknown recipe and keeps powered vacuum',function()
        assert(not G.jobs[pack] and not G.pending[pack],'job still active')
        assert(not _G.VacuumTest.unbreakable.Removed and G.has(pack,_G.VacuumTest.unbreakable))
        assert(not battery.Removed and vacuum.OwnInventory.GetItemAt(0)==battery)
        assert(G.charge(vacuum)>0)
    end)
    check('unbreakable contents survive removal of a crate casing',function()
        local crate=create('toolbox');local raw=create('iron')
        assert(crate.OwnInventory.TryPutItem(raw,bot))
        assert(G.insert(pack,crate,bot))
        local job={ctx=G.context(vacuum),items={crate},index=1,done=0,skipped=0}
        G.jobs[pack]=job;G.processSalvage(job)
        assert(raw.ParentInventory~=crate.OwnInventory and not raw.Removed)
        Timer.Wait(function() check('crate materials and preserved raw item finish together',function()
            assert(crate.Removed and not raw.Removed and G.has(pack,raw))
        end) end,1000)
    end)
end,25000)
Timer.Wait(function()
    check('native suction collects a loose wrench',function()
        local p,d=G.muzzle(vacuum),G.direction(vacuum)
        local item=Item(ItemPrefab.Prefabs['wrench'],Vector2(p.x+d.x*20,p.y+d.y*20),nil)
        bot.SetInput(InputType.Aim,false,true)
        local ranged=U.component(vacuum,'RangedWeapon')
        for i=1,50 do
            ranged.Use(.1,bot);G.update(.1)
            if G.has(pack,item) then break end
        end
        assert(G.has(pack,item),'loose tool not collected')
    end)
end,28000)
