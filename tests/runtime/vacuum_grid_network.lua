-- Real isolated client. Verify protocol v2 and request a genuine remote stack withdrawal.
assert(CLIENT and not BMTVacuum.authoritative)
local G=BMTVacuum
local P={rows={}};VacuumGridNetwork=P
function P.check(name,fn)
    local ok,err=pcall(fn)
    P.rows[#P.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM GRID MP] '..P.rows[#P.rows])
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-grid-network-results.txt',table.concat(P.rows,'\n'))
end
local original=G.onSnapshot
G.onSnapshot=function(s) P.last=s;if original then original(s) end end
local pack;for item in Item.ItemList do if item.HasTag('bmtgrid_mp_pack') then pack=item;break end end
assert(pack and G.context(pack,Character.Controlled).valid)
P.pack=pack
G.openPanel(pack)
Timer.Wait(function()
    P.check('real server sends forty native item icons over protocol v2',function()
        assert(P.last and P.last.groups>40 and #P.last.rows==40 and P.last.pages==2)
        for _,row in ipairs(P.last.rows) do assert(row.kind and row.name and row.id>0) end
    end)
    if not P.last then return end
    local target;for _,row in ipairs(P.last.rows) do if row.kind=='iron' then target=row.id;break end end
    assert(target)
    P.before=P.last.count;P.target=target
    G.request('stack',pack,target,{})
    Timer.Wait(function()
        P.check('real stack request is authoritative and leaves excess in storage',function()
            assert(P.last and P.last.count<P.before and P.before-P.last.count<=100)
            assert(#G.contents(pack)==P.last.count)
        end)
        P.after=P.last and P.last.count
    end,1400)
end,1500)
