-- Isolated native visual comparison; never package with the mod.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local c=Character.Controlled;local R={};ServoRackCompare=R
local oldLighting,oldLos=Game.LightManager.LightingEnabled,Game.LightManager.LosEnabled
-- Uniform visibility for a texture comparison, restored after capture.
Game.LightManager.LightingEnabled=false;Game.LightManager.LosEnabled=false
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
    h.WaterVolume=0;h.Oxygen=10000000
end
local rect=room.WorldRect;local p=Vector2(rect.X+rect.Width*.5,rect.Y-rect.Height+72)
c.GodMode=true;c.TeleportTo(p+Vector2(240,0))
for other in Character.CharacterList do if other~=c then Entity.Spawner.AddEntityToRemoveQueue(other) end end
-- Clear foreground furniture in this disposable scene, so all panes are visible.
for item in Item.ItemList do
    local q=item.WorldPosition
    if not item.ParentInventory and math.abs(q.X-p.X)<500 and math.abs(q.Y-p.Y)<250 then Entity.Spawner.AddEntityToRemoveQueue(item) end
end
local ids={'divingsuit','abyssdivingsuit','descendantservosuit'}
for i,id in ipairs(ids) do
    local q=p+Vector2((i-2)*80,0)
    local rack=Item(ItemPrefab.Prefabs['divingsuitlocker'],q-Submarine.MainSub.Position,Submarine.MainSub)
    local suit=Item(ItemPrefab.Prefabs[id],q-Submarine.MainSub.Position,Submarine.MainSub)
    assert(rack.OwnInventory.TryPutItem(suit,c));R[i]={rack=rack,suit=suit,id=id}
end
Hook.Patch('bmt.rack.compare.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam;cam.Zoom=3;cam.Position=R[2].rack.WorldPosition+Vector2(0,10);cam.TargetPos=cam.Position;cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
Timer.Wait(function()
    local suit=R[3].suit
    assert(suit.Sprite.SourceRect.Width==657 and suit.Sprite.SourceRect.Height==1742)
    assert(suit.Sprite.Origin.X<0 and suit.Sprite.Origin.Y<0)
    File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/rack-compare-native.png')
    File.Write('LocalMods/MULTI-TOOL-V2/rack-compare-native.txt','PASS native side-by-side lockers: left divingsuit, middle abyssdivingsuit, right descendantservosuit; front upper-body pane657x1742 loaded; item placement preserved.')
    print('[RACK COMPARE] PASS native panes loaded')
    Timer.Wait(function()
        Game.LightManager.LightingEnabled=oldLighting;Game.LightManager.LosEnabled=oldLos
        Hook.RemovePatch('bmt.rack.compare.camera','Barotrauma.GameScreen','Draw',Hook.HookMethodType.Before)
    end,1000)
end,1500)
