local Core=require('DescendantSuit.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
function M.new(E)
    local G={env=E,authoritative=E.SERVER or E.Game.IsSingleplayer,states={},now=0,alive=true,patches={}}
    local humanAI
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
        local inv=G.container(item,2)
        local source=inv and inv.GetItemAt(0)
        if source and not source.Removed and source.MaxCondition>0 and
            (source.HasTag('mobilebattery') or source.HasTag('reactorfuel')) then return source end
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
        local inv=G.container(item,1)
        local tank=inv and inv.GetItemAt(0)
        local usable=tank and not tank.Removed and tank.Condition>0 and tank.HasTag('oxygensource')
        owner.OxygenAvailable=usable and 100 or 0
        if G.authoritative and usable and owner.NeedsAir and not owner.IsDead then
            tank.Condition=math.max(0,tank.Condition-C.oxygenRate*math.min(dt,.1))
        end
    end
    function G.mount(owner)
        local p=owner.WorldPosition
        local facing=owner.AnimController and owner.AnimController.Dir or 1
        return {x=p.X-(facing<0 and -1 or 1)*18,y=p.Y+25}
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
        local slotted=false
        U.each(item.AllowedSlots,function(slot)
            local name=tostring(slot):lower()
            if name~='none' and name~='0' and name~='' then slotted=true end
        end)
        if not slotted or U.component(item,'Door') then return false end
        local wire=U.component(item,'Wire')
        if wire then
            local connected=false
            if type(wire.Connections)=='table' then
                for _,connection in pairs(wire.Connections) do if connection then connected=true end end
            else U.each(wire.Connections,function(connection) if connection then connected=true end end) end
            U.each(wire.GetNodes(),function() connected=true end)
            if connected then return false end
        end
        local pick
        U.each(item.Components,function(component)
            if E.LuaUserData.IsTargetType(component,'Barotrauma.Items.Components.Pickable') then pick=component end
        end)
        return pick and pick.CanBePicked and not pick.IsAttached and pick.PickingTime<2147483647 or false
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
                        local body=G.body(other)
                        if body and body.Mass<=C.maxGrabMass then
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
                if G.portable(item) and item.body.Mass<=C.maxGrabMass then
                    add({id='g'..item.ID,kind='grab',entity=item,point=position(item),free=true},C.grabRange)
                end
            end)
            elseif s.target.kind=='grab' and not s.target.entity.Removed then
                local t=s.target
                t.point=position(t.entity);t.free=E.LuaUserData.IsTargetType(t.entity,'Barotrauma.Character') or not t.entity.ParentInventory
                add(t,C.grabRange)
            end
        end
        return targets
    end
    function G.perform(owner,item,target,dt)
        local fraction=G.spend(item,(C.rates[target.kind] or 0)*dt)
        if fraction<=0 then return false end
        local elapsed=dt*fraction
        if target.kind=='repair' then
            target.entity.Condition=math.min(target.entity.MaxCondition,target.entity.Condition+C.repairRate*elapsed)
        elseif target.kind=='weld' then
            target.entity.AddDamage(target.section,-C.weldRate*elapsed,owner,false,false)
        elseif target.kind=='combat' then
            G.damage(target.entity,target.point,owner,C.burnRate*elapsed,0,0)
        elseif target.kind=='grab' then
            local body=G.body(target.entity)
            if not body or body.Mass>C.maxGrabMass then return false end
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
                if G.equipped(owner)~=item then G.states[item]=nil
                else
                    s.owner=owner;s.active=false;s.swimming=false
                    if owner.IsUnconscious then s.target=nil
                    else
                        local powered=G.energy(item)>0
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
                                    local best,distance=nil,40*40
                                    for _,t in ipairs(candidates) do
                                        local d=(t.point.x-cursor.X)^2+(t.point.y-cursor.Y)^2
                                        if t.kind=='grab' and d<distance and t.visible and t.free then best=t;distance=d end
                                    end
                                    s.target=best;s.grabStarted=G.now
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
                                target.free=E.LuaUserData.IsTargetType(target.entity,'Barotrauma.Character') or not target.entity.ParentInventory
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
        end
        if G.updateClient then G.updateClient(dt) end
    end
    function G.clear()
        G.states={};G.nextOwners=0
        if G.clearClient then G.clearClient() end
    end
    function G.dispose()
        G.alive=false;G.clear()
        E.Hook.Remove('think','bmt.descendant.update');E.Hook.Remove('roundEnd','bmt.descendant.reset')
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
    end
    return G
end
return M
