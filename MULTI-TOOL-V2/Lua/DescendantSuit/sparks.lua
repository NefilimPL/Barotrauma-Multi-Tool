-- Native particles own integration, fading and drawing. Lua only emits them.
local M={}
function M.new(E)
    return function(state,kind,point,dt)
        if (kind~='repair' and kind~='weld') or not point then state.sparkBudget=0;return end
        local screen=E.Game.GameScreen.Cam.WorldToScreen(E.Vector2(point.x,point.y))
        local viewport=E.GUI.GUI.Canvas.Rect
        if screen.X< -128 or screen.Y< -128 or screen.X>viewport.Width+128 or screen.Y>viewport.Height+128 then
            state.sparkBudget=0;return
        end
        state.sparkBudget=math.min(15,(state.sparkBudget or 0)+math.max(0,math.min(dt,.1))*150)
        while state.sparkBudget>=1 do
            state.sparkBudget=state.sparkBudget-1
            local angle=math.random()*math.pi*2;local speed=80+math.random()*200
            E.Game.ParticleManager.CreateParticle('descendantrepairspark',E.Vector2(point.x,point.y),
                E.Vector2(math.cos(angle)*speed,math.sin(angle)*speed))
        end
    end
end
return M
