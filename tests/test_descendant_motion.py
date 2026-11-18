from lua_support import LuaCase


class DescendantServoAnimationGuardTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            hooks={};owner={SelectedItem=nil};suit={}
            E={LuaUserData={RegisterType=function(n) return n end,MakeMethodAccessible=function() end}}
            G={authoritative=false,equipped=function(c) return c==owner and suit end,
                patch=function(id,t,method,fn) hooks[method]=fn end}
            require('DescendantSuit.repair').install(G,E)
            device={};r={Item=device,CurrentFixer=owner}
        """)

    def test_replica_blocks_servo_repair_pose_before_it_can_move_or_crouch_player(self):
        self.lua.execute("""
            local fn=assert(hooks.UpdateFixAnimation,'replica has no repair animation guard')
            local p={character=owner};fn(r,p);assert(p.PreventExecution)
        """)

    def test_manually_selected_repair_keeps_its_normal_animation(self):
        self.lua.execute("""
            local fn=assert(hooks.UpdateFixAnimation)
            owner.SelectedItem=device
            local p={character=owner};fn(r,p);assert(not p.PreventExecution)
        """)

    def test_inspecting_the_automatic_repair_device_does_not_enable_wearer_animation(self):
        self.lua.execute("""
            G.states={[suit]={repairing=device}};owner.SelectedItem=device
            local p={character=owner};hooks.UpdateFixAnimation(r,p)
            assert(p.PreventExecution,'opening the device UI re-enabled servo crouching')
        """)

    def test_other_character_and_scoped_servo_are_distinguished(self):
        self.lua.execute("""
            local fn=assert(hooks.UpdateFixAnimation)
            local p={character={}};fn(r,p);assert(not p.PreventExecution)
            owner.SelectedItem=device;G.repairScope={owner=owner,repairable=r}
            p={character=owner};fn(r,p);assert(p.PreventExecution)
        """)


class DescendantMotionMathTests(LuaCase):
    def test_large_target_change_moves_partway_and_converges_without_snapping(self):
        self.lua.execute("""
            local M=require('DescendantSuit.motion')
            local current={upper=0,lower=0,head=0};local wanted={upper=2,lower=-1,head=.8}
            local a=M.step(current,wanted,1/60)
            assert(a.upper>0 and a.upper<.15 and a.lower<0 and a.lower>-.15)
            for i=1,180 do a=M.step(a,wanted,1/60) end
            assert(math.abs(a.upper-2)<.001 and math.abs(a.head-.8)<.001)
        """)

    def test_angle_wrap_uses_the_short_path_and_huge_frame_gaps_do_not_teleport(self):
        self.lua.execute("""
            local M=require('DescendantSuit.motion')
            local a=M.step({upper=math.pi-.01,lower=0,head=0},{upper=-math.pi+.05,lower=0,head=0},1/60)
            assert(math.abs(M.delta(a.upper,math.pi-.01))<.02)
            a=M.step({upper=0,lower=0,head=0},{upper=3,lower=2,head=1},10)
            assert(a.upper<1 and a.lower<1 and a.head<1)
        """)

    def test_reconstructed_pose_keeps_link_lengths_and_nozzle_attached_while_rotating(self):
        self.lua.execute("""
            local M=require('DescendantSuit.motion');local C=require('DescendantSuit.config')
            local a={upper=.7,lower=-1.3,head=.5}
            local p=M.pose({x=10,y=20},math.pi/2,a)
            assert(math.abs(math.sqrt((p.elbow.x-10)^2+(p.elbow.y-20)^2)-C.upper)<1e-6)
            assert(math.abs(math.sqrt((p.tip.x-p.elbow.x)^2+(p.tip.y-p.elbow.y)^2)-C.lower)<1e-6)
            assert(math.abs(math.sqrt((p.muzzle.x-p.tip.x)^2+(p.muzzle.y-p.tip.y)^2)-C.toolOffset)<1e-6)
        """)


class DescendantGripContactRecoveryTests(LuaCase):
    def test_established_grip_survives_brief_frame_occlusion_and_release_margin(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local t={id='g1',kind='grab',free=true,visible=true,distance=200}
            local s={mode='grab',target=t,grip={}}
            assert(C.contact(s,t,0))
            t.visible=false;local kept,working=C.contact(s,t,.5)
            assert(kept and working,'minor obstruction dropped physical hold')
            t.visible=true;t.distance=330;assert(C.contact(s,t,.6))
            assert(not C.choose('grab',{t},t.id),'fresh acquisition range expanded')
        """)


class DescendantGripAnchorPlannerTests(LuaCase):
    def test_low_ceiling_selects_a_lower_closer_anchor_without_losing_grip(self):
        self.lua.execute("""
            local M=require('DescendantSuit.grip')
            local function cast(a,b)
                if b.y>90 then return {t=.5,x=b.x,y=90,nx=0,ny=-1} end
            end
            local goal,recovering=M.anchor({x=0,y=60},{x=120,y=45},{x=120,y=80},true,cast,false)
            assert(recovering and goal.y<=45,'low ceiling was ignored')
            assert(goal.y>=0,'blocked body was forced toward the floor')
        """)

    def test_obstructed_tether_guides_around_wall_instead_of_pulling_through_it(self):
        self.lua.execute("""
            local M=require('DescendantSuit.grip')
            local function cast(a,b)
                if a.x<0 and b.x>=0 then return {t=.5,x=0,y=10,nx=-1,ny=0} end
            end
            local goal,recovering=M.anchor({x=50,y=0},{x=100,y=45},{x=-50,y=0},true,cast,true)
            assert(recovering and 50+goal.x<0 and goal.y>0,'guide crossed the wall')
        """)

    def test_open_space_preserves_original_hold_offset(self):
        self.lua.execute("""
            local M=require('DescendantSuit.grip')
            local offset={x=110,y=45}
            local goal,recovering=M.anchor({x=0,y=60},offset,{x=110,y=105},true,function() end,false)
            assert(not recovering and goal.x==110 and goal.y==45)
        """)

    def test_permanent_wall_and_invalid_or_distant_target_still_release(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local t={id='g1',kind='grab',free=true,visible=true,distance=200}
            local s={mode='grab',target=t,grip={}}
            assert(C.contact(s,t,0));t.visible=false
            assert(not C.contact(s,t,10))
            t.visible=true;t.distance=1000;assert(not C.contact(s,t,11))
            t.distance=100;t.free=false;assert(not C.contact(s,t,12))
        """)
