-- Disposable native server only: actual storage, recipes, spawner callbacks.
assert(SERVER and Game.RoundStarted)
local G=BMTVacuum
local created,lines={},{}
local function track(x) created[#created+1]=x;return x end
local function check(name,ok)
    lines[#lines+1]=(ok and 'PASS ' or 'FAIL ')..name
    print('[SALVAGE PROGRESS] '..lines[#lines])
end
local origin=Submarine.MainSub.WorldPosition+Vector2(0,2000)
local owner=track(Character.Create('human',origin,'vacuum-progress',nil,0,false,true,true,nil,true,false))
owner.GodMode=true;owner.AIController.Enabled=false
local function item(kind) return track(Item(ItemPrefab.Prefabs[kind],origin,nil)) end
local pack,vacuum,battery,page=item('aegisvacuumpack'),item('aegisvacuum'),item('batterycell'),item('aegisvacuumpage')
assert(owner.Inventory.TryPutItem(pack,owner,{InvSlotType.Bag}))
assert(owner.Inventory.TryPutItem(vacuum,owner,{InvSlotType.RightHand+InvSlotType.LeftHand}))
assert(vacuum.OwnInventory.TryPutItem(battery,0,false,false,owner))
assert(pack.OwnInventory.TryPutItem(page,owner))
local source=item('wrench')
assert(G.insert(pack,source,owner))
for _=1,40 do assert(G.insert(pack,item('iron'),owner)) end
local ctx=G.context(vacuum,owner)
assert(G.startSalvage(ctx))
local job=G.jobs[pack]
check('original snapshot has 41 inputs',#job.items==41)
local incoming=item('wrench')
check('new loot enters during running job',G.insert(pack,incoming,owner))
check('new loot stays outside original snapshot',#job.items==41)
local initial=G.snapshot(ctx,{}).salvage
check('initial progress is present',initial and initial.total==41 and initial.processed==0)
Timer.Wait(function()
    local p=G.snapshot(ctx,{}).salvage
    check('native job finishes and retains final progress',not G.jobs[pack] and not G.pending[pack] and p and p.phase=='complete' and p.processed==41)
    check('native recipe removed source and kept newly collected wrench',source.Removed and not incoming.Removed and G.has(pack,incoming))
    check('unsupported materials skipped in bounded batches',p and p.done==1 and p.skipped==40)
    File.Write('LocalMods/MULTI-TOOL-V2/salvage-progress-results.txt',table.concat(lines,'\n'))
    for _,x in ipairs(G.contents(pack)) do if not x.Removed then x.Remove() end end
    for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
end,2500)
