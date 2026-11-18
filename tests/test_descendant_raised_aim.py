from lua_support import LuaCase


class DescendantRaisedAimTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            Core=require('DescendantSuit.core');Motion=require('DescendantSuit.motion')
            G=require('DescendantSuit.game').new({Game={IsSingleplayer=true}})
            owner={AnimController={InWater=false},SelectedItem='manual',SelectedSecondaryItem='ladder'}
            base={x=0,y=0};rotation=0;facing=1;boxes={};casts=0
            enemy={WorldPosition={X=500,Y=0}};ally={}
            target={id='c1',kind='combat',entity=enemy,point={x=500,y=0}}
            state={mode='combat',target=target}
            G.mount=function() return base,rotation,facing end
            G.restGoal=function() return {x=base.x+10,y=base.y+80} end
            G.cast=function(a,b,radius,character,wallsOnly)
                casts=casts+1;local nearest
                for _,box in ipairs(boxes) do
                    if not wallsOnly or box.wall then
                        local lo,hi=0,1;local hit=true
                        for _,axis in ipairs({'x','y'}) do
                            local d=b[axis]-a[axis];local mn,mx=box[axis..'1'],box[axis..'2']
                            if math.abs(d)<1e-7 then if a[axis]<mn or a[axis]>mx then hit=false end
                            else local u,v=(mn-a[axis])/d,(mx-a[axis])/d
                                if u>v then u,v=v,u end;lo=math.max(lo,u);hi=math.min(hi,v)
                            end
                        end
                        if hit and lo<=hi and (not nearest or lo<nearest.t) then
                            nearest={t=lo,kind=box.wall and 'wall' or 'character',target=ally,blocker=box,
                                x=a.x+(b.x-a.x)*lo,y=a.y+(b.y-a.y)*lo}
                        end
                    end
                end
                return nearest
            end
            Motion.install(G,{})
            local ok,Aim=pcall(require,'DescendantSuit.aim')
            if ok then Aim.install(G,{}) end
            function npc(x1,x2,top) boxes={{x1=x1,x2=x2,y1=-100,y2=top}} end
        """)

    def test_clear_land_aim_keeps_ordinary_low_pose(self):
        self.lua.execute("""
            local p,raised=G.planShot(owner,state,target)
            assert(p and not raised and math.abs(p.muzzle.y)<1)
        """)

    def test_ally_between_wearer_and_ordinary_muzzle_still_triggers_lift(self):
        self.lua.execute("""
            npc(65,100,55)
            local p,raised=G.planShot(owner,state,target)
            assert(p and raised and p.muzzle.y>55,'arm was pushed forward through ally instead of lifted')
            assert(G.visibleFromTool(owner,state,target,true))
        """)

    def test_enemy_can_be_acquired_when_ally_blocks_ordinary_nozzle_ray(self):
        self.lua.execute("""
            npc(180,220,45)
            assert(G.visibleFromTool(owner,state,target,true),'blocked enemy never reaches elevated aim planner')
            local p,raised=G.planShot(owner,state,target);assert(raised and p.muzzle.y>45)
        """)

    def test_raised_arm_can_bend_over_a_low_wall_without_any_link_crossing_it(self):
        self.lua.execute("""
            boxes={{wall=true,x1=30,x2=85,y1=-200,y2=55}}
            local p,raised=G.planShot(owner,state,target)
            assert(p and raised,'no raised low-wall pose')
            assert(G.cast(p.base,p.muzzle,0,owner,true),'fixture must block straight base-to-nozzle ray')
            assert(G.shotPathClear(owner,p,target),'one of the actual arm links crosses wall')
            assert((p.tip.x-base.x)^2+(p.tip.y-base.y)^2<=Core.config.reach^2+.01)
        """)

    def test_full_wall_or_ceiling_cannot_be_bypassed(self):
        self.lua.execute("""
            boxes={{wall=true,x1=150,x2=170,y1=-1000,y2=1000}}
            assert(not G.planShot(owner,state,target),'aimed through full wall')
            assert(not G.visibleFromTool(owner,state,target,true))
            G.now=1;npc(65,100,55)
            boxes[#boxes+1]={wall=true,x1=-200,x2=200,y1=65,y2=85}
            assert(not G.planShot(owner,state,target),'arm goes through ceiling to clear ally')
        """)

    def test_swimming_preserves_the_existing_ordinary_pose(self):
        self.lua.execute("""
            owner.AnimController.InWater=true;npc(65,100,55)
            local p,raised=G.planShot(owner,state,target)
            assert(p and not raised and math.abs(p.muzzle.y)<1)
            G.now=1;npc(180,220,45)
            assert(not G.planShot(owner,state,target),'swimming silently gained overhead path search')
        """)

    def test_firing_waits_for_elevated_position_even_when_low_nozzle_is_past_ally(self):
        self.lua.execute("""
            npc(65,100,55)
            state.toolAngles=Motion.angles(Core.toolPose(base,target.point,G.restGoal(),1,0),0)
            assert(not G.armReady(owner,state,target),'fired while still below raised aim pose')
            for i=1,180 do G.now=G.now+1/60;G.advanceTool(owner,state,1/60) end
            assert(G.armReady(owner,state,target) and G.visibleFromTool(owner,state,target,false))
            assert(owner.SelectedItem=='manual' and owner.SelectedSecondaryItem=='ladder')
        """)

    def test_probe_is_cached_and_returns_to_low_only_after_clearance_is_stable(self):
        self.lua.execute("""
            npc(65,100,55);assert(G.planShot(owner,state,target));local before=casts
            for i=1,20 do G.now=i*.005;G.planShot(owner,state,target) end
            assert(casts==before,'full overhead search runs every frame')
            boxes={};G.now=.14
            local p,raised=G.planShot(owner,state,target);assert(raised,'arm immediately bobbed down')
            G.now=1;local q,high=G.planShot(owner,state,target)
            assert(q and not high,'arm never returns to normal when obstruction leaves')
        """)

    def test_cached_relative_pose_follows_small_wearer_movements(self):
        self.lua.execute("""
            npc(65,100,55);local p=G.planShot(owner,state,target);local before=casts
            base={x=10,y=0};G.now=.05
            local q=G.planShot(owner,state,target)
            assert(math.abs(q.tip.x-p.tip.x-10)<.001,'cached wrist stuck at old world position')
            assert(casts==before)
        """)

    def test_new_obstruction_keeps_target_while_actual_fire_stops_and_lift_is_planned(self):
        self.lua.execute("""
            assert(G.planShot(owner,state,target))
            state.toolAngles=Motion.angles(Core.toolPose(base,target.point,G.restGoal(),1,0),0)
            npc(180,220,45)
            target.trackable=G.visibleFromTool(owner,state,target,true)
            target.visible=G.visibleFromTool(owner,state,target,false)
            target.alive=true;target.hostile=true;target.distance=500
            local kept,fire=Core.contact(state,target,G.now)
            assert(kept and not fire,'target dropped or shot through newly entering ally')
            G.now=.13;local p,raised=G.planShot(owner,state,target)
            assert(p and raised)
        """)

    def test_target_switch_does_not_reuse_another_targets_raised_pose(self):
        self.lua.execute("""
            npc(65,100,55);local p,high=G.planShot(owner,state,target);assert(high)
            boxes={};target={id='c2',kind='combat',entity={},point={x=400,y=0}};state.target=target
            local q,raised=G.planShot(owner,state,target)
            assert(q and not raised,'old target elevation leaked into new target')
        """)

    def test_new_ally_before_cached_nozzle_blocks_actual_fire_immediately(self):
        self.lua.execute("""
            assert(G.planShot(owner,state,target))
            state.toolAngles=Motion.angles(Core.toolPose(base,target.point,G.restGoal(),1,0),0)
            G.now=.04;npc(65,100,55)
            assert(G.visibleFromTool(owner,state,target,true),'cached target should stay tracked')
            assert(not G.visibleFromTool(owner,state,target,false),'shot past newly entering pre-nozzle ally')
        """)

    def test_no_raised_plan_can_push_forearm_through_a_tall_nearby_ally(self):
        self.lua.execute("""
            npc(30,40,200)
            assert(not G.planShot(owner,state,target),'forearm passes through tall ally to fire beyond it')
        """)

    def test_swimming_preserves_straight_mount_to_nozzle_wall_block(self):
        self.lua.execute("""
            owner.AnimController.InWater=true
            boxes={{wall=true,x1=62,x2=67,y1=-4,y2=4}}
            state.toolAngles=Motion.angles(Core.toolPose(base,target.point,G.restGoal(),1,0),0)
            assert(not G.planShot(owner,state,target),'water planner gained bent-arm wall bypass')
            assert(not G.visibleFromTool(owner,state,target,false),'water firing lost original straight wall check')
        """)

    def test_overhead_pose_uses_available_headroom_below_a_cabin_ceiling(self):
        self.lua.execute("""
            npc(65,100,55)
            boxes[#boxes+1]={wall=true,x1=-200,x2=200,y1=80,y2=100}
            local p,raised=G.planShot(owner,state,target)
            assert(p and raised and p.muzzle.y>55,'no pose within available cabin headroom')
            assert(G.shotPathClear(owner,p,target))
        """)
