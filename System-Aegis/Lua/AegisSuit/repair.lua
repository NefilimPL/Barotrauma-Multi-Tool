local U=require('AegisCombat.util')
local C=require('AegisSuit.config')
local M={}
function M.install(G,E)
    local descriptor=E.LuaUserData.RegisterType('Barotrauma.Items.Components.Repairable')
    E.LuaUserData.MakeMethodAccessible(descriptor,'UpdateFixAnimation')
    -- Replicated CurrentFixer also runs this animation on the client. It calls
    -- UpdateUseItem(false), which can steer, move hands and force crouching.
    G.patch('native-repair-animation','Barotrauma.Items.Components.Repairable','UpdateFixAnimation',function(r,p)
        local owner=p['character'] or r.CurrentFixer
        local scope=G.repairScope
        local suit=owner and G.equipped(owner)
        local state=suit and G.states and G.states[suit]
        if (scope and scope.repairable==r and scope.owner==owner) or
            (owner and r.CurrentFixer==owner and suit and
                ((state and state.repairing==r.Item) or owner.SelectedItem~=r.Item)) then
            p.PreventExecution=true
        end
    end)
    if not G.authoritative then return end
    E.LuaUserData.MakeFieldAccessible(descriptor,'currentRepairItem')
    E.LuaUserData.MakeFieldAccessible(E.LuaUserData.RegisterType('Barotrauma.Character'),'_selectedItem')
    E.LuaUserData.MakeFieldAccessible(E.LuaUserData.RegisterType('Barotrauma.AICharacter'),'_selectedItem')
    local actions=E.LuaUserData.CreateEnumTable('Barotrauma.Items.Components.Repairable+FixActions')
    local abilities=E.LuaUserData.CreateEnumTable('Barotrauma.AbilityEffectType')
    local stats=E.LuaUserData.CreateEnumTable('Barotrauma.StatTypes')
    local quality=E.LuaUserData.CreateEnumTable('Barotrauma.Items.Components.Quality+StatType')
    local sessions={}
    local function scoped(session,fn)
        local oldScope,selected=G.repairScope,session.owner._selectedItem
        G.repairScope=session
        -- Direct field access avoids OnItemSelected talents/UI events every tick.
        session.owner._selectedItem=session.repairable.Item
        local ok,result=pcall(fn)
        session.owner._selectedItem=selected;G.repairScope=oldScope
        if not ok then error(result) end
        return result
    end
    local function stop(r,s)
        sessions[r]=nil
        local state=G.states[s.item]
        if state and state.repairing==r.Item then state.repairing=nil end
        if r.CurrentFixer==s.owner and not r.Item.Removed then scoped(s,function() r.StopRepairing(s.owner) end) end
    end
    -- An actual native Repair/Sabotage/Tinker command hands the device back to
    -- normal gameplay. Merely selecting its UI does not end a servo session.
    G.patch('native-repair-manual','Barotrauma.Items.Components.Repairable','StartRepairing',function(r)
        local s=sessions[r]
        if s and G.repairScope~=s then stop(r,s) end
    end)
    function G.repairDevice(owner,item,target,dt)
        if G.repairEligible and not G.repairEligible(owner,target.entity) then return false end
        local r=U.component(target.entity,'Repairable')
        if not r or (r.CurrentFixer and (r.CurrentFixer~=owner or not sessions[r])) then return false end
        local s=sessions[r] or {owner=owner,item=item,repairable=r}
        if not r.CurrentFixer then
            if not scoped(s,function() return r.StartRepairing(owner,actions.Repair) end) then return false end
            r.currentRepairItem=item;sessions[r]=s
        end
        local state=G.states[item]
        if state then state.repairing=r.Item end
        local fraction=G.spend(item,C.rates.repair*dt)
        if fraction<=0 then stop(r,s);return false end
        s.used=G.now
        -- The actual native update computes skills, stats, quality, overrepair,
        -- awards and OnRepairComplete; it is not simulated by raising Condition.
        scoped(s,function() r.Update(dt*fraction,nil) end)
        return true
    end
    G.patch('native-repair-tick','Barotrauma.Items.Components.Repairable','Update',function(r,p)
        if sessions[r] and G.repairScope~=sessions[r] then p.PreventExecution=true end
    end)
    G.patch('native-repair-tool','Barotrauma.Items.Components.Repairable','CheckCharacterSuccess',function(r,p)
        if G.repairScope and G.repairScope.repairable==r then p['bestRepairItem']=G.repairScope.item end
    end)
    G.patch('native-repair-access','Barotrauma.Character','CanInteractWith',function(owner,p)
        local s=G.repairScope
        if s and s.owner==owner and p['item']==s.repairable.Item then p.PreventExecution=true;return true end
    end,false,{'Barotrauma.Item','System.Boolean'})
    local function allowScopedRepair(owner,p)
        local s=G.repairScope
        if s and s.owner==owner and p['item']==s.repairable.Item then
            -- Leave the native out-float untouched. Assigning a Lua number
            -- stores a boxed double in LuaCs' by-ref patch, which cannot be
            -- unboxed as System.Single when the prefix returns.
            p.PreventExecution=true;return true
        end
    end
    local distanceTypes={'Barotrauma.Item','System.Single&','System.Boolean'}
    if not pcall(G.patch,'native-repair-access-distance','Barotrauma.Character','CanInteractWith',
        allowScopedRepair,false,distanceTypes) then
        -- The Companion Update added the optional allowHiddenItems argument.
        distanceTypes[4]='System.Boolean'
        G.patch('native-repair-access-distance','Barotrauma.Character','CanInteractWith',
            allowScopedRepair,false,distanceTypes)
        -- The new native update discards repair tools that are not held in a hand.
        E.LuaUserData.MakeMethodAccessible(descriptor,'GetBestRepairItem')
        G.patch('native-repair-mounted-tool','Barotrauma.Items.Components.Repairable','GetBestRepairItem',function(r,p)
            local s=G.repairScope
            if s and s.repairable==r and s.owner==p['character'] then
                p.PreventExecution=true;return s.item
            end
        end)
    end
    G.patch('native-repair-selection','Barotrauma.Character','set_SelectedItem',function(owner,p)
        if G.repairScope and G.repairScope.owner==owner then p.PreventExecution=true end
    end)
    G.patch('native-repair-hands','Barotrauma.AnimController','StopUsingItem',function(anim,p)
        if G.repairScope and G.repairScope.owner.AnimController==anim then p.PreventExecution=true end
    end)
    function G.pruneRepairs()
        for r,s in pairs(sessions) do
            local state=G.states[s.item]
            if G.equipped(s.owner)~=s.item or not state or state.mode~='repair' or not state.target or
                (G.repairEligible and not G.repairEligible(s.owner,r.Item)) or
                state.target.entity~=r.Item or r.CurrentFixer~=s.owner or
                G.now-(s.used or 0)>C.contactGrace+.15 then stop(r,s) end
        end
    end
    function G.clearRepairs() for r,s in pairs(sessions) do stop(r,s) end end
    function G.weld(owner,item,target,elapsed)
        local wall,n=target.entity,target.section
        local leaking=wall.SectionIsLeakingFromOutside(n)
        local bonus=1+owner.GetStatValue(stats.RepairToolStructureRepairMultiplier)
        local q=U.component(item,'Quality')
        if q then bonus=bonus*(1+item.GetQualityModifier(quality.RepairToolStructureRepairMultiplier)) end
        wall.AddDamage(n,-C.weldRate*elapsed*math.max(0,bonus),owner,false,false)
        if leaking and not wall.SectionIsLeakingFromOutside(n) then owner.CheckTalents(abilities.OnRepairedOutsideLeak) end
    end
end
return M
