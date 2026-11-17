-- Native GPU rendering acceptance; isolated SP only, never package.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTDescendantSuit;local c=Character.Controlled;local P='bmt.beam.visuals'
local R={rows={},shots=0};ServoBeamVisuals=R
R.otherDevices={}
for item in Item.ItemList do
    if item.GetComponentString('Repairable') then R.otherDevices[#R.otherDevices+1]=item end
    if not item.Submarine and item.Prefab.Identifier.Value=='junctionbox' then Entity.Spawner.AddEntityToRemoveQueue(item) end
end
local function log(line) R.rows[#R.rows+1]=line;print('[BEAM VISUALS] '..line);File.Write('LocalMods/MULTI-TOOL-V2/beam-visuals.txt',table.concat(R.rows,'\n')) end
local function capture(name) File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/beam-'..name..'.png') end
local function check(name,fn) local ok,result=pcall(fn);log((ok and 'PASS ' or 'FAIL ')..name..' '..tostring(result)) end
LuaUserData.MakeFieldAccessible(LuaUserData.RegisterType('Barotrauma.Particles.ParticleManager'),'particles')
log('BEGIN native 1.3.20 beam check; tracer must retain full ray length')
local origin=Submarine.MainSub.WorldPosition+Vector2(0,3000)
for i=1,30 do if not G.cast({x=origin.X-200,y=origin.Y},{x=origin.X+1200,y=origin.Y},200,c,true) then break end;origin=origin+Vector2(0,400) end
c.TeleportTo(origin);c.GodMode=true;c.SetAllDamage(0,0,0);c.SelectedItem=nil;c.SelectedSecondaryItem=nil
for other in Character.CharacterList do if other~=c then Entity.Spawner.AddEntityToRemoveQueue(other) end end
local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
for _,item in ipairs(old) do item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end
local function spawn(id) return Item(ItemPrefab.Prefabs[id],c.Position,c.Submarine) end
R.suit=spawn('descendantservosuit');assert(c.Inventory.TryPutItem(R.suit,c,{InvSlotType.OuterClothes}))
R.cell=spawn('batterycell');R.box=spawn('pulselaserammobox')
assert(G.container(R.suit,1).TryPutItem(R.cell,0,false,false,c));assert(G.container(R.suit,1).TryPutItem(R.box,1,false,false,c))
Timer.Wait(function()
    LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
    G.panelHideButton.OnClicked.Invoke(G.panelHideButton,nil)
end,300)
local function input(ch)
    if ch~=c then return end
    for _,key in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down,InputType.Aim,InputType.Use,InputType.Shoot}) do c.SetInput(key,false,false) end
    c.CursorPosition=c.Position+Vector2(900,0);c.Oxygen=100
end
for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.Patch(P..e[1],'Barotrauma.Character',e[1],input,e[2]) end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(ch,p) if ch==c then p.PreventExecution=true;input(c) end end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam;cam.Zoom=2;cam.Position=c.WorldPosition+Vector2(G.state(R.suit).mode=='combat' and 260 or 100,30);cam.TargetPos=cam.Position;cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.shot','Barotrauma.Items.Components.Projectile','Shoot',function(projectile)
    if projectile.Item.Prefab.Identifier.Value~='descendantpulsebolt' then return end
    R.shots=R.shots+1
    if R.shots==2 then Timer.Wait(function()
        local pm=Game.ParticleManager
        for i=0,pm.ParticleCount-1 do
            local particle=pm.particles[i+1]
            if particle.Prefab.Name=='descendantpulsetracer' then R.tracerLength=particle.Size.X end
        end
        capture('native-pulse')
    end,40) end
end,Hook.HookMethodType.After)
local started=G.now
Hook.Add('think',P,function()
    for _,item in ipairs(R.otherDevices) do if not item.Removed then item.Condition=item.MaxCondition end end
    c.TeleportTo(origin+Vector2(R.translate and math.sin((G.now-started)*2)*3 or 0,0))
    if R.enemy and not R.enemy.Removed then R.enemy.TeleportTo(origin+Vector2(520,20));R.enemy.Oxygen=100 end
end)
Entity.Spawner.AddCharacterToSpawnQueue('human',origin+Vector2(520,20),function(h)
    h.TeamID=CharacterTeamType.Team2;h.AIController.Enabled=false;h.GodMode=true;R.enemy=h
    G.setMode(R.suit,'combat',c);R.ammo=R.box.Condition
end)
Timer.Wait(function()
    check('native mini pulse fires full-length tracer',function()
        assert(R.shots>=2 and R.box.Condition<R.ammo and not G.drawError)
        assert(R.tracerLength and R.tracerLength>280,'native tracer shortened: '..tostring(R.tracerLength))
        return 'shots='..R.shots..' ammo='..R.box.Condition..' actualTracerLength='..R.tracerLength
    end)
    G.setMode(R.suit,'off',c);if R.enemy then Entity.Spawner.AddEntityToRemoveQueue(R.enemy);R.enemy=nil end
    Entity.Spawner.AddCharacterToSpawnQueue('human',origin+Vector2(110,20),function(h)
        h.TeamID=c.TeamID;h.AIController.Enabled=false;h.GodMode=true;R.human=h
        G.setMode(R.suit,'grab',c);local s=G.state(R.suit);local q=h.WorldPosition
        s.target={id='g'..h.ID,entity=h,kind='grab',point={x=q.X,y=q.Y},visible=true,free=true,distance=112};s.grabStarted=G.now
        G.hold(c,R.suit,s.target,1/60)
    end)
end,2200)
Timer.Wait(function()
    -- Show the real tether while a held body is displaced and the spring
    -- recovers, rather than hiding a short beam inside the target's sprite.
    if R.human then R.human.TeleportTo(R.human.WorldPosition+Vector2(80,20)) end
end,3950)
Timer.Wait(function()
    check('soft tractor attached to live target',function() local s=G.state(R.suit);assert(s.grip and s.active and not G.drawError);capture('soft-grab');return 'live grip=true' end)
end,4000)
Timer.Wait(function()
    G.setMode(R.suit,'off',c);R.device=spawn('junctionbox');R.device.SetTransform(ConvertUnits.ToSimUnits(c.Position+Vector2(160,25)),0);R.device.Condition=5
    G.setMode(R.suit,'repair',c);R.translate=true
end,4300)
Timer.Wait(function()
    check('soft repair and sparks',function() assert(R.device.Condition>5 and not G.drawError);capture('soft-repair');return 'condition='..R.device.Condition end)
end,5400)
Timer.Wait(function()
    G.setMode(R.suit,'off',c)
    Timer.Wait(function()
        Hook.Remove('think',P)
        for _,e in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.RemovePatch(P..e[1],'Barotrauma.Character',e[1],e[2]) end
        Hook.RemovePatch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',Hook.HookMethodType.Before)
        Hook.RemovePatch(P..'.camera','Barotrauma.GameScreen','Draw',Hook.HookMethodType.Before)
        Hook.RemovePatch(P..'.shot','Barotrauma.Items.Components.Projectile','Shoot',Hook.HookMethodType.After)
        log('DONE native GPU pulse/grab/repair; lighting enabled')
    end,500)
end,5700)
