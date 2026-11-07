-- Real multiplayer client automation. Never ship in the production package.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=BMTCombat
local P={phase='waiting',events={},target=0,aim=false,shoot=false,inputs=0}
CombatSessionClient=P
local eventName='bmt.combat.session.phase'
local oldEffect=G.onEffect
LuaUserData.RegisterType('Barotrauma.GameMain')
local Main=LuaUserData.CreateStatic('Barotrauma.GameMain')
local function save()
    local rows={'phase='..P.phase,'controlled='..tostring(Character.Controlled and Character.Controlled.ID),
        'inputs='..P.inputs,'authority='..tostring(G.authoritative),'visualError='..tostring(G.visualError)}
    for key,value in pairs(P.events) do rows[#rows+1]=key..'='..value end
    File.Write('LocalMods/MULTI-TOOL-V2/combat-session-events-'..P.phase..'.txt',table.concat(rows,'\n'))
end
G.onEffect=function(kind,...)
    P.events[kind]=(P.events[kind] or 0)+1
    return oldEffect(kind,...)
end
Networking.Receive(eventName,function(m)
    local phase=m.ReadString()
    if phase~=P.phase then save();P.events={};P.inputs=0 end
    P.target=m.ReadUInt16();P.aim=m.ReadBoolean();P.shoot=m.ReadBoolean()
    P.x=m.ReadSingle();P.y=m.ReadSingle()
    if phase~=P.phase then
        P.phase=phase;File.Write('LocalMods/MULTI-TOOL-V2/combat-session-phase.txt',P.phase)
    end
    print('[COMBAT SESSION] '..P.phase..' character='..tostring(Character.Controlled and Character.Controlled.ID)..' target='..P.target)
end)
local function input(c)
    if c~=Character.Controlled or not P.x then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Use,InputType.Attack}) do c.SetInput(key,false,false) end
    local target=Entity.FindEntityByID(P.target)
    if target and not target.Removed then
        local point=target.AnimController and target.AnimController.MainLimb.WorldPosition or target.WorldPosition
        c.CursorPosition=c.Position+point-c.WorldPosition
    end
    c.SetInput(InputType.Aim,false,P.aim);c.SetInput(InputType.Shoot,false,P.shoot)
    P.inputs=P.inputs+1
end
Hook.Patch('bmt.session.input-net','Barotrauma.Character','UpdateNetInput',input,Hook.HookMethodType.Before)
Hook.Patch('bmt.session.input-local','Barotrauma.Character','ControlLocalPlayer',function(c) input(c) end,Hook.HookMethodType.After)
Hook.Patch('bmt.session.input-control','Barotrauma.Character','Control',input,Hook.HookMethodType.Before)
Hook.Add('think','bmt.session.camera',function()
    if not P.x then return end
    local cam=Main.GameScreen.Cam
    cam.Position=Vector2(P.x,P.y);cam.Zoom=.65
end)
local function ready()
    if P.phase~='waiting' then return end
    local m=Networking.Start('bmt.combat.session.ready');m.WriteString('ready');Networking.Send(m)
    Timer.Wait(ready,2000)
end
ready()
print('[COMBAT SESSION] Client ready; actual network authority='..tostring(G.authoritative))
