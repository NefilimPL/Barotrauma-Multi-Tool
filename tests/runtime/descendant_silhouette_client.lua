-- Disposable native singleplayer visual probe. Never package.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local G=BMTDescendantSuit
local Core=require('DescendantSuit.core')
local c=assert(Character.Controlled)
local directions=LuaUserData.CreateEnumTable('Barotrauma.Direction')
local R={rows={},facing=1};ServoSilhouette=R
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO SILHOUETTE] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-silhouette.txt',table.concat(R.rows,'\n'))
end
local waitId=0
local function wait(seconds,fn)
    waitId=waitId+1
    local id='bmt.silhouette.wait.'..waitId
    local deadline=G.now+seconds
    Hook.Add('think',id,function()
        if G.now<deadline then return end
        Hook.Remove('think',id);fn()
    end)
end
local function capture(name)
    assert(not G.drawError,tostring(G.drawError))
    File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request',
        'F:/_Github/Barotrauma-Multi-Tool/.runtime/servo-silhouette-'..name..'.png')
end
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
    h.WaterVolume=0;h.Oxygen=10000000
end
local rect=room.WorldRect
c.TeleportTo(Vector2(rect.X+rect.Width*.35,rect.Y-rect.Height+70));c.SetAllDamage(0,0,0)
for other in Character.CharacterList do
    if other~=c and other.Submarine==Submarine.MainSub then Entity.Spawner.AddEntityToRemoveQueue(other) end
end
local oldItems={}
for old in c.Inventory.AllItems do oldItems[#oldItems+1]=old end
for _,old in ipairs(oldItems) do
    if old.Prefab.Identifier.Value~='idcard' then old.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(old) end
end
local function spawn(id,p) return Item(ItemPrefab.Prefabs[id],p,c.Submarine) end
local suit=spawn('descendantservosuit',c.Position);R.suit=suit
assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
assert(G.container(suit,1).TryPutItem(spawn('batterycell',c.Position),0,false,false,c))
G.setMode(suit,'off',c)
Game.GameScreen.Cam.Zoom=2
Hook.Patch('bmt.silhouette.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam
    cam.Zoom=2;cam.Position=c.WorldPosition+Vector2(70,50);cam.TargetPos=cam.Position
    cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
-- Simulate the local cursor without moving the user's desktop pointer.
Hook.Patch('bmt.silhouette.cursor','Barotrauma.Character','UpdateLocalCursor',function(character,p)
    if character~=c then return end
    p.PreventExecution=true
    character.CursorPosition=R.target and
        (character.Position+R.target.WorldPosition-character.WorldPosition) or
        (character.Position+Vector2(R.facing*500,50))
end,Hook.HookMethodType.Before)
local update=G.update
G.update=function(dt)
    c.SetInput(InputType.Left,false,false);c.SetInput(InputType.Right,false,false)
    c.SetInput(InputType.Up,false,false);c.SetInput(InputType.Down,false,false)
    c.SetInput(InputType.Shoot,false,false)
    local target=R.target
    local held=false
    if target then
        c.CursorPosition=c.Position+target.WorldPosition-c.WorldPosition
        local elapsed=G.now-R.start;held=elapsed>.45 and elapsed<.65
    else c.CursorPosition=c.Position+Vector2(R.facing*500,50) end
    c.SetInput(InputType.Aim,false,target~=nil);c.SetInput(InputType.Use,held and not R.held,held);R.held=held
    c.AnimController.TargetDir=R.facing<0 and directions.Left or directions.Right
    Game.GameScreen.Cam.Zoom=2
    return update(dt)
end
wait(2,function()
    local base,_,facing=G.mount(c)
    assert(facing==1,'native character did not turn right')
    local pose=Core.pose(base,G.restGoal(c),facing)
    assert(pose.tip.y-base.y>60,'rest tool did not rise above shoulder')
    capture('right')
    log('PASS raised rest pose right tipAboveMount='..(pose.tip.y-base.y)..' drawError=nil')
    wait(.3,function()
        R.facing=-1
        wait(2,function()
            local _,_,facing=G.mount(c)
            assert(facing==-1,'native character did not turn left')
            capture('left');log('PASS left-facing rest render drawError=nil')
            wait(.3,function()
                R.facing=1
                R.prop=spawn('wrench',c.Position+Vector2(180,20))
                R.distance=(R.prop.WorldPosition-c.WorldPosition).Length()
                G.setMode(suit,'grab',c);R.target=R.prop;R.start=G.now
                wait(1.7,function()
                    local s=G.state(suit)
                    assert(s.active and s.target and s.target.entity==R.prop,'grab did not acquire')
                    assert((R.prop.WorldPosition-c.WorldPosition).Length()<R.distance-10,'target did not move closer')
                    capture('working');log('PASS working grab render and physical pull drawError=nil')
                    wait(.4,function()
                        R.target=nil;G.setMode(suit,'off',c);G.update=update
                        c.SetInput(InputType.Aim,false,false);c.SetInput(InputType.Use,false,false)
                        Hook.RemovePatch('bmt.silhouette.camera','Barotrauma.GameScreen','Draw',Hook.HookMethodType.Before)
                        Hook.RemovePatch('bmt.silhouette.cursor','Barotrauma.Character','UpdateLocalCursor',Hook.HookMethodType.Before)
                        log('DONE native visual probe; zoom=2, original lighting enabled')
                    end)
                end)
            end)
        end)
    end)
end)
