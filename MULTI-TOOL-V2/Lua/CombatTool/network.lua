local U=require('CombatTool.util')
local C=require('CombatTool.config')
local Core=require('CombatTool.core')
local N={}
function N.install(G,E)
    local snapshotName=C.protocol..'.snapshot'
    local eventName=C.protocol..'.effect'
    local eventIDs={charge=1,shot=2,hit=3,bounce=4,shieldhit=5,['break']=6,contact=7}
    G.eventNames={};for name,id in pairs(eventIDs) do G.eventNames[id]=name end
    G.authoritative=E.SERVER or E.Game.IsSingleplayer
    G.remote={shields={},rings={}}
    local sequence,lastSequence=0,-1
    local epoch=math.floor(E.Timer.GetTime()*1000)%4294967296
    local lastEpoch,oldEpochs=nil,{}
    function G.event(kind,s,position)
        local point=type(position)=='table' and position or U.point(position)
        local _,angle=G.direction(s.item)
        if point.nx and point.ny then angle=Core.angle(point.nx,point.ny) end
        if G.onEffect then G.onEffect(kind,point,angle,s.item.ID) end
        if not E.SERVER or not E.Game.Server then return end
        local message=E.Networking.Start(eventName)
        message.WriteByte(eventIDs[kind]);message.WriteUInt16(s.item.ID)
        message.WriteSingle(point.x);message.WriteSingle(point.y);message.WriteSingle(angle)
        E.Networking.Send(message)
    end
    if E.CLIENT then
        -- No custom client-to-server firing or damage messages exist. The native
        -- synchronized character inputs and CustomInterface own all requests.
        E.Networking.Receive(eventName,function(message)
            local kind=G.eventNames[message.ReadByte()]
            local id=message.ReadUInt16()
            local point={x=message.ReadSingle(),y=message.ReadSingle()}
            local angle=message.ReadSingle()
            if kind and G.onEffect then G.onEffect(kind,point,angle,id) end
        end)
        E.Networking.Receive(snapshotName,function(message)
            local incomingEpoch=message.ReadUInt32()
            local seq=message.ReadUInt32()
            local count=message.ReadUInt16()
            if count>128 then return end
            local shields={}
            for i=1,count do
                local id=message.ReadUInt16()
                shields[#shields+1]={id=id,x=message.ReadSingle(),y=message.ReadSingle(),angle=message.ReadSingle(),
                    radius=C.shieldRadius,halfAngle=C.shieldHalfAngle,energy=message.ReadSingle()}
            end
            local ringCount=message.ReadUInt16()
            if ringCount>C.maxRings then return end
            local rings={}
            for i=1,ringCount do
                rings[#rings+1]={id=message.ReadUInt16(),x=message.ReadSingle(),y=message.ReadSingle(),
                    dx=message.ReadSingle(),dy=message.ReadSingle(),radius=message.ReadSingle(),
                    age=message.ReadSingle(),distance=message.ReadSingle(),bouncesLeft=message.ReadByte(),
                    speed=C.speed,damageMultiplier=1,alive=true}
            end
            if incomingEpoch~=lastEpoch then
                if oldEpochs[incomingEpoch] then return end
                if lastEpoch then oldEpochs[lastEpoch]=true end
                lastEpoch=incomingEpoch;lastSequence=-1
            end
            if seq>lastSequence then
                lastSequence=seq
                G.remote={shields=shields,rings=rings,received=G.now,epoch=incomingEpoch}
            end
        end)
    end
    local nextSnapshot=0
    function G.sendSnapshot()
        if not E.SERVER or not E.Game.Server or G.now<nextSnapshot then return end
        nextSnapshot=G.now+C.snapshotInterval
        sequence=sequence+1
        local shields={}
        for _,s in pairs(G.states) do
            if s.shield and #shields<128 then shields[#shields+1]=s end
        end
        local message=E.Networking.Start(snapshotName)
        message.WriteUInt32(epoch);message.WriteUInt32(sequence);message.WriteUInt16(#shields)
        for _,s in ipairs(shields) do
            message.WriteUInt16(s.item.ID)
            message.WriteSingle(s.shield.x);message.WriteSingle(s.shield.y);message.WriteSingle(s.shield.angle)
            message.WriteSingle(G.source(s.item,1).condition)
        end
        message.WriteUInt16(#G.rings)
        for _,r in ipairs(G.rings) do
            message.WriteUInt16(r.id);message.WriteSingle(r.x);message.WriteSingle(r.y)
            message.WriteSingle(r.dx);message.WriteSingle(r.dy);message.WriteSingle(r.radius)
            message.WriteSingle(r.age);message.WriteSingle(r.distance);message.WriteByte(r.bouncesLeft)
        end
        E.Networking.Send(message)
    end
end
return N
