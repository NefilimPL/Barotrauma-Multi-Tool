-- Isolated client or server sandbox only; creates one bot and one repair target.
assert(Game.RoundStarted)
local G=AegisSuit
local origin=Character.Controlled and Character.Controlled.WorldPosition
if not origin then
    for h in Hull.HullList do if h.Submarine==Submarine.MainSub then origin=h.WorldPosition;break end end
end
assert(origin)
local bot=Character.Create('human',origin,'servo-ai-native',nil,0,false,true,true,nil,true,false)
bot.TeamID=CharacterTeamType.Team1
-- IsBot requires an enabled HumanAIController; use the real running AI.
bot.AIController.Enabled=true
local suit=Item(ItemPrefab.Prefabs['aegisservosuit'],bot.WorldPosition,nil)
local rod=Item(ItemPrefab.Prefabs['fuelrod'],bot.WorldPosition,nil)
local tank=Item(ItemPrefab.Prefabs['oxygentank'],bot.WorldPosition,nil)
assert(bot.Inventory.TryPutItem(suit,bot,{InvSlotType.OuterClothes}))
assert(G.container(suit,1).TryPutItem(tank,0,false,false,bot))
assert(G.container(suit,2).TryPutItem(rod,0,false,false,bot))
local device=Item(ItemPrefab.Prefabs['junctionbox'],bot.WorldPosition+Vector2(50,25),nil)
device.Condition=10
ServoAIProbe={bot=bot,suit=suit,rod=rod,device=device}
Timer.Wait(function()
    local s=G.state(suit)
    local line='bot='..tostring(bot.IsBot)..' mode='..tostring(s.mode)..' device='..tostring(device.Condition)..
        ' energy='..tostring(rod.Condition)..' active='..tostring(s.active)..' renderError='..tostring(G.drawError)..
        ' worn='..tostring(G.equipped(bot)==suit)..' dead='..tostring(bot.IsDead)..' tank='..tostring(tank.Condition)..
        ' pressure='..tostring(bot.PressureProtection)..' open='..tostring(s.open)
    print('[SERVO AI] '..line)
    File.Write('LocalMods/System-Aegis/servo-ai-results.txt',line)
    assert(bot.IsBot and device.Condition>10 and rod.Condition<rod.MaxCondition,'autonomous repair failed')
end,2500)
Timer.Wait(function()
    if bot.Removed or bot.IsDead then return end
    bot.TeleportTo(Submarine.MainSub.WorldPosition+Vector2(3000,-100))
    Timer.Wait(function()
        local s=G.state(suit)
        local line='wet='..tostring(bot.AnimController.HeadInWater)..' open='..tostring(s.open)..
            ' oxygen='..tostring(bot.OxygenAvailable)..' tank='..tostring(tank.Condition)..
            ' pressure='..tostring(bot.PressureProtection)..' swimming='..tostring(s.swimming)..
            ' energy='..tostring(rod.Condition)..' dead='..tostring(bot.IsDead)
        print('[SERVO WATER] '..line)
        File.Write('LocalMods/System-Aegis/servo-water-results.txt',line)
        assert(bot.AnimController.HeadInWater and not s.open and tank.Condition<tank.MaxCondition and bot.OxygenAvailable>90,
            'underwater breathing failed')
        dofile('LocalMods/System-Aegis/Lua/Tests/probe.lua')
    end,2000)
end,3250)
