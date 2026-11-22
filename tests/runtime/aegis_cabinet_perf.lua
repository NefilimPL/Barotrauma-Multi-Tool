-- Isolated client fixture. Run with the AegisPerfStartup timing hook.
if not CLIENT then return end
local path='LocalMods/CabinetProbe/'
local function run()
    if not Game.RoundStarted then Timer.Wait(run,500);return end
    local ok,err=pcall(function()
        local c=assert(Character.Controlled)
        c.GodMode=true
        local sub=c.Submarine
        local origin=c.WorldPosition-(sub and sub.Position or Vector2.Zero)
        local function create(id) return Item(ItemPrefab.Prefabs[id],origin,sub) end
        for other in Character.CharacterList do
            if other.AIController then other.AIController.Enabled=false end
        end
        local empty,full,nested=create('mediumsteelcabinet'),create('steelcabinet'),create('steelcabinet')
        local fab=create('fabricator')
        LuaUserData.RegisterType('System.Collections.Generic.List`1[[Barotrauma.MapEntity, Barotrauma]]')
        fab.linkedTo.Add(nested)
        for i=1,18 do assert(full.OwnInventory.TryPutItem(create('iron'),c)) end
        for i=1,5 do
            local container=create('toolbox')
            assert(nested.OwnInventory.TryPutItem(container,c))
            for j=1,12 do assert(container.OwnInventory.TryPutItem(create('steel'),c)) end
        end
        local scanCount,scanTime,childCount=0,0,0
        local vacuum=AegisVacuum
        if vacuum then
            local available=vacuum.availablePacks
            local children=vacuum.children
            vacuum.children=function(item)
                childCount=childCount+1
                return children(item)
            end
            vacuum.availablePacks=function(owner)
                local before=os.clock()
                local result=available(owner)
                scanTime=scanTime+(os.clock()-before)*1000
                scanCount=scanCount+1
                return result
            end
        end
        local phases={{'closed'},{'empty',empty},{'full',full},{'nested',nested},{'linked',fab},
            {'nested-repeat',nested},{'linked-repeat',fab}}
        local results={}
        local function measure(i)
            if not phases[i] then
                File.Write(path..'aegis-perf-phase.txt','done')
                File.Write(path..'lua-cost.txt',table.concat(results,'\n'))
                return
            end
            local name,item=phases[i][1],phases[i][2]
            c.SelectedItem=nil
            scanCount,scanTime,childCount=0,0,0
            File.Write(path..'aegis-perf-phase.txt',name)
            if item then
                assert(item.TryInteract(c,true,true) or item.TryInteract(c,true,false,true),name..' could not be opened')
                assert(c.SelectedItem==item,name..' did not select native facility')
            end
            Timer.Wait(function()
                if c.SelectedItem~=item then
                    File.Write(path..'error.txt','selection lost: '..name..' | access '..tostring(c.CanInteractWith(item))..
                        ' | distance '..tostring((c.WorldPosition-item.WorldPosition).Length()))
                    return
                end
                results[#results+1]=string.format('%s,%d,%.3f,%d',name,scanCount,scanTime,childCount)
                local success,failure=pcall(measure,i+1)
                if not success then File.Write(path..'error.txt',tostring(failure)) end
            end,3200)
        end
        File.Write(path..'loaded.txt',vacuum and 'AEGIS' or 'VANILLA')
        Timer.Wait(function()
            local success,failure=pcall(measure,1)
            if not success then File.Write(path..'error.txt',tostring(failure)) end
        end,2400)
    end)
    if not ok then File.Write(path..'error.txt',tostring(err)) end
end
Timer.Wait(run,500)

