local Core=require('CombatTool.core')
local C=Core.config
local M={}
function M.install(G,E)
    G.rings={};G.nextRingID=0
    function G.fire(s,ctx)
        if #G.rings>=C.maxRings then return end
        local direction=G.direction(s.item)
        local muzzle=G.muzzle(s.item)
        -- Never materialize an energy ring on the far side of a closed wall.
        local obstruction=G.cast({x=s.item.WorldPosition.X,y=s.item.WorldPosition.Y},muzzle,0,ctx.owner,true)
        if obstruction then muzzle={x=obstruction.x-direction.x*.5,y=obstruction.y-direction.y*.5} end
        local ring=Core.ring(muzzle,direction,s.item.Quality)
        G.nextRingID=(G.nextRingID%65534)+1
        ring.id=G.nextRingID;ring.owner=ctx.owner;ring.weapon=s.item
        ring.autonomous=ctx.bot or false
        G.rings[#G.rings+1]=ring
        if s.item.body and s.item.body.Enabled then
            s.item.body.ApplyLinearImpulse(E.Vector2(-direction.x,-direction.y)*s.item.body.Mass*C.recoilVelocity,4)
        end
        G.event('shot',s,muzzle)
    end
    function G.cancelRings(item)
        for _,ring in ipairs(G.rings) do if ring.weapon==item then ring.alive=false end end
    end
    function G.clearProjectiles() G.rings={} end
    function G.updateRings(dt)
        for i=#G.rings,1,-1 do
            local ring=G.rings[i]
            if ring.weapon.Removed or (not ring.autonomous and not G.flags(ring.weapon).damage) then ring.alive=false end
            Core.advanceRing(ring,dt,function(a,b,r)
                -- Native Character.AddDamage enforces the match's friendly-fire
                -- setting. Do not make allied crew immune at the ray-cast layer.
                local hit=G.cast(a,b,r.radius,r.owner,false,true)
                local shield=G.findShield(a,b,r.owner,ring.weapon)
                if shield and (not hit or shield.t<hit.t) then return shield end
                return hit
            end,function(hit,r)
                if hit.kind=='character' then
                    local impulse=C.hitImpulse*r.damageMultiplier
                    G.damage(hit.target,hit,r.owner,C.burnDamage*r.damageMultiplier,C.bluntDamage*r.damageMultiplier,0,
                        {x=r.dx*impulse,y=r.dy*impulse})
                    G.event('hit',G.state(r.weapon),hit)
                elseif hit.kind=='shield' then
                    local blocked=G.blockShield(hit.state,Core.bulletCost(30*r.damageMultiplier),hit)
                    -- Insufficient shield energy lets this ring continue from the contact.
                    if not blocked then
                        r.alive=true;r.x=r.x+r.dx*.05;r.y=r.y+r.dy*.05
                    end
                elseif hit.kind=='wall' then G.event(r.alive and 'bounce' or 'wallhit',G.state(r.weapon),hit) end
            end)
            if not ring.alive then table.remove(G.rings,i) end
        end
    end
end
return M
