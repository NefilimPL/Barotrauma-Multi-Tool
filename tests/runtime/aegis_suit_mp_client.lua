-- Real joined client only, isolated local sandbox. Never package.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=AegisSuit
assert(G and G.alive and not G.authoritative and Character.Controlled)
local P='aegis.servo.probe.v1'
local R={rows={},phase=0,move=false,grab=false,grabPressed=false}
local cam=Game.GameScreen.Cam
local oldZoom,oldLighting,oldLos=cam.Zoom,Game.LightManager.LightingEnabled,Game.LightManager.LosEnabled
cam.Zoom=1.8;Game.LightManager.LightingEnabled=false;Game.LightManager.LosEnabled=false
ServoMPClientProbe=R
local function save(line)
    R.rows[#R.rows+1]=line;print('[SERVO MP CLIENT] '..line)
    File.Write('LocalMods/System-Aegis/servo-mp-client-results.txt',table.concat(R.rows,'\n'))
end
local function report(phase,ok,detail)
    save((ok and 'PASS ' or 'FAIL ')..phase..' '..detail)
    local m=Networking.Start(P..'.report');m.WriteByte(phase);m.WriteBoolean(ok);m.WriteString(detail);Networking.Send(m)
end
local function entity(id) return Entity.FindEntityByID(id) end
local function inputs(c)
    if c~=Character.Controlled then return end
    c.SetInput(InputType.Left,false,false);c.SetInput(InputType.Right,false,R.move)
    c.SetInput(InputType.Up,false,false);c.SetInput(InputType.Down,false,false)
    c.SetInput(InputType.Shoot,false,false)
    local target=R.grab and entity(R.wrench)
    local pressed=false
    if target and R.suit and G.state(entity(R.suit)).mode=='grab' then
        if not R.grabStarted then R.grabStarted=G.now end
        local elapsed=G.now-R.grabStarted
        pressed=elapsed>=.5 and elapsed<.75
        c.CursorPosition=c.Position+target.WorldPosition-c.WorldPosition
    end
    c.SetInput(InputType.Aim,false,target~=nil)
    c.SetInput(InputType.Use,pressed and not R.grabPressed,pressed)
    R.grabPressed=pressed
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
    Hook.Patch('aegis.servo.mp.'..entry[1],'Barotrauma.Character',entry[1],inputs,entry[2])
end
Networking.Receive(P..'.phase',function(m)
    local phase=m.ReadByte();R.phase=phase
    if phase==0 then R.move=false;R.grab=false;return end
    if phase==1 then
        R.suit=m.ReadUInt16();R.cell=m.ReadUInt16();R.tank=m.ReadUInt16();R.device=m.ReadUInt16()
        R.enemy=m.ReadUInt16();R.wrench=m.ReadUInt16();R.foreign=m.ReadUInt16()
    end
    if phase==5 then R.rod=m.ReadUInt16() end
    if phase==8 then R.wall=m.ReadUInt16();R.section=m.ReadUInt16() end
    R.move=phase==4;R.grab=phase==3;R.grabStarted=nil;R.grabPressed=false
    local modes={[1]='repair',[2]='combat',[3]='grab',[4]='off',[5]='off',[6]='off',[7]='off',[8]='repair'}
    local function ready()
        local item=R.suit and entity(R.suit)
        if not item or G.equipped(Character.Controlled)~=item then Timer.Wait(ready,100);return end
        G.requestMode(item,modes[phase])
        if phase==6 then
            Timer.Wait(function() G.requestMode(entity(R.foreign),'combat') end,200)
        end
        Timer.Wait(function()
            local ok,detail=pcall(function()
                local c=Character.Controlled;local s=G.states[item]
                assert(s and s.received and G.now-s.received<.5,'no fresh server snapshot')
                assert(not G.drawError,'renderer error: '..tostring(G.drawError))
                assert(s.mode==modes[phase],'mode mismatch '..tostring(s.mode))
                if phase==1 then
                    assert(G.source(item)==entity(R.cell),'second container did not replicate')
                    assert(G.container(item,1).GetItemAt(0)==entity(R.tank),'oxygen container mismatch')
                    assert(entity(R.device).Submarine==c.Submarine,'device left submarine space')
                    assert(s.active and s.target and s.target.entity==entity(R.device) and s.target.kind=='repair','repair target mismatch')
                    assert(entity(R.device).Condition>10,'device condition not replicated')
                    assert(#(s.sparks or {})>0,'no repair contact sparks')
                elseif phase==2 then
                    assert(s.active and s.target and s.target.entity==entity(R.enemy) and s.target.kind=='combat','combat target mismatch')
                elseif phase==3 then
                    assert(s.active and s.target and s.target.entity==entity(R.wrench) and s.target.kind=='grab','grab target mismatch')
                    assert(not entity(R.wrench).ParentInventory,'grab picked up item natively')
                elseif phase==4 then
                    assert(c.AnimController.HeadInWater and not s.open,'helmet did not close')
                    assert(c.OxygenAvailable>90 and c.Oxygen>90,'client predicts oxygen deprivation')
                    assert(entity(R.tank).Condition<entity(R.tank).MaxCondition,'tank debit did not replicate')
                    assert(s.swimming,'propulsion state did not replicate')
                elseif phase==5 then
                    assert(G.source(item)==entity(R.rod) and G.source(item).HasTag('reactorfuel'),'rod swap did not replicate')
                elseif phase==6 then
                    local foreign=G.states[entity(R.foreign)]
                    assert(foreign and foreign.mode=='off','foreign suit request was accepted')
                elseif phase==7 then assert(not s.active and not s.target,'off mode retained a beam')
                elseif phase==8 then
                    assert(s.active and s.target and s.target.kind=='weld' and s.target.entity==entity(R.wall),'welding target mismatch')
                    assert(entity(R.wall).SectionDamage(R.section)<35,'wall repair did not replicate')
                    assert(#(s.sparks or {})>0,'no welding sparks')
                end
                if phase<=4 or phase==8 then
                    File.Write('LocalMods/System-Aegis/headset-capture.request',
                        (AegisCaptureRoot or 'LocalMods/System-Aegis/')..'aegis-mp-'..phase..'.png')
                end
                return 'mode='..s.mode..' active='..tostring(s.active)..' open='..tostring(s.open)..
                    ' oxygen='..c.OxygenAvailable..' sparks='..#(s.sparks or {})..' renderer=ok'
            end)
            report(phase,ok,tostring(detail))
        end,2200)
    end
    ready()
end)
Networking.Receive(P..'.done',function()
    R.move=false;R.grab=false
    save('DONE real joined client phases complete')
    Timer.Wait(function()
        cam.Zoom=oldZoom;Game.LightManager.LightingEnabled=oldLighting;Game.LightManager.LosEnabled=oldLos
    end,1500)
    for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
        Hook.RemovePatch('aegis.servo.mp.'..entry[1],'Barotrauma.Character',entry[1],entry[2])
    end
end)
Networking.Receive(P..'.grabtarget',function(m) R.wrench=m.ReadUInt16() end)
local hello=Networking.Start(P..'.hello');Networking.Send(hello)
save('READY authoritative=false real multiplayer client')
