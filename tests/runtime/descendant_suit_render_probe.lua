-- Disposable singleplayer GPU client only. Never package with the mod.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local G=BMTDescendantSuit
local U=require('CombatTool.util')
local c=assert(Character.Controlled)
assert(G and G.alive and not Game.Paused)
local room=c.AnimController.CurrentHull
if not room then
    for h in Hull.HullList do if h.Submarine==Submarine.MainSub then room=h;break end end
end
assert(room)
room.WaterVolume=0
local wr=room.WorldRect
local origin=Vector2(wr.X+wr.Width*.5,wr.Y-wr.Height+70)
c.TeleportTo(origin)
c.GodMode=false
local old=c.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
if old then old.Drop(c) end
local suit=Item(ItemPrefab.Prefabs['descendantservosuit'],c.WorldPosition,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],c.WorldPosition,nil)
local tank=Item(ItemPrefab.Prefabs['oxygentank'],c.WorldPosition,nil)
assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
assert(G.container(suit,1).TryPutItem(tank,0,false,false,c))
assert(G.container(suit,2).TryPutItem(cell,0,false,false,c))
local device=Item(ItemPrefab.Prefabs['junctionbox'],c.Position+Vector2(80,25),c.Submarine)
device.Condition=10
assert(G.setMode(suit,'repair',c))
local R={wearer=c,suit=suit,cell=cell,tank=tank,device=device,rows={},wet=false,move=false}
ServoRenderProbe=R
local oldLighting,oldLos=Game.LightManager.LightingEnabled,Game.LightManager.LosEnabled
local cam=Game.GameScreen.Cam
local oldZoom=cam.Zoom
Game.LightManager.LightingEnabled=false
Game.LightManager.LosEnabled=false
local function record(label)
    local s=G.state(suit)
    local visiblePlates=0
    local functional=U.component(suit,'Wearable')
    for limb in c.AnimController.Limbs do
        for w in limb.WearingItems do
            if w.WearableComponent and w.WearableComponent.Item==suit and w.WearableComponent~=functional then
                assert(not w.CanBeHiddenByOtherWearables,'plate is hideable')
                visiblePlates=visiblePlates+1
            end
        end
    end
    local line=label..' plates='..visiblePlates..' device='..device.Condition..' energy='..cell.Condition..
        ' tank='..tank.Condition..' pressure='..c.PressureProtection..' open='..tostring(s.open)..
        ' active='..tostring(s.active)..' swimming='..tostring(s.swimming)..' sparks='..#(s.sparks or {})..
        ' renderError='..tostring(G.drawError)
    R.rows[#R.rows+1]=line
    print('[SERVO RENDER] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-render-results.txt',table.concat(R.rows,'\n'))
    assert(visiblePlates==14 and not G.drawError,'native plate/render check failed')
end
local function input(who)
    if who~=c then return end
    c.SetInput(InputType.Right,false,R.move)
    c.SetInput(InputType.Left,false,false)
    c.SetInput(InputType.Up,false,false)
    c.SetInput(InputType.Down,false,false)
end
for _,method in ipairs({'ControlLocalPlayer','Control'}) do
    Hook.Patch('bmt.servo.render.'..method,'Barotrauma.Character',method,input,Hook.HookMethodType.Before)
end
Hook.Add('think','bmt.servo.render.view',function()
    if c.Removed then return end
    cam.Zoom=1.8
    cam.Position=c.WorldPosition
    if R.wet then room.WaterVolume=room.Rect.Width*room.Rect.Height end
end)
local function capture(label)
    File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request',
        'F:/_Github/Barotrauma-Multi-Tool/.runtime/descendant-final-'..label..'.png')
end
Timer.Wait(function()
    record('air')
    assert(G.state(suit).open and tank.Condition==tank.MaxCondition and c.PressureProtection>=10000)
    capture('air')
end,1500)
Timer.Wait(function() R.wet=true;R.move=true end,2400)
Timer.Wait(function()
    record('water')
    assert(c.AnimController.HeadInWater and not G.state(suit).open and tank.Condition<tank.MaxCondition)
    capture('water')
end,4500)
Timer.Wait(function()
    R.wet=false;R.move=false;room.WaterVolume=0
    input(c)
    for _,method in ipairs({'ControlLocalPlayer','Control'}) do
        Hook.RemovePatch('bmt.servo.render.'..method,'Barotrauma.Character',method,Hook.HookMethodType.Before)
    end
    Hook.Remove('think','bmt.servo.render.view')
    Game.LightManager.LightingEnabled=oldLighting;Game.LightManager.LosEnabled=oldLos;cam.Zoom=oldZoom
end,5500)
