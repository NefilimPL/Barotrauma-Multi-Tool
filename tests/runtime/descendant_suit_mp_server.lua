-- Real joined client, disposable local sandbox only. Never package.
assert(SERVER and Game.RoundStarted)
local G=BMTDescendantSuit
local U=require('CombatTool.util')
local P='bmt.servo.probe.v1'
local previous=ServoMPServerProbe
if previous then
    for _,key in ipairs({'suit','cell','tank','rod','device','enemy','wrench','foreign','other'}) do
        local old=previous[key]
        if old and not old.Removed then Entity.Spawner.AddEntityToRemoveQueue(old) end
    end
end
local R={rows={},phase=0,passed=0,failed=0}
ServoMPServerProbe=R
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO MP SERVER] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-mp-server-results.txt',table.concat(R.rows,'\n'))
end
local function sendPhase(phase)
    R.phase=phase
    local m=Networking.Start(P..'.phase');m.WriteByte(phase)
    if phase==1 then
        for _,key in ipairs({'suit','cell','tank','device','enemy','wrench','foreign'}) do m.WriteUInt16(R[key].ID) end
    end
    if phase==5 then m.WriteUInt16(R.rod.ID) end
    if phase==8 then m.WriteUInt16(R.wall.ID);m.WriteUInt16(R.section) end
    Networking.Send(m,R.client.Connection)
end
local function spawn(kind,inventory,callback)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],inventory,nil,nil,callback,false)
end
local function spawnWorld(kind,position,callback)
    local sub=Submarine.MainSub
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],position-sub.Position,sub,nil,nil,callback)
end
local function prepare(client)
    R.client=client
    local c=assert(client.Character,'real controlled character missing');R.wearer=c
    for other in Character.CharacterList do
        if other~=c and not other.IsRemotePlayer and other.Submarine==Submarine.MainSub then
            Entity.Spawner.AddEntityToRemoveQueue(other)
        end
    end
    local room
    for h in Hull.HullList do
        if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
        h.WaterVolume=0;h.Oxygen=10000000
    end
    assert(room)
    local wr=room.WorldRect;R.origin=Vector2(wr.X+wr.Width*.45,wr.Y-wr.Height+65)
    R.sub=Submarine.MainSub;R.localOrigin=R.origin-R.sub.Position
    c.TeleportTo(R.origin);c.GodMode=false
    c.SetAllDamage(0,0,0)
    for item in c.Inventory.AllItems do
        if item.Prefab.Identifier.Value~='idcard' then Entity.Spawner.AddEntityToRemoveQueue(item) end
    end
    -- Repeated disposable runs must not leave degrading junction boxes or loose
    -- inventory in front of the intended repair/grab fixture.
    for item in Item.ItemList do
        if (item.WorldPosition-R.origin).Length()<300 and
            (item.Prefab.Identifier.Value=='junctionbox' or G.portable(item)) then
            Entity.Spawner.AddEntityToRemoveQueue(item)
        end
    end
    -- One damaged fixture prevents unrelated maintenance from taking priority.
    for item in Item.ItemList do if item.Submarine==Submarine.MainSub and U.component(item,'Repairable') then item.Condition=item.MaxCondition end end
    for wall in Structure.WallList do
        if wall.Submarine==Submarine.MainSub and wall.HasBody and not wall.Indestructible then
            for n=0,wall.SectionCount-1 do if wall.SectionDamage(n)>0 then wall.AddDamage(n,-1000000,c,false,false) end end
        end
    end
    spawn('descendantservosuit',c.Inventory,function(suit)
        R.suit=suit;assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
        spawn('batterycell',G.container(suit,2),function(x) R.cell=x end)
        spawn('oxygentank',G.container(suit,1),function(x) R.tank=x end)
    end)
    spawnWorld('junctionbox',R.origin+Vector2(70,25),function(x) R.device=x;x.Condition=10 end)
    spawnWorld('wrench',R.origin+Vector2(230,10),function(x) R.wrench=x;R.grabDistance=(x.WorldPosition-c.WorldPosition).Length() end)
    Entity.Spawner.AddCharacterToSpawnQueue('human',R.origin+Vector2(170,0),function(enemy)
        enemy.TeamID=CharacterTeamType.Team2;enemy.AIController.Enabled=false;R.enemy=enemy
        R.enemyHealth=enemy.Vitality
    end)
    Entity.Spawner.AddCharacterToSpawnQueue('human',R.origin-Vector2(150,0),function(other)
        other.TeamID=c.TeamID;other.AIController.Enabled=false;R.other=other
        spawn('descendantservosuit',other.Inventory,function(suit)
            assert(other.Inventory.TryPutItem(suit,other,{InvSlotType.OuterClothes}));R.foreign=suit
        end)
    end)
    local attempts=0
    local function ready()
        attempts=attempts+1
        for _,key in ipairs({'suit','cell','tank','device','enemy','wrench','foreign'}) do
            if not R[key] then assert(attempts<100,'replicated spawn timeout: '..key);Timer.Wait(ready,100);return end
        end
        Timer.Wait(function() sendPhase(1) end,1000)
    end
    ready()
end
Hook.Add('think','bmt.servo.mp.trace',function()
    if R.phase~=3 or not R.wearer or not R.wrench or R.wrench.Removed then return end
    if G.now<(R.traceAt or 0) then return end
    R.traceAt=G.now+.1
    local c=R.wearer;local b=G.mount(c);local p=R.wrench.WorldPosition
    local cursor=c.CursorWorldPosition
    local target={kind='grab',entity=R.wrench,point={x=p.X,y=p.Y}}
    local s=G.state(R.suit)
    local a=c.AimRefPosition;if c.Submarine then a=a+c.Submarine.Position end
    local dir=cursor-a;local diff=p-a
    local across=math.abs(diff.X*dir.Y-diff.Y*dir.X)/dir.Length()
    log('TRACE grab aim='..tostring(c.IsKeyDown(InputType.Aim))..' use='..tostring(c.IsKeyDown(InputType.Use))..
        ' cursorDistance='..tostring((cursor-p).Length())..' portable='..tostring(G.portable(R.wrench))..
        ' range='..math.sqrt((p.X-b.x)^2+(p.Y-b.y)^2)..' visible='..tostring(G.visible(c,b,target))..
        ' across='..across..' target='..tostring(s.target and s.target.entity.ID))
end)
Networking.Receive(P..'.hello',function(_,client)
    if R.client then return end
    local ok,err=pcall(prepare,client)
    if not ok then log('FAIL setup '..tostring(err)) end
end)
Networking.Receive(P..'.report',function(m,client)
    local phase,clientOK,detail=m.ReadByte(),m.ReadBoolean(),m.ReadString()
    if client~=R.client or phase~=R.phase then return end
    local ok,serverDetail=pcall(function()
        local s=G.state(R.suit)
        if phase==1 then assert(s.mode=='repair' and R.device.Condition>10 and R.cell.Condition<R.cell.MaxCondition,
            'device='..R.device.Condition..' energy='..G.energy(R.suit)..' target='..tostring(s.target and s.target.id))
        elseif phase==2 then assert(s.mode=='combat' and R.enemy.Vitality<R.enemyHealth)
        elseif phase==3 then
            assert(s.mode=='grab' and s.target and s.target.entity==R.wrench)
            assert((R.wrench.WorldPosition-R.wearer.WorldPosition).Length()<R.grabDistance-20,'grab did not pull')
        elseif phase==4 then
            assert(not s.open and R.wearer.AnimController.HeadInWater and R.wearer.OxygenAvailable>90 and s.swimming)
        elseif phase==5 then assert(G.source(R.suit)==R.rod)
        elseif phase==6 then assert(G.state(R.foreign).mode=='off','unauthorized request changed another suit')
        elseif phase==7 then assert(s.mode=='off' and not s.active and not s.target)
        elseif phase==8 then assert(s.mode=='repair' and R.wall.SectionDamage(R.section)<35) end
        return 'server mode='..s.mode..' energy='..G.energy(R.suit)..' tank='..R.tank.Condition
    end)
    if ok and clientOK then R.passed=R.passed+1 else R.failed=R.failed+1 end
    log((ok and clientOK and 'PASS ' or 'FAIL ')..phase..' client={'..detail..'} server={'..tostring(serverDetail)..'}')
    if phase==2 then
        -- The combat fixture would correctly intercept a grab aimed through it.
        if R.enemy and not R.enemy.Removed then Entity.Spawner.AddEntityToRemoveQueue(R.enemy) end
        if R.wrench and not R.wrench.Removed then Entity.Spawner.AddEntityToRemoveQueue(R.wrench) end
        local position=R.wearer.WorldPosition+Vector2(230,40)
        spawnWorld('wrench',position,function(wrench)
            R.wrench=wrench;R.grabDistance=(wrench.WorldPosition-R.wearer.WorldPosition).Length()
            -- Initial setup IDs are already sent; explicitly refresh the target ID.
            local update=Networking.Start(P..'.grabtarget');update.WriteUInt16(wrench.ID);Networking.Send(update,R.client.Connection)
            Timer.Wait(function() sendPhase(3) end,300)
        end)
    elseif phase==3 then
        R.wearer.TeleportTo(Submarine.MainSub.WorldPosition+Vector2(3000,-100))
        Timer.Wait(function() sendPhase(4) end,1000)
    elseif phase==4 then
        sendPhase(0)
        Timer.Wait(function()
            R.wearer.TeleportTo(R.localOrigin+R.sub.Position)
            G.setMode(R.suit,'off',R.wearer)
            Entity.Spawner.AddEntityToRemoveQueue(R.cell)
            Timer.Wait(function()
                spawn('fuelrod',G.container(R.suit,2),function(rod)
                    R.rod=rod;Timer.Wait(function() sendPhase(5) end,1000)
                end)
            end,300)
        end,300)
    elseif phase==7 then
        R.device.Condition=R.device.MaxCondition
        local base=G.mount(R.wearer);local best=140
        for wall in Structure.WallList do
            if wall.Submarine==R.sub and wall.HasBody and not wall.Indestructible and not wall.Prefab.Platform then
                for section=0,wall.SectionCount-1 do
                    local p=wall.SectionPosition(section,true)
                    local d=math.sqrt((p.X-base.x)^2+(p.Y-base.y)^2)
                    local target={kind='weld',entity=wall,section=section,point={x=p.X,y=p.Y}}
                    if d<best and G.visible(R.wearer,base,target) then best=d;R.wall=wall;R.section=section end
                end
            end
        end
        assert(R.wall,'no reachable wall for native welding check')
        R.wall.AddDamage(R.section,35,R.wearer,false,false)
        Timer.Wait(function() sendPhase(8) end,500)
    elseif phase==8 then
        log('RESULT passed='..R.passed..' failed='..R.failed..' real_client=true')
        local done=Networking.Start(P..'.done');Networking.Send(done,R.client.Connection)
    else Timer.Wait(function() sendPhase(phase+1) end,500) end
end)
log('READY waiting for joined client probe')
