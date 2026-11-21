-- Public, data-driven compatibility API. No dependency on NT or game globals.
local M={policies={}}
local preserveTypes={talentbuff=true,geneticmaterialbuff=true,geneticmaterial=true}
-- Real Sonar maintains this non-buff control flag. Clearing it enables its
-- XML fallback while Lua is running and is not medical regeneration.
local technical={serversidelua=true}
-- Character.Update restores stun>=5 every frame while incapacitated. Treat
-- its cause first: otherwise repeated stun consumes the entire medical budget.
local priorities={bleeding=100,bloodloss=100,oxygenlow=100,stun=-10,
    cardiacarrest=100,respiratoryarrest=100,hypoxemia=100,neurotrauma=95}
local typePriorities={paralysis=95}
function M.register(identifier,policy)
    assert(type(identifier)=='string' and type(policy)=='table','identifier and policy required')
    M.policies[identifier:lower()]=policy
end
function M.classify(prefab)
    local id=(prefab.id or ''):lower()
    local override=M.policies[id]
    if override then return not override.preserve and override or nil end
    if technical[id] then return nil end
    if preserveTypes[(prefab.type or ''):lower()] or (prefab.isBuff and not prefab.harmful) then return nil end
    return {target=0,priority=priorities[id] or typePriorities[(prefab.type or ''):lower()] or 0}
end
function M.plan(entries,budget)
    local groups,prioritiesList={},{}
    for _,entry in ipairs(entries) do
        local p=entry.policy
        if p and not p.preserve and not p.anatomy then
            local healthy=p.healthyMin and p.healthyMax and
                entry.strength>=p.healthyMin and entry.strength<=p.healthyMax
            local deficit=healthy and 0 or math.abs((p.target or 0)-entry.strength)
            if deficit>1e-6 then
                local priority=p.priority or 0
                if not groups[priority] then groups[priority]={total=0,entries={}};prioritiesList[#prioritiesList+1]=priority end
                local g=groups[priority]
                g.total=g.total+deficit;g.entries[#g.entries+1]={entry=entry,deficit=deficit}
            end
        end
    end
    table.sort(prioritiesList,function(a,b) return a>b end)
    local actions={}
    for _,priority in ipairs(prioritiesList) do
        local g=groups[priority]
        local available=math.min(math.max(0,budget),g.total)
        if available<=0 then break end
        for _,candidate in ipairs(g.entries) do
            local e=candidate.entry
            local amount=available*candidate.deficit/g.total
            actions[#actions+1]={entry=e,amount=amount,
                value=e.strength+((e.policy.target or 0)>e.strength and amount or -amount)}
        end
        budget=budget-available
    end
    return actions
end
return M
