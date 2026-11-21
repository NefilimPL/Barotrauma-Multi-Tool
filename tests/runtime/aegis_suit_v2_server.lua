-- Isolated joined-client sandbox only; never distribute in the mod.
assert(SERVER and Game.RoundStarted)
local G=AegisSuit
local U=require('AegisCombat.util')
local C=require('AegisSuit.config')
local P='aegis.servo.v2.probe'
local R={rows={},passed=0,failed=0,stage=0,rewards=0}
ServoV2Probe=R
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO V2] '..line)
    File.Write('LocalMods/System-Aegis/servo-v2-server.txt',table.concat(R.rows,'\n'))
end
local function inventory(kind,inv,fn)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],inv,nil,nil,fn,false)
end
local function world(kind,position,fn)
    local sub=Submarine.MainSub
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],position-sub.Position,sub,nil,nil,fn)
end
local function phase(n)
    R.stage=n
    local m=Networking.Start(P..'.phase');m.WriteByte(n)
    for _,key in ipairs({'suit','cell','ammo','device','enemy','wrench'}) do m.WriteUInt16(R[key] and R[key].ID or 0) end
    m.WriteUInt16(R.wall and R.wall.ID or 0);m.WriteUInt16(R.section or 0)
    Networking.Send(m,R.client.Connection)
end
local function nextPhase(n,delay) Timer.Wait(function() phase(n) end,delay or 400) end
local abilities=LuaUserData.CreateEnumTable('Barotrauma.AbilityEffectType')
Hook.Patch('aegis.servo.v2.rewards','Barotrauma.Character','CheckTalents',{'Barotrauma.AbilityEffectType','Barotrauma.Abilities.AbilityObject'},function(c,p)
    if c==R.wearer and p['abilityEffectType']==abilities.OnRepairComplete then R.rewards=R.rewards+1 end
end,Hook.HookMethodType.Before)
local function prepare(client)
    R.client=client;R.wearer=assert(client.Character);local c=R.wearer
    for other in Character.CharacterList do
        if other~=c and not other.IsRemotePlayer and (other.Submarine==Submarine.MainSub or G.equipped(other)) then Entity.Spawner.AddEntityToRemoveQueue(other) end
    end
    local room
    for h in Hull.HullList do
        if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
        h.WaterVolume=0;h.Oxygen=10000000
    end
    local wr=room.WorldRect
    R.localOrigin=Vector2(wr.X+wr.Width*.20,wr.Y-wr.Height+70)-Submarine.MainSub.Position
    R.origin=R.localOrigin+Submarine.MainSub.Position
    c.TeleportTo(R.origin);c.GodMode=false;c.SetAllDamage(0,0,0)
    for old in c.Inventory.AllItems do if old.Prefab.Identifier.Value~='idcard' then Entity.Spawner.AddEntityToRemoveQueue(old) end end
    for old in Item.ItemList do
        if old.Submarine==Submarine.MainSub and U.component(old,'Repairable') then old.Condition=old.MaxCondition end
        if (old.WorldPosition-R.origin).Length()<300 and (old.Prefab.Identifier.Value=='junctionbox' or G.portable(old)) then Entity.Spawner.AddEntityToRemoveQueue(old) end
    end
    for wall in Structure.WallList do
        if wall.Submarine==Submarine.MainSub and wall.HasBody and not wall.Indestructible then
            for n=0,wall.SectionCount-1 do if wall.SectionDamage(n)>0 then wall.AddDamage(n,-100000,c,false,false) end end
        end
    end
    pcall(function() c.Info.SetSkillLevel('electrical',20) end)
    R.skill=c.GetSkillLevel('electrical')
    inventory('aegisservosuit',c.Inventory,function(suit)
        R.suit=suit;assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
        inventory('batterycell',G.container(suit,1),function(cell) R.cell=cell end)
        inventory('pulselaserammobox',c.Inventory,function(ammo)
            assert(G.container(suit,1).TryPutItem(ammo,1,false,false,c));R.ammo=ammo
        end)
    end)
    world('junctionbox',R.origin+Vector2(60,20),function(device) R.device=device;device.Condition=10 end)
    local function ready()
        if not R.suit or not R.cell or not R.ammo or not R.device then Timer.Wait(ready,100);return end
        log('READY real-client=true skill='..R.skill..' range='..C.combatRange..' pulseDamage='..C.shotDamage)
        nextPhase(1,1000)
    end
    ready()
end
Networking.Receive(P..'.hello',function(_,client)
    if R.client then return end
    local ok,err=pcall(prepare,client);if not ok then log('FAIL setup '..tostring(err)) end
end)
Networking.Receive(P..'.report',function(m,client)
    local n,clientOK,detail=m.ReadByte(),m.ReadBoolean(),m.ReadString()
    if client~=R.client or n~=R.stage then return end
    local ok,server=pcall(function()
        local s=G.state(R.suit)
        if n==1 then
            assert(G.source(R.suit)==R.cell and G.ammo(R.suit)==R.ammo and R.suit.OwnInventory.Capacity==2)
            assert(R.device.Condition>20,'native repair did not progress: '..R.device.Condition)
        elseif n==2 then
            assert(R.device.IsFullCondition,'native repair not complete: '..R.device.Condition)
            assert(R.rewards==1,'native OnRepairComplete count='..R.rewards)
            assert(R.wearer.GetSkillLevel('electrical')>R.skill,'no native skill gain')
        elseif n==3 then
            assert(R.enemy.Vitality<R.enemyHealth-20,'pulse damage too low')
            assert(R.ammo.Condition<100 and (s.shots or 0)>0,'no pulse ammo debit')
        elseif n==4 then assert(R.ammo.Condition==0 and (s.shots or 0)==R.stoppedShots,'fired without ammo')
        elseif n==5 then assert(s.target and s.target.entity==R.wrench and (R.wrench.WorldPosition-R.wearer.WorldPosition).Length()<180,'grab failed')
        elseif n==6 then assert(not s.open and R.wearer.AnimController.HeadInWater and R.wearer.OxygenAvailable>90 and s.swimming)
        elseif n==7 then assert(R.wall.SectionDamage(R.section)<5,'welding slow or blocked')
        elseif n==8 then
            assert(R.bot.IsBot and G.equipped(R.bot)==R.botSuit,'AI unequipped suit')
            assert(G.source(R.botSuit)==R.spareCell and G.ammo(R.botSuit)==R.spareAmmo,'AI did not install own supplies')
        elseif n==9 then assert(G.source(R.botSuit)==R.remoteCell and G.ammo(R.botSuit)==R.remoteAmmo,'AI did not fetch/replace storage supplies')
        elseif n==10 then
            assert(G.energy(R.suit)==0 and R.wearer.OxygenAvailable==0)
            assert(G.equipped(R.bot)==R.botSuit and R.bot.OxygenAvailable>90,'AI closed loop failed in water')
        elseif n==11 then assert(s.mode=='repair' and s.active,'toggle did not restore mode') end
        return 'mode='..s.mode..' device='..R.device.Condition..' skill='..R.wearer.GetSkillLevel('electrical')..
            ' rewards='..R.rewards..' power='..G.energy(R.suit)..' ammo='..R.ammo.Condition..' shots='..(s.shots or 0)
    end)
    local pass=ok and clientOK
    R[pass and 'passed' or 'failed']=R[pass and 'passed' or 'failed']+1
    log((pass and 'PASS ' or 'FAIL ')..n..' client={'..detail..'} server={'..tostring(server)..'}')
    if n==1 then nextPhase(2,7000)
    elseif n==2 then
        Entity.Spawner.AddCharacterToSpawnQueue('human',R.wearer.WorldPosition+Vector2(650,0),function(enemy)
            enemy.TeamID=CharacterTeamType.Team2;enemy.AIController.Enabled=false
            R.enemy=enemy;R.enemyHealth=enemy.Vitality;nextPhase(3,500)
        end)
    elseif n==3 then R.ammo.Condition=0;R.stoppedShots=G.state(R.suit).shots or 0;nextPhase(4)
    elseif n==4 then
        if R.enemy and not R.enemy.Removed then Entity.Spawner.AddEntityToRemoveQueue(R.enemy) end
        world('wrench',R.wearer.WorldPosition+Vector2(230,40),function(wrench) R.wrench=wrench;nextPhase(5,300) end)
    elseif n==5 then R.wearer.TeleportTo(Submarine.MainSub.WorldPosition+Vector2(3000,-100));nextPhase(6,1000)
    elseif n==6 then
        phase(0)
        Timer.Wait(function()
            R.wearer.TeleportTo(R.localOrigin+Submarine.MainSub.Position)
            G.setMode(R.suit,'off',R.wearer);R.device.Condition=R.device.MaxCondition
            local base=G.mount(R.wearer);local best=140
            for wall in Structure.WallList do
                if wall.Submarine==Submarine.MainSub and wall.HasBody and not wall.Indestructible and not wall.Prefab.Platform then
                    for section=0,wall.SectionCount-1 do
                        local p=wall.SectionPosition(section,true)
                        local t={kind='weld',entity=wall,section=section,point={x=p.X,y=p.Y}}
                        local d=math.sqrt((p.X-base.x)^2+(p.Y-base.y)^2)
                        if d<best and G.visible(R.wearer,base,t) then best=d;R.wall=wall;R.section=section end
                    end
                end
            end
            assert(R.wall);R.wall.AddDamage(R.section,100,R.wearer,false,false);nextPhase(7,500)
        end,300)
    elseif n==7 then
        Entity.Spawner.AddCharacterToSpawnQueue('human',R.wearer.WorldPosition-Vector2(220,0),function(bot)
            R.bot=bot;bot.TeamID=R.wearer.TeamID;bot.AIController.Enabled=true
            inventory('aegisservosuit',bot.Inventory,function(suit)
                R.botSuit=suit;assert(bot.Inventory.TryPutItem(suit,bot,{InvSlotType.OuterClothes}))
                inventory('batterycell',bot.Inventory,function(x) R.spareCell=x end)
                inventory('pulselaserammobox',bot.Inventory,function(x) R.spareAmmo=x end)
                nextPhase(8,2500)
            end)
        end)
    elseif n==8 then
        R.spareCell.Condition=0;R.spareAmmo.Condition=0
        world('metalcrate',R.bot.WorldPosition+Vector2(450,0),function(crate)
            R.crate=crate
            inventory('batterycell',crate.OwnInventory,function(x) R.remoteCell=x end)
            world('coilgunammoshelf',crate.WorldPosition+Vector2(80,20),function(shelf)
                R.shelf=shelf
                inventory('pulselaserammobox',shelf.OwnInventory,function(x) R.remoteAmmo=x end)
            end)
            nextPhase(9,20000)
        end)
    elseif n==9 then
        R.cell.Condition=0
        R.wearer.TeleportTo(Submarine.MainSub.WorldPosition+Vector2(3000,-100))
        R.bot.TeleportTo(Submarine.MainSub.WorldPosition+Vector2(2000,-100))
        nextPhase(10,1000)
    elseif n==10 then
        R.cell.Condition=100;R.device.Condition=10
        R.wearer.TeleportTo(R.localOrigin+Submarine.MainSub.Position)
        nextPhase(11,500)
    elseif n==11 then
        log('RESULT passed='..R.passed..' failed='..R.failed..' real_joined_client=true')
        local done=Networking.Start(P..'.done');Networking.Send(done,R.client.Connection)
    end
end)
log('WAITING for client')
