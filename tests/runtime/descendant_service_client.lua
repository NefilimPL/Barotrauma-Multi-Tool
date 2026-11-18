-- Isolated singleplayer acceptance. Never include in the published package.
assert(CLIENT and Game.RoundStarted and Game.IsSingleplayer)
local G=assert(BMTDescendantSuit);local U=require('CombatTool.util')
local C=require('DescendantSuit.config');local c=assert(Character.Controlled)
local R={rows={},steps={},index=0,passed=0,failed=0,impact=0};ServoService=R
local P='bmt.servo.service'
LuaUserData.RegisterType('Barotrauma.GUIButton+OnClickedHandler')
local function click(b) assert(b.OnClicked.Invoke(b,nil)) end
local function log(s)
    R.rows[#R.rows+1]=s;print('[SERVO SERVICE] '..s)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-service-client.txt',table.concat(R.rows,'\n'))
end
local function add(delay,name,fn) R.steps[#R.steps+1]={delay=delay,name=name,fn=fn} end
local function state() return G.state(R.suit) end
local function spawn(id,p) return Item(ItemPrefab.Prefabs[id],p or c.Position,c.Submarine) end
local function capture(name)
    File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request','F:/_Github/Barotrauma-Multi-Tool/.runtime/servo-service-'..name..'.png')
end
local room
for h in Hull.HullList do
    if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end
    h.WaterVolume=0;h.Oxygen=10000000
end
local rect=room.WorldRect;R.home=Vector2(rect.X+rect.Width*.18,rect.Y-rect.Height+70)
c.SelectedItem=nil;c.SelectedSecondaryItem=nil
c.TeleportTo(R.home);c.GodMode=true;c.SetAllDamage(0,0,0)
for other in Character.CharacterList do if other~=c then Entity.Spawner.AddEntityToRemoveQueue(other) end end
local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
for _,item in ipairs(old) do item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end
for item in Item.ItemList do local repair=item.GetComponentString('Repairable');if repair then item.Condition=item.MaxCondition;repair.DeteriorationSpeed=0 end end
R.suit=spawn('descendantservosuit');assert(c.Inventory.TryPutItem(R.suit,c,{InvSlotType.OuterClothes}))
R.cell=spawn('batterycell');R.box=spawn('pulselaserammobox')
assert(G.container(R.suit,1).TryPutItem(R.cell,0,false,false,c))
assert(G.container(R.suit,1).TryPutItem(R.box,1,false,false,c))
Entity.Spawner.AddCharacterToSpawnQueue('human',c.WorldPosition+Vector2(120,20),function(h)
    h.TeamID=c.TeamID;h.AIController.Enabled=false;R.human=h;R.originalPlatforms=h.AnimController.IgnorePlatforms
end)
local function inputs(character)
    if character~=c then return end
    for _,key in ipairs({InputType.Left,InputType.Up,InputType.Down,InputType.Crouch,InputType.Shoot}) do c.SetInput(key,false,false) end
    c.SetInput(InputType.Right,false,R.run==true);c.SetInput(InputType.Run,false,R.run==true)
    local elapsed=R.pressAt and G.now-R.pressAt or 100
    local aim=elapsed<.9;local use=elapsed>.3 and elapsed<.6
    c.SetInput(InputType.Aim,false,aim);c.SetInput(InputType.Use,use and not R.held,use);R.held=use
    local t=R.indicated;local p=t and t.WorldPosition or c.WorldPosition+Vector2(500,50)
    c.CursorPosition=c.Position+p-c.WorldPosition
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do
    Hook.Patch(P..'.input.'..entry[1],'Barotrauma.Character',entry[1],inputs,entry[2])
end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(character,p)
    if character==c then p.PreventExecution=true;inputs(c) end
end,Hook.HookMethodType.Before)
Hook.Patch(P..'.camera','Barotrauma.GameScreen','Draw',function()
    local cam=Game.GameScreen.Cam;cam.Zoom=1.5;cam.Position=c.WorldPosition+Vector2(30,35)
    cam.TargetPos=cam.Position;cam.UpdateTransform(false,true)
end,Hook.HookMethodType.Before)
add(1,'equipment and native mineral scanner',function()
    assert(G.equipped(c)==R.suit and R.human)
    assert(R.suit.GetComponentString('Sonar').HasMineralScanner)
    return 'protocol='..C.protocol
end)
add(.1,'off minimized sonar is completely hidden',function()
    G.updateSuitUI(1/60);assert(not G.sonarPanel.Visible and not G.sonarShowButton.Visible)
    click(G.sonarShowButton);click(G.sonarPowerButton);click(G.sonarMineralButton)
    return 'expanded controls enabled sonar+minerals'
end)
add(.5,'native mineral scan and compact powered radar',function()
    local sonar=R.suit.GetComponentString('Sonar')
    assert(sonar.UseMineralScanner and sonar.HasPower)
    click(G.sonarHideButton);G.updateSuitUI(1/60)
    assert(G.sonarPanel.Visible and G.sonarPanel.Rect.Width<=242 and not G.sonarPowerButton.Visible)
    assert(G.sonarView.Rect.Width>100)
    capture('compact');return 'radarWidth='..G.sonarPanel.Rect.Width..' mineral=true'
end)
add(.1,'active mode has a distinct selected tint',function()
    assert(G.setMode(R.suit,'grab',c));G.updateSuitUI(1/60)
    assert(G.panelButtons.grab.Selected and G.panelButtons.off.Selected)
    assert(G.panelButtons.grab.SelectedColor~=G.panelButtons.grab.Color)
    click(G.sonarShowButton);click(G.sonarPowerButton);click(G.sonarHideButton);G.updateSuitUI(1/60)
    assert(not G.sonarPanel.Visible)
    R.indicated=R.human;R.pressAt=G.now
    return 'grab highlighted; powered-off radar hidden; single grab press scheduled'
end)
add(1.5,'human held higher with scoped platform handling',function()
    assert(state().grip and state().grip.entity==R.human)
    assert(R.human.AnimController.IgnorePlatforms and R.human.DisableImpactDamageTimer>0)
    R.originalPlatforms=state().grip.platforms;R.health=R.human.CharacterHealth.Vitality;R.start=c.WorldPosition;R.minLift=999;R.maxError=0;R.run=true
    assert(R.human.WorldPosition.Y-c.WorldPosition.Y>40,'initial lift='..(R.human.WorldPosition.Y-c.WorldPosition.Y))
    return 'initialLift='..(R.human.WorldPosition.Y-c.WorldPosition.Y)
end)
add(4,'running keeps body airborne without collision injury',function()
    R.run=false;local moved=(c.WorldPosition-R.start).Length()
    assert(moved>150,'wearer did not run: '..moved)
    assert(state().grip,'grip dropped while running')
    assert(R.minLift>35,'body dragged: '..R.minLift..' error='..R.maxError..' trace='..tostring(R.worst))
    assert(R.human.CharacterHealth.Vitality>=R.health-.01,'incidental damage')
    capture('running');return 'moved='..moved..' minLift='..R.minLift..' maxError='..R.maxError..' vitality='..R.human.CharacterHealth.Vitality
end)
add(.2,'release restores platform flags',function()
    G.setMode(R.suit,'off',c);assert(not state().grip and R.human.AnimController.IgnorePlatforms==R.originalPlatforms,'platform restore expected='..tostring(R.originalPlatforms)..' actual='..tostring(R.human.AnimController.IgnorePlatforms))
    return 'restore=true'
end)
add(.1,'loose item grip setup',function()
    c.TeleportTo(R.home);R.indicated=nil
    R.prop=spawn('wrench',c.Position+Vector2(110,30));R.prop.body.BodyType=LuaUserData.CreateEnumTable('FarseerPhysics.BodyType').Dynamic
    G.setMode(R.suit,'grab',c);R.indicated=R.prop;R.pressAt=G.now
    return 'restore=true; loose wrench indicated'
end)
add(2,'loose item follows actual claw',function()
    assert(state().grip and state().grip.entity==R.prop,'no item grip')
    local p=G.toolPose(c,state()).muzzle;local error=(R.prop.WorldPosition-Vector2(p.x,p.y)).Length()
    assert(error<18,'claw error='..error);capture('claw')
    G.setMode(R.suit,'off',c);R.indicated=nil
    return 'clawError='..error
end)
add(.2,'wired suit holder setup',function()
    c.TeleportTo(R.home)
    R.rack=spawn('divingsuitlocker',c.Position+Vector2(-135,10));R.rackSuit=spawn('descendantservosuit')
    assert(R.rack.OwnInventory.TryPutItem(R.rackSuit,c));R.rackCell=spawn('batterycell');R.rackCell.Condition=20
    assert(G.container(R.rackSuit,1).TryPutItem(R.rackCell,0,false,false,c))
    R.battery=spawn('battery',c.Position+Vector2(-250,0));local storage=R.battery.GetComponentString('PowerContainer')
    storage.Charge=1000;storage.RechargeSpeed=0
    local function connection(item,name)
        local found;U.each(item.GetComponentString('ConnectionPanel').Connections,function(pin) if pin.Name==name then found=pin end end)
        return assert(found,'missing pin '..name)
    end
    R.wire=spawn('redwire').GetComponentString('Wire')
    R.out=connection(R.battery,'power_out');R.input=connection(R.rack,'power_in')
    assert(R.out.TryAddLink(R.wire) and R.input.TryAddLink(R.wire))
    assert(R.wire.Connect(R.out,0,false,false))
    assert(R.wire.Connect(R.input,1,false,false))
    return 'real battery power_out -> rack power_in'
end)
add(2,'upright rack sprite and real powered charging',function()
    local powered=R.rack.GetComponentString('Powered')
    assert(powered.Voltage>.1,'rack not powered: '..powered.Voltage)
    assert(R.rackCell.Condition>20,'docked battery did not recharge')
    assert(R.rackSuit.Sprite.SourceRect.Width==657 and R.rackSuit.Sprite.SourceRect.Height==1742,'front window sprite missing')
    capture('rack');R.rackBefore=R.rackCell.Condition;R.input.DisconnectWire(R.wire)
    return 'voltage='..powered.Voltage..' charge='..R.rackCell.Condition..' spriteHeight='..R.rackSuit.Sprite.SourceRect.Height
end)
add(1.5,'disconnected rack stops charging',function()
    local condition=R.rackCell.Condition;assert(not R.rackBefore or condition<=R.rackBefore+.6,'charges without grid')
    R.ladder=Item(Rectangle(c.Position.X-6,c.Position.Y+200,12,320),ItemPrefab.Prefabs['ladder'],c.Submarine)
    c.TeleportTo(R.ladder.WorldPosition)
    R.device=spawn('junctionbox',c.Position+Vector2(130,0));R.device.Condition=5
    c.SelectedSecondaryItem=R.ladder;assert(R.ladder.GetComponentString('Ladder').Select(c));G.setMode(R.suit,'repair',c)
    return 'no power charge='..condition..'; ladder selected'
end)
add(3,'native repair while on ladder preserves secondary selection',function()
    assert(c.SelectedSecondaryItem==R.ladder and c.IsClimbing,'ladder lost selected='..tostring(c.SelectedSecondaryItem)..' anim='..tostring(c.AnimController.Anim)..' condition='..R.device.Condition)
    assert(R.device.Condition>10,'no ladder repair: '..R.device.Condition)
    capture('ladder');return 'ladderCondition='..R.device.Condition
end)
add(.1,'seated repair setup',function()
    G.setMode(R.suit,'off',c);c.SelectedSecondaryItem=nil
    c.TeleportTo(R.home);R.device.SetTransform(ConvertUnits.ToSimUnits(c.Position+Vector2(130,20)),0)
    R.chair=spawn('op_cafeteriachair',c.Position);c.SelectedSecondaryItem=R.chair;assert(R.chair.GetComponentString('Controller').Select(c))
    R.device.Condition=5;G.setMode(R.suit,'repair',c)
    return 'chair selected'
end)
add(3,'native repair while seated preserves chair',function()
    assert(c.SelectedSecondaryItem==R.chair,'seat lost')
    assert(R.device.Condition>10,'no seated repair: '..R.device.Condition)
    capture('seat');G.setMode(R.suit,'off',c);c.SelectedSecondaryItem=nil
    return 'seatedCondition='..R.device.Condition
end)
local function advance()
    R.index=R.index+1;local s=R.steps[R.index]
    if not s then
        R.run=false;G.setMode(R.suit,'off',c);Hook.Remove('think',P)
        for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.RemovePatch(P..'.input.'..entry[1],'Barotrauma.Character',entry[1],entry[2]) end
        Hook.RemovePatch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',Hook.HookMethodType.Before)
        Hook.RemovePatch(P..'.camera','Barotrauma.GameScreen','Draw',Hook.HookMethodType.Before)
        log('RESULT passed='..R.passed..' failed='..R.failed..' native=true');return
    end
    R.at=G.now+s.delay
end
Hook.Add('think',P,function()
    if R.run and state().grip then
        local lift=R.human.WorldPosition.Y-c.WorldPosition.Y
        if lift<R.minLift then R.minLift=lift;local l=state().grip;R.worst='offsetY='..l.offset.y..' wanted='..tostring(l.wantedOffset and l.wantedOffset.y)..' recovery='..tostring(l.recovering) end
        local l=state().grip;local q=c.WorldPosition+Vector2(l.offset.x,l.offset.y)
        R.maxError=math.max(R.maxError,(q-R.human.WorldPosition).Length())
    end
    if not R.at or G.now<R.at then return end
    local s=R.steps[R.index];local ok,result=pcall(s.fn)
    if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end
    log((ok and 'PASS ' or 'FAIL ')..s.name..' '..tostring(result));advance()
end)
advance()
