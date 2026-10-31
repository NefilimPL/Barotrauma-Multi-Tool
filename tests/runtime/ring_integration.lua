-- Test-only: actual energy-ring flight, native NPC damage and match friendly fire.
local G=BMTCombat
local U=require('CombatTool.util')
local results,created={},{}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BMT RING] '..results[#results])
end
local function track(value) created[#created+1]=value;return value end
local origin=Submarine.MainSub.WorldPosition+Vector2(0,5000)
for n=1,20 do
    local a=U.point(origin);local b={x=a.x+500,y=a.y}
    if not G.cast(a,b,0,nil,true) then break end
    origin=origin+Vector2(0,500)
end
local function human(position,team)
    local c=track(Character.Create('human',position,'bmt-ring-'..team,nil,0,false,false,true,nil,true,false))
    c.TeamID=team;c.Enabled=true;c.GodMode=false
    return c
end
local owner=human(origin-Vector2(250,0),CharacterTeamType.Team1)
local target=human(origin+Vector2(180,0),CharacterTeamType.Team2)
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],origin,nil))
U.component(gun,'LightComponent').IsOn=true
local state=G.state(gun);state.owner=owner
local originalFriendlyFire=Game.ServerSettings.AllowFriendlyFire
local function fireAt(c)
    -- Align the real weapon muzzle to the target's native limb, then use
    -- production fire/update methods, physics ray casts and Character.AddDamage.
    local muzzleOffset=ConvertUnits.ToDisplayUnits(U.component(gun,'RangedWeapon').TransformedBarrelPos)
    gun.body.SetTransform(ConvertUnits.ToSimUnits(c.AnimController.MainLimb.WorldPosition-Vector2(150,0)-muzzleOffset),0)
    G.rings={}
    G.fire(state,{owner=owner})
    assert(#G.rings==1,'fire did not create a ring')
    G.updateRings(.2)
    assert(#G.rings==0,'ring failed to collide with NPC')
end
check('native ring damages hostile NPC',function()
    local before=target.Vitality
    fireAt(target)
    assert(target.Vitality<before,'hostile NPC did not lose vitality')
end)
local pushed=human(origin+Vector2(180,600),CharacterTeamType.Team2)
check('native ring gives NPC a bounded forward impulse',function()
    local before=pushed.AnimController.MainLimb.body.LinearVelocity.X
    fireAt(pushed)
    local after=pushed.AnimController.MainLimb.body.LinearVelocity.X
    assert(after>before+.01,'hit did not impart forward velocity')
    assert(after<50,'hit imparted excessive velocity')
end)
local ally=human(origin+Vector2(180,300),CharacterTeamType.Team1)
check('native ring damages crew when match friendly fire is enabled',function()
    Game.ServerSettings.AllowFriendlyFire=true
    local before=ally.Vitality
    fireAt(ally)
    assert(ally.Vitality<before,'crew remained immune despite enabled friendly fire')
end)
check('native match friendly-fire disable protects crew',function()
    Game.ServerSettings.AllowFriendlyFire=false
    local before=ally.Vitality
    local velocity=ally.AnimController.MainLimb.body.LinearVelocity.X
    fireAt(ally)
    assert(ally.Vitality==before,'crew took damage with friendly fire disabled')
    assert(ally.AnimController.MainLimb.body.LinearVelocity.X==velocity,'friendly fire off still pushed crew')
end)
check('technical emitter and energy muzzle share display position',function()
    local muzzle=G.muzzle(gun)
    local toolOffset=U.component(gun,'RepairTool').TransformedBarrelPos
    assert(math.abs(muzzle.x-gun.WorldPosition.X-toolOffset.X)<.05)
    assert(math.abs(muzzle.y-gun.WorldPosition.Y-toolOffset.Y)<.05)
end)
Game.ServerSettings.AllowFriendlyFire=originalFriendlyFire
G.rings={}
for i=#created,1,-1 do
    local entity=created[i]
    if not entity.Removed and not Entity.Spawner.IsInRemoveQueue(entity) then entity.Remove() end
end
File.Write('LocalMods/MULTI-TOOL-V2/ring-results.txt',table.concat(results,'\n'))
