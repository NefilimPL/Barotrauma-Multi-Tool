local Core=require('DescendantSuit.core')
local Motion=require('DescendantSuit.motion')
local C=Core.config
local M={}
local function distance2(a,b) return (a.x-b.x)^2+(a.y-b.y)^2 end
local function copy(p) return {x=p.x,y=p.y} end
function M.install(G,E)
    local function onLand(owner) return owner.AnimController and not owner.AnimController.InWater or false end
    local function armClear(owner,p)
        -- Swimming retains its original mount-to-nozzle wall test. On land
        -- every link must also clear people, including before the nozzle.
        if not onLand(owner) then return not G.cast(p.base,p.muzzle,0,owner,true) end
        return not G.cast(p.base,p.elbow,0,owner,false,true) and
            not G.cast(p.elbow,p.tip,0,owner,false,true) and not G.cast(p.tip,p.muzzle,0,owner,false,true)
    end
    function G.shotPathClear(owner,pose,target)
        return pose~=nil and G.visible(owner,pose.muzzle,target) and armClear(owner,pose)
    end
    local function resolve(base,rotation,rest,target,entry,bend)
        bend=bend or entry.bend
        if entry.direct then return Core.toolPose(base,target.point,rest,bend,rotation) end
        local p=Core.pose(base,{x=base.x+entry.offset.x,y=base.y+entry.offset.y},bend)
        p.base=base;p.angle=math.atan2(target.point.y-p.tip.y,target.point.x-p.tip.x)
        p.muzzle={x=p.tip.x+math.cos(p.angle)*C.toolOffset,y=p.tip.y+math.sin(p.angle)*C.toolOffset}
        return p
    end
    function G.planShot(owner,state,target)
        local base,rotation,facing=G.mount(owner)
        local rest=G.restGoal(owner,false,base,rotation,facing)
        local land=onLand(owner)
        local key=target.entity or target.id or target
        local pinned=not state.target or state.target.entity==target.entity and state.target.id==target.id
        local slot=pinned and 'combatAim' or 'aimCandidate'
        local previous=state[slot]
        if previous and previous.key==key and previous.land==land and G.now<previous.expires and
            distance2(base,previous.base)<400 and distance2(target.point,previous.target)<1600 then
            if previous.negative then return nil,false end
            return resolve(base,rotation,rest,target,previous),previous.raised
        end
        local entry={key=key,land=land,base=copy(base),target=copy(target.point),expires=G.now+C.aimProbeInterval}
        local function save(p,raised)
            entry.raised=raised==true;entry.negative=p==nil;state[slot]=entry
            return p,entry.raised
        end
        local function choose(spec)
            local p=resolve(base,rotation,rest,target,spec,facing)
            -- Both IK bends share a nozzle. Reject blocked rays before probing
            -- each physical link, avoiding a full search for every render tick.
            if not G.visible(owner,p.muzzle,target) then return end
            local best,cost
            for _,bend in ipairs({facing,-facing}) do
                local q=bend==facing and p or resolve(base,rotation,rest,target,spec,bend)
                if armClear(owner,q) then
                    local score=0
                    if state.toolAngles then
                        local a=Motion.angles(q,rotation)
                        score=Motion.delta(a.upper,state.toolAngles.upper)^2+Motion.delta(a.lower,state.toolAngles.lower)^2
                    end
                    if not best or score<cost then best,cost=q,score;spec.bend=bend end
                end
            end
            return best
        end
        local direct={direct=true}
        local normal
        if not land or G.visible(owner,base,target) then normal=choose(direct) end
        if land and previous and previous.key==key and previous.land and previous.raised then
            if normal then entry.clearSince=previous.clearSince or G.now end
            if not normal or G.now-entry.clearSince<C.aimLowerDelay then
                local p=resolve(base,rotation,rest,target,previous)
                if G.shotPathClear(owner,p,target) then
                    entry.offset=previous.offset;entry.bend=previous.bend
                    return save(p,true)
                end
            end
        end
        if normal then entry.direct=true;entry.bend=direct.bend;return save(normal,false) end
        if land then
            local side=target.point.x>=base.x and 1 or -1
            for _,offset in ipairs({{60,85},{30,105},{0,116},{70,90},{-35,105},{60,70}}) do
                local spec={offset={x=side*offset[1],y=offset[2]}}
                local p=choose(spec)
                if p then entry.offset=spec.offset;entry.bend=spec.bend;return save(p,true) end
            end
        end
        return save(nil,false)
    end
end
return M
