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
    if s.mode~=mode then s.mode=mode;s.target=nil;s.grabStarted=nil end
    if mode~='off' then s.resumeMode=mode end
    return true
end
function M.toggle(s)
    return M.setMode(s,s.mode=='off' and (s.resumeMode or 'repair') or 'off')
end
function M.payPulse(s,power,ammo,now,powerCost)
    powerCost=powerCost or C.shotPower
    if now<(s.nextPulse or 0) or power<powerCost or ammo<C.ammoCost then return false end
    s.nextPulse=now+C.shotInterval
    return true,power-powerCost,ammo-C.ammoCost
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
    if s.target and s.target.kind~='repair' and s.mode=='grab' and s.grabStarted and now-s.grabStarted>=C.grabDuration then
        s.blockedGrab=s.target.id;s.grabBlockedUntil=now+2
        s.target=nil;s.grabStarted=nil;s.acquireGrab=false
        return true
    end
    return false
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
function M.choose(mode,targets,pinned)
    local best
    for _,t in ipairs(targets) do
        local valid=t.visible and t.distance and t.distance>=0
        if mode=='repair' then valid=valid and (t.kind=='repair' or t.kind=='weld') and t.damaged and t.distance<=C.reach+C.repairBeam
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
function M.ai(targets)
    local combat=M.choose('combat',targets)
    if combat then return 'combat',combat end
    local repair=M.choose('repair',targets)
    if repair then return 'repair',repair end
    for _,t in ipairs(targets) do
        if t.rescue then local grab=M.choose('grab',{t},t.id);if grab then return 'grab',grab end end
    end
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
