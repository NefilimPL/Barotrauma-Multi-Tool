-- TEST ONLY. Bounded read-only attribution trace; not a performance comparison.
local R=assert(AegisPerformance)
LuaUserData.RegisterType('System.Diagnostics.Stopwatch')
local Clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch')
local active,entry,phase,start,printed=nil,nil,nil,nil,0
Hook.Patch('aegis.performance.wall.diag.use.before','Barotrauma.Items.Components.RepairTool','Use',function(tool)
    local a=R.actors[6]
    active=nil
    if not R.started or not R.phase or R.phase.count~=8 or
        (R.phase.mode~='weld' and R.phase.mode~='cut') or not a or tool.Item~=a.item then return end
    if phase~=R.phase.id then
        phase=R.phase.id;printed=0
        start=tonumber(File.Read('LocalMods/System-Aegis/aegis-perf-phase.txt'):match('|(%d+)'))
    end
    if start and Clock.GetTimestamp()-start>=5*Clock.Frequency and printed<3 then
        active={actor=a,tool=tool,damage=0}
    end
end,Hook.HookMethodType.Before)
Hook.Patch('aegis.performance.wall.diag.ray','Barotrauma.Items.Components.RepairTool','Repair',function(tool,p)
    if active and active.tool==tool then active.rayStart=p['rayStart'];active.rayEnd=p['rayEnd'] end
end,Hook.HookMethodType.Before)
local types={'System.Int32','System.Single','Barotrauma.Character','System.Boolean','System.Boolean'}
Hook.Patch('aegis.performance.wall.diag.damage.before','Barotrauma.Structure','AddDamage',types,function(wall,p)
    if active then
        local section=p['sectionIndex']
        entry={wall=wall,section=section,before=wall.SectionDamage(section)}
    end
end,Hook.HookMethodType.Before)
Hook.Patch('aegis.performance.wall.diag.damage.after','Barotrauma.Structure','AddDamage',types,function(wall)
    if not active or not entry or entry.wall~=wall then return end
    local delta=wall.SectionDamage(entry.section)-entry.before
    if delta~=0 then
        active.damage=active.damage+math.abs(delta)
        print('[WALL DIAG] '..phase..' selected='..active.actor.section..' actual='..entry.section..
            ' sameWall='..tostring(wall==active.actor.wall)..' actualDelta='..delta)
    end
    entry=nil
end,Hook.HookMethodType.After)
Hook.Patch('aegis.performance.wall.diag.use.after','Barotrauma.Items.Components.RepairTool','Use',function(tool)
    if active and active.tool==tool then
        print('[WALL DIAG] '..phase..' totalActualWallDelta='..active.damage..
            ' rayStart='..tostring(active.rayStart)..' rayEnd='..tostring(active.rayEnd)..
            ' actor='..tostring(active.actor.c.WorldPosition)..' aim='..tostring(active.actor.aim))
        printed=printed+1;active=nil;entry=nil
    end
end,Hook.HookMethodType.After)
