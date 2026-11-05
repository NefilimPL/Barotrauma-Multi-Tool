-- Test only: actual campaign LoadNewLevel during an active native-spawner batch.
local R=assert(VacuumExtended)
local G=BMTVacuum
function R.prepareTransition()
    R.tagged=nil
    local pack=R.find('disconnectpack')
    -- Existing pages contain 220 items; create additional native pages for 200 tools.
    for j=1,2 do
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['aegisvacuumpage'],pack.OwnInventory,nil,nil,function(page)
            for i=1,100 do
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['wrench'],page.OwnInventory,nil,nil,function(item)
                    item.AddTag(R.prefix..'transitiontool'..item.ID)
                end,false)
            end
        end,false)
    end
end
function R.beginTransition()
    local main=LuaUserData.CreateStatic('Barotrauma.GameMain')
    local campaign=main.GameSession.Campaign
    R.transitionSeed=Level.Loaded.Seed
    local ready=R.check('level transition begins during an active salvage job',function()
        assert(G.jobs[R.disconnectPack],'no active salvage job')
        assert(tostring(campaign.GetAvailableTransition())~='None')
    end)
    assert(ready,'test requires active salvage and an available level exit')
    campaign.LoadNewLevel()
end
function R.startPartialTransition()
    local player
    for c in Client.ClientList do if c.Name=='VacuumA' then player=c.Character end end
    assert(player and G.context(R.vacuum,player).valid)
    local campaign=LuaUserData.CreateStatic('Barotrauma.GameMain').GameSession.Campaign
    for conn in campaign.Map.CurrentLocation.Connections do
        for location in conn.Locations do if location~=campaign.Map.CurrentLocation then
            campaign.Map.SelectLocation(location);break
        end end
        break
    end
    assert(tostring(campaign.GetAvailableTransition())~='None')
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['aegisvacuumpack'],player.Inventory,nil,nil,function(pack)
        pack.AddTag(R.prefix..'transitionpack')
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['aegisvacuumpage'],pack.OwnInventory,nil,nil,function(page)
            local complete=0
            for i=1,30 do
                local number=i
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[number<=10 and 'wrench' or 'iron'],page.OwnInventory,nil,nil,function(item)
                    item.AddTag(R.prefix..(number<=10 and 'transitiontool' or 'disconnectraw')..number)
                    complete=complete+1
                    if complete==30 then
                        R.disconnectPack=pack;R.transitionPackTag='transitionpack';R.transitionTotal=30
                        G.selected[R.vacuum.ID]=pack.ID;R.battery.Condition=R.battery.MaxCondition
                        assert(G.startSalvage(G.context(R.vacuum,player)))
                        Hook.Add('think','bmt.test.transition.partway',function()
                            local job=G.jobs[pack]
                            if job and job.done>=3 then
                                Hook.Remove('think','bmt.test.transition.partway')
                                R.check('partly completed native batch before level transition',function()
                                    assert(job.done>=3 and job.done<10)
                                end)
                                R.beginTransition()
                            end
                        end)
                    end
                end,false)
            end
        end,false)
    end,false)
end
function R.verifyTransition()
    R.tagged=nil
    R.check('campaign changed to a different native level',function()
        assert(Level.Loaded.Seed~=R.transitionSeed)
        assert(Game.RoundStarted)
    end)
    R.check('level transition preserves 10000 actual items and their conditions',function()
        local pack=R.find('stresspack')
        local items=G.contents(pack)
        assert(#items==10000,'stress count '..#items)
        local seen={}
        for _,item in ipairs(items) do
            local id=tonumber(item.Tags:match(R.prefix..'stressitem(%d+)'))
            assert(id and not seen[id]);seen[id]=true
            assert(math.abs(item.Condition-(10+id%80))<.02)
        end
        R.stressPack=pack
    end)
    R.check('level transition preserves mixed loot, nested contents and quality',function()
        local pack=R.find('pack')
        assert(#G.contents(pack)==103)
        assert(R.find('ammo').ParentInventory==R.find('crate').OwnInventory)
        assert(R.find('tank').ParentInventory==R.find('suit').OwnInventory)
        assert(math.abs(R.find('ammo').Condition-37.25)<.02)
        assert(R.find('quality').Quality==3)
        R.pack=pack;R.vacuum=R.find('vacuum');R.battery=R.find('battery')
        assert(R.vacuum.OwnInventory.GetItemAt(0)==R.battery)
    end)
    R.check('interrupted level-transition batch has no lost or duplicated items',function()
        local pack=R.find(R.transitionPackTag or 'disconnectpack')
        local counts,ids,raw={},{},0
        for _,page in ipairs(G.pages(pack)) do for item in page.OwnInventory.AllItems do
            assert(not ids[item.ID]);ids[item.ID]=true
            counts[G.id(item)]=(counts[G.id(item)] or 0)+1
            if item.Tags:find(R.prefix..'disconnectraw',1,true) then raw=raw+1 end
        end end
        assert(raw==20)
        assert((counts.iron or 0)+(counts.wrench or 0)==R.transitionTotal,'wrong conserved total')
        assert(#G.contents(pack)==R.transitionTotal,'stale inventory cache')
        assert(not G.jobs[pack] and not G.pending[pack])
        print('[VACUUM EXTENDED] TRANSITION COUNTS iron='..(counts.iron or 0)..' wrench='..(counts.wrench or 0))
        R.disconnectPack=pack
    end)
end
