-- Disposable singleplayer native probe. Never package.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local G=AegisSuit
local c=assert(Character.Controlled)
local R={rows={},phase=0};ServoGrabFollowup=R
-- Wait for simulated suit time, not wall time: background rendering can stall
-- native frames while Timer callbacks still become due.
local waitId=0
local function wait(fn,milliseconds)
    waitId=waitId+1
    local id='aegis.grab.followup.wait.'..waitId
    local deadline=G.now+milliseconds/1000
    Hook.Add('think',id,function()
        if G.now<deadline then return end
        Hook.Remove('think',id);fn()
    end)
end
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO GRAB] '..line)
    File.Write('LocalMods/System-Aegis/servo-grab-followup.txt',table.concat(R.rows,'\n'))
end
local function check(name,fn)
    local ok,detail=pcall(fn)
    log((ok and 'PASS ' or 'FAIL ')..name..' '..tostring(detail))
end
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
    h.WaterVolume=0;h.Oxygen=10000000
end
local rect=room.WorldRect
local origin=Vector2(rect.X+rect.Width*.35,rect.Y-rect.Height+70)
c.TeleportTo(origin);c.SetAllDamage(0,0,0);c.GodMode=true
for other in Character.CharacterList do
    if other~=c and other.Submarine==Submarine.MainSub then Entity.Spawner.AddEntityToRemoveQueue(other) end
end
local oldItems={}
for old in c.Inventory.AllItems do oldItems[#oldItems+1]=old end
for _,old in ipairs(oldItems) do
    if old.Prefab.Identifier.Value~='idcard' then old.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(old) end
end
local U=require('AegisCombat.util')
for item in Item.ItemList do
    if (item.WorldPosition-origin).Length()<300 and G.portable(item) then Entity.Spawner.AddEntityToRemoveQueue(item) end
end
local function spawn(prefab,position) return Item(ItemPrefab.Prefabs[prefab],position,c.Submarine) end
local suit=spawn('aegisservosuit',c.Position);R.suit=suit
assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
local cell=spawn('batterycell',c.Position)
assert(G.container(suit,1).TryPutItem(cell,0,false,false,c))
Entity.Spawner.AddCharacterToSpawnQueue('human',c.WorldPosition+Vector2(-170,15),function(human)
    human.TeamID=CharacterTeamType.Team2;human.AIController.Enabled=false;R.human=human
end)
Entity.Spawner.AddCharacterToSpawnQueue('moloch',Submarine.MainSub.WorldPosition+Vector2(3500,-200),function(large)
    large.AIController.Enabled=false;R.large=large
end)
local function inputs(character)
    if character~=c then return end
    character.SetInput(InputType.Left,false,false);character.SetInput(InputType.Right,false,false)
    local target=R.target
    local held=false
    if target then
        character.CursorPosition=character.Position+target.WorldPosition-character.WorldPosition
        local elapsed=G.now-R.start
        held=(elapsed>=.45 and elapsed<.65) or (R.releaseAt~=nil and elapsed>=R.releaseAt and elapsed<R.releaseAt+.2)
    end
    character.SetInput(InputType.Aim,false,target~=nil)
    character.SetInput(InputType.Use,held and not R.held,held);R.held=held
    character.SetInput(InputType.Shoot,false,false)
end
-- Inject at the consumer boundary: the ordinary mouse update would otherwise
-- replace the simulated cursor between Character.Control and the think hook.
local update=G.update
G.update=function(dt) inputs(c);return update(dt) end
local function acquire(target)
    G.setMode(suit,'off',c);G.setMode(suit,'grab',c)
    R.target=target;R.start=G.now;R.held=false;R.releaseAt=nil
    R.distance=(target.WorldPosition-c.WorldPosition).Length()
end
local function finish()
    R.target=nil
    G.setMode(suit,'off',c)
    G.update=update
    inputs(c)
    Hook.Remove('think','aegis.grab.followup.trace')
    log('DONE focused grab follow-up')
end
local function checkHeld(target)
    local s=G.state(suit)
    assert(s.grip and s.target.entity==target and s.active,'player did not acquire the target')
end
local function grabAtWall()
    local origin=c.WorldPosition+Vector2(-1000,350)
    c.TeleportTo(origin)
    local prop=Item(ItemPrefab.Prefabs['aegispulsebolt'],origin+Vector2(240,0),nil)
    acquire(prop)
    wait(function()
        LuaUserData.RegisterType('Barotrauma.StructurePrefab')
        local prefabs=LuaUserData.CreateStatic('Barotrauma.StructurePrefab').Prefabs
        local wall=Structure(Rectangle(origin.X+145,origin.Y+240,48,480),prefabs['ff_y_wall'],nil)
        wait(function()
            check('native wall keeps grip on the reachable side',function()
                checkHeld(prop)
                assert(G.state(suit).grip.recovering,'wall was missed by the path probe')
                assert(prop.WorldPosition.X>origin.X+193,'prop crossed solid wall')
                return 'offset='..(prop.WorldPosition.X-origin.X)
            end)
            local blockedX=prop.WorldPosition.X
            wall.Remove()
            wait(function()
                check('same grip resumes when the wall clears',function()
                    checkHeld(prop)
                    assert(prop.WorldPosition.X<blockedX-20,'prop did not resume its approach')
                    return 'movement='..(prop.WorldPosition.X-blockedX)
                end)
                finish()
            end,1700)
        end,4000)
    end,620)
end
local function grabMonster()
    local moloch=R.large
    local start=moloch.WorldPosition
    c.TeleportTo(start+Vector2(-245,-65))
    acquire(moloch)
    wait(function()
        check('Aim+Use pulls live moloch',function()
            assert(not moloch.IsDead)
            checkHeld(moloch)
            local move=moloch.WorldPosition-start
            assert(move.X<-25,'moloch was not pulled toward wearer: '..tostring(move))
            return 'horizontal movement='..move.X
        end)
        grabAtWall()
    end,2200)
end
local function grabCorpse()
    local corpse=R.human
    corpse.Kill(CauseOfDeathType.Unknown)
    wait(function()
        local body=G.body(corpse)
        check('corpse physics sleeps naturally',function()
            assert(corpse.IsDead and body.Enabled and not body.PhysEnabled)
            return 'disabled while resting'
        end)
        local initialY=corpse.WorldPosition.Y-c.WorldPosition.Y
        acquire(corpse)
        wait(function()
            check('Aim+Use lifts resting enemy corpse',function()
                checkHeld(corpse)
                local lift=corpse.WorldPosition.Y-c.WorldPosition.Y-initialY
                assert(body.PhysEnabled and lift>12,'corpse did not lift: '..lift)
                return 'lift='..lift
            end)
            grabMonster()
        end,1800)
    end,6500)
end
Hook.Add('think','aegis.grab.followup.trace',function()
    if not R.target or R.target.Removed or G.now<(R.traceAt or 0) then return end
    R.traceAt=G.now+.15
    local s=G.state(suit);local rows={}
    for _,t in ipairs(G.gather(c,s)) do rows[#rows+1]=t.id..':'..tostring(t.visible)..':'..math.floor(t.distance) end
    log('TRACE mode='..s.mode..' bot='..tostring(c.IsBot)..' aim='..tostring(c.IsKeyDown(InputType.Aim))..
        ' use='..tostring(c.IsKeyDown(InputType.Use))..' cursor='..(c.CursorWorldPosition-R.target.WorldPosition).Length()..
        ' target='..tostring(s.target and s.target.id)..' candidates='..table.concat(rows,','))
end)
local function ready()
    if not R.human or not R.large then wait(ready,100);return end
    local aim=c.AimRefPosition+c.Submarine.Position
    for _,offset in ipairs({Vector2(210,25),Vector2(170,65),Vector2(-220,65),Vector2(165,-10)}) do
        local point=c.WorldPosition+offset
        if not G.cast({x=aim.X,y=aim.Y},{x=point.X,y=point.Y},0,c,true,false,suit) then
            R.prop=spawn('aegispulsebolt',c.Position+offset)
            break
        end
    end
    assert(R.prop,'test room has no clear throw lane')
    assert(not U.component(R.prop,'Pickable') and not U.component(R.prop,'Holdable'))
    check('creatures heavier than the item limit are eligible',function()
        assert(G.grabbable(R.human),'ordinary live human rejected')
        assert(R.large.Mass>80 and G.grabbable(R.large),'moloch rejected')
        return 'human='..R.human.Mass..' moloch='..R.large.Mass..' collider='..G.body(R.large).Mass
    end)
    check('loose non-pickable object',function()
        assert(G.grabbable(R.prop))
        return 'body='..tostring(R.prop.body.BodyType)..' mass='..R.prop.body.Mass
    end)
    acquire(R.prop)
    wait(function()
        check('Aim+Use acquires non-pickable prop',function()
            local s=G.state(suit)
            assert(s.active and s.target and s.target.entity==R.prop)
            assert((R.prop.WorldPosition-c.WorldPosition).Length()<R.distance-20,'prop not pulled')
            return 'distance='..(R.prop.WorldPosition-c.WorldPosition).Length()
        end)
        check('localized UI bindings',function()
            local text=tostring(G.panelStatus.Text)
            assert(not text:find('InputType',1,true) and text:find('grab / release',1,true),text)
            assert(not G.drawError,tostring(G.drawError))
            File.Write('LocalMods/System-Aegis/headset-capture.request',(AegisCaptureRoot or 'LocalMods/System-Aegis/')..'servo-grab-help.png')
            return text:gsub('\n',' / ')
        end)
        -- Remove the first target so it cannot intercept the next aim ray.
        local clearSide=R.prop.WorldPosition.X>=c.WorldPosition.X and 1 or -1
        Entity.Spawner.AddEntityToRemoveQueue(R.prop)
        R.human.TeleportTo(c.WorldPosition+Vector2(clearSide*120,35))
        wait(function()
            acquire(R.human)
            wait(function()
                check('Aim+Use acquires live human',function()
                    local s=G.state(suit)
                    assert(not R.human.IsDead and s.target and s.target.entity==R.human and s.active)
                    R.liveAcquired=true
                    return 'alive=true mass='..R.human.Mass
                end)
                R.releaseAt=G.now-R.start+.15
                wait(function()
                    check('second Aim+Use releases live human',function()
                        local s=G.state(suit)
                        assert(R.liveAcquired and not s.target and not s.active)
                        return 'released=true'
                    end)
                    R.target=nil
                    grabCorpse()
                end,550)
            end,1700)
        end,400)
    end,1700)
end
wait(ready,700)
