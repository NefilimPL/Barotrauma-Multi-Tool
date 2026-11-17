local C=require('DescendantSuit.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local modes={off=0,repair=1,combat=2,grab=3,toggle=4,sonar=5,sonaractive=6,sonarpassive=7,minerals=8}
    local names={[0]='off','repair','combat','grab','toggle','sonar','sonaractive','sonarpassive','minerals'}
    local kinds={repair=1,weld=2,combat=3,grab=4}
    local kindNames={'repair','weld','combat','grab'}
    local nextSend,hadStates,requests=0,false,setmetatable({},{__mode='k'})
    function G.requestMode(item,mode)
        if not modes[mode] then return end
        if G.authoritative then return G.setMode(item,mode,E.Character.Controlled) end
        local m=E.Networking.Start(C.protocol..'.mode')
        m.WriteUInt16(item.ID);m.WriteByte(modes[mode]);E.Networking.Send(m)
    end
    if E.SERVER then
        E.Networking.Receive(C.protocol..'.mode',function(m,client)
            local id,mode=m.ReadUInt16(),names[m.ReadByte()]
            if not G.alive or not mode or not client then return end
            -- Independent sonar/arm controls can arrive in the same packet burst.
            local budget=requests[client] or {at=G.now,tokens=C.controlBurst}
            budget.tokens=math.min(C.controlBurst,budget.tokens+math.max(0,G.now-budget.at)*C.controlRate)
            budget.at=G.now;requests[client]=budget
            if budget.tokens<1 then return end
            budget.tokens=budget.tokens-1
            local item=E.Entity.FindEntityByID(id)
            if G.is(item) then G.authorize(client,item,mode) end
        end)
    end
    function G.sendSnapshot()
        if not E.SERVER or G.now<nextSend then return end
        nextSend=G.now+C.snapshotInterval
        local rows={};for item,s in pairs(G.states) do
            if not item.Removed and s.owner and #rows<128 then rows[#rows+1]=s end
        end
        if #rows==0 and not hadStates then return end
        hadStates=#rows>0
        local m=E.Networking.Start(C.protocol..'.snapshot')
        m.WriteByte(#rows)
        for _,s in ipairs(rows) do
            m.WriteUInt16(s.item.ID);m.WriteUInt16(s.owner.ID);m.WriteByte(modes[s.mode] or 0)
            m.WriteBoolean(s.open==true);m.WriteBoolean(s.swimming==true);m.WriteSingle(G.energy(s.item))
            m.WriteBoolean(s.active==true)
            m.WriteUInt16(s.shots or 0)
            m.WriteBoolean(s.sonar==true);m.WriteBoolean(s.sonarActive~=false)
            m.WriteBoolean(s.minerals==true)
            m.WriteUInt16(s.repairing and not s.repairing.Removed and s.repairing.ID or 0)
            m.WriteBoolean(s.lastPulse~=nil)
            if s.lastPulse then m.WriteSingle(s.lastPulse.x);m.WriteSingle(s.lastPulse.y) end
            m.WriteBoolean(s.toolAngles~=nil)
            if s.toolAngles then m.WriteSingle(s.toolAngles.upper);m.WriteSingle(s.toolAngles.lower);m.WriteSingle(s.toolAngles.head);m.WriteSingle(s.toolRotation or 0) end
            local target=s.target
            m.WriteByte(target and kinds[target.kind] or 0)
            if target then
                m.WriteUInt16(target.entity.ID);m.WriteSingle(target.point.x);m.WriteSingle(target.point.y)
            end
        end
        E.Networking.Send(m)
    end
    if E.CLIENT and not G.authoritative then
        E.Networking.Receive(C.protocol..'.snapshot',function(m)
            if not G.alive then return end
            local count=m.ReadByte();if count>128 then return end
            local seen={}
            for i=1,count do
                local id,ownerId,mode=m.ReadUInt16(),m.ReadUInt16(),names[m.ReadByte()]
                local open,swimming,charge=m.ReadBoolean(),m.ReadBoolean(),m.ReadSingle()
                local active=m.ReadBoolean()
                local shots=m.ReadUInt16()
                local sonar,sonarActive=m.ReadBoolean(),m.ReadBoolean()
                local minerals=m.ReadBoolean()
                local repairing=E.Entity.FindEntityByID(m.ReadUInt16())
                local lastPulse
                if m.ReadBoolean() then
                    local x,y=m.ReadSingle(),m.ReadSingle()
                    if x==x and y==y and math.abs(x)<1e8 and math.abs(y)<1e8 then lastPulse={x=x,y=y} end
                end
                local toolAngles,toolRotation
                if m.ReadBoolean() then
                    local upper,lower,head=m.ReadSingle(),m.ReadSingle(),m.ReadSingle()
                    toolRotation=m.ReadSingle()
                    if upper==upper and lower==lower and head==head and
                        math.abs(upper)<=math.pi+.001 and math.abs(lower)<=math.pi+.001 and math.abs(head)<=math.pi+.001 then
                        toolAngles={upper=upper,lower=lower,head=head}
                    end
                end
                local kind=kindNames[m.ReadByte()]
                local target
                if kind then
                    local entityId,x,y=m.ReadUInt16(),m.ReadSingle(),m.ReadSingle()
                    target={kind=kind,entity=E.Entity.FindEntityByID(entityId),point={x=x,y=y}}
                end
                local item,owner=E.Entity.FindEntityByID(id),E.Entity.FindEntityByID(ownerId)
                if G.is(item) and owner and mode and charge==charge then
                    local s=G.state(item);seen[item]=true
                    s.owner=owner;s.mode=mode;s.open=open;s.swimming=swimming;s.charge=charge
                    s.active=active and target~=nil;s.target=target;s.received=G.now;s.shots=shots
                    s.sonar=sonar;s.sonarActive=sonarActive;s.lastPulse=lastPulse
                    s.minerals=minerals
                    s.repairing=repairing
                    s.toolAngles=toolAngles
                    s.toolRotation=toolRotation
                    if not toolAngles then s.drawAngles=nil end
                end
            end
            for item,s in pairs(G.states) do if not seen[item] then
                if G.stopSonar then G.stopSonar(item,s) end
                G.states[item]=nil
            end end
        end)
    end
end
return M
