-- Disposable, real server + two GPU clients. Never package with the mod.
assert(SERVER and Game.RoundStarted)
assert(not DescendantPerf,'Use a fresh round')
local G=assert(BMTDescendantSuit)
local U=require('CombatTool.util')
LuaUserData.RegisterType('System.Diagnostics.Stopwatch')
local Clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch')
local clock=Clock.StartNew()
local function now() return clock.ElapsedMilliseconds/1000 end
local function ticks() return Clock.GetTimestamp() end
local function ms(delta) return delta*1000/Clock.Frequency end
local R={actors={},ready={},rows={},phase='setup',index=0,clients={},created={},duration=30}
DescendantPerf=R
local P='bmt.descendant.performance'
local function write(line)
    R.rows[#R.rows+1]=line;print('[DESCENDANT PERF] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/descendant-perf-server.txt',table.concat(R.rows,'\n'))
end
for client in Client.ClientList do
    if client.Name=='PerfA' or client.Name=='PerfB' then R.clients[client.Name]=client end
end
assert(R.clients.PerfA and R.clients.PerfB,'Both actual clients must be joined')
local base=Submarine.MainSub.WorldPosition+Vector2(0,3000)
for i=1,20 do
    if not G.cast(U.point(base-Vector2(700,350)),U.point(base+Vector2(700,350)),0,nil,true) then break end
    base=base+Vector2(0,500)
end
R.base=base
local function own(entity) R.created[#R.created+1]=entity;return entity end
local function spawn(id,inventory,callback)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],inventory,nil,nil,function(item)
        own(item);callback(item)
    end,false)
end
local function healthy(c)
    c.GodMode=true;c.Oxygen=100;c.Stun=0;c.PressureProtection=1000000
end
local function setup(c,i)
    local a={c=c,i=i,home=base+Vector2(((i-1)%4-1.5)*260,(i<=4 and -1 or 1)*230)}
    R.actors[i]=a
    if c.IsDead then c.Revive(true,true) end
    healthy(c);c.TeamID=CharacterTeamType.Team1;c.SetAllDamage(0,0,0);c.TeleportTo(a.home)
    if c.AIController then c.AIController.Enabled=false end
    local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
    for _,item in ipairs(old) do item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end
    spawn('descendantservosuit',c.Inventory,function(suit)
        a.suit=suit;assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
        spawn('batterycell',G.container(suit,1),function(cell) a.cell=cell end)
        spawn('pulselaserammobox',c.Inventory,function(box)
            assert(G.container(suit,1).TryPutItem(box,1,false,false,c));a.box=box
        end)
    end)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['junctionbox'],a.home+Vector2(0,85),nil,nil,nil,function(device)
        a.device=own(device);device.Condition=device.MaxCondition
        device.GetComponentString('Repairable').DeteriorationSpeed=0
    end)
    Entity.Spawner.AddCharacterToSpawnQueue('crawler',a.home+Vector2(100,95),function(enemy)
        a.enemy=own(enemy);healthy(enemy);enemy.TeamID=CharacterTeamType.Team1;enemy.AIController.Enabled=false
    end)
    if i<=2 then Entity.Spawner.AddCharacterToSpawnQueue('human',a.home+Vector2(-100,20),function(h)
        a.grab=own(h);healthy(h);h.TeamID=c.TeamID;h.AIController.Enabled=false
    end) end
end
for other in Character.CharacterList do
    if other~=R.clients.PerfA.Character and other~=R.clients.PerfB.Character then Entity.Spawner.AddEntityToRemoveQueue(other) end
end
setup(assert(R.clients.PerfA.Character),1);setup(assert(R.clients.PerfB.Character),2)
for i=3,8 do local n=i
    Entity.Spawner.AddCharacterToSpawnQueue('human',base,function(c) own(c);setup(c,n) end)
end
local phases={
    {'idle_observer','off',0},{'repair_1','repair',1},{'combat_1','combat',1},{'grip_1','grab',1},
    {'idle_1','off',0},{'repair_2a','repair',2},{'idle_2','off',0},
    {'combat_2a','combat',2},{'idle_3','off',0},{'grip_2a','grab',2},
    {'idle_4','off',0},{'sonar_2','off',0,true},{'idle_5','off',0},
    {'repair_2b','repair',2},{'idle_6','off',0},{'combat_2b','combat',2},
    {'idle_7','off',0},{'repair_8','repair',8},{'idle_8','off',0},
    {'combat_8','combat',8},{'combat_8_sonar','combat',8,true},{'idle_final','off',0},
}
local function message(client)
    local m=Networking.Start(P..'.phase')
    local a=R.actors[client==R.clients.PerfA and 1 or 2]
    m.WriteString(R.phase);m.WriteString(a.i<=(R.count or 0) and R.mode or 'off');m.WriteBoolean(R.sonar==true)
    m.WriteSingle(base.X);m.WriteSingle(base.Y)
    m.WriteUInt16(a.suit.ID);m.WriteUInt16(a.grab.ID)
    Networking.Send(m,client.Connection)
end
local function stat(values,p)
    if #values==0 then return 0 end
    return values[math.max(1,math.ceil(#values*p))]
end
local function finish()
    if not R.started then return end
    local times=R.times;table.sort(times)
    local elapsed=now()-R.started-5
    local shots,damage=0,0
    for _,a in ipairs(R.actors) do shots=shots+((G.state(a.suit).shots or 0)-a.startShots);damage=damage+(a.repaired or 0) end
    write(string.format('phase=%s seconds=%.3f updates=%d ups=%.2f controller_mean_ms=%.4f controller_p95_ms=%.4f controller_p99_ms=%.4f controller_max_ms=%.4f active_mean=%.3f grip_mean=%.3f shots=%d repaired=%.3f',
        R.phase,elapsed,#times,#times/math.max(.001,elapsed),R.total/math.max(1,#times),stat(times,.95),stat(times,.99),stat(times,1),R.active/math.max(1,#times),R.grips/math.max(1,#times),shots,damage))
end
local function begin()
    finish();R.index=R.index+1
    local entry=phases[R.index]
    if not entry then
        R.phase='done';R.mode='off';R.sonar=false
        for _,a in ipairs(R.actors) do G.setMode(a.suit,'off',a.c);G.stopSonar(a.suit,G.state(a.suit)) end
        for _,client in pairs(R.clients) do message(client) end
        write('RESULT phases='..#phases..' clients=2 production=1.3.17');return
    end
    R.phase,R.mode,R.count,R.sonar=entry[1],entry[2],entry[3],entry[4]
    R.powerCount=R.index>=17 and 8 or 2
    R.started=now();R.times={};R.total=0;R.active=0;R.grips=0;R.maintenance=0
    for _,a in ipairs(R.actors) do
        G.setMode(a.suit,'off',a.c)
        a.c.TeleportTo(a.home);healthy(a.c)
        a.enemy.TeleportTo(R.mode=='combat' and a.i<=R.count and a.home+Vector2(100,95) or base+Vector2(10000+a.i*200,0));healthy(a.enemy)
        a.enemy.TeamID=R.mode=='combat' and a.i<=R.count and CharacterTeamType.Team2 or CharacterTeamType.Team1
        if a.grab then a.grab.TeleportTo(R.mode=='grab' and a.i<=R.count and a.home+Vector2(-100,20) or base+Vector2(14000+a.i*200,0));healthy(a.grab) end
        a.device.Condition=R.mode=='repair' and a.i<=R.count and 10 or a.device.MaxCondition
        a.repaired=0;a.startShots=G.state(a.suit).shots or 0
        a.cell.Condition=a.i<=R.powerCount and a.cell.MaxCondition or 0
        -- Fixed NPCs have native navigation disabled (IsBot then becomes false).
        -- Select their function through the same production mode handler.
        if a.i>2 then G.setMode(a.suit,a.i<=R.count and R.mode or 'off',a.c) end
    end
    for _,client in pairs(R.clients) do message(client) end
    if R.mode=='grab' then
        for i=1,math.min(2,R.count) do local a=R.actors[i]
            -- A freshly network-spawned target avoids interpolation history
            -- from the far-away parking position in this synthetic scene.
            Entity.Spawner.AddEntityToRemoveQueue(a.grab)
            Entity.Spawner.AddCharacterToSpawnQueue('human',a.home+Vector2(-100,20),function(h)
                a.grab=own(h);healthy(h);h.TeamID=a.c.TeamID;h.AIController.Enabled=false
                message(R.clients[i==1 and 'PerfA' or 'PerfB'])
            end)
        end
    end
    write('BEGIN '..R.phase)
end
Networking.Receive(P..'.ready',function(_,client) R.ready[client.Name]=true end)
local original=G.update
G.update=function(dt)
    local sampled=R.started and R.phase~='done' and now()-R.started>=5
    local before=ticks();original(dt);local elapsed=ms(ticks()-before)
    if sampled then
        R.times[#R.times+1]=elapsed;R.total=R.total+elapsed
        for _,a in ipairs(R.actors) do
            local s=G.state(a.suit)
            if s.active then R.active=R.active+1 end
            if s.grip then R.grips=R.grips+1 end
        end
    end
end
local repair=G.repairDevice
G.repairDevice=function(owner,item,t,dt)
    local before=t.entity.Condition;local ok=repair(owner,item,t,dt)
    for _,a in ipairs(R.actors) do if a.suit==item then a.repaired=(a.repaired or 0)+math.max(0,t.entity.Condition-before);break end end
    return ok
end
Hook.Add('think',P,function()
    if R.phase=='done' then return end
    if not R.started then
        if not R.ready.PerfA or not R.ready.PerfB then return end
        for i=1,8 do local a=R.actors[i]
            if not a or not a.suit or not a.cell or not a.box or not a.device or not a.enemy or (i<=2 and not a.grab) then return end
        end
        begin();return
    end
    if now()-R.started>=R.duration then begin();return end
    if now()-R.maintenance<.1 then return end;R.maintenance=now()
    for _,a in ipairs(R.actors) do
        healthy(a.c);healthy(a.enemy);if a.grab then healthy(a.grab) end
        a.cell.Condition=a.i<=R.powerCount and a.cell.MaxCondition or 0;a.box.Condition=a.box.MaxCondition
        if R.mode=='repair' and a.i<=R.count and a.device.Condition>65 then a.device.Condition=10 end
        -- Keep fixtures in view without running an extra native AI/navigation
        -- workload. Native body, repair, hit and grip simulation still runs.
        if (a.c.WorldPosition-a.home).Length()>25 then a.c.TeleportTo(a.home) end
        local enemyHome=R.mode=='combat' and a.i<=R.count and a.home+Vector2(100,95) or base+Vector2(10000+a.i*200,0)
        if (a.enemy.WorldPosition-enemyHome).Length()>25 then a.enemy.TeleportTo(enemyHome) end
    end
end)
write('WAITING clients=2 actors=8 protocol='..require('DescendantSuit.config').protocol)
