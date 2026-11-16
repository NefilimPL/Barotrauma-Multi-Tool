local C=require('DescendantSuit.config')
local Core=require('DescendantSuit.core')
local U=require('CombatTool.util')
local M={}
function M.install(G,E,root)
    local UI=E.GUI
    local gui=UI.GUI
    local atlas=E.Sprite(root..'/Assets/DescendantSuit/arm.png',E.Vector2(.5,.5))
    local sort=E.LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
    E.LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.BlendState')
    local blend=E.LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
    local rects={upper={270,60,435,145},lower={730,50,325,145},red={160,215,290,190},
        blue={615,215,290,190},orange={1075,215,290,190},rotor0={20,755,275,260},
        rotor1={325,755,275,260},rotor2={615,755,275,260},rotor3={910,755,275,260}}
    local colors={repair={75,190,255},weld={75,190,255},combat={255,45,45},grab={255,153,35}}
    local panel=UI.Frame(UI.RectTransform(E.Vector2(.22,.23),gui.Canvas,UI.Anchor.CenterRight),'GUIFrame')
    local function box(x,y,w,h)
        local t=UI.RectTransform(E.Vector2(w,h),panel.RectTransform,UI.Anchor.TopLeft,UI.Pivot.TopLeft)
        t.RelativeOffset=E.Vector2(x,y);return t
    end
    local function text(id) return tostring(E.TextManager.Get('descendant.'..id)) end
    UI.TextBlock(box(.05,.02,.9,.15),text('title'))
    local buttons={}
    for n,mode in ipairs({'off','repair','combat','grab'}) do
        local b=UI.Button(box(.05,.18+(n-1)*.15,.9,.14),text(mode))
        b.OnClicked=function()
            local owner=E.Character.Controlled;local item=G.equipped(owner)
            if item then G.requestMode(item,mode) end
            return true
        end
        buttons[mode]=b
    end
    local status=UI.TextBlock(box(.05,.80,.9,.16),'')
    panel.Visible=false
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
    local function screen(cam,p) return cam.WorldToScreen(E.Vector2(p.x,p.y)) end
    local function line(batch,cam,a,b,color,width)
        gui.DrawLine(batch,screen(cam,a),screen(cam,b),color,0,width*cam.Zoom)
    end
    local function sprite(batch,cam,key,point,rotation,scale,origin)
        local r=rects[key]
        atlas.SourceRect=E.Rectangle(r[1],r[2],r[3],r[4])
        atlas.Origin=origin or E.Vector2(r[3]/2,r[4]/2)
        atlas.Draw(batch,screen(cam,point),E.Color.White,atlas.Origin,rotation or 0,E.Vector2(scale*cam.Zoom,scale*cam.Zoom))
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
                    local r=open and {1295,45,240,260} or {1040,60,250,245}
                    w.Sprite.SourceRect=E.Rectangle(r[1],r[2],r[3],r[4]);w.Sprite.Origin=E.Vector2(r[3]/2,r[4]/2)
                end
            end) end
        end)
        s.drawOpen=open
    end
    function G.updateClient(dt)
        local controlled=E.Character.Controlled
        local equipped=G.equipped(controlled)
        panel.Visible=equipped~=nil
        if equipped then
            local s=G.state(equipped)
            for mode,b in pairs(buttons) do b.Selected=s.mode==mode end
            status.Text=text('power')..': '..math.floor(s.charge or G.energy(equipped))..'%  |  '..text(s.open and 'air' or 'tank')
            panel.AddToGUIUpdateList(false,8)
        end
        for item,s in pairs(G.states) do
            local owner=s.owner or G.owner(item)
            if item.Removed or not owner or G.equipped(owner)~=item or
                (not G.authoritative and s.received and G.now-s.received>.6) then
                local entry=channels[item]
                if entry then stop(entry.beam);stop(entry.motor);channels[item]=nil end
                G.states[item]=nil
            else
                helmet(owner,item,s.open==true)
                local entry=channels[item] or {};channels[item]=entry
                local active=s.active and s.target and s.target.kind
                loop(entry,'beam',active,owner);loop(entry,'motor',s.swimming and 'impeller' or nil,owner)
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
        for item,entry in pairs(channels) do if not G.states[item] then stop(entry.beam);stop(entry.motor);channels[item]=nil end end
    end
    local function draw(batch,cam)
        for item,s in pairs(G.states) do
            local owner=s.owner or G.owner(item)
            if owner and G.equipped(owner)==item then
                local base=G.mount(owner)
                local sp=screen(cam,base)
                local viewport=gui.Canvas.Rect
                if sp.X> -300 and sp.Y> -300 and sp.X<viewport.Width+300 and sp.Y<viewport.Height+300 then
                    local facing=owner.AnimController.Dir<0 and -1 or 1
                    local goal={x=base.x+facing*24,y=base.y+20}
                    local target=s.target
                    if target then
                        if target.entity and not target.entity.Removed and target.kind~='weld' then target.point=U.point(target.entity.WorldPosition) end
                        local dx,dy=target.point.x-base.x,target.point.y-base.y
                        local d=math.sqrt(dx*dx+dy*dy)
                        local distance=math.max(8,math.min(C.reach,d-8))
                        if d>1e-5 then goal={x=base.x+dx/d*distance,y=base.y+dy/d*distance} end
                    end
                    local elapsed=math.min(.1,math.max(0,G.now-(s.drawTime or G.now)))
                    local weight=s.drawGoal and (1-math.exp(-12*elapsed)) or 1
                    local old=s.drawGoal or goal
                    s.drawGoal={x=old.x+(goal.x-old.x)*weight,y=old.y+(goal.y-old.y)*weight};s.drawTime=G.now
                    local pose=Core.pose(base,s.drawGoal,facing)
                    link(batch,cam,'upper',base,pose.elbow,310,E.Vector2(65,75))
                    link(batch,cam,'lower',pose.elbow,pose.tip,230,E.Vector2(65,75))
                    local point=target and target.point or {x=pose.tip.x+facing,y=pose.tip.y}
                    local angle=-math.atan2(point.y-pose.tip.y,point.x-pose.tip.x)
                    local colorKey=target and (target.kind=='combat' and 'red' or target.kind=='grab' and 'orange' or 'blue') or 'blue'
                    sprite(batch,cam,colorKey,pose.tip,angle,.12,E.Vector2(82,95))
                    local motor={x=base.x-facing*5,y=base.y-38}
                    sprite(batch,cam,'rotor'..(s.swimming and math.floor(G.now*18)%4 or 0),motor,0,.12)
                    local short=not target or (target.kind~='repair' and target.kind~='weld') or
                        (target.point.x-pose.tip.x)^2+(target.point.y-pose.tip.y)^2<=(C.repairBeam+2)^2
                    if target and s.active and short then
                        local col=colors[target.kind]
                        line(batch,cam,pose.tip,target.point,E.Color(col[1],col[2],col[3],40),7)
                        line(batch,cam,pose.tip,target.point,E.Color(col[1],col[2],col[3],210),2)
                        line(batch,cam,pose.tip,target.point,E.Color(235,250,255,240),.6)
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
    G.patch('draw','Barotrauma.GameScreen','DrawMap',function(screenObj,p)
        if G.drawError then return end
        local batch=p['spriteBatch'];batch.Begin(sort.Deferred,blend.NonPremultiplied)
        local ok,err=pcall(draw,batch,screenObj.Cam);batch.End()
        if not ok then G.drawError=tostring(err);E.printerror('[Descendant suit] Render: '..tostring(err)) end
    end,true)
    function G.pauseClient()
        for _,entry in pairs(channels) do stop(entry.beam);stop(entry.motor) end
        channels={}
    end
    function G.clearClient()
        for _,entry in pairs(channels) do stop(entry.beam);stop(entry.motor) end
        channels={};panel.Visible=false
    end
    function G.disposeClient()
        panel.Visible=false;panel.RemoveFromGUIUpdateList();panel.RectTransform.Parent=nil;atlas.Remove()
    end
end
return M
