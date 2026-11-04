local Core=require('SalvageVacuum.core')
local Recipes=require('SalvageVacuum.recipes')
local C=Core.config
local M={}
function M.install(G,E)
    function G.startSalvage(ctx)
        if not ctx.valid or not G.is(ctx.vacuum,C.vacuum) or G.charge(ctx.vacuum)<=0 or G.jobs[ctx.pack] or G.pending[ctx.pack] then return false end
        local items=Core.snapshot(G.contents(ctx.pack),G.children)
        G.jobs[ctx.pack]={ctx=ctx,items=items,index=1,done=0,skipped=0}
        return true
    end
    local function rollback(tx)
        for _,product in ipairs(tx.products) do
            if not product.Removed then E.Entity.Spawner.AddItemToRemoveQueue(product) end
        end
        if tx.battery and not tx.battery.Removed then
            tx.battery.Condition=math.min(tx.battery.MaxCondition,tx.battery.Condition+tx.debit)
        end
    end
    local function finish(tx)
        local ctx=G.context(tx.ctx.vacuum,tx.ctx.owner)
        local valid=G.alive and not tx.cancelled and ctx.valid and ctx.pack==tx.ctx.pack
            and not tx.item.Removed and G.has(ctx.pack,tx.item)
        for _,p in ipairs(tx.products) do
            if p.Removed or not G.has(tx.ctx.pack,p) then valid=false end
        end
        if valid then
            -- Spawns and removal are consumed by the same native spawner pass;
            -- only complete source or complete products survive a campaign save.
            E.Entity.Spawner.AddItemToRemoveQueue(tx.item)
            tx.job.done=tx.job.done+1
        else rollback(tx);tx.job.skipped=tx.job.skipped+1 end
        G.reserved[tx.item]=nil;G.pending[tx.ctx.pack]=nil
    end
    function G.processSalvage(job)
        local ctx=G.context(job.ctx.vacuum,job.ctx.owner)
        if not ctx.valid or ctx.pack~=job.ctx.pack or G.charge(ctx.vacuum)<C.salvageCost then
            G.jobs[job.ctx.pack]=nil;return
        end
        if G.pending[ctx.pack] then return end
        local item=job.items[job.index]
        if not item then G.jobs[ctx.pack]=nil;return end
        if item.Removed or not G.has(ctx.pack,item) then job.index=job.index+1;return end
        local plan=Recipes.plan(E,item,ctx.vacuum)
        if not plan then job.index=job.index+1;job.skipped=job.skipped+1;return end
        local children=G.children(item)
        local remaining={}
        for _,i in ipairs(G.contents(ctx.pack)) do if i~=item then remaining[#remaining+1]=i end end
        local extra=G.records(children)
        for _,p in ipairs(plan) do extra[#extra+1]=p end
        if not Core.canFit(G.records(remaining),extra) then job.index=job.index+1;job.skipped=job.skipped+1;return end
        if not G.ensureSpace(ctx.pack,#children+#plan) then
            if #G.pages(ctx.pack)>=C.pages then job.index=job.index+1;job.skipped=job.skipped+1 end
            return
        end
        -- Move surviving nested content before removal; never discard it with its casing.
        for _,child in ipairs(children) do
            if not G.insert(ctx.pack,child,ctx.owner,true) then job.index=job.index+1;job.skipped=job.skipped+1;return end
        end
        local slots=G.freeSlots(ctx.pack,#plan)
        local battery=G.source(ctx.vacuum)
        local before=battery.Condition
        if not G.spend(ctx.vacuum,C.salvageCost) then return end
        local tx={ctx=ctx,item=item,job=job,battery=battery,debit=before-battery.Condition,products={},expected=#plan}
        G.pending[ctx.pack]=tx;G.reserved[item]=true;job.index=job.index+1
        for i,p in ipairs(plan) do
            E.Entity.Spawner.AddItemToSpawnQueue(p.prefab,slots[i].inv,p.condition,nil,function(product)
                product.StolenDuringRound=item.StolenDuringRound
                product.AllowStealing=item.AllowStealing
                product.OriginalOutpost=item.OriginalOutpost
                product.SpawnedInCurrentOutpost=item.SpawnedInCurrentOutpost
                tx.products[#tx.products+1]=product
                if #tx.products==tx.expected then finish(tx) end
            end,false)
        end
    end
end
return M
