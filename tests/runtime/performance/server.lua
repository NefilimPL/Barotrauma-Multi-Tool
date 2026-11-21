-- TEST ONLY. A disposable real server round, never a campaign save.
assert(SERVER and Game.RoundStarted)
assert(not AegisPerformance,'Use a fresh process for a new performance run')
local U=AegisCombat and require('AegisCombat.util') or {}
local D=AegisSuit
local V=AegisVacuum
local C=AegisCombat
local H=AegisHeadsets
local P='aegis.performance.v1'
local signalRoot='LocalMods/System-Aegis/'
local function write(path,text) File.Write(signalRoot..path,text) end
LuaUserData.RegisterType('System.Diagnostics.Stopwatch')
local Clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch')
local clock=Clock.StartNew()
local function now() return clock.ElapsedMilliseconds/1000 end
local function signal(id) write('aegis-perf-phase.txt',id..'|'..string.format('%.0f',Clock.GetTimestamp())) end
local R={actors={},clients={},ready={},created={},phase=nil,index=0,activity={},enabled=true}
local Proof=dofile('LocalMods/System-Aegis/Lua/Tests/performance/proof.lua')
local managed=Proof.tracker(function(entity) Entity.Spawner.AddEntityToRemoveQueue(entity) end)
R.created=managed.items
R.serverOnly=File.Exists(signalRoot..'aegis-perf-server-only.txt')
AegisPerformance=R
local function encode(v)
    if type(v)=='string' then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"' end
    if type(v)=='number' or type(v)=='boolean' then return tostring(v) end
    if type(v)~='table' then return 'null' end
    local out={}
    if #v>0 then for _,x in ipairs(v) do out[#out+1]=encode(x) end;return '['..table.concat(out,',')..']' end
    for k,x in pairs(v) do out[#out+1]=encode(k)..':'..encode(x) end
    return '{'..table.concat(out,',')..'}'
end
local function append(path,row)
    local old=File.Exists(signalRoot..path) and File.Read(signalRoot..path) or ''
    write(path,old..encode(row)..'\n')
end
local base=Submarine.MainSub.WorldPosition+Vector2(0,3500)
R.base=base
for client in Client.ClientList do
    if client.Name=='PerfA' or client.Name=='PerfB' then R.clients[client.Name]=client end
end
if R.serverOnly then R.clients={PerfA={Name='PerfA'},PerfB={Name='PerfB'}};R.ready={PerfA=true,PerfB=true} end
assert(R.clients.PerfA and R.clients.PerfB,'Two real clients must be joined')
for c in Character.CharacterList do
    if c~=R.clients.PerfA.Character and c~=R.clients.PerfB.Character then Entity.Spawner.AddEntityToRemoveQueue(c) end
end
LuaUserData.MakePropertyAccessible(LuaUserData.RegisterType('Barotrauma.Networking.GameServer'),'EndRoundTimer')
local function healthy(c,medical,pressure)
    c.GodMode=not medical;c.Oxygen=100;c.Stun=0
    c.DisableImpactDamageTimer=1
    if not pressure then c.PressureProtection=1000000 end
end
local own=managed.add
local function item(id,inventory,callback)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],inventory,nil,nil,function(value)
        own(value);callback(value)
    end,false)
end
local function worldItem(id,p,callback)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],p,nil,nil,nil,function(value)
        own(value);callback(value)
    end)
end
local function configure(c,i)
    local a={c=c,home=base+Vector2(((i-1)%4-1.5)*280,(i<=4 and -1 or 1)*230),index=i}
    a.initialHome=a.home
    R.actors[i]=a;c.TeamID=CharacterTeamType.Team1;healthy(c);c.TeleportTo(a.home)
    if c.Info and c.Info.Job then
        for _,skill in ipairs({'helm','weapons','mechanical','electrical','medical'}) do c.Info.SetSkillLevel(skill,50,true) end
    end
    if c.AIController then c.AIController.Enabled=false end
    local old={};for x in c.Inventory.AllItems do old[#old+1]=x end
    for _,x in ipairs(old) do Entity.Spawner.AddEntityToRemoveQueue(x) end
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['junctionbox'],a.home+Vector2(0,85),nil,nil,nil,function(device)
        a.device=device;device.Condition=device.MaxCondition;device.GetComponentString('Repairable').DeteriorationSpeed=0
    end)
    Entity.Spawner.AddCharacterToSpawnQueue('crawler',a.home+Vector2(150,100),function(enemy)
        a.enemy=enemy;healthy(enemy);enemy.TeamID=CharacterTeamType.Team1;enemy.AIController.Enabled=false
    end)
end
local index=0
for _,name in ipairs({'PerfA','PerfB'}) do
    index=index+1;local n=index;local client=R.clients[name]
    if client.Character then configure(client.Character,n)
    else Entity.Spawner.AddCharacterToSpawnQueue('human',base,function(c)
        if not R.serverOnly then Game.Server.SetClientCharacter(client,c) end
        configure(c,n)
    end) end
end
for i=3,8 do local n=i;Entity.Spawner.AddCharacterToSpawnQueue('human',base,function(c) configure(c,n) end) end
Networking.Receive(P..'.ready',function(_,client) R.ready[client.Name]=true end)
Networking.Receive(P..'.prepared',function(m,client)
    local token=m.ReadString()
    if R.phase and token==R.phase.id then R.replicaReady[client.Name]=token end
end)
Networking.Receive(P..'.stopped',function(m,client)
    local id=m.ReadString()
    if R.stopping and id==R.stopping.id then R.stoppedClients[client.Name]=true end
end)
local function prepareMessage(client)
    if R.serverOnly then R.replicaReady[client.Name]=R.phase.id;return end
    local m=Networking.Start(P..'.prepare');m.WriteString(R.phase.id);m.WriteBoolean(R.phase.mode=='panel');m.WriteByte(R.phase.count)
    for i=1,R.phase.count do local a=R.actors[i]
        m.WriteUInt16(a.item.ID);m.WriteUInt16(a.pack and a.pack.ID or 0)
        m.WriteUInt16(a.expected or 0);m.WriteUInt16(a.cell and a.cell.ID or 0)
    end
    Networking.Send(m,client.Connection)
end
local function message(client,waiting)
    if R.serverOnly then return end
    local a=R.actors[client==R.clients.PerfA and 1 or 2]
    local p=not waiting and R.phase or nil
    local m=Networking.Start(P..'.phase');m.WriteString(p and p.id or 'done');m.WriteString(p and p.mode or 'idle')
    m.WriteUInt16(a.item and not a.item.Removed and a.item.ID or 0)
    m.WriteUInt16(a.pack and not a.pack.Removed and a.pack.ID or 0)
    local camera=p and (p.mode=='weld' or p.mode=='cut') and Submarine.MainSub.WorldPosition or base
    m.WriteSingle(camera.X);m.WriteSingle(camera.Y);m.WriteBoolean(p and a.index<=p.count or false)
    m.WriteBoolean(p and p.hidden==true or false)
    m.WriteSingle(p and p.item=='aegisvacuum' and .4 or .75)
    local aim=a.aim or a.home+Vector2(500,0)
    if p and p.mode=='grab' then aim=a.enemy.WorldPosition end
    m.WriteSingle(aim.X);m.WriteSingle(aim.Y);Networking.Send(m,client.Connection)
end
local function catalogue(repeats,filter)
    local phases={}
    local function add(kind,mode,count,extra)
        local key=kind..'_'..mode..'_'..count..(extra and '_hidden' or '')
        if filter~='' then
            local matched=false
            for part in filter:gmatch('[^,]+') do if key:sub(1,#part)==part then matched=true end end
            if not matched then return end
        end
        for r=1,repeats do phases[#phases+1]={id=key..'_r'..r,item=kind,mode=mode,count=count,
            active=mode~='idle' and mode~='stored' and mode~='none',hidden=extra==true} end
    end
    add('none','none',0)
    add('screwdriver','repair',8)
    add('smg','fire',8)
    add('weldingtool','weld',8)
    local modes={aegiswrenchscrewdriver={'idle','repair'},['aegiscompositetool']={'idle','repair','light','weld','cut','extinguish','passive'},
        aegiscombattool={'idle','repair','light','shield','fire','weld','cut','extinguish','passive'},aegisheadset={'idle','heal','pressure'},
        aegisheadsetmk2={'idle','heal','pressure','hit'},aegisvacuum={'idle','vacuum'},
        aegisvacuumpack={'idle','panel','storage1000','storage10000','salvage'},
        aegisservosuit={'idle','repair','combat','grab','sonar'}}
    if D then for _,kind in ipairs({'aegiswrenchscrewdriver','aegiscompositetool','aegiscombattool','aegisheadset','aegisheadsetmk2','aegisvacuum','aegisvacuumpack','aegisservosuit'}) do
        local first=#phases+1
        for _,mode in ipairs(modes[kind]) do
            for _,count in ipairs({1,2,8}) do
                if (mode~='storage10000' or count==1) and (mode~='panel' or count<=2) then add(kind,mode,count) end
            end
        end
        if #phases>=first then
            table.insert(phases,first,{id='none_before_'..kind..'_r1',item='none',mode='none',count=0,active=false})
        end
    end
    add('aegisservosuit','repair',8,true)
    add('mixed','stress',8)
    end
    return phases
end
local mixed={
    {'aegisservosuit','repair'},{'aegisservosuit','combat'},
    {'aegiscombattool','shield'},{'aegiscombattool','fire'},
    {'aegisheadset','heal'},{'aegisheadsetmk2','hit'},
    {'aegisvacuum','vacuum'},{'aegisvacuumpack','storage1000'}}
local function actorPhase(a,p)
    if p.item~='mixed' then return p end
    local entry=mixed[a.index]
    return {item=entry[1],mode=entry[2],count=8,active=true}
end
local function clean()
    managed.clear()
    for _,a in ipairs(R.actors) do
        a.item=nil;a.cell=nil;a.ammo=nil;a.pack=nil;a.pending=0;a.work=0;a.healed=0;a.shots=0
        a.vacuum=nil;a.wall=nil;a.section=nil;a.lootAt=nil;a.home=a.initialHome;a.aim=nil
        a.wallReference=nil
        a.expected=nil;a.oxygen=nil
        a.skillBaseline=nil
        a.c.SelectedItem=nil
        Proof.resetHealth(a.c);Proof.resetHealth(a.enemy)
        a.c.GodMode=true;a.enemy.GodMode=true
        if a.c.Info and a.c.Info.Job then
            for _,skill in ipairs({'helm','weapons','mechanical','electrical','medical'}) do a.c.Info.SetSkillLevel(skill,50,true) end
        end
        a.device.Condition=a.device.MaxCondition;a.enemy.TeamID=CharacterTeamType.Team1
    end
end
local function equipment(a,p)
    a.testMode=p.mode;a.testKind=p.item
    a.pending=a.pending+1
    item(p.item,a.c.Inventory,function(value)
        a.item=value
        if p.item=='aegisheadset' or p.item=='aegisheadsetmk2' then
            assert(a.c.Inventory.TryPutItem(value,a.c,{InvSlotType.Headset}))
        elseif p.item=='aegisservosuit' then
            assert(a.c.Inventory.TryPutItem(value,a.c,{InvSlotType.OuterClothes}))
        elseif p.item=='aegisvacuumpack' then
            assert(a.c.Inventory.TryPutItem(value,a.c,{InvSlotType.Bag}));a.pack=value
        elseif p.item=='aegiscombattool' or p.item=='aegisvacuum' or p.item=='smg' then
            assert(a.c.Inventory.TryPutItem(value,a.c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
        else
            assert(a.c.Inventory.TryPutItem(value,a.c,{InvSlotType.RightHand}))
        end
        local inventory=value.OwnInventory
        if p.item=='aegisservosuit' then inventory=D.container(value,1) end
        if inventory and p.item~='aegisvacuumpack' then
            a.pending=a.pending+1
            local kind=p.item=='aegiscompositetool' and 'fuelrod' or p.item=='weldingtool' and 'weldingfueltank' or
                p.item=='smg' and 'smgmagazine' or 'batterycell'
            item(kind,inventory,function(cell)
                if p.item=='smg' then a.ammo=cell else a.cell=cell end
                a.pending=a.pending-1
            end)
        end
        if p.item=='aegisservosuit' then
            a.pending=a.pending+1
            item('pulselaserammobox',a.c.Inventory,function(box)
                assert(D.container(value,1).TryPutItem(box,1,false,false,a.c));a.ammo=box;a.pending=a.pending-1
            end)
        elseif p.item=='aegisvacuum' then
            a.pending=a.pending+1
            item('aegisvacuumpack',a.c.Inventory,function(pack)
                a.pack=pack;assert(a.c.Inventory.TryPutItem(pack,a.c,{InvSlotType.Bag}));a.pending=a.pending-1
            end)
        end
        a.pending=a.pending-1
    end)
end
local function finish()
    local p=R.phase;if not p or not R.started then return end
    local valid,reason=true,'';local work={}
    for i=1,p.count do
        local a=R.actors[i];local value=a.work or 0;work[i]=value
        if p.active and value<=0 then valid=false;reason=reason..'wearer '..i..' did no work; ' end
    end
    if not Proof.sustained(R,now(),true) then valid=false;reason=reason..'inactive sustained-work window; ' end
    append('aegis-perf-activity.jsonl',{phase=p.id,valid=valid,reason=reason,work=work,seconds=now()-R.started,
        scans=R.scans or 0,casts=R.casts or 0,poses=R.poses or 0,controller_ms=R.controllerMs or {},module_calls=R.moduleCalls or {},
        native_send_calls=R.netCalls or 0,native_payload_bytes=R.netBytes or 0,network_error=R.networkError or '',
        work_windows=R.workWindows or {}})
    print('[Aegis PERFORMANCE] END '..p.id..' valid='..tostring(valid)..' '..reason)
end
local function advance()
    R.index=R.index+1;R.phase=R.phases[R.index];R.started=nil
    clean()
    if not R.phase then
        signal('done');for _,client in pairs(R.clients) do message(client) end
        print('[Aegis PERFORMANCE] DONE');return
    end
    R.preparing=now();R.prepared=false;R.replicaReady={};R.prepareSentAt=nil
    if R.phase.item~='none' then for i=1,R.phase.count do equipment(R.actors[i],actorPhase(R.actors[i],R.phase)) end end
end
local function begin()
    if not R.phase then advance();return end
    -- Publish the exact local QPC boundary before diagnostics or teardown.
    signal('');finish()
    R.stopping={id=R.phase.id,at=now()};R.stoppedClients={};R.started=nil
    for _,client in pairs(R.clients) do message(client,true) end
end
dofile('LocalMods/System-Aegis/Lua/Tests/performance/scenarios.lua').install(R,
    {D=D,V=V,C=C,H=H,U=U,now=now,item=item,worldItem=worldItem,remove=managed.remove})
function R.run(seconds,repeats,filter)
    assert(not R.phases,'Already running')
    assert(R.ready.PerfA and R.ready.PerfB,'Clients not ready')
    R.duration=seconds;R.phases=catalogue(repeats,filter or '')
    assert(#R.phases>0,'No matching scenarios')
    write('aegis-perf-manifest.json',encode(R.phases));begin()
end
for name,G in pairs({suit=D,combat=C,vacuum=V,headsets=H}) do
    local update=G.update
    G.update=function(dt)
        local before=Clock.GetTimestamp();update(dt)
        if R.started and now()-R.started>=5 then
            R.controllerMs[name]=(R.controllerMs[name] or 0)+(Clock.GetTimestamp()-before)*1000/Clock.Frequency
            R.moduleCalls[name]=(R.moduleCalls[name] or 0)+1
        end
    end
end
Hook.Patch('aegis.performance.network','Barotrauma.Networking.LidgrenServerPeer','Send',function(_,p)
    if not R.started or now()-R.started<5 then return end
    local ok,length=pcall(function() return p['msg'].LengthBytes end)
    if ok and type(length)=='number' then R.netCalls=R.netCalls+1;R.netBytes=R.netBytes+length
    else R.networkError='Cannot read message length: '..tostring(length) end
end,Hook.HookMethodType.Before)
if D then
local cast=D.cast;D.cast=function(...) if R.started and now()-R.started>=5 then R.casts=R.casts+1 end;return cast(...) end
local gather=D.gather;D.gather=function(...) if R.started and now()-R.started>=5 then R.scans=R.scans+1 end;return gather(...) end
local pose=D.toolPose;D.toolPose=function(...) if R.started and now()-R.started>=5 then R.poses=R.poses+1 end;return pose(...) end
local repair=D.repairDevice;D.repairDevice=function(owner,value,target,dt)
    local before=target.entity.Condition;local ok=repair(owner,value,target,dt)
    if R.started and now()-R.started>=5 then for _,a in ipairs(R.actors) do
        if a.item==value then a.work=a.work+math.max(0,target.entity.Condition-before);break end
    end end
    return ok
end
end
Hook.Add('think',P,function()
    Game.Server.EndRoundTimer=1
    if R.failed then return end
    if R.stopping then
        local path=signalRoot..'aegis-perf-stopped.txt'
        local localStop=File.Exists(path) and File.Read(path)==R.stopping.id
        local remoteStop=R.serverOnly or (R.stoppedClients.PerfA and R.stoppedClients.PerfB)
        if localStop and remoteStop then R.stopping=nil;advance()
        elseif now()-R.stopping.at>20 then
            R.failed=true;write('aegis-perf-fatal.txt','Missing native/client stop acknowledgement for '..R.stopping.id)
        end
        return
    end
    if not R.phases or not R.phase then return end
    local p=R.phase
    if not R.started then
        for i=1,8 do local a=R.actors[i];if not a or not a.device or not a.enemy or a.pending>0 then return end end
        if not R.prepared then
            R.prepared=true
            for i=1,p.count do R.prepareItem(R.actors[i],actorPhase(R.actors[i],p)) end
            return
        end
        if now()-R.preparing<2 then return end
        if not R.prepareSentAt or now()-R.prepareSentAt>=2 then
            R.prepareSentAt=now()
            for name,client in pairs(R.clients) do if R.replicaReady[name]~=p.id then prepareMessage(client) end end
        end
        if R.replicaReady.PerfA~=p.id or R.replicaReady.PerfB~=p.id then return end
        if p.mode=='passive' then
            C.clearPassiveSkills()
            for i=1,p.count do local a=R.actors[i]
                a.skillBaseline={}
                for _,skill in ipairs({'helm','weapons','mechanical','electrical','medical'}) do
                    a.c.Info.SetSkillLevel(skill,50,true);a.skillBaseline[skill]=50
                end
            end
            -- Accelerate only pre-measurement setup; normal production ticks
            -- cross the unchanged 300-second threshold inside the sample.
            C.updatePassiveSkills(300-math.max(6,R.duration/2))
        end
        for i=1,p.count do local a=R.actors[i]
            local q=actorPhase(a,p)
            if q.item=='aegisservosuit' then
                D.setMode(a.item,(q.mode=='repair' or q.mode=='combat' or q.mode=='grab') and q.mode or 'off',a.c)
                if q.mode=='repair' then a.device.Condition=10 end
                if q.mode=='combat' then a.enemy.TeamID=CharacterTeamType.Team2 end
            elseif q.item=='aegiscombattool' then
                U.component(a.item,'LightComponent').IsOn=q.mode=='fire' or q.mode=='shield'
            end
        end
        R.started=now();R.maintenance=0;R.scans=0;R.casts=0;R.poses=0;R.controllerMs={};R.moduleCalls={}
        R.workWindows=nil;R.windowBefore=nil;R.windowStart=nil;R.sustainedValid=nil
        R.netCalls=0;R.netBytes=0;R.networkError=nil
        signal(p.id);for _,client in pairs(R.clients) do message(client) end
        print('[Aegis PERFORMANCE] BEGIN '..p.id);return
    end
    if now()-R.started>=R.duration then begin();return end
    for i=1,p.count do
        Proof.followWall(R.actors[i])
        R.inputItem(R.actors[i],actorPhase(R.actors[i],p),1/60)
    end
    if now()-(R.maintenance or 0)<.1 then return end;R.maintenance=now()
    if now()-R.started>=5 then Proof.sustained(R,now()) end
    for i,a in ipairs(R.actors) do
        local q=actorPhase(a,p)
        local medical=i<=p.count and (q.item=='aegisheadset' or q.item=='aegisheadsetmk2') and q.mode~='idle'
        healthy(a.c,medical,medical and q.mode=='pressure');healthy(a.enemy)
        if (a.c.WorldPosition-a.home).Length()>25 then a.c.TeleportTo(a.home) end
        local enemyHome=a.home+Vector2(150,100)
        if (a.enemy.WorldPosition-enemyHome).Length()>25 then a.enemy.TeleportTo(enemyHome) end
        if a.cell then
            if i<=p.count and now()-R.started>=5 and
                q.mode=='extinguish' then
                a.work=a.work+math.max(0,(a.previousCharge or a.cell.MaxCondition)-a.cell.Condition)
            end
            a.cell.Condition=a.cell.MaxCondition;a.previousCharge=a.cell.MaxCondition
        end
        if a.ammo then a.ammo.Condition=a.ammo.MaxCondition end
        if a.oxygen then a.oxygen.Condition=a.oxygen.MaxCondition end
        if i<=p.count then
            R.maintainItem(a,q)
            if q.item=='aegisservosuit' then
                local s=D.state(a.item)
                if q.mode=='repair' and a.device.Condition>65 then a.device.Condition=10 end
                if q.mode=='combat' then
                    local shots=s.shots or 0
                    if now()-R.started>=5 then a.work=a.work+(shots-(a.lastShots or shots))%65536 end
                    a.lastShots=shots
                end
            end
        end
    end
end)
local function ready()
    for i=1,8 do local a=R.actors[i];if not a or not a.device or not a.enemy then Timer.Wait(ready,250);return end end
    local itemCount=0;for _ in Item.ItemList do itemCount=itemCount+1 end
    local characterCount=0;for _ in Character.CharacterList do characterCount=characterCount+1 end
    write('aegis-perf-scene.json',encode({seed=Level.Loaded.Seed,sub=Submarine.MainSub.Info.Name,
        items=itemCount,characters=characterCount,fixture_wearers=8,skill_level=50,skill_reset='each_phase',
        health_reset='all_afflictions_and_client_prediction'}))
    write('aegis-perf-scene-ready.txt','ready');print('[Aegis PERFORMANCE] scene ready')
end
ready()
