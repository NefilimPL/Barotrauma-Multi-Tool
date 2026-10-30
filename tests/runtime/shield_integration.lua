-- Native fixture/damage checks on the isolated server, during a sandbox round.
local G=BMTCombat
local U=require('CombatTool.util')
local results,created={},{}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BMT SHIELD] '..results[#results])
end
local function track(o) created[#created+1]=o;return o end
local room
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then room=hull;break end end
check('actual submarine wall is hit by a world-space ray',function()
    local a=U.point(room.WorldPosition)
    local hit=G.cast(a,{x=a.x+5000,y=a.y},0,nil,true)
    assert(hit and hit.kind=='wall','world-to-submarine wall ray missed')
end)
local origin=room.WorldPosition+Vector2(0,2000)
for i=1,10 do
    if not G.cast(U.point(origin),U.point(origin+Vector2(500,0)),0,nil,true) then break end
    origin=origin+Vector2(0,500)
end
local function human(offset,team)
    local c=track(Character.Create('human',origin+Vector2(offset,0),'bmt-shield-'..offset,nil,0,false,false,true,nil,true,false))
    c.TeamID=team
    c.Enabled=true
    c.GodMode=false
    return c
end
local attacker=human(-200,CharacterTeamType.Team2)
local protected=human(300,CharacterTeamType.Team1)
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],protected.WorldPosition,nil))
local battery=track(Item(ItemPrefab.Prefabs['batterycell'],protected.WorldPosition,nil))
assert(gun.OwnInventory.TryPutItem(battery,1,false,false,protected))
local state=G.state(gun);state.owner=protected
local function shield()
    battery.Condition=100
    state.shield={x=protected.WorldPosition.X,y=protected.WorldPosition.Y,
        radius=95,angle=math.pi,halfAngle=math.pi/3}
end
local function projectile(hitscan)
    local item=track(Item(ItemPrefab.Prefabs['revolverround'],origin,nil))
    local p=U.component(item,'Projectile')
    p.Hitscan=hitscan;p.MaxTargetsToHit=1
    return p
end
local function shoot(p)
    local pos=Vector2(origin.X,protected.AnimController.MainLimb.WorldPosition.Y)
    local sim=ConvertUnits.ToSimUnits(pos)
    p.Shoot(attacker,sim,sim,0,nil,false,1,0)
end
check('native hitscan is intercepted before protected character damage',function()
    shield()
    local health=protected.Vitality
    shoot(projectile(true))
    assert(battery.Condition<100,'shield did not consume energy for native hitscan')
    assert(protected.Vitality==health,'protected character took hitscan damage')
end)
local nearer=human(100,CharacterTeamType.Team1)
check('nearer unshielded character still takes native hitscan damage',function()
    shield()
    local health=nearer.Vitality
    shoot(projectile(true))
    assert(nearer.Vitality<health,'native earlier target was canceled by a farther shield')
    assert(battery.Condition==100,'farther shield consumed energy for a stopped shot')
end)
nearer.Remove()
check('fast physical projectile is intercepted across its traveled segment',function()
    shield()
    local p=projectile(false)
    shoot(p)
    p.Item.Move(Vector2(250,0),true)
    p.Update(.016,nil)
    assert(not p.IsActive and battery.Condition<100,'physical segment was not intercepted')
end)
check('contact shock uses native character damage and higher energy cost',function()
    battery.Condition=100
    gun.Move(protected.WorldPosition-gun.WorldPosition,true)
    attacker.TeleportTo(gun.WorldPosition+Vector2(70,0))
    state.brokenUntil=0;state.contactTimes={}
    G.updateShield(state,{valid=true,aim=true,damage=true,owner=protected},.016)
    assert(battery.Condition<95,'contact did not use the six-point shock debit')
end)
for i=#created,1,-1 do
    local entity=created[i]
    if not entity.Removed and not Entity.Spawner.IsInRemoveQueue(entity) then entity.Remove() end
end
G.states[gun]=nil
File.Write('LocalMods/MULTI-TOOL-V2/shield-results.txt',table.concat(results,'\n'))
