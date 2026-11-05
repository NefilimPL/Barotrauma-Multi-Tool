-- Actual client/server transport test, after vacuum_grid_server.lua fixture is ready.
assert(CLIENT and not BMTVacuum.authoritative)
local G=BMTVacuum
local P={rows={}};Vacuum134Network=P
function P.check(name,fn)
    local ok,err=pcall(fn)
    P.rows[#P.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM 134 MP] '..P.rows[#P.rows])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-134-network-results.txt',table.concat(P.rows,'\n'))
    return ok
end
local original=G.onSnapshot
G.onSnapshot=function(s) P.last=s;if original then original(s) end end
local pack;for item in Item.ItemList do if item.HasTag('bmtgrid_mp_pack') then pack=item;break end end
assert(pack and G.context(pack,Character.Controlled).valid)
P.pack=pack;G.openPanel(pack)
Timer.Wait(function()
    P.check('v3 receives forty actual icon rows and new category metadata',function()
        assert(P.last and #P.last.rows==40 and P.last.groups>40 and P.last.category=='all')
    end)
    local target;for _,row in ipairs(P.last.rows) do if row.kind=='iron' then target=row.id;break end end
    assert(target);P.before=P.last.count
    G.request('stack',pack,target,{})
    Timer.Wait(function()
        P.check('remote stack fills only one native stack and preserves remaining entities',function()
            local delta=P.before-P.last.count
            local item=Entity.FindEntityByID(target)
            assert(delta>0 and delta<=item.Prefab.GetMaxStackSize(Character.Controlled.Inventory))
            assert(#G.contents(pack)==P.last.count and item.ParentInventory==Character.Controlled.Inventory)
            P.delta=delta
        end)
        G.closePanel() -- stop automatic polls while checking exact reply modes
        G.request('filter',pack,1,{filters=true,kind='iron',search='iron'})
        Timer.Wait(function()
            P.check('remote filter persists tags and reports excluded catalog row',function()
                assert(P.last.filters and #P.last.rows>0)
                local found=false;for _,row in ipairs(P.last.rows) do if row.kind=='iron' then assert(row.excluded);found=true end end
                assert(found and G.filter(pack).iron,'saved Tags were not synchronized')
            end)
            G.request('open',pack,0,{category='medical'})
            Timer.Wait(function()
                P.check('remote category view only includes native medical items',function()
                    assert(P.last.category=='medical' and #P.last.rows>0)
                    for _,row in ipairs(P.last.rows) do assert(G.categoryMatches(ItemPrefab.Prefabs[row.kind],'medical')) end
                end)
                local id=P.last.rows[1].id;P.trashId=id;P.trashBefore=P.last.count
                G.request('preparetrash',pack,id,{category='medical'})
                Timer.Wait(function()
                    P.check('server issues a counted trash confirmation without deleting yet',function()
                        assert(P.last.trashTarget==id and P.last.trashToken>0 and P.last.trashCount>0)
                        assert(P.last.count==P.trashBefore and Entity.FindEntityByID(id))
                    end)
                    G.request('trash',pack,id,{category='medical',confirm=P.last.trashToken})
                    Timer.Wait(function()
                        -- Poll after the native removal queue commits and replicates.
                        G.request('open',pack,0,{category='medical'})
                        Timer.Wait(function()
                            P.check('confirmed remote trash removes actual entities on both sides',function()
                                local item=Entity.FindEntityByID(id)
                                assert(not item or item.Removed)
                                assert(P.last.count<P.trashBefore and #G.contents(pack)==P.last.count)
                            end)
                            G.openPanel(pack)
                        end,1000)
                    end,700)
                end,1000)
            end,1000)
        end,1000)
    end,1400)
end,1500)
