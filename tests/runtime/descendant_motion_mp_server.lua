-- Real loopback server acceptance probe. Never package.
assert(SERVER and Game.RoundStarted)
local G=BMTDescendantSuit
local U=require('CombatTool.util')
local P='bmt.servo.motion.mp'
local R={rows={},passed=0,failed=0,phase=0,rewards=0,origins=0};ServoMotionMP=R
local abilities=LuaUserData.CreateEnumTable('Barotrauma.AbilityEffectType')
local sonarModes=LuaUserData.CreateEnumTable('Barotrauma.Items.Components.Sonar+Mode')
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO MOTION MP] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-motion-server.txt',table.concat(R.rows,'\n'))
end
local function inventory(id,inv,fn) Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],inv,nil,nil,fn,false) end
local function world(id,point,fn)
    local sub=Submarine.MainSub
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],point-sub.Position,sub,nil,nil,fn)
end
local function state() return G.state(R.suit) end
local function phase(n)
    R.phase=n;R.at=G.now
    local m=Networking.Start(P..'.phase');m.WriteByte(n)
    for _,key in ipairs({'suit','cell','box','human','device'}) do m.WriteUInt16(R[key] and R[key].ID or 0) end
    Networking.Send(m,R.client.Connection)
end
Hook.Patch(P..'.reward','Barotrauma.Character','CheckTalents',{'Barotrauma.AbilityEffectType','Barotrauma.Abilities.AbilityObject'},function(c,p)
    if c==R.wearer and p['abilityEffectType']==abilities.OnRepairComplete then R.rewards=R.rewards+1 end
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.muzzle','Barotrauma.Items.Components.Projectile','Shoot',function(projectile,p)
    if projectile.Item.Prefab.Identifier.Value~='descendantpulsebolt' or not R.suit then return end
    local muzzle=G.toolPose(R.wearer,state()).muzzle
    local point=ConvertUnits.ToDisplayUnits(p['spawnPos'])
    if projectile.Item.Submarine then point=point+projectile.Item.Submarine.Position end
    R.originError=math.max(R.originError or 0,(point-Vector2(muzzle.x,muzzle.y)).Length());R.origins=R.origins+1
end,Hook.HookMethodType.Before)
local function prepare(client)
    R.client=client;R.wearer=assert(client.Character);local c=R.wearer
    if c.IsDead then c.Revive() end
    c.GodMode=true;c.SetAllDamage(0,0,0)
    for other in Character.CharacterList do
        if other~=c and not other.IsRemotePlayer then Entity.Spawner.AddEntityToRemoveQueue(other) end
    end
    local room
    for h in Hull.HullList do
        if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
        h.WaterVolume=0;h.Oxygen=10000000
    end
    for wall in Structure.WallList do
        if wall.Submarine==Submarine.MainSub and wall.HasBody and not wall.Indestructible then
            for i=0,wall.SectionCount-1 do if wall.SectionDamage(i)>0 then wall.AddDamage(i,-100000,c,false,false) end end
        end
    end
    local rect=room.WorldRect;R.localHome=Vector2(rect.X+rect.Width*.2,rect.Y-rect.Height+70)-Submarine.MainSub.Position
    c.TeleportTo(R.localHome+Submarine.MainSub.Position)
    local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
    for _,item in ipairs(old) do if item.Prefab.Identifier.Value~='idcard' then item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end end
    for item in Item.ItemList do
        if U.component(item,'Repairable') then item.Condition=item.MaxCondition end
    end
    inventory('descendantservosuit',c.Inventory,function(suit)
        R.suit=suit;assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
        inventory('batterycell',G.container(suit,1),function(cell) R.cell=cell end)
        inventory('pulselaserammobox',c.Inventory,function(box)
            assert(G.container(suit,1).TryPutItem(box,1,false,false,c));R.box=box
        end)
    end)
    Entity.Spawner.AddCharacterToSpawnQueue('human',c.WorldPosition+Vector2(130,20),function(h)
        h.TeamID=c.TeamID;h.AIController.Enabled=false;R.human=h
    end)
    local function ready()
        if not R.suit or not R.cell or not R.box or not R.human then Timer.Wait(ready,100);return end
        log('READY real joined client; protocol='..require('DescendantSuit.config').protocol);phase(1)
    end
    ready()
end
local function verify(n)
    local c,s=R.wearer,state()
    if n==1 then assert(G.equipped(c)==R.suit and G.source(R.suit)==R.cell and G.ammo(R.suit)==R.box);return 'native inventory replicated'
    elseif n==2 then
        assert(s.grip and s.target.entity==R.human and R.human.IsForceRagdolled)
        assert(not c.IsKeyDown(InputType.Aim) and not c.IsKeyDown(InputType.Use))
        local error=(c.WorldPosition+Vector2(s.grip.offset.x,s.grip.offset.y)-R.human.WorldPosition).Length()
        assert(error<35,'hold error='..error..' recovery='..tostring(s.grip.recovering))
        assert(s.grip.recovering or R.human.WorldPosition.Y>c.WorldPosition.Y+20,'open hold lost lift')
        return 'latch='..(G.now-R.at)..'s anchorError='..error..' recovery='..tostring(s.grip.recovering)..' anchorY='..s.grip.offset.y
    elseif n==3 then
        local sonar=U.component(R.suit,'Sonar')
        assert(s.sonar and s.mode=='grab' and s.grip and sonar.IsActive and sonar.HasPower)
        return 'native sonar powered while gripping'
    elseif n==4 then
        assert(s.sonar and s.sonarActive==false and U.component(R.suit,'Sonar').CurrentMode==sonarModes.Passive)
        assert(s.grip and s.mode=='grab');return 'passive mode authorized; latch retained'
    elseif n==5 then assert(not s.grip and not s.target and not R.human.IsForceRagdolled);return 'released by client second press'
    elseif n==6 then
        assert(R.device.Condition>95 and c.GetSkillLevel('electrical')>R.skill and R.rewards==1)
        return 'condition='..R.device.Condition..' skill='..c.GetSkillLevel('electrical')..' nativeCompletions='..R.rewards
    elseif n==7 then
        assert(s.shots and s.shots>0 and R.box.Condition<R.ammo and R.origins>0 and R.originError<.1)
        return 'shots='..s.shots..' originError='..R.originError
    elseif n==8 then
        assert(s.grip and R.human.IsForceRagdolled);R.cell.Condition=0;return 'power drained during a second live latch'
    elseif n==9 then
        assert(not s.grip and not s.target and not R.human.IsForceRagdolled and G.energy(R.suit)==0)
        return 'power loss safely restored ragdoll'
    end
end
Networking.Receive(P..'.hello',function(_,client)
    if R.client then return end
    prepare(client)
end)
Networking.Receive(P..'.report',function(m,client)
    local n,clientOK,detail=m.ReadByte(),m.ReadBoolean(),m.ReadString()
    if client~=R.client or n~=R.phase then return end
    local ok,result=pcall(verify,n);ok=ok and clientOK
    if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end
    log((ok and 'PASS ' or 'FAIL ')..n..' server='..tostring(result)..' client='..detail)
    if n==5 then
        local c=R.wearer;c.Info.SetSkillLevel('electrical',20);R.skill=c.GetSkillLevel('electrical')
        world('junctionbox',c.WorldPosition+Vector2(175,-30),function(device)
            R.device=device;device.Condition=5;phase(6)
            Timer.Wait(function() c.TeleportTo(c.WorldPosition+Vector2(-25,0)) end,700)
        end)
    elseif n==6 then
        local water=Submarine.MainSub.WorldPosition+Vector2(3500,-400);R.wearer.TeleportTo(water);R.ammo=R.box.Condition
        Entity.Spawner.AddCharacterToSpawnQueue('crawler',water+Vector2(-650,20),function(enemy)
            enemy.AIController.Enabled=false;R.enemy=enemy;phase(7)
        end)
    elseif n==7 then
        if R.enemy and not R.enemy.Removed then Entity.Spawner.AddEntityToRemoveQueue(R.enemy) end
        R.wearer.TeleportTo(R.localHome+Submarine.MainSub.Position)
        R.human.TeleportTo(R.wearer.WorldPosition+Vector2(130,20));R.human.SetAllDamage(0,0,0)
        phase(8)
    elseif n==9 then
        log('RESULT passed='..R.passed..' failed='..R.failed..' real_joined_client=true')
        local done=Networking.Start(P..'.done');Networking.Send(done,R.client.Connection)
    else phase(n+1) end
end)
log('WAITING for real joined client')
