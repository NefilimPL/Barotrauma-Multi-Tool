local U=require('CombatTool.util')
local C=require('CombatTool.config')
local Core=require('CombatTool.core')
local M={}
function M.install(G,E,root)
    -- Current LuaCs exposes GUI drawing under GUI.GUI. Sprite.Draw supplies
    -- SpriteEffects.None by default; the optional global enum may be absent.
    local gui=type(E.GUI)=='table' and E.GUI.GUI or E.GUI
    local sortMode=E.LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
    E.LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.BlendState')
    local blend=E.LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
    local assets={}
    for _,name in ipairs({'shield-active','shield-hit','shield-break','shield-contact'}) do
        assets[name]=E.Sprite(root..'/Assets/Combat/'..name..'.png',E.Vector2(.5,.5))
    end
    function G.updateFlashlights()
        for item in pairs(G.states or {}) do
            if not item.Removed and U.itemId(item)==C.identifier and item.body then
                local lamp=U.component(item,'LightComponent',2)
                if lamp and lamp.Light then
                    local body=item.body
                    body.UpdateDrawPosition()
                    local angle=body.DrawRotation
                    local x=lamp.LightOffset.X*item.Scale*(body.Dir<0 and -1 or 1)
                    local y=lamp.LightOffset.Y*item.Scale
                    lamp.Light.ParentBody=body
                    lamp.Light.OffsetFromBody=E.Vector2(x*math.cos(angle)-y*math.sin(angle),
                        x*math.sin(angle)+y*math.cos(angle))
                    lamp.Light.Rotation=angle+(body.Dir<0 and -math.pi or 0)
                end
            end
        end
    end
    -- The native light component rotates its offset by the editor rotation,
    -- while a held weapon turns its physics body. Correct the mount immediately
    -- before the light map consumes it, using the same interpolated pose.
    G.patch('flashlight-origin','Barotrauma.Lights.LightManager','RenderLightMap',G.updateFlashlights)
    local effects={}
    local electricity,particleManager
    local function emitNativeArc(point,endpoint)
        local dx,dy=endpoint.x-point.x,endpoint.y-point.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length<.01 then return end
        if not electricity then
            E.LuaUserData.RegisterType('Barotrauma.SpriteSheet')
            E.LuaUserData.RegisterType('Barotrauma.GameMain')
            local sheet=E.LuaUserData.CreateStatic('Barotrauma.SpriteSheet')
            electricity=sheet('Content/Lights/Electricity.png',4,4,E.Vector2(.5,0))
            particleManager=E.LuaUserData.CreateStatic('Barotrauma.GameMain').ParticleManager
        end
        local function spark(x,y)
            local particle=particleManager.CreateParticle('ElectricShock',E.Vector2(x,y),E.Vector2(0,0))
            if particle then particle.Size=particle.Size*.3 end
        end
        -- Same native particles and spacing as ElectricalDischarger, with a
        -- final spark at the contacted character. Emit once per network event.
        for distance=0,length,50 do spark(point.x+dx*distance/length,point.y+dy*distance/length) end
        spark(endpoint.x,endpoint.y)
    end
    function G.onEffect(kind,point,angle,id,endpoint)
        if G.playCombatSound then G.playCombatSound(kind,point) end
        if kind=='arc' and endpoint then emitNativeArc(point,endpoint) end
        effects[#effects+1]={kind=kind,x=point.x,y=point.y,angle=angle,age=0,id=id,endpoint=endpoint}
        if #effects>256 then table.remove(effects,1) end
    end
    function G.updateVisuals(dt)
        if not G.authoritative and G.now-(G.remote.received or -100)<.3 then
            for _,ring in ipairs(G.remote.rings) do
                Core.advanceRing(ring,dt,function(a,b,r) return G.cast(a,b,r.radius,nil,true) end)
            end
        end
        for i=#effects,1,-1 do
            local effect=effects[i]
            effect.age=effect.age+dt
            if effect.kind=='charge' then
                for item in pairs(G.states or {}) do
                    if item.ID==effect.id and not item.Removed then
                        local p=G.muzzle(item)
                        effect.x,effect.y=p.x,p.y
                        local _,angle=G.direction(item);effect.angle=angle
                        break
                    end
                end
            end
            if effect.age>.8 then table.remove(effects,i) end
        end
    end
    local function frame(sprite,index)
        index=math.max(0,math.min(15,index))
        local column,row=index%4,math.floor(index/4)
        local x,y=math.floor(column*1254/4),math.floor(row*1254/4)
        local w,h=math.floor((column+1)*1254/4)-x,math.floor((row+1)*1254/4)-y
        sprite.SourceRect=E.Rectangle(x,y,w,h)
        return E.Vector2(w/2,h/2)
    end
    local function drawSheet(batch,cam,name,index,point,angle,sx,sy,alpha,band)
        local sprite=assets[name]
        local origin=frame(sprite,index)
        if band then
            local rect=sprite.SourceRect
            local top,bottom=math.floor(rect.Height*band[1]),math.floor(rect.Height*band[2])
            sprite.SourceRect=E.Rectangle(rect.X,rect.Y+top,rect.Width,bottom-top)
            -- Keep each cropped strip registered to the same full-frame pivot.
            origin=E.Vector2(rect.Width/2,rect.Height/2-top)
        end
        local screen=cam.WorldToScreen(E.Vector2(point.x,point.y))
        sprite.Draw(batch,screen,E.Color(255,255,255,math.floor(255*(alpha or 1))),origin,-angle,
            E.Vector2(sx*cam.Zoom,sy*cam.Zoom))
    end
    local function line(batch,cam,a,b,color,width)
        gui.DrawLine(batch,cam.WorldToScreen(E.Vector2(a.x,a.y)),cam.WorldToScreen(E.Vector2(b.x,b.y)),color,0,math.max(1,math.floor(width*cam.Zoom+.5)))
    end
    local function circle(batch,cam,x,y,angle,radius,color,width,phase,span,squash)
        local previous=nil
        for i=0,24 do
            local a=(phase or 0)+i*(span or math.pi*2)/24
            local ux,uy=math.cos(a)*radius*(squash or .45),math.sin(a)*radius
            local p={x=x+ux*math.cos(angle)-uy*math.sin(angle),y=y+ux*math.sin(angle)+uy*math.cos(angle)}
            if previous then line(batch,cam,previous,p,color,width) end
            previous=p
        end
    end
    local function drawRing(batch,cam,r)
        local angle=Core.angle(r.dx,r.dy)
        local phase=(r.age or 0)*24+(r.id or 0)*1.7
        local radius=(r.radius+2)*(1+.1*math.sin(phase*.7))
        local squash=.45+.12*math.sin(phase*.45)
        local trail=r.trail or {}
        for i=2,#trail do
            local a,b=trail[i-1],trail[i]
            local fade=math.max(0,1-((r.age or 0)-b.age)/C.trailLifetime)
            if fade>0 then
                line(batch,cam,a,b,E.Color(20,140,255,math.floor(35*fade)),5)
                line(batch,cam,a,b,E.Color(90,235,255,math.floor(90*fade)),1)
            end
        end
        circle(batch,cam,r.x,r.y,angle,radius+3,E.Color(10,135,255,35),7,0,nil,squash)
        circle(batch,cam,r.x,r.y,angle,radius,E.Color(80,230,255,210),2,0,nil,squash)
        circle(batch,cam,r.x,r.y,angle,radius*1.06,E.Color(225,255,255,245),2,phase,math.pi*.72,squash)
        circle(batch,cam,r.x,r.y,angle,radius*.72,E.Color(160,245,255,175),1,-phase,math.pi*.95,squash)
    end
    local function impactSparks(batch,cam,e)
        local t=e.age
        if t>.34 then return end
        local alpha=math.floor(255*(1-t/.34))
        if t<.09 then
            local flash=math.floor(255*(1-t/.09))
            circle(batch,cam,e.x,e.y,0,12+t*140,E.Color(100,225,255,math.floor(flash*.65)),9,0,nil,1)
            line(batch,cam,{x=e.x-15,y=e.y},{x=e.x+15,y=e.y},E.Color(235,255,255,flash),4)
            line(batch,cam,{x=e.x,y=e.y-15},{x=e.x,y=e.y+15},E.Color(235,255,255,flash),4)
        end
        for i=0,11 do
            local angle=e.angle+(i-5.5)*.32+math.sin((e.id or 0)+i)*.18
            local distance=4+t*(100+i*13)
            local a={x=e.x+math.cos(angle)*distance,y=e.y+math.sin(angle)*distance-t*t*40}
            local b={x=e.x+math.cos(angle)*(distance+9),y=e.y+math.sin(angle)*(distance+9)-t*t*40}
            line(batch,cam,a,b,E.Color(150,245,255,alpha),2)
        end
        circle(batch,cam,e.x,e.y,0,6+t*100,E.Color(90,220,255,math.floor(alpha*.6)),2,0,nil,1)
    end
    local function drawArc(batch,cam,e)
        if not electricity or not e.endpoint or e.age>.22 then return end
        local dx,dy=e.endpoint.x-e.x,e.endpoint.y-e.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length<.01 then return end
        local alpha=math.floor(255*(1-e.age/.22))
        local frame=(math.floor(e.age*60)+(e.id or 0))%electricity.FrameCount
        local width=math.min(length/electricity.FrameSize.X,1)*(.7+.3*math.abs(math.sin(e.age*90)))
        electricity.Draw(batch,frame,cam.WorldToScreen(E.Vector2(e.x,e.y)),E.Color(190,235,255,alpha),
            electricity.Origin,-Core.angle(dx,dy)-math.pi/2,
            E.Vector2(width*cam.Zoom,length/electricity.FrameSize.Y*cam.Zoom))
    end
    local function drawShield(batch,cam,s)
        local points={}
        local emitter={x=s.x+25*math.cos(s.angle),y=s.y+25*math.sin(s.angle)}
        for i=0,24 do
            local a=s.angle-C.shieldHalfAngle+2*C.shieldHalfAngle*i/24
            local p={x=s.x+math.cos(a)*C.shieldRadius,y=s.y+math.sin(a)*C.shieldRadius}
            local blocked=G.cast(emitter,p,0,nil,true)
            points[#points+1]={point=p,visible=blocked==nil}
        end
        local energy=math.max(.15,math.min(1,(s.energy or 100)/100))
        local height=2*C.shieldRadius*math.sin(C.shieldHalfAngle)
        local center={x=s.x+C.shieldRadius*.75*math.cos(s.angle),y=s.y+C.shieldRadius*.75*math.sin(s.angle)}
        -- Clip individual texture strips instead of discarding the whole sheet
        -- when even one edge touches the ceiling or a wall.
        for strip=0,15 do
            local y=(.5-(strip+.5)/16)*height
            local x=math.sqrt(math.max(0,C.shieldRadius*C.shieldRadius-y*y))
            local p={x=s.x+x*math.cos(s.angle)-y*math.sin(s.angle),
                y=s.y+x*math.sin(s.angle)+y*math.cos(s.angle)}
            if not G.cast(emitter,p,0,nil,true) then
                drawSheet(batch,cam,'shield-active',math.floor(G.now*12)%16,center,s.angle,
                    C.shieldRadius*.86/314,height/314,
                    C.shieldTextureOpacity*(.8+.2*energy)*(.95+.05*math.sin(G.now*5)),{strip/16,(strip+1)/16})
            end
        end
        for i=2,#points do
            if points[i-1].visible and points[i].visible then
                line(batch,cam,points[i-1].point,points[i].point,E.Color(45,195,230,math.floor(24*energy)),6)
                line(batch,cam,points[i-1].point,points[i].point,E.Color(110,235,250,math.floor(95*energy)),1)
            end
        end
    end
    function G.draw(batch,cam)
        if not cam then return end
        local rings,shields={},{}
        if G.authoritative then
            rings=G.rings
            for _,state in pairs(G.states) do
                if state.shield then
                    local s=state.shield
                    local source=G.source(state.item,0)
                    s.energy=source and source.condition or 0
                    shields[#shields+1]=s
                end
            end
        elseif G.now-(G.remote.received or -100)<.5 then rings=G.remote.rings;shields=G.remote.shields end
        for _,s in ipairs(shields) do drawShield(batch,cam,s) end
        for _,r in ipairs(rings) do
            if r.alive~=false then
                drawRing(batch,cam,r)
            end
        end
        for _,effect in ipairs(effects) do
            local f=math.floor(effect.age/.65*16)
            if f<16 then
                if effect.kind=='break' then
                    drawSheet(batch,cam,'shield-break',f,
                        {x=effect.x+C.shieldRadius*.75*math.cos(effect.angle),y=effect.y+C.shieldRadius*.75*math.sin(effect.angle)},
                        effect.angle,C.shieldRadius*.86/314,2*C.shieldRadius*math.sin(C.shieldHalfAngle)/314,.5)
                elseif effect.kind=='contact' then
                    drawSheet(batch,cam,'shield-contact',f,effect,effect.angle,.18,.18,.55)
                elseif effect.kind=='shieldhit' or effect.kind=='hit' or effect.kind=='bounce' or effect.kind=='wallhit' then
                    local size=effect.kind=='shieldhit' and .12 or .26
                    drawSheet(batch,cam,'shield-hit',f,effect,effect.angle,size,size,.8)
                    impactSparks(batch,cam,effect)
                elseif effect.kind=='arc' then
                    drawArc(batch,cam,effect)
                elseif effect.kind=='shot' and effect.age<.16 then
                    local fade=1-effect.age/.16
                    circle(batch,cam,effect.x,effect.y,effect.angle,7+effect.age*90,E.Color(90,225,255,math.floor(150*fade)),4)
                    circle(batch,cam,effect.x,effect.y,effect.angle,5+effect.age*55,E.Color(230,255,255,math.floor(255*fade)),2)
                elseif effect.kind=='charge' and effect.age<C.chargeTime then
                    circle(batch,cam,effect.x,effect.y,effect.angle,5+effect.age*35,E.Color(130,255,255,200),2)
                end
            end
        end
    end
    function G.clearVisuals() effects={};G.remote={shields={},rings={}} end
    -- DrawMap ends its batch before returning, and the HUD is drawn afterwards.
    -- This explicit native point avoids depending on historical draw aliases.
    G.patch('draw','Barotrauma.GameScreen','DrawMap',function(screen,p)
        if G.visualError then return end
        local batch=p['spriteBatch']
        -- The PNGs contain straight alpha. Default AlphaBlend expects
        -- premultiplied RGB and makes low-opacity energy sheets overbright.
        batch.Begin(sortMode.Deferred,blend.NonPremultiplied)
        local ok,err=pcall(G.draw,batch,screen.Cam)
        batch.End()
        if not ok then
            G.visualError=tostring(err)
            if E.printerror then E.printerror('[Aegis] Rendering failed: '..tostring(err)) end
        end
    end,true)
end
return M
