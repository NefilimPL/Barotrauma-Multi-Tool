-- Isolated server: cursor-driven held poses across native update/physics ticks.
assert(SERVER and Game.RoundStarted)
local G=BMTCombat
local U=require('CombatTool.util')
local Core=require('CombatTool.core')
local created,lines={},{}
local function track(x) created[#created+1]=x;return x end
local function log(x) lines[#lines+1]=x;print('[FRONTAL] '..x) end
local room
for hull in Hull.HullList do
    if hull.Submarine==Submarine.MainSub and hull.Rect.Width>650 then room=hull;break end
end
room=room or Hull.HullList[0]
local origin=room.WorldPosition+Vector2(0,3000)
for _=1,16 do
    local clear=true
    for i=0,7 do
        local a=i*math.pi/4
        if G.cast(U.point(origin),U.point(origin+Vector2(math.cos(a)*1200,math.sin(a)*1200)),0,nil,true) then clear=false end
    end
    if clear then break end
    origin=origin+Vector2(0,500)
end
local defender=track(Character.Create('human',origin,'shield-frontal',nil,0,false,false,true,nil,true,false))
local attacker=track(Character.Create('human',origin-Vector2(500,0),'shield-attacker',nil,0,false,false,true,nil,true,false))
defender.TeamID=CharacterTeamType.Team1;attacker.TeamID=CharacterTeamType.Team2
defender.Enabled=true;attacker.Enabled=true
if BMTFrontalEdge then defender.GodMode=true end -- Count attack calls without changing pose after an allowed edge hit.
local descriptor=LuaUserData.RegisterType('Barotrauma.Character')
LuaUserData.MakeFieldAccessible(descriptor,'dequeuedInput')
local flags=LuaUserData.CreateEnumTable('Barotrauma.Character+InputNetFlags')
defender.IsRemotePlayer=true
attacker.IsRemotePlayer=true
local aim=math.pi
Hook.Patch('bmt.frontal.input','Barotrauma.Character','UpdateNetInput',function(c)
    if c~=defender then return end
    c.Enabled=true;c.dequeuedInput=flags.Aim+(math.cos(aim)<0 and flags.FacingLeft or 0)
    c.Oxygen=100
    c.PressureProtection=1000000
    c.CursorPosition=c.Position+Vector2(math.cos(aim)*500,math.sin(aim)*500)
    c.AnimController.Frozen=false
end,Hook.HookMethodType.After)
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],room.WorldPosition,nil))
local battery=track(Item(ItemPrefab.Prefabs['batterycell'],room.WorldPosition,nil))
assert(gun.OwnInventory.TryPutItem(battery,0,false,false,defender))
assert(defender.Inventory.TryPutItem(gun,defender,{InvSlotType.RightHand+InvSlotType.LeftHand}))
U.component(gun,'LightComponent').IsOn=true
local state=G.state(gun)
local hits,damage=0,0
local coveredDamage,outsideDamage=0,0
local ray
Hook.Patch('bmt.frontal.ray','Barotrauma.Items.Components.Projectile','DoHitscan',function(proj,p)
    ray={a=U.point(proj.Item.WorldPosition),dir=p['dir'],projectile=proj}
end,Hook.HookMethodType.Before)
Hook.Patch('bmt.frontal.fixture','Barotrauma.Items.Components.Projectile','HandleProjectileCollision',function(_,p)
    if ray then ray.fixture=p['target'] end
end,Hook.HookMethodType.Before)
local event=G.event
G.event=function(kind,s,...)
    if s==state and kind=='shieldhit' then hits=hits+1 end
    return event(kind,s,...)
end
Hook.Patch('bmt.frontal.damage','Barotrauma.Attack','DoDamageToLimb',function(_,p)
    local limb=p['targetLimb'] or p['limb']
    if limb and limb.character==defender then
        damage=damage+1
        if ray and state.shield and ray.fixture then
            local s=state.shield
            local dx,dy=0,0
            if ray.fixture.Body==limb.LagCompensatedBody.FarseerBody then
                local delta=ConvertUnits.ToDisplayUnits(limb.LagCompensatedBody.SimPosition-limb.body.SimPosition)
                dx,dy=delta.X,delta.Y
            end
            local historical={x=s.x+dx,y=s.y+dy,radius=s.radius,angle=s.angle,halfAngle=s.halfAngle}
            local contact=U.point(ray.projectile.Item.WorldPosition)
            local short=Core.segmentArc(ray.a,contact,historical)
            local full=Core.segmentArc(ray.a,{x=ray.a.x+ray.dir.X*50000,y=ray.a.y+ray.dir.Y*50000},historical)
            if short or full then coveredDamage=coveredDamage+1 else outsideDamage=outsideDamage+1 end
            log('DAMAGE TRACE short='..tostring(short or 'none')..' full='..tostring(full or 'none')..' start='..ray.a.x..','..ray.a.y..
                ' contact='..contact.x..','..contact.y..' arc='..historical.x..','..historical.y..','..historical.angle)
        end
    end
end,Hook.HookMethodType.Before)
local angles={BMTFrontalAngle or math.pi}
local limbTypes=LuaUserData.CreateEnumTable('Barotrauma.LimbType')
local function finish()
    if BMTFrontalEdge then log('EDGE coveredDamage='..coveredDamage..' outsideDamage='..outsideDamage..' intercepted='..hits) end
    File.Write('LocalMods/MULTI-TOOL-V2/frontal-shield-results.txt',table.concat(lines,'\n'))
    G.event=event
    Hook.RemovePatch('bmt.frontal.damage','Barotrauma.Attack','DoDamageToLimb',Hook.HookMethodType.Before)
    Hook.RemovePatch('bmt.frontal.input','Barotrauma.Character','UpdateNetInput',Hook.HookMethodType.After)
    Hook.RemovePatch('bmt.frontal.ray','Barotrauma.Items.Components.Projectile','DoHitscan',Hook.HookMethodType.Before)
    Hook.RemovePatch('bmt.frontal.fixture','Barotrauma.Items.Components.Projectile','HandleProjectileCollision',Hook.HookMethodType.Before)
    G.states[gun]=nil
    -- Let the native spawner drain blocked projectile removals before cleanup.
    Timer.Wait(function()
        for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
    end,200)
    if BMTFrontalDone then BMTFrontalDone(lines) end
end
local function run(index)
    if not angles[index] or defender.IsDead then finish();return end
    aim=angles[index]
    Timer.Wait(function()
        -- Direct Projectile.Shoot does not populate the gun's ignored bodies.
        -- Keep the test shooter from obstructing its own bullet before the shield.
        attacker.Enabled=false
        for limb in attacker.AnimController.Limbs do limb.LagCompensatedBody.Enabled=false end
        local direction,angle=G.direction(gun)
        local ctx=G.context(gun)
        log('POSE '..index..' shield='..tostring(state.shield~=nil)..' angle='..angle..' gun='..tostring(gun.WorldPosition)..
            ' valid='..tostring(ctx.valid)..' aim='..tostring(ctx.aim)..' damage='..tostring(ctx.damage)..
            ' unconscious='..tostring(defender.IsUnconscious)..' stun='..defender.Stun..' oxygen='..defender.Oxygen..
            ' energy='..battery.Condition..' now='..G.now..' cooldown='..state.brokenUntil)
        if BMTFrontalLag then
            for limb in defender.AnimController.Limbs do
                limb.LagCompensatedBody.SetTransformIgnoreContacts(
                    limb.body.SimPosition+ConvertUnits.ToSimUnits(Vector2(direction.x*BMTFrontalLag,direction.y*BMTFrontalLag)),
                    limb.body.Rotation)
            end
            log('LAG compensation displacement='..BMTFrontalLag)
        end
        for repeatIndex=1,(BMTFrontalEdge and 256 or 1) do
        for _,kind in ipairs(BMTFrontalEdge and {'shotgunshell'} or BMTFrontalControl and {'revolverround'} or {'revolverround','smground','riflebullet','shotgunshell'}) do
            for _,name in ipairs(BMTFrontalEdge and {'Waist'} or BMTFrontalControl and {'Torso'} or {'Torso','Head','RightHand','Waist'}) do
                local limb=defender.AnimController.GetLimb(limbTypes[name])
                if limb then
                    local target=limb.WorldPosition
                    -- Keep the real muzzle outside both the current and the
                    -- historical arc, including the native barrel offset.
                    local start=target+Vector2(direction.x*600,direction.y*600)
                    local sub=defender.Submarine
                    local bullet=track(Item(ItemPrefab.Prefabs[kind],sub and start-sub.Position or start,sub))
                    local projectile=U.component(bullet,'Projectile')
                    if BMTFrontalEdge then
                        LuaUserData.MakeFieldAccessible(LuaUserData.RegisterType('Barotrauma.Items.Components.Projectile'),'spreadIndex')
                        projectile.HitScanCount=1;projectile.spreadIndex=repeatIndex-1
                    end
                    battery.Condition=100;state.brokenUntil=0
                    if BMTFrontalControl then state.shield=nil end
                    local t=state.shield and Core.segmentArc(U.point(start),U.point(target),state.shield)
                    local h,d,c,o=hits,damage,coveredDamage,outsideDamage
                    local sim=ConvertUnits.ToSimUnits(bullet.Position)
                    if kind=='revolverround' then
                        local weapon=track(Item(ItemPrefab.Prefabs['revolver'],sub and start-sub.Position or start,sub))
                        assert(weapon.OwnInventory.TryPutItem(bullet,0,false,false,attacker))
                        weapon.body.Dir=1
                        weapon.body.SetTransform(ConvertUnits.ToSimUnits(weapon.Position),angle+math.pi)
                        attacker.dequeuedInput=flags.Aim
                        local ranged=U.component(weapon,'RangedWeapon')
                        ranged.Spread=0;ranged.UnskilledSpread=0
                        log('FIRE nativeRanged='..tostring(ranged.Use(1/60,attacker)))
                        -- Discard the firing gun so its fixture cannot obstruct
                        -- subsequent direct-projectile tests at the same muzzle.
                        weapon.Remove()
                    else projectile.Shoot(attacker,sim,sim,angle+math.pi,nil,false,1,0) end
                    local ok=BMTFrontalControl and damage>d and hits==h or not BMTFrontalControl and hits>h and damage==d
                    if BMTFrontalEdge then
                        ok=coveredDamage==c and damage-d==outsideDamage-o and (hits>h or outsideDamage>o)
                    end
                    log((ok and 'PASS ' or 'FAIL ')..kind..' '..name..' arc='..tostring(t)..' hits='..(hits-h)..' damageCalls='..(damage-d))
                end
            end
        end
        end
        run(index+1)
    end,1600)
end
run(1)
