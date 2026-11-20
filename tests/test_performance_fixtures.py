from pathlib import Path
from lua_support import LuaCase, ROOT


class PerformanceWorkProofTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            hooks={};Hook={HookMethodType={Before=0,After=1},Patch=function(id,_,_,fn,overload)
                hooks[id]=overload and type(overload)=='function' and overload or fn
            end}
            local damage=100
            wall={SectionDamage=function() return damage end};setDamage=function(v) damage=v end
            a={item={},work=0,wall=wall,section=0,testMode='weld'}
            b={item={},work=0,wall=wall,section=0,testMode='weld'}
            R={actors={a,b},started=0,phase={mode='weld',item='combatmultitool'}}
            C={rings={},fire=function() end,toolComponent=function(item) return item.tool end}
            D={hold=function() return true end}
            V={insert=function() return true end,snapshot=function() return {} end}
            H={recordDebit=function() end}
            A={C=C,D=D,V=V,H=H,U={},now=function() return 10 end}
        """)
        self.lua.execute("dofile(...).install(R,A)", (ROOT / 'tests/runtime/performance/scenarios.lua').as_posix())

    def test_ring_cap_noop_is_not_credited_as_a_shot(self):
        self.lua.execute("C.fire({item=a.item},{});assert(a.work==0,'no ring was created')")

    def test_actual_ring_creation_is_credited(self):
        self.lua.execute("""
            -- The installed wrapper captured the native function; reinstall with a real emitter.
            C.fire=function() C.rings[#C.rings+1]={} end
        """)
        self.lua.execute("dofile(...).install(R,A)", (ROOT / 'tests/runtime/performance/scenarios.lua').as_posix())
        self.lua.execute("C.fire({item=a.item},{});assert(a.work==1)")

    def test_unchanged_wall_and_unrelated_power_loss_are_not_work(self):
        self.lua.execute("""
            local tool={Item=a.item};a.item.tool=tool
            hooks['bmt.performance.wall.before'](tool)
            a.item.Condition=20
            hooks['bmt.performance.wall.after'](tool)
            assert(a.work==0 and b.work==0)
        """)

    def test_shared_wall_credits_only_the_acting_tool_and_correct_direction(self):
        self.lua.execute("""
            local first={Item=a.item};a.item.tool=first
            local second={Item=b.item};b.item.tool=second
            local function damage(value)
                hooks['bmt.performance.wall.damage.before'](wall,{sectionIndex=1})
                setDamage(value)
                hooks['bmt.performance.wall.damage.after'](wall)
            end
            hooks['bmt.performance.wall.before'](first);damage(80);hooks['bmt.performance.wall.after'](first)
            assert(a.work==20 and b.work==0)
            setDamage(100) -- fixture reset outside a tool use must not earn credit
            b.testMode='cut'
            hooks['bmt.performance.wall.before'](second);damage(120);hooks['bmt.performance.wall.after'](second)
            assert(a.work==20 and b.work==20)
            hooks['bmt.performance.wall.before'](second);damage(110);hooks['bmt.performance.wall.after'](second)
            assert(b.work==20,'cutting received welding credit')
        """)

    def test_no_mod_control_installs_the_same_native_proof_hooks(self):
        self.lua.execute('enabled={};for id in pairs(hooks) do enabled[id]=true end;hooks={}')
        self.lua.execute("dofile(...).install(R,{U={},now=A.now})", (ROOT / 'tests/runtime/performance/scenarios.lua').as_posix())
        self.lua.execute("for id in pairs(enabled) do assert(hooks[id], 'missing no-mod native instrumentation: '..id) end")

    def test_native_hitscan_counts_the_real_launcher_and_not_an_unrelated_projectile(self):
        self.lua.execute("""
            a.testKind='smg'
            hooks['bmt.performance.native.shot.DoHitscan']({Launcher={}})
            assert(a.work==0)
            hooks['bmt.performance.native.shot.DoHitscan']({Launcher=a.item})
            assert(a.work==1,'native hitscan was not counted as actual work')
        """)


class PerformanceSoakProofTests(LuaCase):
    def setUp(self):
        super().setUp()

    def test_removed_fixture_entities_are_not_retained_during_a_long_soak(self):
        self.lua.execute("Proof=dofile(...)", (ROOT / 'tests/runtime/performance/proof.lua').as_posix())
        self.lua.execute("""
            local queued=0;local t=Proof.tracker(function() queued=queued+1 end)
            local live=t.add({})
            for i=1,10000 do local x=t.add({});t.remove(x) end
            local count=0;for _ in pairs(t.items) do count=count+1 end
            assert(count==1 and t.items[live] and queued==10000)
            t.clear();assert(not next(t.items) and queued==10001)
        """)

    def test_first_action_cannot_validate_an_actor_that_stops_for_the_rest_of_soak(self):
        self.lua.execute("Proof=dofile(...)", (ROOT / 'tests/runtime/performance/proof.lua').as_posix())
        self.lua.execute("""
            local r={phase={item='mixed',count=2},started=0,actors={{work=0},{work=0}}}
            Proof.sustained(r,5)
            r.actors[1].work=2;r.actors[2].work=1
            assert(Proof.sustained(r,35))
            r.actors[1].work=4
            assert(not Proof.sustained(r,65),'one early action validated an inactive later window')
            assert(#r.workWindows==2 and r.workWindows[2].work[2]==0)
        """)

    def test_wall_fixture_tracks_translation_without_drifting_from_its_section(self):
        self.lua.execute("Proof=dofile(...)", (ROOT / 'tests/runtime/performance/proof.lua').as_posix())
        self.lua.execute("""
            local mt={}
            function vec(x,y) return setmetatable({X=x,Y=y},mt) end
            mt.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y) end
            mt.__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y) end
            local position=vec(500,0)
            local a={wall={SectionPosition=function() return position end},section=0,
                wallReference=position,aim=position,home=vec(415,0)}
            position=vec(700,70);Proof.followWall(a)
            assert(a.aim.X==700 and a.home.X==615 and a.home.Y==70)
            for i=1,20 do Proof.followWall(a) end
            assert(a.home.X==615 and a.home.Y==70,'tracking accumulated the same translation repeatedly')
        """)

    def test_each_isolated_case_clears_persistent_afflictions_not_just_physical_damage(self):
        self.lua.execute("Proof=dofile(...)", (ROOT / 'tests/runtime/performance/proof.lua').as_posix())
        self.lua.execute("""
            local effects={bloodloss=150,paralysis=1,burn=10}
            local c={Oxygen=90,Stun=4,SetAllDamage=function() effects.burn=nil end,
                CharacterHealth={RemoveAllAfflictions=function() effects={} end}}
            Proof.resetHealth(c)
            assert(not next(effects) and c.Oxygen==100 and c.Stun==0,'previous scenario still incapacitates the next one')
        """)


class PerformancePanelProofTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            CLIENT=true;Game={RoundStarted=true,IsSingleplayer=false};Character={Controlled={ID=2}}
            Character.Controlled.SetAllDamage=function() end
            Character.Controlled.CharacterHealth={RemoveAllAfflictions=function() end}
            Timer={GetTime=function() return 0 end};files={}
            LuaUserData={RegisterType=function() end,CreateStatic=function() return {GetTimestamp=function() return 100000000 end} end}
            File={Write=function(p,s) files[p]=s end,Read=function(p) return files[p] end,Exists=function(p) return files[p]~=nil end}
            receivers={};Networking={Receive=function(id,fn) receivers[id]=fn end,Send=function() end,
                Start=function() return {WriteString=function() end} end}
            Hook={HookMethodType={Before=0,After=1},Patch=function() end,Add=function(_,_,fn) think=fn end}
            pack={ID=1,ParentInventory={Owner=Character.Controlled}};Entity={FindEntityByID=function(id) if id==1 then return pack end end}
            opens=0;frame=nil
            BMTVacuum={contents=function() return {{}} end,context=function() return {valid=true,pack=pack} end,
                openPanel=function() opens=opens+1;frame={Visible=true};return frame end,
                closePanel=function() if frame then frame.Visible=false end end,
                onSnapshot=function(s) if frame and frame.Visible and s.vacuum==1 and s.filters==false and s.category=='all' and s.search=='' and s.group==0 then frame.accepted=s end end}
            function packet(strings,ints,bools,floats)
                local function take(t) return table.remove(t,1) end
                return {ReadString=function() return take(strings) end,ReadUInt16=function() return take(ints) end,
                    ReadByte=function() return take(ints) end,ReadBoolean=function() return take(bools) end,
                    ReadSingle=function() return take(floats) end}
            end
            Vector2=function(x,y) return {X=x,Y=y} end
            function reply() return {vacuum=1,pack=1,count=1,groups=1,rows={{id=3,count=1}},filters=false,category='all',search='',group=0,page=0} end
        """)
        self.lua.execute("FixtureProof=dofile(...)", (ROOT / 'tests/runtime/performance/proof.lua').as_posix())
        self.lua.execute("local original=dofile;dofile=function(path) if path=='LocalMods/MULTI-TOOL-V2/Lua/Tests/performance/proof.lua' then return FixtureProof end;return original(path) end")
        self.lua.execute("dofile(...)", (ROOT / 'tests/runtime/performance/client.lua').as_posix())
        self.lua.execute("receivers['bmt.performance.v1.prepare'](packet({'panel_case'},{1,1,1,1,0},{true},{}));think()")

    def test_rejected_or_empty_snapshot_cannot_pass_preparation(self):
        self.lua.execute("""
            local r=BMTPerformanceClient
            local wrong=reply();wrong.vacuum=99;BMTVacuum.onSnapshot(wrong)
            assert(not r.preparing.snapshot,'wrong vacuum accepted')
            wrong=reply();wrong.search='old search';BMTVacuum.onSnapshot(wrong)
            assert(not r.preparing.snapshot,'stale view accepted')
            wrong=reply();wrong.count=0;wrong.rows={};BMTVacuum.onSnapshot(wrong)
            assert(not r.preparing.snapshot,'empty storage reply accepted')
        """)

    def test_delayed_valid_snapshot_keeps_the_same_panel_at_measurement_start(self):
        self.lua.execute("""
            local r=BMTPerformanceClient;local preparedFrame=frame
            assert(r.preparing and opens==1)
            think();assert(r.preparing and opens==1)
            BMTVacuum.onSnapshot(reply());think();assert(not r.preparing)
            receivers['bmt.performance.v1.phase'](packet({'panel_case','panel'},{1,1},{true,false},{0,0,.75,500,0}))
            assert(opens==1 and r.panelFrame==preparedFrame and r.requested,'prepared panel was discarded or reopened')
        """)

    def test_closed_panel_cannot_earn_snapshot_credit(self):
        self.lua.execute("""
            local r=BMTPerformanceClient
            BMTVacuum.closePanel();BMTVacuum.onSnapshot(reply())
            assert(not r.preparing.snapshot,'closed panel accepted a snapshot')
        """)
