-- Isolated singleplayer acceptance probe; never package.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local G=assert(BMTDescendantSuit)
local C=require('DescendantSuit.config')
local c=assert(Character.Controlled)
local R={rows={},steps={},index=0,passed=0,failed=0,repairs=0,origins=0,useCalls=0,maxJointStep=0};ServoMotion=R
local P='bmt.servo.motion.probe'
local abilities=LuaUserData.CreateEnumTable('Barotrauma.AbilityEffectType')
LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
local function click(button) assert(button.OnClicked.Invoke(button,nil)) end
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO MOTION] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-motion-client.txt',table.concat(R.rows,'\n'))
end
local function capture(name)
    File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request',
        'F:/_Github/Barotrauma-Multi-Tool/.runtime/servo-motion-'..name..'.png')
end
local function state() return G.state(assert(R.suit)) end
local function spawn(id,p) return Item(ItemPrefab.Prefabs[id],p,c.Submarine) end
local function add(delay,name,fn) R.steps[#R.steps+1]={delay=delay,name=name,fn=fn} end
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
    h.WaterVolume=0;h.Oxygen=10000000
end
local rect=room.WorldRect
for item in Item.ItemList do
    if item.GetComponentString('Repairable') then item.Condition=item.MaxCondition end
end
for wall in Structure.WallList do
    if wall.Submarine==Submarine.MainSub and wall.HasBody and not wall.Indestructible then
        for i=0,wall.SectionCount-1 do if wall.SectionDamage(i)>0 then wall.AddDamage(i,-100000,c,false,false) end end
    end
end
R.home=Vector2(rect.X+rect.Width*.35,rect.Y-rect.Height+70)
c.TeleportTo(R.home);c.SetAllDamage(0,0,0)
for other in Character.CharacterList do
    if other~=c and other.Submarine==Submarine.MainSub then Entity.Spawner.AddEntityToRemoveQueue(other) end
end
local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
for _,item in ipairs(old) do
    if item.Prefab.Identifier.Value~='idcard' then item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end
end
R.suit=spawn('descendantservosuit',c.Position)
assert(c.Inventory.TryPutItem(R.suit,c,{InvSlotType.OuterClothes}))
R.cell=spawn('batterycell',c.Position);R.box=spawn('pulselaserammobox',c.Position)
assert(G.container(R.suit,1).TryPutItem(R.cell,0,false,false,c))
assert(G.container(R.suit,1).TryPutItem(R.box,1,false,false,c))
Entity.Spawner.AddCharacterToSpawnQueue('human',c.WorldPosition+Vector2(130,20),function(h)
    h.TeamID=c.TeamID;h.AIController.Enabled=false;R.human=h
end)
local update=G.update
local Motion=require('DescendantSuit.motion')
Hook.Patch(P..'.hands','Barotrauma.AnimController','UpdateUseItem',function(anim,p)
    if anim==c.AnimController and R.suit and state().mode=='repair' then R.useCalls=R.useCalls+1 end
end,Hook.HookMethodType.Before)
local releaseGrip=G.releaseGrip
G.releaseGrip=function(s)
    if s.grip then
        local t=s.target
        log('TRACE release mode='..s.mode..' target='..tostring(t and t.id)..' visible='..tostring(t and t.visible)..' distance='..tostring(t and t.distance)..' unconscious='..tostring(c.IsUnconscious)..' energy='..G.energy(R.suit))
    end
    return releaseGrip(s)
end
local repairDevice=G.repairDevice
G.repairDevice=function(owner,item,t,dt)
    local result=repairDevice(owner,item,t,dt)
    if t.entity==R.device then R.peakCondition=math.max(R.peakCondition or 0,R.device.Condition) end
    return result
end
local hold=G.hold
G.hold=function(owner,item,t,dt)
    local result=hold(owner,item,t,dt)
    local lease=G.state(item).grip
    if R.ceilingStart and lease and lease.recovering then R.recovered=(R.recovered or 0)+1;R.lowered=math.min(R.lowered or 999,lease.offset.y) end
    return result
end
local advanceTool=G.advanceTool
G.advanceTool=function(owner,s,dt)
    local previous=s.toolAngles
    advanceTool(owner,s,dt)
    if owner==c and previous then
        local change=math.abs(Motion.delta(s.toolAngles.upper,previous.upper))
        R.maxJointStep=math.max(R.maxJointStep,change)
        assert(change<=C.jointSpeed*math.min(dt,.1)+.00001,'native joint snapped')
    end
end
local function inputs()
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Shoot}) do c.SetInput(key,false,false) end
    local elapsed=R.start and G.now-R.start or 100
    local held=R.target~=nil and elapsed>.45 and elapsed<.65
    local aim=R.target~=nil and elapsed<.9
    if R.release then local t=G.now-R.release;aim=t<.5;held=t>.15 and t<.35 end
    c.SetInput(InputType.Aim,false,aim);c.SetInput(InputType.Use,held and not R.held,held);R.held=held
    local point=R.target and R.target.WorldPosition or R.lookAt or c.WorldPosition+Vector2(500,50)
    c.CursorPosition=c.Position+point-c.WorldPosition
end
G.update=function(dt) inputs();return update(dt) end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(character,p)
    if character~=c then return end
    p.PreventExecution=true;inputs()
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam;cam.Zoom=1.6
    cam.Position=c.WorldPosition+Vector2(50,45);cam.TargetPos=cam.Position;cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.rewards','Barotrauma.Character','CheckTalents',{'Barotrauma.AbilityEffectType','Barotrauma.Abilities.AbilityObject'},function(character,p)
    if character==c and p['abilityEffectType']==abilities.OnRepairComplete then R.repairs=R.repairs+1 end
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.muzzle','Barotrauma.Items.Components.Projectile','Shoot',function(projectile,p)
    if projectile.Item.Prefab.Identifier.Value~='descendantpulsebolt' then return end
    local muzzle=G.toolPose(c,state()).muzzle
    local point=ConvertUnits.ToDisplayUnits(p['spawnPos'])
    if projectile.Item.Submarine then point=point+projectile.Item.Submarine.Position end
    local error=(point-Vector2(muzzle.x,muzzle.y)).Length()
    R.originError=math.max(R.originError or 0,error);R.origins=R.origins+1
end,Hook.HookMethodType.Before)
add(.8,'native equipment and folded item metadata',function()
    assert(G.equipped(c)==R.suit and R.human)
    assert(R.suit.Scale==R.suit.Scale and math.abs(R.suit.Scale-.06)<1e-5)
    assert(R.suit.GetComponentString('Sonar'))
    return 'pressure=10000 scale='..R.suit.Scale..' repairBonus='..R.suit.Prefab.AddedRepairSpeedMultiplier
end)
add(.2,'start latched human grip',function()
    assert(G.setMode(R.suit,'grab',c));R.target=R.human;R.start=G.now
    return 'single Aim+Use press scheduled'
end)
add(1.3,'native human ragdoll acquired with released keys',function()
    local s=state()
    assert(s.grip and s.target.entity==R.human and s.active)
    assert(R.human.IsForceRagdolled and R.human.IsRagdolled)
    assert(not c.IsKeyDown(InputType.Use) and not c.IsKeyDown(InputType.Aim))
    return 'mass='..R.human.Mass..' forced=true keys=false'
end)
add(.5,'right menu collapses without releasing grip',function()
    click(G.panelHideButton);G.updateSuitUI(1/60)
    assert(not G.panel.Visible and G.panelShowButton.Visible and state().grip)
    return 'mode='..state().mode
end)
add(.2,'enable optional left native sonar',function()
    click(G.sonarShowButton);click(G.sonarPowerButton);R.sonarPower=R.cell.Condition
    return 'requested='..tostring(state().sonar)
end)
add(2.5,'left sonar draws real native HUD while arm stays latched',function()
    local sonar=R.suit.GetComponentString('Sonar')
    assert(state().sonar and sonar.IsActive and sonar.HasPower and sonar.Voltage>.5)
    assert(G.sonarPanel.Visible and G.sonarView.Rect.Width>100 and state().grip)
    assert(R.cell.Condition<R.sonarPower and not G.drawError)
    capture('sonar');return 'voltage='..sonar.Voltage..' viewWidth='..G.sonarView.Rect.Width
end)
add(.3,'left sonar panel collapses independently',function()
    click(G.sonarHideButton);G.updateSuitUI(1/60)
    assert(not G.sonarPanel.Visible and G.sonarShowButton.Visible and not G.panel.Visible)
    assert(state().sonar and state().mode=='grab' and state().grip)
    return 'both panels collapsed; sonar stays powered'
end)
add(2,'human stays airborne beyond old 5-second limit',function()
    local s=state();assert(s.grip and s.target.entity==R.human and R.human.IsForceRagdolled)
    local goal=c.WorldPosition+Vector2(s.grip.offset.x,s.grip.offset.y)
    local error=(goal-R.human.WorldPosition).Length()
    assert(error<35,'hold error='..error)
    assert(R.human.WorldPosition.Y>c.WorldPosition.Y+20,'held person fell to floor')
    assert(G.now-R.start>5 and not c.IsKeyDown(InputType.Use))
    capture('hold');return 'duration='..(G.now-R.start)..' anchorError='..error..' lift='..(R.human.WorldPosition.Y-c.WorldPosition.Y)
end)
add(.2,'move latched body under a real low ceiling',function()
    local p=c.WorldPosition
    local ceiling=assert(G.cast({x=p.X,y=p.Y},{x=p.X,y=p.Y+1200},0,c,true),'no native ceiling')
    R.ceilingY=ceiling.y
    local next=Vector2(p.X,ceiling.y-72);local delta=next-p
    R.human.TeleportTo(R.human.WorldPosition+delta);c.TeleportTo(next);R.ceilingStart=G.now
    return 'ceiling='..R.ceilingY..' owner='..c.WorldPosition.Y
end)
add(1.2,'native wall probes lower hold anchor without dropping body',function()
    local lease=assert(state().grip,'ceiling contact dropped grip')
    assert((R.recovered or 0)>0,'native ceiling probe did not detect obstruction')
    assert(R.lowered<lease.originalOffset.y-5,'anchor did not adjust')
    assert(R.human.IsForceRagdolled and R.maxJointStep>0)
    capture('ceiling')
    return 'originalY='..lease.originalOffset.y..' minimumY='..R.lowered..' recoverySamples='..R.recovered..' adjustedY='..lease.offset.y..' maxJointStep='..R.maxJointStep
end)
add(.1,'return wearer and body to the open room',function()
    local delta=R.home-c.WorldPosition;R.human.TeleportTo(R.human.WorldPosition+delta);c.TeleportTo(R.home)
    return 'home restored independently of ceiling assertion'
end)
add(1,'request release with second press',function() R.release=G.now;return 'second Aim+Use scheduled' end)
add(.8,'second press releases native ragdoll',function()
    assert(not state().grip and not state().target and not R.human.IsForceRagdolled)
    R.target=nil;R.release=nil;click(G.sonarPowerButton);click(G.panelShowButton)
    for item in Item.ItemList do
        if item.GetComponentString('Repairable') and (item.WorldPosition-c.WorldPosition).Length()<450 then Entity.Spawner.AddEntityToRemoveQueue(item) end
    end
    R.device=spawn('junctionbox',c.Position+Vector2(175,30));R.device.Condition=5
    c.Info.SetSkillLevel('electrical',20);R.skill=c.GetSkillLevel('electrical')
    assert(G.setMode(R.suit,'repair',c));return 'released=true; repair skill='..R.skill
end)
add(1.6,'native repair starts from wider nozzle beam',function()
    local s=state();local t=s.target
    local p=G.toolPose(c,s)
    log('TRACE repair condition='..R.device.Condition..' target='..tostring(t and t.entity)..' device='..tostring(R.device)..' distance='..tostring(t and t.distance)..' ready='..tostring(t and G.armReady(c,s,t))..' useCalls='..R.useCalls)
    assert(R.device.Condition>5 and t and t.entity==R.device)
    R.condition=R.device.Condition;c.TeleportTo(c.WorldPosition+Vector2(-25,0))
    capture('repair');return 'condition='..R.condition..' moved wearer 25 units'
end)
add(.45,'repair keeps contact across a small range movement',function()
    assert(R.device.Condition>R.condition)
    assert(R.device.Condition>=R.device.MaxCondition-.1 or (state().target and state().target.entity==R.device))
    return 'condition='..R.device.Condition..' completionEvents='..R.repairs
end)
add(4,'native faster completion retains skill reward',function()
    assert((R.peakCondition or 0)>=R.device.MaxCondition-.01,'never fully repaired: '..tostring(R.peakCondition))
    assert(c.GetSkillLevel('electrical')>R.skill and R.repairs==1,'native reward not preserved')
    assert(R.useCalls==0,'servo repair called wearer UpdateUseItem '..R.useCalls..' times')
    R.dropped=spawn('descendantservosuit',c.Position+Vector2(-110,-20))
    return 'peakCondition='..R.peakCondition..' currentCondition='..R.device.Condition..' skill='..c.GetSkillLevel('electrical')..' completions='..R.repairs
end)
add(.8,'dropped suit uses folded ground sprite',function()
    assert(R.dropped.Sprite.SourceRect.Width==1428 and R.dropped.Sprite.SourceRect.Height==586)
    capture('ground');return 'displayWidth='..(R.dropped.Sprite.SourceRect.Width*R.dropped.Scale)
end)
add(.2,'prepare native pulse in water',function()
    G.setMode(R.suit,'off',c)
    local water=Submarine.MainSub.WorldPosition+Vector2(3500,-400)
    c.TeleportTo(water);c.SetAllDamage(0,0,0);R.ammo=R.box.Condition
    Entity.Spawner.AddCharacterToSpawnQueue('crawler',water+Vector2(-650,20),function(enemy)
        enemy.AIController.Enabled=false;R.enemy=enemy;R.lookAt=enemy.WorldPosition
        G.setMode(R.suit,'combat',c);R.capturePulse=true
    end)
    return 'outside submarine'
end)
add(2,'native pulse starts at common tool muzzle',function()
    assert(state().shots and state().shots>0 and R.box.Condition<R.ammo)
    assert(R.origins>0 and R.originError<.1,'origin error='..tostring(R.originError))
    assert(state().lastPulse and not G.drawError)
    return 'shots='..state().shots..' nativeOriginError='..R.originError
end)
local function advance()
    R.index=R.index+1
    local step=R.steps[R.index]
    if not step then
        G.setMode(R.suit,'off',c);G.update=update;G.advanceTool=advanceTool;G.releaseGrip=releaseGrip;G.hold=hold;G.repairDevice=repairDevice
        Hook.RemovePatch(P..'.hands','Barotrauma.AnimController','UpdateUseItem',Hook.HookMethodType.Before)
        Hook.Remove('think',P)
        for _,entry in ipairs({{'cursor','Barotrauma.Character','UpdateLocalCursor'},
            {'camera','Barotrauma.GameScreen','Draw'},{'muzzle','Barotrauma.Items.Components.Projectile','Shoot'}}) do
            Hook.RemovePatch(P..'.'..entry[1],entry[2],entry[3],Hook.HookMethodType.Before)
        end
        Hook.RemovePatch(P..'.rewards','Barotrauma.Character','CheckTalents',
            {'Barotrauma.AbilityEffectType','Barotrauma.Abilities.AbilityObject'},Hook.HookMethodType.Before)
        log('RESULT passed='..R.passed..' failed='..R.failed..' native=true')
        return
    end
    R.at=G.now+step.delay
end
Hook.Add('think',P,function()
    if R.capturePulse and state().shots and state().shots>0 then capture('pulse');R.capturePulse=false end
    if not R.at or G.now<R.at then return end
    local step=R.steps[R.index];local ok,detail=pcall(step.fn)
    if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end
    log((ok and 'PASS ' or 'FAIL ')..step.name..' '..tostring(detail))
    advance()
end)
advance()
