-- Isolated joined client, never package this fixture.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=BMTDescendantSuit
local P='bmt.servo.v2.probe'
local R={rows={},stage=0,move=false,grab=false}
ServoV2Client=R
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO V2 CLIENT] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-v2-client.txt',table.concat(R.rows,'\n'))
end
local function entity(id) return Entity.FindEntityByID(id) end
local function capture(name)
    File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/servo-v2-'..name..'.png')
end
local function inputs(c)
    if c~=Character.Controlled then return end
    c.SetInput(InputType.Left,false,false);c.SetInput(InputType.Right,false,R.move)
    c.SetInput(InputType.Up,false,false);c.SetInput(InputType.Down,false,false)
    c.SetInput(InputType.Shoot,false,false)
    local target=R.grab and entity(R.wrench)
    local pressed=false
    if target then
        R.grabAt=R.grabAt or G.now
        c.CursorPosition=c.Position+target.WorldPosition-c.WorldPosition
        pressed=G.now-R.grabAt>=.5 and G.now-R.grabAt<.75
    end
    c.SetInput(InputType.Aim,false,target~=nil)
    c.SetInput(InputType.Use,pressed and not R.pressed,pressed);R.pressed=pressed
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
    Hook.Patch('bmt.servo.v2.input.'..entry[1],'Barotrauma.Character',entry[1],inputs,entry[2])
end
Networking.Receive(P..'.phase',function(m)
    local n=m.ReadByte();R.stage=n
    for _,key in ipairs({'suit','cell','ammo','device','enemy','wrench','wall'}) do R[key]=m.ReadUInt16() end
    R.section=m.ReadUInt16()
    R.move=n==6;R.grab=n==5;R.grabAt=nil;R.pressed=false
    if n==0 then return end
    local modes={[1]='repair',[2]='repair',[3]='combat',[4]='combat',[5]='grab',[6]='off',[7]='repair',[8]='off',[9]='off',[10]='off',[11]='repair'}
    local function ready()
        local suit=entity(R.suit)
        if not suit or G.equipped(Character.Controlled)~=suit then Timer.Wait(ready,100);return end
        G.requestMode(suit,modes[n])
        if n==11 then
            Timer.Wait(function() G.requestMode(suit,'toggle') end,300)
            Timer.Wait(function() G.requestMode(suit,'toggle') end,600)
        end
        if n==1 then Timer.Wait(function() capture('repair') end,1000) end
        if n==3 then Timer.Wait(function() capture('pulse') end,700) end
        if n==7 then Timer.Wait(function() capture('weld') end,700) end
        Timer.Wait(function()
            local ok,detail=pcall(function()
                local s=G.states[suit];assert(s and s.received and G.now-s.received<.5,'stale server state')
                assert(not G.drawError,'world draw error: '..tostring(G.drawError))
                assert(s.mode==modes[n],'wrong mode '..tostring(s.mode))
                assert(s.lights and s.lights.helmet,'no real native helmet light')
                assert(suit.OwnInventory.Capacity==2,'not a single visible two-slot container')
                if n==1 then
                    assert(G.source(suit)==entity(R.cell) and G.ammo(suit)==entity(R.ammo),'slot roles not replicated')
                    assert(s.active and s.target and s.target.kind=='repair' and #(s.sparks or {})>0,'no repair/sparks')
                    assert(entity(R.device).Condition>20,'slow repair')
                    assert(tostring(G.panelButtons.off.Text):lower()==tostring(TextManager.Get('descendant.on')):lower(),'arm state text wrong')
                elseif n==2 then assert(entity(R.device).IsFullCondition,'completion did not replicate')
                elseif n==3 then assert((s.shots or 0)>0 and entity(R.ammo).Condition<100,'pulse/ammo did not replicate')
                elseif n==4 then assert(not s.active,'defence active without ammo')
                elseif n==5 then assert(s.active and s.target and s.target.entity==entity(R.wrench),'wrong grab target')
                elseif n==6 then
                    assert(Character.Controlled.AnimController.HeadInWater and not s.open and s.swimming,'water state mismatch')
                    assert(Character.Controlled.OxygenAvailable>90 and s.lights.helmet.Range>0,'closed loop or lamps failed')
                    capture('water')
                elseif n==7 then assert(entity(R.wall).SectionDamage(R.section)<5,'wall repair not replicated')
                elseif n==10 then
                    assert(s.lights.helmet.Range==0 and s.lights.tool.Range==0,'lights remain powered')
                    capture('dark')
                elseif n==11 then assert(tostring(G.panelButtons.off.Text):lower()==tostring(TextManager.Get('descendant.on')):lower(),'toggle label wrong') end
                return 'mode='..s.mode..' active='..tostring(s.active)..' lights='..s.lights.helmet.Range..
                    ' ammo='..entity(R.ammo).Condition..' shots='..(s.shots or 0)..' renderer=ok'
            end)
            log((ok and 'PASS ' or 'FAIL ')..n..' '..tostring(detail))
            local reply=Networking.Start(P..'.report');reply.WriteByte(n);reply.WriteBoolean(ok);reply.WriteString(tostring(detail));Networking.Send(reply)
        end,n==3 and 1500 or n==7 and 3000 or 2200)
    end
    ready()
end)
Networking.Receive(P..'.done',function()
    R.move=false;R.grab=false
    for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before},{'UpdateNetInput',Hook.HookMethodType.Before}}) do
        Hook.RemovePatch('bmt.servo.v2.input.'..entry[1],'Barotrauma.Character',entry[1],entry[2])
    end
    log('DONE')
end)
local hello=Networking.Start(P..'.hello');Networking.Send(hello)
log('HELLO real joined client')
