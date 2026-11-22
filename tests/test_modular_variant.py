import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from lua_support import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'System-Aegis-No-Headsets'


class VariantLuaCase(unittest.TestCase):
    def setUp(self):
        self.assertTrue((MOD / 'filelist.xml').is_file(), 'No-headsets variant is missing')
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("package.path=... .. '/?.lua;' .. package.path", (MOD / 'Lua').as_posix())


class ModularShieldTests(VariantLuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            battery={Condition=100,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
            module={Condition=100,MaxCondition=100,Prefab={Identifier={Value='aegisshieldmodule'}}}
            slots={[0]=battery,[1]=module}
            gun={ID=1,Condition=100,WorldPosition={X=0,Y=0},
                OwnInventory={GetItemAt=function(n) return slots[n] end}}
            E={SERVER=true,Game={IsSingleplayer=false,ServerSettings={AllowFriendlyFire=true}},
                Character={CharacterList=setmetatable({},{__index=function() error('contact scan') end})},
                Entity={Spawner={AddItemToRemoveQueue=function() end}}}
            G=require('AegisCombat.game').new(E);G.authoritative=true
            hooks={};G.patch=function(id,c,m,fn) hooks[id]=fn end
            G.cast=function() end;G.event=function() end
            G.direction=function() return {x=1,y=0},0 end
            G.friendly=function() return false end
            require('AegisCombat.shield').install(G,E)
            s=G.state(gun);s.owner={TeamID=1}
            ctx={valid=true,aim=true,damage=true,owner=s.owner}
            function ready() G.updateShield(s,ctx,0) end
        """)

    def test_module_is_required_without_disabling_weapon_power(self):
        self.lua.execute("slots[1]=nil;ready();assert(not s.shield);assert(G.powered(gun,0))")

    def test_five_interceptions_then_sixth_projectile_passes(self):
        self.lua.execute("""
            ready()
            for _=1,5 do assert(G.blockShield(s,2,{x=80,y=0})) end
            assert(module.Condition==0 and G.shieldCharges(gun)==0)
            assert(not G.blockShield(s,2,{x=80,y=0}))
            assert(battery.Condition==90)
        """)

    def test_two_spent_charges_return_at_fifteen_and_thirty_seconds(self):
        self.lua.execute("""
            ready();G.blockShield(s,2,{});G.blockShield(s,2,{})
            assert(G.shieldCharges(gun)==3)
            G.updateShieldModule(gun,14.9);assert(G.shieldCharges(gun)==3)
            G.updateShieldModule(gun,.1);assert(G.shieldCharges(gun)==4)
            G.updateShieldModule(gun,15);assert(G.shieldCharges(gun)==5)
        """)

    def test_later_hit_preserves_recharge_progress_of_the_queue(self):
        self.lua.execute("""
            ready();G.blockShield(s,2,{})
            G.updateShieldModule(gun,10);G.blockShield(s,2,{})
            assert(G.shieldCharges(gun)==3)
            G.updateShieldModule(gun,5);assert(G.shieldCharges(gun)==4)
            G.updateShieldModule(gun,15);assert(G.shieldCharges(gun)==5)
        """)

    def test_no_recharge_without_power_or_while_module_is_removed(self):
        self.lua.execute("""
            module.Condition=60;battery.Condition=0;G.updateShieldModule(gun,60)
            assert(module.Condition==60)
            battery.Condition=100;slots[1]=nil;G.updateShieldModule(gun,60)
            assert(module.Condition==60)
            slots[1]=module;G.updateShieldModule(gun,15);assert(G.shieldCharges(gun)==4)
        """)

    def test_reinsert_or_reload_does_not_refill_or_round_up_partial_charge(self):
        self.lua.execute("""
            module.Condition=60;G.updateShieldModule(gun,7.5)
            slots[1]=nil;ready();slots[1]=module
            local second=require('AegisCombat.game').new(E);second.authoritative=true
            assert(second.shieldCharges(gun)==3)
            second.updateShieldModule(gun,7.5);assert(second.shieldCharges(gun)==4)
        """)

    def test_module_removal_before_interception_cannot_debit_or_block(self):
        self.lua.execute("""
            ready();slots[1]=nil
            assert(not G.blockShield(s,2,{}));assert(battery.Condition==100)
        """)

    def test_insufficient_battery_does_not_consume_a_module_charge(self):
        self.lua.execute("""
            ready();battery.Condition=.5
            assert(not G.blockShield(s,2,{}));assert(module.Condition==100)
        """)

    def test_empty_module_returns_after_fifteen_powered_seconds(self):
        self.lua.execute("""
            module.Condition=0;ready();assert(not s.shield)
            G.now=15;G.updateShield(s,ctx,15)
            assert(s.shield and G.shieldCharges(gun)==1)
        """)

    def test_recharge_is_server_authoritative_and_clamped_at_capacity(self):
        self.lua.execute("""
            module.Condition=60;G.authoritative=false;G.updateShieldModule(gun,100)
            assert(module.Condition==60)
            G.authoritative=true;G.updateShieldModule(gun,100);assert(module.Condition==100)
        """)

    def test_native_float_condition_recovers_each_charge_on_time(self):
        from ctypes import c_float
        self.lua.globals().native_float = lambda value: c_float(value).value
        self.lua.execute("""
            local value=60
            module=setmetatable({MaxCondition=100,Prefab={Identifier={Value='aegisshieldmodule'}}},
                {__index=function(_,key) if key=='Condition' then return value end end,
                 __newindex=function(t,key,v)
                    if key=='Condition' then value=native_float(v) else rawset(t,key,v) end
                 end})
            slots[1]=module
            for _=1,900 do G.updateShieldModule(gun,1/60) end
            assert(G.shieldCharges(gun)==4)
            for _=1,900 do G.updateShieldModule(gun,1/60) end
            assert(G.shieldCharges(gun)==5)
        """)

    def test_pause_and_broken_weapon_do_not_recharge(self):
        self.lua.execute("""
            module.Condition=60;E.Game.Paused=true;G.updateShieldModule(gun,60)
            assert(module.Condition==60)
            E.Game.Paused=false;gun.Condition=0;G.updateShieldModule(gun,60)
            assert(module.Condition==60)
        """)

    def test_shield_has_no_contact_damage_or_character_enumeration(self):
        self.lua.execute("""
            E.Character.CharacterList=function() error('shield scanned characters') end
            G.damage=function() error('shield inflicted damage') end
            ready();assert(s.shield);assert(module.Condition==100)
        """)

    def test_native_projectile_spends_exactly_one_charge(self):
        self.lua.execute("""
            ready()
            local proj={Item={WorldPosition={X=120,Y=0},body={Enabled=true}},
                IsActive=true,User={TeamID=2},FriendlyFire=true,
                Attack={GetTotalCharacterDamage=function() return 20 end}}
            hooks['projectile-launch'](proj,{})
            proj.Item.WorldPosition={X=0,Y=0}
            local p={};hooks['projectile-update'](proj,p)
            assert(p.PreventExecution and not proj.IsActive and module.Condition==80)
            hooks['projectile-update'](proj,{})
            assert(module.Condition==80)
        """)


class ModularSuitTests(VariantLuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            function part(id) return {Condition=100,MaxCondition=100,Prefab={Identifier={Value=id}}} end
            slots={[2]=part('aegisservomodule'),[3]=part('aegisimpellermodule')}
            inv={GetItemAt=function(n) return slots[n] end}
            suit={Condition=100,Prefab={Identifier={Value='aegisservosuit'}},
                Components={{Name='ItemContainer',Inventory=inv}}}
            E={Game={IsSingleplayer=true},LuaUserData={IsTargetType=function() return true end},InvSlotType={OuterClothes=1}}
            G=require('AegisSuit.game').new(E)
            s=G.state(suit)
            owner={Inventory={GetItemInLimbSlot=function() return suit end},IsUnconscious=false}
        """)

    def test_distinct_fixed_slots_and_wrong_or_broken_modules_are_rejected(self):
        self.lua.execute("""
            assert(G.hasArm(suit) and G.hasImpeller(suit))
            slots[2],slots[3]=slots[3],slots[2]
            assert(not G.hasArm(suit) and not G.hasImpeller(suit))
            slots[2]=part('aegisservomodule');slots[2].Condition=0
            assert(not G.hasArm(suit))
        """)

    def test_removing_servo_releases_grip_and_clears_pending_action(self):
        self.lua.execute("""
            s.mode='grab';s.target={kind='grab'};s.grip={};s.active=true
            local released=0;G.releaseGrip=function(state) state.grip=nil;released=released+1 end
            slots[2]=nil;G.updateModules(suit,s)
            assert(released==1 and not s.target and not s.active and s.mode=='off')
            assert(not s.hasArm and s.hasImpeller)
        """)

    def test_missing_servo_blocks_direct_arm_actions_and_mode_requests(self):
        self.lua.execute("""
            slots[2]=nil
            G.repairDevice=function() error('repair called without servo') end
            assert(not G.perform(owner,suit,{kind='repair'},.1))
            assert(not G.setMode(suit,'repair',owner))
            G.toggleSonar=function() return true end
            assert(G.setMode(suit,'sonar',owner))
        """)

    def test_impeller_module_controls_propulsion_independently_of_servo(self):
        self.lua.execute("""
            G.updateModules(suit,s);assert(s.hasArm and s.hasImpeller)
            slots[3]=nil;s.swimming=true;G.updateModules(suit,s)
            assert(s.hasArm and not s.hasImpeller and not s.swimming)
            slots[3]=part('aegisimpellermodule');slots[2]=nil;G.updateModules(suit,s)
            assert(not s.hasArm and s.hasImpeller)
        """)


class ModularVariantContentTests(unittest.TestCase):
    def manifest(self):
        self.assertTrue((MOD / 'filelist.xml').is_file())
        return ET.parse(MOD / 'filelist.xml').getroot()

    def test_variant_contains_no_custom_headset_content_or_loader(self):
        manifest=self.manifest()
        self.assertEqual(manifest.get('name'),'System Aegis')
        self.assertFalse(manifest.get('steamworkshopid'))
        self.assertFalse(any('headset' in n.get('file','').lower() for n in manifest))
        self.assertFalse((MOD / 'Lua/AegisHeadset').exists())
        self.assertFalse((MOD / 'Lua/Autorun/aegisheadsets.lua').exists())
        self.assertFalse((MOD / 'Assets/AegisHeadsets').exists())
        for path in MOD.glob('*.xml'):
            self.assertNotIn('entityname.aegisheadset',path.read_text(encoding='utf-8'))

    def test_craftable_modules_have_unique_textures_and_no_free_spawned_parts(self):
        self.manifest()
        parts=ET.parse(MOD / 'aegis_modules.xml').getroot().findall('Item')
        self.assertEqual({p.get('identifier') for p in parts},
                         {'aegisshieldmodule','aegisservomodule','aegisimpellermodule','aegiscompressormodule'})
        self.assertEqual(len({p.find('InventoryIcon').get('texture') for p in parts}),4)
        for part in parts:
            self.assertIsNotNone(part.find('Fabricate/RequiredItem'))
            self.assertIsNotNone(part.find('Holdable'))
        for name in ('aegis_combat.xml','aegis_suit.xml'):
            self.assertIsNone(ET.parse(MOD / name).find('.//ItemContainer/SpawnItem'))

    def test_module_slot_filters_follow_power_and_ammunition(self):
        self.manifest()
        gun=ET.parse(MOD / 'aegis_combat.xml').find('Item/ItemContainer')
        self.assertEqual(gun.find('SubContainer/Containable').get('items'),'aegisshieldmodule')
        for name in ('aegis_suit.xml','aegis_factions.xml'):
            for item in ET.parse(MOD / name).findall('Item'):
                if not item.get('identifier').startswith('aegisservosuit'):
                    continue
                suit=item.find('ItemContainer')
                slots=suit.findall('SubContainer')
                self.assertEqual(suit.find('Containable').get('items'),'mobilebattery')
                self.assertEqual(len(slots),5)
                for node, base in zip(slots[1:3], ('aegisservomodule','aegisimpellermodule')):
                    self.assertEqual(set(node.find('Containable').get('items').split(',')),
                                     {base+suffix for suffix in ('','descendens','coalition','separatists','husk','clowns')})
                self.assertEqual([slot.find('Containable').get('items') for slot in slots[3:]],
                                 ['aegiscompressormodule','oxygensource'])
                self.assertEqual({n.get('slotindex') for n in suit.findall('SlotIcon')},set('012345'))

    def test_original_full_package_keeps_headsets_and_previous_slots(self):
        original=ROOT / 'System-Aegis'
        self.assertTrue((original / 'aegis_headsets.xml').is_file())
        self.assertEqual(len(ET.parse(original / 'aegis_combat.xml').findall('.//SubContainer')),0)
        self.assertEqual(len(ET.parse(original / 'aegis_suit.xml').findall('.//SubContainer')),1)


import test_combat_shield_prediction as prediction
import test_aegis_sonar as sonar_tests
import test_aegis_v2 as suit_tests


class ModularClientPredictionTests(prediction.ClientShieldPredictionTests):
    mod_directory = 'System-Aegis-No-Headsets'

    def setUp(self):
        super().setUp()
        self.lua.execute('G.remote.shields[1].charges=5')

    def test_client_cannot_predict_more_blocks_than_server_charge_budget(self):
        self.lua.execute("""
            G.remote.shields[1].charges=2
            for _=1,3 do
                projectile.Item.WorldPosition=env.Vector2(120,0)
                start();collision(0,0);finish()
            end
            assert(damageCalls==1 and G.remote.shields[1].charges==0)
        """)


class ModularSuitSnapshotTests(sonar_tests.AegisSnapshotTests):
    mod_directory = 'System-Aegis-No-Headsets'

    def setUp(self):
        super().setUp()
        self.lua.execute('S.hasArm=function() return true end;S.hasImpeller=function() return false end')

    def test_installed_modules_round_trip_and_removed_arm_is_visible_to_clients(self):
        self.lua.execute("""
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            assert(C.state(suit).hasArm==true and C.state(suit).hasImpeller==false)
            S.hasArm=function() return false end;S.hasImpeller=function() return true end
            S.now=2;S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            assert(C.state(suit).hasArm==false and C.state(suit).hasImpeller==true)
        """)


class ModularNativeRepairTests(suit_tests.AegisNativeRepairTests):
    mod_directory = 'System-Aegis-No-Headsets'

    def setUp(self):
        super().setUp()
        self.lua.execute('G.hasArm=function() return true end')

    def test_removing_servo_stops_native_repair_without_waiting_for_timeout(self):
        self.lua.execute("""
            assert(G.repairDevice(owner,suit,target,.1))
            G.hasArm=function() return false end;G.pruneRepairs()
            assert(stops==1 and not repairable.CurrentFixer)
        """)


class ModularPendingShotTests(VariantLuaCase):
    def test_servo_removal_cancels_asynchronous_projectile_without_spending(self):
        self.lua.execute("""
            servo=true;state={mode='combat'};suit={};owner={};enemy={}
            target={entity=enemy};state.target=target
            local cell={Condition=100,MaxCondition=100,HasTag=function() return false end}
            local box={Condition=100,MaxCondition=100,Prefab={Identifier={Value='pulselaserammobox'}}}
            local profile=require('AegisSuit.ammo').profile(box)
            G={authoritative=true,alive=true,now=0,states={[suit]=state},
                state=function() return state end,hasArm=function() return servo end,
                ammo=function() return box,profile end,source=function() return cell end,
                toolPose=function() return {muzzle={x=0,y=0}} end}
            E={Vector2=function(x,y) return {X=x,Y=y} end,
                ItemPrefab={Prefabs={[profile.projectile]={}}},
                Entity={Spawner={AddItemToSpawnQueue=function(_,_,_,_,callback) spawned=callback end,
                    AddEntityToRemoveQueue=function(item) removed=item end}},
                Timer={Wait=function(callback) pending=callback end}}
            require('AegisSuit.pulse').install(G,E)
            assert(G.firePulse(owner,suit,target))
            servo=false;local projectile={};spawned(projectile);pending()
            assert(removed==projectile and cell.Condition==100 and box.Condition==100)
        """)
