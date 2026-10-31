-- Disposable server only: native platform, hatch and breached-wall fixtures.
-- Optional physics_baseline.lua is a copy of the pre-1.1.9 physics module.
local G=BMTCombat
local U=require('CombatTool.util')
LuaUserData.RegisterType('Barotrauma.Structure')
LuaUserData.RegisterType('Barotrauma.StructurePrefab')
local S=LuaUserData.CreateStatic('Barotrauma.Structure')
local SP=LuaUserData.CreateStatic('Barotrauma.StructurePrefab')
local legacy
if File.Exists('LocalMods/MULTI-TOOL-V2/Lua/Tests/physics_baseline.lua') then
    legacy={}
    dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/physics_baseline.lua').install(legacy,_G)
end
local created,results={},{}
local function track(value) created[#created+1]=value;return value end
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[BMT PASSAGE] '..results[#results])
end
local wallPrefab
for wall in S.WallList do
    if wall.HasBody and not wall.IsPlatform and wall.MaxHealth>0 then wallPrefab=wall.Prefab;break end
end
assert(wallPrefab)
local origin=Submarine.MainSub.WorldPosition+Vector2(0,5000)
for i=1,20 do
    if not G.cast(U.point(origin-Vector2(0,200)),U.point(origin+Vector2(0,200)),0,nil,true) then break end
    origin=origin+Vector2(500,500)
end
local function structure(prefab,offset)
    local p=origin+Vector2(offset,0)
    return track(S(Rectangle(math.floor(p.X-100),math.floor(p.Y+10),200,20),prefab,nil))
end
local function ray(wall,cast)
    local p=wall.WorldPosition
    return (cast or G.cast)(U.point(p+Vector2(0,90)),U.point(p-Vector2(0,90)),12,nil,true)
end
local platform=structure(SP.Prefabs['platform'],0)
check('platform is transparent to the corrected projectile ray',function()
    if legacy then assert(ray(platform,legacy.cast),'baseline did not reproduce platform obstruction') end
    assert(not ray(platform),'platform still causes false ricochet')
end)
local wall=structure(wallPrefab,600)
check('solid native wall still blocks the swept energy ring',function()
    assert(ray(wall),'collision filter made a real wall transparent')
end)
check('fully breached wall leaves only repair fixtures, which must not block',function()
    for i=0,wall.SectionCount-1 do wall.SetDamage(i,wall.MaxHealth,nil,false,true,false,false) end
    if legacy then assert(ray(wall,legacy.cast),'baseline did not reproduce repair-body obstruction') end
    assert(not ray(wall),'repair fixture sealed the destroyed wall hole')
end)
local hatch=track(Item(ItemPrefab.Prefabs['hatch'],origin+Vector2(1200,0),nil))
local door=U.component(hatch,'Door')
check('closed horizontal hatch blocks, fully open hatch passes',function()
    door.IsOpen=false;door.Update(.016,nil)
    local p=hatch.WorldPosition
    local a,b=U.point(p+Vector2(0,90)),U.point(p-Vector2(0,90))
    assert(G.cast(a,b,8,nil,true),'closed hatch was ignored')
    door.IsOpen=true;door.Update(.016,nil)
    assert(not G.cast(a,b,8,nil,true),'open hatch still blocks the ring')
end)
for i=#created,1,-1 do if not created[i].Removed then created[i].Remove() end end
File.Write('LocalMods/MULTI-TOOL-V2/passage-results.txt',table.concat(results,'\n'))
