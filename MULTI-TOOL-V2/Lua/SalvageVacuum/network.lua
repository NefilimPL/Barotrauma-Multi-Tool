local Core=require('SalvageVacuum.core')
local C=Core.config
local M={}
function M.install(G,E)
    local actions={'open','withdraw','salvage','select','stack','filter','preparetrash','trash'}
    local ids={open=1,withdraw=2,salvage=3,select=4,stack=5,filter=6,preparetrash=7,trash=8}
    local pageSize=C.viewColumns*C.viewRows
    G.lastPoll=G.lastPoll or {}
    function G.normalizeView(view)
        view=view or {}
        local category='all'
        for _,name in ipairs(C.categories) do if name==view.category then category=name end end
        return {page=math.max(0,math.min(65534,math.floor(view.page or 0))),category=category,filters=view.filters==true,
            kind=tostring(view.kind or ''):sub(1,100),confirm=math.max(0,math.min(65535,math.floor(view.confirm or 0))),
            group=math.max(0,math.min(100,math.floor(view.group or 0))),search=tostring(view.search or ''):sub(1,64)}
    end
    function G.handleRequest(client,action,vacuum,target,view)
        if not G.alive or not G.authoritative or not G.authorize(client,vacuum) or not ids[action] then return false end
        local key=client.Character
        local quota=action=='open' and G.lastPoll or G.lastRequest
        if G.now-(quota[key] or -100)<.1 then return false end
        quota[key]=G.now
        local ctx=G.context(vacuum,client.Character)
        view=G.normalizeView(view)
        if action=='withdraw' then return G.withdraw(ctx,target) end
        if action=='stack' then return G.withdrawStack(ctx,target) end
        if action=='salvage' then return G.startSalvage(ctx) end
        if action=='filter' then
            if target~=0 and target~=1 then return false end
            return G.setExcluded(ctx,view.kind,target==1)
        end
        if action=='preparetrash' then return G.prepareTrash(ctx,target,view.group>0)~=false end
        if action=='trash' then return G.confirmTrash(ctx,target,view.confirm) end
        if action=='select' then
            if G.jobs[ctx.pack] or G.pending[ctx.pack] then return false end
            for _,pack in ipairs(G.packs(ctx.owner)) do
                if pack.ID==target then G.selected[vacuum.ID]=target;return true end
            end
            return false
        end
        return true
    end
    function G.snapshot(ctx,view)
        view=G.normalizeView(view)
        local cached=G.storageView and G.storageView(ctx.pack)
        local records,groups,count
        if cached then groups,count=cached.groups,cached.count
        else
            records=G.records(G.contents(ctx.pack))
            table.sort(records,function(a,b) return a.kind==b.kind and a.id<b.id or a.kind<b.kind end)
            groups=Core.groups(records);count=#records
        end
        local rows={}
        local filter=G.filter and G.filter(ctx.pack) or {}
        if view.filters then
            for _,entry in ipairs(G.filterCatalog(view)) do
                rows[#rows+1]={id=0,kind=entry.kind,count=1,group=0,name=entry.name,condition=0,quality=0,
                    excluded=entry.blocked or filter[entry.kind]==true,blocked=entry.blocked}
            end
        elseif view.group>0 and groups[view.group] then
            for _,record in ipairs(groups[view.group].items) do
                local item=record.item
                rows[#rows+1]={id=item.ID,kind=record.kind,count=1,group=view.group,name=tostring(item.Name),
                    condition=item.MaxCondition>0 and item.Condition/item.MaxCondition*100 or 0,quality=item.Quality}
            end
        else
            for index,group in ipairs(groups) do
                local item=group.items[1].item
                local name=tostring(item.Name)
                if (not G.categoryMatches or G.categoryMatches(item.Prefab,view.category)) and
                    (view.search=='' or name:lower():find(view.search:lower(),1,true) or group.kind:find(view.search:lower(),1,true)) then
                    rows[#rows+1]={id=item.ID,kind=group.kind,count=#group.items,group=index,name=name,
                        condition=item.MaxCondition>0 and item.Condition/item.MaxCondition*100 or 0,quality=item.Quality}
                end
            end
        end
        if not view.filters then for _,row in ipairs(rows) do row.excluded=filter[row.kind]==true end end
        local page=math.min(view.page,math.max(0,math.ceil(#rows/pageSize)-1))
        local selected={}
        for i=page*pageSize+1,math.min(#rows,page*pageSize+pageSize) do selected[#selected+1]=rows[i] end
        local available=G.is(ctx.vacuum,C.vacuum) and G.packs(ctx.owner) or G.availablePacks(ctx.owner)
        local packs={};for _,pack in ipairs(available) do packs[#packs+1]=pack.ID end
        local present=false;for _,id in ipairs(packs) do if id==ctx.pack.ID then present=true end end
        if not present then packs[#packs+1]=ctx.pack.ID end
        local ticket=G.trashTicket and G.trashTicket(ctx)
        return {vacuum=ctx.vacuum.ID,pack=ctx.pack.ID,packs=packs,charge=G.charge(ctx.vacuum),
            busy=G.jobs[ctx.pack]~=nil or G.pending[ctx.pack]~=nil,count=count,groups=#groups,
            page=page,pages=math.min(65535,math.max(1,math.ceil(#rows/pageSize))),rows=selected,group=view.group,
            filters=view.filters,category=view.category,search=view.search,
            trashTarget=ticket and ticket.id or 0,trashToken=ticket and ticket.token or 0,trashCount=ticket and ticket.count or 0}
    end
    local function sendSnapshot(client,vacuum,view)
        local ctx=G.context(vacuum,client.Character)
        if not ctx.valid then return end
        local s=G.snapshot(ctx,view)
        local m=E.Networking.Start(C.protocol..'.snapshot')
        m.WriteUInt16(s.vacuum);m.WriteUInt16(s.pack);m.WriteSingle(s.charge);m.WriteBoolean(s.busy)
        m.WriteUInt16(s.count);m.WriteByte(s.groups);m.WriteUInt16(s.page);m.WriteUInt16(s.pages);m.WriteByte(s.group)
        m.WriteBoolean(s.filters);m.WriteString(s.category);m.WriteString(s.search)
        m.WriteUInt16(s.trashTarget);m.WriteUInt16(s.trashToken);m.WriteUInt16(math.min(65535,s.trashCount))
        m.WriteByte(math.min(100,#s.packs));for i=1,math.min(100,#s.packs) do m.WriteUInt16(s.packs[i]) end
        m.WriteByte(#s.rows)
        for _,r in ipairs(s.rows) do
            m.WriteUInt16(r.id);m.WriteByte(r.count);m.WriteByte(r.group)
            m.WriteString(r.kind:sub(1,100))
            m.WriteString(r.name:sub(1,100));m.WriteSingle(r.condition);m.WriteByte(math.min(255,r.quality))
            m.WriteBoolean(r.excluded==true);m.WriteBoolean(r.blocked==true)
        end
        E.Networking.Send(m,client.Connection)
    end
    if E.SERVER then
        E.Networking.Receive(C.protocol..'.request',function(m,client)
            local ok,err=pcall(function()
                local action=actions[m.ReadByte()]
                local vacuum=E.Entity.FindEntityByID(m.ReadUInt16())
                local target=m.ReadUInt16()
                local view={page=m.ReadUInt16(),group=m.ReadByte(),search=m.ReadString():sub(1,64),
                    filters=m.ReadBoolean(),category=m.ReadString():sub(1,20),kind=m.ReadString():sub(1,100),confirm=m.ReadUInt16()}
                if G.handleRequest(client,action,vacuum,target,view) then sendSnapshot(client,vacuum,view) end
            end)
            if not ok and E.printerror then E.printerror('[Aegis Vacuum] Invalid request: '..tostring(err)) end
        end)
    end
    if E.CLIENT then
        E.Networking.Receive(C.protocol..'.snapshot',function(m)
            if not G.alive then return end
            local s={vacuum=m.ReadUInt16(),pack=m.ReadUInt16(),charge=m.ReadSingle(),busy=m.ReadBoolean(),
                count=m.ReadUInt16(),groups=m.ReadByte(),page=m.ReadUInt16(),pages=m.ReadUInt16(),group=m.ReadByte(),
                filters=m.ReadBoolean(),category=m.ReadString(),search=m.ReadString(),
                trashTarget=m.ReadUInt16(),trashToken=m.ReadUInt16(),trashCount=m.ReadUInt16(),packs={},rows={}}
            local count=m.ReadByte();if count>100 then return end
            for i=1,count do s.packs[i]=m.ReadUInt16() end
            count=m.ReadByte();if count>pageSize then return end
            for i=1,count do s.rows[i]={id=m.ReadUInt16(),count=m.ReadByte(),group=m.ReadByte(),
                kind=m.ReadString(),name=m.ReadString(),condition=m.ReadSingle(),quality=m.ReadByte(),
                excluded=m.ReadBoolean(),blocked=m.ReadBoolean()} end
            if G.onSnapshot then G.onSnapshot(s) end
        end)
    end
    function G.request(action,vacuum,target,view)
        view=G.normalizeView(view)
        if G.authoritative then
            local client={Character=E.Character.Controlled}
            if G.handleRequest(client,action,vacuum,target or 0,view) and G.onSnapshot then
                G.onSnapshot(G.snapshot(G.context(vacuum,E.Character.Controlled),view))
            end
            return
        end
        local m=E.Networking.Start(C.protocol..'.request')
        m.WriteByte(ids[action]);m.WriteUInt16(vacuum.ID);m.WriteUInt16(target or 0)
        m.WriteUInt16(view.page);m.WriteByte(view.group);m.WriteString(view.search)
        m.WriteBoolean(view.filters);m.WriteString(view.category);m.WriteString(view.kind);m.WriteUInt16(view.confirm)
        E.Networking.Send(m)
    end
    function G.transferEffect(vacuum,point)
        if G.onTransfer then G.onTransfer(vacuum.ID,point) end
        if E.SERVER then
            local m=E.Networking.Start(C.protocol..'.transfer')
            m.WriteUInt16(vacuum.ID);m.WriteSingle(point.x);m.WriteSingle(point.y)
            E.Networking.Send(m)
        end
    end
    if E.CLIENT then E.Networking.Receive(C.protocol..'.transfer',function(m)
        local id=m.ReadUInt16();local p={x=m.ReadSingle(),y=m.ReadSingle()}
        if G.alive and G.onTransfer then G.onTransfer(id,p) end
    end) end
    local activeSenders={}
    function G.resetNetwork()
        activeSenders={};G.remoteActiveUntil={}
    end
    function G.sendActivity(vacuum,active)
        if not E.SERVER then return end
        -- Active heartbeats keep the remote timeout alive; idle nozzles stay silent.
        if not active and not activeSenders[vacuum.ID] then return end
        activeSenders[vacuum.ID]=active or nil
        local m=E.Networking.Start(C.protocol..'.activity')
        m.WriteUInt16(vacuum.ID);m.WriteBoolean(active);E.Networking.Send(m)
    end
    function G.salvageEffect(vacuum)
        if G.onSalvage then G.onSalvage(vacuum.ID) end
        if E.SERVER then
            local m=E.Networking.Start(C.protocol..'.salvage')
            m.WriteUInt16(vacuum.ID);E.Networking.Send(m)
        end
    end
    if E.CLIENT then E.Networking.Receive(C.protocol..'.salvage',function(m)
        local id=m.ReadUInt16()
        if G.alive and G.onSalvage then G.onSalvage(id) end
    end) end
    G.remoteActiveUntil={}
    if E.CLIENT then E.Networking.Receive(C.protocol..'.activity',function(m)
        local id=m.ReadUInt16();local active=m.ReadBoolean()
        if G.alive then G.remoteActiveUntil[id]=active and G.now+.4 or 0 end
    end) end
end
return M
