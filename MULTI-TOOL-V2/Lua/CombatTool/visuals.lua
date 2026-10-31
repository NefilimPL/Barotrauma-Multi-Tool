local U=require('CombatTool.util')
local C=require('CombatTool.config')
local Core=require('CombatTool.core')
local M={}
function M.install(G,E,root)
    -- Current LuaCs exposes GUI drawing under GUI.GUI. Sprite.Draw supplies
    -- SpriteEffects.None by default; the optional global enum may be absent.
    local gui=type(E.GUI)=='table' and E.GUI.GUI or E.GUI
    local assets={}
    for _,name in ipairs({'shield-active','shield-hit','shield-break','shield-contact'}) do
        assets[name]=E.Sprite(root..'/Assets/Combat/'..name..'.png',E.Vector2(.5,.5))
    end
    local effects={}
    function G.onEffect(kind,point,angle,id)
        effects[#effects+1]={kind=kind,x=point.x,y=point.y,angle=angle,age=0,id=id}
        if #effects>256 then table.remove(effects,1) end
    end
    function G.updateVisuals(dt)
        if not G.authoritative and G.now-(G.remote.received or -100)<.3 then
            for _,ring in ipairs(G.remote.rings) do
                Core.advanceRing(ring,dt,function(a,b,r) return G.cast(a,b,r.radius,nil,true) end)
            end
        end
        for i=#effects,1,-1 do
            effects[i].age=effects[i].age+dt
            if effects[i].age>.8 then table.remove(effects,i) end
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
    local function drawSheet(batch,cam,name,index,point,angle,sx,sy,alpha)
        local sprite=assets[name]
        local origin=frame(sprite,index)
        local screen=cam.WorldToScreen(E.Vector2(point.x,point.y))
        sprite.Draw(batch,screen,E.Color(255,255,255,math.floor(255*(alpha or 1))),origin,-angle,
            E.Vector2(sx*cam.Zoom,sy*cam.Zoom))
    end
    local function line(batch,cam,a,b,color,width)
        gui.DrawLine(batch,cam.WorldToScreen(E.Vector2(a.x,a.y)),cam.WorldToScreen(E.Vector2(b.x,b.y)),color,0,math.max(1,math.floor(width*cam.Zoom+.5)))
    end
    local function circle(batch,cam,x,y,angle,radius,color,width)
        local previous=nil
        for i=0,24 do
            local a=i*math.pi/12
            local ux,uy=math.cos(a)*radius*.45,math.sin(a)*radius
            local p={x=x+ux*math.cos(angle)-uy*math.sin(angle),y=y+ux*math.sin(angle)+uy*math.cos(angle)}
            if previous then line(batch,cam,previous,p,color,width) end
            previous=p
        end
    end
    local function drawShield(batch,cam,s)
        local visible,points=true,{}
        local emitter={x=s.x+25*math.cos(s.angle),y=s.y+25*math.sin(s.angle)}
        for i=0,24 do
            local a=s.angle-C.shieldHalfAngle+2*C.shieldHalfAngle*i/24
            local p={x=s.x+math.cos(a)*C.shieldRadius,y=s.y+math.sin(a)*C.shieldRadius}
            local blocked=G.cast(emitter,p,0,nil,true)
            points[#points+1]={point=p,visible=blocked==nil}
            if blocked then visible=false end
        end
        local energy=math.max(.15,math.min(1,(s.energy or 100)/100))
        if visible then
            drawSheet(batch,cam,'shield-active',math.floor(G.now*18)%16,
                {x=s.x+70*math.cos(s.angle),y=s.y+70*math.sin(s.angle)},s.angle,.4,.535,.5+.4*energy)
        end
        for i=2,#points do
            if points[i-1].visible and points[i].visible then
                line(batch,cam,points[i-1].point,points[i].point,E.Color(45,230,255,math.floor(220*energy)),2)
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
                    local source=G.source(state.item,1)
                    s.energy=source and source.condition or 0
                    shields[#shields+1]=s
                end
            end
        elseif G.now-(G.remote.received or -100)<.5 then rings=G.remote.rings;shields=G.remote.shields end
        for _,s in ipairs(shields) do drawShield(batch,cam,s) end
        for _,r in ipairs(rings) do
            if r.alive~=false then
            local angle=math.atan2 and math.atan2(r.dy,r.dx) or math.atan(r.dy,r.dx)
            circle(batch,cam,r.x,r.y,angle,r.radius+2,E.Color(0,140,240,100),5)
            circle(batch,cam,r.x,r.y,angle,r.radius,E.Color(170,255,255,255),2)
            end
        end
        for _,effect in ipairs(effects) do
            local f=math.floor(effect.age/.65*16)
            if f<16 then
                if effect.kind=='break' then
                    drawSheet(batch,cam,'shield-break',f,{x=effect.x+70*math.cos(effect.angle),y=effect.y+70*math.sin(effect.angle)},effect.angle,.4,.535)
                elseif effect.kind=='contact' then
                    drawSheet(batch,cam,'shield-contact',f,effect,effect.angle,.3,.3)
                elseif effect.kind=='shieldhit' or effect.kind=='hit' or effect.kind=='bounce' or effect.kind=='shot' then
                    drawSheet(batch,cam,'shield-hit',f,effect,effect.angle,.2,.2)
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
        batch.Begin()
        local ok,err=pcall(G.draw,batch,screen.Cam)
        batch.End()
        if not ok then
            G.visualError=tostring(err)
            if E.printerror then E.printerror('[Aegis] Rendering failed: '..tostring(err)) end
        end
    end,true)
end
return M
