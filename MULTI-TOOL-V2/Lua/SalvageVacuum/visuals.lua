local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E,root)
    local gui=type(E.GUI)=='table' and E.GUI.GUI or E.GUI
    local sort=E.LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
    E.LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.BlendState')
    local blend=E.LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
    local backpack=E.Sprite(root..'/Assets/Vacuum/backpack.png',E.Vector2(.5,.5))
    local stream=E.Sprite(root..'/Assets/Vacuum/suction.png',E.Vector2(1,.5))
    local effects={}
    function G.onTransfer(id,point) effects[#effects+1]={id=id,x=point.x,y=point.y,age=0} end
    function G.updateVisuals(dt)
        for i=#effects,1,-1 do effects[i].age=effects[i].age+dt;if effects[i].age>.4 then table.remove(effects,i) end end
    end
    local function screen(cam,p) return cam.WorldToScreen(E.Vector2(p.x,p.y)) end
    local function line(batch,cam,a,b,color,width)
        gui.DrawLine(batch,screen(cam,a),screen(cam,b),color,0,width*cam.Zoom)
    end
    local function draw(batch,cam)
        for item,state in pairs(G.states) do
            local ctx=G.context(item)
            if ctx.valid then
                local torso
                U.each(ctx.owner.AnimController.Limbs,function(limb)
                    if limb.type==E.LimbType.Torso and not limb.IsSevered then torso=limb end
                end)
                if torso and torso.body and item.body then
                    torso.body.UpdateDrawPosition();item.body.UpdateDrawPosition()
                    local pos=torso.body.DrawPosition
                    local facing=torso.body.Dir<0 and -1 or 1
                    local angle=-torso.body.DrawRotation
                    local mount={x=pos.X-facing*16*math.cos(angle),y=pos.Y+facing*16*math.sin(angle)-3}
                    -- Equipped packs use their native Wearable sprite, including without the nozzle.
                    if ctx.owner.Inventory.GetItemInLimbSlot(E.InvSlotType.Bag)~=ctx.pack then
                        backpack.Draw(batch,screen(cam,mount),E.Color.White,backpack.Origin,angle,E.Vector2(.041*facing*cam.Zoom,.041*cam.Zoom))
                    end
                    local rear=U.point(item.body.DrawPosition)
                    local origin=G.muzzle(item)
                    local mid={x=(mount.x+rear.x)*.5,y=math.min(mount.y,rear.y)-22}
                    local previous=mount
                    for n=1,12 do
                        local t=n/12
                        local p={x=(1-t)^2*mount.x+2*(1-t)*t*mid.x+t*t*rear.x,
                            y=(1-t)^2*mount.y+2*(1-t)*t*mid.y+t*t*rear.y}
                        line(batch,cam,previous,p,E.Color(18,24,29,255),4)
                        line(batch,cam,previous,p,E.Color(67,83,89,255),1)
                        previous=p
                    end
                    local active=ctx.aim and G.charge(item)>0 and
                        (G.now-(state.usedAt or -100)<.15 or (G.remoteActiveUntil[item.ID] or 0)>G.now)
                    if active then
                        local direction,rotation=G.direction(item)
                        -- Sheet points left-to-right; rotate its inlet to face the nozzle.
                        local frame=math.floor(G.now*16)%16
                        local col,row=frame%4,math.floor(frame/4)
                        local x,y=math.floor(col*1451/4),math.floor(row*1084/4)
                        local right,bottom=math.floor((col+1)*1451/4),math.floor((row+1)*1084/4)
                        stream.SourceRect=E.Rectangle(x,y,right-x,bottom-y)
                        stream.Origin=E.Vector2(right-x,(bottom-y)/2)
                        stream.Draw(batch,screen(cam,origin),E.Color(150,240,255,95),stream.Origin,-rotation+math.pi,
                            E.Vector2(C.range/(right-x)*cam.Zoom,.35*cam.Zoom))
                    end
                end
            end
        end
        for _,effect in ipairs(effects) do
            local item=E.Entity.FindEntityByID(effect.id)
            if item and not item.Removed then
                local endPoint=G.muzzle(item)
                local t=effect.age/.4
                local p={x=effect.x+(endPoint.x-effect.x)*t*t,y=effect.y+(endPoint.y-effect.y)*t*t}
                local color=E.Color(120,240,255,math.floor(220*(1-t)))
                line(batch,cam,{x=p.x-3,y=p.y}, {x=p.x+3,y=p.y},color,2)
                line(batch,cam,{x=p.x,y=p.y-3}, {x=p.x,y=p.y+3},color,2)
            end
        end
    end
    G.draw=draw
    G.patch('draw','Barotrauma.GameScreen','DrawMap',function(screenObj,p)
        if G.visualError then return end
        local batch=p['spriteBatch']
        batch.Begin(sort.Deferred,blend.NonPremultiplied)
        local ok,err=pcall(draw,batch,screenObj.Cam)
        batch.End()
        if not ok then G.visualError=tostring(err);E.printerror('[Aegis Vacuum] Render: '..tostring(err)) end
    end,true)
    function G.disposeVisuals() backpack.Remove();stream.Remove();effects={} end
end
return M
