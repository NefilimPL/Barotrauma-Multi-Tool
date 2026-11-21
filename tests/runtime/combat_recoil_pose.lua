-- Disposable real client only: native input -> firing -> HoldItem -> GPU frames.
if not CLIENT then return end
local root=AegisCaptureRoot or 'LocalMods/System-Aegis/'
local rows={'phase='..File.Read('LocalMods/System-Aegis/recoil-phase.txt')}
local function log(row)
    rows[#rows+1]=row
    File.Write('LocalMods/System-Aegis/recoil-results.txt',table.concat(rows,'\n'))
end
local function start()
    if not Game.RoundStarted then Timer.Wait(start,500);return end
    local ok,err=pcall(function()
        local G=assert(AegisCombat,'combat did not initialize')
        local U=require('AegisCombat.util')
        local room
        for h in Hull.HullList do
            if h.Submarine==Submarine.MainSub and h.WaterPercentage<10 then room=h;break end
        end
        assert(room,'no dry room')
        local c=Character.Create('human',room.WorldPosition,'recoil-pose-probe')
        Character.Controlled=c;c.GodMode=true
        local gun=Item(ItemPrefab.Prefabs['aegiscombattool'],c.WorldPosition,nil)
        local cell=Item(ItemPrefab.Prefabs['batterycell'],c.WorldPosition,nil)
        assert(c.Inventory.TryPutItem(gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
        assert(gun.OwnInventory.TryPutItem(cell,0,false,false,c))
        U.component(gun,'LightComponent').IsOn=true
        local main=LuaUserData.CreateStatic('Barotrauma.GameMain')
        local born=G.now
        local shots,lastShot,lastSample=0,-100,-100
        local maxPoseAngle=0
        local idleCapture,shotCapture,finished=false,false,false
        local function input(actor)
            if actor~=c then return end
            local age=G.now-born
            c.CursorPosition=c.Position+Vector2(800,0)
            c.SetInput(InputType.Aim,false,true)
            c.SetInput(InputType.Shoot,false,age>1.2 and age<4.2)
        end
        Hook.Patch('aegis.recoil.probe.input','Barotrauma.Character','ControlLocalPlayer',input,Hook.HookMethodType.After)
        local old=G.event
        G.event=function(kind,s,...)
            if kind=='shot' and s.item==gun then shots=shots+1;lastShot=G.now end
            return old(kind,s,...)
        end
        Hook.Patch('aegis.recoil.probe.pose','Barotrauma.AnimController','HoldItem',function(_,p)
            if finished or p['item']~=gun or G.now-lastSample<.014 then return end
            lastSample=G.now
            gun.body.UpdateDrawPosition()
            local pos=p['itemPos']
            maxPoseAngle=math.max(maxPoseAngle,math.abs(p['itemAngleRelativeToHoldAngle']))
            log(string.format('t=%.3f sinceShot=%.3f pose=%.5f,%.5f angleOffset=%.5f bodyRotation=%.5f drawRotation=%.5f',
                G.now-born,G.now-lastShot,pos.X,pos.Y,p['itemAngleRelativeToHoldAngle'],gun.body.Rotation,gun.body.DrawRotation))
        end,Hook.HookMethodType.After)
        Hook.Add('think','aegis.recoil.probe.camera',function()
            if finished then return end
            local age=G.now-born
            main.GameScreen.Cam.Position=c.WorldPosition+Vector2(30,0)
            main.GameScreen.Cam.Zoom=1.5
            if age>.8 and not idleCapture then
                idleCapture=true;File.Write('LocalMods/System-Aegis/recoil-capture.request',root..'recoil-idle.png')
            end
            if shots==1 and G.now-lastShot>.035 and not shotCapture then
                shotCapture=true;File.Write('LocalMods/System-Aegis/recoil-capture.request',root..'recoil-shot.png')
            end
            if age>5 then
                finished=true
                log('DONE shots='..shots..' maxPoseAngle='..maxPoseAngle..' visualError='..tostring(G.visualError)..' audioError='..tostring(G.audioError))
                Hook.Remove('think','aegis.recoil.probe.camera')
                Hook.RemovePatch('aegis.recoil.probe.input','Barotrauma.Character','ControlLocalPlayer',Hook.HookMethodType.After)
                Hook.RemovePatch('aegis.recoil.probe.pose','Barotrauma.AnimController','HoldItem',Hook.HookMethodType.After)
                G.event=old
            end
        end)
        local channel=G.playCombatSound('shot',{x=c.WorldPosition.X,y=c.WorldPosition.Y})
        assert(channel,'shot audio did not play')
        log('nativeShotGain='..channel.Gain)
        channel.Dispose()
        log('START round='..tostring(Game.RoundStarted)..' authority='..tostring(G.authoritative)..' gun='..gun.ID)
    end)
    if not ok then log('FAIL '..tostring(err)) end
end
start()
