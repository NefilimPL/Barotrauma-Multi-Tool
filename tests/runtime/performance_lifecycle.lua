-- TEST ONLY: disposable native rounds and campaign copies, not a benchmark.
assert(SERVER)
local root='LocalMods/MULTI-TOOL-V2/'
local log=assert(BMTLifecycleLog)
local L={owned={},pending=0};BMTLifecycle=L
local function write(line)
    print('[BMT LIFECYCLE] '..line)
    File.Write(root..log,(File.Exists(root..log) and File.Read(root..log) or '')..line..'\n')
end
function L.check(name,fn)
    local ok,err=pcall(fn);write((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err)))
    return ok
end
function L.signal(value) File.Write(root..log..'.ready',value) end
local function spawn(id,inv,fn)
    L.pending=L.pending+1
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],inv,nil,nil,function(item)
        L.owned[item]=true
        if fn then
            local ok,err=pcall(fn,item)
            if not ok then write('FAIL prepare '..id..': '..tostring(err)) end
        end
        L.pending=L.pending-1
    end,false)
end
local function client(name) for c in Client.ClientList do if c.Name==name then return c end end end
local function equip(id,owner,slot,fn)
    spawn(id,owner.Inventory,function(item)
        if slot then
            assert(owner.Inventory.TryPutItem(item,owner,{slot}),'cannot equip '..id..' in '..tostring(slot))
        end
        if id=='descendantservosuit' then
            spawn('batterycell',BMTDescendantSuit.container(item,1))
            BMTDescendantSuit.setMode(item,'repair',owner)
        elseif item.OwnInventory and id~='aegisvacuumpack' and id~='wrenchscrewdrivertwoinoneset' then
            spawn(id=='multi-toolset' and 'fuelrod' or 'batterycell',item.OwnInventory)
        end
        if fn then fn(item) end
    end)
end
function L.prepare()
    assert(Game.RoundStarted)
    local a,b=client('PerfA'),client('PerfB');assert(a and b and a.Character and b.Character)
    L.a,L.b=a.Character,b.Character
    for _,owner in ipairs({L.a,L.b}) do
        owner.GodMode=true;owner.Oxygen=100;owner.PressureProtection=1000000;owner.Stun=0
        if owner.AIController then owner.AIController.Enabled=false end
        for item in owner.Inventory.AllItems do Entity.Spawner.AddItemToRemoveQueue(item) end
    end
    Timer.Wait(L.equipAfterClear,500)
end
function L.equipAfterClear()
    equip('aegisvacuumpack',L.a,InvSlotType.Bag,function(pack)
        L.pack=pack
        spawn('aegisvacuumpage',pack.OwnInventory,function(page)
            for i=1,30 do local n=i;spawn('iron',page.OwnInventory,function(item)
                item.Condition=20+n;item.AddTag('bmt_lifecycle_'..n)
            end) end
        end)
    end)
    equip('aegisvacuumpack',L.b,InvSlotType.Bag)
    equip('descendantservosuit',L.a,InvSlotType.OuterClothes)
    equip('aegisheadsetmk2',L.a,InvSlotType.Headset)
    equip('aegisheadset',L.b,InvSlotType.Headset)
    equip('multi-toolset',L.a,nil)
    equip('wrenchscrewdrivertwoinoneset',L.a,nil)
    equip('combatmultitool',L.a,InvSlotType.RightHand+InvSlotType.LeftHand)
    equip('aegisvacuum',L.b,InvSlotType.RightHand+InvSlotType.LeftHand)
    local function ready()
        if L.pending>0 then Timer.Wait(ready,100);return end
        L.check('all four production controllers track real equipped items',function()
            for _,g in ipairs({BMTDescendantSuit,BMTCombat,BMTHeadsets,BMTVacuum}) do assert(next(g.states)) end
            assert(L.a.Inventory.GetItemInLimbSlot(InvSlotType.Bag)==L.pack)
            assert(L.a.Inventory.GetItemInLimbSlot(InvSlotType.RightHand).Prefab.Identifier.Value:lower()=='combatmultitool')
            assert(L.b.Inventory.GetItemInLimbSlot(InvSlotType.RightHand).Prefab.Identifier.Value:lower()=='aegisvacuum')
        end)
        L.helpers={}
        L.check('native multitool mode helpers and backpack page exist',function()
            local expected={toolwe=false,toolpl=false,tooldamageflag=false,toolexton=false,toolextoff=false,aegisvacuumpage=false}
            for item in Item.ItemList do
                local id=item.Prefab.Identifier.Value:lower()
                local parent=item.ParentInventory and item.ParentInventory.Owner
                if expected[id]~=nil and (L.owned[item] or L.owned[parent]) then
                    L.helpers[item]=id;expected[id]=true
                end
            end
            for id,found in pairs(expected) do assert(found,'missing native helper '..id) end
        end)
        L.verifyPack('native pack prepared');L.signal('prepared')
    end
    Timer.Wait(ready,1500)
end
function L.disconnected()
    if client('PerfA') then Timer.Wait(L.disconnected,100);return end
    L.check('original character survives actual client disconnect',function()
        assert(L.a and not L.a.Removed)
    end)
    L.signal('disconnected')
end
function L.reapConnection()
    local connection=client('PerfA')
    if connection then Game.Server.KickClient(connection,'Owned lifecycle test reconnect',false) end
    L.disconnected()
end
function L.reconnected()
    local c=client('PerfA');assert(c and L.a and not L.a.Removed,'original native character did not survive disconnect')
    Game.Server.SetClientCharacter(c,L.a)
    L.verifyPack('30 native identities and conditions preserved through real disconnect/rejoin')
    L.signal('reconnected')
end
function L.verifyPack(name)
    L.check(name,function()
        local found={};local items=BMTVacuum.contents(L.pack);assert(#items==30)
        for _,item in ipairs(items) do
            local n=tonumber(item.Tags:match('bmt_lifecycle_(%d+)'))
            assert(n and not found[n]);found[n]=true;assert(math.abs(item.Condition-(20+n))<.02)
        end
    end)
end
function L.clearOwned()
    -- Queue only roots. A separate removal of pages or contents would mask an
    -- orphan left behind by the native parent's removal.
    for item in pairs(L.owned) do
        if not item.Removed then
            local parent=item.ParentInventory and item.ParentInventory.Owner
            if not L.owned[parent] then Entity.Spawner.AddEntityToRemoveQueue(item) end
        end
    end
    local removed=L.owned
    L.owned={}
    Timer.Wait(function()
        L.check('removed item states pruned before round end',function()
            for _,g in ipairs({BMTDescendantSuit,BMTCombat,BMTHeadsets,BMTVacuum}) do
                for item in pairs(g.states) do assert(not item.Removed) end
            end
        end)
        L.check('native contained helper items removed with their parent',function()
            assert(next(L.helpers),'no native helpers were observed')
            for item,id in pairs(L.helpers) do assert(item.Removed,'orphan native helper '..id) end
            for item in pairs(removed) do assert(item.Removed,'orphaned test item') end
        end)
        L.signal('removed')
    end,1500)
end
function L.verifyStopped()
    L.check('round ended and production states cleared',function()
        assert(not Game.RoundStarted)
        for _,g in ipairs({BMTDescendantSuit,BMTCombat,BMTHeadsets,BMTVacuum}) do assert(not next(g.states)) end
        assert(#BMTCombat.rings==0 and not next(BMTVacuum.jobs) and not next(BMTVacuum.pending))
    end)
    L.signal('stopped')
end
function L.waitStopped()
    if Game.RoundStarted then Timer.Wait(L.waitStopped,100);return end
    L.verifyStopped()
end
function L.loadCampaign(loadPath,savePath)
    for _,name in ipairs({'Barotrauma.GameMain','Barotrauma.GameModePreset','Barotrauma.SaveUtil','Barotrauma.CampaignDataPath','Barotrauma.SubmarineInfo','System.Diagnostics.Stopwatch'}) do LuaUserData.RegisterType(name) end
    local Main=LuaUserData.CreateStatic('Barotrauma.GameMain')
    local Save=LuaUserData.CreateStatic('Barotrauma.SaveUtil')
    local Data=LuaUserData.CreateStatic('Barotrauma.CampaignDataPath')
    local preset=LuaUserData.CreateStatic('Barotrauma.GameModePreset').MultiPlayerCampaign
    Main.NetLobbyScreen.SelectedModeIdentifier=preset.Identifier
    L.savePath=savePath;Save.LoadGame(Data(loadPath,savePath))
    assert(Main.GameSession and Main.GameSession.Campaign and Main.GameSession.DataPath.SavePath==savePath,'campaign path mismatch')
    local function loaded()
        if not Game.RoundStarted then Timer.Wait(loaded,250);return end
        if L.check('campaign copy loaded into native session',function()
            assert(Main.GameSession.Campaign and Main.GameSession.GameMode.Preset==preset,'round did not start in native campaign mode')
        end) then L.signal('loaded') end
    end
    Timer.Wait(loaded,250)
end
function L.verifyLegacy(name, saved)
    if L.check(name,function()
        local pack
        for item in Item.ItemList do if item.HasTag('bmtvac_20261104_stresspack') then pack=item;break end end
        assert(pack,'native saved stress pack missing')
        local items=BMTVacuum.contents(pack);assert(#items==10000,'native stress count '..#items)
        local seen={}
        for _,item in ipairs(items) do
            local n=tonumber(item.Tags:match('bmtvac_20261104_stressitem(%d+)'))
            assert(n and not seen[n]);seen[n]=true
            local expected=saved and n==10000 and 23 or 10+n%80
            assert(math.abs(item.Condition-expected)<.02,'saved condition changed')
            if n==10000 then L.saveSentinel=item end
        end
        if not saved then
            -- This copied fixture can materialize on the floor. Exercise the
            -- native character-inventory serializer with the same loaded pack.
            local c=assert(client('PerfA'),'test client not connected')
            local wearer=assert(c.Character,'test character not spawned')
            wearer.GodMode=true
            if not pack.ParentInventory or pack.ParentInventory.Owner~=wearer then
                local inventory=wearer.Inventory
                local occupied=inventory.GetItemInLimbSlot(InvSlotType.Bag)
                if occupied and occupied~=pack then occupied.Drop(wearer,true,true) end
                if pack.ParentInventory then pack.Drop(nil,true,false) end
                local slot=inventory.FindLimbSlot(InvSlotType.Bag)
                assert(slot>=0 and inventory.TryPutItem(pack,slot,false,false,nil,true,true,false),
                    'could not equip verified legacy pack in empty bag slot')
            end
            assert(wearer.Inventory.GetItemInLimbSlot(InvSlotType.Bag)==pack,'verified pack not in save owner bag slot')
            if BMTVacuum.filterRules then
                local ctx=BMTVacuum.context(pack,wearer)
                assert(BMTVacuum.setExcluded(ctx,'iron',true),'could not save exclusion')
                assert(BMTVacuum.setProtected(ctx,'iron',true),'could not save protection')
                assert(BMTVacuum.setAllowed(ctx,'chalcopyrite',true),'could not save ore allowance')
            end
        elseif BMTVacuum.filterRules then
            local rules=BMTVacuum.filterRules(pack)
            assert(rules.excluded.iron and rules.protected.iron and rules.allowed.chalcopyrite,'native save lost filter rules')
            write('METRIC saved_filter_rules=3')
        end
    end) then L.signal('legacy-verified') end
end
function L.saveCampaign()
    local Main=LuaUserData.CreateStatic('Barotrauma.GameMain')
    assert(Main.GameSession.DataPath.SavePath==L.savePath,'refusing unexpected save target')
    assert(L.saveSentinel and not L.saveSentinel.Removed,'no verified loaded sentinel')
    L.saveSentinel.Condition=23 -- Prove the reload is of the new native save, not the input XML.
    Main.GameSession.SubmarineInfo=LuaUserData.CreateStatic('Barotrauma.SubmarineInfo')(Submarine.MainSub)
    local clock=LuaUserData.CreateStatic('System.Diagnostics.Stopwatch').StartNew()
    Main.GameSession.Campaign.SavePlayers()
    LuaUserData.CreateStatic('Barotrauma.SaveUtil').SaveGame(Main.GameSession.DataPath)
    clock.Stop();write('METRIC native_save_ms='..clock.ElapsedMilliseconds)
    if L.check('native campaign save completed',function() assert(File.Exists(L.savePath)) end) then L.signal('saved') end
end
