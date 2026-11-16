local Core=require('DescendantSuit.core')
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
    function G.updateLights(s)
        local owner=s.owner or (G.owner and G.owner(s.item))
        if not owner then G.removeLights(s);return end
        if not s.lights then
            s.lights={helmet=Source(E.Vector2(0,0),0,E.Color(0,0,0,0),nil),
                tool=Source(E.Vector2(0,0),0,E.Color(0,0,0,0),nil)}
        end
        local powered=G.energy(s.item)>0
        local head=G.attachment(owner,8,48)
        local base,_,facing=G.mount(owner)
        local point=s.target and s.target.point or G.restGoal(owner)
        facing=facing or 1
        local tip=Core.pose(base,point,facing<0 and -1 or 1).tip
        move(s.lights.helmet,owner,head,powered and 420 or 0,E.Color(190,220,255,170))
        local repairing=s.active and s.target and (s.target.kind=='repair' or s.target.kind=='weld')
        local flash=G.now-(s.shotTime or -100)<.12
        local color=flash and E.Color(255,60,65,230) or repairing and E.Color(60,175,255,210) or E.Color(185,220,255,110)
        move(s.lights.tool,owner,repairing and point or tip,powered and (flash and 300 or 220) or 0,color)
    end
end
return M
