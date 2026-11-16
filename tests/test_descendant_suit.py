from lua_support import LuaCase


class DescendantSuitTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.suit = self.lua.eval("require('DescendantSuit.core')")

    def test_breathing_switches_immediately_when_head_submerges(self):
        self.assertTrue(self.suit.breathable(self.t(hull=True, wet=False, oxygen=100, pressure=0)))
        self.assertFalse(self.suit.breathable(self.t(hull=True, wet=True, oxygen=100, pressure=0)))
        self.assertFalse(self.suit.breathable(self.t(hull=True, wet=False, oxygen=10, pressure=0)))
        self.assertFalse(self.suit.breathable(self.t(hull=False, wet=False, oxygen=100, pressure=0)))

    def test_arm_reaches_in_every_direction_and_cannot_overextend(self):
        for x, y in [(1000, 0), (-1000, 0), (0, 1000), (0, -1000), (0, 0)]:
            pose = self.suit.pose(self.t(x=0, y=0), self.t(x=x, y=y), -1)
            elbow, tip = pose['elbow'], pose['tip']
            self.assertAlmostEqual((elbow['x']**2+elbow['y']**2)**.5, 64)
            self.assertAlmostEqual(((tip['x']-elbow['x'])**2+(tip['y']-elbow['y'])**2)**.5, 56)
            self.assertLessEqual((tip['x']**2+tip['y']**2)**.5, 120.00001)

    def test_one_mode_releases_the_previous_grab(self):
        self.lua.execute("s={mode='grab',target={id=1}};assert(require('DescendantSuit.core').setMode(s,'repair'));assert(s.target==nil and s.mode=='repair');assert(not require('DescendantSuit.core').setMode(s,'repair+combat'))")

    def test_wall_and_device_share_repair_mode_but_only_one_target(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local wall={id=1,kind='weld',distance=90,visible=true,damaged=true,emergency=true}
            local device={id=2,kind='repair',distance=60,visible=true,damaged=true}
            assert(C.choose('repair',{wall,device}).id==1)
            assert(C.choose('repair',{wall,device},2).id==2)
            device.visible=false
            assert(C.choose('repair',{wall,device},2).id==1)
            wall.distance=151
            assert(C.choose('repair',{wall,device})==nil)
        """)

    def test_ai_chooses_a_single_function_and_can_rescue_crew(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local enemy={id=3,kind='combat',distance=200,visible=true,hostile=true,alive=true}
            local wall={id=1,kind='weld',distance=90,visible=true,damaged=true,emergency=true}
            local device={id=2,kind='repair',distance=60,visible=true,damaged=true}
            local rescue={id=4,kind='grab',distance=100,visible=true,rescue=true,free=true}
            local mode,target=C.ai({enemy,wall,device,rescue})
            assert(mode=='combat' and target==enemy)
            mode,target=C.ai({wall,device,rescue});assert(mode=='repair' and target==wall)
            mode,target=C.ai({rescue});assert(mode=='grab' and target==rescue)
        """)

    def test_blocked_allied_dead_and_contained_targets_are_excluded(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
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
            local C=require('DescendantSuit.core')
            local s={mode='grab',target={id='g1'},grabStarted=0}
            assert(C.grabPress(s,true));assert(not C.grabPress(s,true))
            assert(C.expireGrab(s,6));assert(s.target==nil and s.grabStarted==nil)
            assert(not C.grabAllowed(s,'g1',6.5));assert(C.grabAllowed(s,'g1',8.1))
            assert(C.grabAllowed(s,'g2',6.5))
            assert(not C.grabPress(s,false));assert(C.grabPress(s,true))
        """)

    def test_grab_uses_network_aim_direction_instead_of_reconstructed_cursor_distance(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
            local t={id='g1',kind='grab',distance=230,point={x=230,y=10},free=true,visible=true}
            assert(C.aimGrab({x=0,y=10},{x=500,y=10},{t})==t)
            assert(C.aimGrab({x=0,y=10},{x=230,y=10},{t})==t)
        """)

    def test_grab_ray_rejects_occluded_behind_out_of_range_and_off_axis_targets(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core')
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
            local C=require('DescendantSuit.core')
            local near={id=1,kind='grab',distance=100,point={x=100,y=0},free=true,visible=true}
            local far={id=2,kind='grab',distance=200,point={x=200,y=0},free=true,visible=true}
            assert(C.aimGrab({x=0,y=0},{x=500,y=0},{far,near})==near)
            near.visible=false
            assert(C.aimGrab({x=0,y=0},{x=500,y=0},{far,near})==far)
        """)

    def test_beam_waits_for_the_arm_to_approach_a_new_target(self):
        self.lua.execute("""
            local C=require('DescendantSuit.core');local s={}
            assert(not C.ready(s,'a',0));assert(not C.ready(s,'a',.2));assert(C.ready(s,'a',.3))
            assert(not C.ready(s,'b',.3));assert(not C.ready(s,nil,.4));assert(not C.ready(s,'a',.5))
        """)


class DescendantAdapterTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E={SERVER=true,Game={IsSingleplayer=false},InvSlotType={OuterClothes=9}}
            E.Vector2=function(x,y) return {X=x,Y=y} end
            E.LuaUserData={IsTargetType=function(v,t) return v.isCharacter==true end}
            battery={Condition=50,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            tank={Condition=80,MaxCondition=100,HasTag=function(t) return t=='oxygensource' end}
            suit={Condition=100,Prefab={Identifier={Value='descendantservosuit'}},Components={
                {Name='ItemContainer',Inventory={GetItemAt=function() return tank end}},
                {Name='ItemContainer',Inventory={GetItemAt=function() return battery end}}}}
            wearer={isCharacter=true,NeedsAir=true,Inventory={GetItemInLimbSlot=function() return suit end},
                AnimController={HeadInWater=false,CurrentHull={OxygenPercentage=100,LethalPressure=0}}}
            suit.ParentInventory={Owner=wearer}
            G=require('DescendantSuit.game').new(E)
        """)

    def test_only_worn_suit_can_authorize_an_action(self):
        self.lua.execute("assert(G.equipped(wearer)==suit);suit.Condition=0;assert(G.equipped(wearer)==nil)")

    def test_paused_singleplayer_does_not_advance_suit_simulation(self):
        self.lua.execute("E.Game.Paused=true;G.now=5;G.update(.1);assert(G.now==5 and battery.Condition==50)")

    def test_mount_rotates_with_the_torso_when_swimming(self):
        self.lua.execute("""
            E.LimbType={Torso=1};wearer.WorldPosition={X=1000,Y=2000}
            local torso={WorldPosition={X=10,Y=20},body={Rotation=math.pi/2,Dir=1}}
            wearer.AnimController.GetLimb=function(kind) assert(kind==1);return torso end
            local p=G.mount(wearer)
            assert(math.abs(p.x)<.00001 and math.abs(p.y-2)<.00001)
            torso.body.Dir=-1;p=G.mount(wearer)
            assert(math.abs(p.x)<.00001 and math.abs(p.y-38)<.00001)
        """)

    def test_visible_mount_uses_interpolated_torso_position_and_rotation(self):
        self.lua.execute("""
            E.LimbType={Torso=1};wearer.WorldPosition={X=1000,Y=2000}
            local updated=false
            local torso={WorldPosition={X=10,Y=20},body={Rotation=0,DrawRotation=math.pi/2,Dir=1,
                DrawPosition={X=50,Y=60},UpdateDrawPosition=function() updated=true end}}
            wearer.AnimController.GetLimb=function() return torso end
            local p=G.mount(wearer,true)
            assert(updated and math.abs(p.x-40)<.00001 and math.abs(p.y-42)<.00001)
        """)

    def test_air_does_not_drain_tank_and_water_resumes_consumption(self):
        self.lua.execute("""
            G.breathe(wearer,suit,.1);assert(tank.Condition==80 and wearer.UseHullOxygen and G.state(suit).open)
            wearer.AnimController.HeadInWater=true
            G.breathe(wearer,suit,.1)
            assert(tank.Condition<80 and not wearer.UseHullOxygen and not G.state(suit).open)
            assert(wearer.OxygenAvailable>0)
            tank.Condition=0;G.breathe(wearer,suit,.1);assert(wearer.OxygenAvailable==0)
        """)

    def test_client_supplies_breathing_properties_without_consuming_tank(self):
        self.lua.execute("""
            G.authoritative=false;wearer.AnimController.HeadInWater=true
            G.breathe(wearer,suit,.1)
            assert(wearer.OxygenAvailable>0 and not wearer.UseHullOxygen and tank.Condition==80)
        """)

    def test_underwater_breathing_does_not_read_nonexistent_character_properties(self):
        self.lua.execute("""
            setmetatable(wearer,{__index=function(_,key)
                if key=='DecreasedOxygenConsumption' then error('not a Character property') end
            end})
            wearer.AnimController.HeadInWater=true
            G.breathe(wearer,suit,.1)
            assert(math.abs(tank.Condition-79.97)<.00001)
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
            local item={AllowedSlots={'RightHand'},Components={pick},body={Enabled=true}}
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
