from lua_support import LuaCase


class DescendantContactTests(LuaCase):
    def test_contact_survives_small_movement_but_not_a_large_range_escape(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core');local limit=C.repairRange()
            local t={id='i1',kind='repair',distance=limit-1,visible=true,damaged=true}
            local s={mode='repair',target=t}
            assert(C.contact(s,t,0))
            t.distance=limit+10
            local retained,working=C.contact(s,t,.1)
            assert(retained and working,'small movement broke repair contact')
            assert(not C.choose('repair',{t}),'outside acquisition range acquired a fresh target')
            t.distance=limit+C.config.contactSlack+1
            assert(not C.contact(s,t,.2),'large range escape retained contact')
        """)

    def test_brief_occlusion_keeps_target_without_repairing_through_a_wall(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local t={id='i1',kind='repair',distance=100,visible=true,damaged=true}
            local s={mode='repair',target=t}
            assert(C.contact(s,t,0))
            t.visible=false
            local retained,working=C.contact(s,t,.2)
            assert(retained and not working)
            assert(not C.contact(s,t,1),'permanent blocker retained contact')
            t.visible=true;assert(C.contact(s,t,1.1))
            t.damaged=false;assert(not C.contact(s,t,1.2))
        """)

    def test_occlusion_grace_does_not_acquire_a_new_hidden_device(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local s={mode='repair'}
            local t={id='hidden',kind='repair',distance=50,visible=false,damaged=true}
            assert(not C.contact(s,t,0))
        """)


class DescendantToolGeometryTests(LuaCase):
    def test_beam_origin_is_on_nozzle_in_all_directions_and_nearby_targets(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            for _,facing in ipairs({-1,1}) do
                for _,p in ipairs({{x=1000,y=0},{x=-1000,y=0},{x=0,y=1000},
                    {x=0,y=-1000},{x=10,y=0},{x=0,y=0}}) do
                    local pose=C.toolPose({x=0,y=0},p,{x=10,y=88},facing,0)
                    local dx,dy=pose.muzzle.x-pose.tip.x,pose.muzzle.y-pose.tip.y
                    assert(math.abs(math.sqrt(dx*dx+dy*dy)-C.config.toolOffset)<1e-6)
                    assert(math.abs(dx-math.cos(pose.angle)*C.config.toolOffset)<1e-6)
                    assert(math.abs(dy-math.sin(pose.angle)*C.config.toolOffset)<1e-6)
                    assert(pose.muzzle.x==pose.muzzle.x and pose.angle==pose.angle)
                end
            end
        """)

    def test_rest_nozzle_mirrors_and_rotates_with_swimming_torso(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local p=C.toolPose({x=0,y=0},nil,{x=20,y=80},-1,math.pi/2)
            assert(math.abs(p.muzzle.x-p.tip.x)<1e-6)
            assert(math.abs(p.muzzle.y-p.tip.y+C.config.toolOffset)<1e-6)
        """)


class DescendantHoldMathTests(LuaCase):
    def test_stationary_hold_cancels_gravity_and_damps_downward_velocity(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local a=C.holdAcceleration({x=0,y=0},{x=0,y=0},{x=0,y=-9.82})
            assert(math.abs(a.y-9.82)<1e-6 and a.x==0)
            local b=C.holdAcceleration({x=0,y=0},{x=0,y=-2},{x=0,y=-9.82})
            assert(b.y>a.y)
        """)


class DescendantGripTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E={Vector2=function(x,y) return {X=x,Y=y} end,
                LuaUserData={IsTargetType=function(t,k) return t.character==true end}}
            local function body(mass)
                return {Mass=mass,Enabled=true,LinearVelocity={X=0,Y=0},
                    FarseerBody={GravityScale=1,World={Gravity={X=0,Y=-9.82}}},
                    ApplyForce=function(v) forces[#forces+1]=v end}
            end
            forces={};root=body(4);limb=body(6)
            target={character=true,WorldPosition={X=120,Y=20},IsForceRagdolled=false,IsRagdolled=false,
                AnimController={Collider=root,MainLimb={body=limb},Limbs={{body=limb},{body=limb}}}}
            owner={WorldPosition={X=0,Y=0},AnimController={Collider=body(4)}}
            suit={};state={item=suit,owner=owner,mode='grab',target={entity=target,kind='grab'}}
            charge=100
            G={authoritative=true,alive=true,now=0,states={[suit]=state},
                body=function(t) return t.AnimController and (t.AnimController.Collider.Enabled and
                    t.AnimController.Collider or t.AnimController.MainLimb.body) or t.body end,
                grabbable=function(t) return not t.Removed end,
                equipped=function(o) return o==owner and suit end,
                energy=function() return charge end,
                spend=function(i,cost) local f=math.min(charge,cost)/cost;charge=math.max(0,charge-cost);return f end}
            require('DescendantSuit.grip').install(G,E)
        """)

    def test_ragdoll_is_temporary_and_force_suspends_all_unique_enabled_bodies(self):
        self.lua.execute("""
            assert(G.hold(owner,suit,state.target,.1))
            assert(target.IsForceRagdolled and target.IsRagdolled)
            assert(#forces==2,'duplicate or missing limb forces')
            assert(forces[1].Y>root.Mass*9.82 and forces[2].Y>limb.Mass*9.82)
            G.releaseGrip(state)
            assert(not target.IsForceRagdolled and not target.IsRagdolled and not state.grip)
            G.releaseGrip(state)
        """)

    def test_preserves_preexisting_ragdoll_and_owner_transfer_releases(self):
        self.lua.execute("""
            target.IsForceRagdolled=true;target.IsRagdolled=true
            assert(G.hold(owner,suit,state.target,.1))
            G.equipped=function() return nil end;G.pruneGrips()
            assert(target.IsForceRagdolled and target.IsRagdolled and not state.grip)
        """)

    def test_disabled_collider_after_ragdoll_does_not_break_the_hold(self):
        self.lua.execute("""
            assert(G.hold(owner,suit,state.target,.1))
            root.Enabled=false;forces={}
            assert(G.hold(owner,suit,state.target,.1))
            assert(#forces==1 and target.IsForceRagdolled)
        """)

    def test_no_power_releases_without_leaving_a_character_forced_ragdolled(self):
        self.lua.execute("""
            assert(G.hold(owner,suit,state.target,.1))
            charge=0;assert(not G.hold(owner,suit,state.target,.1))
            assert(not target.IsForceRagdolled and not state.grip)
        """)

    def test_another_suit_cannot_take_an_existing_grip_or_pay_for_a_failed_attempt(self):
        self.lua.execute("""
            assert(G.hold(owner,suit,state.target,.1));local before=charge
            local other={};G.states[other]={item=other,mode='grab',target=state.target}
            assert(not G.hold(owner,other,state.target,.1))
            assert(charge==before and state.grip)
            G.clearGrips();assert(not target.IsForceRagdolled and not state.grip)
        """)

    def test_mode_change_unconsciousness_and_target_removal_release_the_grip(self):
        self.lua.execute("""
            for _,reason in ipairs({'mode','unconscious','removed'}) do
                state.mode='grab';owner.IsUnconscious=false;target.Removed=false
                assert(G.hold(owner,suit,state.target,.1))
                if reason=='mode' then state.mode='off'
                elseif reason=='unconscious' then owner.IsUnconscious=true
                else target.Removed=true end
                G.pruneGrips();assert(not state.grip)
                assert(not target.IsForceRagdolled)
            end
        """)

class DescendantHoldAnchorTests(LuaCase):
    def test_hold_anchor_is_elevated_relative_to_wearer_and_force_is_bounded(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local p=C.holdOffset({x=0,y=0},{x=-300,y=-100})
            assert(p.x<0 and p.y>=45 and math.abs(p.x)<=150)
            local a=C.holdAcceleration({x=100000,y=100000},{x=-10000,y=-10000},{x=0,y=-9.82})
            assert(a.x==a.x and a.y==a.y)
            assert(math.sqrt(a.x*a.x+a.y*a.y)<=C.config.grabAcceleration+10)
        """)


class DescendantPulseOriginTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            local mt={};mt.__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y) end
            function vec(x,y) return setmetatable({X=x,Y=y},mt) end
            E={Vector2=vec,ConvertUnits={ToSimUnits=function(v) return vec(v.X/100,v.Y/100) end},
                Timer={Wait=function(fn) launch=fn end},ItemPrefab={Prefabs={descendantpulsebolt={}}},
                Entity={Spawner={AddEntityToRemoveQueue=function(p) p.Removed=true end}}}
            cell={Condition=100,MaxCondition=100,HasTag=function() return false end}
            local Ammo=require('DescendantSuit.ammo')
            box={Condition=100,MaxCondition=100,Prefab={Identifier={Value='pulselaserammobox'}}}
            owner={Submarine={Position=vec(10000,20000)}};suit={}
            enemy={WorldPosition=vec(10500,20040)}
            target={entity=enemy,point={x=10500,y=20040},kind='combat'}
            state={mode='combat',target=target}
            projectile={Components={{Name='Projectile',Shoot=function(c,weapon,spawn,angle)
                shot={owner=c,origin=spawn,angle=angle}
            end}}}
            E.Entity.Spawner.AddItemToSpawnQueue=function(prefab,pos,sub,a,b,callback)
                spawnedAt=pos;spawnedPrefab=prefab;callback(projectile)
            end
            G={authoritative=true,alive=true,now=1,state=function() return state end,
                states={[suit]=state},ally=function() return friendly or false end,
                energy=function() return cell.Condition end,source=function() return cell end,
                ammo=function() return box,Ammo.profile(box) end,equipped=function() return suit end,
                mount=function() return {x=10000,y=20000} end,visible=function() return true end,
                toolPose=function() return {tip={x=10030,y=20040},muzzle={x=10060,y=20040}} end}
            require('DescendantSuit.pulse').install(G,E)
        """)

    def test_native_shot_uses_shared_muzzle_and_records_endpoint_for_connected_beam(self):
        self.lua.execute("""
            assert(G.firePulse(owner,suit,target));launch()
            assert(shot and math.abs(shot.origin.X-.6)<1e-6 and math.abs(shot.origin.Y-.4)<1e-6)
            assert(state.lastPulse.x==enemy.WorldPosition.X and state.lastPulse.y==enemy.WorldPosition.Y)
            assert(state.shots==1 and state.shotTime==G.now and not state.pendingPulse)
        """)

    def test_gauss_box_selects_its_projectile_and_swapping_cancels_the_shot(self):
        self.lua.execute("""
            local Ammo=require('DescendantSuit.ammo')
            local gauss={Condition=100,MaxCondition=100,Prefab={Identifier={Value='coilgunammobox'}}}
            local pulse={Condition=100,MaxCondition=100,Prefab={Identifier={Value='pulselaserammobox'}}}
            local loaded=gauss
            G.ammo=function() return loaded,Ammo.profile(loaded) end
            E.ItemPrefab.Prefabs.descendantgaussbolt={}
            assert(G.firePulse(owner,suit,target))
            assert(spawnedPrefab==E.ItemPrefab.Prefabs.descendantgaussbolt)
            loaded=pulse;launch()
            assert(not shot and projectile.Removed and gauss.Condition==100 and pulse.Condition==100 and cell.Condition==100)
        """)

    def test_async_owner_loss_cancels_projectile_without_spending_resources(self):
        self.lua.execute("""
            assert(G.firePulse(owner,suit,target));G.equipped=function() return nil end;launch()
            assert(not shot and cell.Condition==100 and box.Condition==100 and projectile.Removed)
            assert(not state.pendingPulse)
        """)

    def test_async_target_team_change_cancels_without_spending(self):
        self.lua.execute("""
            assert(G.firePulse(owner,suit,target));friendly=true;launch()
            assert(not shot and projectile.Removed and cell.Condition==100 and box.Condition==100)
        """)

    def test_async_round_clear_cancels_captured_state_without_spending(self):
        self.lua.execute("""
            assert(G.firePulse(owner,suit,target));G.states={};launch()
            assert(not shot and projectile.Removed and cell.Condition==100 and box.Condition==100)
        """)

    def test_missing_native_projectile_component_does_not_debit_power_or_ammo(self):
        self.lua.execute("""
            projectile.Components={}
            assert(G.firePulse(owner,suit,target));launch()
            assert(not shot and cell.Condition==100 and box.Condition==100 and projectile.Removed)
        """)

    def test_insufficient_power_does_not_queue_a_projectile(self):
        self.lua.execute("""
            cell.Condition=.2
            assert(not G.firePulse(owner,suit,target))
            assert(not spawnedAt and not state.pendingPulse and box.Condition==100)
        """)

    def test_player_latch_survives_time_without_holding_keys(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local s={mode='grab',target={id='g1',kind='grab'},grabStarted=0}
            assert(C.grabPress(s,true));assert(not C.grabPress(s,false))
            assert(not C.expireGrab(s,600),'player latch expired')
            assert(s.target and C.grabPress(s,true))
        """)
