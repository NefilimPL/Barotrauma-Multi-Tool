import unittest
from lua_support import LuaCase
from test_combat_shield_network import ShieldRenderSynchronizationTests
from test_vacuum_client import VacuumClientTests
from test_idle_performance import IdlePerformanceTests
from test_passive_skills import PassiveSkillTests


def load_tests(loader, tests, pattern):
    return unittest.TestSuite([
        ShieldFrameTests('test_stationary_occlusion_is_reused_and_moving_or_expired_masks_refresh'),
        ShieldFrameTests('test_offscreen_shield_does_not_cast_or_draw'),
        IdleToolFrameTests('test_stowed_tool_skips_context_but_equipping_and_dropping_are_immediate'),
        PassiveFrameTests('test_passive_timer_never_enumerates_unrelated_characters'),
        PassiveFrameTests('test_equip_event_tracks_new_owner_without_waiting_for_discovery'),
        VacuumFrameTests('test_loot_refresh_bounds_native_inspection_per_think'),
        TileFrameTests('test_snapshots_reuse_tiles_and_clicks_follow_replaced_rows'),
    ])


class ShieldFrameTests(ShieldRenderSynchronizationTests):
    def test_stationary_occlusion_is_reused_and_moving_or_expired_masks_refresh(self):
        self.lua.execute("""
            local casts=0;G.cast=function() casts=casts+1 end
            draw();assert(casts==41)
            G.now=.02;draw();assert(casts==41,'stationary shield repeated occlusion casts')
            body.DrawPosition.X=body.DrawPosition.X+10;draw();assert(casts==82)
            G.now=.15;draw();assert(casts==123,'dynamic obstruction mask did not expire')
        """)

    def test_offscreen_shield_does_not_cast_or_draw(self):
        self.lua.execute("""
            local casts=0;G.cast=function() casts=casts+1 end
            camera.WorldView={X=10000,Y=10100,Width=100,Height=100}
            draw();assert(casts==0 and drawCount==0,'offscreen shield performed rendering work')
            camera.WorldView={X=-200,Y=200,Width=400,Height=400}
            draw();assert(casts==41 and drawCount>0,'visible shield disappeared')
        """)


class IdleToolFrameTests(LuaCase):
    def test_stowed_tool_skips_context_but_equipping_and_dropping_are_immediate(self):
        self.lua.execute("""
            local held=false
            local owner={IsKeyDown=function() return true end}
            owner.Inventory={GetItemInLimbSlot=function() if held then return gun end end}
            local lamp={Name='LightComponent',IsOn=false,IsActive=false}
            gun={ID=1,Condition=100,Prefab={Identifier={Value='combatmultitool'}},Components={
                {Name='Pump',IsOn=false},{Name='Controller',State=false},{Name='LightComponent',IsOn=false},lamp}}
            local E={InvSlotType={RightHand=1,LeftHand=2},InputType={Aim=1},
                Util={GetItemsById=function() return {gun} end},Hook={Add=function() end},
                LuaUserData={CreateEnumTable=function() return {Both=1} end,
                    RegisterType=function() return {} end,MakeFieldAccessible=function() end,
                    IsTargetType=function(o,t) return o==owner and t=='Barotrauma.Character' end}}
            local G=require('CombatTool.game').new(E);G.authoritative=false;G.patch=function() end
            G.powered=function() return true end
            local context=G.context;local calls=0
            G.context=function(...) calls=calls+1;return context(...) end
            require('CombatTool.runtime').install(G,E)
            for i=1,60 do G.update(1/60) end
            assert(calls==0,'floor tool resolved full context '..calls..' times')
            gun.ParentInventory={Owner=owner};held=true;G.update(1/60)
            assert(calls==1 and lamp.IsOn and lamp.IsActive,'equipped tool did not wake immediately')
            held=false;G.update(1/60)
            assert(calls==1 and not lamp.IsOn and not lamp.IsActive,'stowed tool stayed active')
        """)


class PassiveFrameTests(PassiveSkillTests):
    def test_passive_timer_never_enumerates_unrelated_characters(self):
        self.lua.execute("""
            env.Character=setmetatable({},{__index=function() error('enumerated all characters') end})
            G.updatePassiveSkills(300);assert(changes==5)
        """)

    def test_equip_event_tracks_new_owner_without_waiting_for_discovery(self):
        self.lua.execute("""
            actor.HeldItems={};G.updatePassiveSkills(.01)
            local newcomer={HeldItems={gun},Info=actor.Info,HasAbilityFlag=actor.HasAbilityFlag}
            gun.ParentInventory={Owner=newcomer}
            hooks['item.equip'](gun,newcomer)
            G.updatePassiveSkills(299.99);assert(changes==0)
            G.updatePassiveSkills(.01);assert(changes==5)
        """)


class VacuumFrameTests(IdlePerformanceTests):
    def test_loot_refresh_bounds_native_inspection_per_think(self):
        self.lua.execute("""
            local nozzle={ID=1,kind='aegisvacuum',WorldPosition={X=-10000,Y=0}}
            indexed.aegisvacuum={nozzle};world={nozzle}
            for i=2,1025 do world[i]={ID=i,kind='iron',WorldPosition={X=-10000,Y=0}} end
            vacuumRuntime(true);G.update(.01)
            G.context=function() return {valid=true,aim=true,pack={},owner={}} end
            G.charge=function() return 100 end;G.spend=function() return true end
            G.muzzle=function() return {x=0,y=0} end;G.direction=function() return {x=1,y=0} end
            local inspected=0
            G.id=function(i) inspected=inspected+1;return i.kind end
            local total=0
            for i=1,40 do
                inspected=0;G.states[nozzle].usedAt=G.now;G.update(1/60)
                assert(inspected<=256,'single think inspected '..inspected..' native items')
                total=total+inspected
            end
            assert(total>=1025,'incremental refresh never finished')
        """)


class TileFrameTests(VacuumClientTests):
    def test_snapshots_reuse_tiles_and_clicks_follow_replaced_rows(self):
        self.lua.execute("""
            G.openPanel(pack)
            local s={vacuum=pack.ID,pack=pack.ID,charge=0,groups=1,count=1,busy=false,
                page=0,pages=1,packs={pack.ID},rows={{id=10,kind='iron',name='Iron',count=1,condition=80,quality=0,group=1}}}
            G.onSnapshot(s)
            local count=#widgets;local tile
            for _,w in ipairs(widgets) do if w.ToolTip and w.ToolTip:find('Iron',1,true) then tile=w end end
            G.onSnapshot(s);assert(#widgets==count,'unchanged snapshot allocated widgets')
            s.rows[1]={id=20,kind='iron',name='New Iron',count=2,condition=40,quality=1,group=1}
            G.onSnapshot(s);assert(#widgets==count)
            tile.OnClicked();button('vacuum.stack').OnClicked()
            assert(requests[#requests].target==20,'reused tile operated on its previous item')
            s.rows={};G.onSnapshot(s)
            assert(not tile.Enabled and not button('vacuum.stack').Enabled)
            s.rows={{id=30,kind='iron',name='Iron',count=3,condition=100,quality=0,group=1}}
            G.onSnapshot(s);assert(#widgets==count and tile.Enabled)
        """)
