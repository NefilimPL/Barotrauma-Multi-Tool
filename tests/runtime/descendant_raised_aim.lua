-- Real dry-room NPC/structure acceptance; isolated singleplayer only.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTDescendantSuit;local c=Character.Controlled;local P='bmt.raised.aim'
local R={rows={},passed=0,failed=0,stage='setup',shots=0,unsafe=0};ServoRaisedAim=R
local function log(s) R.rows[#R.rows+1]=s;print('[RAISED AIM] '..s);File.Write('LocalMods/MULTI-TOOL-V2/raised-aim-native.txt',table.concat(R.rows,'\n')) end
local function check(name,fn) local ok,result=pcall(fn);if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end;log((ok and 'PASS ' or 'FAIL ')..name..' '..tostring(result)) end
local function capture(name) File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/raised-aim-'..name..'.png') end
for h in Hull.HullList do if h.Submarine and (not R.room or h.Rect.Width>R.room.Rect.Width) then R.room=h end end
assert(R.room and R.room.Rect.Width>850,'no broad test hull')
R.sub=R.room.Submarine
local prefab
for wall in Structure.WallList do if wall.HasBody and not wall.Prefab.Platform and wall.Rect.Width>wall.Rect.Height then prefab=wall.Prefab;break end end
assert(prefab)
local rect=R.room.Rect
R.floor=Structure(Rectangle(rect.X+80,rect.Y-rect.Height+10,math.min(rect.Width-120,1000),32),prefab,R.sub)
local floor=R.floor.WorldRect;R.home=Vector2(floor.X+150,floor.Y+100)
local remove={}
for wall in Structure.WallList do
    local q=wall.WorldRect
    if wall~=R.floor and wall.Submarine==R.sub and q.X<R.home.X+650 and q.X+q.Width>R.home.X-90 and
        q.Y>floor.Y+1 and q.Y-q.Height<floor.Y+360 then remove[#remove+1]=wall end
end
for _,wall in ipairs(remove) do wall.Remove() end
for item in Item.ItemList do
    local q=item.WorldPosition
    if not item.ParentInventory and item.Submarine==R.sub and math.abs(q.X-R.home.X-250)<430 and math.abs(q.Y-R.home.Y)<230 then Entity.Spawner.AddEntityToRemoveQueue(item) end
end
for other in Character.CharacterList do if other~=c then Entity.Spawner.AddEntityToRemoveQueue(other) end end
local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
for _,item in ipairs(old) do item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end
c.SelectedItem=nil;c.SelectedSecondaryItem=nil;c.GodMode=true;c.TeleportTo(R.home);c.SetAllDamage(0,0,0)
local function spawn(id) return Item(ItemPrefab.Prefabs[id],c.Position,c.Submarine) end
R.suit=spawn('descendantservosuit');assert(c.Inventory.TryPutItem(R.suit,c,{InvSlotType.OuterClothes}))
R.cell=spawn('batterycell');R.box=spawn('pulselaserammobox')
assert(G.container(R.suit,1).TryPutItem(R.cell,0,false,false,c));assert(G.container(R.suit,1).TryPutItem(R.box,1,false,false,c))
local function state() return G.state(R.suit) end
local function input(ch)
    if ch~=c then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Aim,InputType.Use,InputType.Shoot,InputType.Crouch}) do c.SetInput(key,false,false) end
    c.CursorPosition=c.Position+Vector2(800,0)
end
for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.Patch(P..e[1],'Barotrauma.Character',e[1],input,e[2]) end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(ch,p) if ch==c then p.PreventExecution=true;input(c) end end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam;cam.Zoom=1.5;cam.Position=c.WorldPosition+Vector2(250,50);cam.TargetPos=cam.Position;cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
Hook.Add('think',P,function()
    R.room.WaterVolume=0;R.room.Oxygen=10000000;c.Oxygen=100
    if R.ally then R.ally.Oxygen=100 end
    if R.enemy then R.enemy.Oxygen=100 end
end)
Hook.Patch(P..'.shot','Barotrauma.Items.Components.Projectile','Shoot',function(projectile)
    if projectile.Item.Prefab.Identifier.Value~='descendantpulsebolt' then return end
    R.shots=R.shots+1
    if R.stage=='ally' then
        local s=state();local pose=G.toolPose(c,s);local head=R.ally.AnimController.GetLimb(LimbType.Head)
        if not s.combatAim or not s.combatAim.raised or pose.muzzle.y<=head.WorldPosition.Y then R.unsafe=R.unsafe+1 end
        R.peakLift=math.max(R.peakLift or 0,pose.muzzle.y-G.mount(c).y)
        if not R.captured then R.captured=true;Timer.Wait(function() capture('over-ally') end,50) end
    end
end,Hook.HookMethodType.Before)
local function begin(stage)
    G.setMode(R.suit,'off',c);R.stage=stage;R.before=R.shots;R.ammo=R.box.Condition;G.setMode(R.suit,'combat',c)
end
local function obstacle(x,y,w,h)
    return Structure(Rectangle(c.Position.X+x,c.Position.Y+y,w,h),prefab,c.Submarine)
end
Timer.Wait(function()
    LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler');G.panelHideButton.OnClicked.Invoke(G.panelHideButton,nil)
    check('dry standing setup',function() assert(not c.AnimController.InWater);return 'room='..R.room.Rect.Width..'x'..R.room.Rect.Height..' removedCeilings='..#remove end)
    Entity.Spawner.AddCharacterToSpawnQueue('human',c.WorldPosition+Vector2(550,0),function(h)
        h.TeamID=CharacterTeamType.Team2;h.AIController.Enabled=false;h.GodMode=true;R.enemy=h;begin('clear')
    end)
end,1000)
Timer.Wait(function()
    check('clear line uses ordinary low aim',function()
        assert(R.shots>R.before and state().combatAim and not state().combatAim.raised,'no low clear shot')
        return 'shots='..(R.shots-R.before)
    end)
    G.setMode(R.suit,'off',c)
    Entity.Spawner.AddCharacterToSpawnQueue('human',c.WorldPosition+Vector2(90,0),function(h)
        h.TeamID=c.TeamID;h.AIController.Enabled=false;R.ally=h;R.health=h.CharacterHealth.Vitality
        Timer.Wait(function() begin('ally') end,300)
    end)
end,2700)
Timer.Wait(function()
    check('arm rises before firing over standing ally',function()
        assert(R.shots>R.before and R.unsafe==0,'no elevated safe shot; shots='..(R.shots-R.before)..' unsafe='..R.unsafe)
        assert(R.ally.CharacterHealth.Vitality>=R.health-.01,'ally injured')
        return 'shots='..(R.shots-R.before)..' maxMuzzleLift='..R.peakLift..' allyVitality='..R.ally.CharacterHealth.Vitality
    end)
    R.ally.TeleportTo(c.WorldPosition-Vector2(150,0))
end,5100)
Timer.Wait(function()
    check('stable clearance returns arm to ordinary aim',function() assert(state().combatAim and not state().combatAim.raised);return 'ordinary aim restored' end)
    R.low=obstacle(20,75,32,190);begin('low-wall')
end,6600)
Timer.Wait(function()
    check('articulated arm fires over real low wall',function()
        assert(R.shots>R.before and state().combatAim and state().combatAim.raised,'low wall blocks raised aim')
        assert(G.visibleFromTool(c,state(),state().target,false));capture('over-wall');return 'shots='..(R.shots-R.before)
    end)
    Timer.Wait(function() R.low.Remove();R.full=obstacle(200,350,32,500);begin('full-wall') end,250)
end,8500)
Timer.Wait(function()
    check('full wall blocks all fire',function() assert(R.shots==R.before and R.box.Condition==R.ammo,'shot through full wall');return 'ammo unchanged' end)
    R.full.Remove();R.ceiling=obstacle(-80,85,280,20);R.ally.TeleportTo(c.WorldPosition+Vector2(90,0));begin('ceiling')
end,10400)
Timer.Wait(function()
    check('low ceiling prevents unsafe overhead shot',function() assert(R.shots==R.before and R.box.Condition==R.ammo,'shot with ceiling obstruction');return 'ammo unchanged' end)
    G.setMode(R.suit,'off',c);R.ceiling.Remove();Hook.Remove('think',P)
    for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.RemovePatch(P..e[1],'Barotrauma.Character',e[1],e[2]) end
    for _,e in ipairs({{'.cursor','Barotrauma.Character','UpdateLocalCursor'},{'.camera','Barotrauma.GameScreen','Draw'},{'.shot','Barotrauma.Items.Components.Projectile','Shoot'}}) do Hook.RemovePatch(P..e[1],e[2],e[3],Hook.HookMethodType.Before) end
    log('RESULT passed='..R.passed..' failed='..R.failed..' native_dry_npc_and_structures=true')
end,12400)
