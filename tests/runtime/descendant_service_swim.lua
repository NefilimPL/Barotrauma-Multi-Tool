-- Same-character native comparison in an empty, clear water corridor.
assert(CLIENT and Game.IsSingleplayer and Game.RoundStarted)
local G=BMTDescendantSuit;local c=Character.Controlled;local R={rows={},index=0,speeds={}}
ServoSwim=R
local P='bmt.servo.service.swim'
local stats=LuaUserData.CreateEnumTable('Barotrauma.StatTypes')
local animations=LuaUserData.CreateEnumTable('Barotrauma.AnimController+Animation')
local entries={{'divingsuit',true},{'abyssdivingsuit',true},{'pucs',true},{'descendantservosuit',true},{'descendantservosuit',false}}
local origin=Submarine.MainSub.WorldPosition+Vector2(0,3000)
for i=1,30 do
    if not G.cast({x=origin.X-100,y=origin.Y},{x=origin.X+8000,y=origin.Y},90,c,true) then break end
    origin=origin+Vector2(0,400)
end
local function log(line)
    R.rows[#R.rows+1]=line;print('[SERVO SWIM] '..line)
    File.Write('LocalMods/MULTI-TOOL-V2/servo-service-swim.txt',table.concat(R.rows,'\n'))
end
local function input(character)
    if character~=c or R.done then return end
    for _,key in ipairs({InputType.Left,InputType.Up,InputType.Down,InputType.Aim,InputType.Use,InputType.Shoot,InputType.Crouch}) do c.SetInput(key,false,false) end
    c.SetInput(InputType.Right,false,true);c.SetInput(InputType.Run,false,true)
    c.CursorPosition=c.Position+Vector2(1000,0);c.Oxygen=100
end
for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do
    Hook.Patch(P..entry[1],'Barotrauma.Character',entry[1],input,entry[2])
end
Hook.Patch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',function(character,p)
    if character==c then p.PreventExecution=true;input(c) end
end,Hook.HookMethodType.Before)
local function nextVariant()
    R.index=R.index+1;local v=entries[R.index]
    if not v then
        R.done=true
        for _,key in ipairs({InputType.Right,InputType.Run}) do c.SetInput(key,false,false) end
        for _,entry in ipairs({{'ControlLocalPlayer',Hook.HookMethodType.After},{'Control',Hook.HookMethodType.Before}}) do Hook.RemovePatch(P..entry[1],'Barotrauma.Character',entry[1],entry[2]) end
        Hook.RemovePatch(P..'.cursor','Barotrauma.Character','UpdateLocalCursor',Hook.HookMethodType.Before)
        Hook.Remove('think',P);log('RESULT variants=5 native=true');return
    end
    local old=c.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    if old then if G.is(old) then G.setMode(old,'off',c) end;old.Drop(c,true) end
    c.SelectedItem=nil;c.SelectedSecondaryItem=nil;c.AnimController.Anim=animations.None
    c.TeleportTo(origin);c.SetAllDamage(0,0,0);c.GodMode=true;c.Oxygen=100
    local suit=Item(ItemPrefab.Prefabs[v[1]],c.Position,c.Submarine)
    assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
    if G.is(suit) then
        local cell=Item(ItemPrefab.Prefabs['batterycell'],c.Position,c.Submarine)
        assert(G.container(suit,1).TryPutItem(cell,0,false,false,c));cell.Condition=v[2] and 100 or 0
    else
        local tank=Item(ItemPrefab.Prefabs['oxygentank'],c.Position,c.Submarine)
        assert(suit.OwnInventory.TryPutItem(tank,c))
    end
    c.AnimController.Collider.LinearVelocity=Vector2.Zero
    R.suit=suit;R.started=G.now;R.samples=0;R.total=0;R.first=nil;R.bubbles=0
end
Hook.Add('think',P,function()
    if not R.started then return end
    local age=G.now-R.started
    if age>=6 and not R.first then R.first=c.WorldPosition;R.firstAt=G.now end
    if age>=6 then
        R.samples=R.samples+1;R.total=R.total+c.AnimController.Collider.LinearVelocity.X
        local s=G.is(R.suit) and G.state(R.suit)
        if s and s.swimming then R.bubbles=R.bubbles+1 end
    end
    if age<10 then return end
    assert(R.samples>200 and c.AnimController.InWater,'invalid swim measurement')
    local distance=(c.WorldPosition.X-R.first.X)/100
    log(string.format('variant=%s powered=%s speed_mean=%.5f displacement_speed=%.5f swim_stat=%.3f samples=%d thrust_ticks=%d',
        entries[R.index][1],tostring(entries[R.index][2]),R.total/R.samples,distance/(G.now-R.firstAt),
        c.GetStatValue(stats.SwimmingSpeed),R.samples,R.bubbles))
    nextVariant()
end)
nextVariant()
