local C=require('SalvageVacuum.config')
local U=require('CombatTool.util')
local M={}
local categoryBits={medical=8,weapon=16,diving=32,equipment=64,fuel=128,electrical=256,material=1024,alien=2048,misc=32768}
function M.install(G,E)
    local prefix='bmt.vacuum.exclude.'
    local cache,entries,byKind,registry={},nil,nil,nil
    local slots={any=true,righthand=true,lefthand=true,bothhands=true,head=true,
        innerclothes=true,outerclothes=true,headset=true,card=true,bag=true,healthinterface=true}
    local pickables={pickable=true,holdable=true,wearable=true,idcard=true,planter=true,meleeweapon=true,throwable=true}
    local function encode(s)
        return (s:gsub('[%%,%s]',function(c) return string.format('%%%02x',string.byte(c)) end))
    end
    local function setTag(ctx,target,enabled)
        if not ctx.valid or G.jobs[ctx.pack] or G.pending[ctx.pack] or type(enabled)~='boolean' then return false end
        local result={}
        for tag in tostring(ctx.pack.Tags or ''):gmatch('[^,]+') do if tag~=target then result[#result+1]=tag end end
        if enabled then result[#result+1]=target end
        ctx.pack.Tags=table.concat(result,',')
        if E.SERVER then
            local property=ctx.pack.SerializableProperties[E.Identifier('Tags')]
            E.Networking.CreateEntityEvent(ctx.pack,E.Item.ChangePropertyEventData(property,ctx.pack))
        end
        return true
    end
    function G.looseOnly(pack)
        for tag in tostring(pack and pack.Tags or ''):gmatch('[^,]+') do if tag=='bmt.vacuum.looseonly' then return true end end
        return false
    end
    function G.setLooseOnly(ctx,enabled) return setTag(ctx,'bmt.vacuum.looseonly',enabled) end
    function G.filter(pack)
        local tags=tostring(pack and pack.Tags or '')
        local old=cache[pack]
        if old and old.tags==tags then return old.value end
        local value={}
        for tag in tags:gmatch('[^,]+') do
            if tag:sub(1,#prefix)==prefix then
                local kind=tag:sub(#prefix+1):gsub('%%(%x%x)',function(n) return string.char(tonumber(n,16)) end)
                value[kind]=true
            end
        end
        if pack then cache[pack]={tags=tags,value=value} end
        return value
    end
    function G.categoryMatches(prefab,category)
        if not category or category=='all' then return true end
        -- LuaCs exposes this native [Flags] enum as a number, including combinations.
        local value=prefab and prefab.Category
        local numeric=tonumber(value)
        local flags=tostring(value or ''):lower()
        local function has(name)
            return numeric and categoryBits[name] and math.floor(numeric/categoryBits[name])%2==1
                or (not numeric and flags:find(name,1,true)~=nil)
        end
        if has(category) then return true end
        if category~='misc' then return false end
        for _,name in ipairs(C.categories) do
            if name~='all' and name~='misc' and has(name) then return false end
        end
        return true
    end
    local function inventoryCapable(prefab)
        local capable=false
        if prefab.ConfigElement then U.each(prefab.ConfigElement.Elements(),function(element)
            local name=tostring(element.Name):lower()
            if name=='door' then capable='door';return end
            if capable=='door' then return end
            if element.GetAttributeBool('canbepicked',true) then
                local text=element.GetAttributeString('slots',pickables[name] and 'Any' or '')
                for slot in tostring(text):lower():gmatch('[^,+%s]+') do if slots[slot] then capable=true end end
            end
        end) end
        return capable==true
    end
    local function catalog()
        if entries and registry==E.ItemPrefab.Prefabs then return end
        entries,byKind,registry={},{},E.ItemPrefab.Prefabs
        U.each(registry,function(prefab)
            local kind=tostring(prefab.Identifier):lower()
            if kind~=C.page then
                local name=tostring(prefab.Name or kind)
                local row={kind=kind,name=name~='' and name or kind,prefab=prefab,blocked=not inventoryCapable(prefab)}
                entries[#entries+1]=row;byKind[kind]=row
            end
        end)
        table.sort(entries,function(a,b) return a.name==b.name and a.kind<b.kind or a.name<b.name end)
    end
    function G.filterCatalog(view)
        catalog();local out={};local search=tostring(view.search or ''):lower()
        for _,row in ipairs(entries) do
            if G.categoryMatches(row.prefab,view.category) and (search=='' or
                row.name:lower():find(search,1,true) or row.kind:find(search,1,true)) then out[#out+1]=row end
        end
        return out
    end
    function G.setExcluded(ctx,kind,excluded)
        if not ctx.valid or G.jobs[ctx.pack] or G.pending[ctx.pack] or type(kind)~='string'
            or #kind>100 or type(excluded)~='boolean' then return false end
        catalog();local row=byKind[kind]
        if not row or row.blocked then return false end
        return setTag(ctx,prefix..encode(kind),excluded)
    end
    function G.acceptsLoot(pack,item)
        local filter,seen,budget=G.filter(pack),{},0
        local function visit(node)
            if seen[node] or budget>=C.pickupTreeLimit then return false end
            seen[node]=true;budget=budget+1
            if filter[G.id(node)] then return false end
            for _,child in ipairs(G.children(node)) do if not visit(child) then return false end end
            return true
        end
        return visit(item)
    end
    function G.clearFilters() cache={};entries=nil;byKind=nil;registry=nil end
end
return M
