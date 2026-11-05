-- Native projectile regression in an isolated singleplayer sandbox.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local U=require('CombatTool.util')
local G=BMTCombat
local created,lines={},{}
local function track(o) created[#created+1]=o;return o end
local function log(s) lines[#lines+1]=s;print('[FIREARMS] '..s) end
local origin=Submarine.MainSub.WorldPosition+Vector2(0,2500)
local shooter=track(Character.Create('human',origin-Vector2(600,0),'bmt-shooter',nil,0,false,false,true,nil,true,false))
local defender=track(Character.Create('human',origin,'bmt-defender',nil,0,false,false,true,nil,true,false))
shooter.TeamID=CharacterTeamType.Team2;defender.TeamID=CharacterTeamType.Team1
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],origin,nil))
local cell=track(Item(ItemPrefab.Prefabs['batterycell'],origin,nil))
assert(gun.OwnInventory.TryPutItem(cell,0,false,false,defender))
local s=G.state(gun)
local updateShield=G.updateShield
G.updateShield=function(state,ctx,dt)
    if state~=s then return updateShield(state,ctx,dt) end
    local pos=defender.AnimController.MainLimb.WorldPosition
    gun.Move(pos-gun.WorldPosition,true)
    state.owner=defender
    state.shield={x=pos.X,y=pos.Y,radius=80,angle=math.pi,halfAngle=math.pi/3}
end
local oldEvent=G.event
G.event=function(kind,state,pos,...)
    if state==s then log('event '..kind..' at '..pos.x..','..pos.y) end
    return oldEvent(kind,state,pos,...)
end
local cases={{'revolverround'},{'smground'},{'riflebullet'},{'shotgunshell'},
    {'revolverround','turned'},{'revolverround','moved'}}
local function finish()
    G.updateShield=updateShield;G.event=oldEvent;G.states[gun]=nil
    File.Write('LocalMods/MULTI-TOOL-V2/firearms-results.txt',table.concat(lines,'\n'))
    Timer.Wait(function() for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end end,1500)
end
local function run(index)
    if not cases[index] then finish();return end
    local kind,change=cases[index][1],cases[index][2]
    cell.Condition=100;s.brokenUntil=0
    G.updateShield(s,{})
    local pos=defender.AnimController.MainLimb.WorldPosition
    gun.body.Dir=1
    gun.body.SetTransform(ConvertUnits.ToSimUnits(pos),math.pi)
    if change=='turned' then s.shield.angle=0 end
    if change=='moved' then s.shield.x=s.shield.x-400 end
    local start=pos-Vector2(350,0)
    local item=track(Item(ItemPrefab.Prefabs[kind],start,nil))
    local p=assert(U.component(item,'Projectile'))
    p.MaxTargetsToHit=1
    local health=defender.Vitality
    log('start '..kind..' hitscan='..tostring(p.Hitscan)..' change='..tostring(change))
    local sim=ConvertUnits.ToSimUnits(start)
    p.Shoot(shooter,sim,sim,0,nil,false,1,0)
    log((cell.Condition<100 and defender.Vitality>=health-.01 and 'PASS ' or 'FAIL ')..kind..
        ' change='..tostring(change)..' energy='..cell.Condition..' healthDelta='..(defender.Vitality-health))
    run(index+1)
end
run(1)
