-- Execute only on the disposable dedicated server after `gamemode sandbox; start`.
-- lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/smoke.lua')
local G=BMTCombat
assert(G and #G.patches>=15,'Combat bootstrap did not install hooks')
local U=require('CombatTool.util')
local C=require('CombatTool.config')
local A=require('CombatTool.ai')
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BMT TEST] '..results[#results])
end
local position=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then position=hull.WorldPosition;break end end
local bot=Character.Create('human',position,'bmt-runtime',nil,0,false,true,true,nil,true,false)
bot.GodMode=true
bot.AIController.Enabled=false
local item=Item(ItemPrefab.Prefabs['combatmultitool'],position,nil)
assert(bot.Inventory.TryPutItem(item,bot,{InvSlotType.RightHand+InvSlotType.LeftHand}))
local a=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
local b=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
assert(item.OwnInventory.TryPutItem(a,0,false,false,bot))
assert(item.OwnInventory.TryPutItem(b,1,false,false,bot))
local state=G.state(item)
local ranged=U.component(item,'RangedWeapon')
G.update(.51)
bot.SetInput(InputType.Aim,false,true)
check('two hands and ordinary inventory slots',function()
    assert(G.context(item).valid)
    local any=false
    for slot in item.AllowedSlots do if slot==InvSlotType.Any then any=true end end
    assert(any)
end)
check('native IsEmpty uses slot 0 only',function()
    a.Condition=0;assert(ranged.IsEmpty(bot));assert(G.powered(item,1))
    a.Condition=.4;assert(ranged.IsEmpty(bot),'partial charge was treated as a full shot')
    a.Condition=100;assert(not ranged.IsEmpty(bot))
end)
check('independent source spending',function()
    local before=b.Condition;assert(G.spend(item,0,1));assert(b.Condition==before)
end)
check('native stock battery is allowed by both slot restrictions',function()
    local container=U.component(item,'ItemContainer')
    assert(container.CanBeContained(a,0) and container.CanBeContained(a,1))
end)
check('native damage checkbox authorizes combat while aiming',function()
    local d=LuaUserData.RegisterType('Barotrauma.Items.Components.CustomInterface')
    LuaUserData.MakeFieldAccessible(d,'customInterfaceElementList')
    LuaUserData.MakeMethodAccessible(d,'TickBoxToggled')
    local ci=U.component(item,'CustomInterface')
    ci.TickBoxToggled(ci.customInterfaceElementList[3],true)
    local ctx=G.context(item,bot)
    assert(ctx.damage and ctx.valid and ctx.aim and ctx.mode=='combat')
end)
check('charged native ranged use creates one custom ring',function()
    G.rings={};state.nextShot=0;state.chargeStarted=nil
    ranged.Use(.016,bot)
    G.now=G.now+C.chargeTime+.01
    ranged.Use(.016,bot)
    assert(#G.rings==1)
    for i=1,5 do ranged.Use(.016,bot) end
    assert(#G.rings==1)
end)
check('real world ray cast and ring advance',function()
    G.updateRings(.016)
end)
check('shield activates and spends only slot 1',function()
    local ctx=G.context(item,bot);G.transition(state,ctx)
    local before=a.Condition
    G.updateShield(state,ctx,.016)
    assert(state.shield and a.Condition==before)
    assert(b.Condition<100)
end)
check('damage disable cancels shield and in-flight rings',function()
    U.component(item,'LightComponent').IsOn=false
    local ctx=G.context(item,bot);G.transition(state,ctx)
    assert(not state.shield)
    for _,ring in ipairs(G.rings) do assert(not ring.alive) end
end)
check('native welding and cutting are exclusive',function()
    G.frame=G.frame+1
    local weld=U.component(item,'RepairTool',1)
    local cut=U.component(item,'RepairTool',2)
    U.component(item,'Pump').IsOn=false
    assert(G.use(weld,bot,.016))
    assert(not G.use(cut,bot,.016))
    G.frame=G.frame+1;U.component(item,'Pump').IsOn=true
    assert(not G.use(weld,bot,.016))
    assert(G.use(cut,bot,.016))
end)
check('shield final-energy and three-second lockout',function()
    U.component(item,'LightComponent').IsOn=true
    local ctx=G.context(item,bot);G.transition(state,ctx)
    b.Condition=1;G.updateShield(state,ctx,.016)
    assert(state.shield)
    assert(not G.blockShield(state,2,{x=position.X,y=position.Y}))
    assert(not state.shield and b.Condition==0 and state.brokenUntil>G.now)
end)
check('native AI replaces partial weapon source in its exact slot',function()
    a.Condition=.4
    local source=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
    assert(bot.Inventory.TryPutItem(source,bot,{InvSlotType.Any}))
    bot.AIController.Enabled=true
    local manager=bot.AIController.ObjectiveManager
    local parent=manager.CurrentObjective or AIObjectiveIdle(bot,manager)
    assert(parent)
    assert(A.resupply(bot,item,0,parent,1))
    assert(state.resupply.TargetSlot==0)
    state.resupply.TryComplete(.016)
    assert(G.powered(item,0),'native containment did not replace empty source')
end)
check('native AI fills shield slot without taking weapon source',function()
    state.resupply.TryComplete(.016)
    local weaponSource=item.OwnInventory.GetItemAt(0)
    b.Condition=0
    local fresh=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
    assert(bot.Inventory.TryPutItem(fresh,bot,{InvSlotType.Any}))
    local manager=bot.AIController.ObjectiveManager
    local parent=manager.CurrentObjective or AIObjectiveIdle(bot,manager)
    state.nextResupply=0
    assert(A.resupply(bot,item,1,parent))
    assert(state.resupply.TargetSlot==1)
    state.resupply.TryComplete(.016)
    assert(G.powered(item,1))
    assert(item.OwnInventory.GetItemAt(0)==weaponSource)
end)
BMTTestBot=bot;BMTTestGun=item
File.Write('LocalMods/MULTI-TOOL-V2/runtime-results.txt',table.concat(results,'\n'))
print('[BMT TEST] Wrote '..#results..' checks to bmt-runtime-results.txt')
