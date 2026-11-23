-- Test-only native reproduction. Run inside the disposable game client.
-- Model a queued raycast executing after power-off, followed by power-on.
local descriptor=LuaUserData.RegisterType('Barotrauma.Lights.LightSource')
LuaUserData.MakeFieldAccessible(descriptor,'verts')
LuaUserData.MakeMethodAccessible(descriptor,'CalculateLightVertices')
local Source=LuaUserData.CreateStatic('Barotrauma.Lights.LightSource',true)
local report={}
for _,radius in ipairs({0,120,650}) do
    local light=Source(Vector2.Zero,radius,Color(185,220,255,110),nil)
    light.Enabled=false
    local ok,err=pcall(function()
        light.RayCastTask(Vector2.Zero,0)
        local verts=light.verts
        local count=verts.Count or #verts
        light.Range=650
        local valid,geometryError=pcall(function() light.CalculateLightVertices(verts) end)
        if radius==0 then
            assert(count==0 and not valid and tostring(geometryError):find('Index was outside',1,true))
        else
            assert(count>0 and valid,tostring(geometryError))
        end
        report[#report+1]='PASS queued-radius='..radius..' vertices='..count..' geometry='..tostring(valid)
    end)
    light.Remove()
    assert(ok,tostring(err))
end
File.Write('LocalMods/System-Aegis/ui161-v161-native-geometry.txt',table.concat(report,'\n'))
