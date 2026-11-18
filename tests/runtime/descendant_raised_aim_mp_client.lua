-- Real joined native client; evaluates replicated pose rather than local planning.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=BMTDescendantSuit;local P='bmt.raised.aim.mp';local Motion=require('DescendantSuit.motion')
local R={rows={},phase=0,frames=0};ServoRaisedAimMPClient=R
local function log(s) R.rows[#R.rows+1]=s;print('[RAISED MP CLIENT] '..s);File.Write('LocalMods/MULTI-TOOL-V2/raised-aim-mp-client.txt',table.concat(R.rows,'\n')) end
local function entity(key) return Entity.FindEntityByID(R[key] or 0) end
local function inputs(c)
    if c~=Character.Controlled then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Aim,InputType.Use,InputType.Shoot,InputType.Crouch}) do c.SetInput(key,false,false) end
    c.CursorPosition=c.Position+Vector2(800,0)
end
for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do Hook.Patch(P..e[1],'Barotrauma.Character',e[1],inputs,e[2]) end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(c,p) if c==Character.Controlled then p.PreventExecution=true;inputs(c) end end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    if Character.Controlled then local cam=Game.GameScreen.Cam;cam.Zoom=1.3;cam.Position=Character.Controlled.WorldPosition+Vector2(250,50);cam.TargetPos=cam.Position;cam.UpdateTransform(false,true) end
end,Hook.HookMethodType.Before)
Networking.Receive(P..'.phase',function(m)
    R.phase=m.ReadByte();R.started=false;R.checkAt=nil
    for _,k in ipairs({'suit','ally','enemy'}) do R[k]=m.ReadUInt16() end
end)
Hook.Add('think',P,function()
    if R.phase==0 then return end
    local suit=entity('suit');local c=Character.Controlled
    if not R.started then
        if not suit or not c or G.equipped(c)~=suit or not entity('ally') or not entity('enemy') then return end
        R.started=true;R.before=G.states[suit] and G.states[suit].shots or 0;R.checkAt=G.now+3
        G.requestMode(suit,'combat');return
    end
    R.frames=R.frames+1
    if G.now<R.checkAt then return end
    local n=R.phase;R.phase=0
    local ok,result=pcall(function()
        local s=assert(G.states[suit]);assert(not G.authoritative and s.received and G.now-s.received<.6,'stale or local-authority state')
        assert(s.shots>R.before and s.target and s.target.entity==entity('enemy'),'pulse/target not replicated')
        assert(not c.AnimController.InWater and not G.drawError,'water or drawing failure')
        local p=G.toolPose(c,s,true);local head=entity('ally').AnimController.GetLimb(LimbType.Head)
        if n==2 or n==4 then
            assert(p.muzzle.y>head.WorldPosition.Y,'replicated nozzle is below ally head')
            assert(s.drawAngles and math.abs(Motion.delta(s.drawAngles.upper,s.toolAngles.upper))<.2,'replicated arm did not settle')
            File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/raised-aim-mp-over-ally.png')
        end
        return 'native snapshot shots='..s.shots..' muzzleLift='..(p.muzzle.y-G.mount(c).y)..' frames='..R.frames
    end)
    log((ok and 'PASS ' or 'FAIL ')..n..' '..tostring(result))
    local reply=Networking.Start(P..'.report');reply.WriteByte(n);reply.WriteBoolean(ok);reply.WriteString(tostring(result));Networking.Send(reply)
end)
Networking.Receive(P..'.done',function()
    Hook.Remove('think',P)
    for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do Hook.RemovePatch(P..e[1],'Barotrauma.Character',e[1],e[2]) end
    Hook.RemovePatch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',Hook.HookMethodType.Before)
    Hook.RemovePatch(P..'.camera','Barotrauma.GameScreen','Draw',Hook.HookMethodType.Before)
    log('DONE real joined client')
end)
local hello=Networking.Start(P..'.hello');Networking.Send(hello);log('HELLO real joined client')
