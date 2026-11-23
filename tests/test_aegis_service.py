from lua_support import LuaCase


class ServiceGripTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            calls={};local function body(vx)
                return {Enabled=true,Mass=10,LinearVelocity={X=vx or 0,Y=0},
                    FarseerBody={World={Gravity={X=0,Y=-9.82}},GravityScale=1},
                    ApplyForce=function(force,speed) calls[#calls+1]={force=force,speed=speed} end}
            end
            root=body();carrier=body(5)
            owner={WorldPosition={X=0,Y=0},AnimController={Collider=carrier}}
            target={character=true,WorldPosition={X=100,Y=20},DisableImpactDamageTimer=0,
                AnimController={Collider=root,Limbs={},IgnorePlatforms=false}}
            suit={};state={mode='grab',target={entity=target,kind='grab'}}
            G={authoritative=true,alive=true,now=0,states={[suit]=state},
                grabbable=function() return true end,spend=function() return 1 end,
                equipped=function() return suit end,energy=function() return 100 end,
                body=function(t) return t==owner and carrier or root end}
            E={Vector2=function(x,y) return {X=x,Y=y} end,
                LuaUserData={IsTargetType=function(t) return t.character==true end}}
            require('AegisSuit.grip').install(G,E)
        """)

    def test_recovery_cap_keeps_room_for_lift_while_carrier_runs(self):
        self.lua.execute("""
            G.hold(owner,suit,state.target,1/60);state.grip.recovering=true
            G.hold(owner,suit,state.target,1/60)
            assert(calls[#calls].speed>carrier.LinearVelocity.X+2,'world speed cap removes lifting force')
            assert(calls[#calls].force.Y>0)
        """)

    def test_character_gets_higher_lift_and_scoped_platform_impact_protection(self):
        self.lua.execute("""
            G.hold(owner,suit,state.target,1/60)
            assert(state.grip.originalOffset.y>=80,'ragdoll feet still drag')
            assert(target.AnimController.IgnorePlatforms,'one-way platforms block held body')
            assert(target.DisableImpactDamageTimer>0,'incidental impact unprotected')
            G.releaseGrip(state)
            assert(not target.AnimController.IgnorePlatforms)
            assert(not target.IsForceRagdolled)
        """)

    def test_loose_item_is_pulled_to_actual_claw_instead_of_an_unrelated_offset(self):
        self.lua.execute("""
            target.character=false
            carrier.LinearVelocity.X=0
            G.toolPose=function() return {muzzle={x=50,y=80}} end
            G.hold(owner,suit,state.target,1/60)
            assert(calls[#calls].force.X<0,'item is not following claw endpoint')
        """)

    def test_loose_item_follows_a_clear_waypoint_when_claw_is_behind_a_wall(self):
        self.lua.execute("""
            target.character=false;target.WorldPosition.X=-50;owner.WorldPosition.X=50
            carrier.LinearVelocity.X=0
            G.toolPose=function() return {muzzle={x=90,y=20}} end
            G.cast=function(a,b)
                if a.x<0 and b.x>=0 then
                    local t=-a.x/(b.x-a.x)
                    return {t=t,x=0,y=a.y+(b.y-a.y)*t,nx=-1,ny=0}
                end
            end
            assert(G.hold(owner,suit,state.target,1/60))
            assert(calls[#calls].force.Y>100,'item was pulled straight into the wall')
        """)

    def test_wall_recovery_does_not_drag_held_target_with_carrier_velocity(self):
        self.lua.execute("""
            G.cast=function(a,b) return {t=.5,x=a.x,y=a.y,nx=-1,ny=0} end
            assert(G.hold(owner,suit,state.target,1/60))
            assert(math.abs(calls[#calls].force.X)<.01,'carrier pulled the target out of its safe position')
        """)

    def test_claw_turning_toward_waypoint_does_not_cancel_recovery(self):
        self.lua.execute("""
            target.character=false;target.WorldPosition.X=-50;owner.WorldPosition.X=-150
            carrier.LinearVelocity.X=0
            local muzzle={x=-50,y=50}
            G.toolPose=function() return {muzzle=muzzle} end
            G.cast=function(a,b)
                if a.x<0 and b.x>=0 then
                    local t=-a.x/(b.x-a.x)
                    return {t=t,x=0,y=a.y+(b.y-a.y)*t,nx=-1,ny=0}
                end
            end
            assert(G.hold(owner,suit,state.target,1/60))
            owner.WorldPosition.X=50;muzzle.x=100;G.now=.2
            assert(G.hold(owner,suit,state.target,1/60))
            local waypoint=assert(state.grip.waypoint)
            muzzle.x=waypoint.x;muzzle.y=waypoint.y;G.now=.4
            assert(G.hold(owner,suit,state.target,1/60))
            assert(state.grip.waypoint,'claw stopped routing around the wall before clearing it')
        """)


class ServiceTrackingTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            M=require('AegisSuit.motion');rotation=0;facing=1
            G={authoritative=true,now=1,mount=function() return {x=0,y=0},rotation,facing end,
                restGoal=function() return {x=20,y=80} end}
            M.install(G,{})
            state={target={kind='repair',point={x=140,y=40}}}
            for i=1,240 do G.advanceTool({},state,1/60) end
        """)

    def test_low_ceiling_keeps_the_highest_safe_body_anchor_before_lowering_to_floor(self):
        self.lua.execute("""
            local M=require('AegisSuit.grip')
            local function cast(a,b) if b.y>200 then return {t=.5,x=b.x,y=200,nx=0,ny=-1} end end
            local goal,recovery=M.anchor({x=0,y=70},{x=120,y=85},{x=110,y=150},true,cast)
            assert(recovery and goal.y>=45,'small ceiling obstruction pulled body down to wearer feet')
        """)

    def test_low_room_still_lifts_body_when_only_short_clearance_is_available(self):
        self.lua.execute("""
            local M=require('AegisSuit.grip')
            local function cast(a,b)
                if b.y>81 then return {t=.5,x=b.x,y=81,nx=0,ny=-1} end
            end
            local goal,recovery,waiting=M.anchor({x=0,y=0},{x=120,y=85},{x=130,y=0},true,cast)
            assert(recovery and not waiting and goal.y>=25,'body left on floor despite safe low lift')
            assert(goal.y+50<=81,'head pushed through ceiling')
        """)

    def test_torso_turn_does_not_drag_world_aim_through_a_large_sweep(self):
        self.lua.execute("""
            local old=M.pose({x=0,y=0},rotation,state.toolAngles).angle
            rotation=math.pi/2;G.advanceTool({},state,1/60)
            local new=M.pose({x=0,y=0},rotation,state.toolAngles).angle
            assert(math.abs(M.delta(new,old))<.2,'torso turn swept arm off target')
        """)

    def test_facing_flip_keeps_existing_ik_bend_during_work(self):
        self.lua.execute("""
            local old=state.toolAngles.lower
            facing=-1
            for i=1,120 do G.advanceTool({},state,1/60) end
            assert(math.abs(M.delta(state.toolAngles.lower,old))<.1,'facing flip folded elbow through target')
        """)

    def test_repair_beam_accepts_small_transverse_motion_near_nozzle(self):
        self.lua.execute("""
            G.toolPose=function() return {muzzle={x=0,y=0},tip={x=-24,y=0},angle=0} end
            assert(G.armReady({},state,{kind='repair',point={x=20,y=3}}),'millimetric motion stops repair')
            assert(not G.armReady({},state,{kind='repair',point={x=-40,y=0}}),'backwards beam accepted')
        """)

    def test_unobstructed_nozzle_can_fire_above_a_character_but_never_through_a_wall(self):
        self.lua.execute("""
            local Game=require('AegisSuit.game').new({SERVER=true})
            Game.mount=function() return {x=0,y=0},0,1 end
            Game.toolPose=function() return {muzzle={x=80,y=100}} end
            local ally={};local enemy={};local t={entity=enemy,kind='combat',point={x=400,y=100}}
            Game.cast=function(a,b,r,owner,walls)
                if not walls and a.x<50 then return {kind='character',target=ally} end
            end
            assert(Game.visibleFromTool({}, {}, t,false),'torso occlusion disabled clear tool')
            Game.cast=function() return {kind='wall'} end
            assert(not Game.visibleFromTool({}, {}, t,false),'arm reached through a solid wall')
        """)


class ServiceDockTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            source={Condition=20,MaxCondition=100,HasTag=function(tag) return tag=='mobilebattery' end}
            ammo={Condition=35};power={Name='Powered',Voltage=1,IsActive=true}
            cabinet={Condition=100,Components={power},HasTag=function(tag) return tag=='divingsuitcontainer' end}
            suit={ParentInventory={Owner=cabinet}}
            G={authoritative=true,source=function() return source end}
            E={LuaUserData={IsTargetType=function(t,k) return t==cabinet and k=='Barotrauma.Item' end}}
            require('AegisSuit.dock').install(G,E)
        """)

    def test_powered_suit_holder_charges_source_without_replenishing_ammo(self):
        self.lua.execute("""
            G.updateDocked(suit,2)
            assert(source.Condition>20 and ammo.Condition==35)
            source.Condition=99.99;G.updateDocked(suit,2);assert(source.Condition==100)
        """)

    def test_unpowered_broken_and_non_suit_containers_do_not_charge(self):
        self.lua.execute("""
            power.Voltage=0;G.updateDocked(suit,2);assert(source.Condition==20)
            power.Voltage=1;cabinet.Condition=0;G.updateDocked(suit,2);assert(source.Condition==20)
            cabinet.Condition=100;cabinet.HasTag=function() return false end
            G.updateDocked(suit,2);assert(source.Condition==20)
        """)

    def test_installed_reactor_rod_also_recharges_when_docked(self):
        self.lua.execute("""
            source.HasTag=function(tag) return tag=='reactorfuel' end
            G.updateDocked(suit,2);assert(source.Condition>20)
        """)


class ServiceSonarTests(LuaCase):
    def test_minimized_sonar_is_only_a_small_radar_and_disappears_when_off(self):
        self.lua.execute("""
            local M=require('AegisSuit.ui')
            local off=M.layout(false,false,1280,800);assert(not off.visible)
            local mini=M.layout(true,false,1280,800)
            assert(mini.visible and not mini.controls and mini.width<=240 and mini.height==mini.width)
            local full=M.layout(false,true,1280,800);assert(full.visible and full.controls)
        """)

    def test_mineral_scanner_uses_native_component_and_authorized_mode(self):
        self.lua.execute("""
            local component={Name='Sonar',CurrentMode=1,HasMineralScanner=true}
            owner={};suit={Components={component}};state={owner=owner,mode='off',sonar=false}
            local G={authoritative=true,states={[suit]=state},equipped=function() return suit end,
                energy=function() return 100 end,state=function() return state end}
            local E={LuaUserData={CreateEnumTable=function() return {Active=1,Passive=2} end}}
            require('AegisSuit.sonar').install(G,E)
            assert(G.toggleMinerals(owner,suit));assert(state.minerals and state.sonar and state.sonarActive)
            assert(component.UseMineralScanner)
            G.setSonarMode(owner,suit,false);assert(not component.UseMineralScanner)
            assert(G.toggleMinerals(owner,suit) and component.UseMineralScanner)
            G.energy=function() return 0 end;assert(not G.toggleMinerals(owner,suit))
        """)


class ServicePassableCollisionTests(LuaCase):
    def test_only_currently_held_bodies_ignore_platforms_and_stairs(self):
        self.lua.execute("""
            local callback
            local E={LuaUserData={RegisterType=function() return {} end,MakeFieldAccessible=function() end,
                CreateEnumTable=function() return {None=0} end,
                IsTargetType=function(v,t) return v.structure and t=='Barotrauma.Structure' end}}
            local G={authoritative=true,patch=function(id,t,m,fn) callback=fn end}
            require('AegisSuit.grip').install(G,E)
            local person={};local anim={character=person}
            local wall={structure=true,IsPlatform=true,StairDirection=0}
            local p={f2={Body={UserData=wall}}};callback(anim,p);assert(not p.PreventExecution)
            G.heldCharacters[person]=true
            p={f2={Body={UserData=wall}}};assert(callback(anim,p)==false and p.PreventExecution)
            wall.IsPlatform=false;p={f2={Body={UserData=wall}}};callback(anim,p);assert(not p.PreventExecution)
            wall.StairDirection=1;p={f2={Body={UserData=wall}}};assert(callback(anim,p)==false and p.PreventExecution)
            G.heldCharacters[person]=nil;p={f2={Body={UserData=wall}}};callback(anim,p);assert(not p.PreventExecution)
        """)
