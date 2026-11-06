local M={}
function M.install(G,E)
    local suction,grinding={},{}
    function G.suctionActive(item,state)
        if item.Removed then return false end
        if G.now-(state.usedAt or -100)>=.15 and (G.remoteActiveUntil[item.ID] or 0)<=G.now then return false end
        local ctx=G.context(item)
        return ctx.valid and ctx.aim and G.charge(item)>0 and not G.pending[ctx.pack]
    end
    local function stop(channel) if channel then channel.FadeOutAndDispose() end end
    function G.onSalvage(id)
        local item=E.Entity.FindEntityByID(id)
        if not item or item.Removed then return end
        local active=grinding[item]
        if not active or not active.channel.IsPlaying then
            local channel=E.SoundPlayer.PlaySound('aegis_vacuum_salvage',item.WorldPosition)
            if not channel then return end
            channel.Looping=true
            active={channel=channel};grinding[item]=active
        end
        active.untilTime=G.now+.5
    end
    function G.updateAudio()
        for item,state in pairs(G.states) do
            if G.suctionActive(item,state) then
                local ch=suction[item]
                if not ch or not ch.IsPlaying then
                    ch=E.SoundPlayer.PlaySound('aegis_vacuum_suction',item.WorldPosition)
                    if ch then ch.Looping=true;suction[item]=ch end
                end
                if ch then local p=item.WorldPosition;ch.Position=E.Vector3(p.X,p.Y,0) end
            end
        end
        for item,ch in pairs(suction) do
            if not G.states[item] or not G.suctionActive(item,G.states[item]) then stop(ch);suction[item]=nil end
        end
        for item,active in pairs(grinding) do
            if item.Removed or G.now>=active.untilTime or not active.channel.IsPlaying then
                stop(active.channel);grinding[item]=nil
            else local p=item.WorldPosition;active.channel.Position=E.Vector3(p.X,p.Y,0) end
        end
    end
    function G.clearAudio()
        for _,ch in pairs(suction) do stop(ch) end
        for _,active in pairs(grinding) do stop(active.channel) end
        suction={};grinding={}
    end
end
return M
