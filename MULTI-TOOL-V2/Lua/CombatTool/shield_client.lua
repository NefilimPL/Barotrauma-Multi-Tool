local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    if G.authoritative then return end
    local scans={}
    G.patch('client-shield-start','Barotrauma.Items.Components.Projectile','DoHitscan',function(proj)
        scans[proj]={lastPoint=U.point(proj.Item.WorldPosition),limit=proj.MaxTargetsToHit}
    end)
    G.patch('client-shield-collision','Barotrauma.Items.Components.Projectile','HandleProjectileCollision',function(proj,p)
        local scan=scans[proj]
        if not scan then return end
        local current=U.point(proj.Item.WorldPosition)
        local hit=G.findClientShield(scan.lastPoint,current,proj,false)
        if not hit then return end
        -- Stop local prediction before native damage, pain, blood and impulses.
        -- Server snapshots still decide actual wounds and energy consumption.
        p.PreventExecution=true
        scan.blocked=true
        proj.MaxTargetsToHit=1
        -- Physics decides whether to block. The native tracer then ends at the
        -- displayed arc, which can be interpolated slightly ahead of that pose.
        local visual=G.findClientShield(scan.lastPoint,current,proj,true) or hit
        proj.Item.Move(E.Vector2(visual.x-current.x,visual.y-current.y),true)
        return true
    end)
    G.patch('client-shield-result','Barotrauma.Items.Components.Projectile','HandleProjectileCollision',function(proj)
        local scan=scans[proj]
        if scan then scan.lastPoint=U.point(proj.Item.WorldPosition) end
    end,true)
    G.patch('client-shield-finish','Barotrauma.Items.Components.Projectile','DoHitscan',function(proj)
        local scan=scans[proj]
        if scan and scan.blocked then proj.MaxTargetsToHit=scan.limit end
        scans[proj]=nil
    end,true)
    G.clearShieldTracking=function() scans={} end
end
return M
