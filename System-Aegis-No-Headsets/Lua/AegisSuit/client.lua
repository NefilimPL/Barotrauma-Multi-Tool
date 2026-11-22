local C=require('AegisSuit.config')
local Core=require('AegisSuit.core')
local U=require('AegisCombat.util')
local Factions=require('AegisSuit.factions')
local M={}
function M.install(G,E,root)
    local UI=E.GUI
    local gui=UI.GUI
    local skins={}
    local function skin(key,asset)
        local path=Factions.path(key,asset)
        if not skins[path] then
            skins[path]=E.Sprite(root..'/'..path,E.Vector2(asset=='housing' and .54 or .5,.5))
        end
        return skins[path]
    end
    local atlasKey='pirates'
    local atlas=skin(atlasKey,'atlas')
    local impeller=E.Sprite(root..'/Assets/AegisSuit/impeller.png',E.Vector2(.5,.5))
    -- The rotor and its housing retain their world size after texture downsampling.
    local rotorTextureScale=1254/312
    local bladeSize=.0135*rotorTextureScale
    local housingSize=.022*rotorTextureScale
    local housing=skin('pirates','housing')
    local pulseHead=E.Sprite('Content/Items/Weapons/Turrets.png',E.Vector2(.5,.5))
    local beamSprite=E.Sprite('Content/Particles/ParticleAtlas.png',E.Vector2(0,.5))
    -- Native neutral, feathered trail. The pulse itself is rendered only by
    -- Projectile's native pulse texture; never overlay another red beam.
    beamSprite.SourceRect=E.Rectangle(130,383,225,40)
    beamSprite.Origin=E.Vector2(0,20)
    local A=require('AegisSuit.atlas')
    local rects={upper='upperLink',lower='lowerLink',red='emitter',blue='emitter',orange='emitter',
        rotor0='rotor',rotor1='rotor',rotor2='rotor',rotor3='rotor'}
    require('AegisSuit.lights').install(G,E)
    require('AegisSuit.ui').install(G,E)
    local emitSparks=require('AegisSuit.sparks').new(E)
    local colors={repair={75,190,255},weld={75,190,255},combat={255,45,45},grab={255,153,35}}
    local channels={}
    local heldPlatforms={}
    local drawFailures=setmetatable({},{__mode='k'})
    local function restoreHeld(entity,old)
        if not entity.Removed then entity.AnimController.IgnorePlatforms=old end
        if G.heldCharacters then G.heldCharacters[entity]=nil end
        heldPlatforms[entity]=nil
    end
    local function stop(ch) if ch then ch.FadeOutAndDispose() end end
    local function sound(id,owner) return E.SoundPlayer.PlaySound('aegis_'..id,owner.WorldPosition) end
    local function loop(entry,key,kind,owner)
        local ch=entry[key]
        if not kind then stop(ch);entry[key]=nil;return end
        if entry[key..'Kind']~=kind then stop(ch);ch=nil end
        if not ch or not ch.IsPlaying then ch=sound(kind,owner);if ch then ch.Looping=true end end
        entry[key],entry[key..'Kind']=ch,kind
        if ch then local p=owner.WorldPosition;ch.Position=E.Vector3(p.X,p.Y,0) end
    end
    -- Character.Draw already has the world transform and is lit afterwards.
    local function screen(cam,p) return E.Vector2(p.x,-p.y) end
    local function sprite(batch,cam,key,point,rotation,scale,origin)
        local base=A[rects[key]]
        local r=Factions.frame(atlasKey,rects[key])
        if origin then origin=E.Vector2(origin.X+(r[3]-base[3])/2,origin.Y+(r[4]-base[4])/2) end
        atlas.SourceRect=E.Rectangle(r[1],r[2],r[3],r[4])
        atlas.Origin=origin or E.Vector2(r[3]/2,r[4]/2)
        atlas.Draw(batch,screen(cam,point),E.Color.White,atlas.Origin,rotation or 0,E.Vector2(scale,scale))
    end
    local function link(batch,cam,key,a,b,span,origin)
        local dx,dy=b.x-a.x,b.y-a.y
        sprite(batch,cam,key,a,-math.atan2(dy,dx),math.sqrt(dx*dx+dy*dy)/span,origin)
    end
    local function drawPulseHead(batch,cam,pose)
        -- Original pulse-laser rail/barrel, uniformly miniaturized. Origins
        -- include native firingoffset=(-10,-220), so its nozzle is exactly
        -- the shared physical muzzle, including while the arm rotates.
        local point=screen(cam,pose.muzzle)
        local angle=math.pi/2-pose.angle
        pulseHead.SourceRect=E.Rectangle(904,592,120,287)
        pulseHead.Origin=E.Vector2(50,-16.23)
        pulseHead.Draw(batch,point,E.Color.White,pulseHead.Origin,angle,E.Vector2(.11,.11))
        pulseHead.SourceRect=E.Rectangle(779,592,125,333)
        pulseHead.Origin=E.Vector2(52.5,46.4)
        pulseHead.Draw(batch,point,E.Color.White,pulseHead.Origin,angle,E.Vector2(.11,.11))
        -- The two native charging panels complete the original gun silhouette.
        pulseHead.SourceRect=E.Rectangle(570,692,59,150)
        pulseHead.Origin=E.Vector2(49,20)
        pulseHead.Draw(batch,point,E.Color.White,pulseHead.Origin,angle,E.Vector2(.11,.11))
        pulseHead.SourceRect=E.Rectangle(642,692,59,150)
        pulseHead.Origin=E.Vector2(-10,20)
        pulseHead.Draw(batch,point,E.Color.White,pulseHead.Origin,angle,E.Vector2(.11,.11))
    end
    local function softBeam(batch,cam,a,b,col,repairing)
        local dx,dy=b.x-a.x,b.y-a.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length<.1 then return end
        local angle=-math.atan2(dy,dx)
        local p=screen(cam,a)
        -- Premultiplied tints preserve soft alpha edges in the world batch.
        local glow=E.Color(math.floor(col[1]*.38),math.floor(col[2]*.38),math.floor(col[3]*.38),97)
        local core=E.Color(math.floor((col[1]*.25+191.25)*.85),
            math.floor((col[2]*.25+191.25)*.85),math.floor((col[3]*.25+191.25)*.85),217)
        beamSprite.Draw(batch,p,glow,beamSprite.Origin,angle,E.Vector2(length/225,(repairing and 9 or 7)/40))
        beamSprite.Draw(batch,p,core,beamSprite.Origin,angle,E.Vector2(length/225,(repairing and 2.4 or 1.8)/40))
    end
    local function helmet(owner,item,open)
        local s=G.state(item)
        if s.drawOpen==open then return end
        U.each(owner.AnimController.Limbs,function(limb)
            if limb.type==E.LimbType.Head then U.each(limb.WearingItems,function(w)
                if w.WearableComponent and w.WearableComponent.Item==item then
                    local r=Factions.frame(Factions.key(item),open and 'helmetOpen' or 'helmetClosed')
                    w.Sprite.SourceRect=E.Rectangle(r[1],r[2],r[3],r[4]);w.Sprite.Origin=E.Vector2(r[3]/2,r[4]/2)
                end
            end) end
        end)
        s.drawOpen=open
    end
    function G.updateClient(dt)
        G.updateSuitUI(dt)
        local holding={}
        for item,s in pairs(G.states) do
            local owner=s.owner or G.owner(item)
            if item.Removed or not owner or G.equipped(owner)~=item or
                (not G.authoritative and s.received and G.now-s.received>.6) then
                local entry=channels[item]
                if entry then stop(entry.beam);stop(entry.motor);channels[item]=nil end
                G.removeLights(s)
                G.stopSonar(item,s)
                G.states[item]=nil
            else
                helmet(owner,item,s.open==true)
                if G.interpolateTool then G.interpolateTool(s,dt,owner) end
                G.syncSonar(item,s)
                local entry=channels[item] or {};channels[item]=entry;entry.state=s
                local active=s.active and s.target and s.target.kind
                if not G.authoritative and active=='grab' then
                    local entity=s.target.entity
                    if entity and E.LuaUserData.IsTargetType(entity,'Barotrauma.Character') then
                        if heldPlatforms[entity]==nil then heldPlatforms[entity]=entity.AnimController.IgnorePlatforms==true end
                        holding[entity]=true;G.heldCharacters[entity]=true
                        entity.AnimController.IgnorePlatforms=true
                        entity.DisableImpactDamageTimer=math.max(entity.DisableImpactDamageTimer,.25)
                    end
                end
                if s.swimming and owner.AnimController.InWater then
                    s.bubbleBudget=(s.bubbleBudget or 0)+dt*24
                    while s.bubbleBudget>=1 do
                        s.bubbleBudget=s.bubbleBudget-1
                        local p=G.attachment(owner,-24,-20)
                        E.Game.ParticleManager.CreateParticle('bubbles',E.Vector2(p.x,p.y),E.Vector2.Zero)
                    end
                else s.bubbleBudget=0 end
                loop(entry,'beam',active~='combat' and active or nil,owner);loop(entry,'motor',s.swimming and 'impeller' or nil,owner)
                local newShot=entry.shots~=nil and entry.shots~=(s.shots or 0)
                if newShot then
                    sound(s.ballisticShot and 'gauss' or 'pulse',owner);s.shotTime=G.now
                end
                entry.shots=s.shots or 0
                G.updateLights(s,newShot)
                if entry.open~=nil and entry.open~=s.open then sound('helmet',owner) end
                if entry.mode and entry.mode~=s.mode then sound('switch',owner) end
                local id=s.target and s.target.entity and s.target.entity.ID
                if id and id~=entry.target then sound('servo',owner) end
                entry.open,entry.mode,entry.target=s.open,s.mode,id
                emitSparks(s,active,s.target and s.target.point,dt)
            end
        end
        for entity,old in pairs(heldPlatforms) do if not holding[entity] then restoreHeld(entity,old) end end
        for item,entry in pairs(channels) do if not G.states[item] then
            stop(entry.beam);stop(entry.motor);G.removeLights(entry.state);channels[item]=nil
        end end
    end
    local function draw(batch,cam,drawOwner)
        for item,s in pairs(G.states) do
            local owner=s.owner or G.owner(item)
            if owner==drawOwner and G.equipped(owner)==item then
                local base,bodyRotation,facing=G.mount(owner,true)
                local sp=cam.WorldToScreen(E.Vector2(base.x,base.y))
                local viewport=gui.Canvas.Rect
                if sp.X> -300 and sp.Y> -300 and sp.X<viewport.Width+300 and sp.Y<viewport.Height+300 then
                    local target=s.target
                    if target and target.entity and not target.entity.Removed and target.kind~='weld' then target.point=U.point(target.entity.WorldPosition) end
                    local pose
                    if s.hasArm then
                        local part=G.module and G.module(item,'servo')
                        atlasKey=Factions.key(part or item)
                        atlas=skin(atlasKey,'atlas')
                        local flash=s.lastPulse and G.now-(s.shotTime or -100)<C.pulseDuration
                        pose=G.toolPose(owner,s,true,flash and s.lastPulse or nil)
                        link(batch,cam,'upper',base,pose.elbow,250,E.Vector2(44,50))
                        link(batch,cam,'lower',pose.elbow,pose.tip,247,E.Vector2(39,41))
                        if s.mode=='combat' then drawPulseHead(batch,cam,pose)
                        else sprite(batch,cam,target and target.kind=='grab' and 'orange' or 'blue',pose.tip,-pose.angle,.16,E.Vector2(37,54)) end
                    end
                    if s.hasImpeller then
                        local part=G.module and G.module(item,'impeller')
                        housing=skin(Factions.key(part or item),'housing')
                        local motor=G.attachment(owner,-20,-18,true)
                        impeller.Draw(batch,screen(cam,motor),E.Color.White,impeller.Origin,
                            -bodyRotation+(s.swimming and G.now*14 or 0),E.Vector2(bladeSize,bladeSize))
                        housing.Draw(batch,screen(cam,motor),E.Color.White,housing.Origin,-bodyRotation,
                            E.Vector2(housingSize,housingSize))
                    end
                    local short=pose and (not target or (target.kind~='repair' and target.kind~='weld') or
                        (target.point.x-pose.muzzle.x)^2+(target.point.y-pose.muzzle.y)^2<=(C.repairBeam+C.contactSlack+2)^2)
                    local beam=pose and target and target.kind~='combat' and s.active and short and target.point
                    if beam then
                        softBeam(batch,cam,pose.muzzle,beam,colors[target.kind],target.kind~='grab')
                    end
                end
            end
        end
    end
    G.patch('draw','Barotrauma.Character','Draw',function(owner,p)
        local failure=drawFailures[owner]
        if failure and G.now<failure.retryAt then return end
        local ok,err=pcall(draw,p['spriteBatch'],p['cam'],owner)
        if ok then
            if failure then
                drawFailures[owner]=nil
                local _,other=next(drawFailures)
                G.drawError=other and other.message or nil
            end
            return
        end
        -- A temporary draw transform failure must not disable other wearers.
        -- Retry this wearer after a short delay and log repeated errors once.
        local message=tostring(err)
        G.drawError=message
        if not failure or failure.message~=message then E.printerror('[Aegis suit] Render: '..message) end
        drawFailures[owner]={message=message,retryAt=G.now+.25}
    end,true)
    function G.pauseClient()
        for _,entry in pairs(channels) do stop(entry.beam);stop(entry.motor) end
        channels={}
    end
    function G.clearClient()
        for owner in pairs(drawFailures) do drawFailures[owner]=nil end
        G.drawError=nil
        for entity,old in pairs(heldPlatforms) do restoreHeld(entity,old) end
        for _,s in pairs(G.states) do G.removeLights(s) end
        for _,entry in pairs(channels) do stop(entry.beam);stop(entry.motor);G.removeLights(entry.state) end
        channels={};G.clearSuitUI()
    end
    function G.disposeClient()
        G.disposeSuitUI();impeller.Remove();pulseHead.Remove();beamSprite.Remove()
        for _,sprite in pairs(skins) do sprite.Remove() end
        skins={}
    end
end
return M
