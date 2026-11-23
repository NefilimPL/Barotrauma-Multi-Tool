local Core=require('AegisCombat.core')
local U=require('AegisCombat.util')
local C=Core.config
local M={}
function M.install(G,E)
    local physical,consumed,scans={},{},{}
    local function geometry(item)
        local direction,angle=G.direction(item)
        local pos=item.WorldPosition
        -- A rearward pivot lets an arm fixture protrude through the arc while
        -- the held weapon turns. Keep the barrier ahead of the weapon mount.
        return {x=pos.X,y=pos.Y,
            radius=C.shieldRadius,angle=angle,halfAngle=C.shieldHalfAngle},direction
    end
    local function blocksAttacker(owner,attacker,friendlyFire)
        if owner and owner==attacker then return false end
        if friendlyFire==false and G.friendly(owner,attacker) then return false end
        -- Match native DamageLimb: server friendly-fire protection applies
        -- only to player-team attackers hitting their own team. Faction NPCs
        -- can be hostile while Character.IsFriendly still reports true.
        if owner and attacker and attacker.IsOnPlayerTeam and owner.TeamID==attacker.TeamID
            and E.Game and not E.Game.IsSingleplayer then
            local settings=E.Game.ServerSettings
            return settings and settings.AllowFriendlyFire or false
        end
        return true
    end
    function G.findShield(a,b,attacker,weapon,friendlyFire,historical)
        local nearest=nil
        for _,s in pairs(G.states) do
            if s.shield and s.item~=weapon and blocksAttacker(s.owner,attacker,friendlyFire) then
                -- Item/physics updates can move or turn the weapon between think ticks.
                -- Intercept at its current simulation pose, matching the rendered mount.
                if s.item.body then s.shield=geometry(s.item) end
                local shield=s.shield
                local emitter=U.point(s.item.WorldPosition)
                if historical and historical.owner==s.owner then
                    -- Native hitscans also hit lag-compensated limb fixtures.
                    -- Translate this owner's shield into that fixture's frame;
                    -- never overwrite the live/rendered arc with historical data.
                    shield={x=shield.x+historical.x,y=shield.y+historical.y,
                        radius=shield.radius,angle=shield.angle,halfAngle=shield.halfAngle}
                    emitter={x=emitter.x+historical.x,y=emitter.y+historical.y}
                end
                local t,point=Core.segmentArc(a,b,shield)
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
    local function limbPoints(target,contacts)
        local points=contacts and contacts[target]
        if points then return points end
        points={minX=math.huge,maxX=-math.huge,minY=math.huge,maxY=-math.huge}
        U.each(target.AnimController.Limbs,function(limb)
            if not limb.IsSevered then
                local p=limb.WorldPosition
                local x,y=p.X,p.Y
                points[#points+1]=x;points[#points+1]=y
                if x<points.minX then points.minX=x end
                if x>points.maxX then points.maxX=x end
                if y<points.minY then points.minY=y end
                if y>points.maxY then points.maxY=y end
            end
        end)
        if contacts then contacts[target]=points end
        return points
    end
    local function outsideRange(points,x,y,radius)
        return points.maxX<x-radius or points.minX>x+radius or points.maxY<y-radius or points.minY>y+radius
    end
    function G.updateShield(s,ctx,dt,contacts)
        if not ctx.valid or not ctx.aim or not ctx.damage or G.now<s.brokenUntil or not G.powered(s.item,0) then
            s.shield=nil;return
        end
        if not G.spend(s.item,0,C.shieldIdleCost*dt) then
            local source=G.source(s.item,0)
            if source then source.item.Condition=0 end
            s.brokenUntil=G.now+C.shieldCooldown
            G.event('break',s,{x=s.item.WorldPosition.X,y=s.item.WorldPosition.Y})
            if contacts then for character in pairs(contacts) do contacts[character]=nil end end
            s.shield=nil;return
        end
        local direction
        s.shield,direction=geometry(s.item)
        local pos=s.item.WorldPosition
        local radius=C.shieldRadius+14
        local inner,outer=math.max(1,C.shieldRadius-14)^2,radius*radius
        local facing=math.cos(C.shieldHalfAngle)
        U.each(E.Character.CharacterList,function(target)
            if not s.shield then return end
            local sx,sy=s.shield.x,s.shield.y
            local points=contacts and contacts[target]
            -- A character's origin can be far from a ragdolled limb. Only
            -- reject by the bounds of the exact points sampled this tick.
            if points and outsideRange(points,sx,sy,radius) then return end
            if target.Removed or target.IsDead or G.friendly(ctx.owner,target) then return end
            local nextContact=s.contactTimes[target] or 0
            if G.now<nextContact then return end
            if not points then
                points=limbPoints(target,contacts)
                if outsideRange(points,sx,sy,radius) then return end
            end
            local touched=nil
            for i=1,#points,2 do
                local x,y=points[i],points[i+1]
                local dx,dy=x-sx,y-sy
                local distance2=dx*dx+dy*dy
                if distance2>=inner and distance2<=outer then
                    local dist=math.sqrt(distance2)
                    if dist>1 and (dx*direction.x+dy*direction.y)/dist>=facing then touched={x=x,y=y} end
                end
            end
            if touched and not G.cast({x=pos.X,y=pos.Y},touched,0,ctx.owner,true) then
                s.contactTimes[target]=G.now+C.shieldContactInterval
                if G.blockShield(s,C.shieldContactCost,touched) then
                    G.damage(target,touched,ctx.owner,C.contactBurn,0,C.contactStun)
                    G.event('contact',s,touched)
                end
                -- Contact and break hooks may move bodies synchronously. Later
                -- shields in this controller step must sample them again.
                if contacts then for character in pairs(contacts) do contacts[character]=nil end end
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
    local function intercept(projectile,a,b,includeCharacters,historical)
        if consumed[projectile] then return true end
        local hit=G.findShield(a,b,projectile.User or projectile.Attacker,projectile.Launcher,projectile.FriendlyFire,historical)
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
        local historical
        local fixture=p['target']
        local limb=fixture and fixture.Body.UserData
        -- LagCompensatedBody is only compiled into the server's Limb type.
        if E.SERVER and scan and limb and E.LuaUserData and E.LuaUserData.IsTargetType(limb,'Barotrauma.Limb') then
            local body=limb.LagCompensatedBody
            if body and fixture.Body==body.FarseerBody then
                local delta=E.ConvertUnits.ToDisplayUnits(E.Vector2(body.SimPosition.X-limb.body.SimPosition.X,
                    body.SimPosition.Y-limb.body.SimPosition.Y))
                historical={owner=limb.character,x=delta.X,y=delta.Y}
            end
        end
        local blocked,hit=intercept(proj,scan and scan.lastPoint or physical[proj] or current,current,not scan,historical)
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
