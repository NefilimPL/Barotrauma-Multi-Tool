-- Dedicated server + two real clients. Native input, weapons, damage, snapshots.
assert(SERVER and Game.RoundStarted)
local G=BMTCombat
local U=require('CombatTool.util')
LuaUserData.RegisterType('System.Diagnostics.Stopwatch')
local Clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch')
assert(not CombatSession,'Run this probe once in a fresh round')
local R={clients={},npcs={},guns={},cells={},ready={},created={},counts={},victims={},rows={},phase='setup',index=0}
CombatSession=R
R.clock=Clock.StartNew()
local function now() return R.clock.ElapsedMilliseconds/1000 end
for client in Client.ClientList do if client.Name=='CombatA' or client.Name=='CombatB' then R.clients[client.Name]=client end end
assert(R.clients.CombatA and R.clients.CombatB,'both actual clients must be connected')
Networking.Receive('bmt.combat.session.ready',function(_,client) R.ready[client.Name]=true;print('[COMBAT SESSION] ready '..client.Name) end)
local function own(item) R.created[#R.created+1]=item;return item end
local function spawn(kind,inventory,fn)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],inventory,nil,nil,function(item) own(item);if fn then fn(item) end end,false)
end
local base=Submarine.MainSub.WorldPosition+Vector2(0,3500)
for i=1,20 do
    if not G.cast(U.point(base-Vector2(700,0)),U.point(base+Vector2(700,0)),0,nil,true) then break end
    base=base+Vector2(0,500)
end
R.origin=base
local waterBase=base
local room
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub and (not room or hull.Rect.Width>room.Rect.Width) then room=hull end end
local roomBase=room.WorldPosition
local function healthy(c)
    c.Oxygen=100;c.PressureProtection=1000000;c.Stun=0
end
local function equip(c,key)
    for item in c.Inventory.AllItems do if not item.Removed then item.Drop(c,true) end end
    spawn('combatmultitool',c.Inventory,function(gun)
        assert(c.Inventory.TryPutItem(gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
        U.component(gun,'LightComponent').IsOn=true;R.guns[key]=gun
        spawn('batterycell',gun.OwnInventory,function(cell) R.cells[key]=cell end)
    end)
end
for name,client in pairs(R.clients) do
    local c=assert(client.Character,'connected client needs its native round character')
    if c.IsDead then c.Revive(true,true) end
    c.CharacterHealth.SetVitality(100000);c.GodMode=true;c.TeamID=CharacterTeamType.Team1
    c.SetAllDamage(0,0,0);healthy(c);c.TeleportTo(base+Vector2(-350,name=='CombatA' and 0 or 200))
    equip(c,name)
end
for i=1,15 do
    local index=i
    Entity.Spawner.AddCharacterToSpawnQueue('human',base+Vector2(250+(i-1)%5*45,math.floor((i-1)/5)*70),function(c)
        own(c);c.TeamID=CharacterTeamType.Team2;c.CharacterHealth.SetVitality(100000);c.GodMode=true
        c.AIController.Enabled=false;healthy(c);R.npcs[index]=c
        spawn('shotgun',c.Inventory,function(gun)
            assert(c.Inventory.TryPutItem(gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
            R.guns[index]=gun
            for j=1,8 do spawn('shotgunshell',gun.OwnInventory) end
        end)
    end)
end
local oldEvent,oldDamage,oldBlock=G.event,G.damage,G.blockShield
G.event=function(kind,s,...)
    R.counts[kind]=(R.counts[kind] or 0)+1
    return oldEvent(kind,s,...)
end
G.damage=function(target,...)
    R.counts.damageCalls=(R.counts.damageCalls or 0)+1
    R.victims[target.ID]=true
    local before=target.Vitality
    local result=oldDamage(target,...)
    if target.Vitality<before then R.counts.vitalityDrops=(R.counts.vitalityDrops or 0)+1 end
    return result
end
G.blockShield=function(s,...)
    if R.mass and (s.item==R.guns.CombatA or s.item==R.guns.CombatB) then
        local cell=R.cells[s.item==R.guns.CombatA and 'CombatA' or 'CombatB'];cell.Condition=100
    end
    return oldBlock(s,...)
end
local phases={
    {'single_idle',1,'CombatA',false,false},
    {'single_fire_A',1,'CombatA',true,false},
    {'single_fire_B',1,'CombatB',true,false},
    {'cluster_idle',15,'CombatA',false,false},
    {'cluster_fire_A',15,'CombatA',true,false},
    {'cluster_fire_B',15,'CombatB',true,false},
    {'shield_idle_A',15,'CombatA',false,false,true},
    {'shield_mass_A',15,'CombatA',false,true,true},
    {'shield_idle_B',15,'CombatB',false,false,true},
    {'shield_mass_B',15,'CombatB',false,true,true},
}
local function message(client,target,aim,shoot)
    local m=Networking.Start('bmt.combat.session.phase')
    m.WriteString(R.phase);m.WriteUInt16(target and target.ID or 0);m.WriteBoolean(aim);m.WriteBoolean(shoot)
    m.WriteSingle(base.X);m.WriteSingle(base.Y+50);Networking.Send(m,client.Connection)
end
local function report()
    if R.phase=='setup' then return end
    local victims=0;for _ in pairs(R.victims) do victims=victims+1 end
    local values={'phase='..R.phase,'seconds='..string.format('%.2f',now()-R.started),'victims='..victims}
    for key,value in pairs(R.counts) do values[#values+1]=key..'='..value end
    R.rows[#R.rows+1]=table.concat(values,' ')
    File.Write('LocalMods/MULTI-TOOL-V2/combat-session-server.txt',table.concat(R.rows,'\n'))
    print('[COMBAT SESSION] '..R.rows[#R.rows])
end
local function beginPhase()
    report();R.index=R.index+1;local p=phases[R.index]
    if not p then
        R.phase='done';R.mass=false
        for _,client in pairs(R.clients) do message(client,nil,false,false) end
        print('[COMBAT SESSION] ALL PHASES DONE');return
    end
    R.phase=p[1];R.activeCount=p[2];R.actor=p[3];R.firing=p[4];R.mass=p[5];R.shield=p[6]
    R.counts={};R.victims={};R.started=now();R.nextTarget=now()+1;R.targetIndex=1
    R.lastSupply=now();R.lastShot=now();R.lastMaintenance=0
    local a=R.clients[R.actor].Character
    local other=R.clients[R.actor=='CombatA' and 'CombatB' or 'CombatA']
    base=R.shield and waterBase or roomBase
    a.TeleportTo(base+Vector2(-350,0));other.Character.TeleportTo(base+Vector2(R.mass and 0 or -350,R.shield and 200 or 50))
    for i,c in ipairs(R.npcs) do
        local angle=(i-8)*math.pi/84
        local offset=R.shield and Vector2(-350+600*math.cos(angle),600*math.sin(angle))
            or Vector2(i<=R.activeCount and 250+(i-1)%5*45 or 10000+i*100,(math.floor((i-1)/5)-1)*40)
        c.TeleportTo(base+offset)
        healthy(c);c.SetAllDamage(0,0,0)
    end
    for _,cell in pairs(R.cells) do cell.Condition=100 end
    message(R.clients[R.actor],R.npcs[1],R.firing or R.shield or false,R.firing)
    message(other,a,R.mass,R.mass)
    print('[COMBAT SESSION] PHASE '..R.phase)
end
function R.start()
    assert(R.ready.CombatA and R.ready.CombatB,'both clients must have acknowledged the probe')
    assert(#R.npcs==15 and R.cells.CombatA and R.cells.CombatB and R.guns[15],'native fixture not complete')
    for _,client in pairs(R.clients) do client.Character.GodMode=false end
    for _,c in ipairs(R.npcs) do c.GodMode=false end
    R.running=true;beginPhase()
end
Hook.Patch('bmt.session.health','Barotrauma.Character','UpdateNetInput',function(c)
    if c==R.clients.CombatA.Character or c==R.clients.CombatB.Character then healthy(c);return end
    for _,npc in ipairs(R.npcs) do if c==npc then healthy(c);return end end
end,Hook.HookMethodType.After)
Hook.Add('think','bmt.session.server',function()
    if not R.running then
        if R.ready.CombatA and R.ready.CombatB and #R.npcs==15 and R.cells.CombatA and R.cells.CombatB and R.guns[15] and now()>8 then R.start() end
        return
    end
    if R.phase=='done' then return end
    local t=now()
    if t-R.started>=18 then beginPhase();return end
    if t-R.lastMaintenance>.1 then
        R.lastMaintenance=t
        for _,client in pairs(R.clients) do healthy(client.Character) end
        for _,c in ipairs(R.npcs) do healthy(c) end
        for _,cell in pairs(R.cells) do cell.Condition=100 end
    end
    if R.firing and t>=R.nextTarget then
        R.targetIndex=R.targetIndex%R.activeCount+1;R.nextTarget=t+1
        message(R.clients[R.actor],R.npcs[R.targetIndex],true,true)
    end
    if R.mass and t-R.lastShot>.1 then
        R.lastShot=t
        local defender=R.clients[R.actor].Character
        local target=defender.AnimController.MainLimb.WorldPosition
        for i=1,15 do
            local c,gun=R.npcs[i],R.guns[i]
            c.CursorPosition=c.Position+target-c.WorldPosition;c.SetInput(InputType.Aim,false,true)
            local ranged=U.component(gun,'RangedWeapon')
            if ranged.Use(.1,c) then R.counts.nativeShots=(R.counts.nativeShots or 0)+1 end
        end
    end
    if R.mass and t-R.lastSupply>.5 then
        R.lastSupply=t
        for i=1,15 do local gun=R.guns[i];if not gun.OwnInventory.IsFull(false) then spawn('shotgunshell',gun.OwnInventory) end end
    end
end)
print('[COMBAT SESSION] Fixture spawning for two native clients; load client probes, then CombatSession.start()')
