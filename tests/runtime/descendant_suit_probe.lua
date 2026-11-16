-- Run ONLY on the isolated server after gamemode sandbox/start.
assert(Game.RoundStarted,'round must be started')
local G=BMTDescendantSuit
local U=require('CombatTool.util')
assert(G and G.alive and G.authoritative,'suit bootstrap missing')
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    local line=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    results[#results+1]=line;print('[SERVO TEST] '..line)
end
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end end
assert(room,'test room missing')
local position=room.WorldPosition
local wearer=Character.Create('human',position,'servo-native',nil,0,false,true,true,nil,true,false)
wearer.AIController.Enabled=false;wearer.TeamID=CharacterTeamType.Team1;wearer.GodMode=true
local suit=Item(ItemPrefab.Prefabs['descendantservosuit'],position,nil)
local battery=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
local rod=Item(ItemPrefab.Prefabs['fuelrod'],position,nil)
local tank=Item(ItemPrefab.Prefabs['oxygentank'],position,nil)
assert(wearer.Inventory.TryPutItem(suit,wearer,{InvSlotType.OuterClothes}))
assert(G.container(suit,1).TryPutItem(tank,0,false,false,wearer))
assert(G.container(suit,2).TryPutItem(battery,0,false,false,wearer))
local device=Item(ItemPrefab.Prefabs['junctionbox'],position+Vector2(50,0),nil)
check('real wearable, two separate containers and native power',function()
    assert(G.equipped(wearer)==suit and G.source(suit)==battery)
    assert(G.container(suit,1)~=G.container(suit,2) and G.energy(suit)>0)
end)
check('visual plates do not duplicate functional armor modifiers',function()
    local functional=U.component(suit,'Wearable')
    assert(U.component(suit,'Wearable',2),'separate visual component missing')
    local expected=0
    for _ in functional.DamageModifiers do expected=expected+1 end
    local checked=0
    for limb in wearer.AnimController.Limbs do
        if limb.type==LimbType.Torso or limb.type==LimbType.Head then
            local count=0
            for w in limb.WearingItems do
                if w.WearableComponent and w.WearableComponent.Item==suit then
                    for _ in w.WearableComponent.DamageModifiers do count=count+1 end
                end
            end
            assert(count==expected,'armor modifiers repeated on '..tostring(limb.type))
            checked=checked+1
        end
    end
    assert(checked==2)
end)
check('oxygen cannot replace electrical or fission source',function()
    assert(not G.container(suit,2).CanBePut(tank,0,false))
end)
check('repair laser repairs an actual native junction box',function()
    device.Condition=30;battery.Condition=100
    assert(G.perform(wearer,suit,{kind='repair',entity=device},.1))
    assert(device.Condition>30 and battery.Condition<100)
end)
check('a real reactor rod supplies the same repair function',function()
    battery.Drop(wearer)
    assert(G.container(suit,2).TryPutItem(rod,0,false,false,wearer))
    local before=rod.Condition
    assert(G.source(suit)==rod and G.perform(wearer,suit,{kind='repair',entity=device},.1))
    assert(rod.Condition<before)
end)
check('empty rod stops repair without changing the device',function()
    rod.Condition=0;local before=device.Condition
    assert(not G.perform(wearer,suit,{kind='repair',entity=device},.1))
    assert(device.Condition==before);rod.Condition=100
end)
check('native air state and tank debit properties are writable',function()
    local before=tank.Condition
    G.breathe(wearer,suit,.1)
    if require('DescendantSuit.core').breathable(G.air(wearer)) then
        assert(G.state(suit).open and tank.Condition==before and wearer.UseHullOxygen)
    else assert(not G.state(suit).open and tank.Condition<before) end
end)
check('native target enumeration and LOS raycasts run',function()
    local s=G.state(suit);s.mode='repair'
    local list=G.gather(wearer,s)
    assert(type(list)=='table')
end)
check('native wall section welding reduces damage',function()
    local wall
    for w in Structure.WallList do if w.Submarine==Submarine.MainSub and w.HasBody and not w.Indestructible and not w.Prefab.Platform and w.SectionCount>0 then wall=w;break end end
    assert(wall)
    wall.AddDamage(0,30,wearer,false,false)
    local before=wall.SectionDamage(0)
    assert(G.perform(wearer,suit,{kind='weld',entity=wall,section=0},.1))
    assert(wall.SectionDamage(0)<before)
end)
check('native living-target grab applies force through its collider',function()
    local other=Character.Create('human',position+Vector2(100,0),'servo-grab',nil,0,false,true,true,nil,true,false)
    other.AIController.Enabled=false;other.GodMode=true
    assert(G.body(other))
    assert(G.perform(wearer,suit,{kind='grab',entity=other,point={x=position.X+100,y=position.Y}},.1))
end)
check('native continuous combat beam causes damage',function()
    local other=Character.Create('human',position+Vector2(100,0),'servo-enemy',nil,0,false,true,true,nil,true,false)
    other.AIController.Enabled=false;other.TeamID=CharacterTeamType.Team2
    local before=other.Vitality
    assert(G.perform(wearer,suit,{kind='combat',entity=other,point={x=position.X+100,y=position.Y}},.1))
    assert(other.Vitality<before)
end)
_G.ServoNativeProbe={wearer=wearer,suit=suit,rod=rod,tank=tank,device=device,results=results}
File.Write('LocalMods/MULTI-TOOL-V2/Lua/Tests/results.txt',table.concat(results,'\n'))
print('[SERVO TEST] Finished '..#results..' checks; inspect the recorded PASS/FAIL lines.')
