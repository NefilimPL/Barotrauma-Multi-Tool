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
local rows={};local passed,failed=0,0
Networking.Receive('bmt.shield.host.done',function(m)
 local expected=m.ReadUInt16()
 local summary='TOTAL expected='..expected..' passed='..passed..' failed='..failed
 rows[#rows+1]=summary;print('[TRACER CHECK] '..summary)
 File.Write('LocalMods/MULTI-TOOL-V2/host-tracer-after.txt',table.concat(rows,'\n'))
 assert(expected>0 and passed==expected and failed==0,'tracers must stop on every shield contact')
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
