local Core=require('DescendantSuit.core')
local C=Core.config
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    if not G.authoritative then return end
    local leases={}
    function G.releaseGrip(state)
        local lease=state and state.grip
        if not lease then return end
        local entity=lease.entity
        if lease.character then
            entity.IsForceRagdolled=lease.forced
            entity.IsRagdolled=lease.ragdolled
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
            if lease.character then
                lease.forced=entity.IsForceRagdolled==true;lease.ragdolled=entity.IsRagdolled==true
            end
            leases[entity]=lease;state.grip=lease
        end
        if lease.character then entity.IsForceRagdolled=true;entity.IsRagdolled=true end
        lease.used=G.now
        local p,q=owner.WorldPosition,entity.WorldPosition
        local error={x=(p.X+lease.offset.x-q.X)/100,y=(p.Y+lease.offset.y-q.Y)/100}
        local ownerBody=G.body(owner)
        local carrier=ownerBody and ownerBody.LinearVelocity
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
            body.ApplyForce(E.Vector2(acceleration.x*body.Mass*fraction,acceleration.y*body.Mass*fraction),C.grabSpeed)
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
