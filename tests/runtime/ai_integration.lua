-- Asynchronous native bot exercise. Run after sandbox start, allow ~16 s.
local G=BMTCombat
local U=require('CombatTool.util')
local counts={shot=0,weld=0,cut=0,extinguish=0}
-- Previous runs leave invulnerable test crew behind; isolate this trial.
local obsolete={}
for c in Character.CharacterList do if c.GodMode then obsolete[#obsolete+1]=c end end
for _,c in ipairs(obsolete) do c.Remove() end
local results={}
local function report(name,ok,detail)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(detail and ': '..tostring(detail) or '')
    print('[BMT AI] '..results[#results])
    File.Write('LocalMods/MULTI-TOOL-V2/ai-results.txt',table.concat(results,'\n'))
end
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub then
        h.WaterVolume=0;h.Oxygen=100000000
        if h.Rect.Width>250 and (not room or h.Rect.Width*h.Rect.Height>room.Rect.Width*room.Rect.Height) then room=h end
    end
end
assert(room,'test needs a room on the submarine')
local bot=Character.Create('human',room.WorldPosition,'bmt-ai',nil,0,false,true,true,nil,true,false)
bot.TeamID=CharacterTeamType.Team1;bot.GodMode=true
bot.Enabled=true
local gun=Item(ItemPrefab.Prefabs['combatmultitool'],bot.WorldPosition,nil)
assert(bot.Inventory.TryPutItem(gun,bot,{InvSlotType.RightHand+InvSlotType.LeftHand}))
for slot=0,0 do
    local source=Item(ItemPrefab.Prefabs['batterycell'],bot.WorldPosition,nil)
    assert(gun.OwnInventory.TryPutItem(source,slot,false,false,bot))
end
local originalFire,originalUse=G.fire,G.use
local rangedAttempts,technicalDuringCombat=0,0
G.fire=function(s,ctx)
    if s.item==gun and ctx.owner==bot then counts.shot=counts.shot+1 end
    return originalFire(s,ctx)
end
G.use=function(component,character,dt)
    if component.Item==gun and character==bot and component.Name=='RangedWeapon' then rangedAttempts=rangedAttempts+1 end
    local allowed=originalUse(component,character,dt)
    if allowed and component.Item==gun and character==bot and component.Name=='RepairTool' then
        local mode=G.state(gun).mode
        counts[mode]=(counts[mode] or 0)+1
        local current=bot.AIController.ObjectiveManager.CurrentObjective
        if current and current.Identifier.Value=='combat' then technicalDuringCombat=technicalDuringCombat+1 end
    end
    return allowed
end
local manager=bot.AIController.ObjectiveManager
BMTAIBot=bot;BMTAIGun=gun
local gap=Gap(Rectangle(math.floor(room.Position.X+100),math.floor(room.Position.Y),8,32),true,Submarine.MainSub)
gap.Open=1
U.component(gun,'Pump').IsOn=true
U.component(gun,'Controller').State=true
U.component(gun,'LightComponent').IsOn=true
local weldOrder=AIObjectiveFixLeak(gap,bot,manager)
weldOrder.ForceHighestPriority=true
manager.SetForcedOrder(weldOrder)
Timer.Wait(function()
    report('native leak AI uses welding despite cutter/extinguisher checkboxes',counts.weld>0,
        'weld='..counts.weld..', cut='..counts.cut..', extinguisher='..counts.extinguish..', shots='..counts.shot..', task='..tostring(manager.CurrentObjective)..', mode='..G.context(gun).mode)
    report('welding does not also shoot/cut/extinguish',counts.shot==0 and counts.cut==0 and counts.extinguish==0)
    gap.Open=0
    local target=Character.Create('human',room.WorldPosition+Vector2(160,0),'bmt-target',nil,0,false,false,true,nil,true,false)
    target.TeamID=CharacterTeamType.Team2;target.GodMode=true
    target.Enabled=true
    bot.TeleportTo(room.WorldPosition-Vector2(60,0))
    U.component(gun,'Controller').State=false
    local combatOrder=AIObjectiveCombat(bot,target,CombatMode.Offensive,manager)
    combatOrder.ForceHighestPriority=true
    BMTAICombat=combatOrder;BMTAITarget=target
    manager.SetForcedOrder(combatOrder)
    local weldBefore=counts.weld
    Timer.Wait(function()
        report('native combat AI fires charged rings',counts.shot>0,'shots='..counts.shot..', attempts='..rangedAttempts..', weapon='..tostring(combatOrder.Weapon)..', child='..tostring(combatOrder.CurrentSubObjective)..', task='..tostring(manager.CurrentObjective)..', mode='..G.context(gun).mode..', valid='..tostring(G.context(gun).valid)..', aim='..tostring(G.context(gun).aim)..', damage='..tostring(G.context(gun).damage)..', enemyDown='..tostring(target.IsUnconscious)..', speed='..bot.AIController.AimSpeed)
        report('combat AI does not also weld',technicalDuringCombat==0,'technical calls while combat task selected='..technicalDuringCombat)
        manager.ClearForcedOrder()
        target.Remove()
        local before=counts.shot
        Timer.Wait(function()
            report('removing actual threat stops autonomous fire and shield',counts.shot==before and not G.state(gun).shield)
            manager.ClearForcedOrder()
            gap.Remove()
            G.fire,G.use=originalFire,originalUse
        end,2000)
    end,6000)
end,6000)
