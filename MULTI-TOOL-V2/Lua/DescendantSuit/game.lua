local Core=require('DescendantSuit.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
function M.new(E)
    local G={env=E,authoritative=E.SERVER or E.Game.IsSingleplayer,states={},now=0,alive=true,patches={}}
    local humanAI
    local dynamicBodyType
    local function movable(body)
        dynamicBodyType=dynamicBodyType or E.LuaUserData.CreateEnumTable('FarseerPhysics.BodyType').Dynamic
        return body.BodyType==dynamicBodyType
    end
    function G.ally(a,b)
        humanAI=humanAI or E.LuaUserData.CreateStatic('Barotrauma.HumanAIController')
        return humanAI.IsFriendly(a,b,false,false)
    end
    function G.is(item) return item and not item.Removed and U.itemId(item)==C.identifier end
    function G.owner(item)
        local owner=item and item.ParentInventory and item.ParentInventory.Owner
        return owner and E.LuaUserData.IsTargetType(owner,'Barotrauma.Character') and owner or nil
    end
    function G.equipped(owner)
        if not owner or owner.Removed or owner.IsDead or not owner.Inventory then return end
        local item=owner.Inventory.GetItemInLimbSlot(E.InvSlotType.OuterClothes)
        if G.is(item) and item.Condition>0 then return item end
    end
    function G.state(item)
        if not G.states[item] then G.states[item]={item=item,mode='off',nextScan=0} end
        return G.states[item]
    end
    function G.container(item,index)
        local c=U.component(item,'ItemContainer',index)
        return c and c.Inventory
    end
    function G.source(item)
        local inv=G.container(item,1)
        local source=inv and inv.GetItemAt(0)
        if source and not source.Removed and source.MaxCondition>0 and
            (source.HasTag('mobilebattery') or source.HasTag('reactorfuel')) then return source end
    end
    function G.ammo(item)
        local inv=G.container(item,1)
        local box=inv and inv.GetItemAt(1)
        if box and not box.Removed and box.MaxCondition>0 and box.HasTag('pulselaserammo') then return box end
    end
    function G.energy(item)
        local s=G.source(item)
        return s and Core.charge(s.Condition,s.MaxCondition,true) or 0
    end
    function G.spend(item,cost)
        local source=G.source(item)
        if not source then return 0 end
        cost=cost*(source.HasTag('reactorfuel') and C.rodMultiplier or 1)
        local value,fraction=Core.debit(G.energy(item),cost)
        source.Condition=value*source.MaxCondition/100
        return fraction
    end
    function G.air(owner)
        local anim=owner.AnimController
        local hull=anim and anim.CurrentHull
        return {hull=hull~=nil,wet=not anim or anim.HeadInWater,
            oxygen=hull and hull.OxygenPercentage or 0,pressure=hull and hull.LethalPressure or 100}
    end
    function G.breathe(owner,item,dt)
        local s=G.state(item)
        local air=G.air(owner)
        s.open=Core.breathable(air)
        owner.UseHullOxygen=s.open
        if s.open then owner.OxygenAvailable=air.oxygen;return end
        local usable=G.energy(item)>0
        owner.OxygenAvailable=usable and 100 or 0
        if G.authoritative and usable and owner.NeedsAir and not owner.IsDead then
            G.spend(item,C.lifeSupportRate*math.min(dt,.1))
        end
    end
    function G.attachment(owner,x,y,draw)
        local anim=owner.AnimController
        local torso=anim and anim.GetLimb and E.LimbType and anim.GetLimb(E.LimbType.Torso)
        local p,rotation=owner.WorldPosition,0
        local facing=anim and anim.Dir or 1
        if torso and torso.body then
            local body=torso.body
            facing=body.Dir
            if draw then
                body.UpdateDrawPosition();p=body.DrawPosition;rotation=body.DrawRotation
            else p=torso.WorldPosition;rotation=body.Rotation end
        end
        facing=facing<0 and -1 or 1
        local rx=x*facing
        return {x=p.X+rx*math.cos(rotation)-y*math.sin(rotation),
            y=p.Y+rx*math.sin(rotation)+y*math.cos(rotation)},rotation,facing
    end
    function G.mount(owner,draw)
        return G.attachment(owner,-22,18,draw)
    end
    function G.restGoal(owner,draw)
        return G.attachment(owner,10,88,draw)
    end
    local function position(entity)
        local p=entity.WorldPosition;return {x=p.X,y=p.Y}
    end
    function G.visible(owner,base,t)
        local hit=G.cast(base,t.point,0,owner,t.kind~='combat',true)
        if not hit then return true end
        if hit.kind=='character' then return hit.target==t.entity end
        if t.kind=='weld' then
            if hit.blocker~=t.entity then return false end
            local dx,dy=t.point.x-base.x,t.point.y-base.y
            local length=math.sqrt(dx*dx+dy*dy)
            if length<1e-6 then return false end
            local inside=E.Vector2(hit.x+dx/length*.5,hit.y+dy/length*.5)
            if t.entity.FindSectionIndex(inside,true,false)~=t.section then return false end
            t.point={x=hit.x,y=hit.y}
            return true
        end
        return false
    end
    function G.body(target)
        if not target then return end
        if E.LuaUserData.IsTargetType(target,'Barotrauma.Character') then
            local anim=target.AnimController
            if anim.Collider and anim.Collider.Enabled then return anim.Collider end
            return anim.MainLimb and anim.MainLimb.body or anim.Collider
        end
        return target.body
    end
    function G.portable(item)
        if not item or item.Removed or item.ParentInventory or not item.body or not item.body.Enabled then return false end
        if not movable(item.body) or U.component(item,'Door') then return false end
        local wire=U.component(item,'Wire')
        if wire then
            local connected=false
            if type(wire.Connections)=='table' then
                for _,connection in pairs(wire.Connections) do if connection then connected=true end end
            else U.each(wire.Connections,function(connection) if connection then connected=true end end) end
            U.each(wire.GetNodes(),function() connected=true end)
            if connected then return false end
        end
        local attached=false
        U.each(item.Components,function(component)
            if E.LuaUserData.IsTargetType(component,'Barotrauma.Items.Components.Pickable') and component.IsAttached then attached=true end
        end)
        return not attached
    end
    function G.grabbable(target)
        if not target or target.Removed then return false end
        local body=G.body(target)
        if not body or not body.Enabled or not movable(body) then return false end
        local character=E.LuaUserData.IsTargetType(target,'Barotrauma.Character')
        if not character and not G.portable(target) then return false end
        local mass=character and target.Mass or body.Mass
        return type(mass)=='number' and mass>0 and mass<=C.maxGrabMass
    end
    function G.gather(owner,s)
        local targets,base={},G.mount(owner)
        local automatic=owner.IsBot
        local function add(t,range)
            local dx,dy=t.point.x-base.x,t.point.y-base.y
            t.distance=math.sqrt(dx*dx+dy*dy)
            local bound=range
            if t.kind=='weld' then bound=bound+math.sqrt(t.entity.Rect.Width^2+t.entity.Rect.Height^2) end
            if t.distance<=bound then
                t.visible=G.visible(owner,base,t)
                t.distance=math.sqrt((t.point.x-base.x)^2+(t.point.y-base.y)^2)
                if t.distance<=range then
                    if t.kind=='grab' and not Core.grabAllowed(s,t.id,G.now) then t.free=false end
                    targets[#targets+1]=t
                end
            end
        end
        if automatic or s.mode=='repair' then
            U.each(E.Util.GetItemGroup('bmt.descendant.repairables'),function(item)
                if not item.Removed and item.Condition<item.MaxCondition-.01 and not item.ParentInventory
                    and (not item.HasAccess or item.HasAccess(owner)) then
                    add({id='i'..item.ID,kind='repair',entity=item,point=position(item),damaged=true},C.reach+C.repairBeam)
                end
            end)
            U.each(E.Structure.WallList,function(wall)
                if not wall.Removed and wall.HasBody and not wall.Indestructible and not wall.Prefab.Platform then
                    local p=wall.WorldPosition
                    if math.abs(p.X-base.x)<C.reach+C.repairBeam+wall.Rect.Width and
                        math.abs(p.Y-base.y)<C.reach+C.repairBeam+wall.Rect.Height then
                        for section=0,wall.SectionCount-1 do
                            if wall.SectionDamage(section)>.01 then
                                local q=wall.SectionPosition(section,true)
                                add({id='w'..wall.ID..':'..section,kind='weld',entity=wall,section=section,
                                    point={x=q.X,y=q.Y},damaged=true,emergency=wall.GetSection(section).gap~=nil},C.reach+C.repairBeam)
                            end
                        end
                    end
                end
            end)
        end
        if automatic or s.mode=='combat' or s.mode=='grab' then
            U.each(E.Character.CharacterList,function(other)
                if other~=owner and not other.Removed then
                    local friendly=G.ally(owner,other)
                    if not friendly and not other.IsDead and (automatic or s.mode=='combat') then
                        add({id='c'..other.ID,kind='combat',entity=other,point=position(other),hostile=true,alive=true},C.combatRange)
                    end
                    if automatic or s.mode=='grab' then
                        if G.grabbable(other) then
                            add({id='g'..other.ID,kind='grab',entity=other,point=position(other),free=true,
                                rescue=friendly and other.IsUnconscious},C.grabRange)
                        end
                    end
                end
            end)
        end
        if s.mode=='grab' and not automatic then
            -- World-item enumeration is only needed when acquiring an indicated grab.
            if not s.target then U.each(E.Item.ItemList,function(item)
                if G.grabbable(item) then
                    add({id='g'..item.ID,kind='grab',entity=item,point=position(item),free=true},C.grabRange)
                end
            end)
            elseif s.target.kind=='grab' and not s.target.entity.Removed then
                local t=s.target
                t.point=position(t.entity);t.free=G.grabbable(t.entity)
                add(t,C.grabRange)
            end
        end
        return targets
    end
    function G.perform(owner,item,target,dt)
        if target.kind=='repair' then return G.repairDevice and G.repairDevice(owner,item,target,dt) or false end
        if target.kind=='combat' then return G.firePulse and G.firePulse(owner,item,target) or false end
        if target.kind=='grab' and not G.grabbable(target.entity) then return false end
        local fraction=G.spend(item,(C.rates[target.kind] or 0)*dt)
        if fraction<=0 then return false end
        local elapsed=dt*fraction
        if target.kind=='weld' then
            if G.weld then G.weld(owner,item,target,elapsed)
            else target.entity.AddDamage(target.section,-C.weldRate*elapsed,owner,false,false) end
        elseif target.kind=='grab' then
            local body=G.body(target.entity)
            if not body then return false end
            local p=owner.WorldPosition
            local dx,dy=(p.X-target.point.x)/100,(p.Y-target.point.y)/100
            local distance=math.sqrt(dx*dx+dy*dy)
            if distance>.6 then
                local v=body.LinearVelocity
                local magnitude=math.min(C.grabForce,distance*C.grabForce)*body.Mass*fraction
                body.ApplyForce(E.Vector2(dx/distance*magnitude-v.X*body.Mass*2,
                    dy/distance*magnitude-v.Y*body.Mass*2),C.grabSpeed)
            end
        end
        return true
    end
    function G.patch(name,class,method,fn,after,types)
        local id='bmt.descendant.'..name
        local phase=after and E.Hook.HookMethodType.After or E.Hook.HookMethodType.Before
        if types then E.Hook.Patch(id,class,method,types,fn,phase) else E.Hook.Patch(id,class,method,fn,phase) end
        G.patches[#G.patches+1]={id,class,method,phase,types}
    end
    function G.setMode(item,mode,owner)
        if G.equipped(owner)~=item or owner.IsUnconscious then return false end
        if mode=='toggle' then return Core.toggle(G.state(item)) end
        return Core.setMode(G.state(item),mode)
    end
    function G.authorize(client,item,mode)
        return client and client.Character and G.setMode(item,mode,client.Character) or false
    end
    function G.update(dt)
        if E.Game.Paused then if G.pauseClient then G.pauseClient() end;return end
        G.now=G.now+dt
        if G.authoritative and E.Game.RoundStarted then
            if G.now>=(G.nextOwners or 0) then
                G.nextOwners=G.now+.25
                U.each(E.Util.GetItemsById(C.identifier),function(item)
                    local owner=G.owner(item)
                    if G.equipped(owner)==item then local s=G.state(item);s.owner=owner end
                end)
            end
            for item,s in pairs(G.states) do
                local owner=G.owner(item)
                if G.equipped(owner)~=item then
                    if G.cancelSupplies then G.cancelSupplies(s) end
                    G.states[item]=nil
                else
                    if s.owner and s.owner~=owner and G.cancelSupplies then G.cancelSupplies(s) end
                    s.owner=owner;s.active=false;s.swimming=false
                    if G.updateSupplies then G.updateSupplies(owner,item,s) end
                    if owner.IsUnconscious then s.target=nil
                    else
                        local powered=G.energy(item)>0
                        if powered then G.spend(item,C.lightRate*dt) end
                        Core.expireGrab(s,G.now)
                        local held=not owner.IsBot and s.mode=='grab' and owner.IsKeyDown(E.InputType.Aim) and owner.IsKeyDown(E.InputType.Use)
                        if Core.grabPress(s,held) then
                            if s.target then s.target=nil;s.grabStarted=nil
                            else s.acquireGrab=true;s.nextScan=0 end
                        end
                        if G.now>=s.nextScan and (owner.IsBot or s.mode~='off') and powered then
                            s.nextScan=G.now+C.scanInterval
                            local candidates=G.gather(owner,s)
                            if owner.IsBot then
                                local old=s.target
                                local mode,target=Core.ai(candidates)
                                Core.setMode(s,mode);s.target=target
                                if target and target.kind=='grab' and (not old or old.id~=target.id) then s.grabStarted=G.now end
                            elseif s.mode~='grab' then s.target=Core.choose(s.mode,candidates,s.target and s.target.id)
                            elseif s.target then s.target=Core.choose('grab',candidates,s.target.id)
                            else
                                if s.acquireGrab then
                                    s.acquireGrab=false
                                    local cursor=owner.CursorWorldPosition
                                    local aim=owner.AimRefPosition
                                    if owner.Submarine then aim=aim+owner.Submarine.Position end
                                    s.target=Core.aimGrab({x=aim.X,y=aim.Y},{x=cursor.X,y=cursor.Y},candidates)
                                    s.grabStarted=G.now
                                end
                            end
                        end
                        local target=s.target
                        if target and not target.entity.Removed and powered then
                            if target.kind~='weld' then target.point=position(target.entity)
                            else local q=target.entity.SectionPosition(target.section,true);target.point={x=q.X,y=q.Y} end
                            local base=G.mount(owner)
                            target.visible=G.visible(owner,base,target)
                            target.distance=math.sqrt((target.point.x-base.x)^2+(target.point.y-base.y)^2)
                            if target.kind=='repair' then target.damaged=target.entity.Condition<target.entity.MaxCondition-.01 end
                            if target.kind=='weld' then target.damaged=target.entity.SectionDamage(target.section)>.01 end
                            if target.kind=='combat' then target.alive=not target.entity.IsDead;target.hostile=not G.ally(owner,target.entity) end
                            if target.kind=='grab' then
                                target.free=G.grabbable(target.entity)
                                s.grabStarted=s.grabStarted or G.now
                            end
                            if target and Core.choose(s.mode,{target},target.id) then
                                if Core.ready(s,target.id,G.now) then s.active=G.perform(owner,item,target,dt) end
                            else s.target=nil end
                        elseif not powered then s.target=nil end
                        if not s.target then Core.ready(s,nil,G.now) end
                        local anim=owner.AnimController
                        if powered and anim.InWater and anim.TargetMovement then
                            local movement=anim.TargetMovement
                            local length=math.sqrt(movement.X^2+movement.Y^2)
                            if length>.1 and anim.Collider then
                                local paid=G.spend(item,C.rates.swim*dt)
                                if paid>0 then
                                    anim.Collider.ApplyForce(E.Vector2(movement.X/length,movement.Y/length)*anim.Collider.Mass*C.swimForce*paid,C.swimSpeed)
                                    s.swimming=true
                                end
                            end
                        end
                    end
                end
            end
            if G.sendSnapshot then G.sendSnapshot() end
            if G.pruneRepairs then G.pruneRepairs() end
        end
        if G.updateClient then G.updateClient(dt) end
    end
    function G.clear()
        if G.clearRepairs then G.clearRepairs() end
        if G.clearSupplies then G.clearSupplies() end
        if G.clearClient then G.clearClient() end
        G.states={};G.nextOwners=0
    end
    function G.dispose()
        if not G.alive then return end
        G.alive=false;G.clear()
        E.Hook.Remove('think','bmt.descendant.update');E.Hook.Remove('roundEnd','bmt.descendant.reset')
        E.Hook.Remove('stop','bmt.descendant.dispose')
        for _,p in ipairs(G.patches) do
            if p[5] then E.Hook.RemovePatch(p[1],p[2],p[3],p[5],p[4]) else E.Hook.RemovePatch(p[1],p[2],p[3],p[4]) end
        end
        if G.disposeClient then G.disposeClient() end
    end
    function G.install()
        if G.authoritative then
            E.Util.RegisterItemGroup('bmt.descendant.repairables',function(item) return U.component(item,'Repairable')~=nil end)
        end
        G.patch('breathing','Barotrauma.Character','UpdateOxygen',function(owner,p)
            local item=G.equipped(owner)
            if item then G.breathe(owner,item,p['deltaTime']) end
        end)
        E.Hook.Add('think','bmt.descendant.update',function() if G.alive then G.update(1/60) end end)
        E.Hook.Add('roundEnd','bmt.descendant.reset',G.clear)
        E.Hook.Add('stop','bmt.descendant.dispose',G.dispose)
    end
    return G
end
return M
