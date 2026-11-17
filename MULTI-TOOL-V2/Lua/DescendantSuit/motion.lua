local Core=require('DescendantSuit.core')
local C=Core.config
local M={}
function M.delta(to,from) return (to-from+math.pi)%(math.pi*2)-math.pi end
local function advance(current,wanted,dt,ease,speed)
    local delta=M.delta(wanted,current)
    local step=delta*(1-math.exp(-dt/ease))
    local limit=speed*dt
    return M.delta(current+math.max(-limit,math.min(limit,step)),0)
end
function M.step(current,wanted,dt,ease,speed)
    dt=math.max(0,math.min(.1,dt))
    return {upper=advance(current.upper,wanted.upper,dt,ease or C.jointEase,speed or C.jointSpeed),
        lower=advance(current.lower,wanted.lower,dt,ease or C.jointEase,speed or C.jointSpeed),
        head=advance(current.head,wanted.head,dt,ease or C.jointEase,speed or C.headSpeed)}
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
        local rest=G.restGoal(owner)
        local point=state.target and state.target.point
        if state.lastPulse and G.now-(state.shotTime or -100)<C.pulseDuration then point=state.lastPulse end
        local wanted=M.angles(Core.toolPose(base,point,rest,facing,rotation),rotation)
        if not state.toolAngles then state.toolAngles=M.angles(Core.toolPose(base,nil,rest,facing,rotation),rotation) end
        state.toolAngles=M.step(state.toolAngles,wanted,dt)
    end
    function G.interpolateTool(state,dt)
        if G.authoritative or not state.toolAngles then return end
        state.drawAngles=state.drawAngles and M.step(state.drawAngles,state.toolAngles,dt,C.replicaEase,C.headSpeed) or state.toolAngles
    end
    function G.armReady(owner,state,target)
        local pose=G.toolPose(owner,state)
        local dx,dy=target.point.x-pose.muzzle.x,target.point.y-pose.muzzle.y
        if math.abs(M.delta(math.atan2(dy,dx),pose.angle))>C.toolAngleTolerance then return false end
        if target.kind=='repair' or target.kind=='weld' then
            return dx*dx+dy*dy<=(C.repairBeam+C.contactSlack)^2
        end
        return true
    end
end
return M
