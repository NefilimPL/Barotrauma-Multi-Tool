-- Test only. Server fixture: 200 recyclable tools and 20 irreducible raw items.
local R=assert(VacuumExtended)
local G=BMTVacuum
local player
for client in Client.ClientList do if client.Name=='VacuumA' then player=client.Character end end
if not _G.VacuumDisconnectRestoreOnly then
    assert(player and G.context(R.vacuum,player).valid)
    R.networkPlayer=player
    R.battery.Condition=R.battery.MaxCondition
end
local function spawn(kind,inv,callback)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],inv,nil,nil,callback,false)
end
if not _G.VacuumDisconnectRestoreOnly then spawn('aegisvacuumpack',player.Inventory,function(pack)
    pack.AddTag(R.prefix..'disconnectpack');R.disconnectPack=pack
    local completed=0
    for pageNumber=1,3 do spawn('aegisvacuumpage',pack.OwnInventory,function(page)
        local count=pageNumber==3 and 20 or 100
        for i=1,count do
            local kind=pageNumber==3 and 'iron' or 'wrench'
            spawn(kind,page.OwnInventory,function(item)
                item.AddTag(R.prefix..(pageNumber==3 and 'disconnectraw' or 'disconnecttool')..((pageNumber-1)*100+i))
                completed=completed+1
                if completed==220 then
                    R.check('disconnect fixture has 200 tools and 20 raw items',function()
                        assert(#G.contents(pack)==220)
                        G.selected[R.vacuum.ID]=pack.ID
                        assert(G.context(R.vacuum,player).pack==pack)
                    end)
                    print('[VACUUM EXTENDED] DISCONNECT FIXTURE READY '..pack.ID)
                end
            end)
        end
    end) end
end) end
function R.verifyDisconnect(label)
    R.tagged=nil
    R.check(label,function()
        local pack=R.find('disconnectpack')
        local native,ids,counts,raw={},{},{},0
        for _,page in ipairs(G.pages(pack)) do for item in page.OwnInventory.AllItems do
            assert(not ids[item.ID],'duplicate entity ID');ids[item.ID]=true
            native[#native+1]=item
            local kind=G.id(item);counts[kind]=(counts[kind] or 0)+1
            if item.Tags:find(R.prefix..'disconnectraw',1,true) then raw=raw+1 end
        end end
        assert(raw==20,'tagged raw items lost '..raw)
        local plan=require('SalvageVacuum.recipes').plan(_G,
            {AllowDeconstruct=true,Condition=100,MaxCondition=100,Prefab=ItemPrefab.Prefabs['wrench']},R.vacuum)
        assert(plan,'no native wrench recipe')
        local yield={};for _,p in ipairs(plan) do yield[p.kind]=(yield[p.kind] or 0)+1 end
        local completed=200-(counts.wrench or 0)
        for kind,amount in pairs(yield) do
            local products=(counts[kind] or 0)-(kind=='iron' and 20 or 0)
            assert(products==completed*amount,'wrong '..kind..' output '..products..' for '..completed..' tools')
        end
        assert(#G.contents(pack)==#native,'cache disagrees with native inventory')
        print('[VACUUM EXTENDED] DISCONNECT COUNTS '..(counts.wrench or 0)..' wrench left, '..completed..' processed, 20 tagged raw preserved')
        R.disconnectPack=pack
    end)
end
