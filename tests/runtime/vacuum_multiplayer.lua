-- Run independently on two real, isolated clients after joining the test server.
if not CLIENT then return end
local G=BMTVacuum
local P={rows={},snapshots=0,transfers=0,activity=0}
VacuumNetworkProbe=P
local function write() File.Write('LocalMods/MULTI-TOOL-V2/vacuum-network-results.txt',table.concat(P.rows,'\n')) end
function P.check(name,fn)
    local ok,err=pcall(fn)
    P.rows[#P.rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[VACUUM NETWORK] '..P.rows[#P.rows]);write()
    return ok
end
local onSnapshot=G.onSnapshot
G.onSnapshot=function(s)
    P.snapshots=P.snapshots+1;P.last=s
    if onSnapshot then onSnapshot(s) end
    File.Write('LocalMods/MULTI-TOOL-V2/vacuum-network-last.txt',
        string.format('pack=%d count=%d groups=%d rows=%d charge=%.4f busy=%s snapshots=%d',
            s.pack,s.count,s.groups,#s.rows,s.charge,tostring(s.busy),P.snapshots))
end
local onTransfer=G.onTransfer
G.onTransfer=function(id,point)
    P.transfers=P.transfers+1
    if onTransfer then onTransfer(id,point) end
end
function P.find(tag)
    local found={}
    for item in Item.ItemList do if item.HasTag('bmtvac_20261104_'..tag) then found[#found+1]=item end end
    assert(#found==1,'tag '..tag..' count '..#found)
    return found[1]
end
function P.verifyMain(label,count)
    P.check(label,function()
        local pack=P.find('pack')
        assert(#G.contents(pack)==(count or 104),'root items '..#G.contents(pack))
        assert(P.find('ammo').ParentInventory==P.find('crate').OwnInventory)
        assert(P.find('tank').ParentInventory==P.find('suit').OwnInventory)
        assert(math.abs(P.find('ammo').Condition-37.25)<.02)
        assert(P.find('quality').Quality==3)
    end)
end
function P.open(tag)
    local item=P.find(tag or 'vacuum')
    assert(G.context(item,Character.Controlled).valid,'controlled character does not own/hold '..(tag or 'vacuum'))
    G.openPanel(item)
end
P.check('real client is multiplayer and has authoritative vacuum adapter disabled',function()
    assert(Game.RoundStarted and not Game.IsSingleplayer and not G.authoritative)
    assert(Character.Controlled and not Character.Controlled.Removed)
end)
P.verifyMain('native campaign synchronization preserves mixed contents',_G.VacuumNetExpectedCount)
