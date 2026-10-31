from lua_support import LuaCase


class PassiveSkillTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            levels={helm=10,weapons=20,mechanical=30,electrical=40,medical=50}
            changes=0
            source={Condition=100,HasTag=function(tag) return tag=='mobilebattery' end}
            gun={Condition=100,Prefab={Identifier={Value='combatmultitool'}},
                OwnInventory={GetItemAt=function() return source end}}
            actor={HeldItems={gun},Info={Job={GetSkillLevel=function(id) return levels[id] end},
                SetSkillLevel=function(id,level) levels[id]=level;changes=changes+1 end},
                HasAbilityFlag=function() return overcap or false end}
            env={Character={CharacterList={actor}},LuaUserData={RegisterType=function() end,
                CreateEnumTable=function() return {GainSkillPastMaximum=1} end,
                CreateStatic=function(name)
                    if name=='Barotrauma.Skill' then return {DefaultMaximumSkill=100} end
                    return {Current={MaximumSkillWithTalents=150}}
                end}}
            G={authoritative=true}
            require('CombatTool.passive_skills').install(G,env)
        ''')

    def test_first_reward_waits_five_minutes_and_awards_all_five_skills(self):
        self.lua.execute('''
            G.updatePassiveSkills(299.9);assert(changes==0,'reward granted before five minutes')
            G.updatePassiveSkills(.1)
            assert(changes==5 and levels.helm==12 and levels.weapons==22 and levels.mechanical==32
                and levels.electrical==42 and levels.medical==52,'reward was not exactly two per skill')
            G.updatePassiveSkills(299);assert(changes==5,'reward interval restarted incorrectly')
            G.updatePassiveSkills(1);assert(changes==10 and levels.weapons==24)
        ''')

    def test_stowing_pauses_progress_and_switching_tools_cannot_stack_it(self):
        self.lua.execute('''
            G.updatePassiveSkills(150)
            actor.HeldItems={};G.updatePassiveSkills(300);assert(changes==0)
            local small={Condition=100,Prefab={Identifier={Value='multi-toolset'}},OwnInventory=gun.OwnInventory}
            source.HasTag=function(tag) return tag=='reactorfuel' end
            actor.HeldItems={small,gun};G.updatePassiveSkills(149);assert(changes==0)
            G.updatePassiveSkills(1);assert(changes==5,'two multitools doubled or reset the character timer')
        ''')

    def test_empty_source_and_unconscious_character_do_not_earn_time(self):
        self.lua.execute('''
            source.Condition=0;G.updatePassiveSkills(300);assert(changes==0)
            source.Condition=100;actor.IsUnconscious=true;G.updatePassiveSkills(300);assert(changes==0)
            actor.IsUnconscious=false;G.updatePassiveSkills(299);assert(changes==0)
            G.updatePassiveSkills(1);assert(changes==5)
        ''')

    def test_smaller_tool_retains_fuel_rod_requirement(self):
        self.lua.execute('''
            gun.Prefab.Identifier.Value='multi-toolset'
            G.updatePassiveSkills(300);assert(changes==0,'small tool earned time with ordinary battery')
            source.HasTag=function(tag) return tag=='reactorfuel' end
            G.updatePassiveSkills(300);assert(changes==5)
        ''')

    def test_multiplayer_clients_cannot_grant_skills(self):
        self.lua.execute('G.authoritative=false;G.updatePassiveSkills(600);assert(changes==0)')

    def test_native_skill_limits_and_existing_above_limit_values_are_preserved(self):
        self.lua.execute('''
            levels.helm=99;levels.weapons=110
            G.updatePassiveSkills(300)
            assert(levels.helm==100 and levels.weapons==110,'default cap was exceeded or an existing high skill decreased')
            overcap=true;G.updatePassiveSkills(300)
            assert(levels.helm==102 and levels.weapons==112,'native overcap talent was ignored')
        ''')

    def test_round_cleanup_resets_earned_time(self):
        self.lua.execute('''
            G.updatePassiveSkills(299);G.clearPassiveSkills();G.updatePassiveSkills(1)
            assert(changes==0,'previous round progress leaked')
        ''')
