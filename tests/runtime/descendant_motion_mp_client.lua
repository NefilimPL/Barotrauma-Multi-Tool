-- Real joined client acceptance probe. Never package.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=BMTDescendantSuit
local P='bmt.servo.motion.mp'
local R={rows={},phase=0,useCalls=0,forced=0,moving=0,manualCrouch=0,jointSamples=0};ServoMotionMPClient=R
LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
local function click(b) assert(b.OnClicked.Invoke(b,nil)) end
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO MOTION MP CLIENT] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-motion-mp-client.txt',table.concat(R.rows,'\n'))
end
local function entity(key) return Entity.FindEntityByID(R[key] or 0) end
Hook.Patch(P..'.hands','Barotrauma.AnimController','UpdateUseItem',function(anim,p)
    if R.phase==6 and Character.Controlled and anim==Character.Controlled.AnimController then R.useCalls=R.useCalls+1 end
end,Hook.HookMethodType.Before)
local function inputs(c)
    if c~=Character.Controlled then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Crouch,InputType.Shoot}) do c.SetInput(key,false,false) end
    if R.phase==6 and R.repairAt then
        local t=G.now-R.repairAt
        c.SetInput(InputType.Right,false,t>.8 and t<1.3)
        c.SetInput(InputType.Crouch,false,t>1.8 and t<2.3)
    end
    local elapsed=R.pressAt and G.now-R.pressAt or 100
    local aim=R.pressing==true and elapsed<1.2
    local held=aim and elapsed>.45 and elapsed<.75
    c.SetInput(InputType.Aim,false,aim);c.SetInput(InputType.Use,held and not R.held,held);R.held=held
    local human=entity('human')
    local point=R.pressing and human and human.WorldPosition or c.WorldPosition+Vector2(500,50)
    c.CursorPosition=c.Position+point-c.WorldPosition
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
    Hook.Patch(P..'.input.'..entry[1],'Barotrauma.Character',entry[1],inputs,entry[2])
end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(c,p)
    if c==Character.Controlled then p.PreventExecution=true;inputs(c) end
end,Hook.HookMethodType.Before)
local function start(n,suit)
    R.started=true
    if n==2 or n==8 then R.pressing=true;R.pressAt=G.now;R.held=false;G.requestMode(suit,'grab')
    elseif n==3 then
        click(G.panelHideButton);click(G.sonarShowButton);click(G.sonarPowerButton)
    elseif n==4 then click(G.sonarPassiveButton);click(G.sonarHideButton)
    elseif n==5 then R.pressing=true;R.pressAt=G.now;R.held=false
    elseif n==6 then
        R.repairAt=G.now;R.pressing=false;click(G.sonarPowerButton);click(G.panelShowButton);G.requestMode(suit,'repair')
    elseif n==7 then R.pressing=false;G.requestMode(suit,'combat') end
    local delays={[1]=1,[2]=7,[3]=2.5,[4]=1.5,[5]=1.5,[6]=6,[7]=2.5,[8]=2,[9]=1}
    R.checkAt=G.now+delays[n]
end
local function verify(n,suit)
    local s=assert(G.states[suit]);assert(s.received and G.now-s.received<.6,'stale v4 snapshot')
    if n==1 then assert(G.source(suit) and G.ammo(suit));return 'native slots + snapshot'
    elseif n==2 then
        local h=entity('human');assert(s.target and s.target.entity==h and s.active and h.IsRagdolled)
        assert(not Character.Controlled.IsKeyDown(InputType.Use));return 'live ragdoll visible, keys released'
    elseif n==3 then
        assert(s.sonar and G.sonarPanel.Visible and not G.panel.Visible and G.panelShowButton.Visible)
        assert(suit.GetComponentString('Sonar').HasPower and G.sonarView.Rect.Width>100)
        File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/servo-motion-mp-sonar.png')
        return 'native left sonar and collapsed right UI'
    elseif n==4 then
        assert(s.sonar and s.sonarActive==false and not G.sonarPanel.Visible and G.sonarShowButton.Visible)
        return 'passive + both panels collapsed'
    elseif n==5 then assert(not s.target and not entity('human').IsRagdolled);return 'released snapshot + ragdoll'
    elseif n==6 then
        assert(entity('device').Condition>95 and s.mode=='repair')
        assert(R.inspected,'automatic repair UI inspection was not exercised')
        assert(R.useCalls==0 and R.forced==0,'servo forced wearer animation')
        assert(R.moving>0,'manual movement did not reach animation')
        assert(R.manualCrouch>0,'manual crouch input was blocked')
        assert(R.jointSamples>20 and s.toolAngles and s.drawAngles,'joint replication missing')
        return 'repair complete; useCalls='..R.useCalls..' forced='..R.forced..' movementSamples='..R.moving..' manualCrouchSamples='..R.manualCrouch..' jointSamples='..R.jointSamples
    elseif n==7 then assert(s.shots and s.shots>0 and s.lastPulse and not G.drawError);return 'pulse endpoint replicated; origin rendered'
    elseif n==8 then assert(s.target and s.target.entity==entity('human') and s.active);return 'second latch acquired'
    elseif n==9 then assert(not s.target and not entity('human').IsRagdolled and s.charge<=0);return 'empty battery release replicated' end
end
Networking.Receive(P..'.phase',function(m)
    R.phase=m.ReadByte();R.started=false;R.readyAt=G.now;R.checkAt=nil
    for _,key in ipairs({'suit','cell','box','human','device'}) do R[key]=m.ReadUInt16() end
end)
Hook.Add('think',P,function()
    if R.phase==0 then return end
    local suit=entity('suit')
    if not R.started then
        if suit and G.equipped(Character.Controlled)==suit and entity('human') and
            (R.phase~=6 or entity('device')) then start(R.phase,suit) end
        return
    end
    if R.phase==6 and Character.Controlled then
        local c=Character.Controlled;local anim=c.AnimController
        if tostring(anim.ForceSelectAnimationType):find('Crouch') then R.forced=R.forced+1 end
        if c.IsKeyDown(InputType.Right) and anim.TargetMovement.X>.1 then R.moving=R.moving+1 end
        if c.IsKeyDown(InputType.Crouch) and anim.Crouching then R.manualCrouch=R.manualCrouch+1 end
        local s=G.states[suit]
        if s and s.repairing==entity('device') and not R.inspected then c.SelectedItem=entity('device');R.inspected=true end
        if s and s.toolAngles and s.drawAngles then R.jointSamples=R.jointSamples+1 end
    end
    if G.now<R.checkAt then return end
    local n=R.phase;R.phase=0
    local ok,detail=pcall(verify,n,suit)
    log((ok and 'PASS ' or 'FAIL ')..n..' '..tostring(detail))
    local reply=Networking.Start(P..'.report');reply.WriteByte(n);reply.WriteBoolean(ok);reply.WriteString(tostring(detail));Networking.Send(reply)
end)
Networking.Receive(P..'.done',function()
    R.pressing=false;Hook.RemovePatch(P..'.hands','Barotrauma.AnimController','UpdateUseItem',Hook.HookMethodType.Before);Hook.Remove('think',P)
    for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
        Hook.RemovePatch(P..'.input.'..entry[1],'Barotrauma.Character',entry[1],entry[2])
    end
    Hook.RemovePatch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',Hook.HookMethodType.Before)
    log('DONE real joined client')
end)
local hello=Networking.Start(P..'.hello');Networking.Send(hello)
log('HELLO real joined client')
