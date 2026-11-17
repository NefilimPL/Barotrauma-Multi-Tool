local Core=require('DescendantSuit.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
-- Probe space for the whole body, then prefer a short, unobstructed route.
-- The result is only a spring anchor; native collisions still constrain movement.
function M.anchor(owner,offset,body,character,cast,blocked)
    local function world(o) return {x=owner.x+o.x,y=owner.y+o.y} end
    local function clear(a,b,radius)
        local hit=cast(a,b,radius)
        return not hit or (hit.t or 0)>=.97
    end
    local function fits(p)
        local height,width=character and 50 or 12,character and 18 or 12
        return clear(p,{x=p.x,y=p.y+height},width) and
            clear(p,{x=p.x,y=p.y-height},width) and
            clear({x=p.x-width,y=p.y},{x=p.x+width,y=p.y},0)
    end
    local normal=world(offset)
    if not blocked and fits(normal) and clear(body,normal,8) then return offset,false end
    local side=offset.x<0 and -1 or 1
    local candidates=character and {{x=side*80,y=65},{x=side*60,y=45},{x=side*35,y=45},{x=0,y=45},{x=-side*35,y=45},
        {x=side*80,y=25},{x=side*60,y=25},{x=side*35,y=25},{x=0,y=25},{x=-side*35,y=25}} or
        {{x=side*55,y=0},{x=side*35,y=-12},{x=side*70,y=-20},{x=0,y=0},{x=-side*35,y=-10}}
    for _,candidate in ipairs(candidates) do
        local p=world(candidate)
        if fits(p) and clear(body,p,8) then return candidate,true end
    end
    local hit=cast(body,normal,8)
    if hit then
        local nx,ny=hit.nx or 0,hit.ny or 0
        local dx,dy=normal.x-body.x,normal.y-body.y
        local dot=dx*nx+dy*ny
        local tx,ty=dx-dot*nx,dy-dot*ny
        local length=math.sqrt(tx*tx+ty*ty)
        if length<.01 then tx,ty=-ny,nx;if ty<0 then tx,ty=-tx,-ty end
        else tx,ty=tx/length,ty/length end
        local p={x=hit.x+nx*22+tx*60,y=hit.y+ny*22+ty*60}
        if (not character or p.y>=math.min(body.y,owner.y+45)) and fits(p) and clear(body,p,8) then return {x=p.x-owner.x,y=p.y-owner.y},true end
    end
    return {x=body.x-owner.x,y=body.y-owner.y},true,true
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
            entity.AnimController.IgnorePlatforms=lease.platforms
        end
        leases[entity]=nil;state.grip=nil
    end
    function G.canHold(entity,state) return not leases[entity] or leases[entity].state==state end
    function G.hold(owner,item,target,dt)
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
        lease.used=G.now
        local p,q=owner.WorldPosition,entity.WorldPosition
        if G.cast and G.now>=(lease.nextProbe or 0) then
            lease.nextProbe=G.now+C.gripProbeInterval
            local waiting
            lease.wantedOffset,lease.recovering,waiting=M.anchor({x=p.X,y=p.Y},lease.originalOffset,
                {x=q.X,y=q.Y},lease.character,function(a,b,radius)
                    return G.cast(a,b,radius,owner,true)
                end,target.visible==false)
            if waiting then
                lease.refuge=lease.refuge or {x=q.X,y=q.Y}
                lease.wantedOffset={x=lease.refuge.x-p.X,y=lease.refuge.y-p.Y}
            else lease.refuge=nil end
        end
        if lease.wantedOffset then
            local a=1-math.exp(-10*math.min(dt,.1))
            lease.offset={x=lease.offset.x+(lease.wantedOffset.x-lease.offset.x)*a,
                y=lease.offset.y+(lease.wantedOffset.y-lease.offset.y)*a}
        end
        local goal={x=p.X+lease.offset.x,y=p.Y+lease.offset.y}
        if not lease.character and G.toolPose then goal=G.toolPose(owner,state).muzzle end
        local error={x=(goal.x-q.X)/100,y=(goal.y-q.Y)/100}
        local ownerBody=G.body(owner)
        local carrier=ownerBody and ownerBody.LinearVelocity
        local vx,vy=carrier and carrier.X or 0,carrier and carrier.Y or 0
        local feed={x=0,y=0}
        if lease.carrier and dt>0 then
            feed.x=math.max(-60,math.min(60,(vx-lease.carrier.x)/dt))
            feed.y=math.max(-60,math.min(60,(vy-lease.carrier.y)/dt))
        end
        lease.carrier={x=vx,y=vy}
        local speed=math.sqrt(vx*vx+vy*vy)+(lease.recovering and 6 or C.grabSpeed)
        local seen={}
        local function pull(body)
            if not body or not body.Enabled or body.Mass<=0 or seen[body] then return end
            seen[body]=true
            local native=body.FarseerBody
            if native and native.Enabled==false then return end
            local world=native and native.World
            local gravity=world and world.Gravity
            local scale=native and (native.IgnoreGravity and 0 or native.GravityScale) or 1
            local velocity=body.LinearVelocity
            local acceleration=Core.holdAcceleration(error,
                {x=velocity.X-(carrier and carrier.X or 0),y=velocity.Y-(carrier and carrier.Y or 0)},
                {x=(gravity and gravity.X or 0)*(scale or 1),y=(gravity and gravity.Y or 0)*(scale or 1)})
            body.ApplyForce(E.Vector2((acceleration.x+feed.x)*body.Mass*fraction,
                (acceleration.y+feed.y)*body.Mass*fraction),speed)
        end
        pull(G.body(entity))
        if lease.character then U.each(entity.AnimController.Limbs,function(limb)
            if not limb.IsSevered then pull(limb.body) end
        end) end
        return true
    end
    function G.pruneGrips()
        for entity,lease in pairs(leases) do
            local state=lease.state
            if entity.Removed or not G.alive or G.states[lease.item]~=state or
                G.equipped(lease.owner)~=lease.item or lease.owner.IsUnconscious or lease.owner.IsDead or
                state.mode~='grab' or not state.target or state.target.entity~=entity or
                G.energy(lease.item)<=0 or G.now-(lease.used or 0)>.1 then G.releaseGrip(state) end
        end
    end
    function G.clearGrips() for _,lease in pairs(leases) do G.releaseGrip(lease.state) end end
end
return M
