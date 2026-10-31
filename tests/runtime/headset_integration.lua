-- Disposable server only. Run after gamemode sandbox/start; never package.
local G=BMTHeadsets
assert(G and #G.patches>=4,'headset bootstrap missing')
local U=require('CombatTool.util')
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    local result=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    results[#results+1]=result;print('[HEADSET TEST] '..result)
end
local position=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then position=hull.WorldPosition;break end end
local character=Character.Create('human',position,'headset-runtime',nil,0,false,true,true,nil,true,false)
character.AIController.Enabled=false
local item=Item(ItemPrefab.Prefabs['aegisheadsetmk2'],position,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
assert(character.Inventory.TryPutItem(item,character,{InvSlotType.Headset}))
assert(item.OwnInventory.TryPutItem(cell,0,false,false,character))
check('native headset slot and battery container',function()
    assert(G.equipped(character)==item and G.source(item)==cell)
    assert(item.OwnInventory.Capacity==1)
    assert(U.component(item,'WifiComponent').Range==35000)
end)
check('native gradual burn treatment and energy cost',function()
    cell.Condition=100
    character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb,AfflictionPrefab.Prefabs['burn'].Instantiate(10))
    local before=character.CharacterHealth.GetAfflictionStrengthByIdentifier('burn',true)
    G.heal(character,item,1)
    local after=character.CharacterHealth.GetAfflictionStrengthByIdentifier('burn',true)
    assert(after<before and cell.Condition<100)
end)
check('native full attack blocked before health damage',function()
    character.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
    local before=character.Vitality
    character.AddDamage(position,{AfflictionPrefab.Prefabs['burn'].Instantiate(100)},0,false,Vector2.Zero,nil,1)
    assert(not character.IsDead and character.Vitality==before,'attack reached wearer')
    assert(math.abs(G.energy(item)-87.5)<.01,'attack not charged exactly once')
end)
check('native partial battery passes remaining attack damage',function()
    character.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=1.25
    local before=character.Vitality
    character.AddDamage(position,{AfflictionPrefab.Prefabs['burn'].Instantiate(20)},0,false,Vector2.Zero,nil,1)
    assert(cell.Condition==0 and character.Vitality<before)
    assert(math.abs(character.CharacterHealth.GetAfflictionStrengthByIdentifier('burn',true)-10)<.01,'partial damage must be exactly 10')
end)
check('native basic headset receives ordinary attacks',function()
    local basic=Item(ItemPrefab.Prefabs['aegisheadset'],position,nil)
    item.Drop(character)
    assert(character.Inventory.TryPutItem(basic,character,{InvSlotType.Headset}))
    character.CharacterHealth.SetAllDamage(0,0,0)
    local before=character.Vitality
    character.AddDamage(position,{AfflictionPrefab.Prefabs['burn'].Instantiate(5)},0,false,Vector2.Zero,nil,1)
    assert(character.Vitality<before)
    basic.Drop(character);assert(character.Inventory.TryPutItem(item,character,{InvSlotType.Headset}))
end)
check('native severed limb restored with joints and mass',function()
    character.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
    local jointIndex,index=nil,0
    for joint in character.AnimController.LimbJoints do
        index=index+1
        if not jointIndex and joint.CanBeSevered and joint.LimbA.type~=LimbType.Head and joint.LimbB.type~=LimbType.Head then jointIndex=index end
    end
    assert(jointIndex,'no severable extremity')
    index=0
    for joint in character.AnimController.LimbJoints do index=index+1;if index==jointIndex then character.AnimController.SeverLimbJoint(joint) end end
    for i=1,10 do G.heal(character,item,1) end
    index=0
    for joint in character.AnimController.LimbJoints do index=index+1;if index==jointIndex then assert(not joint.IsSevered and joint.Enabled) end end
    assert(not character.IsDead)
end)
check('native pressure consumes at configured rate outside hull',function()
    character.CharacterHealth.SetAllDamage(0,0,0);cell.Condition=100
    character.TeleportTo(Vector2(position.X+10000,position.Y))
    assert(character.AnimController.CurrentHull==nil)
    assert(G.pressure(character,1,false))
    assert(math.abs(G.energy(item)-97.5)<.01)
end)
-- A server with no clients disables distant NPCs. Explicitly run the native
-- Update method so this tests pressure simulation, not NPC culling.
check('native update protects exposed wearer before implosion',function()
    cell.Condition=100
    LuaUserData.RegisterType('Barotrauma.GameMain')
    local main=LuaUserData.CreateStatic('Barotrauma.GameMain')
    for i=1,30 do character.Enabled=true;character.Update(.1,main.GameScreen.Cam) end
    assert(not character.IsDead and G.energy(item)<95 and character.PressureTimer<1,
        'dead='..tostring(character.IsDead)..' energy='..G.energy(item)..' pressure='..character.PressureTimer)
end)
item.Drop(character)
check('removing headset leaves no permanent pressure immunity',function()
    assert(not character.IsProtectedFromPressure)
end)
print('[HEADSET TEST] COMPLETE '..#results..' checks')
File.Write('LocalMods/MULTI-TOOL-V2/headset-results.txt',table.concat(results,'\n'))
Timer.Wait(function() if not character.Removed then character.Remove() end end,3000)
