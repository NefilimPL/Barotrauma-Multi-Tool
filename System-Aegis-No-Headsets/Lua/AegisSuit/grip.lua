local Core=require('AegisSuit.core')
local C=Core.config
local U=require('AegisCombat.util')
local M={}
function M.anchor(owner,offset,body,character,cast,muzzle,size)
    local function world(o) return {x=owner.x+o.x,y=owner.y+o.y} end
    local function blocking(a,b,radius)
        local hit=cast(a,b,radius)
        if hit and (hit.t or 0)<.97 then return hit end
    end
    local height=math.max(character and 50 or 12,size and size.Y*50 or 0)
    local width=math.max(character and 18 or 12,size and size.X*50 or 0)
    local function fits(p)
        return not blocking(p,{x=p.x,y=p.y+height},width) and
            not blocking(p,{x=p.x,y=p.y-height},width) and
            not blocking({x=p.x-width,y=p.y},{x=p.x+width,y=p.y},0)
    end
    local function offsetTo(p) return {x=p.x-owner.x,y=p.y-owner.y} end
    local function sweep(a,b)
        local dx,dy=b.x-a.x,b.y-a.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length>1e-7 then
            local radius=(math.abs(dy)*width+math.abs(dx)*height)/length
            return blocking(a,b,radius)
        end
    end
    local normal=world(offset)
    local hit=sweep(body,normal)
    local normalFits=fits(normal)
    if not hit and normalFits then
        return offset,muzzle and (sweep(body,muzzle)~=nil or not fits(muzzle)) or false
    end
    local side=offset.x<0 and -1 or 1
    local candidates=character and {{x=side*80,y=65},{x=side*60,y=45},{x=side*35,y=45},{x=0,y=45},{x=-side*35,y=45},
        {x=side*80,y=25},{x=side*60,y=25},{x=side*35,y=25},{x=0,y=25},{x=-side*35,y=25}} or
        {{x=side*55,y=0},{x=side*35,y=-12},{x=side*70,y=-20},{x=0,y=0},{x=-side*35,y=-10}}
    for _,candidate in ipairs(candidates) do
        local p=world(candidate)
        if not sweep(body,p) and fits(p) then return candidate,true end
    end
    if normalFits and hit and hit.nx and hit.ny and (hit.nx~=0 or hit.ny~=0) then
        local nx,ny=hit.nx,hit.ny
        local tx,ty=-ny,nx
        if ty<0 then tx,ty=-tx,-ty end
        local clearance=math.abs(nx)*width+math.abs(ny)*height+10
        for _,step in ipairs({45,90,150}) do
            for _,distance in ipairs({step,-step}) do
                local x,y=hit.x+tx*distance,hit.y+ty*distance
                local p={x=x+nx*clearance,y=y+ny*clearance}
                if not sweep(body,p) and fits(p) then
                    if not sweep(p,normal) then return offsetTo(p),true end
                    local far={x=x-nx*clearance,y=y-ny*clearance}
                    if not sweep(p,far) and fits(far) and not sweep(far,normal) then
                        if sweep(body,far) then return offsetTo(p),true end
                        return offsetTo(far),true
                    end
                end
            end
        end
    end
    return offsetTo(body),true,true
end
function M.install(G,E)
    local held={};G.heldCharacters=held
    if G.patch and E.LuaUserData.RegisterType then
        local descriptor=E.LuaUserData.RegisterType('Barotrauma.Ragdoll')
        E.LuaUserData.MakeFieldAccessible(descriptor,'character')
        local none=E.LuaUserData.CreateEnumTable('Barotrauma.Direction').None
        G.patch('held-body-passable','Barotrauma.Ragdoll','OnLimbCollision',function(anim,p)
            if not held[anim.character] then return end
            local fixture=p['f2']
            local wall=fixture and fixture.Body and fixture.Body.UserData
            if wall and E.LuaUserData.IsTargetType(wall,'Barotrauma.Structure') and
                (wall.IsPlatform or wall.StairDirection~=none) then p.PreventExecution=true;return false end
        end)
        if G.authoritative then
            G.patch('held-body-awake','Barotrauma.Ragdoll','CheckBodyInRest',function(anim,p)
                if held[anim.character] then p.PreventExecution=true end
            end)
        end
    end
    if not G.authoritative then return end
    local leases={}
    function G.releaseGrip(state)
        local lease=state and state.grip
        if not lease then return end
        local entity=lease.entity
        if lease.character then
            held[entity]=nil
            entity.IsForceRagdolled=lease.forced
            entity.IsRagdolled=lease.ragdolled
            local anim=entity.AnimController
            if anim then anim.IgnorePlatforms=lease.platforms end
        end
        leases[entity]=nil;state.grip=nil
    end
    function G.canHold(entity,state) return not leases[entity] or leases[entity].state==state end
    function G.hold(owner,item,target,dt)
        if not G.hasArm(item) then G.releaseGrip(G.state(item));return false end
        local state=G.state and G.state(item) or G.states[item]
        local entity=target.entity
        if not state or not G.grabbable(entity) or not G.canHold(entity,state) then return false end
        local fraction=G.spend(item,C.rates.grab*dt)
        if fraction<=0 then G.releaseGrip(state);return false end
        local lease=state.grip
        if lease and lease.entity~=entity then G.releaseGrip(state);lease=nil end
        if not lease then
            local p,q=owner.WorldPosition,entity.WorldPosition
            lease={state=state,item=item,owner=owner,entity=entity,
                offset=Core.holdOffset({x=p.X,y=p.Y},{x=q.X,y=q.Y}),
                character=E.LuaUserData.IsTargetType(entity,'Barotrauma.Character')}
            lease.originalOffset=lease.offset
            if lease.character then
                lease.forced=entity.IsForceRagdolled==true;lease.ragdolled=entity.IsRagdolled==true
                lease.platforms=entity.AnimController.IgnorePlatforms==true
                lease.offset.y=math.max(C.gripLift,lease.offset.y)
            end
            leases[entity]=lease;state.grip=lease
        end
        if lease.character then
            held[entity]=true
            entity.IsForceRagdolled=true;entity.IsRagdolled=true
            entity.AnimController.IgnorePlatforms=true
            entity.DisableImpactDamageTimer=math.max(entity.DisableImpactDamageTimer or 0,.25)
        end
        local root=G.body(entity)
        local p,q=owner.WorldPosition,entity.WorldPosition
        local muzzle=not lease.character and G.toolPose and G.toolPose(owner,state).muzzle or nil
        local preferred=lease.originalOffset
        local sub=entity.Submarine
        if lease.pathSub~=sub then
            lease.pathSub=sub;lease.refuge=nil;lease.nextProbe=0
        end
        local origin=sub and sub.Position
        local sx,sy=origin and origin.X or 0,origin and origin.Y or 0
        if G.cast and G.now>=(lease.nextProbe or 0) then
            lease.nextProbe=G.now+C.gripProbeInterval
            local offset,recovering,waiting=M.anchor({x=p.X,y=p.Y},preferred,
                {x=q.X,y=q.Y},lease.character,function(a,b,radius)
                    return G.cast(a,b,radius,owner,true,false,entity,not lease.character)
                end,muzzle,root.GetSize and root.GetSize())
            lease.recovering=recovering
            if waiting then
                lease.refuge=lease.refuge or {x=q.X-sx,y=q.Y-sy}
                lease.pathPoint=lease.refuge
            else
                lease.refuge=nil
                lease.pathPoint=recovering and {x=p.X+offset.x-sx,y=p.Y+offset.y-sy} or nil
            end
        end
        -- Keep recovery points in the target's physics frame between probes.
        local pathPoint=lease.pathPoint
        lease.waypoint=pathPoint and {x=pathPoint.x+sx,y=pathPoint.y+sy} or nil
        local goal=lease.waypoint or muzzle or {x=p.X+preferred.x,y=p.Y+preferred.y}
        lease.offset={x=goal.x-p.X,y=goal.y-p.Y}
        local error={x=(goal.x-q.X)/100,y=(goal.y-q.Y)/100}
        local ownerBody=G.body(owner)
        local carrier=not lease.waypoint and ownerBody and ownerBody.LinearVelocity
        local vx,vy=carrier and carrier.X or 0,carrier and carrier.Y or 0
        local reference=root.LinearVelocity
        local steering=Core.holdAcceleration(error,{x=reference.X-vx,y=reference.Y-vy},{x=0,y=0})
        local speed=math.sqrt(vx*vx+vy*vy)+(lease.recovering and 6 or C.grabSpeed)
        local seen={}
        local function pull(body)
            if not body or not body.Enabled or body.Mass<=0 or seen[body] then return end
            seen[body]=true
            local native=body.FarseerBody
            if native and native.Enabled==false then
                if not lease.character then return end
                body.PhysEnabled=true
            end
            local world=native and native.World
            local gravity=world and world.Gravity
            local scale=native and (native.IgnoreGravity and 0 or native.GravityScale) or 1
            local velocity=body.LinearVelocity
            local gx,gy=(gravity and gravity.X or 0)*(scale or 1),(gravity and gravity.Y or 0)*(scale or 1)
            -- Give an already moving body room for lift and steering forces.
            local speedLimit=math.max(speed,math.sqrt(velocity.X^2+velocity.Y^2)+1)
            body.ApplyForce(E.Vector2((steering.x-gx)*body.Mass*fraction,
                (steering.y-gy)*body.Mass*fraction),speedLimit)
        end
        pull(root)
        if lease.character then U.each(entity.AnimController.Limbs,function(limb)
            if not limb.IsSevered then pull(limb.body) end
        end) end
        return true
    end
    function G.pruneGrips()
        for entity,lease in pairs(leases) do
            local state=lease.state
            if not G.hasArm(lease.item) or entity.Removed or not G.alive or G.states[lease.item]~=state or
                G.equipped(lease.owner)~=lease.item or lease.owner.IsUnconscious or lease.owner.IsDead or
                state.mode~='grab' or not state.target or state.target.entity~=entity or
                G.energy(lease.item)<=0 then G.releaseGrip(state) end
        end
    end
    function G.clearGrips() for _,lease in pairs(leases) do G.releaseGrip(lease.state) end end
end
return M
