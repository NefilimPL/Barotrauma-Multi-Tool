local Core=require('SalvageVacuum.core')
local M={}
function M.install(G,E)
    local tickets,queued,counter={},{},0
    local function plan(ctx,id,individual)
        if not ctx.valid or G.pending[ctx.pack] or G.jobs[ctx.pack] then return end
        local roots
        for _,group in ipairs(G.storageView(ctx.pack).groups) do
            for _,r in ipairs(group.items) do if r.id==id then
                roots={}
                if individual then roots[1]=r.item
                else for _,entry in ipairs(group.items) do roots[#roots+1]=entry.item end end
                break
            end end
            if roots then break end
        end
        if not roots then return end
        local items=Core.snapshot(roots,G.children)
        for _,item in ipairs(items) do
            if item.Removed or G.reserved[item] or not G.has(ctx.pack,item) then return end
        end
        return items
    end
    function G.prepareTrash(ctx,id,individual)
        local items=plan(ctx,id,individual)
        if not items then return false end
        counter=counter%65535+1
        local ticket={pack=ctx.pack,id=id,token=counter,count=#items,items=items,individual=individual,expires=G.now+10}
        tickets[ctx.owner]=ticket
        return ticket
    end
    function G.trashTicket(ctx)
        local t=tickets[ctx.owner]
        if t and t.pack==ctx.pack and t.expires>=G.now and not G.jobs[ctx.pack] and not G.pending[ctx.pack] then return t end
    end
    function G.confirmTrash(ctx,id,token)
        local ticket=ctx.valid and G.trashTicket(ctx)
        if not ticket or ticket.id~=id or ticket.token~=token then return false end
        tickets[ctx.owner]=nil
        local items=plan(ctx,id,ticket.individual)
        if not items or #items~=#ticket.items then return false end
        local known={};for _,item in ipairs(ticket.items) do known[item]=true end
        for _,item in ipairs(items) do if not known[item] then return false end end
        local tx={trash=true,products={},items=items}
        G.pending[ctx.pack]=tx;queued[ctx.pack]=tx
        for _,item in ipairs(items) do G.reserved[item]=true;E.Entity.Spawner.AddItemToRemoveQueue(item) end
        return true
    end
    function G.updateTrash()
        for pack,tx in pairs(queued) do
            local done=true;for _,item in ipairs(tx.items) do if not item.Removed then done=false;break end end
            if done then
                for _,item in ipairs(tx.items) do G.reserved[item]=nil end
                if G.pending[pack]==tx then G.pending[pack]=nil end
                queued[pack]=nil
            end
        end
        for owner,t in pairs(tickets) do if owner.Removed or t.expires<G.now then tickets[owner]=nil end end
    end
    function G.clearTrash()
        tickets={}
        for pack,tx in pairs(queued) do if G.pending[pack]==tx then G.pending[pack]=nil end end
        queued={}
    end
end
return M
