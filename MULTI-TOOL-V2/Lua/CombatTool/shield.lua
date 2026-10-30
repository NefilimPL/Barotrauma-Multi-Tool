local Core=require('CombatTool.core')
local U=require('CombatTool.util')
local C=Core.config
local M={}
function M.install(G,E)
    local physical,consumed,scans={},{},{}
    function G.findShield(a,b,attacker,weapon)
        local nearest=nil
        for _,s in pairs(G.states) do
            if s.shield and s.item~=weapon and not G.friendly(s.owner,attacker) then
                local t,point=Core.segmentArc(a,b,s.shield)
                local emitter=U.point(s.item.WorldPosition)
                if t and (not nearest or t<nearest.t) and not G.cast(emitter,point,0,s.owner,true) then
                    nearest={t=t,x=point.x,y=point.y,kind='shield',state=s}
                end
            end
        end
        return nearest
    end
    function G.blockShield(s,cost,position)
        if not s.shield then return false end
        local blocked,broken=G.shieldDebit(s.item,cost)
        if broken then
            s.brokenUntil=G.now+C.shieldCooldown
            G.event('break',s,{x=s.shield.x,y=s.shield.y})
            s.shield=nil
        elseif blocked then G.event('shieldhit',s,position) end
        return blocked
    end
    function G.updateShield(s,ctx,dt)
        if not ctx.valid or not ctx.aim or not ctx.damage or G.now<s.brokenUntil or not G.powered(s.item,1) then
            s.shield=nil;return
        end
        if not G.spend(s.item,1,C.shieldIdleCost*dt) then
            local source=G.source(s.item,1)
            if source then source.item.Condition=0 end
            s.brokenUntil=G.now+C.shieldCooldown
            G.event('break',s,{x=s.item.WorldPosition.X,y=s.item.WorldPosition.Y})
            s.shield=nil;return
        end
        local direction,angle=G.direction(s.item)
        local pos=s.item.WorldPosition
        s.shield={x=pos.X-direction.x*25,y=pos.Y-direction.y*25,
            radius=C.shieldRadius,angle=angle,halfAngle=C.shieldHalfAngle}
        U.each(E.Character.CharacterList,function(target)
            if not s.shield or target.Removed or target.IsDead or G.friendly(ctx.owner,target) then return end
            local nextContact=s.contactTimes[target] or 0
            if G.now<nextContact then return end
            local touched=nil
            U.each(target.AnimController.Limbs,function(limb)
                if limb.IsSevered then return end
                local p=limb.WorldPosition
                local dx,dy=p.X-s.shield.x,p.Y-s.shield.y
                local dist=math.sqrt(dx*dx+dy*dy)
                if dist>1 and math.abs(dist-C.shieldRadius)<=14 and
                    (dx*direction.x+dy*direction.y)/dist>=math.cos(C.shieldHalfAngle) then touched={x=p.X,y=p.Y} end
            end)
            if touched and not G.cast({x=pos.X,y=pos.Y},touched,0,ctx.owner,true) then
                s.contactTimes[target]=G.now+C.shieldContactInterval
                if G.blockShield(s,C.shieldContactCost,touched) then
                    G.damage(target,touched,ctx.owner,C.contactBurn,0,C.contactStun)
                    G.event('contact',s,touched)
                end
            end
        end)
    end
    local function remove(projectile)
        consumed[projectile]=true
        projectile.IsActive=false
        if projectile.Item.body then projectile.Item.body.Enabled=false end
        if E.Entity.Spawner then E.Entity.Spawner.AddItemToRemoveQueue(projectile.Item) end
        physical[projectile]=nil
    end
    local function intercept(projectile,a,b,includeCharacters)
        if consumed[projectile] then return true end
        local hit=G.findShield(a,b,projectile.User or projectile.Attacker,projectile.Launcher)
        if not hit then return false end
        local obstacle=G.cast(a,b,0,projectile.User or projectile.Attacker,not includeCharacters,projectile.FriendlyFire)
        if obstacle and obstacle.t<hit.t then return false end
        local attack=projectile.Attack
        local damage=attack and attack.GetTotalCharacterDamage() or 20
        if G.blockShield(hit.state,Core.bulletCost(damage),hit) then remove(projectile);return true,hit end
        return false
    end
    G.patch('projectile-launch','Barotrauma.Items.Components.Projectile','DoLaunch',function(proj,p)
        physical[proj]=U.point(proj.Item.WorldPosition)
    end,true)
    G.patch('projectile-update','Barotrauma.Items.Components.Projectile','Update',function(proj,p)
        if not proj.IsActive then physical[proj]=nil;return end
        local current=U.point(proj.Item.WorldPosition)
        local previous=physical[proj] or current
        if intercept(proj,previous,current,true) then p.PreventExecution=true;return end
        physical[proj]=current
    end)
    G.patch('projectile-collision','Barotrauma.Items.Components.Projectile','HandleProjectileCollision',function(proj,p)
        local current=U.point(proj.Item.WorldPosition)
        local scan=scans[proj]
        local blocked,hit=intercept(proj,scan and scan.lastPoint or physical[proj] or current,current,not scan)
        if consumed[proj] or blocked then
            p.PreventExecution=true
            if scan then
                -- The native loop already applied earlier hits. Stop at this
                -- shield contact without suppressing the whole hitscan.
                proj.MaxTargetsToHit=1
                if hit then proj.Item.Move(E.Vector2(hit.x-current.x,hit.y-current.y),true) end
                return true
            end
            return false
        end
    end)
    G.patch('projectile-collision-result','Barotrauma.Items.Components.Projectile','HandleProjectileCollision',function(proj,p)
        local scan=scans[proj]
        if scan then
            if p.ReturnValue then scan.hits=scan.hits+1 end
            scan.lastPoint=U.point(proj.Item.WorldPosition)
        end
    end,true)
    G.patch('hitscan','Barotrauma.Items.Components.Projectile','DoHitscan',function(proj,p)
        local a=U.point(proj.Item.WorldPosition)
        local dir=p['dir']
        local b={x=a.x+dir.X*50000,y=a.y+dir.Y*50000}
        scans[proj]={lastPoint=a,finish=b,hits=0,limit=proj.MaxTargetsToHit}
    end)
    G.patch('hitscan-finish','Barotrauma.Items.Components.Projectile','DoHitscan',function(proj,p)
        local scan=scans[proj]
        if scan and not consumed[proj] and scan.hits<scan.limit then
            intercept(proj,scan.lastPoint,scan.finish,false)
        end
        scans[proj]=nil
    end,true)
    function G.pruneShieldTracking()
        for proj in pairs(physical) do if proj.Item.Removed or not proj.IsActive then physical[proj]=nil end end
        for proj in pairs(consumed) do if proj.Item.Removed then consumed[proj]=nil end end
    end
    G.clearShieldTracking=function() physical={};consumed={};scans={} end
end
return M
