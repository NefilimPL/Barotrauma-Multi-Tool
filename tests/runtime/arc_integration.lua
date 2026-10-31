-- Disposable server only: real characters, ray casts, afflictions and match FF.
local G=BMTCombat
local U=require('CombatTool.util')
local created,results={},{}
local random=math.random
local friendlyFire=Game.ServerSettings.AllowFriendlyFire
local function track(entity) created[#created+1]=entity;return entity end
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BMT ARC] '..results[#results])
end
local origin=Submarine.MainSub.WorldPosition+Vector2(0,5000)
for n=1,20 do
    if not G.cast(U.point(origin),U.point(origin+Vector2(500,0)),0,nil,true) then break end
    origin=origin+Vector2(0,500)
end
local function human(position,team)
    local c=track(Character.Create('human',position,'bmt-arc-'..team,nil,0,false,false,true,nil,true,false))
    c.TeamID=team;c.Enabled=true;c.GodMode=false
    return c
end
local owner=human(origin-Vector2(250,0),CharacterTeamType.Team1)
local enemy=human(origin+Vector2(35,0),CharacterTeamType.Team2)
local ally=human(origin+Vector2(35,600),CharacterTeamType.Team1)
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],origin,nil))
local function discharge(target)
    local point=target.AnimController.MainLimb.WorldPosition-Vector2(35,0)
    local ring={owner=owner,weapon=gun,damageMultiplier=1}
    G.tryArc(ring,{x=point.X,y=point.Y,nx=-1,ny=0,kind='wall'})
    assert(ring.arcDischarged,'eligible real character was not selected')
    return ring
end
math.random=function() return 0 end -- Deterministic successful roll; native damage stays real.
check('impact arc burns and briefly stuns a nearby hostile',function()
    local vitality,stun=enemy.Vitality,enemy.Stun
    discharge(enemy)
    assert(enemy.Vitality<vitality,'secondary burn did not apply')
    assert(enemy.Stun>stun and enemy.Stun<.5,'secondary electrical stun did not apply or was excessive')
end)
check('match friendly fire off protects allied vitality and stun',function()
    Game.ServerSettings.AllowFriendlyFire=false
    local vitality,stun=ally.Vitality,ally.Stun
    discharge(ally)
    assert(ally.Vitality==vitality and ally.Stun==stun,'friendly-fire protection was bypassed')
end)
check('match friendly fire on permits allied electrical shock',function()
    Game.ServerSettings.AllowFriendlyFire=true
    local vitality,stun=ally.Vitality,ally.Stun
    discharge(ally)
    assert(ally.Vitality<vitality and ally.Stun>stun,'ally remained immune despite match settings')
end)
check('same real ring cannot shock twice after ricochets',function()
    local ring=discharge(enemy)
    local vitality=enemy.Vitality
    G.tryArc(ring,{x=origin.X,y=origin.Y,kind='wall'})
    assert(enemy.Vitality==vitality,'same ring applied a second shock')
end)
math.random=random
Game.ServerSettings.AllowFriendlyFire=friendlyFire
for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
File.Write('LocalMods/MULTI-TOOL-V2/arc-results.txt',table.concat(results,'\n'))
