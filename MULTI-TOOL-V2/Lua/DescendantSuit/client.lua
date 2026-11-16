local C=require('DescendantSuit.config')
local Core=require('DescendantSuit.core')
local U=require('CombatTool.util')
local M={}
function M.install(G,E,root)
    local UI=E.GUI
    local gui=UI.GUI
    local atlas=E.Sprite(root..'/Assets/DescendantSuit/suit-v2.png',E.Vector2(.5,.5))
    local A=require('DescendantSuit.atlas')
    local rects={upper=A.upperLink,lower=A.lowerLink,red=A.emitter,blue=A.emitter,orange=A.emitter,
        rotor0=A.rotor,rotor1=A.rotor,rotor2=A.rotor,rotor3=A.rotor}
    require('DescendantSuit.lights').install(G,E)
    require('DescendantSuit.ui').install(G,E)
    local colors={repair={75,190,255},weld={75,190,255},combat={255,45,45},grab={255,153,35}}
    local channels={}
    local function stop(ch) if ch then ch.FadeOutAndDispose() end end
    local function sound(id,owner) return E.SoundPlayer.PlaySound('descendant_'..id,owner.WorldPosition) end
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
    local function line(batch,cam,a,b,color,width)
        gui.DrawLine(batch,screen(cam,a),screen(cam,b),color,0,width)
    end
    local function sprite(batch,cam,key,point,rotation,scale,origin)
        local r=rects[key]
        atlas.SourceRect=E.Rectangle(r[1],r[2],r[3],r[4])
        atlas.Origin=origin or E.Vector2(r[3]/2,r[4]/2)
        atlas.Draw(batch,screen(cam,point),E.Color.White,atlas.Origin,rotation or 0,E.Vector2(scale,scale))
    end
    local function link(batch,cam,key,a,b,span,origin)
        local dx,dy=b.x-a.x,b.y-a.y
        sprite(batch,cam,key,a,-math.atan2(dy,dx),math.sqrt(dx*dx+dy*dy)/span,origin)
    end
    local function helmet(owner,item,open)
        local s=G.state(item)
        if s.drawOpen==open then return end
        U.each(owner.AnimController.Limbs,function(limb)
            if limb.type==E.LimbType.Head then U.each(limb.WearingItems,function(w)
                if w.WearableComponent and w.WearableComponent.Item==item then
                    local r=open and A.helmetOpen or A.helmetClosed
                    w.Sprite.SourceRect=E.Rectangle(r[1],r[2],r[3],r[4]);w.Sprite.Origin=E.Vector2(r[3]/2,r[4]/2)
                end
            end) end
        end)
        s.drawOpen=open
    end
    function G.updateClient(dt)
        G.updateSuitUI(dt)
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
                G.syncSonar(item,s)
                local entry=channels[item] or {};channels[item]=entry;entry.state=s
                local active=s.active and s.target and s.target.kind
                loop(entry,'beam',active~='combat' and active or nil,owner);loop(entry,'motor',s.swimming and 'impeller' or nil,owner)
                if entry.shots~=nil and entry.shots~=(s.shots or 0) then sound('pulse',owner);s.shotTime=G.now end
                entry.shots=s.shots or 0
                G.updateLights(s)
                if entry.open~=nil and entry.open~=s.open then sound('helmet',owner) end
                if entry.mode and entry.mode~=s.mode then sound('switch',owner) end
                local id=s.target and s.target.entity and s.target.entity.ID
                if id and id~=entry.target then sound('servo',owner) end
                entry.open,entry.mode,entry.target=s.open,s.mode,id
                s.sparks=s.sparks or {}
                for n=#s.sparks,1,-1 do
                    local p=s.sparks[n];p.age=p.age+dt
                    if p.age>p.life then table.remove(s.sparks,n)
                    else p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.vy=p.vy-160*dt end
                end
                if active=='repair' or active=='weld' then
                    s.sparkBudget=(s.sparkBudget or 0)+dt*150
                    local point=s.target.point
                    while s.sparkBudget>=1 and #s.sparks<72 do
                        s.sparkBudget=s.sparkBudget-1
                        local angle=math.random()*math.pi*2;local speed=80+math.random()*200
                        s.sparks[#s.sparks+1]={x=point.x,y=point.y,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,
                            age=0,life=.12+math.random()*.18}
                    end
                    s.sparkBudget=math.min(s.sparkBudget,2)
                else s.sparkBudget=0 end
            end
        end
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
                    local flash=s.lastPulse and G.now-(s.shotTime or -100)<C.pulseDuration
                    local pose=G.toolPose(owner,s,true,flash and s.lastPulse or nil)
                    link(batch,cam,'upper',base,pose.elbow,250,E.Vector2(44,50))
                    link(batch,cam,'lower',pose.elbow,pose.tip,247,E.Vector2(39,41))
                    local colorKey=flash and 'red' or target and (target.kind=='combat' and 'red' or target.kind=='grab' and 'orange' or 'blue') or 'blue'
                    sprite(batch,cam,colorKey,pose.tip,-pose.angle,.16,E.Vector2(37,54))
                    local motor=G.attachment(owner,-20,-18,true)
                    sprite(batch,cam,'rotor0',motor,-bodyRotation+(s.swimming and G.now*14 or 0),.10)
                    local short=not target or (target.kind~='repair' and target.kind~='weld') or
                        (target.point.x-pose.muzzle.x)^2+(target.point.y-pose.muzzle.y)^2<=(C.repairBeam+C.contactSlack+2)^2
                    local beam=flash and s.lastPulse or (target and target.kind~='combat' and s.active and short and target.point)
                    if beam then
                        local repairing=not flash and target and (target.kind=='repair' or target.kind=='weld')
                        local col=flash and colors.combat or colors[target.kind]
                        line(batch,cam,pose.muzzle,beam,E.Color(col[1],col[2],col[3],70),repairing and 12 or 8)
                        line(batch,cam,pose.muzzle,beam,E.Color(col[1],col[2],col[3],220),repairing and 4 or 2.5)
                        line(batch,cam,pose.muzzle,beam,E.Color(235,250,255,240),repairing and 1.2 or .7)
                    end
                    for _,p in ipairs(s.sparks or {}) do
                        local tail={x=p.x-p.vx*.022,y=p.y-p.vy*.022}
                        local alpha=math.floor(255*(1-p.age/p.life))
                        line(batch,cam,tail,p,E.Color(65,170,255,math.floor(alpha*.35)),4)
                        line(batch,cam,tail,p,E.Color(220,248,255,alpha),1.2)
                    end
                end
            end
        end
    end
    G.patch('draw','Barotrauma.Character','Draw',function(owner,p)
        if G.drawError then return end
        local ok,err=pcall(draw,p['spriteBatch'],p['cam'],owner)
        if not ok then G.drawError=tostring(err);E.printerror('[Descendant suit] Render: '..tostring(err)) end
    end,true)
    function G.pauseClient()
        for _,entry in pairs(channels) do stop(entry.beam);stop(entry.motor) end
        channels={}
    end
    function G.clearClient()
        for _,s in pairs(G.states) do G.removeLights(s) end
        for _,entry in pairs(channels) do stop(entry.beam);stop(entry.motor);G.removeLights(entry.state) end
        channels={};G.clearSuitUI()
    end
    function G.disposeClient()
        G.disposeSuitUI();atlas.Remove()
    end
end
return M
