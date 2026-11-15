-- Disposable multiplayer Sandbox only; run before shield_host_server.lua.
assert(CLIENT and Game.RoundStarted and not Game.IsSingleplayer)
local input=function(c)
 if c~=Character.Controlled then return end
 local target=ShieldHostTarget and Entity.FindEntityByID(ShieldHostTarget)
 if not target then return end
 c.CursorPosition=c.Position+target.WorldPosition-c.WorldPosition
 c.SetInput(InputType.Aim,false,true)
 c.SetInput(InputType.Shoot,false,false)
 for _,k in ipairs({InputType.Left,InputType.Right,InputType.Up,InputType.Down}) do c.SetInput(k,false,false) end
end
Networking.Receive('bmt.shield.host.target',function(m) ShieldHostTarget=m.ReadUInt16();print('[HOST SHIELD] target='..ShieldHostTarget) end)
Hook.Patch('bmt.host.input','Barotrauma.Character','ControlLocalPlayer',input,Hook.HookMethodType.After)
Hook.Patch('bmt.host.control','Barotrauma.Character','Control',input,Hook.HookMethodType.Before)
Hook.Patch('bmt.host.netinput','Barotrauma.Character','UpdateNetInput',input,Hook.HookMethodType.Before)
print('[HOST SHIELD] client ready')

local U=require('CombatTool.util');local Core=require('CombatTool.core');local G=BMTCombat
local rows={};local passed,failed,localDamage=0,0,0
local minHealth,maxOverlay,clientScans=math.huge,0,0
Hook.Patch('bmt.host.client-damage','Barotrauma.Attack','DoDamageToLimb',function(_,p)
 local limb=p['targetLimb']
 if limb and limb.character==Character.Controlled then localDamage=localDamage+1 end
end,Hook.HookMethodType.Before)
Hook.Patch('bmt.host.client-health','Barotrauma.Items.Components.Projectile','DoHitscan',function(proj)
 if not proj.User or proj.User.ID~=ShieldHostTarget then return end
 clientScans=clientScans+1
 local c=Character.Controlled
 minHealth=math.min(minHealth,c.Vitality);maxOverlay=math.max(maxOverlay,c.CharacterHealth.DamageOverlayTimer)
 local row='HEALTH value='..c.Vitality..' localDamage='..localDamage..' overlay='..c.CharacterHealth.DamageOverlayTimer
 rows[#rows+1]=row;print('[TRACER CHECK] '..row)
end,Hook.HookMethodType.After)
Networking.Receive('bmt.shield.host.done',function(m)
 local expected=m.ReadUInt16()
 local summary='TOTAL serverShots='..expected..' clientScans='..clientScans..' passed='..passed..' failed='..failed..' localDamage='..localDamage..' minHealth='..minHealth..' maxOverlay='..maxOverlay
 rows[#rows+1]=summary;print('[TRACER CHECK] '..summary)
 File.Write('LocalMods/MULTI-TOOL-V2/host-tracer-after.txt',table.concat(rows,'\n'))
 -- Count native client replays separately from authoritative server shots.
 assert(expected>0 and clientScans>0 and clientScans<=expected and passed==clientScans and failed==0,'every replayed shot must stop on the shield')
 assert(localDamage==0 and minHealth>=99.99 and maxOverlay<.001,'blocked bullets must not cause local wounds or pain')
end)
Hook.Patch('bmt.host.tracer','Barotrauma.Items.Components.Projectile','LaunchProjSpecific',function(proj,p)
 if not proj.User or proj.User.ID~=ShieldHostTarget then return end
 local a,b=U.point(p['startLocation']),U.point(p['endLocation'])
 local near=false
 for _,snapshot in ipairs(G.remote.shields) do
  local item=Entity.FindEntityByID(snapshot.id)
  if item and item.body then
   item.body.UpdateDrawPosition();local pos=item.body.DrawPosition
   local s={x=pos.X,y=pos.Y,angle=item.body.DrawRotation+(item.body.Dir<0 and -math.pi or 0),radius=80,halfAngle=math.pi/3}
   local t=Core.segmentArc(a,b,s)
   local dist=math.sqrt((b.x-s.x)^2+(b.y-s.y)^2)
   if math.abs(dist-80)<.05 then near=true end
   if t and t<.999 then failed=failed+1;print('[TRACER CHECK] FAIL t='..t) end
  end
 end
 if near then passed=passed+1 end
 local row='ammo='..proj.Item.Prefab.Identifier.Value..' end='..b.x..','..b.y..' onArc='..tostring(near)..' passed='..passed..' failed='..failed
 rows[#rows+1]=row;print('[TRACER CHECK] '..row);File.Write('LocalMods/MULTI-TOOL-V2/host-tracer-after.txt',table.concat(rows,'\n'))
end,Hook.HookMethodType.After)
print('[TRACER CHECK] ready')
