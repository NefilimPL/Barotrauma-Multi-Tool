-- Native SP integration probe, isolated test copy only; never package.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTDescendantSuit;local c=Character.Controlled;local B=assert(ServoService)
local suit=B.suit;local M=require('DescendantSuit.motion');local U=require('CombatTool.util')
local R={rows={},steps={},index=0,passed=0,failed=0,bubbles=0,work=0,track=0,samples=0,maxStep=0,hands=0}
ServoExtra=R;local P='bmt.servo.extra'
local function s() return G.state(suit) end
local function log(line) R.rows[#R.rows+1]=line;print('[SERVO EXTRA] '..line);File.Write('LocalMods/MULTI-TOOL-V2/servo-service-extra.txt',table.concat(R.rows,'\n')) end
local function add(delay,name,fn) R.steps[#R.steps+1]={delay=delay,name=name,fn=fn} end
local function capture(name) File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/servo-service-'..name..'.png') end
local animations=LuaUserData.CreateEnumTable('Barotrauma.AnimController+Animation')
G.setMode(suit,'off',c);c.SelectedItem=nil;c.SelectedSecondaryItem=nil;c.AnimController.Anim=animations.None
R.otherDevices={}
for item in Item.ItemList do local r=item.GetComponentString('Repairable');if r then item.Condition=item.MaxCondition;r.DeteriorationSpeed=0;R.otherDevices[#R.otherDevices+1]=item end end
for other in Character.CharacterList do if other~=c and other~=B.human then Entity.Spawner.AddEntityToRemoveQueue(other) end end
local origin=Submarine.MainSub.WorldPosition+Vector2(0,3000)
for i=1,30 do
    if not G.cast({x=origin.X-400,y=origin.Y},{x=origin.X+1400,y=origin.Y},180,c,true) then break end
    origin=origin+Vector2(0,400)
end
c.TeleportTo(origin);c.GodMode=true;c.SetAllDamage(0,0,0);B.cell.Condition=100
local function inputs(character)
    if character~=c then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Aim,InputType.Use,InputType.Shoot,InputType.Crouch}) do c.SetInput(key,false,false) end
    c.SetInput(InputType.Right,false,R.move==true);c.SetInput(InputType.Run,false,R.move==true)
    local a=R.turn and math.floor((G.now-R.turn)*2)%4 or 0
    local look=({Vector2(800,0),Vector2(-800,0),Vector2(0,800),Vector2(0,-800)})[a+1]
    c.CursorPosition=c.Position+look;c.Oxygen=100
end
for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.Patch(P..e[1],'Barotrauma.Character',e[1],inputs,e[2]) end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(ch,p) if ch==c then p.PreventExecution=true;inputs(c) end end,Hook.HookMethodType.Before)
Hook.Patch(P..'.hands','Barotrauma.AnimController','UpdateUseItem',function(anim) if anim==c.AnimController and s().mode=='repair' then R.hands=R.hands+1 end end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam;cam.Zoom=1.5;cam.Position=c.WorldPosition+Vector2(100,30);cam.TargetPos=cam.Position;cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
add(.5,'native water setup',function()
    assert(c.AnimController.InWater and c.Submarine==nil)
    R.device=Item(ItemPrefab.Prefabs['junctionbox'],c.Position+Vector2(160,30),nil)
    R.device.Condition=5;R.device.GetComponentString('Repairable').DeteriorationSpeed=0
    G.setMode(suit,'repair',c);R.turn=G.now;R.observe=true
    return 'clear water; repair target at 160/30'
end)
add(5,'repair tracks native swimming turns without steering wearer',function()
    R.observe=false;R.turn=nil
    log('METRICS targetTicks='..R.track..' workTicks='..R.work..' maxWorldStep='..R.maxStep..' gain='..tostring(R.gain))
    assert(R.track>200,'target lost samples='..R.track)
    assert(R.work>120,'work interrupted: '..R.work..'/'..R.samples)
    assert(R.maxStep<.7,'arm swept during torso turn: '..R.maxStep)
    assert(R.hands==0,'wearer hands controlled')
    capture('water-repair')
    return 'targetTicks='..R.track..' workTicks='..R.work..' samples='..R.samples..' maxWorldStep='..R.maxStep..' repairGain='..(R.gain or 0)..' hands='..R.hands
end)
add(.1,'swim bubble setup',function() R.observe=false;R.turn=nil;G.setMode(suit,'off',c);R.move=true;return 'native right+run in water' end)
add(2,'swimming emits native bubbles',function()
    local bubbles=0
    for prefab,count in pairs(Game.ParticleManager.CountActiveParticles()) do if prefab.Name=='bubbles' then bubbles=bubbles+count end end
    assert(s().swimming and bubbles>0,'native bubbles absent: '..bubbles)
    capture('bubbles');return 'native live bubbles='..bubbles
end)
add(.1,'combat setup',function()
    R.move=false
    c.TeleportTo(origin);G.setMode(suit,'off',c)
    if B.human.IsDead then B.human.Revive() end
    B.human.GodMode=true;B.human.Oxygen=100
    B.human.TeleportTo(c.WorldPosition+Vector2(60,0));B.human.SetAllDamage(0,0,0)
    R.positionCombat=true;R.block=false
    Entity.Spawner.AddCharacterToSpawnQueue('crawler',c.WorldPosition+Vector2(600,0),function(enemy) enemy.AIController.Enabled=false;enemy.GodMode=true;R.enemy=enemy end)
    return 'crawler spawn scheduled'
end)
add(.5,'ally blocks torso ray while planned nozzle is clear',function()
    local q=R.enemy.WorldPosition;local t={entity=R.enemy,kind='combat',point={x=q.X,y=q.Y}}
    if G.visible(c,G.mount(c),t) then
        local torso=B.human.AnimController.GetLimb(LimbType.Torso)
        local base=G.mount(c);local body=torso.body
        log('RAY_DEBUG mount='..base.x..','..base.y..' friend='..torso.WorldPosition.X..','..torso.WorldPosition.Y..' enabled='..tostring(body.Enabled)..' collider='..tostring(B.human.Enabled)..' simple='..tostring(B.human.AnimController.SimplePhysicsEnabled)..' sub='..tostring(B.human.Submarine)..' ownerSub='..tostring(c.Submarine)..' enemy='..q.X..','..q.Y)
    end
    assert(not G.visible(c,G.mount(c),t),'fixture torso ray not blocked')
    assert(G.visibleFromTool(c,s(),t,true),'planned muzzle still blocked')
    R.ammo=B.box.Condition;R.shots=s().shots or 0;R.health=B.human.CharacterHealth.Vitality
    G.setMode(suit,'combat',c);return 'native ally between torso and enemy'
end)
add(2,'native pulse fires from exposed tool above ally',function()
    assert((s().shots or 0)>R.shots and B.box.Condition<R.ammo,'no shot above ally')
    assert(B.human.CharacterHealth.Vitality>=R.health-.01,'friendly injured')
    capture('ally-pulse');R.block=true
    return 'shots='..((s().shots or 0)-R.shots)..' friendlyVitality='..B.human.CharacterHealth.Vitality
end)
add(.5,'block actual muzzle with ally',function() R.blockShots=s().shots or 0;return 'native ally in muzzle ray' end)
add(1,'ally in muzzle ray stops firing',function()
    assert((s().shots or 0)==R.blockShots,'shot through ally')
    R.positionCombat=false;G.setMode(suit,'off',c)
    return 'shots unchanged='..R.blockShots
end)
local function advance()
    R.index=R.index+1;local t=R.steps[R.index]
    if t then R.at=G.now+t.delay;return end
    G.setMode(suit,'off',c);R.move=false;R.positionCombat=false
    Hook.Remove('think',P)
    for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.RemovePatch(P..e[1],'Barotrauma.Character',e[1],e[2]) end
    for _,e in ipairs({{'.cursor','Barotrauma.Character','UpdateLocalCursor'},{'.hands','Barotrauma.AnimController','UpdateUseItem'},{'.camera','Barotrauma.GameScreen','Draw'}}) do Hook.RemovePatch(P..e[1],e[2],e[3],Hook.HookMethodType.Before) end
    log('RESULT passed='..R.passed..' failed='..R.failed..' native=true')
end
Hook.Add('think',P,function()
    if R.observe then
        -- Old underwater electrical test devices take native water damage;
        -- keep them out of this single-target tracking measurement.
        for _,item in ipairs(R.otherDevices) do if not item.Removed then item.Condition=item.MaxCondition end end
        -- Counter passive sinking to isolate small translation and real native
        -- facing/torso turns from leaving the repair operating radius.
        c.TeleportTo(origin+Vector2(math.sin((G.now-R.turn)*3)*3,0))
        R.samples=R.samples+1
        if s().target and s().target.entity==R.device then R.track=R.track+1 end
        if s().active then R.work=R.work+1 end
        local pose=G.toolPose(c,s());if R.angle then R.maxStep=math.max(R.maxStep,math.abs(M.delta(pose.angle,R.angle))) end;R.angle=pose.angle
        if R.condition then R.gain=(R.gain or 0)+math.max(0,R.device.Condition-R.condition) end
        if R.device.Condition>70 then R.device.Condition=5 end;R.condition=R.device.Condition
    end
    if R.positionCombat and R.enemy then
        R.enemy.TeleportTo(c.WorldPosition+Vector2(600,0))
        local from=R.block and G.toolPose(c,s()).muzzle or G.mount(c)
        local target=R.enemy.WorldPosition;local fraction=R.block and .18 or .13
        local point=Vector2(from.x+(target.X-from.x)*fraction,from.y+(target.Y-from.y)*fraction)
        local torso=B.human.AnimController.GetLimb(LimbType.Torso)
        B.human.TeleportTo(B.human.WorldPosition+point-torso.WorldPosition)
    end
    if G.now<R.at then return end
    local t=R.steps[R.index];local ok,result=pcall(t.fn)
    if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end
    log((ok and 'PASS ' or 'FAIL ')..t.name..' '..tostring(result));advance()
end)
advance()
