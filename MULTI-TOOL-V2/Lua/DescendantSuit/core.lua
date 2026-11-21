local C=require('DescendantSuit.config')
local M={config=C,modes={off=true,repair=true,combat=true,grab=true}}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function M.breathable(e)
    return e.hull==true and not e.wet and (e.oxygen or 0)>=C.airOxygen and (e.pressure or 100)<C.airPressure
end
function M.charge(condition,maxCondition,allowed)
    if not allowed or not maxCondition or maxCondition<=0 then return 0 end
    return clamp((condition or 0)/maxCondition*100,0,100)
end
function M.debit(charge,cost)
    if cost<=0 then return charge,1 end
    local used=math.min(math.max(0,charge),cost)
    return math.max(0,charge-used),used/cost
end
function M.setMode(s,mode)
    if not M.modes[mode] then return false end
    if s.mode~=mode then s.mode=mode;s.target=nil;s.grabStarted=nil;s.contactId=nil;s.contactAt=nil end
    if mode~='off' then s.resumeMode=mode end
    return true
end
function M.toggle(s)
    return M.setMode(s,s.mode=='off' and (s.resumeMode or 'repair') or 'off')
end
function M.payPulse(s,power,ammo,now,powerCost,ammoCost,interval)
    powerCost=powerCost or C.shotPower
    ammoCost=ammoCost or C.ammoCost
    if now<(s.nextPulse or 0) or power<powerCost or ammo<ammoCost then return false end
    s.nextPulse=now+(interval or C.shotInterval)
    return true,power-powerCost,ammo-ammoCost
end
function M.grabPress(s,held)
    local pressed=held and not s.grabHeld
    s.grabHeld=held
    return pressed==true
end
function M.ready(s,id,now)
    if not id then s.actionId=nil;s.readyAt=nil;return false end
    if s.actionId~=id then s.actionId=id;s.readyAt=now+C.servoDelay end
    return now>=(s.readyAt or now+C.servoDelay)
end
function M.grabAllowed(s,id,now)
    return id~=s.blockedGrab or now>=(s.grabBlockedUntil or 0)
end
function M.expireGrab(s,now)
    if not s.grabAutomatic then return false end
    if s.target and s.target.kind~='repair' and s.mode=='grab' and s.grabStarted and now-s.grabStarted>=C.grabDuration then
        s.blockedGrab=s.target.id;s.grabBlockedUntil=now+2
        s.target=nil;s.grabStarted=nil;s.acquireGrab=false
        return true
    end
    return false
end
function M.repairRange() return C.reach+C.toolOffset+C.repairBeam end
function M.holdOffset(owner,point)
    local dx,dy=point.x-owner.x,point.y-owner.y
    local distance=math.sqrt(dx*dx+dy*dy)
    local scale=distance>1e-6 and math.min(C.grabHoldDistance,distance)/distance or 0
    return {x=dx*scale,y=clamp(dy*scale,45,120)}
end
function M.holdAcceleration(error,relativeVelocity,gravity)
    local x=error.x*C.grabSpring-relativeVelocity.x*C.grabDamping
    local y=error.y*C.grabSpring-relativeVelocity.y*C.grabDamping
    local length=math.sqrt(x*x+y*y)
    if length>C.grabAcceleration then x=x/length*C.grabAcceleration;y=y/length*C.grabAcceleration end
    return {x=x-gravity.x,y=y-gravity.y}
end
function M.pose(base,goal,bend)
    local dx,dy=goal.x-base.x,goal.y-base.y
    local d=math.sqrt(dx*dx+dy*dy)
    local angle=d>1e-6 and math.atan2(dy,dx) or 0
    local distance=clamp(d,math.abs(C.upper-C.lower)+.001,C.reach-.001)
    local offset=math.acos(clamp((C.upper^2+distance^2-C.lower^2)/(2*C.upper*distance),-1,1))*(bend or -1)
    return {elbow={x=base.x+C.upper*math.cos(angle+offset),y=base.y+C.upper*math.sin(angle+offset)},
        tip={x=base.x+distance*math.cos(angle),y=base.y+distance*math.sin(angle)}}
end
function M.toolPose(base,target,rest,facing,rotation,standOff)
    local goal=rest
    if target then
        local dx,dy=target.x-base.x,target.y-base.y
        local length=math.sqrt(dx*dx+dy*dy)
        local x,y=math.cos(rotation or 0)*(facing or 1),math.sin(rotation or 0)*(facing or 1)
        if length>1e-6 then x,y=dx/length,dy/length end
        local gap=standOff==nil and C.toolStandOff or standOff
        goal={x=target.x-x*(C.toolOffset+gap),y=target.y-y*(C.toolOffset+gap)}
    end
    local pose=M.pose(base,goal,facing)
    local angle=(rotation or 0)+((facing or 1)<0 and math.pi or 0)
    if target then angle=math.atan2(target.y-pose.tip.y,target.x-pose.tip.x) end
    pose.angle=angle;pose.base=base
    pose.muzzle={x=pose.tip.x+math.cos(angle)*C.toolOffset,y=pose.tip.y+math.sin(angle)*C.toolOffset}
    return pose
end
function M.choose(mode,targets,pinned)
    local best
    for _,t in ipairs(targets) do
        local valid=t.visible and t.distance and t.distance>=0
        if mode=='repair' then valid=valid and (t.kind=='repair' or t.kind=='weld') and t.damaged and
            t.distance<=M.repairRange()+(t.id==pinned and C.contactSlack or 0)
        elseif mode=='combat' then valid=valid and t.kind=='combat' and t.alive and t.hostile and t.distance<=C.combatRange
        elseif mode=='grab' then valid=valid and t.kind=='grab' and t.free and t.id==pinned and t.distance<=C.grabRange
        else valid=false end
        if valid then
            local wins=not best
            if best then
                if (t.id==pinned)~=(best.id==pinned) then wins=t.id==pinned
                elseif mode=='repair' and (t.emergency==true)~=(best.emergency==true) then wins=t.emergency==true
                else wins=t.distance<best.distance end
            end
            if wins then best=t end
        end
    end
    return best
end
function M.contact(s,target,now)
    if s.mode=='combat' and target.trackable and target.alive and target.hostile and
        target.distance and target.distance<=C.combatRange then
        return true,target.visible==true
    end
    if s.mode=='grab' and s.grip then
        if not target.free or not target.distance or target.distance>C.gripReleaseRange then return false,false end
        if target.visible then s.contactId=target.id;s.contactAt=now;return true,true end
        if s.contactId==target.id and now-(s.contactAt or -100)<=C.gripOcclusionGrace then return true,true end
        return false,false
    end
    if M.choose(s.mode,{target},target.id) then
        s.contactId=target.id;s.contactAt=now;return true,true
    end
    if s.mode=='repair' and (target.kind=='repair' or target.kind=='weld') and target.damaged and
        not target.visible and s.contactId==target.id and now-(s.contactAt or -100)<=C.contactGrace and
        target.distance and target.distance<=M.repairRange()+C.contactSlack then return true,false end
    return false,false
end
function M.ai(targets)
    local combat=M.choose('combat',targets)
    if combat then return 'combat',combat end
    local repair=M.choose('repair',targets)
    if repair then return 'repair',repair end
    return 'off',nil
end
function M.aimGrab(origin,cursor,targets)
    -- Native multiplayer sends an aim angle, not the cursor's distance.
    local dx,dy=cursor.x-origin.x,cursor.y-origin.y
    local length=math.sqrt(dx*dx+dy*dy)
    if length<1e-6 then return end
    dx,dy=dx/length,dy/length
    local best,nearest
    for _,t in ipairs(targets) do
        if M.choose('grab',{t},t.id) then
            local x,y=t.point.x-origin.x,t.point.y-origin.y
            local along=x*dx+y*dy
            local across=math.abs(x*dy-y*dx)
            if along>=0 and across<40 and (not nearest or along<nearest) then
                best,nearest=t,along
            end
        end
    end
    return best
end
return M
