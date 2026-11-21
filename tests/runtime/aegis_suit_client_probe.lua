-- Isolated singleplayer client only. Never package this test script.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local G=AegisSuit
local c=Character.Controlled
assert(G and G.alive and c,'client fixture missing')
c.GodMode=false
local old=c.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
if old then old.Drop(c) end
local suit=Item(ItemPrefab.Prefabs['aegisservosuit'],c.WorldPosition,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],c.WorldPosition,nil)
local tank=Item(ItemPrefab.Prefabs['oxygentank'],c.WorldPosition,nil)
assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
assert(G.container(suit,1).TryPutItem(tank,0,false,false,c))
assert(G.container(suit,2).TryPutItem(cell,0,false,false,c))
local device=Item(ItemPrefab.Prefabs['junctionbox'],c.WorldPosition+Vector2(60,35),nil)
device.Condition=10
assert(G.setMode(suit,'repair',c))
ServoClientProbe={wearer=c,suit=suit,cell=cell,tank=tank,device=device}
local function record(label)
    local s=G.state(suit)
    local line=label..' device='..tostring(device.Condition)..' energy='..tostring(cell.Condition)..
        ' tank='..tostring(tank.Condition)..' pressure='..tostring(c.PressureProtection)..
        ' open='..tostring(s.open)..' active='..tostring(s.active)..' sparks='..tostring(#(s.sparks or {}))..
        ' renderError='..tostring(G.drawError)
    print('[SERVO CLIENT] '..line)
    File.Write('LocalMods/System-Aegis/servo-client-results.txt',line)
end
Timer.Wait(function()
    record('repair')
    File.Write('LocalMods/System-Aegis/headset-capture.request',(AegisCaptureRoot or 'LocalMods/System-Aegis/')..'aegis-client-repair.png')
end,2000)
