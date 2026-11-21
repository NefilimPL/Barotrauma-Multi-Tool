-- Native joined-client observer, never package.
local native=SoundPlayer
local tracer,sounds,playing=0,0,0
local function save()
    File.Write('LocalMods/System-Aegis/servo-v2-pulse-visual.txt',
        'native pulse tracer emissions='..tracer..' automatic pulse sounds='..sounds..' playing channels='..playing)
end
SoundPlayer=setmetatable({PlaySound=function(id,...)
    local channel=native.PlaySound(id,...)
    if id=='aegis_pulse' then sounds=sounds+1;if channel and channel.IsPlaying then playing=playing+1 end;save() end
    return channel
end},{__index=function(_,key) return native[key] end})
LuaUserData.MakeMethodAccessible(LuaUserData.RegisterType('Barotrauma.Items.Components.Projectile'),'LaunchProjSpecific')
Hook.Patch('aegis.servo.v2.tracer-observer','Barotrauma.Items.Components.Projectile','LaunchProjSpecific',function(projectile)
    if projectile.Item.Prefab.Identifier.Value~='aegispulsebolt' then return end
    tracer=tracer+1;save()
    File.Write('LocalMods/System-Aegis/headset-capture.request',(AegisCaptureRoot or 'LocalMods/System-Aegis/')..'servo-v2-pulse-real.png')
end,Hook.HookMethodType.After)
Timer.Wait(function()
    SoundPlayer=native
    Hook.RemovePatch('aegis.servo.v2.tracer-observer','Barotrauma.Items.Components.Projectile','LaunchProjSpecific',Hook.HookMethodType.After)
    save()
end,10000)
save()
