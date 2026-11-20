from lua_support import LuaCase


class DescendantAcquisitionPerformanceTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            owner={WorldPosition={X=0,Y=0},AimRefPosition={X=0,Y=0},CursorWorldPosition={X=100,Y=0},
                AnimController={InWater=false},IsKeyDown=function() return false end}
            suit={};local source={Condition=100,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            E={SERVER=true,Game={RoundStarted=true},InputType={Aim=1,Use=2},
                Util={GetItemsById=function() return {} end}}
            G=require('DescendantSuit.game').new(E)
            nativeVisible=G.visible
            nativeMount=G.mount
            G.owner=function() return owner end;G.equipped=function() return suit end
            G.source=function() return source end;G.mount=function() return {x=0,y=0},0,1 end
            G.visible=function() return true end;G.visibleFromTool=function() return true end
            G.ally=function() return false end;G.perform=function() return true end
            scans=0
            device={ID=1,Condition=10,MaxCondition=100,WorldPosition={X=60,Y=0}}
            function candidate() return {id='i1',kind='repair',entity=device,point={x=60,y=0},damaged=true,distance=60,visible=true} end
            G.gather=function() scans=scans+1;return {candidate()} end
            state=G.state(suit);state.mode='repair'
        """)

    def test_stable_manual_target_does_not_enumerate_world_again(self):
        self.lua.execute("""
            for i=1,120 do G.update(1/60) end
            assert(state.target and state.target.entity==device and state.active)
            assert(scans==1,'stable pinned repair repeats global acquisition scans: '..scans)
        """)

    def test_wide_wall_uses_resolved_near_face_for_reach_every_tick(self):
        self.lua.execute("""
            local Core=require('DescendantSuit.core')
            local face=Core.repairRange()-5
            local wall={ID=6,SectionPosition=function() return {X=face+150,Y=0} end,
                FindSectionIndex=function() return 0 end,SectionDamage=function() return 20 end}
            E.Vector2=function(x,y) return {X=x,Y=y} end
            G.visible=nativeVisible
            G.cast=function() return {kind='wall',blocker=wall,x=face,y=0} end
            G.gather=function() return {{id='w6:0',kind='weld',entity=wall,section=0,
                point={x=face,y=0},visible=true,damaged=true,distance=face}} end
            for i=1,120 do G.update(1/60) end
            assert(state.target and state.active,'reachable face dropped because section center is outside reach')
            assert(math.abs(state.target.distance-face)<1e-6)
        """)

    def assert_repair_invalidation(self, mutation):
        self.lua.execute("""
            allowed=true;device.HasAccess=function() return allowed end
            G.update(1/60);assert(state.target)
            local previous=device
            """ + mutation + """
            G.update(1/60)
            assert(not state.target and not state.active,'ineligible device remained pinned')
            device={ID=2,Condition=10,MaxCondition=100,WorldPosition={X=80,Y=0}}
            for i=1,20 do G.update(1/60) end
            assert(state.target and state.target.entity==device,'eligible alternative was not reacquired')
        """)

    def test_pinned_repair_releases_when_device_is_put_in_inventory(self):
        self.assert_repair_invalidation('device.ParentInventory={}')

    def test_pinned_repair_releases_when_access_is_revoked(self):
        self.assert_repair_invalidation('allowed=false')

    def test_grab_without_a_press_or_while_holding_does_not_scan_for_new_targets(self):
        self.lua.execute("""
            state.mode='grab'
            for i=1,60 do G.update(1/60) end
            assert(scans==0,'idle grab scans world without acquisition input')
        """)

    def test_bots_still_scan_for_threats_during_a_repair(self):
        self.lua.execute("""
            owner.IsBot=true
            for i=1,120 do G.update(1/60) end
            assert(scans>=8,'active repair stopped bot threat detection')
        """)

    def test_invalid_target_releases_and_next_tick_can_reacquire(self):
        self.lua.execute("""
            G.update(1/60);assert(state.target)
            local first=device;first.Removed=true
            device={ID=2,Condition=10,MaxCondition=100,WorldPosition={X=80,Y=0}}
            for i=1,20 do G.update(1/60) end
            assert(state.target and state.target.entity==device and state.active)
        """)

    def test_acquisition_input_is_immediate_even_if_previous_scan_is_not_due(self):
        self.lua.execute("""
            state.mode='grab';state.nextScan=999
            owner.IsKeyDown=function() return true end
            G.gather=function() scans=scans+1;return {} end
            G.update(1/60)
            assert(scans==1,'grab press waited for periodic scan')
        """)

    def test_grab_rejects_distant_items_before_inspecting_native_components(self):
        self.lua.execute("""
            local scans=0
            local E={SERVER=true,Game={},Character={CharacterList={}},
                Item={ItemList={{ID=1,WorldPosition={X=10000,Y=0}},
                               {ID=2,WorldPosition={X=80,Y=0}}}}}
            local G=require('DescendantSuit.game').new(E)
            G.mount=function() return {x=0,y=0} end
            G.grabbable=function(item) scans=scans+1;return true end
            G.visible=function() return true end
            local candidates=G.gather({}, {mode='grab',acquireGrab=true})
            assert(#candidates==1 and candidates[1].entity.ID==2)
            assert(scans==1,'far-away loot still enters component/mass checks')
        """)

    def test_owner_transform_is_read_once_in_update_and_fresh_outside_it(self):
        self.lua.execute("""
            local reads=0;local position={X=0,Y=0};G.mount=nativeMount
            E.LimbType={Torso=1};state.mode='repair'
            owner.AnimController.GetLimb=function()
                reads=reads+1
                return {WorldPosition=position,body={Rotation=0,Dir=1}}
            end
            G.advanceTool=function()
                G.mount(owner);G.restGoal(owner);G.mount(owner)
            end
            G.update(1/60)
            assert(reads==1,'native torso transform was fetched repeatedly inside one update: '..reads)
            position={X=100,Y=0}
            local p=G.mount(owner)
            assert(reads==2 and p.x==78,'async use retained a stale simulation transform')
        """)

    def test_update_error_cannot_leak_transform_cache_to_async_actions(self):
        self.lua.execute("""
            local position={X=0,Y=0};E.LimbType={Torso=1};state.mode='repair';G.mount=nativeMount
            owner.AnimController.GetLimb=function() return {WorldPosition=position,body={Rotation=0,Dir=1}} end
            G.advanceTool=function() G.mount(owner);error('fixture failure') end
            assert(not pcall(G.update,1/60))
            position={X=100,Y=0}
            assert(G.mount(owner).x==78,'failed update leaked cached torso into an async action')
        """)

    def test_combat_visibility_and_firing_use_the_same_advanced_arm_pose(self):
        self.lua.execute("""
            state.mode='combat'
            local enemy={ID=3,WorldPosition={X=100,Y=0}}
            state.target={id='c3',kind='combat',entity=enemy,point={x=100,y=0}}
            local version,visibleVersion=0,-1
            G.advanceTool=function() version=version+1 end
            G.visibleFromTool=function(_,_,_,planned)
                if not planned then visibleVersion=version end
                return true
            end
            G.perform=function()
                assert(visibleVersion==version,'visibility tested previous pose instead of the firing pose')
                return true
            end
            state.actionId='c3';state.readyAt=0
            G.update(1/60)
            assert(state.active)
        """)


class DescendantMotionPerformanceTests(LuaCase):
    def test_forward_geometry_is_reused_only_while_all_inputs_match(self):
        self.lua.execute("""
            local Motion=require('DescendantSuit.motion');local original=Motion.pose;local calls=0
            Motion.pose=function(...) calls=calls+1;return original(...) end
            local G=require('DescendantSuit.game').new({Game={IsSingleplayer=true}})
            local x,rotation=0,0;local owner={}
            G.mount=function() return {x=x,y=0},rotation,1 end
            local s={toolAngles={upper=0,lower=1,head=.2}}
            local p=G.toolPose(owner,s)
            for i=1,10 do G.toolPose(owner,s) end
            assert(calls==1,'same forward pose reconstructed repeatedly')
            x=10;local q=G.toolPose(owner,s)
            assert(calls==2 and math.abs(q.muzzle.x-p.muzzle.x-10)<1e-8,'moved mount reused stale geometry')
            s.toolAngles.upper=.5;G.toolPose(owner,s);assert(calls==3,'mutated angles reused old pose')
            rotation=.7;G.toolPose(owner,s);assert(calls==4,'rotation reused old pose')
            G.toolPose({},s);assert(calls==5,'owner transfer reused old pose')
        """)

    def test_forward_draw_pose_never_reuses_simulation_or_old_interpolated_angles(self):
        self.lua.execute("""
            local G=require('DescendantSuit.game').new({Game={IsSingleplayer=false}})
            local owner={};G.mount=function(_,draw) return {x=draw and 20 or 0,y=0},0,1 end
            local s={toolAngles={upper=0,lower=1,head=0},drawAngles={upper=.5,lower=1,head=0}}
            local p=G.toolPose(owner,s);local q=G.toolPose(owner,s,true)
            assert(p.base.x==0 and q.base.x==20 and p.elbow.y~=q.elbow.y)
            local y=q.elbow.y;s.drawAngles.upper=.6
            assert(G.toolPose(owner,s,true).elbow.y~=y,'interpolated frame is stale')
        """)

    def test_joint_step_reuses_the_same_easing_factor(self):
        self.lua.execute("""
            local M=require('DescendantSuit.motion')
            local original=math.exp;local calls=0
            math.exp=function(x) calls=calls+1;return original(x) end
            local a=M.step({upper=0,lower=0,head=0},{upper=1,lower=-1,head=.5},1/60)
            assert(a.upper>0 and a.lower<0 and a.head>0)
            assert(calls==1,'identical joint easing recomputed: '..calls)
        """)

    def test_stationary_rest_does_not_resolve_inverse_kinematics_every_tick(self):
        self.lua.execute("""
            local Core=require('DescendantSuit.core');local Motion=require('DescendantSuit.motion')
            local pose=Core.toolPose;local solved=0
            Core.toolPose=function(...) solved=solved+1;return pose(...) end
            local base={x=0,y=0};local rest={x=10,y=88};local owner={};local state={mode='off'}
            local G={now=0,mount=function() return base,0,1 end,restGoal=function() return rest end}
            Motion.install(G,{})
            for i=1,120 do G.now=i/60;G.advanceTool(owner,state,1/60) end
            assert(solved<=2,'stationary rest repeats IK: '..solved)
            local old=state.toolAngles.upper
            rest={x=-70,y=30};G.advanceTool(owner,state,1/60)
            assert(state.toolAngles.upper~=old,'changed rest pose reused obsolete IK')
        """)
