local C=require('AegisSuit.config')
local M={}

function M.install(G,E)
    function G.isSwimming(anim)
        if not anim or not anim.InWater then return false end
        local movement=anim.TargetMovement
        return movement and movement.X^2+movement.Y^2>.01
    end

    function G.installSwimBoost()
        local controller='Barotrauma.HumanoidAnimController'
        local original={}
        -- UpdateSwimming overwrites collider velocity from its movement target.
        -- Supply the boosted target only for this native animation step.
        G.patch('swim-boost',controller,'UpdateSwimming',function(anim)
            local owner=anim.Character
            if not owner or owner.IsUnconscious or not G.isSwimming(anim) then return end
            local suit=G.equipped(owner)
            if not suit or not G.hasImpeller(suit) or G.energy(suit)<=0 then return end
            local move=anim.TargetMovement
            original[anim]=move
            anim.TargetMovement=E.Vector2(move.X*C.swimMultiplier,move.Y*C.swimMultiplier)
        end)
        G.patch('swim-restore-target',controller,'UpdateSwimming',function(anim)
            local move=original[anim]
            if move then
                anim.TargetMovement=move
                original[anim]=nil
            end
        end,true)
    end
end
return M
