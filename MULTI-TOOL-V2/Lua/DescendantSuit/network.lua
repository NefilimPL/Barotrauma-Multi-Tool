local C=require('DescendantSuit.config')
local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local modes={off=0,repair=1,combat=2,grab=3}
    local names={[0]='off','repair','combat','grab'}
    local kinds={repair=1,weld=2,combat=3,grab=4}
    local kindNames={'repair','weld','combat','grab'}
    local nextSend,hadStates,lastRequest=0,false,{}
    function G.requestMode(item,mode)
        if not modes[mode] then return end
        if G.authoritative then return G.setMode(item,mode,E.Character.Controlled) end
        local m=E.Networking.Start(C.protocol..'.mode')
        m.WriteUInt16(item.ID);m.WriteByte(modes[mode]);E.Networking.Send(m)
    end
    if E.SERVER then
        E.Networking.Receive(C.protocol..'.mode',function(m,client)
            local id,mode=m.ReadUInt16(),names[m.ReadByte()]
            if not G.alive or not mode or not client or G.now-(lastRequest[client] or -100)<.1 then return end
            lastRequest[client]=G.now
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
                    s.active=active and target~=nil;s.target=target;s.received=G.now
                end
            end
            for item in pairs(G.states) do if not seen[item] then G.states[item]=nil end end
        end)
    end
end
return M
