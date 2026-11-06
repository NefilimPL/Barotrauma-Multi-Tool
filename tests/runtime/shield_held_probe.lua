-- Disposable Sandbox server only. Actual held item, native human fixtures,
-- native firearm prefabs (including all shotgun pellets), and damage calls.
-- The immediate turn deliberately precedes the following arm physics update.
assert(SERVER and Game.RoundStarted)
local G=BMTCombat
local U=require('CombatTool.util')
local created,lines={},{}
local function log(s) lines[#lines+1]=s;print('[HELD SHIELD] '..s) end
local function track(o) created[#created+1]=o;return o end
local room
for hull in Hull.HullList do if hull.Submarine==Submarine.MainSub and hull.Rect.Width>650 then room=hull;break end end
room=room or Hull.HullList[0]
local center=room.WorldPosition
local defender=track(Character.Create('human',center,'bmt-held-defender',nil,0,false,false,true,nil,true,false))
local attacker=track(Character.Create('human',center-Vector2(500,0),'bmt-held-attacker',nil,0,false,false,true,nil,true,false))
defender.TeamID=CharacterTeamType.Team1;attacker.TeamID=CharacterTeamType.Team2
defender.Enabled=true;defender.GodMode=false;attacker.Enabled=true;attacker.GodMode=false
local descriptor=LuaUserData.RegisterType('Barotrauma.Character')
LuaUserData.MakeFieldAccessible(descriptor,'dequeuedInput')
local flags=LuaUserData.CreateEnumTable('Barotrauma.Character+InputNetFlags')
defender.IsRemotePlayer=true;defender.dequeuedInput=flags.Aim
defender.CursorPosition=defender.Position-Vector2(500,0)
local gun=track(Item(ItemPrefab.Prefabs['combatmultitool'],center,nil))
local battery=track(Item(ItemPrefab.Prefabs['batterycell'],center,nil))
assert(gun.OwnInventory.TryPutItem(battery,0,false,false,defender))
assert(defender.Inventory.TryPutItem(gun,defender,{InvSlotType.RightHand+InvSlotType.LeftHand}))
U.component(gun,'LightComponent').IsOn=true
local s=G.state(gun)
local event=G.event
local hits=0
local damageCalls,failures=0,0
Hook.Patch('bmt.probe.damage','Barotrauma.Attack','DoDamageToLimb',function(attack,p)
    local limb=p['targetLimb'] or p['limb']
    if limb and limb.character==defender then damageCalls=damageCalls+1 end
end,Hook.HookMethodType.Before)
G.event=function(kind,state,pos,...)
    if state==s and (kind=='shieldhit' or kind=='break') then hits=hits+1 end
    return event(kind,state,pos,...)
end
local function finish()
    G.event=event
    Hook.RemovePatch('bmt.probe.damage','Barotrauma.Attack','DoDamageToLimb',Hook.HookMethodType.Before)
    File.Write('LocalMods/MULTI-TOOL-V2/held-shield-results.txt',table.concat(lines,'\n'))
    Timer.Wait(function()
        G.states[gun]=nil
        for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
    end,1500)
    assert(failures==0,tostring(failures)..' held-shield cases failed; see held-shield-results.txt')
end
local function shots()
    defender.Enabled=true;attacker.Enabled=true
    defender.dequeuedInput=flags.Aim
    local ctx=G.context(gun)
    log('ctx valid='..tostring(ctx.valid)..' aim='..tostring(ctx.aim)..' damage='..tostring(ctx.damage)..' shield='..tostring(s.shield~=nil))
    log('gun '..tostring(gun.WorldPosition)..' bodyRotation='..gun.body.Rotation..' dir='..gun.body.Dir..' sub='..tostring(gun.Submarine))
    -- Native held pose has settled; turn the emitter before the next arm step.
    gun.body.Dir=1
    gun.body.SetTransform(gun.body.SimPosition,math.pi)
    local targets={'Torso','Head','LeftArm','RightArm','LeftHand','RightHand','Waist'}
    local limbTypes=LuaUserData.CreateEnumTable('Barotrauma.LimbType')
    for _,kind in ipairs({'revolverround','smground','riflebullet','shotgunshell'}) do
        for _,name in ipairs(targets) do
            local limb=defender.AnimController.GetLimb(limbTypes[name])
            if limb and not limb.IsSevered then
                local p=limb.WorldPosition
                local start=p-Vector2(220,0)
                local sub=defender.Submarine
                local bullet=track(Item(ItemPrefab.Prefabs[kind],sub and start-sub.Position or start,sub))
                local projectile=U.component(bullet,'Projectile')
                battery.Condition=100;s.brokenUntil=0
                G.updateShield(s,G.context(gun),0)
                local before,hitsBefore,callsBefore=defender.Vitality,hits,damageCalls
                local targetsBefore=projectile.MaxTargetsToHit
                local sim=ConvertUnits.ToSimUnits(bullet.Position)
                projectile.Shoot(attacker,sim,sim,0,nil,false,1,0)
                local delta=defender.Vitality-before
                local ok=damageCalls==callsBefore and delta>=-.001 and hits>hitsBefore and not defender.IsDead
                if not ok then failures=failures+1 end
                log((ok and 'PASS ' or 'FAIL ')..kind..' '..name..' delta='..delta..' shieldHits='..(hits-hitsBefore)..' energy='..battery.Condition..
                    ' targets='..targetsBefore..' damageCalls='..(damageCalls-callsBefore)..' sub='..tostring(bullet.Submarine))
            end
        end
    end
    s.shield=nil
    local p=defender.AnimController.MainLimb.WorldPosition
    local start=p-Vector2(220,0)
    local sub=defender.Submarine
    local bullet=track(Item(ItemPrefab.Prefabs['revolverround'],start-sub.Position,sub))
    local projectile=U.component(bullet,'Projectile')
    local before,callsBefore=defender.Vitality,damageCalls
    local sim=ConvertUnits.ToSimUnits(bullet.Position)
    projectile.Shoot(attacker,sim,sim,0,nil,false,1,0)
    local ok=defender.Vitality<before and damageCalls>callsBefore
    if not ok then failures=failures+1 end
    log((ok and 'PASS ' or 'FAIL ')..'UNSHIELDED control delta='..(defender.Vitality-before)..' damageCalls='..(damageCalls-callsBefore))
    finish()
end
Timer.Wait(shots,1800)
