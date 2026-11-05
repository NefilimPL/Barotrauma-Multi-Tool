-- Isolated server only. Measures mod updates, not whole-game FPS.
assert(SERVER and not Game.RoundStarted)
local U=require('CombatTool.util')
local results={}
local function measure(label,fn)
    local samples={}
    for n=1,5 do
        local start=os.clock()
        for i=1,120 do fn(1/60) end
        samples[n]=(os.clock()-start)*1000
    end
    table.sort(samples)
    results[#results+1]=string.format('%s: 120 updates, n=5 median=%.2fms max=%.2fms',label,samples[3],samples[5])
    print('[IDLE PERF] '..results[#results])
end
local items={}
for i=1,3000 do items[i]=Item(ItemPrefab.Prefabs['iron'],Vector2(0,0),nil) end
local count=0;U.each(Item.ItemList,function() count=count+1 end)
measure('vacuum idle, '..count..' native items',BMTVacuum.update)
measure('combat idle, '..count..' native items',BMTCombat.update)
for _,item in ipairs(items) do item.Remove() end
File.Write('LocalMods/MULTI-TOOL-V2/idle-performance-'..tostring(_G.IdlePerformanceLabel or 'before')..'.txt',table.concat(results,'\n'))
