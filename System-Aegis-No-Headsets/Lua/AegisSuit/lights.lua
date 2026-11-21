local C=require('AegisSuit.config')
local M={}
function M.install(G,E)
    E.LuaUserData.RegisterType('Barotrauma.Lights.LightSource')
    local Source=E.LuaUserData.CreateStatic('Barotrauma.Lights.LightSource',true)
    local function move(light,owner,point,range,color)
        light.ParentSub=owner.Submarine
        local p=E.Vector2(point.x,point.y)
        if owner.Submarine then p=p-owner.Submarine.Position end
        light.Position=p;light.Range=range;light.Color=color
    end
    function G.removeLights(s)
        if not s or not s.lights then return end
        s.lights.helmet.Remove();s.lights.tool.Remove();s.lights=nil
    end
    function G.updateLights(s,newShot)
        local owner=s.owner or (G.owner and G.owner(s.item))
        if not owner then G.removeLights(s);return end
        if not s.lights then
            local template=s.item.Prefab.ConfigElement.GetChildElement('LightComponent')
            s.lights={helmet=Source(template),
                tool=Source(E.Vector2(0,0),0,E.Color(0,0,0,0),nil)}
        end
        local powered=G.energy(s.item)>0
        local head,rotation,facing=G.attachment(owner,8,48)
        local anim=owner.AnimController
        local limb=anim and anim.GetLimb and anim.GetLimb(E.LimbType.Head)
        local angle=limb and limb.body and limb.body.Rotation or rotation or 0
        local flash=s.lastPulse and G.now-(s.shotTime or -100)<C.pulseDuration
        local pose=G.toolPose(owner,s,true,flash and s.lastPulse or nil)
        local muzzle=pose.muzzle
        if newShot and flash then
            local particle=s.ballisticShot and 'aegisgaussmuzzle' or 'aegispulsemuzzle'
            E.Game.ParticleManager.CreateParticle(particle,E.Vector2(muzzle.x,muzzle.y),E.Vector2.Zero,-pose.angle)
        end
        local point=s.target and s.target.point or muzzle
        move(s.lights.helmet,owner,head,powered and 650 or 0,E.Color(190,220,255,170))
        s.lights.helmet.Rotation=angle+((facing or 1)<0 and -math.pi or 0)
        s.lights.helmet.Enabled=powered
        local repairing=s.active and s.target and (s.target.kind=='repair' or s.target.kind=='weld')
        local color=flash and E.Color(255,60,65,230) or repairing and E.Color(60,175,255,210) or E.Color(185,220,255,110)
        if flash and s.ballisticShot then color=E.Color(255,202,128,200) end
        local toolActive=powered and s.hasArm==true and (flash or repairing)
        move(s.lights.tool,owner,repairing and point or muzzle,toolActive and (flash and 300 or 120) or 0,color)
        s.lights.tool.Enabled=toolActive==true
    end
end
return M
