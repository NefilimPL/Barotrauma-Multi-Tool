-- Sustained native-ammunition stress. Fixed native emitters; real player aiming shields.
assert(SERVER and CombatSession)
local R,G,U=CombatSession,BMTCombat,require('CombatTool.util')
R.running=false;R.ready={};R.mass=false
Hook.Remove('think','bmt.session.followup')
Hook.RemovePatch('bmt.session.aim-npc','Barotrauma.Character','UpdateNetInput',Hook.HookMethodType.After)
local S={index=0,rows={},lastSupply=0,lastShot=0}
CombatShieldStress=S
local function now() return R.clock.ElapsedMilliseconds/1000 end
local phases={{'mass_idle_A','CombatA',false},{'mass_block_A','CombatA',true},
    {'mass_idle_B','CombatB',false},{'mass_block_B','CombatB',true}}
local function healthy(c) c.Oxygen=100;c.PressureProtection=1000000;c.Stun=0 end
local function send(client,target,aim,shoot)
    local m=Networking.Start('bmt.combat.session.phase');m.WriteString(S.phase)
    m.WriteUInt16(target and target.ID or 0);m.WriteBoolean(aim);m.WriteBoolean(shoot)
    m.WriteSingle(R.origin.X);m.WriteSingle(R.origin.Y+50);Networking.Send(m,client.Connection)
end
local function report()
    if not S.phase then return end
    local row={'phase='..S.phase,'seconds='..string.format('%.2f',now()-S.started)}
    for k,v in pairs(R.counts) do row[#row+1]=k..'='..v end
    S.rows[#S.rows+1]=table.concat(row,' ')
    File.Write('LocalMods/MULTI-TOOL-V2/combat-session-shield-stress.txt',table.concat(S.rows,'\n'))
    print('[SHIELD STRESS] '..S.rows[#S.rows])
end
local function begin()
    report();S.index=S.index+1;local p=phases[S.index]
    if not p then
        S.phase='done';R.phase='done';R.mass=false
        for _,client in pairs(R.clients) do send(client,nil,false,false) end
        print('[SHIELD STRESS] DONE');return
    end
    S.phase=p[1];S.actor=p[2];S.active=p[3];S.started=now();S.lastSupply=now();S.lastShot=now()
    R.phase=S.phase;R.actor=S.actor;R.mass=S.active;R.counts={};R.victims={}
    for name,client in pairs(R.clients) do
        local c=assert(client.Character);if c.IsDead then c.Revive(true,true) end
        c.CharacterHealth.RemoveAllAfflictions();c.SetAllDamage(0,0,0);c.GodMode=true;healthy(c)
        Game.Server.SetClientCharacter(client,c)
        local gun=R.guns[name]
        for item in c.Inventory.AllItems do if item~=gun then item.Drop(c,true) end end
        if c.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)~=gun or c.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)~=gun then
            assert(c.Inventory.TryPutItem(gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
        end
        U.component(gun,'LightComponent').IsOn=true;G.state(gun).brokenUntil=0;R.cells[name].Condition=100
        c.TeleportTo(R.origin+Vector2(name==S.actor and -350 or -100,name==S.actor and 0 or 150))
    end
    for i,c in ipairs(R.npcs) do
        if c.IsDead then c.Revive(true,true) end
        c.CharacterHealth.RemoveAllAfflictions();c.SetAllDamage(0,0,0);c.GodMode=true;healthy(c)
        c.AIController.Enabled=false;c.IsRemotePlayer=false
        local a=(i-8)*math.pi/84
        c.TeleportTo(R.origin+Vector2(-350+600*math.cos(a),600*math.sin(a)))
        local gun=R.guns[i];gun.Drop(c,true);gun.body.Enabled=false
        local ranged=U.component(gun,'RangedWeapon');ranged.Spread=0;ranged.UnskilledSpread=0
    end
    send(R.clients[S.actor],R.npcs[8],true,false)
    send(R.clients[S.actor=='CombatA' and 'CombatB' or 'CombatA'],R.clients[S.actor].Character,S.active,S.active)
    print('[SHIELD STRESS] PHASE '..S.phase)
end
Hook.Add('think','bmt.session.shield-stress',function()
    if not S.phase or S.phase=='done' then return end
    local t=now();if t-S.started>=18 then begin();return end
    for _,client in pairs(R.clients) do healthy(client.Character) end
    for _,cell in pairs(R.cells) do cell.Condition=100 end
    local defender=R.clients[S.actor].Character
    local state=G.state(R.guns[S.actor])
    if state.shield then R.counts.activeShieldTicks=(R.counts.activeShieldTicks or 0)+1 end
    if defender.IsDead then R.counts.deadTicks=(R.counts.deadTicks or 0)+1 end
    if S.active and t-S.lastShot>.1 then
        S.lastShot=t
        local target=defender.AnimController.MainLimb.WorldPosition
        for i,c in ipairs(R.npcs) do
            local gun=R.guns[i];local angle=(i-8)*math.pi/84
            local origin=R.origin+Vector2(-350+600*math.cos(angle),600*math.sin(angle))
            local delta=target-origin
            gun.body.Dir=1;gun.body.SetTransform(ConvertUnits.ToSimUnits(origin),math.atan2(delta.Y,delta.X))
            if U.component(gun,'RangedWeapon').Use(.1,c) then R.counts.nativeShots=(R.counts.nativeShots or 0)+1 end
        end
    end
    if S.active and t-S.lastSupply>.5 then
        S.lastSupply=t
        for i=1,15 do local gun=R.guns[i];if not gun.OwnInventory.IsFull(false) then
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['shotgunshell'],gun.OwnInventory,nil,nil,nil,false)
        end end
    end
end)
begin()
