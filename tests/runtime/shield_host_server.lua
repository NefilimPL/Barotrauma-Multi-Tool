-- Disposable multiplayer Sandbox only; one real client named ShieldHost.
-- Run shield_tracer_client.lua on that client before starting this fixture.
assert(SERVER and Game.RoundStarted)
local U=require('CombatTool.util');local G=BMTCombat
local R={shots=0,hits=0,damage=0,rows={},created={}};ShieldHostProbe=R
local function log(s) R.rows[#R.rows+1]=s;print('[HOST SHIELD] '..s);File.Write('LocalMods/MULTI-TOOL-V2/host-shield-results.txt',table.concat(R.rows,'\n')) end
for client in Client.ClientList do if client.Name=='ShieldHost' then R.client=client end end
local c=assert(R.client and R.client.Character,'real client character required');R.defender=c
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end;h.WaterVolume=0;h.Oxygen=10000000 end
local origin=room.WorldPosition
c.TeleportTo(origin+Vector2(200,0));c.GodMode=false;c.SetAllDamage(0,0,0);c.CharacterHealth.RemoveAllAfflictions()
for item in c.Inventory.AllItems do item.Drop(c,true) end
assert(not BMTHeadsets.equipped(c),'shield test must not use headset protection or healing')
local function spawn(kind,inv,fn) Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[kind],inv,nil,nil,function(x) R.created[#R.created+1]=x;if fn then fn(x) end end,false) end
spawn('combatmultitool',c.Inventory,function(gun) R.gun=gun;assert(c.Inventory.TryPutItem(gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}));U.component(gun,'LightComponent').IsOn=true;spawn('batterycell',gun.OwnInventory,function(cell) R.cell=cell end) end)
Entity.Spawner.AddCharacterToSpawnQueue('human',origin-Vector2(350,0),function(a)
 R.attacker=a;R.created[#R.created+1]=a;a.TeamID=CharacterTeamType.Team2;a.GodMode=false
 spawn((ShieldProbeWeapon or 'scp_python'),a.Inventory,function(gun) R.revolver=gun;assert(a.Inventory.TryPutItem(gun,a,{InvSlotType.RightHand}));for i=1,6 do spawn((ShieldProbeAmmo or 'scp_357round'),gun.OwnInventory) end end)
end)
local event=G.event
G.event=function(kind,s,...) if s.item==R.gun and kind=='shieldhit' then R.hits=R.hits+1 end;return event(kind,s,...) end
Hook.Patch('bmt.host.ray','Barotrauma.Items.Components.Projectile','DoHitscan',function(p,args)
 if p.User~=R.attacker and p.Launcher~=R.revolver then return end
 R.shots=R.shots+1;R.proj=p
 local s=R.gun and G.state(R.gun)
 local pos=p.Item.WorldPosition;local shield=s and s.shield
 log('SHOT '..R.shots..' user='..tostring(p.User)..' pos='..tostring(pos)..' shield='..tostring(shield~=nil)..' gun='..tostring(R.gun.WorldPosition)..' angle='..tostring(shield and shield.angle)..' dir='..tostring(args['dir'])..' ff='..tostring(p.FriendlyFire))
end,Hook.HookMethodType.Before)
Hook.Patch('bmt.host.damage','Barotrauma.Attack','DoDamageToLimb',function(_,p)
 local limb=p['targetLimb'] or p['limb'];if limb and limb.character==c then R.damage=R.damage+1;log('DAMAGE limb='..tostring(limb.type)..' shield='..tostring(R.gun and G.state(R.gun).shield~=nil)) end
end,Hook.HookMethodType.Before)
Hook.Add('think','bmt.host.health',function()
 for _,x in ipairs({c,R.attacker}) do if x then x.Oxygen=100;x.PressureProtection=1000000 end end
 if R.cell then R.cell.Condition=100 end
end)
local function start()
 if not R.cell or not R.revolver then Timer.Wait(start,100);return end
 local m=Networking.Start('bmt.shield.host.target');m.WriteUInt16(R.attacker.ID);Networking.Send(m,R.client.Connection)
 R.attacker.AIController.AimSpeed=10;R.attacker.AIController.AimAccuracy=1
 local manager=R.attacker.AIController.ObjectiveManager
 local order=AIObjectiveCombat(R.attacker,c,CombatMode.Offensive,manager);order.ForceHighestPriority=true;manager.SetForcedOrder(order)
 log('START client='..R.client.Name..' godmode='..tostring(c.GodMode)..' gun='..R.gun.ID..' attacker='..R.attacker.ID)
 Timer.Wait(function()
  local ctx=G.context(R.gun)
  log('RESULT shots='..R.shots..' hits='..R.hits..' damage='..R.damage..' vitality='..c.Vitality..' aim='..tostring(ctx.aim)..' shield='..tostring(G.state(R.gun).shield~=nil)..' AI='..tostring(manager.CurrentObjective)..' weapon='..tostring(order.Weapon))
  manager.ClearForcedOrder();R.attacker.AIController.Enabled=false
  assert(R.shots>0 and R.hits>=R.shots and R.damage==0 and c.Vitality>=99.99, 'shield server regression: inspect host-shield-results.txt')
  local done=Networking.Start('bmt.shield.host.done');done.WriteUInt16(R.shots);Networking.Send(done,R.client.Connection)
 end,14000)
end
Timer.Wait(start,1000)

