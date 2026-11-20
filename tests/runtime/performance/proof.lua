-- TEST ONLY: bounded fixture ownership and per-window sustained-work evidence.
local M={}
function M.resetHealth(character)
    character.SetAllDamage(0,0,0)
    character.CharacterHealth.RemoveAllAfflictions()
    character.Oxygen=100;character.Stun=0
end
function M.followWall(a)
    if not a.wall then return end
    local point=a.wall.SectionPosition(a.section,true)
    a.home=a.home+point-a.wallReference
    a.aim=point;a.wallReference=point
end
function M.tracker(queue)
    local t={items={}}
    function t.add(entity) t.items[entity]=true;return entity end
    function t.remove(entity)
        t.items[entity]=nil
        if not entity.Removed then queue(entity) end
    end
    function t.clear() for entity in pairs(t.items) do t.remove(entity) end end
    return t
end
function M.sustained(r,at,final)
    if not r.phase or r.phase.item~='mixed' then return true end
    r.workWindows=r.workWindows or {}
    r.windowStart=r.windowStart or r.started+5
    r.windowBefore=r.windowBefore or {}
    if at-r.windowStart<30 and not final then return r.sustainedValid~=false end
    if at-r.windowStart<1 then return r.sustainedValid~=false end
    local row={from=r.windowStart-r.started,to=at-r.started,work={}}
    for i=1,r.phase.count do
        local value=r.actors[i].work or 0
        row.work[i]=value-(r.windowBefore[i] or 0)
        if row.work[i]<=0 then r.sustainedValid=false end
        r.windowBefore[i]=value
    end
    r.workWindows[#r.workWindows+1]=row;r.windowStart=at
    return r.sustainedValid~=false
end
return M
