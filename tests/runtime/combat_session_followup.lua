-- Continue the same real two-client session with normal-health damage cases.
assert(SERVER and CombatSession)
local R,G,U=CombatSession,BMTCombat,require('CombatTool.util')
R.running=false;R.ready={}
local L={index=0,counts={},kills={},pending={},rows={}}
CombatSessionFollowup=L
local function now() return R.clock.ElapsedMilliseconds/1000 end
local d=LuaUserData.RegisterType('Barotrauma.Character');LuaUserData.MakeFieldAccessible(d,'dequeuedInput')
local ai=LuaUserData.RegisterType('Barotrauma.AICharacter');LuaUserData.MakeFieldAccessible(ai,'dequeuedInput')
local flags=LuaUserData.CreateEnumTable('Barotrauma.Character+InputNetFlags')
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end end
local phases={
    {'live_single_idle',1,false,false,'CombatA'},
    {'live_single_A',1,true,false,'CombatA'},
    {'live_cluster_idle',15,false,false,'CombatA'},
    {'live_cluster_A',15,true,false,'CombatA'},
}
local function healthy(c)
    c.Oxygen=100;c.PressureProtection=1000000;c.Stun=0
end
local function send(client,target,aim,shoot)
    local m=Networking.Start('bmt.combat.session.phase');m.WriteString(L.phase)
    m.WriteUInt16(target and target.ID or 0);m.WriteBoolean(aim);m.WriteBoolean(shoot)
    m.WriteSingle(L.base.X);m.WriteSingle(L.base.Y+40);Networking.Send(m,client.Connection)
end
local function pose(i)
    if L.shield then
        local angle=(i-8)*math.pi/84
        return L.base+Vector2(-350+600*math.cos(angle),600*math.sin(angle))
    end
    return L.base+Vector2(i<=L.count and 150+(i-1)%5*40 or 10000+i*100,(math.floor((i-1)/5)-1)*40)
end
local function report()
    if not L.phase then return end
    local victims=0;for _ in pairs(R.victims) do victims=victims+1 end
    local row={'phase='..L.phase,'seconds='..string.format('%.2f',now()-L.started),'victims='..victims}
    for k,v in pairs(R.counts) do row[#row+1]=k..'='..v end
    L.rows[#L.rows+1]=table.concat(row,' ')
    File.Write('LocalMods/MULTI-TOOL-V2/combat-session-followup.txt',table.concat(L.rows,'\n'))
    print('[COMBAT FOLLOWUP] '..L.rows[#L.rows])
end
local function begin()
    report();L.index=L.index+1;local p=phases[L.index]
    if not p then
        L.phase='done';R.phase='done';R.mass=false
        for _,client in pairs(R.clients) do send(client,nil,false,false) end
        print('[COMBAT FOLLOWUP] DONE');return
    end
    L.phase=p[1];L.count=p[2];L.fire=p[3];L.shield=p[4];L.actor=p[5];L.mass=p[6]
    L.base=L.shield and R.origin or room.WorldPosition
    R.phase=L.phase;R.mass=L.mass;R.actor=L.actor;R.counts={};R.victims={}
    L.started=now();L.lastShot=now();L.lastSupply=now();L.lastTarget=now();L.target=1;L.pending={}
    for name,client in pairs(R.clients) do
        local c=assert(client.Character)
        if c.IsDead then c.Revive(true,true) end
        c.CharacterHealth.RemoveAllAfflictions();c.SetAllDamage(0,0,0);healthy(c);c.GodMode=L.shield
        Game.Server.SetClientCharacter(client,c)
        local gun=R.guns[name]
        for item in c.Inventory.AllItems do if item~=gun then item.Drop(c,true) end end
        if c.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)~=gun or c.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)~=gun then
            assert(c.Inventory.TryPutItem(gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
        end
        U.component(gun,'LightComponent').IsOn=true
        c.TeleportTo(L.base+Vector2(name==L.actor and -350 or L.shield and 0 or -350,name==L.actor and 0 or L.shield and 200 or 50))
    end
    for i,c in ipairs(R.npcs) do
        if c.IsDead then c.Revive(true,true) end
        c.CharacterHealth.RemoveAllAfflictions();c.CharacterHealth.SetVitality(100);c.SetAllDamage(0,0,0)
        c.AIController.Enabled=false;c.IsRemotePlayer=L.shield;c.GodMode=L.shield;healthy(c);c.TeleportTo(pose(i))
    end
    send(R.clients[L.actor],R.npcs[1],L.fire or L.shield,L.fire)
    send(R.clients[L.actor=='CombatA' and 'CombatB' or 'CombatA'],R.clients[L.actor].Character,L.mass or false,L.mass or false)
    print('[COMBAT FOLLOWUP] PHASE '..L.phase)
end
Hook.Patch('bmt.session.aim-npc','Barotrauma.Character','UpdateNetInput',function(c)
    if not L.shield then return end
    for _,npc in ipairs(R.npcs) do if npc==c then
        local target=R.clients[L.actor].Character.AnimController.MainLimb.WorldPosition
        c.dequeuedInput=flags.Aim+flags.FacingLeft
        c.CursorPosition=c.Position+target-c.WorldPosition
        c.Enabled=true;c.AnimController.Frozen=false;healthy(c);return
    end end
end,Hook.HookMethodType.After)
Hook.Add('think','bmt.session.followup',function()
    if not L.phase or L.phase=='done' then return end
    local t=now()
    if t-L.started>=18 then begin();return end
    for _,client in pairs(R.clients) do healthy(client.Character) end
    for _,cell in pairs(R.cells) do cell.Condition=100 end
    if not L.shield then
        for i,c in ipairs(R.npcs) do if c.IsDead and not L.pending[c] then
            L.pending[c]=true;R.counts.kills=(R.counts.kills or 0)+1
            Timer.Wait(function()
                c.Revive(true,true);c.CharacterHealth.RemoveAllAfflictions();c.SetAllDamage(0,0,0);healthy(c)
                c.TeleportTo(pose(i));L.pending[c]=nil
            end,1000)
        end end
    end
    if L.fire and t-L.lastTarget>=1 then
        L.lastTarget=t;L.target=L.target%L.count+1
        send(R.clients[L.actor],R.npcs[L.target],true,true)
    end
    if L.mass and t-L.lastShot>.1 then
        L.lastShot=t
        for i=1,15 do if U.component(R.guns[i],'RangedWeapon').Use(.1,R.npcs[i]) then R.counts.nativeShots=(R.counts.nativeShots or 0)+1 end end
    end
    if L.mass and t-L.lastSupply>.5 then
        L.lastSupply=t
        for i=1,15 do local gun=R.guns[i];if not gun.OwnInventory.IsFull(false) then
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['shotgunshell'],gun.OwnInventory,nil,nil,nil,false)
        end end
    end
end)
begin()
