local U=require('CombatTool.util')
local C=require('CombatTool.config')
local M={}
function M.install(G,E)
    E.LuaUserData.RegisterType('Barotrauma.Skill')
    E.LuaUserData.RegisterType('Barotrauma.SkillSettings')
    local skillType=E.LuaUserData.CreateStatic('Barotrauma.Skill')
    local settings=E.LuaUserData.CreateStatic('Barotrauma.SkillSettings')
    local flags=E.LuaUserData.CreateEnumTable('Barotrauma.AbilityFlags')
    local skills={'helm','weapons','mechanical','electrical','medical'}
    local progress={}
    local function eligible(character)
        local powered=false
        U.each(character.HeldItems,function(item)
            local id=U.itemId(item)
            if item.Removed or item.Condition<=0 or not item.OwnInventory then return end
            if id~='multi-toolset' and id~=C.identifier then return end
            local source=item.OwnInventory.GetItemAt(0)
            if not source or source.Removed or source.Condition<=0 then return end
            if source.HasTag('reactorfuel') or (id==C.identifier and source.HasTag('mobilebattery')) then powered=true end
        end)
        return powered
    end
    function G.updatePassiveSkills(dt)
        if not G.authoritative or dt<=0 then return end
        local seen={}
        U.each(E.Character.CharacterList,function(character)
            seen[character]=true
            if character.Removed or character.IsDead or not character.Info or not character.Info.Job then
                progress[character]=nil;return
            end
            if character.IsUnconscious or not eligible(character) then return end
            local elapsed=(progress[character] or 0)+dt
            local periods=math.floor((elapsed+1e-7)/C.passiveSkillInterval)
            progress[character]=math.max(0,elapsed-periods*C.passiveSkillInterval)
            if periods==0 then return end
            local limit=character.HasAbilityFlag(flags.GainSkillPastMaximum)
                and settings.Current.MaximumSkillWithTalents or skillType.DefaultMaximumSkill
            for _,id in ipairs(skills) do
                local level=character.Info.Job.GetSkillLevel(id)
                if level<limit then
                    -- A fixed +2, independent of repair/skill-gain multipliers.
                    -- Native SetSkillLevel handles the saved level and networking.
                    character.Info.SetSkillLevel(id,math.min(limit,level+C.passiveSkillAmount*periods),true)
                end
            end
        end)
        for character in pairs(progress) do if not seen[character] then progress[character]=nil end end
    end
    function G.clearPassiveSkills() progress={} end
end
return M
