-- TEST ONLY: real remote client input and camera; never package this file.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local P='aegis.performance.v1'
local Proof=dofile('LocalMods/System-Aegis/Lua/Tests/performance/proof.lua')
local R={mode='idle',phase='',home=nil};AegisPerformanceClient=R
local function resetReplicas(mode)
    local medical=mode=='heal' or mode=='hit' or mode=='pressure'
    local function reset(c)
        if c.Removed then return end
        local headset=medical and c.Inventory and c.Inventory.GetItemInLimbSlot(InvSlotType.Headset)
        local id=headset and tostring(headset.Prefab.Identifier.Value):lower()
        c.GodMode=true;Proof.resetHealth(c)
        c.GodMode=not (medical and (id=='aegisheadset' or id=='aegisheadsetmk2'))
    end
    local list=Character.CharacterList
    if type(list)=='table' then for _,c in ipairs(list) do reset(c) end
    elseif list then for c in list do reset(c) end
    elseif Character.Controlled then reset(Character.Controlled) end
end
Networking.Receive(P..'.prepare',function(m)
    local prep={token=m.ReadString(),panel=m.ReadBoolean(),rows={}}
    local count=m.ReadByte()
    for i=1,count do prep.rows[i]={item=m.ReadUInt16(),pack=m.ReadUInt16(),count=m.ReadUInt16(),cell=m.ReadUInt16()} end
    if R.phase==prep.token then return end
    if R.preparedToken==prep.token and (not prep.panel or (R.panelFrame and R.panelFrame.Visible)) then
        local ack=Networking.Start(P..'.prepared');ack.WriteString(prep.token);Networking.Send(ack);return
    end
    -- Reliable retransmission must preserve progress while a snapshot is in flight.
    if not R.preparing or R.preparing.token~=prep.token then resetReplicas();R.preparing=prep end
end)
local function evidence()
    if R.phase=='' or R.phase=='done' then return end
    local c=Character.Controlled
    local path='LocalMods/System-Aegis/aegis-perf-client-evidence.jsonl'
    local old=File.Exists(path) and File.Read(path) or ''
    File.Write(path,old..string.format('{"phase":"%s","controlled":%s,"samples":%d,"equipped_samples":%d,"panel_snapshots":%d,"sonar_visible":%d,"draw_error":%s,"can_interact_samples":%d}\n',
        R.phase,tostring(c and c.ID or 0),R.samples or 0,R.equipped or 0,R.snapshots or 0,R.sonarVisible or 0,
        tostring(AegisSuit~=nil and AegisSuit.drawError~=nil),R.canInteract or 0))
end
if AegisVacuum then
local oldClose=AegisVacuum.closePanel
AegisVacuum.closePanel=function(...)
    if R.panelFrame then
        local c=Character.Controlled
        print('[PERF PANEL CLOSE] phase='..R.phase..' mode='..R.mode..' allow='..tostring(c and c.AllowInput)..
            ' oxygen='..tostring(c and c.Oxygen)..' stun='..tostring(c and c.Stun)..
            ' lock='..tostring(c and c.LockHands)..' '..(debug and debug.traceback and debug.traceback() or ''))
    end
    oldClose(...)
    R.panelFrame=nil;R.panelDevice=nil;R.panelPack=nil;R.panelExpected=nil;R.panelPreparedFor=nil
    if R.preparing then R.preparing.opened=nil;R.preparing.snapshot=nil end
end
local oldSnapshot=AegisVacuum.onSnapshot
AegisVacuum.onSnapshot=function(s)
    oldSnapshot(s)
    -- Match the actual initial UI view, then check the retained visible frame.
    -- A reply rejected by production, an empty payload or a closed UI is no proof.
    local valid=R.panelFrame and R.panelFrame.Visible and s.vacuum==R.panelDevice and s.pack==R.panelPack and
        s.count==R.panelExpected and s.count>0 and s.rows and #s.rows>0 and (s.groups or 0)>0 and
        s.filters==false and s.category=='all' and s.search=='' and s.group==0 and s.page==0
    if valid and R.preparing and R.preparing.panel and s.pack==R.preparing.ownPack then R.preparing.snapshot=true end
    if valid and R.mode=='panel' and Timer.GetTime()-(R.started or 0)>=5 then R.snapshots=(R.snapshots or 0)+1 end
end
end
Networking.Receive(P..'.phase',function(m)
    local previous=R.phase
    local nextPhase=m.ReadString()
    -- Native File.WriteAllText instrumentation captures the exact local QPC.
    File.Write('LocalMods/System-Aegis/aegis-perf-phase.txt',nextPhase)
    evidence()
    R.phase=nextPhase;R.mode=m.ReadString();R.item=m.ReadUInt16();R.pack=m.ReadUInt16()
    resetReplicas(R.mode)
    if previous~='' and previous~='done' and previous~=nextPhase then R.stoppedPhase=previous end
    R.home=Vector2(m.ReadSingle(),m.ReadSingle());R.active=m.ReadBoolean();R.hidden=m.ReadBoolean()
    R.zoom=m.ReadSingle()
    R.aim=Vector2(m.ReadSingle(),m.ReadSingle());R.started=Timer.GetTime()
    R.wallAnchored=R.mode=='weld' or R.mode=='cut'
    R.localAim=R.wallAnchored and R.aim-R.home or nil
    local keep=R.mode=='panel' and R.pack==R.panelPack and R.panelFrame and R.panelFrame.Visible
    R.requested=keep or false;R.held=false;R.panelDebug=false;R.panelPreparedFor=nil
    if not keep then R.panelFrame=nil end
    R.samples=0;R.equipped=0;R.snapshots=0;R.sonarVisible=0
    R.canInteract=0
end)
local function inputs(c)
    if c~=Character.Controlled or not R.home then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Crouch,InputType.Run}) do c.SetInput(key,false,false) end
    local working=R.active and (R.mode=='fire' or R.mode=='vacuum' or R.mode=='weld' or R.mode=='cut' or R.mode=='extinguish' or R.mode=='light' or R.mode=='shield')
    c.SetInput(InputType.Aim,false,working)
    c.SetInput(InputType.Shoot,false,working and R.mode~='light' and R.mode~='shield')
    c.SetInput(InputType.Use,false,false)
    if R.active and R.mode=='grab' then
        local item=Entity.FindEntityByID(R.item)
        local state=item and AegisSuit.states[item]
        local acquire=not (state and state.target)
        local cycle=(Timer.GetTime()-R.started)%2
        local held=acquire and cycle>.3 and cycle<.6
        c.SetInput(InputType.Aim,false,acquire);c.SetInput(InputType.Use,held and not R.held,held);R.held=held
    end
    local target=R.wallAnchored and Submarine.MainSub and Submarine.MainSub.WorldPosition+R.localAim or
        R.aim or c.WorldPosition+Vector2(500,0)
    c.CursorPosition=c.Position+target-c.WorldPosition
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
    Hook.Patch(P..'.input.'..entry[1],'Barotrauma.Character',entry[1],inputs,entry[2])
end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(c,p)
    if c==Character.Controlled then p.PreventExecution=true;inputs(c) end
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    if not R.home then return end
    local cam=Game.GameScreen.Cam
    local anchor=R.wallAnchored and Submarine.MainSub and Submarine.MainSub.WorldPosition or R.home
    cam.Position=anchor+(R.hidden and Vector2(12000,0) or Vector2(0,0));cam.TargetPos=cam.Position;cam.Zoom=R.zoom or .75
    cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
Hook.Add('think',P,function()
    if R.stoppedPhase then
        local path='LocalMods/System-Aegis/aegis-perf-stopped.txt'
        if File.Exists(path) and File.Read(path)==R.stoppedPhase then
            local m=Networking.Start(P..'.stopped');m.WriteString(R.stoppedPhase);Networking.Send(m);R.stoppedPhase=nil
        end
    end
    if R.panelPreparedFor then return end -- retain the acknowledged UI until its phase packet
    if R.preparing then
        local panelPreparation=R.preparing.panel
        local ready=true
        for _,row in ipairs(R.preparing.rows) do
            local item=Entity.FindEntityByID(row.item)
            if not item or not item.ParentInventory then ready=false;break end
            if row.cell>0 and not Entity.FindEntityByID(row.cell) then ready=false;break end
            if row.pack>0 then
                local pack=Entity.FindEntityByID(row.pack)
                if not pack or not pack.ParentInventory or #AegisVacuum.contents(pack)~=row.count then ready=false;break end
                if R.preparing.panel and pack.ParentInventory.Owner==Character.Controlled then
                    R.preparing.ownPack=pack.ID;R.preparing.expected=row.count
                end
            end
        end
        if ready and R.preparing.panel and R.preparing.ownPack and not R.preparing.opened then
            local pack=Entity.FindEntityByID(R.preparing.ownPack)
            if AegisVacuum.context(pack,Character.Controlled).valid then
                R.panelFrame=AegisVacuum.openPanel(pack);R.preparing.opened=true
                R.panelDevice=pack.ID;R.panelPack=pack.ID;R.panelExpected=R.preparing.expected
            end
        end
        if ready and (not R.preparing.panel or not R.preparing.ownPack or R.preparing.snapshot) then
            local m=Networking.Start(P..'.prepared');m.WriteString(R.preparing.token);Networking.Send(m)
            R.preparedToken=R.preparing.token
            if R.preparing.panel and R.preparing.ownPack then R.panelPreparedFor=R.preparing.token end
            R.preparing=nil
        end
        if panelPreparation then return end
    end
    if R.started and Timer.GetTime()-R.started>=5 and R.phase~='done' then
        R.samples=R.samples+1
        if Character.Controlled and Character.Controlled.CanInteract~=false then R.canInteract=R.canInteract+1 end
        local item=Entity.FindEntityByID(R.item)
        if not R.active or (item and item.ParentInventory and item.ParentInventory.Owner==Character.Controlled) then R.equipped=R.equipped+1 end
        if R.mode=='sonar' then
            local sonar=item and item.GetComponentString('Sonar')
            local G=AegisSuit
            if sonar and sonar.HasPower and sonar.Voltage>.5 and G.sonarPanel and G.sonarPanel.Visible and G.sonarView and G.sonarView.Rect.Width>100 then
                R.sonarVisible=R.sonarVisible+1
            end
        end
        if R.mode=='panel' and R.active and not R.panelDebug then
            local pack=Entity.FindEntityByID(R.pack);local ctx=pack and AegisVacuum.context(pack,Character.Controlled)
            print('[PERF PANEL] valid='..tostring(ctx and ctx.valid)..' requested='..tostring(R.requested)..
                ' frame='..tostring(R.panelFrame and R.panelFrame.Visible)..' paused='..tostring(GUI.GUI.PauseMenuOpen)..
                ' canInteract='..tostring(Character.Controlled.CanInteract)..' oxygen='..tostring(Character.Controlled.Oxygen)..
                ' stun='..tostring(Character.Controlled.Stun)..' incapacitated='..tostring(Character.Controlled.IsIncapacitated)..
                ' lockHands='..tostring(Character.Controlled.LockHands))
            R.panelDebug=true
        end
    end
    if R.requested or not R.home then return end
    local item=Entity.FindEntityByID(R.item)
    if R.mode=='panel' then
        local pack=Entity.FindEntityByID(R.pack)
        if pack and AegisVacuum and AegisVacuum.context(pack,Character.Controlled).valid then R.panelFrame=AegisVacuum.openPanel(pack);R.requested=true end
    elseif R.mode=='sonar' then
        if item and AegisSuit then
            local s=AegisSuit.states[item]
            if s and s.sonar then R.requested=true
            elseif s then AegisSuit.requestMode(item,'sonar') end
        end
    else
        if AegisVacuum and AegisVacuum.closePanel then AegisVacuum.closePanel() end
        R.requested=true
    end
end)
local m=Networking.Start(P..'.ready');Networking.Send(m)
print('[Aegis PERFORMANCE] remote client ready')
