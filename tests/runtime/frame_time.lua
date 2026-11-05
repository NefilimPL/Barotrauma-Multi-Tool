-- Disposable server round only. Compare per-update costs on real native entities.
assert(SERVER and Game.RoundStarted)
local U=require('CombatTool.util')
local owned,results={},{}
local pos=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub then pos=hull.WorldPosition;break end end
local function create(kind,point)
    local item=Item(ItemPrefab.Prefabs[kind],point or pos,nil);owned[#owned+1]=item;return item
end
for i=1,32 do create('combatmultitool') end
for i=1,1500 do create('iron',Vector2(pos.X+10000,pos.Y)) end
local actor=Character.Create('human',pos,'bmt-frame-time',nil,0,false,true,true,nil,true,false)
actor.GodMode=true;actor.AIController.Enabled=false
local pack=create('aegisvacuumpack')
local nozzle=create('aegisvacuum')
local cell=create('batterycell')
assert(actor.Inventory.TryPutItem(pack,actor,{InvSlotType.Bag}))
assert(actor.Inventory.TryPutItem(nozzle,actor,{InvSlotType.RightHand+InvSlotType.LeftHand}))
assert(nozzle.OwnInventory.TryPutItem(cell,0,false,false,actor))
local function measure(label,fn)
    local times={};local total=0
    for i=1,120 do
        local start=os.clock();fn();local elapsed=(os.clock()-start)*1000
        times[i]=elapsed;total=total+elapsed
    end
    table.sort(times)
    local row=string.format('%s: 120 updates median=%.3fms p95=%.3fms max=%.3fms total=%.2fms',
        label,times[60],times[114],times[120],total)
    results[#results+1]=row;print('[FRAME TIME] '..row)
end
BMTCombat.update(.01)
measure('32 idle combat tools',function() BMTCombat.update(1/60) end)
measure('passive skill owner checks',function() BMTCombat.updatePassiveSkills(1/60) end)
local V=BMTVacuum
V.resetRuntime();V.update(.01)
local pickup=V.pickupTarget;V.pickupTarget=function() return nil end
measure('active vacuum native world refresh',function()
    actor.SetInput(InputType.Aim,false,true)
    V.states[nozzle]=V.states[nozzle] or {cursor=1}
    V.states[nozzle].usedAt=V.now
    V.update(1/60)
end)
V.pickupTarget=pickup
for i=#owned,1,-1 do if not owned[i].Removed then owned[i].Remove() end end
Timer.Wait(function() if not actor.Removed then actor.Remove() end end,3000)
File.Write('LocalMods/MULTI-TOOL-V2/frame-time-'..tostring(_G.FrameTimeLabel or 'before')..'.txt',table.concat(results,'\n'))
