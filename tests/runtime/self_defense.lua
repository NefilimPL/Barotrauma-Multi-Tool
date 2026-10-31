-- Test-only: ordinary defensive objective, screwdriver equipped, Aegis stowed.
local G=BMTCombat
local U=require('CombatTool.util')
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub then
        h.WaterVolume=0;h.Oxygen=100000000
        if not room or h.Rect.Width*h.Rect.Height>room.Rect.Width*room.Rect.Height then room=h end
    end
end
assert(room)
local bot=Character.Create('human',room.WorldPosition,'aegis-defense',nil,0,false,true,true,nil,true,false)
bot.TeamID=CharacterTeamType.Team1;bot.Enabled=true;bot.GodMode=true
local enemy=Character.Create('human',room.WorldPosition+Vector2(90,0),'aegis-threat',nil,0,false,false,true,nil,true,false)
enemy.TeamID=CharacterTeamType.Team2;enemy.Enabled=true;enemy.GodMode=true
local gun=Item(ItemPrefab.Prefabs['combatmultitool'],bot.WorldPosition,nil)
assert(bot.Inventory.TryPutItem(gun,bot,{InvSlotType.Any}))
local cell=Item(ItemPrefab.Prefabs['batterycell'],bot.WorldPosition,nil)
assert(gun.OwnInventory.TryPutItem(cell,0,false,false,bot))
local screwdriver=Item(ItemPrefab.Prefabs['screwdriver'],bot.WorldPosition,nil)
assert(bot.Inventory.TryPutItem(screwdriver,bot,{InvSlotType.RightHand}))
U.component(gun,'LightComponent').IsOn=false
U.component(gun,'Pump').IsOn=true;U.component(gun,'Controller').State=true
local shots=0
local original=G.fire
G.fire=function(s,ctx) if s.item==gun then shots=shots+1 end;return original(s,ctx) end
-- This is the same native path used by the human controller's attack response.
-- No forced order, forced weapon, forced priority, aim input or checkbox enable.
bot.AIController.AddCombatObjective(CombatMode.Defensive,enemy)
Timer.Wait(function()
    local weapon
    U.each(bot.AIController.ObjectiveManager.Objectives,function(o)
        if U.id(o)=='combat' then weapon=o.Weapon end
    end)
    local lines={}
    local function check(name,pass,detail)
        local line=(pass and 'PASS ' or 'FAIL ')..name..': '..tostring(detail or '')
        lines[#lines+1]=line;print('[BMT DEFENSE] '..line)
    end
    check('natural defensive AI chooses Aegis over equipped screwdriver',weapon==gun,U.itemId(weapon))
    check('bot fires autonomously with player checkbox initially off',shots>0,shots)
    check('automatic combat does not rewrite player checkbox',not U.component(gun,'LightComponent').IsOn)
    G.fire=original
    File.Write('LocalMods/MULTI-TOOL-V2/defense-results.txt',table.concat(lines,'\n'))
    enemy.Remove();bot.Remove()
end,6000)
