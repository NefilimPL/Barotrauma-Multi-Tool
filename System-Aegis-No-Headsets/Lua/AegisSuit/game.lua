local Core=require('AegisSuit.core')
local C=Core.config
local U=require('AegisCombat.util')
local Ammo=require('AegisSuit.ammo')
local Factions=require('AegisSuit.factions')
local M={}
function M.new(E)
    local G={env=E,authoritative=E.SERVER or E.Game.IsSingleplayer,states={},now=0,alive=true,patches={}}
    local humanAI
    local dynamicBodyType
    local transforms
    local function movable(body)
        dynamicBodyType=dynamicBodyType or E.LuaUserData.CreateEnumTable('FarseerPhysics.BodyType').Dynamic
        return body.BodyType==dynamicBodyType
    end
    function G.ally(a,b)
        humanAI=humanAI or E.LuaUserData.CreateStatic('Barotrauma.HumanAIController')
        return humanAI.IsFriendly(a,b,false,false)
    end
    function G.is(item) return item and not item.Removed and Factions.is(item,'suit') end
    function G.eachSuit(fn)
        for _,identifier in ipairs(Factions.suitIds) do U.each(E.Util.GetItemsById(identifier),fn) end
    end
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
        if source and not source.Removed and source.MaxCondition>0 and source.HasTag('mobilebattery') then return source end
    end
    function G.ammo(item)
        local inv=G.container(item,1)
        local box=inv and inv.GetItemAt(1)
        local profile=Ammo.profile(box)
        if profile then return box,profile end
    end
    function G.energy(item)
        local s=G.source(item)
        return s and Core.charge(s.Condition,s.MaxCondition,true) or 0
    end
    function G.spend(item,cost)
        local source=G.source(item)
        if not source then return 0 end
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
    function G.tank(item)
        local inv=G.container(item,1)
        local tank=inv and inv.GetItemAt(C.tankSlot)
        if tank and not tank.Removed and tank.MaxCondition>0 and tank.HasTag('oxygensource') then return tank end
    end
    function G.breathe(owner,item,dt)
        local s=G.state(item)
        local air=G.air(owner)
        s.open=Core.breathable(air)
        owner.UseHullOxygen=s.open
        local tank=G.tank(item)
        owner.OxygenAvailable=s.open and air.oxygen or (tank and tank.Condition>0 and 100 or 0)
        if not G.authoritative or not tank or owner.IsDead then return end
        dt=math.min(dt,.1)
        if s.open then
            if not tank.HasTag('refillableoxygensource') or not G.module(item,'compressor') then return end
            local missing=1-tank.Condition/tank.MaxCondition
            local seconds=math.min(dt,missing*100/C.tankRefillRate)
            if seconds<=0 then return end
            local fraction=G.spend(item,C.compressorPowerRate*seconds)
            if fraction>0 then
                tank.Condition=math.min(tank.MaxCondition,tank.Condition+tank.MaxCondition*C.tankRefillRate/100*seconds*fraction)
            end
        elseif owner.NeedsAir and tank.Condition>0 then
            tank.Condition=math.max(0,tank.Condition-C.tankUseRate*dt)
        end
    end
    function G.attachment(owner,x,y,draw)
        local cached=not draw and transforms and transforms[owner]
        if cached then
            local rx=x*cached.facing
            return {x=cached.x+rx*cached.cosine-y*cached.sine,
                y=cached.y+rx*cached.sine+y*cached.cosine},cached.rotation,cached.facing
        end
        local anim=owner.AnimController
        local torso=anim and anim.GetLimb and E.LimbType and anim.GetLimb(E.LimbType.Torso)
        local p,rotation,facing=nil,0,anim and anim.Dir or 1
        if torso and torso.body then
            local body=torso.body
            facing=body.Dir
            if draw then
                body.UpdateDrawPosition();p=body.DrawPosition;rotation=body.DrawRotation
            else p=torso.WorldPosition;rotation=body.Rotation end
        else p=owner.WorldPosition end
        facing=facing<0 and -1 or 1
        local cosine,sine=math.cos(rotation),math.sin(rotation)
        if not draw and transforms then
            transforms[owner]={x=p.X,y=p.Y,rotation=rotation,facing=facing,cosine=cosine,sine=sine}
        end
        local rx=x*facing
        return {x=p.X+rx*cosine-y*sine,y=p.Y+rx*sine+y*cosine},rotation,facing
    end
    function G.mount(owner,draw)
        return G.attachment(owner,-22,18,draw)
    end
    function G.restGoal(owner,draw,base,rotation,facing)
        if base then
            local x,y=32*facing,70
            local cosine,sine=math.cos(rotation),math.sin(rotation)
            return {x=base.x+x*cosine-y*sine,y=base.y+x*sine+y*cosine}
        end
        return G.attachment(owner,10,88,draw)
    end
    function G.toolPose(owner,state,draw,point)
        local base,rotation,facing=G.mount(owner,draw)
        local angles=draw and not G.authoritative and (state.drawAngles or state.toolAngles) or state.toolAngles
        if angles then
            local key=draw and 'drawPose' or 'simPose'
            local cached=state[key]
            if cached and cached.owner==owner and cached.x==base.x and cached.y==base.y and
                cached.rotation==rotation and cached.upper==angles.upper and
                cached.lower==angles.lower and cached.head==angles.head then return cached.pose end
            local pose=require('AegisSuit.motion').pose(base,rotation,angles)
            cached=cached or {}
            cached.owner,cached.x,cached.y,cached.rotation=owner,base.x,base.y,rotation
            cached.upper,cached.lower,cached.head,cached.pose=angles.upper,angles.lower,angles.head,pose
            state[key]=cached
            return pose
        end
        return Core.toolPose(base,point or (state.target and state.target.point),G.restGoal(owner,draw,base,rotation,facing),facing,rotation)
    end
    local function position(entity)
        local p=entity.WorldPosition;return {x=p.X,y=p.Y}
    end
    local function grabLimb(limb)
        return limb and not limb.IsSevered and not limb.Hidden and limb.body and limb.body.Enabled
    end
    function G.repairEligible(owner,item)
        return item and not item.Removed and not item.ParentInventory and
            (not item.HasAccess or item.HasAccess(owner))
    end
    function G.visible(owner,base,t)
        local hit=G.cast(base,t.point,0,owner,t.kind~='combat',true,t.kind=='grab' and t.entity or nil)
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
    function G.visibleFromTool(owner,state,target,planned)
        if G.planShot then
            -- A cached plan keeps the target through a brief new obstruction
            -- until its next bounded probe. Actual fire always rechecks LOS.
            if planned then return G.planShot(owner,state,target)~=nil end
            return G.shotPathClear(owner,G.toolPose(owner,state),target)
        end
        local base,rotation,facing=G.mount(owner)
        local muzzle
        if planned then
            muzzle=Core.toolPose(base,target.point,G.restGoal(owner),facing,rotation).muzzle
        else muzzle=G.toolPose(owner,state).muzzle end
        -- Bodies may be below the tool, but a solid wall may not be between
        -- its mounting point and nozzle. The final ray still blocks allies.
        if G.cast(base,muzzle,0,owner,true) then return false end
        return G.visible(owner,muzzle,target)
    end
    function G.body(target)
        if not target then return end
        if E.LuaUserData.IsTargetType(target,'Barotrauma.Character') then
            local anim=target.AnimController
            if not anim then return end
            if anim.Collider and anim.Collider.Enabled then return anim.Collider end
            local main=anim.MainLimb
            if main and not main.IsSevered and main.body and main.body.Enabled then return main.body end
            local body
            U.each(anim.Limbs,function(limb)
                if not body and not limb.IsSevered and limb.body and limb.body.Enabled then body=limb.body end
            end)
            return body
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
        local mass=body.Mass
        if type(mass)~='number' or not (mass>0 and mass<math.huge) then return false end
        return character or (mass<=C.maxGrabMass and G.portable(target))
    end
    function G.gather(owner,s,grabOrigin)
        local targets,base={},grabOrigin or G.mount(owner)
        local automatic=owner.IsBot
        local function add(t,range)
            if s.target and s.target.id==t.id and (t.kind=='repair' or t.kind=='weld') then range=range+C.contactSlack end
            if t.kind=='grab' and G.canHold and not G.canHold(t.entity,s) then t.free=false end
            local dx,dy=t.point.x-base.x,t.point.y-base.y
            t.distance=math.sqrt(dx*dx+dy*dy)
            local bound=range
            if t.kind=='weld' then bound=bound+math.sqrt(t.entity.Rect.Width^2+t.entity.Rect.Height^2) end
            if t.distance<=bound then
                if t.kind~='grab' or not grabOrigin then
                    t.visible=t.kind=='combat' and G.visibleFromTool(owner,s,t,true) or
                        (t.kind~='combat' and G.visible(owner,base,t))
                end
                t.distance=math.sqrt((t.point.x-base.x)^2+(t.point.y-base.y)^2)
                if t.distance<=range then
                    if t.kind=='grab' and not Core.grabAllowed(s,t.id,G.now) then t.free=false end
                    targets[#targets+1]=t
                end
            end
        end
        if automatic or s.mode=='repair' then
            U.each(E.Util.GetItemGroup('aegis.suit.repairables'),function(item)
                if G.repairEligible(owner,item) and item.Condition<item.MaxCondition-.01 then
                    add({id='i'..item.ID,kind='repair',entity=item,point=position(item),damaged=true},Core.repairRange())
                end
            end)
            U.each(E.Structure.WallList,function(wall)
                if not wall.Removed and wall.HasBody and not wall.Indestructible and not wall.Prefab.Platform then
                    local p=wall.WorldPosition
                    if math.abs(p.X-base.x)<Core.repairRange()+C.contactSlack+wall.Rect.Width and
                        math.abs(p.Y-base.y)<Core.repairRange()+C.contactSlack+wall.Rect.Height then
                        for section=0,wall.SectionCount-1 do
                            if wall.SectionDamage(section)>.01 then
                                local q=wall.SectionPosition(section,true)
                                add({id='w'..wall.ID..':'..section,kind='weld',entity=wall,section=section,
                                    point={x=q.X,y=q.Y},damaged=true,emergency=wall.GetSection(section).gap~=nil},Core.repairRange())
                            end
                        end
                    end
                end
            end)
        end
        if automatic or s.mode=='combat' or s.mode=='grab' then
            U.each(E.Character.CharacterList,function(other)
                if other~=owner and not other.Removed then
                    local p=other.WorldPosition
                    local range=not automatic and s.mode=='grab' and C.grabRange or C.combatRange
                    if not grabOrigin and (p.X-base.x)^2+(p.Y-base.y)^2>range^2 then return end
                    local friendly=(automatic or s.mode=='combat') and G.ally(owner,other)
                    if not friendly and not other.IsDead and (automatic or s.mode=='combat') then
                        add({id='c'..other.ID,kind='combat',entity=other,point=position(other),hostile=true,alive=true},C.combatRange)
                    end
                    if not automatic and s.mode=='grab' then
                        if G.grabbable(other) then
                            local id='g'..other.ID
                            add({id=id,kind='grab',entity=other,point={x=p.X,y=p.Y},free=true},C.grabRange)
                            if grabOrigin then
                                U.each(other.AnimController.Limbs,function(limb)
                                    if grabLimb(limb) then
                                        add({id=id,kind='grab',entity=other,point=position(limb),limb=limb,free=true},C.grabRange)
                                    end
                                end)
                            end
                        end
                    end
                end
            end)
        end
        if s.mode=='grab' and not automatic then
            -- World-item enumeration is only needed when acquiring an indicated grab.
            if not s.target then U.each(E.Item.ItemList,function(item)
                if not item.Removed and not item.ParentInventory then
                    local p=item.WorldPosition
                    if (p.X-base.x)^2+(p.Y-base.y)^2<=C.grabRange^2 and G.grabbable(item) then
                        add({id='g'..item.ID,kind='grab',entity=item,point={x=p.X,y=p.Y},free=true},C.grabRange)
                    end
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
        if not G.hasArm(item) then return false end
        if target.kind~='grab' and G.armReady and not G.armReady(owner,G.state(item),target) then return false end
        if target.kind=='repair' then return G.repairDevice and G.repairDevice(owner,item,target,dt) or false end
        if target.kind=='combat' then return G.firePulse and G.firePulse(owner,item,target) or false end
        if target.kind=='grab' and not G.grabbable(target.entity) then return false end
        if target.kind=='grab' then return G.hold and G.hold(owner,item,target,dt) or false end
        local fraction=G.spend(item,(C.rates[target.kind] or 0)*dt)
        if fraction<=0 then return false end
        local elapsed=dt*fraction
        if target.kind=='weld' then
            if G.weld then G.weld(owner,item,target,elapsed)
            else target.entity.AddDamage(target.section,-C.weldRate*elapsed,owner,false,false) end
        end
        return true
    end
    function G.patch(name,class,method,fn,after,types)
        local id='aegis.suit.'..name
        local phase=after and E.Hook.HookMethodType.After or E.Hook.HookMethodType.Before
        if types then E.Hook.Patch(id,class,method,types,fn,phase) else E.Hook.Patch(id,class,method,fn,phase) end
        G.patches[#G.patches+1]={id,class,method,phase,types}
    end
    function G.setMode(item,mode,owner)
        if G.equipped(owner)~=item or owner.IsUnconscious then return false end
        if mode=='sonar' then return G.toggleSonar and G.toggleSonar(owner,item) or false end
        if mode=='minerals' then return G.toggleMinerals and G.toggleMinerals(owner,item) or false end
        if mode=='sonaractive' or mode=='sonarpassive' then
            return G.setSonarMode and G.setSonarMode(owner,item,mode=='sonaractive') or false
        end
        if not G.hasArm(item) and mode~='off' then return false end
        local s=G.state(item);local previous=s.mode
        local ok=mode=='toggle' and Core.toggle(s) or Core.setMode(s,mode)
        if s.mode~=previous and G.releaseGrip then G.releaseGrip(s) end
        return ok
    end
    function G.authorize(client,item,mode)
        return client and client.Character and G.setMode(item,mode,client.Character) or false
    end
    local function update(dt)
        if E.Game.Paused then if G.pauseClient then G.pauseClient() end;return end
        G.now=G.now+dt
        if G.authoritative and E.Game.RoundStarted then
            if G.now>=(G.nextOwners or 0) then
                G.nextOwners=G.now+.25
                G.eachSuit(function(item)
                    if G.updateDocked then G.updateDocked(item,.25) end
                    local owner=G.owner(item)
                    if G.equipped(owner)==item then G.state(item) end
                end)
            end
            for item,s in pairs(G.states) do
                local owner=G.owner(item)
                if G.equipped(owner)~=item then
                    if G.cancelSupplies then G.cancelSupplies(s) end
                    if G.stopSonar then G.stopSonar(item,s) end
                    G.states[item]=nil
                else
                    if s.mode~='off' or owner.IsBot then transforms=transforms or {} end
                    if s.owner and s.owner~=owner then
                        if G.cancelSupplies then G.cancelSupplies(s) end
                        if G.releaseGrip then G.releaseGrip(s) end
                        s.target=nil;s.sonar=false
                    end
                    s.owner=owner;s.active=false;s.swimming=false
                    G.updateModules(item,s)
                    s.grabAutomatic=owner.IsBot
                    if G.updateSonar then G.updateSonar(owner,item,s,dt) end
                    if G.updateSupplies then G.updateSupplies(owner,item,s) end
                    if owner.IsUnconscious then s.target=nil
                    else
                        local powered=G.energy(item)>0
                        if powered then G.spend(item,C.lightRate*dt) end
                        if s.target and s.target.entity.Removed then s.target=nil end
                        Core.expireGrab(s,G.now)
                        local held=s.hasArm and not owner.IsBot and s.mode=='grab' and owner.IsKeyDown(E.InputType.Use)
                        if Core.grabPress(s,held) and owner.IsKeyDown(E.InputType.Aim) then
                            if s.target then
                                if G.releaseGrip then G.releaseGrip(s) end
                                s.target=nil;s.grabStarted=nil
                            else s.acquireGrab=true;s.nextScan=0 end
                        end
                        -- Manual selection keeps a valid pinned target. Track it below
                        -- every tick; only acquisition needs the world candidate scan.
                        -- Bots still rescan while working so threats can preempt repair.
                        local acquire=owner.IsBot or (not s.target and (s.mode~='grab' or s.acquireGrab))
                        local acquiredGrab=false
                        if G.now>=s.nextScan and (owner.IsBot or s.mode~='off') and powered and s.hasArm and acquire then
                            s.nextScan=G.now+C.scanInterval
                            local origin
                            if s.mode=='grab' and not owner.IsBot then
                                local aim=owner.AimRefPosition
                                if owner.Submarine then aim=aim+owner.Submarine.Position end
                                origin={x=aim.X,y=aim.Y}
                            end
                            local candidates=G.gather(owner,s,origin)
                            if owner.IsBot then
                                local old=s.target
                                local mode,target=Core.ai(candidates)
                                Core.setMode(s,mode);s.target=target
                                if target and target.kind=='grab' and (not old or old.id~=target.id) then s.grabStarted=G.now end
                            elseif s.mode~='grab' then
                                local selected=Core.choose(s.mode,candidates,s.target and s.target.id)
                                -- A missing scan candidate gets a per-frame contact/grace check.
                                if s.mode~='repair' or not s.target or (selected and selected.id==s.target.id) then s.target=selected end
                            elseif s.acquireGrab then
                                s.acquireGrab=false
                                local cursor=owner.CursorWorldPosition
                                s.target=Core.aimGrab(origin,{x=cursor.X,y=cursor.Y},candidates,function(t)
                                    return G.visible(owner,origin,t)
                                end)
                                acquiredGrab=s.target~=nil
                            end
                        end
                        local target=s.target
                        if target and target.kind=='repair' and not G.repairEligible(owner,target.entity) then
                            s.target=nil;target=nil;s.nextScan=0
                        end
                        local advanced=false
                        if target and not target.entity.Removed and powered and s.hasArm then
                            local grab=target.kind=='grab'
                            if not acquiredGrab then
                                if target.kind=='weld' then
                                    local q=target.entity.SectionPosition(target.section,true);target.point={x=q.X,y=q.Y}
                                else
                                    local limb=target.limb
                                    target.point=position(grabLimb(limb) and limb or target.entity)
                                end
                                local base=grab and s.grip and position(owner) or G.mount(owner)
                                if not (grab and s.grip) and target.kind~='combat' then
                                    target.visible=G.visible(owner,base,target)
                                end
                                target.distance=math.sqrt((target.point.x-base.x)^2+(target.point.y-base.y)^2)
                                if grab and s.grip and target.distance>C.gripReleaseRange and
                                    E.LuaUserData.IsTargetType(target.entity,'Barotrauma.Character') then
                                    local nearest=target.distance^2
                                    local function consider(part)
                                        local p=part.WorldPosition
                                        nearest=math.min(nearest,(p.X-base.x)^2+(p.Y-base.y)^2)
                                    end
                                    consider(target.entity)
                                    if nearest>C.gripReleaseRange^2 then
                                        local anim=target.entity.AnimController
                                        U.each(anim and anim.Limbs,function(limb)
                                            if grabLimb(limb) then consider(limb) end
                                        end)
                                    end
                                    target.distance=math.sqrt(nearest)
                                end
                            else target.visible=true end
                            if target.kind=='combat' then
                                target.alive=not target.entity.IsDead;target.hostile=not G.ally(owner,target.entity)
                                target.trackable=target.alive and target.hostile and target.distance<=C.combatRange
                                    and G.visibleFromTool(owner,s,target,true)
                                if target.trackable and G.advanceTool then G.advanceTool(owner,s,dt);advanced=true end
                                -- Visibility and armReady now share the actual advanced
                                -- firing pose; the async shot still rechecks fresh geometry.
                                target.visible=target.trackable and G.visibleFromTool(owner,s,target,false)
                            end
                            if target.kind=='repair' then target.damaged=target.entity.Condition<target.entity.MaxCondition-.01 end
                            if target.kind=='weld' then target.damaged=target.entity.SectionDamage(target.section)>.01 end
                            if grab then
                                target.free=G.grabbable(target.entity) and (not G.canHold or G.canHold(target.entity,s))
                                s.grabStarted=s.grabStarted or G.now
                            end
                            local retained,contact=Core.contact(s,target,G.now)
                            if retained then
                                if not advanced and G.advanceTool then G.advanceTool(owner,s,dt);advanced=true end
                                if contact and (grab or Core.ready(s,target.id,G.now)) then s.active=G.perform(owner,item,target,dt) end
                            else s.target=nil end
                        elseif not powered then s.target=nil end
                        if s.hasArm and not advanced and G.advanceTool then G.advanceTool(owner,s,dt) end
                        if not s.target then Core.ready(s,nil,G.now) end
                        if powered and s.hasImpeller and G.isSwimming(owner.AnimController) then
                            s.swimming=G.spend(item,C.rates.swim*dt)>0
                        end
                    end
                end
            end
            if G.sendSnapshot then G.sendSnapshot() end
            if G.pruneRepairs then G.pruneRepairs() end
            if G.pruneGrips then G.pruneGrips() end
        end
        if G.updateClient then G.updateClient(dt) end
    end
    function G.update(dt)
        -- Only the synchronous Lua controller shares a torso sample. Async
        -- projectile callbacks and render interpolation always read a fresh one.
        local previous=transforms
        transforms=nil
        local ok,err=pcall(update,dt)
        transforms=previous
        if not ok then error(err,0) end
    end
    function G.clear()
        if G.clearGrips then G.clearGrips() end
        if G.clearSonars then G.clearSonars() end
        if G.clearRepairs then G.clearRepairs() end
        if G.clearSupplies then G.clearSupplies() end
        if G.clearClient then G.clearClient() end
        G.states={};G.nextOwners=0
    end
    function G.dispose()
        if not G.alive then return end
        G.alive=false;G.clear()
        E.Hook.Remove('think','aegis.suit.update');E.Hook.Remove('roundEnd','aegis.suit.reset')
        E.Hook.Remove('stop','aegis.suit.dispose')
        for _,p in ipairs(G.patches) do
            if p[5] then E.Hook.RemovePatch(p[1],p[2],p[3],p[5],p[4]) else E.Hook.RemovePatch(p[1],p[2],p[3],p[4]) end
        end
        if G.disposeClient then G.disposeClient() end
    end
    function G.install()
        if G.authoritative then
            E.Util.RegisterItemGroup('aegis.suit.repairables',function(item) return U.component(item,'Repairable')~=nil end)
        end
        G.installSwimBoost()
        G.patch('breathing','Barotrauma.Character','UpdateOxygen',function(owner,p)
            local item=G.equipped(owner)
            if item then G.breathe(owner,item,p['deltaTime']) end
        end)
        E.Hook.Add('think','aegis.suit.update',function() if G.alive then G.update(1/60) end end)
        E.Hook.Add('roundEnd','aegis.suit.reset',G.clear)
        E.Hook.Add('stop','aegis.suit.dispose',G.dispose)
    end
    require('AegisSuit.modules').install(G,E)
    require('AegisSuit.swim').install(G,E)
    return G
end
return M
