from test_headset_adapter import HeadsetAdapterTests
import unittest


def load_tests(loader, tests, pattern):
    return loader.loadTestsFromNames([
        __name__+'.MedicalOriginsTests.'+name for name in MedicalOriginsTests.__dict__ if name.startswith('test_')
    ])


class MedicalOriginsTests(HeadsetAdapterTests):
    def setUp(self):
        super().setUp()
        self.lua.execute("item.Prefab.Identifier.Value='aegisheadsetmk2'")

    def test_unused_origin_expires_before_a_later_frame(self):
        self.lua.execute('''
            local a=add('burn',20,false)
            G.effectOrigin(char,char,a);G.update(.01)
            assert(G.absorb(char,{a},0,1).empty and battery.Condition==90)
        ''')

    def test_own_medical_consequences_are_not_shield_hits(self):
        self.lua.execute('''
            local a=add('fracturedextremity',100,false)
            G.effectOrigin(char,char,a)
            assert(G.absorb(char,{a},0,1)==nil)
            assert(battery.Condition==100 and not G.state(item).debits)
        ''')

    def test_one_own_effect_can_apply_to_multiple_limbs_without_shield_cost(self):
        self.lua.execute('''
            local a=add('arterialcut',100,false)
            G.effectOrigin(char,char,a)
            for i=1,6 do assert(G.absorb(char,{a},0,1)==nil) end
            assert(battery.Condition==100)
        ''')

    def test_external_and_unattributed_attacks_still_cost_power(self):
        self.lua.execute('''
            local a=add('burn',20,false)
            G.effectOrigin({},char,a)
            assert(G.absorb(char,{a},0,1).empty and battery.Condition==90)
            battery.Condition=100
            assert(G.absorb(char,{a},0,1).empty and battery.Condition==90)
        ''')

    def test_mixed_hit_preserves_internal_effect_and_blocks_external_wound(self):
        self.lua.execute('''
            local injury=add('arterialcut',100,false)
            local bullet=add('gunshotwound',20,false)
            G.effectOrigin(char,char,injury)
            local result=G.absorb(char,{injury,bullet},0,1)
            assert(battery.Condition==90 and not result.empty)
            assert(#result.afflictions==1 and result.afflictions[1]==injury)
        ''')

    def test_reused_status_affliction_does_not_leak_internal_origin(self):
        self.lua.execute('''
            local a=add('burn',20,false)
            G.effectOrigin(char,char,a);G.effectOrigin({},char,a)
            assert(G.absorb(char,{a},0,1).empty and battery.Condition==90)
        ''')

    def test_mk2_heals_four_times_faster_with_same_unit_price(self):
        self.lua.execute('''
            local a=add('unknown_disease',30,false)
            item.Prefab.Identifier.Value='aegisheadset';G.heal(char,item,1)
            assert(a.Strength==25 and battery.Condition==99.375)
            a.Strength=30;battery.Condition=100;item.Prefab.Identifier.Value='aegisheadsetmk2'
            G.heal(char,item,1)
            assert(a.Strength==10 and battery.Condition==97.5)
        ''')

    def test_mk2_cures_multiple_mod_effects_with_same_total_energy_cost(self):
        self.lua.execute('''
            local unknown=add('unknown_mod_disease',100,false)
            local artery=add('arterialcut',100,false)
            for i=1,9 do G.heal(char,item,1) end
            assert(math.abs(unknown.Strength+artery.Strength-20)<.0001)
            G.heal(char,item,1)
            assert(unknown.Strength<.0001 and artery.Strength<.0001)
            assert(math.abs(battery.Condition-75)<.0001)
            G.heal(char,item,1)
            assert(math.abs(battery.Condition-75)<.0001,'healed wearer must be idle')
        ''')

    def test_mk2_limb_job_is_faster_without_changing_total_price(self):
        self.lua.execute('''
            E.NT={};local a=add('tll_amputation',1,true)
            item.Prefab.Identifier.Value='aegisheadsetmk2'
            for i=1,6 do G.heal(char,item,1);assert(a.Strength==1) end
            G.heal(char,item,1)
            assert(a.Strength==0 and math.abs(battery.Condition-87.5)<.00001)
        ''')

    def test_nt_flag_and_native_joint_share_one_regeneration_job(self):
        self.lua.execute('''
            E.NT={};local a=add('tll_amputation',1,true)
            char.AnimController.LimbJoints={{IsSevered=true,LimbA={type='LeftLeg'},LimbB={type='Torso'}}}
            local medical=require('AegisHeadset.medical')
            local jobs=medical.jobs(char,medical.entries(E,char))
            local count=0;for _ in pairs(jobs) do count=count+1 end
            assert(count==1 and jobs['limb:LeftLeg'].jointIndices[1]==1,'same missing limb is charged twice')
        ''')

    def test_combined_limb_restores_its_joints_once_and_preserves_other_loss(self):
        self.lua.execute('''
            E.NT={};local a=add('tll_amputation',1,true)
            char.AnimController.LimbJoints={
                {IsSevered=true,LimbA={type='LeftLeg'},LimbB={type='Torso'}},
                {IsSevered=true,LimbA={type='LeftFoot'},LimbB={type='LeftLeg'}},
                {IsSevered=true,LimbA={type='RightArm'},LimbB={type='Torso'}}}
            local medical=require('AegisHeadset.medical')
            local restored={};medical.restoreNative=function(c,index)
                restored[#restored+1]=index;c.AnimController.LimbJoints[index].IsSevered=false
            end
            for i=1,7 do G.heal(char,item,1) end
            assert(a.Strength==0 and #restored==2 and battery.Condition==87.5)
            assert(char.AnimController.LimbJoints[3].IsSevered)
        ''')

    def test_native_numeric_limb_types_join_the_nt_limb_job(self):
        self.lua.execute('''
            E.NT={};local a=add('tll_amputation',1,true)
            E.LimbType={LeftThigh=16,LeftLeg=7,Torso=1}
            char.AnimController.LimbJoints={
                {IsSevered=true,LimbA={type=16},LimbB={type=1}}}
            local restored=false
            require('AegisHeadset.medical').restoreNative=function(c,index) restored=index==1 end
            for i=1,7 do G.heal(char,item,1) end
            assert(a.Strength==0 and battery.Condition==87.5 and restored,'native limb charged twice')
        ''')
