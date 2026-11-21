local U=require('CombatTool.util')
local Core=require('DescendantSuit.core')
local Ammo=require('DescendantSuit.ammo')
local C=Core.config
local M={}
local function shotPower(source)
    return C.shotPower*(source.HasTag('reactorfuel') and C.rodMultiplier or 1)
end
function M.install(G,E)
    if not G.authoritative then return end
    local function remove(item) if item and not item.Removed then E.Entity.Spawner.AddEntityToRemoveQueue(item) end end
    function G.firePulse(owner,item,target)
        local s=G.state(item)
        if s.pendingPulse then return false end
        local ammo,profile=G.ammo(item)
        local source=G.source(item)
        if not source or Core.charge(source.Condition,source.MaxCondition,true)<shotPower(source)
            or Ammo.status(ammo,profile)<1 then return false end
        if G.now<(s.nextPulse or 0) then return true end
        local prefab=E.ItemPrefab.Prefabs[profile.projectile]
        if not prefab then return false end
        s.pendingPulse=true
        local pose=G.toolPose(owner,s)
        local world=E.Vector2(pose.muzzle.x,pose.muzzle.y)
        local function spawned(projectileItem)
            E.Timer.Wait(function()
                s.pendingPulse=false
                -- Spawning is asynchronous: recheck authority, ownership, mode,
                -- target, range and visibility before spending or firing.
                if not G.alive or item.Removed or owner.Removed or owner.IsDead or owner.IsUnconscious or
                    G.states[item]~=s or
                    G.equipped(owner)~=item or s.mode~='combat' or not s.target or s.target.entity~=target.entity or
                    target.entity.Removed or target.entity.IsDead or G.ally(owner,target.entity) then remove(projectileItem);return end
                local p=target.entity.WorldPosition;target.point={x=p.X,y=p.Y}
                if G.armReady and not G.armReady(owner,s,target) then remove(projectileItem);return end
                local mount=G.mount(owner)
                if (p.X-mount.x)^2+(p.Y-mount.y)^2>C.combatRange^2 or
                    (G.visibleFromTool and not G.visibleFromTool(owner,s,target,false)) then remove(projectileItem);return end
                local muzzle=G.toolPose(owner,s).muzzle
                if not G.visible(owner,muzzle,target) then remove(projectileItem);return end
                local projectile=U.component(projectileItem,'Projectile')
                if not projectile then remove(projectileItem);return end
                local source=G.source(item)
                local box,currentProfile=G.ammo(item)
                if not source or box~=ammo or currentProfile~=profile then remove(projectileItem);return end
                local shots,ammoCost,condition=Ammo.status(box,profile)
                if shots<1 then remove(projectileItem);return end
                local charge=Core.charge(source.Condition,source.MaxCondition,true)
                local ok,power,remaining=Core.payPulse(s,charge,condition,G.now,shotPower(source),ammoCost)
                if not ok then remove(projectileItem);return end
                source.Condition=power*source.MaxCondition/100;box.Condition=remaining
                local sub=owner.Submarine
                local pos=E.Vector2(muzzle.x,muzzle.y)-(sub and sub.Position or E.Vector2.Zero)
                projectileItem.Submarine=sub
                projectile.Launcher=item
                local sim=E.ConvertUnits.ToSimUnits(pos)
                projectile.Shoot(owner,sim,sim,math.atan2(p.Y-muzzle.y,p.X-muzzle.x),nil,true)
                s.shots=((s.shots or 0)+1)%65536
                s.lastPulse={x=p.X,y=p.Y};s.shotTime=G.now
            end,20)
        end
        if owner.Submarine then
            E.Entity.Spawner.AddItemToSpawnQueue(prefab,world-owner.Submarine.Position,owner.Submarine,nil,nil,spawned)
        else E.Entity.Spawner.AddItemToSpawnQueue(prefab,world,nil,nil,spawned) end
        return true
    end
end
return M
