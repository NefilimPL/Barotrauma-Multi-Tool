-- Real joined client automation and validation; native C# hook measures frames.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=assert(AegisSuit);assert(not G.authoritative)
LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
local function now() return G.now end
local P='aegis.suit.performance'
local R={phase='waiting',rows={},snapshots=0,samples=0,total=0,active=0,states=0,sparks=0}
AegisPerfClient=R
local function save()
    if R.phase=='waiting' or R.phase=='done' then return end
    R.rows[#R.rows+1]=string.format('phase=%s authority=%s controlled=%s snapshots=%d samples=%d states_mean=%.3f active_mean=%.3f sparks_peak=%d drawError=%s',
        R.phase,tostring(G.authoritative),tostring(Character.Controlled and Character.Controlled.ID),R.snapshots,R.samples,R.states/math.max(1,R.samples),R.active/math.max(1,R.samples),R.sparks,tostring(G.drawError))
    File.Write('LocalMods/System-Aegis/aegis-perf-client.txt',table.concat(R.rows,'\n'))
end
Networking.Receive(P..'.phase',function(m)
    save();R.phase=m.ReadString();R.mode=m.ReadString();R.sonar=m.ReadBoolean()
    R.x,R.y=m.ReadSingle(),m.ReadSingle();R.suitId,R.grabId=m.ReadUInt16(),m.ReadUInt16()
    R.started=now();R.requested=false;R.snapshots=0;R.samples=0;R.total=0;R.active=0;R.states=0;R.sparks=0;R.received=nil
    File.Write('LocalMods/System-Aegis/aegis-perf-phase.txt',R.phase)
    print('[AEGIS PERF CLIENT] '..R.phase)
end)
local function inputs(c)
    if c~=Character.Controlled or not R.started then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Crouch,InputType.Shoot}) do c.SetInput(key,false,false) end
    local elapsed=now()-R.started
    local suit=Entity.FindEntityByID(R.suitId or 0)
    local s=suit and G.states[suit]
    -- Teleported targets can arrive after the first input packet. Retry only
    -- while unlatched; never send a release press once a target is replicated.
    local aim=R.mode=='grab' and elapsed>.5 and not (s and s.target)
    local cycle=elapsed%2
    local use=aim and cycle>1 and cycle<1.3
    c.SetInput(InputType.Aim,false,aim);c.SetInput(InputType.Use,use and not R.held,use);R.held=use
    local target=Entity.FindEntityByID(R.grabId or 0)
    local point=R.mode=='grab' and target and target.WorldPosition or c.WorldPosition+Vector2(500,50)
    c.CursorPosition=c.Position+point-c.WorldPosition
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
    Hook.Patch(P..'.input.'..entry[1],'Barotrauma.Character',entry[1],inputs,entry[2])
end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(c,p)
    if c==Character.Controlled then p.PreventExecution=true;inputs(c) end
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    if not R.x then return end
    local cam=Game.GameScreen.Cam;cam.Position=Vector2(R.x,R.y);cam.TargetPos=cam.Position;cam.Zoom=1
    cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
local update=G.updateClient
G.updateClient=function(dt)
    update(dt)
    if not R.started or now()-R.started<5 then return end
    R.samples=R.samples+1
    local suit=Entity.FindEntityByID(R.suitId or 0)
    local s=suit and G.states[suit]
    if s and s.received~=R.received then R.received=s.received;R.snapshots=R.snapshots+1 end
    local sparks=0
    for _,state in pairs(G.states) do
        R.states=R.states+1;if state.active then R.active=R.active+1 end
        sparks=sparks+#(state.sparks or {})
    end
    R.sparks=math.max(R.sparks,sparks)
end
Hook.Add('think',P,function()
    if not R.started or R.requested then return end
    local suit=Entity.FindEntityByID(R.suitId)
    if not suit or G.equipped(Character.Controlled)~=suit then return end
    local s=G.states[suit];if not s then return end
    G.requestMode(suit,R.mode)
    if (s.sonar==true)~=R.sonar then G.requestMode(suit,'sonar') end
    local button=R.sonar and G.sonarShowButton or G.sonarHideButton
    assert(button.OnClicked.Invoke(button,nil))
    R.requested=true
end)
local function ready()
    if R.phase~='waiting' then return end
    Networking.Send(Networking.Start(P..'.ready'));Timer.Wait(ready,1500)
end
ready();print('[AEGIS PERF CLIENT] Ready authority=false')
