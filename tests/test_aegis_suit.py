from lua_support import LuaCase


class AegisSuitTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.suit = self.lua.eval("require('AegisSuit.core')")

    def test_breathing_switches_immediately_when_head_submerges(self):
        self.assertTrue(self.suit.breathable(self.t(hull=True, wet=False, oxygen=100, pressure=0)))
        self.assertFalse(self.suit.breathable(self.t(hull=True, wet=True, oxygen=100, pressure=0)))
        self.assertFalse(self.suit.breathable(self.t(hull=True, wet=False, oxygen=10, pressure=0)))
        self.assertFalse(self.suit.breathable(self.t(hull=False, wet=False, oxygen=100, pressure=0)))

    def test_arm_reaches_in_every_direction_and_cannot_overextend(self):
        for x, y in [(1000, 0), (-1000, 0), (0, 1000), (0, -1000), (0, 0)]:
            pose = self.suit.pose(self.t(x=0, y=0), self.t(x=x, y=y), -1)
            elbow, tip = pose['elbow'], pose['tip']
            self.assertAlmostEqual((elbow['x']**2+elbow['y']**2)**.5, 76)
            self.assertAlmostEqual(((tip['x']-elbow['x'])**2+(tip['y']-elbow['y'])**2)**.5, 66)
            self.assertLessEqual((tip['x']**2+tip['y']**2)**.5, 118.00001)

    def test_one_mode_releases_the_previous_grab(self):
        self.lua.execute("s={mode='grab',target={id=1}};assert(require('AegisSuit.core').setMode(s,'repair'));assert(s.target==nil and s.mode=='repair');assert(not require('AegisSuit.core').setMode(s,'repair+combat'))")

    def test_wall_and_device_share_repair_mode_but_only_one_target(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            local wall={id=1,kind='weld',distance=90,visible=true,damaged=true,emergency=true}
            local device={id=2,kind='repair',distance=60,visible=true,damaged=true}
            assert(C.choose('repair',{wall,device}).id==1)
            assert(C.choose('repair',{wall,device},2).id==2)
            device.visible=false
            assert(C.choose('repair',{wall,device},2).id==1)
            wall.distance=C.repairRange()+1
            assert(C.choose('repair',{wall,device})==nil)
        """)

    def test_ai_chooses_combat_or_repair_without_grabbing_crew(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            local enemy={id=3,kind='combat',distance=200,visible=true,hostile=true,alive=true}
            local wall={id=1,kind='weld',distance=90,visible=true,damaged=true,emergency=true}
            local device={id=2,kind='repair',distance=60,visible=true,damaged=true}
            local rescue={id=4,kind='grab',distance=100,visible=true,rescue=true,free=true}
            local mode,target=C.ai({enemy,wall,device,rescue})
            assert(mode=='combat' and target==enemy)
            mode,target=C.ai({wall,device,rescue});assert(mode=='repair' and target==wall)
            mode,target=C.ai({rescue});assert(mode=='off' and target==nil,'AI grabbed an unconscious crewmate')
            assert(C.choose('grab',{rescue},rescue.id)==rescue,'manual grab is unavailable')
        """)

    def test_blocked_allied_dead_and_contained_targets_are_excluded(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            assert(not C.choose('combat',{{id=1,kind='combat',distance=20,visible=true,hostile=false,alive=true}}))
            assert(not C.choose('combat',{{id=1,kind='combat',distance=20,visible=true,hostile=true,alive=false}}))
            assert(not C.choose('repair',{{id=1,kind='repair',distance=20,visible=false,damaged=true}}))
            assert(not C.choose('grab',{{id=1,kind='grab',distance=20,visible=true,free=false}},1))
        """)

    def test_empty_source_does_not_pay_and_small_remainder_is_proportional(self):
        charge, fraction = self.suit.debit(0, 1)
        self.assertEqual((charge, fraction), (0, 0))
        charge, fraction = self.suit.debit(.1, .4)
        self.assertAlmostEqual(charge, 0)
        self.assertAlmostEqual(fraction, .25)
        charge, fraction = self.suit.debit(50, 0)
        self.assertEqual((charge, fraction), (50, 1))

    def test_batteries_and_rods_are_normalized_but_oxygen_is_not_power(self):
        self.assertEqual(self.suit.charge(25, 50, True), 50)
        self.assertEqual(self.suit.charge(50, 100, False), 0)
        self.assertEqual(self.suit.charge(50, 0, True), 0)

    def test_grab_has_a_cooldown_and_held_input_is_not_a_new_press(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            local s={mode='grab',target={id='g1'},grabStarted=0,grabAutomatic=true}
            assert(C.grabPress(s,true));assert(not C.grabPress(s,true))
            assert(C.expireGrab(s,6));assert(s.target==nil and s.grabStarted==nil)
            assert(not C.grabAllowed(s,'g1',6.5));assert(C.grabAllowed(s,'g1',8.1))
            assert(C.grabAllowed(s,'g2',6.5))
            assert(not C.grabPress(s,false));assert(C.grabPress(s,true))
        """)

    def test_grab_uses_network_aim_direction_instead_of_reconstructed_cursor_distance(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            local t={id='g1',kind='grab',distance=230,point={x=230,y=10},free=true,visible=true}
            assert(C.aimGrab({x=0,y=10},{x=500,y=10},{t})==t)
            assert(C.aimGrab({x=0,y=10},{x=230,y=10},{t})==t)
        """)

    def test_grab_ray_rejects_occluded_behind_out_of_range_and_off_axis_targets(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            local t={id='g1',kind='grab',distance=230,point={x=230,y=0},free=true,visible=true}
            local function pick() return C.aimGrab({x=0,y=0},{x=500,y=0},{t}) end
            t.visible=false;assert(not pick());t.visible=true
            t.free=false;assert(not pick());t.free=true
            t.distance=301;assert(not pick());t.distance=230
            t.point.x=-230;assert(not pick());t.point.x=230
            t.point.y=41;assert(not pick());t.point.y=0
            assert(not C.aimGrab({x=0,y=0},{x=0,y=0},{t}))
        """)

    def test_grab_ray_selects_only_the_first_visible_target(self):
        self.lua.execute("""
            local C=require('AegisSuit.core')
            local near={id=1,kind='grab',distance=100,point={x=100,y=0},free=true,visible=true}
            local far={id=2,kind='grab',distance=200,point={x=200,y=0},free=true,visible=true}
            assert(C.aimGrab({x=0,y=0},{x=500,y=0},{far,near})==near)
            near.visible=false
            assert(C.aimGrab({x=0,y=0},{x=500,y=0},{far,near})==far)
        """)

    def test_beam_waits_for_the_arm_to_approach_a_new_target(self):
        self.lua.execute("""
            local C=require('AegisSuit.core');local s={}
            assert(not C.ready(s,'a',0));assert(not C.ready(s,'a',.05));assert(C.ready(s,'a',.2))
            assert(not C.ready(s,'b',.3));assert(not C.ready(s,nil,.4));assert(not C.ready(s,'a',.5))
        """)


class AegisAdapterTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E={SERVER=true,Game={IsSingleplayer=false},InvSlotType={OuterClothes=9}}
            E.Vector2=function(x,y) return {X=x,Y=y} end
            E.LuaUserData={IsTargetType=function(v,t) return v.isCharacter==true end}
            E.LuaUserData.CreateEnumTable=function(name)
                assert(name=='FarseerPhysics.BodyType');return {Dynamic=2,Kinematic=1,Static=0}
            end
            battery={Condition=50,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            tank={Condition=80,MaxCondition=100,HasTag=function(t) return t=='oxygensource' end}
            ammo={Condition=100,MaxCondition=100,HasTag=function(t) return t=='pulselaserammo' end}
            suit={Condition=100,Prefab={Identifier={Value='aegisservosuit'}},Components={
                {Name='ItemContainer',Inventory={GetItemAt=function(n) if n==0 then return battery else return ammo end end}}}}
            wearer={isCharacter=true,NeedsAir=true,Inventory={GetItemInLimbSlot=function() return suit end},
                AnimController={HeadInWater=false,CurrentHull={OxygenPercentage=100,LethalPressure=0}}}
            suit.ParentInventory={Owner=wearer}
            G=require('AegisSuit.game').new(E)
        """)

    def test_only_worn_suit_can_authorize_an_action(self):
        self.lua.execute("assert(G.equipped(wearer)==suit);suit.Condition=0;assert(G.equipped(wearer)==nil)")

    def test_paused_singleplayer_does_not_advance_suit_simulation(self):
        self.lua.execute("E.Game.Paused=true;G.now=5;G.update(.1);assert(G.now==5 and battery.Condition==50)")

    def test_bot_scans_for_threats_without_grabbing_characters(self):
        self.lua.execute("""
            local crew={ID=1,isCharacter=true,Mass=70,IsUnconscious=true,WorldPosition={X=40,Y=0},
                AnimController={Collider={Mass=70,Enabled=true,BodyType=2}}}
            local enemy={ID=2,isCharacter=true,Mass=70,WorldPosition={X=80,Y=0},
                AnimController={Collider={Mass=70,Enabled=true,BodyType=2}}}
            E.Character={CharacterList={wearer,crew,enemy}}
            E.Structure={WallList={}};E.Item={ItemList={}}
            E.Util={GetItemGroup=function() return {} end}
            G.mount=function() return {x=0,y=0} end
            G.ally=function(a,b) return b==crew end
            G.visible=function() return true end
            G.visibleFromTool=function() return true end
            local s=G.state(suit)
            wearer.IsBot=true
            for _,mode in ipairs({'off','grab'}) do
                s.mode=mode
                local targets=G.gather(wearer,s)
                assert(#targets==1 and targets[1].kind=='combat' and targets[1].entity==enemy,
                    'bot considered a character for automatic grabbing')
            end
            wearer.IsBot=false;s.mode='grab'
            local targets=G.gather(wearer,s)
            assert(#targets==2 and targets[1].entity==crew and targets[2].entity==enemy)
            assert(targets[1].kind=='grab' and targets[2].kind=='grab','player cannot grab characters')
        """)

    def test_temporary_occlusion_does_not_switch_to_another_device_during_grace(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;G.nextOwners=1
            wearer.WorldPosition={X=0,Y=0};wearer.IsKeyDown=function() return false end
            local first={Condition=10,MaxCondition=100,WorldPosition={X=40,Y=0}}
            local second={Condition=10,MaxCondition=100,WorldPosition={X=50,Y=0}}
            local old={id='i1',kind='repair',entity=first,point={x=40,y=0},damaged=true,distance=40,visible=true}
            local alternative={id='i2',kind='repair',entity=second,point={x=50,y=0},damaged=true,distance=50,visible=true}
            local s=G.state(suit);s.mode='repair';s.target=old;s.contactId=old.id;s.contactAt=0
            G.gather=function() return {alternative} end;G.visible=function() return false end
            G.update(.1)
            assert(s.target and s.target.id=='i1' and not s.active,'brief occlusion switched devices')
        """)

    def test_turning_the_arm_does_not_put_an_established_grip_out_of_range(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;E.InputType={Aim=1,Use=2};G.nextOwners=1
            wearer.WorldPosition={X=0,Y=0};wearer.IsKeyDown=function() return false end
            G.mount=function() return {x=-22,y=18} end
            G.cast=function() end
            G.perform=function() return true end
            local prop={WorldPosition={X=370,Y=0},body={Enabled=true,BodyType=2,Mass=10}}
            local s=G.state(suit);s.mode='grab';s.grip={}
            s.target={id='g1',kind='grab',entity=prop};s.actionId='g1';s.readyAt=0
            G.update(.1)
            assert(s.target and s.active,'arm rotation dropped an in-range held target')
        """)

    def test_aiming_again_while_use_stays_held_does_not_release_the_grip(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;E.InputType={Aim=1,Use=2};G.nextOwners=1
            local aim,use=true,true
            wearer.WorldPosition={X=0,Y=0}
            wearer.IsKeyDown=function(key) if key==1 then return aim end;return use end
            G.cast=function() end
            G.perform=function() return true end
            local prop={WorldPosition={X=100,Y=0},body={Enabled=true,BodyType=2,Mass=10}}
            local s=G.state(suit);s.mode='grab';s.grip={};s.grabHeld=true
            s.target={id='g1',kind='grab',entity=prop};s.actionId='g1';s.readyAt=0
            aim=false;G.update(.1)
            aim=true;G.update(.1)
            assert(s.target and s.active,'resuming aim was counted as a new Use press')
            use=false;G.update(.1)
            use=true;G.update(.1)
            assert(not s.target,'a new Use press while aiming should release the target')
        """)

    def test_manual_grab_can_start_on_a_visible_limb_of_a_large_enemy(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;E.InputType={Aim=1,Use=2};G.nextOwners=1
            wearer.WorldPosition={X=0,Y=0};wearer.AimRefPosition=wearer.WorldPosition
            wearer.CursorWorldPosition={X=200,Y=0};wearer.IsKeyDown=function() return true end
            local body={Enabled=true,Mass=400,BodyType=2}
            local limb={WorldPosition={X=200,Y=0},body=body}
            local enemy={ID=1,isCharacter=true,IsDead=true,Mass=1000,WorldPosition={X=420,Y=100},
                AnimController={Collider={Enabled=false},MainLimb=limb,Limbs={limb}}}
            E.Character={CharacterList={wearer,enemy}};E.Item={ItemList={}}
            G.cast=function(a,b) if b.y>50 then return {kind='wall'} end end
            G.hold=function(_,_,target) return target.entity==enemy end
            local s=G.state(suit);s.mode='grab'
            G.update(1/60)
            assert(s.active and s.target.entity==enemy,'aiming at the exposed limb did not start the grip')
        """)

    def test_held_creature_stays_in_range_after_aimed_limb_swings_away(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;E.InputType={Aim=1,Use=2};G.nextOwners=1
            wearer.WorldPosition={X=0,Y=0};wearer.IsKeyDown=function() return false end
            local body={Enabled=true,Mass=200,BodyType=2}
            local grabbed={WorldPosition={X=410,Y=0},body=body}
            local nearby={WorldPosition={X=295,Y=0},body=body}
            local creature={isCharacter=true,WorldPosition={X=450,Y=0},
                AnimController={Collider=body,Limbs={grabbed,nearby}}}
            local s=G.state(suit);s.mode='grab';s.grip={}
            s.target={id='g1',kind='grab',entity=creature,limb=grabbed}
            G.hold=function() return true end
            G.update(1/60)
            assert(s.active and s.target.entity==creature,'held creature was dropped while a limb was in range')
            nearby.IsSevered=true;G.update(1/60)
            assert(not s.active and not s.target,'a severed limb incorrectly extended the grip range')
        """)

    def test_removed_repair_target_is_replaced_by_a_visible_device(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;G.nextOwners=1
            wearer.WorldPosition={X=0,Y=0};wearer.IsKeyDown=function() return false end
            local removed={Removed=true,WorldPosition={X=40,Y=0}}
            local device={Condition=10,MaxCondition=100,WorldPosition={X=50,Y=0}}
            local alternative={id='i2',kind='repair',entity=device,point={x=50,y=0},damaged=true,distance=50,visible=true}
            local s=G.state(suit);s.mode='repair';s.target={id='i1',kind='repair',entity=removed}
            G.gather=function() return {alternative} end;G.visible=function() return true end
            G.update(.1)
            assert(s.target and s.target.id=='i2','removed target blocked reacquisition')
        """)

    def test_discovery_preserves_old_owner_until_transfer_cleanup_runs(self):
        self.lua.execute("""
            E.Game.RoundStarted=true;wearer.WorldPosition={X=0,Y=0}
            local nextOwner={isCharacter=true,WorldPosition={X=0,Y=0},AnimController=wearer.AnimController,
                Inventory={GetItemInLimbSlot=function() return suit end},IsKeyDown=function() return false end}
            local s=G.state(suit);s.owner=wearer;s.mode='off';s.sonar=true
            suit.ParentInventory.Owner=nextOwner
            E.Util={GetItemsById=function() return {suit} end}
            local cancelled,released=false,false
            G.cancelSupplies=function() cancelled=true end;G.releaseGrip=function() released=true end
            G.update(.1)
            assert(cancelled and released and s.owner==nextOwner and not s.sonar,'discovery bypassed transfer cleanup')
        """)

    def test_mount_rotates_with_the_torso_when_swimming(self):
        self.lua.execute("""
            E.LimbType={Torso=1};wearer.WorldPosition={X=1000,Y=2000}
            local torso={WorldPosition={X=10,Y=20},body={Rotation=math.pi/2,Dir=1}}
            wearer.AnimController.GetLimb=function(kind) assert(kind==1);return torso end
            local p=G.mount(wearer)
            assert(math.abs(p.x+8)<.00001 and math.abs(p.y+2)<.00001)
            torso.body.Dir=-1;p=G.mount(wearer)
            assert(math.abs(p.x+8)<.00001 and math.abs(p.y-42)<.00001)
        """)

    def test_visible_mount_uses_interpolated_torso_position_and_rotation(self):
        self.lua.execute("""
            E.LimbType={Torso=1};wearer.WorldPosition={X=1000,Y=2000}
            local updated=false
            local torso={WorldPosition={X=10,Y=20},body={Rotation=0,DrawRotation=math.pi/2,Dir=1,
                DrawPosition={X=50,Y=60},UpdateDrawPosition=function() updated=true end}}
            wearer.AnimController.GetLimb=function() return torso end
            local p=G.mount(wearer,true)
            assert(updated and math.abs(p.x-32)<.00001 and math.abs(p.y-38)<.00001)
        """)

    def test_safe_air_is_free_and_closed_loop_breathing_uses_power_without_a_tank(self):
        self.lua.execute("""
            G.breathe(wearer,suit,.1);assert(tank.Condition==80 and wearer.UseHullOxygen and G.state(suit).open)
            wearer.AnimController.HeadInWater=true
            G.breathe(wearer,suit,.1)
            assert(tank.Condition==80 and battery.Condition<50 and not wearer.UseHullOxygen and not G.state(suit).open)
            assert(wearer.OxygenAvailable>0)
            battery.Condition=0;G.breathe(wearer,suit,.1);assert(wearer.OxygenAvailable==0)
        """)

    def test_client_supplies_breathing_properties_without_duplicating_power_debit(self):
        self.lua.execute("""
            G.authoritative=false;wearer.AnimController.HeadInWater=true
            G.breathe(wearer,suit,.1)
            assert(wearer.OxygenAvailable>0 and not wearer.UseHullOxygen and battery.Condition==50)
        """)

    def test_underwater_breathing_does_not_read_nonexistent_character_properties(self):
        self.lua.execute("""
            setmetatable(wearer,{__index=function(_,key)
                if key=='DecreasedOxygenConsumption' then error('not a Character property') end
            end})
            wearer.AnimController.HeadInWater=true
            G.breathe(wearer,suit,.1)
            assert(battery.Condition<50 and tank.Condition==80)
        """)

    def test_welding_uses_the_selected_wall_surface_and_rejects_another_wall(self):
        self.lua.execute("""
            local wall={FindSectionIndex=function(p) assert(p.X>60 and p.X<100);return 0 end}
            local target={kind='weld',entity=wall,section=0,point={x=100,y=0}}
            G.cast=function() return {kind='wall',blocker=wall,x=60,y=0} end
            assert(G.visible(wearer,{x=0,y=0},target));assert(target.point.x==60)
            G.cast=function() return {kind='wall',blocker={},x=60,y=0} end
            assert(not G.visible(wearer,{x=0,y=0},target))
        """)

    def test_welding_cannot_repair_a_far_section_behind_another_section_of_same_wall(self):
        self.lua.execute("""
            local wall={FindSectionIndex=function() return 0 end}
            local target={kind='weld',entity=wall,section=3,point={x=300,y=0}}
            G.cast=function() return {kind='wall',blocker=wall,x=60,y=0} end
            assert(not G.visible(wearer,{x=0,y=0},target))
        """)

    def test_oxygen_tank_never_supplies_arm_power(self):
        self.lua.execute("battery.HasTag=function(t) return t=='oxygensource' end;assert(G.energy(suit)==0);assert(G.spend(suit,.5)==0);assert(battery.Condition==50)")

    def test_rod_and_battery_both_pay_for_real_repairs(self):
        self.lua.execute("""
            local device={Condition=10,MaxCondition=100}
            local target={kind='repair',entity=device}
            G.repairDevice=function(owner,item,t,dt)
                local fraction=G.spend(item,.4*dt)
                if fraction==0 then return false end
                t.entity.Condition=t.entity.Condition+dt*fraction
                return true
            end
            assert(G.perform(wearer,suit,target,.1))
            assert(device.Condition>10 and battery.Condition<50)
            battery.HasTag=function(t) return t=='reactorfuel' end
            local before=battery.Condition
            assert(G.perform(wearer,suit,target,.1));assert(battery.Condition<before)
            battery.Condition=0;local health=device.Condition
            assert(not G.perform(wearer,suit,target,.1));assert(device.Condition==health)
        """)

    def test_welding_repairs_only_the_selected_section(self):
        self.lua.execute("""
            local wall={damage={20,40},AddDamage=function(index,amount) wallResult={index,amount} end}
            assert(G.perform(wearer,suit,{kind='weld',entity=wall,section=1},.1))
            assert(wallResult[1]==1 and wallResult[2]<0)
        """)

    def test_grab_accepts_pickable_tools_but_not_attached_or_wired_items(self):
        self.lua.execute("""
            E.LuaUserData.IsTargetType=function(v,t)
                if t=='Barotrauma.Items.Components.Pickable' then return v.pickable==true end
                return v.isCharacter==true
            end
            local pick={Name='MeleeWeapon',pickable=true,CanBePicked=true,PickingTime=0}
            local item={AllowedSlots={'RightHand'},Components={pick},body={Enabled=true,BodyType=2,Mass=5}}
            assert(G.portable(item))
            pick.IsAttached=true;assert(not G.portable(item));pick.IsAttached=false
            item.Components[2]={Name='Wire',Connections={[2]={}},GetNodes=function() return {} end}
            assert(not G.portable(item))
        """)

    def test_unconscious_target_is_pulled_by_an_active_ragdoll_body(self):
        self.lua.execute("""
            local torso={Enabled=true,Mass=10}
            local patient={isCharacter=true,AnimController={Collider={Enabled=false},MainLimb={body=torso}}}
            assert(G.body(patient)==torso)
        """)

    def test_grab_accepts_loose_dynamic_props_without_pickable_or_inventory_slots(self):
        self.lua.execute("""
            local prop={Components={},AllowedSlots={'None'},body={Enabled=true,BodyType=2,Mass=12}}
            assert(G.portable(prop))
            assert(G.grabbable(prop))
            prop.ParentInventory={};assert(not G.grabbable(prop))
        """)

    def test_grab_rejects_static_kinematic_and_disabled_world_objects(self):
        self.lua.execute("""
            E.LuaUserData.IsTargetType=function(v,t) return v.pickable==true end
            local pick={Name='Holdable',pickable=true,CanBePicked=true,PickingTime=0}
            local prop={AllowedSlots={'RightHand'},Components={pick},body={Enabled=true,BodyType=0,Mass=12}}
            assert(not G.portable(prop))
            prop.body.BodyType=1;assert(not G.portable(prop))
            prop.body.BodyType=2;assert(G.portable(prop))
            prop.body.Enabled=false;assert(not G.portable(prop))
        """)

    def test_grab_accepts_living_or_dead_creatures_above_the_item_mass_limit(self):
        self.lua.execute("""
            local body={Enabled=true,BodyType=2,Mass=4}
            local creature={isCharacter=true,Mass=40,AnimController={Collider=body}}
            assert(G.grabbable(creature))
            creature.Mass=500;assert(G.grabbable(creature))
            creature.IsDead=true;assert(G.grabbable(creature))
            creature.Removed=true;assert(not G.grabbable(creature))
        """)

    def test_grab_rejects_heavy_massless_and_nonphysical_items(self):
        self.lua.execute("""
            local prop={Components={},body={Enabled=true,BodyType=2,Mass=81}}
            assert(not G.grabbable(prop))
            prop.body.Mass=80;assert(G.grabbable(prop))
            prop.body.Mass=0;assert(not G.grabbable(prop))
            prop.body.Mass=0/0;assert(not G.grabbable(prop))
        """)

    def test_retained_creature_without_a_movable_body_is_rejected_before_charging_power(self):
        self.lua.execute("""
            local creature={isCharacter=true,Mass=500,AnimController={Collider={Enabled=true,Mass=4,BodyType=0}}}
            local before=battery.Condition
            assert(not G.perform(wearer,suit,{kind='grab',entity=creature,point={x=20,y=20}},.1))
            assert(battery.Condition==before)
        """)
