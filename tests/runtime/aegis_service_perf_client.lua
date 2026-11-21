-- Short single joined-client frame interval check; not a multi-client stress test.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local G=AegisSuit;local P='aegis.servo.service.perf';local R={rows={}}
LuaUserData.RegisterType('Barotrauma.PerformanceCounter')
local main=LuaUserData.CreateStatic('Barotrauma.GameMain')
local function summary()
    if not R.samples or #R.samples==0 then return end
    local a=R.samples;table.sort(a);local sum=0;for _,v in ipairs(a) do sum=sum+v end
    local line=string.format('%s,%d,%.3f,%.3f,%.3f,%.3f,%.3f',R.label,#a,1000/(sum/#a),sum/#a,a[math.ceil(#a*.95)],a[math.ceil(#a*.99)],a[#a])
    R.rows[#R.rows+1]=line;File.Write('LocalMods/System-Aegis/servo-service-perf-client.csv',table.concat(R.rows,'\n'));print('[SERVO PERF CLIENT] '..line)
end
R.rows={'phase,frames,fps,mean_ms,p95_ms,p99_ms,max_ms'}
Networking.Receive(P..'.phase',function(m)
    summary();R.phase=m.ReadByte();R.label=m.ReadString();R.suit=Entity.FindEntityByID(m.ReadUInt16());R.samples={};R.started=G.now;R.last=nil
    if R.phase==4 then
        LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
        G.sonarHideButton.OnClicked.Invoke(G.sonarHideButton,nil)
    elseif R.phase==0 then Hook.RemovePatch(P,'Barotrauma.GameMain','Draw',Hook.HookMethodType.After);print('[SERVO PERF CLIENT] DONE') end
end)
Hook.Patch(P,'Barotrauma.GameMain','Draw',function()
    if not R.phase or R.phase==0 then return end
    local fps=main.PerformanceCounter.CurrentFramesPerSecond
    if fps>0 and G.now-R.started>=3 then R.samples[#R.samples+1]=1000/fps end
end,Hook.HookMethodType.After)
local ready=Networking.Start(P..'.ready');Networking.Send(ready)
