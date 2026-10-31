local U=require('CombatTool.util')
local C=require('AegisHeadset.config')
local Core=require('AegisHeadset.core')
local T=require('AegisHeadset.treatments')
local Medical=require('AegisHeadset.medical')
local AI=require('AegisHeadset.ai')
local M={}
function M.new(E)
    local G={env=E,now=0,states={},patients={},patches={},contexts={},damageScope={},attackScopes={},providers={}}
    G.authoritative=E.SERVER or E.Game.IsSingleplayer
    G.registerTreatment=T.register
    function G.registerProvider(name,provider)
        assert(type(name)=='string' and type(provider)=='function','provider name and function required')
        G.providers[name]=provider
    end
    function G.equipped(character)
        if not character or character.Removed or character.IsDead or not character.Inventory then return nil end
        local item=character.Inventory.GetItemInLimbSlot(E.InvSlotType.Headset)
        if item and not item.Removed and item.Condition>0 and C.identifiers[U.itemId(item)] then return item end
    end
    function G.state(item)
        if not G.states[item] then G.states[item]={item=item} end
        return G.states[item]
    end
    function G.source(item)
        local cell=item and item.OwnInventory and item.OwnInventory.GetItemAt(0)
        if cell and not cell.Removed and cell.MaxCondition>0 and cell.HasTag('mobilebattery') then return cell end
    end
    function G.energy(item)
        local cell=G.source(item)
        return cell and math.max(0,cell.Condition/cell.MaxCondition*100) or 0
    end
    function G.setEnergy(item,value)
        local cell=G.source(item)
        if cell then cell.Condition=math.max(0,value)*cell.MaxCondition/100 end
    end
    function G.recordDebit(item,amount,reason)
        if amount<=1e-7 then return end
        local s=G.state(item)
        s.debits=s.debits or {}
        s.debits[#s.debits+1]={time=G.now,amount=amount,reason=reason or 'unspecified'}
        if #s.debits>12 then table.remove(s.debits,1) end
    end
    function G.spend(item,cost,reason)
        local left,fraction=Core.debit(G.energy(item),cost)
        G.setEnergy(item,left)
        if fraction>0 then G.recordDebit(item,cost*fraction,reason) end
        return fraction
    end
    local function emit(character,item,kind,joint)
        if G.emit then G.emit(character,item,kind,joint) end
    end
    function G.pressure(character,dt,nativeProtected)
        if nativeProtected or not character.NeedsAir then return false end
        local hull=character.AnimController and character.AnimController.CurrentHull
        if hull and hull.LethalPressure<80 then return false end
        local item=G.equipped(character)
        if not item or G.energy(item)<=0 then return false end
        if not G.authoritative then return true end
        local fraction=G.spend(item,C.pressureCost*dt,'pressure')
        if fraction>0 then emit(character,item,'pressure') end
        -- Never grant a whole native simulation step for a tiny remainder.
        return fraction>=1-1e-7
    end
    function G.heal(character,item,dt)
        if not G.authoritative or character.IsDead or not character.CharacterHealth then return end
        local entries=Medical.entries(E,character)
        for name,provider in pairs(G.providers) do
            local ok,extra=pcall(provider,character)
            if ok then
                for _,entry in ipairs(extra or {}) do
                    entry.policy=entry.policy or T.classify({id=entry.id})
                    entries[#entries+1]=entry
                end
            elseif E.printerror then E.printerror('[Aegis headsets] Provider '..name..': '..tostring(extra)) end
        end
        local patient=G.patients[character] or {jobs={}}
        G.patients[character]=patient
        local actions=T.plan(entries,math.min(C.healRate*dt,G.energy(item)/C.healCost))
        local changed=false
        for _,action in ipairs(actions) do
            local before=G.energy(item)
            local left,fraction=Core.debit(before,action.amount*C.healCost)
            -- Reserve mathematically; commit only the actual cost once.
            -- A provisional zero followed by a refund would fire OnBroken.
            if fraction>0 then
                local value=action.entry.strength+(action.value-action.entry.strength)*fraction
                local ok,err=pcall(function()
                    if action.entry.apply then action.entry.apply(value) else action.entry.ref.Strength=value end
                end)
                local actual=action.entry.ref and math.abs(action.entry.ref.Strength-action.entry.strength) or
                    (ok and action.amount*fraction or 0)
                local used=math.min(before-left,actual*C.healCost)
                G.setEnergy(item,before-used)
                G.recordDebit(item,used,'heal:'..action.entry.id)
                if used>1e-7 then changed=true end
                if not ok and not G.healError then
                    G.healError=tostring(err)
                    if E.printerror then E.printerror('[Aegis headsets] Treatment failed: '..G.healError) end
                end
            end
        end
        local jobs=Medical.jobs(character,entries)
        for key in pairs(patient.jobs) do if not jobs[key] then patient.jobs[key]=nil end end
        local keys={};for key in pairs(jobs) do keys[#keys+1]=key end;table.sort(keys)
        if #keys>0 then
            local job=jobs[keys[1]]
            local progress=patient.jobs[job.key] or {paid=0};patient.jobs[job.key]=progress
            local cost=job.kind=='organ' and C.organCost or job.kind=='surgery' and C.surgeryCost or C.limbCost
            local seconds=job.kind=='organ' and C.organSeconds or job.kind=='surgery' and C.surgerySeconds or C.limbSeconds
            local before=G.energy(item)
            local left,done=Core.advanceJob(progress,before,dt,cost,seconds)
            G.setEnergy(item,left)
            G.recordDebit(item,before-left,'regenerate:'..job.key)
            if left<before then changed=true end
            if done then
                for _,entry in ipairs(job.entries) do
                    if entry.apply then entry.apply(entry.policy.target or 0) else entry.ref.Strength=entry.policy.target or 0 end
                end
                if job.jointIndex then Medical.restoreNative(character,job.jointIndex);emit(character,item,'restore',job.jointIndex) end
                patient.jobs[job.key]=nil
            end
        end
        if changed then
            character.CharacterHealth.RecalculateVitality()
            emit(character,item,'heal')
        end
    end
    function G.blockableStrength(character,a,multiplier,limb,position,penetration)
        if (a.Probability or 1)<=0 then return 0 end
        local prefab=a.Prefab
        local health=character.CharacterHealth
        local kind=prefab.AfflictionType and tostring(prefab.AfflictionType.Value):lower() or ''
        local hp=character.Params and character.Params.Health
        if hp then
            if hp.PoisonImmunity and (kind=='poison' or kind=='paralysis') then return 0 end
            local immune=false
            U.each(hp.ImmunityIdentifiers,function(identifier) if identifier==prefab.Identifier then immune=true end end)
            if immune then return 0 end
        end
        if kind=='bleeding' and health.DoesBleed==false then return 0 end
        if kind=='oxygenlow' and character.NeedsOxygen==false then return 0 end
        if kind=='emp' and character.EmpVulnerability and character.EmpVulnerability<=0 then return 0 end
        if health.GetResistance and health.GetResistance(prefab,limb and limb.type or E.LimbType.None)>=1-1e-7 then return 0 end
        local damage=math.max(0,a.Strength)*(a.AffectedByAttackMultipliers==false and 1 or multiplier or 1)
        if limb then
            local hit=position and E.ConvertUnits and limb.SimPosition+E.ConvertUnits.ToSimUnits(limb.WorldPosition-position) or nil
            local function armor(modifier)
                if modifier.MatchesAffliction(a) and limb.SectorHit(modifier.ArmorSectorInRadians,hit) then
                    local factor=modifier.DamageMultiplier
                    if modifier.DeflectProjectiles and factor<1 then factor=factor+(1-factor)*(penetration or 0) end
                    damage=damage*factor
                end
            end
            U.each(limb.DamageModifiers,armor)
            U.each(limb.WearingItems,function(worn) U.each(worn.WearableComponent.DamageModifiers,armor) end)
        end
        return damage
    end
    function G.absorb(character,afflictions,stun,multiplier,attacker,limb,position,penetration,deferFeedback)
        local item=G.equipped(character)
        if not G.authoritative or not item or C.identifiers[U.itemId(item)]~=2 or G.energy(item)<=0 then return nil end
        if character.GodMode or (character.CharacterHealth and character.CharacterHealth.Unkillable) then return nil end
        -- LuaGame.Server does not exist in the client build (including SP).
        local settings=E.SERVER and E.Game.Server and E.Game.Server.ServerSettings
        if attacker and attacker~=character and attacker.IsOnPlayerTeam and settings and
            not settings.AllowFriendlyFire and attacker.TeamID==character.TeamID then return nil end
        local damage=math.max(0,stun or 0)
        local incoming={}
        U.each(afflictions,function(a)
            incoming[#incoming+1]=a
            if not a.Prefab.IsBuff then damage=damage+G.blockableStrength(character,a,multiplier,limb,position,penetration) end
        end)
        if damage<=0 then return nil end
        local before=G.energy(item)
        local left,residual=Core.absorb(before,damage)
        G.setEnergy(item,left)
        local fraction=residual/damage
        local result={};local buffs=false
        for _,a in ipairs(incoming) do
            if a.Prefab.IsBuff then result[#result+1]=a;buffs=true
            elseif fraction>1e-7 then result[#result+1]=a.CreateMultiplied(fraction,a) end
        end
        if not deferFeedback then G.recordDebit(item,before-left,'hit');emit(character,item,'hit') end
        return {afflictions=result,fraction=fraction,empty=fraction<=1e-7 and not buffs,cost=before-left}
    end
    function G.intercept(character,p,emptyResult)
        if G.damageScope[character] then return end
        local item=G.equipped(character)
        local previous=G.energy(item)
        local outcome=G.absorb(character,p['afflictions'],p['stun'],p['damageMultiplier'],p['attacker'],p['hitLimb'],p['worldPosition'],p['penetration'],true)
        if not outcome then return end
        if outcome.empty then
            if G.attackScopes[character] then G.attackScopes[character].blocked=true end
            G.recordDebit(item,outcome.cost,'hit');emit(character,item,'hit')
            p.PreventExecution=true;return emptyResult()
        end
        -- LuaCs Hook.Patch assigns parameters through raw CLR casts. Lua
        -- numbers are Doubles and tables are not IEnumerable<Affliction>.
        -- Normal method invocation marshals both correctly; guard the one
        -- re-entry so this attack is charged exactly once.
        G.damageScope[character]=true
        local ok,value=pcall(character.DamageLimb,p['worldPosition'],p['hitLimb'],outcome.afflictions,
            (p['stun'] or 0)*outcome.fraction,p['playSound'],p['attackImpulse']*outcome.fraction,
            p['attacker'],p['damageMultiplier'],p['allowStacking'],p['penetration'],
            p['shouldImplode'] and outcome.fraction>1e-7 or false,p['ignoreDamageOverlay'],p['recalculateVitality'])
        G.damageScope[character]=nil
        if not ok then
            G.setEnergy(item,previous)
            if not G.damageError then
                G.damageError=tostring(value)
                if E.printerror then E.printerror('[Aegis headsets] Native damage fallback: '..G.damageError) end
            end
            return -- leave the original attack intact if interop failed
        end
        G.recordDebit(item,outcome.cost,'hit');emit(character,item,'hit')
        p.PreventExecution=true
        return value
    end
    function G.beginAttack(character)
        G.attackScopes[character]={parent=G.attackScopes[character],blocked=false}
    end
    function G.endAttack(character)
        local scope=G.attackScopes[character]
        G.attackScopes[character]=scope and scope.parent or nil
    end
    function G.shouldBlockSever(character)
        return G.attackScopes[character] and G.attackScopes[character].blocked or false
    end
    function G.patch(name,class,method,fn,after)
        local phase=after and E.Hook.HookMethodType.After or E.Hook.HookMethodType.Before
        local key='bmt.headsets.'..name
        E.Hook.Patch(key,class,method,fn,phase)
        G.patches[#G.patches+1]={key,class,method,phase}
    end
    function G.install()
        E.LuaUserData.RegisterType('Barotrauma.AttackResult')
        local result=E.LuaUserData.CreateStatic('Barotrauma.AttackResult')
        E.LuaUserData.RegisterType('Barotrauma.Limb') -- SectorHit is public.
        for _,class in ipairs({'AIObjective','AIObjectiveGetItem','AIObjectiveContainItem'}) do
            E.LuaUserData.MakePropertyAccessible(E.LuaUserData.RegisterType('Barotrauma.'..class),'IsCompleted')
        end
        G.patch('update-enter','Barotrauma.Character','Update',function(character,p)
            G.contexts[character]={dt=p['deltaTime'],paid=false}
        end)
        G.patch('update-leave','Barotrauma.Character','Update',function(character) G.contexts[character]=nil end,true)
        G.patch('pressure','Barotrauma.Character','get_IsProtectedFromPressure',function(character,p)
            if p.ReturnValue then return end
            local context=G.contexts[character]
            if not context then return end
            if not context.checked then
                context.checked=true;context.protected=G.pressure(character,context.dt,false)
            end
            if context.protected then return true end
        end,true)
        if G.authoritative then
            G.patch('attack-enter','Barotrauma.Character','ApplyAttack',function(character) G.beginAttack(character) end)
            G.patch('attack-leave','Barotrauma.Character','ApplyAttack',function(character) G.endAttack(character) end,true)
            G.patch('block-sever','Barotrauma.Character','TrySeverLimbJoints',function(character,p)
                if G.shouldBlockSever(character) and p['damage']<=1e-7 then p.PreventExecution=true end
            end)
            -- DamageLimb is the single native entry before stun, wound,
            -- affliction callbacks and severing. AddDamage overloads call it.
            G.patch('absorb','Barotrauma.Character','DamageLimb',function(character,p)
                return G.intercept(character,p,result)
            end)
        end
        E.Hook.Add('think','bmt.headsets.update',function() G.update(1/60) end)
        E.Hook.Add('roundEnd','bmt.headsets.reset',G.clear)
        E.Game.AddCommand('aegis_headset_status','Show headset power and exact recent drain reasons.',G.printStatus)
        G.commandInstalled=true
    end
    function G.printStatus()
        E.print('[Aegis headsets] authority='..tostring(G.authoritative)..' renderer='..tostring(G.visualError or 'OK'))
        local count=0
        U.each(E.Character.CharacterList,function(character)
            local item=G.equipped(character)
            if not item or count>=16 then return end
            count=count+1
            E.print('[Aegis headsets] '..tostring(character.Name)..' '..U.itemId(item)..' energy='..string.format('%.2f%%',G.energy(item)))
            local s=G.state(item)
            if not s.debits or #s.debits==0 then
                E.print(G.authoritative and '[Aegis headsets] No recorded power use.' or '[Aegis headsets] Run this command on the server for drain reasons.')
            else
                for i=math.max(1,#s.debits-5),#s.debits do
                    local d=s.debits[i]
                    E.print(string.format('[Aegis headsets] %.1fs ago: %s -%.4f%%',G.now-d.time,d.reason,d.amount))
                end
            end
        end)
        if count==0 then E.print('[Aegis headsets] No equipped Aegis headset found.') end
    end
    function G.update(dt)
        G.now=G.now+dt
        if G.authoritative then
            G.healTime=(G.healTime or 0)+dt
            if G.healTime>=C.healInterval then
                local elapsed=G.healTime;G.healTime=0
                U.each(E.Character.CharacterList,function(character)
                    local item=G.equipped(character)
                    if item then G.heal(character,item,elapsed);AI.update(G,E,character,item) end
                end)
                for character in pairs(G.patients) do
                    if character.Removed or character.IsDead or not G.equipped(character) then G.patients[character]=nil end
                end
                for item,s in pairs(G.states) do
                    local owner=item.ParentInventory and item.ParentInventory.Owner
                    local isCharacter=owner and E.LuaUserData.IsTargetType(owner,'Barotrauma.Character')
                    if item.Removed or not isCharacter or G.equipped(owner)~=item then AI.cancel(s);G.states[item]=nil end
                end
            end
        end
        if G.updateEffects then G.updateEffects(dt) end
    end
    function G.clear()
        for _,s in pairs(G.states) do AI.cancel(s) end
        G.states={};G.patients={};G.contexts={};G.damageScope={};G.attackScopes={};G.healTime=0
        if G.clearEffects then G.clearEffects() end
    end
    function G.dispose()
        G.clear()
        if G.commandInstalled then E.Game.RemoveCommand('aegis_headset_status');G.commandInstalled=false end
        if E.Hook then
            E.Hook.Remove('think','bmt.headsets.update');E.Hook.Remove('roundEnd','bmt.headsets.reset')
            for _,p in ipairs(G.patches) do E.Hook.RemovePatch(p[1],p[2],p[3],p[4]) end
        end
        if G.disposeEffects then G.disposeEffects() end
        G.patches={}
    end
    return G
end
return M
