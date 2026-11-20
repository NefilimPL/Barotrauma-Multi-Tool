local Core=require('DescendantSuit.core')
local C=Core.config
local M={}
function M.delta(to,from) return (to-from+math.pi)%(math.pi*2)-math.pi end
local function advance(current,wanted,dt,smoothing,speed)
    local delta=M.delta(wanted,current)
    local step=delta*smoothing
    local limit=speed*dt
    return M.delta(current+math.max(-limit,math.min(limit,step)),0)
end
function M.step(current,wanted,dt,ease,speed)
    dt=math.max(0,math.min(.1,dt))
    local smoothing=1-math.exp(-dt/(ease or C.jointEase))
    return {upper=advance(current.upper,wanted.upper,dt,smoothing,speed or C.jointSpeed),
        lower=advance(current.lower,wanted.lower,dt,smoothing,speed or C.jointSpeed),
        head=advance(current.head,wanted.head,dt,smoothing,speed or C.headSpeed)}
end
function M.angles(pose,rotation)
    local upper=math.atan2(pose.elbow.y-pose.base.y,pose.elbow.x-pose.base.x)
    local lower=math.atan2(pose.tip.y-pose.elbow.y,pose.tip.x-pose.elbow.x)
    return {upper=M.delta(upper,rotation),lower=M.delta(lower,upper),head=M.delta(pose.angle,lower)}
end
function M.pose(base,rotation,angles)
    local upper=rotation+angles.upper
    local lower=upper+angles.lower
    local head=lower+angles.head
    local elbow={x=base.x+math.cos(upper)*C.upper,y=base.y+math.sin(upper)*C.upper}
    local tip={x=elbow.x+math.cos(lower)*C.lower,y=elbow.y+math.sin(lower)*C.lower}
    return {base=base,elbow=elbow,tip=tip,angle=head,
        muzzle={x=tip.x+math.cos(head)*C.toolOffset,y=tip.y+math.sin(head)*C.toolOffset}}
end
function M.install(G,E)
    function G.advanceTool(owner,state,dt)
        local base,rotation,facing=G.mount(owner)
        local rest=G.restGoal(owner,false,base,rotation,facing)
        local point=state.target and state.target.point
        local gap
        if state.grip and not state.grip.character then
            local p=owner.WorldPosition
            local offset=state.grip.wantedOffset or state.grip.offset
            point={x=p.X+offset.x,y=p.Y+offset.y};gap=0
        end
        if state.lastPulse and G.now-(state.shotTime or -100)<C.pulseDuration then point=state.lastPulse end
        if not state.toolAngles then state.toolAngles=M.angles(Core.toolPose(base,nil,rest,facing,rotation),rotation) end
        if state.toolRotation then
            state.toolAngles={upper=M.delta(state.toolAngles.upper+M.delta(state.toolRotation,rotation),0),
                lower=state.toolAngles.lower,head=state.toolAngles.head}
        end
        local combat=state.target and state.target.kind=='combat' and G.planShot
        local planned=combat and G.planShot(owner,state,state.target)
        if not combat then state.combatAim=nil;state.aimCandidate=nil end
        local wanted,other
        if planned then wanted=M.angles(planned,rotation)
        else
            -- Relative geometry is unchanged by translation of the entire rig.
            -- Cache both bends, but keep selecting the nearest one as joints move.
            local dx,dy=point and point.x-base.x,point and point.y-base.y
            local rx,ry=rest.x-base.x,rest.y-base.y
            local cached=state.ik
            if not cached or cached.dx~=dx or cached.dy~=dy or cached.rx~=rx or cached.ry~=ry or
                cached.rotation~=rotation or cached.facing~=facing or cached.gap~=gap then
                cached=cached or {}
                cached.dx,cached.dy,cached.rx,cached.ry=dx,dy,rx,ry
                cached.rotation,cached.facing,cached.gap=rotation,facing,gap
                cached.wanted=M.angles(Core.toolPose(base,point,rest,facing,rotation,gap),rotation)
                cached.other=point and M.angles(Core.toolPose(base,point,rest,-facing,rotation,gap),rotation) or nil
                state.ik=cached
            end
            wanted,other=cached.wanted,cached.other
        end
        if other then
            local function cost(a)
                return M.delta(a.upper,state.toolAngles.upper)^2+M.delta(a.lower,state.toolAngles.lower)^2
            end
            if cost(other)<cost(wanted) then wanted=other end
        end
        state.toolAngles=M.step(state.toolAngles,wanted,dt)
        state.toolRotation=rotation
    end
    function G.interpolateTool(state,dt,owner)
        if G.authoritative or not state.toolAngles then return end
        local wanted=state.toolAngles
        if owner and state.toolRotation then
            local _,rotation=G.mount(owner,true)
            wanted={upper=M.delta(wanted.upper+M.delta(state.toolRotation,rotation),0),lower=wanted.lower,head=wanted.head}
            if state.drawAngles and state.drawRotation then
                state.drawAngles={upper=M.delta(state.drawAngles.upper+M.delta(state.drawRotation,rotation),0),
                    lower=state.drawAngles.lower,head=state.drawAngles.head}
            end
            state.drawRotation=rotation
        end
        state.drawAngles=state.drawAngles and M.step(state.drawAngles,wanted,dt,C.replicaEase,C.headSpeed) or wanted
    end
    function G.armReady(owner,state,target)
        local pose=G.toolPose(owner,state)
        if target.kind=='combat' and G.planShot then
            local planned,raised=G.planShot(owner,state,target)
            if not planned then return false end
            if raised and (planned.tip.x-pose.tip.x)^2+(planned.tip.y-pose.tip.y)^2>C.aimPositionTolerance^2 then return false end
        end
        local dx,dy=target.point.x-pose.muzzle.x,target.point.y-pose.muzzle.y
        if target.kind=='repair' or target.kind=='weld' then
            local forward=dx*math.cos(pose.angle)+dy*math.sin(pose.angle)
            local side=math.abs(dy*math.cos(pose.angle)-dx*math.sin(pose.angle))
            return forward>=-2 and side<=C.repairTrackingWidth and dx*dx+dy*dy<=(C.repairBeam+C.contactSlack)^2
        end
        return math.abs(M.delta(math.atan2(dy,dx),pose.angle))<=C.toolAngleTolerance
    end
end
return M
