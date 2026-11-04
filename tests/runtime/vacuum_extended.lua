-- Test only: isolated campaign server, vanilla + LuaCs + MULTI-TOOL-V2.
local U=require('CombatTool.util')
local Core=require('SalvageVacuum.core')
local G=BMTVacuum
local R={results={},metrics={},prefix='bmtvac_20261104_',expected={},stressCount=0}
VacuumExtended=R
for _,name in ipairs({'System.Diagnostics.Stopwatch','Barotrauma.GameMain','Barotrauma.SaveUtil',
    'Barotrauma.CampaignDataPath','Barotrauma.SubmarineInfo'}) do LuaUserData.RegisterType(name) end
local Clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch')
local Main=LuaUserData.CreateStatic('Barotrauma.GameMain')
local function write()
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-extended-results.txt',table.concat(R.results,'\n'))
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-extended-metrics.txt',table.concat(R.metrics,'\n'))
end
function R.check(name,fn)
    local ok,err=pcall(fn)
    local row=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    R.results[#R.results+1]=row;print('[VACUUM EXTENDED] '..row);write()
    return ok
end
function R.measure(name,fn,count)
    local samples={}
    for i=1,(count or 1) do
        local sw=Clock.StartNew();fn();sw.Stop();samples[#samples+1]=sw.ElapsedMilliseconds
    end
    table.sort(samples)
    local sum=0;for _,v in ipairs(samples) do sum=sum+v end
    local row=string.format('%s: n=%d min=%dms median=%dms max=%dms mean=%.2fms',name,#samples,
        samples[1],samples[math.ceil(#samples/2)],samples[#samples],sum/#samples)
    R.metrics[#R.metrics+1]=row;print('[VACUUM METRIC] '..row);write()
end
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub then room=h;break end end
assert(room,'campaign submarine not loaded')
R.room=room
function R.create(kind,label,condition,quality)
    local item=Item(ItemPrefab.Prefabs[kind],room.Position,Submarine.MainSub)
    item.AddTag(R.prefix..label)
    if quality then item.Quality=quality end
    if condition then item.Condition=condition end
    return item
end
function R.find(label)
    if R.tagged then
        local items=R.tagged[label] or {}
        assert(#items==1,'expected one '..label..', got '..#items)
        return items[1]
    end
    local found={}
    for item in Item.ItemList do if item.HasTag(R.prefix..label) then found[#found+1]=item end end
    assert(#found==1,'expected one '..label..', got '..#found)
    return found[1]
end
function R.mark(item,label)
    R.expected[label]={kind=G.id(item),condition=item.Condition,quality=item.Quality}
end
function R.setup()
    R.pack=R.create('aegisvacuumpack','pack')
    R.vacuum=R.create('aegisvacuum','vacuum')
    R.battery=R.create('fulguriumbatterycell','battery',67.875)
    assert(R.vacuum.OwnInventory.TryPutItem(R.battery,nil))
    for i=1,2 do
        local page=R.create('aegisvacuumpage','smallpage'..i)
        assert(R.pack.OwnInventory.TryPutItem(page,nil))
    end
    for i=1,101 do
        local item=R.create('iron','iron'..i,20+i%70)
        assert(G.insert(R.pack,item,nil));R.mark(item,'iron'..i)
    end
    local crate=R.create('metalcrate','crate',61)
    local ammo=R.create('smgmagazine','ammo',37.25)
    assert(crate.OwnInventory.TryPutItem(ammo,nil))
    assert(G.insert(R.pack,crate,nil));R.mark(crate,'crate');R.mark(ammo,'ammo')
    local suit=R.create('divingsuit','suit',73.5,2)
    local tank=R.create('oxygentank','tank',46.75)
    assert(suit.OwnInventory.TryPutItem(tank,nil));assert(G.insert(R.pack,suit,nil))
    R.mark(suit,'suit');R.mark(tank,'tank')
    local wrench=R.create('wrench','quality',81,3)
    assert(G.insert(R.pack,wrench,nil));R.mark(wrench,'quality')
    R.mark(R.vacuum,'vacuum');R.mark(R.battery,'battery')
    R.check('mixed campaign fixture has 104 root items and nested crate/suit contents',function()
        assert(#G.contents(R.pack)==104)
        assert(R.ammo==nil and G.has(R.pack,ammo) and G.has(R.pack,tank))
    end)
end
function R.verify(label)
    R.check(label,function()
        R.tagged={}
        for item in Item.ItemList do
            for token in item.Tags:gmatch('[^,]+') do
                local key=token:match('^'..R.prefix..'(.+)$')
                if key then R.tagged[key]=R.tagged[key] or {};table.insert(R.tagged[key],item) end
            end
        end
        local pack=R.find('pack');local vacuum=R.find('vacuum');local battery=R.find('battery')
        assert(#G.contents(pack)==104,'wrong root count '..#G.contents(pack))
        assert(vacuum.OwnInventory.GetItemAt(0)==battery,'battery moved/lost')
        for key,expected in pairs(R.expected) do
            local item=R.find(key)
            assert(G.id(item)==expected.kind,'wrong type '..key)
            assert(math.abs(item.Condition-expected.condition)<.02,'condition changed '..key..' '..item.Condition)
            assert(item.Quality==expected.quality,'quality changed '..key)
        end
        assert(R.find('ammo').ParentInventory==R.find('crate').OwnInventory)
        assert(R.find('tank').ParentInventory==R.find('suit').OwnInventory)
        R.pack,R.vacuum,R.battery=pack,vacuum,battery
    end)
end
function R.save()
    local manifest={}
    for key,v in pairs(R.expected) do manifest[#manifest+1]=table.concat({key,v.kind,v.condition,v.quality},'\t') end
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-extended-expected.txt',table.concat(manifest,'\n'))
    Main.GameSession.SubmarineInfo=LuaUserData.CreateStatic('Barotrauma.SubmarineInfo')(Submarine.MainSub)
    local save=LuaUserData.CreateStatic('Barotrauma.SaveUtil')
    R.measure('native campaign save',function() save.SaveGame(Main.GameSession.DataPath) end)
    R.path=Main.GameSession.DataPath.SavePath
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-campaign-savepath.txt',R.path)
    print('[VACUUM EXTENDED] Saved '..R.path)
end
function R.stress()
    R.stressPack=R.create('aegisvacuumpack','stresspack')
    local stopwatch=Clock.StartNew()
    local pageIndex=0
    local function nextPage()
        local ok,err=pcall(function()
            pageIndex=pageIndex+1
            local page=R.create('aegisvacuumpage','stresspage'..pageIndex)
            assert(R.stressPack.OwnInventory.TryPutItem(page,nil))
            for i=1,100 do
                R.stressCount=R.stressCount+1
                local item=R.create('iron','stressitem'..R.stressCount,10+R.stressCount%80)
                assert(page.OwnInventory.TryPutItem(item,i-1,false,false,nil,false,true,false))
            end
        end)
        if not ok then R.check('create 10000 actual entities',function() error(err) end);return end
        if pageIndex<100 then Timer.Wait(nextPage,1);return end
        stopwatch.Stop()
        R.metrics[#R.metrics+1]='create 10000 actual items: '..stopwatch.ElapsedMilliseconds..'ms wall time (batched 100/frame)'
        R.check('10000 actual entities form exactly 100 groups of 100',function()
            local items=G.contents(R.stressPack);local groups=Core.groups(G.records(items))
            assert(#items==10000 and #groups==100)
            for _,group in ipairs(groups) do assert(#group.items==100) end
        end)
        R.check('10001st item is rejected without losing source',function()
            local extra=R.create('iron','overflow',53)
            assert(not G.insert(R.stressPack,extra,nil))
            assert(not extra.Removed and extra.ParentInventory==nil)
        end)
        R.measure('contents 10000',function() assert(#G.contents(R.stressPack)==10000) end,10)
        R.measure('grouping 10000',function() Core.groups(G.records(G.contents(R.stressPack))) end,10)
        local context={pack=R.stressPack,vacuum=R.vacuum,owner={Inventory={AllItems={R.stressPack}}}}
        R.measure('snapshot 10000',function() local s=G.snapshot(context,{});assert(s.count==10000 and #s.rows==8) end,10)
        R.measure('update with 10000 stored entities',function() G.update(.1) end,20)
        write();print('[VACUUM EXTENDED] STRESS COMPLETE')
    end
    nextPage()
end
function R.restoreExpected()
    local manifest=File.Read('LocalMods/MULTI-TOOL-V2/vacuum-extended-expected.txt')
    for line in manifest:gmatch('[^\r\n]+') do
        local key,kind,condition,quality=line:match('([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)')
        assert(key,'invalid expected manifest')
        R.expected[key]={kind=kind,condition=tonumber(condition),quality=tonumber(quality)}
    end
end
function R.verifyStress(label)
    R.check(label,function()
        local pack=R.find('stresspack')
        local items=G.contents(pack)
        assert(#items==10000,'stress count '..#items)
        local groups=Core.groups(G.records(items));assert(#groups==100)
        local seen={}
        for _,item in ipairs(items) do
            local id=tonumber(item.Tags:match(R.prefix..'stressitem(%d+)'))
            assert(id and not seen[id],'missing/duplicate identity')
            seen[id]=true
            assert(math.abs(item.Condition-(10+id%80))<.02,'stress item condition changed')
        end
        R.stressPack=pack
    end)
end
if not _G.VacuumExtendedRestoreOnly then R.setup() end
