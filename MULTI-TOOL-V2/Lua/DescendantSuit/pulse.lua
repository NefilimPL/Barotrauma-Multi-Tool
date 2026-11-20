local U=require('CombatTool.util')
local Core=require('DescendantSuit.core')
local C=Core.config
local M={}
function M.install(G,E)
    if not G.authoritative then return end
    local function remove(item) if item and not item.Removed then E.Entity.Spawner.AddEntityToRemoveQueue(item) end end
    function G.firePulse(owner,item,target)
        local s=G.state(item)
        local ammo=G.ammo(item)
        if not ammo or ammo.Condition<C.ammoCost or G.energy(item)<=0 then return false end
        if s.pendingPulse then return false end
        if G.now<(s.nextPulse or 0) then return true end
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
                local source,box=G.source(item),G.ammo(item)
                local cost=C.shotPower*(source and source.HasTag('reactorfuel') and C.rodMultiplier or 1)
                local ok,power,remaining=Core.payPulse(s,G.energy(item),box and box.Condition or 0,G.now,cost)
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
        local prefab=E.ItemPrefab.Prefabs['descendantpulsebolt']
        if owner.Submarine then
            E.Entity.Spawner.AddItemToSpawnQueue(prefab,world-owner.Submarine.Position,owner.Submarine,nil,nil,spawned)
        else E.Entity.Spawner.AddItemToSpawnQueue(prefab,world,nil,nil,spawned) end
        return true
    end
end
return M
