-- Pure rules and geometry. No game objects or network side effects.
local C = require('CombatTool.config')
local M = { config = C }
local sqrt, abs, min, max = math.sqrt, math.abs, math.min, math.max
local function dot(a, b) return a.x*b.x + a.y*b.y end
function M.bounces(q) return 1 + max(0, min(3, math.floor(tonumber(q) or 0))) end
function M.angle(x,y)
    if math.atan2 then return math.atan2(y,x) end
    if x>0 then return math.atan(y/x) end
    if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
    return y>0 and math.pi/2 or y<0 and -math.pi/2 or 0
end
function M.mode(c)
    if c.bot then
        if c.task == 'combat' then return c.damage and 'combat' or 'idle' end
        if c.task == 'repair' or c.task == 'weld' or c.task == 'cut' or c.task == 'extinguish' then return c.task end
        return 'idle'
    end
    if c.repairing then return 'repair' end
    if c.extinguisher then return 'extinguish' end
    if c.damage then return 'combat' end
    return c.cutter and 'cut' or 'weld'
end
function M.normalize(v)
    local length = sqrt(dot(v,v))
    if length < 1e-8 then return {x=1,y=0} end
    return {x=v.x/length, y=v.y/length}
end
function M.reflect(v,n)
    n = M.normalize(n)
    local d = 2*dot(v,n)
    return {x=v.x-d*n.x,y=v.y-d*n.y}
end
function M.segmentArc(a,b,s)
    local dx,dy,ox,oy = b.x-a.x,b.y-a.y,a.x-s.x,a.y-s.y
    local aa = dx*dx+dy*dy
    if aa < 1e-10 then return nil end
    local bb,cc = 2*(ox*dx+oy*dy), ox*ox+oy*oy-s.radius*s.radius
    local discriminant = bb*bb-4*aa*cc
    if discriminant <= 1e-8 then return nil end
    local root = sqrt(discriminant)
    local candidates = {(-bb-root)/(2*aa),(-bb+root)/(2*aa)}
    local fx,fy = math.cos(s.angle),math.sin(s.angle)
    for _,t in ipairs(candidates) do
        if t >= 0 and t <= 1 then
            local px,py = a.x+dx*t,a.y+dy*t
            local nx,ny = (px-s.x)/s.radius,(py-s.y)/s.radius
            if nx*fx+ny*fy >= math.cos(s.halfAngle)-1e-7 and dx*nx+dy*ny < -1e-7 then
                return t,{x=px,y=py}, {x=nx,y=ny}
            end
        end
    end
end
function M.spend(source,cost)
    if not source or cost < 0 then return false end
    local debit = cost*(source.multiplier or 1)
    if source.condition + 1e-7 < debit then return false end
    source.condition = max(0,source.condition-debit)
    return true
end
function M.shieldHit(source,cost)
    if not source then return false,true end
    local blocked = M.spend(source,cost)
    if not blocked then source.condition=0 end
    return blocked,source.condition <= 1e-7
end
function M.bulletCost(damage)
    return min(C.shieldMaxHitCost,max(C.shieldMinHitCost,(tonumber(damage) or 20)*0.1))
end
function M.ring(position,direction,quality)
    local d = M.normalize(direction)
    return {x=position.x,y=position.y,dx=d.x,dy=d.y,speed=C.speed,
        age=0,distance=0,radius=C.radius,bouncesLeft=M.bounces(quality),
        damageMultiplier=1,alive=true}
end
local function trailPoint(r,x,y)
    r.trail=r.trail or {}
    local last=r.trail[#r.trail]
    if not last or math.abs(last.x-x)+math.abs(last.y-y)>.01 then
        r.trail[#r.trail+1]={x=x,y=y,age=r.age}
    end
    while #r.trail>C.trailPoints or (#r.trail>1 and r.age-r.trail[1].age>C.trailLifetime) do
        table.remove(r.trail,1)
    end
end
-- cast(a,b,ring) returns the nearest hit {t,x,y,nx,ny,kind}, or nil.
-- onHit(hit,ring) is called once per hit. Character/shield contacts terminate.
function M.advanceRing(r,dt,cast,onHit)
    if not r.alive or dt <= 0 then return end
    trailPoint(r,r.x,r.y)
    local step = min(dt,max(0,C.lifetime-r.age))
    local remaining = min(r.speed*step,max(0,C.maxDistance-r.distance))
    r.age = r.age+dt
    r.radius = min(C.maxRadius,C.radius+r.age*3)
    local contacts=0
    while remaining > 1e-5 and r.alive do
        local a={x=r.x,y=r.y}
        local b={x=r.x+r.dx*remaining,y=r.y+r.dy*remaining}
        local hit=cast(a,b,r)
        if not hit then
            r.x,r.y=b.x,b.y
            trailPoint(r,r.x,r.y)
            r.distance=r.distance+remaining
            break
        end
        local t=max(0,min(1,hit.t))
        local traveled=remaining*t
        r.x,r.y=hit.x,hit.y
        trailPoint(r,r.x,r.y)
        r.distance=r.distance+traveled
        remaining=remaining-traveled
        contacts=contacts+1
        if hit.kind ~= 'wall' or r.bouncesLeft <= 0 then
            r.alive=false
        else
            local v=M.reflect({x=r.dx,y=r.dy},{x=hit.nx,y=hit.ny})
            r.dx,r.dy=v.x,v.y
            r.bouncesLeft=r.bouncesLeft-1
            r.damageMultiplier=r.damageMultiplier*C.bounceRetention
            local epsilon=min(0.02,remaining)
            r.x,r.y=r.x+r.dx*epsilon,r.y+r.dy*epsilon
            remaining=remaining-epsilon
            r.distance=r.distance+epsilon
        end
        if onHit then onHit(hit,r) end
        if contacts >= C.maxStepContacts then r.alive=false end
    end
    if r.age >= C.lifetime or r.distance >= C.maxDistance-1e-5 then r.alive=false end
end
return M
