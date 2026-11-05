local M={}
function M.install(G,E)
    local suction,grinding,lastGrind={},{},{}
    function G.suctionActive(item,state)
        if item.Removed then return false end
        local ctx=G.context(item)
        return ctx.valid and ctx.aim and G.charge(item)>0 and not G.jobs[ctx.pack] and not G.pending[ctx.pack]
            and (G.now-(state.usedAt or -100)<.15 or (G.remoteActiveUntil[item.ID] or 0)>G.now)
    end
    local function stop(channel) if channel then channel.FadeOutAndDispose() end end
    function G.onSalvage(id)
        local item=E.Entity.FindEntityByID(id)
        if not item or item.Removed or G.now-(lastGrind[id] or -100)<.18 then return end
        lastGrind[id]=G.now
        local channel=E.SoundPlayer.PlaySound('aegis_vacuum_salvage',item.WorldPosition)
        if channel then grinding[#grinding+1]=channel end
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
        for i=#grinding,1,-1 do if not grinding[i].IsPlaying then stop(grinding[i]);table.remove(grinding,i) end end
    end
    function G.clearAudio()
        for _,ch in pairs(suction) do stop(ch) end
        for _,ch in ipairs(grinding) do stop(ch) end
        suction={};grinding={};lastGrind={}
    end
end
return M
