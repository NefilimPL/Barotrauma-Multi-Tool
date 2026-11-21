-- Four 20s phases, last17s measured. One real player and one held human.
assert(SERVER and Game.RoundStarted)
local G=AegisSuit;local B=ServoServiceMP;local c=B.wearer;local P='aegis.servo.service.perf'
local R={phase=0,rows={'phase,calls,work_ticks,mean_ms,p95_ms,p99_ms,max_ms'}}
LuaUserData.RegisterType('System.Diagnostics.Stopwatch')
local clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch')
local update=G.update
local labels={'off','grip','repair','grip_compact_sonar'}
local function summary()
    if not R.samples or #R.samples==0 then return end
    local a=R.samples;table.sort(a);local sum=0;for _,v in ipairs(a) do sum=sum+v end
    local line=string.format('%s,%d,%d,%.4f,%.4f,%.4f,%.4f',labels[R.phase],#a,R.work,sum/#a,a[math.ceil(#a*.95)],a[math.ceil(#a*.99)],a[#a])
    R.rows[#R.rows+1]=line;File.Write('LocalMods/System-Aegis/servo-service-perf-server.csv',table.concat(R.rows,'\n'));print('[SERVO PERF SERVER] '..line)
end
local function phase()
    summary();R.phase=R.phase+1;R.samples={};R.work=0;R.at=G.now
    G.setMode(B.suit,'off',c);local s=G.state(B.suit);B.cell.Condition=100;s.sonar=false
    if R.phase>4 then G.update=update;Hook.Remove('think',P);R.phase=0
    elseif R.phase==2 or R.phase==4 then
        B.human.TeleportTo(c.WorldPosition+Vector2(100,20));if B.human.IsDead then B.human.Revive() end
        B.human.SetAllDamage(0,0,0);B.human.Oxygen=100
        G.setMode(B.suit,'grab',c);local q=B.human.WorldPosition
        s.target={id='g'..B.human.ID,entity=B.human,kind='grab',point={x=q.X,y=q.Y},free=true,visible=true,distance=102}
        s.grabStarted=G.now;G.hold(c,B.suit,s.target,1/60)
        if R.phase==4 then s.sonar=true;s.sonarActive=true end
    elseif R.phase==3 then
        B.device.SetTransform(ConvertUnits.ToSimUnits(c.Position+Vector2(140,25)),0);B.device.Condition=5;G.setMode(B.suit,'repair',c)
    end
    local m=Networking.Start(P..'.phase');m.WriteByte(R.phase);m.WriteString(labels[R.phase] or 'done');m.WriteUInt16(B.suit.ID);Networking.Send(m,B.client.Connection)
end
G.update=function(dt)
    local t=clock.GetTimestamp();update(dt)
    if R.phase>0 and G.now-R.at>=3 then R.samples[#R.samples+1]=(clock.GetTimestamp()-t)*1000/clock.Frequency;if G.state(B.suit).active then R.work=R.work+1 end end
end
Hook.Add('think',P,function()
    if R.phase==3 and B.device.Condition>65 then B.device.Condition=5 end
    if R.phase>0 and G.now-R.at>=20 then phase() end
end)
Networking.Receive(P..'.ready',function(_,client) if client==B.client and R.phase==0 then phase() end end)
