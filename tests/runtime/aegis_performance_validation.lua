-- Additional native action/powered-sonar evidence; safe to attach during a run.
local G=AegisSuit
local R=SERVER and AegisPerf or AegisPerfClient
local phase,started,rows,latest=nil,0,{},{}
local samples,powered,visible=0,0,0
local function save()
    if not phase then return end
    if SERVER then
        for _,line in ipairs(latest) do rows[#rows+1]=line end
    elseif phase:find('sonar') then
        rows[#rows+1]=string.format('phase=%s samples=%d powered=%d visible=%d',phase,samples,powered,visible)
    end
    File.Write('LocalMods/System-Aegis/aegis-perf-validation-'..(SERVER and 'server' or 'client')..'.txt',table.concat(rows,'\n'))
end
Hook.Add('think','aegis.suit.performance.validation',function()
    if R.phase~=phase then
        save();phase=R.phase;started=G.now;latest={};samples=0;powered=0;visible=0
    end
    if not phase or phase=='done' or phase=='setup' or phase=='waiting' then return end
    if SERVER then
        latest={}
        for i,a in ipairs(R.actors) do
            local s=G.state(a.suit)
            latest[#latest+1]=string.format('phase=%s wearer=%d mode=%s shots=%d repaired=%.3f active=%s',
                phase,i,s.mode,(s.shots or 0)-(a.startShots or 0),a.repaired or 0,tostring(s.active))
        end
    elseif phase:find('sonar') and G.now-started>=5 then
        samples=samples+1
        local suit=Entity.FindEntityByID(R.suitId or 0)
        local s=suit and G.states[suit]
        local sonar=suit and suit.GetComponentString('Sonar')
        if s and s.sonar and sonar and sonar.HasPower and sonar.Voltage>.5 then powered=powered+1 end
        if G.sonarPanel and G.sonarPanel.Visible and G.sonarView and G.sonarView.Rect.Width>100 then visible=visible+1 end
    end
end)
