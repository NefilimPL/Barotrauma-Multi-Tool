-- Actual native structures and ragdoll collisions; isolated SP fixture only.
assert(Game.IsSingleplayer and Game.RoundStarted)
local G=BMTDescendantSuit;local B=ServoService;local c=Character.Controlled
local R={rows={},contacts=0,passed=0,failed=0};ServoPlatforms=R
local P='bmt.servo.service.platforms';local U=require('CombatTool.util')
local function log(line) R.rows[#R.rows+1]=line;print('[SERVO PLATFORMS] '..line);File.Write('LocalMods/MULTI-TOOL-V2/servo-service-platforms.txt',table.concat(R.rows,'\n')) end
local function check(name,fn) local ok,result=pcall(fn);if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end;log((ok and 'PASS ' or 'FAIL ')..name..' '..tostring(result)) end
local original=Submarine.MainSub.WorldPosition+Vector2(0,3000)
LuaUserData.RegisterType('Barotrauma.StructurePrefab')
local structurePrefabs=LuaUserData.CreateStatic('Barotrauma.StructurePrefab')
local state=G.state(B.suit)
Hook.Patch(P,'Barotrauma.Ragdoll','OnLimbCollision',function(anim,p)
    if anim~=B.human.AnimController then return end
    local wall=p['f2'].Body.UserData
    if wall==R.structure then R.contacts=R.contacts+1 end
end,Hook.HookMethodType.Before)
local function run(id,next)
    G.setMode(B.suit,'off',c);c.SelectedItem=nil;c.SelectedSecondaryItem=nil
    c.TeleportTo(original);B.human.TeleportTo(original+Vector2(90,150));B.human.SetAllDamage(0,0,0)
    local p=c.Position
    R.structure=Structure(Rectangle(p.X+10,p.Y+50,220,id=='platform' and 27 or 220),structurePrefabs.Prefabs[id],nil)
    R.contacts=0;R.health=B.human.CharacterHealth.Vitality
    G.setMode(B.suit,'grab',c)
    local q=B.human.WorldPosition
    state.target={id='g'..B.human.ID,entity=B.human,kind='grab',point={x=q.X,y=q.Y},visible=true,free=true,distance=175}
    state.grabStarted=G.now;G.hold(c,B.suit,state.target,1/60)
    Timer.Wait(function() c.TeleportTo(original+Vector2(0,-180)) end,700)
    Timer.Wait(function()
        check('held body crosses native '..id,function()
            assert(state.grip and state.grip.entity==B.human,'grip lost')
            assert(B.human.WorldPosition.Y<original.Y-20,'body blocked at '..(B.human.WorldPosition.Y-original.Y))
            local body;U.each(R.structure.Bodies,function(b) body=body or b end)
            local fixture;U.each(body.FixtureList,function(f) fixture=fixture or f end)
            local heldFixture;U.each(B.human.AnimController.Collider.FarseerBody.FixtureList,function(f) heldFixture=heldFixture or f end)
            assert(B.human.AnimController.OnLimbCollision(heldFixture,fixture,nil)==false,'held collision handler blocks passable structure')
            assert(B.human.CharacterHealth.Vitality>=R.health-.01,'incidental injury')
            return 'nativeCallback=false; body crossed from +150 to '..(B.human.WorldPosition.Y-original.Y)..'; vitality='..B.human.CharacterHealth.Vitality
        end)
        G.setMode(B.suit,'off',c);R.structure.Remove();next()
    end,2500)
end
run('platform',function() run('stairsright',function()
    Hook.RemovePatch(P,'Barotrauma.Ragdoll','OnLimbCollision',Hook.HookMethodType.Before)
    log('RESULT passed='..R.passed..' failed='..R.failed..' real_physics=true')
end) end)
