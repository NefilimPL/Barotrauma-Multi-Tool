import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from lua_support import LuaCase
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'System-Aegis-No-Headsets'


class PresentationContentTests(unittest.TestCase):
    def test_suit_cabinets_use_compact_portraits_and_one_shell_per_limb(self):
        for filename in ('aegis_suit.xml', 'aegis_factions.xml'):
            for suit in ET.parse(MOD / filename).getroot().findall('Item'):
                if not suit.get('identifier', '').startswith('aegisservosuit'):
                    continue
                window = suit.find("ContainedSprite[@allowedcontainertags='divingsuitcontainerwindow']")
                width, height = map(int, window.get('sourcerect').split(',')[2:])
                self.assertGreater(width, 550)
                self.assertLess(height, width * 1.6)
                plates = [node for node in suit.iter('sprite') if node.get('texture').endswith('/suit-v2.png')]
                self.assertEqual(len(plates), 15)
                shell = [node for node in suit.iter('sprite') if node.get('hidelimb') == 'true']
                self.assertEqual(set(shell), {node for node in plates if node.get('limb') != 'Head'})
                for plate in shell:
                    self.assertEqual(plate.get('hideotherwearables'), 'true')
                    self.assertEqual(plate.get('canbehiddenbyotherwearables'), 'false')
                path = MOD / plates[0].get('texture').removeprefix('%ModDir%/')
                with Image.open(path) as atlas:
                    self.assertEqual(atlas.size, (768, 512))

    def test_public_package_has_no_variant_qualifier(self):
        self.assertEqual(ET.parse(MOD / 'filelist.xml').getroot().get('name'), 'System Aegis')

    def test_shield_cartridge_remains_insertable_without_world_overlay(self):
        item = ET.parse(MOD / 'aegis_combat.xml').find('Item')
        container = item.find('ItemContainer')
        self.assertEqual(container.get('hideitems'), 'true')
        self.assertEqual(container.find('SubContainer/Containable').get('items'), 'aegisshieldmodule')
        self.assertIsNotNone(container.find("SlotIcon[@slotindex='1']"))

    def test_native_controls_are_preserved_but_no_longer_draw_independent_panels(self):
        for filename in ('aegis_combat.xml', 'aegis_tools.xml'):
            for component in ET.parse(MOD / filename).getroot().iter('CustomInterface'):
                self.assertEqual(component.get('drawhudwhenequipped'), 'true')
                self.assertEqual(len(component.findall('TickBox')), 3)

    def test_flashlights_use_directional_cones_with_wider_helmet_beams(self):
        combat = ET.parse(MOD / 'aegis_combat.xml').find('Item').findall('LightComponent')[1]
        tools = ET.parse(MOD / 'aegis_tools.xml').getroot()
        composite = next(n for n in tools.findall('Item') if n.get('identifier') == 'aegiscompositetool')
        lights = [combat, composite.find('LightComponent')]
        for filename in ('aegis_suit.xml', 'aegis_factions.xml'):
            for suit in ET.parse(MOD / filename).getroot().findall('Item'):
                if suit.get('identifier', '').startswith('aegisservosuit'):
                    lights.append(suit.find('LightComponent'))
        self.assertEqual(len(lights), 8)
        for index, light in enumerate(lights):
            self.assertIsNotNone(light)
            self.assertGreater(float(light.get('range')),0)
            self.assertEqual(light.get('directional'), 'true')
            texture = light.find('LightTexture')
            self.assertEqual(texture.get('texture'), 'Content/Lights/lightcone.png')
            width, height = map(float, texture.get('size').split(','))
            if index < 2:
                self.assertLessEqual(height / width, .5)
            else:
                self.assertGreaterEqual(height / width, .75)

    def test_suit_slots_start_collapsed_in_each_variant(self):
        for filename in ('aegis_suit.xml', 'aegis_factions.xml'):
            for suit in ET.parse(MOD / filename).getroot().findall('Item'):
                if suit.get('identifier', '').startswith('aegisservosuit'):
                    self.assertEqual(suit.find('ItemContainer').get('keepopenwhenequipped'), 'false')


class NativeControlRelayTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def setUp(self):
        super().setUp()
        self.lua.execute("""
            nativeEvents={};values={false,false,false};controls={}
            for i=1,3 do controls[i]=setmetatable({}, {
                __index=function(_,key) if key=='Selected' then return values[i] end end,
                __newindex=function(_,key,value)
                    assert(key=='Selected');if values[i]==value then return end
                    values[i]=value;nativeEvents[#nativeEvents+1]={index=i,value=value}
                end}) end
            frame={RemoveFromGUIUpdateList=function() end}
            ci={Name='CustomInterface',uiElements=controls,GuiFrame=frame,
                UpdateHUDComponentSpecific=function() end}
            item={Prefab={Identifier={Value='aegiscombattool'}},Components={ci}}
            E={LuaUserData={RegisterType=function() return {} end,MakeFieldAccessible=function() end}}
            R=require('AegisHUD.controls').new(E)
        """)


    def test_explicit_modes_clear_conflicting_flags_through_native_setters(self):
        self.lua.execute("""
            assert(R.setMode(item,'combat'));assert(values[3] and not values[1] and not values[2])
            assert(R.setMode(item,'cut'));assert(values[1] and not values[2] and not values[3])
            assert(R.setMode(item,'extinguish'));assert(values[2] and not values[3])
            assert(R.setMode(item,'weld'));assert(not values[1] and not values[2] and not values[3])
            assert(#nativeEvents>0)
        """)

    def test_reselecting_active_mode_emits_no_duplicate_events(self):
        self.lua.execute("R.setMode(item,'combat');local n=#nativeEvents;R.setMode(item,'combat');assert(#nativeEvents==n)")

    def test_composite_damage_permission_is_independent_of_tool_mode(self):
        self.lua.execute("""
            item.Prefab.Identifier.Value='aegiscompositetool'
            R.setDamage(item,true);R.setMode(item,'cut')
            assert(values[1] and values[3] and not values[2]);assert(not R.setMode(item,'combat'))
        """)

    def test_missing_native_interface_and_unknown_modes_are_safe(self):
        self.lua.execute("assert(not R.setMode(item,'arbitrary'));item.Components={};assert(not R.setMode(item,'cut'));assert(#nativeEvents==0)")

    def test_native_refresh_keeps_widget_hidden_and_reads_predicted_flags(self):
        self.lua.execute("""
            R.setMode(item,'cut');R.refresh(item,{},.1,{})
            assert(frame.Visible==false);local f=R.flags(item);assert(f.cutter and not f.damage)
        """)


class CombinedPanelModelTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def test_mode_labels_follow_actual_combat_precedence(self):
        self.lua.execute("""
            local M=require('AegisHUD.model')
            assert(M.mode({cutter=true,damage=true},true)=='combat')
            assert(M.mode({cutter=true,damage=true,extinguisher=true},true)=='extinguish')
            assert(M.mode({cutter=true,damage=true},false)=='cut')
        """)


    def test_both_sections_fit_inside_one_panel_at_supported_resolutions(self):
        self.lua.execute("""
            local M=require('AegisHUD.model')
            for _,size in ipairs({{1280,720},{1920,1080},{3440,1440}}) do
                local r=M.layout(true,true,size[1],size[2])
                assert(r.width<=size[1]*.4 and r.height<=size[2]*.85)
                assert(r.width<=300 and r.height<=350)
                assert(r.toolY+r.toolH<=r.armY and r.armY+r.armH<=1)
            end
        """)


class CombinedPanelClientTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def setUp(self):
        super().setUp()
        self.lua.execute("""
            widgets={};hooks={};removed={};events=0;nativePatch=nil
            local function rt(v,parent)
                local r={Parent=parent,RelativeSize=v,RelativeOffset={X=0,Y=0}}
                r.Resize=function(size) r.RelativeSize=size end
                return r
            end
            local function widget(r,text)
                local w={RectTransform=r,Text=text,Visible=true}
                w.AddToGUIUpdateList=function() w.queued=true end
                w.RemoveFromGUIUpdateList=function() w.queued=false end
                widgets[#widgets+1]=w;return w
            end
            local UI={Anchor={TopLeft=1,CenterRight=2},Pivot={TopLeft=1},RectTransform=rt,
                GUI={Canvas={Rect={Width=1920,Height=1080}}}}
            UI.Frame=function(r) return widget(r,'') end
            UI.Button=widget;UI.TextBlock=widget
            flags={false,false,false};native={}
            for i=1,3 do native[i]=setmetatable({}, {
                __index=function(_,k) if k=='Selected' then return flags[i] end end,
                __newindex=function(_,k,v) assert(k=='Selected');if flags[i]~=v then flags[i]=v;events=events+1 end end}) end
            ci={Name='CustomInterface',uiElements=native,GuiFrame=widget(rt({}),''),UpdateHUDComponentSpecific=function() end}
            battery={Condition=80,MaxCondition=100}
            cartridge={Prefab={Identifier={Value='aegisshieldmodule'}},Condition=60,MaxCondition=100}
            tool={Prefab={Identifier={Value='aegiscombattool'}},Name='Aegis',Condition=100,Components={ci},
                OwnInventory={GetItemAt=function(i) return i==0 and battery or cartridge end}}
            held=tool;suit={};worn=suit
            owner={Inventory={GetItemInLimbSlot=function() return held end}}
            E={GUI=UI,Character={Controlled=owner},InvSlotType={RightHand=1,LeftHand=2},
                Game={RoundStarted=true,GameScreen={Cam={}}},
                Vector2=function(x,y) return {X=x,Y=y} end,
                Color=function(r,g,b,a) return {r,g,b,a} end,
                TextManager={Get=function(s) return s end},
                LuaUserData={RegisterType=function() return {} end,MakeFieldAccessible=function() end},
                Hook={HookMethodType={Before=1},Add=function(event,id,fn) hooks[event]=fn end,
                    Remove=function(event,id) removed[event]=true end,
                    Patch=function(id,class,method,fn) nativePatch=fn end,RemovePatch=function() removed.patch=true end},
                AegisSuit={equipped=function() return worn end,state=function() return {mode='off'} end},
                AegisCombat={shieldCharges=function() return 3 end}}
            H=require('AegisHUD.client').install(E)
        """)

    def test_native_localized_text_userdata_does_not_break_combined_panel(self):
        class LocalizedText:
            def __init__(self, value):
                self.value = value
            def __str__(self):
                return str(self.value)
        self.lua.globals().native_text = LocalizedText
        self.lua.execute("""
            local w=H.shieldStatus;local value=w.Text;rawset(w,'Text',nil)
            setmetatable(w,{
                __index=function(_,key) if key=='Text' then return native_text(value) end end,
                __newindex=function(t,key,v) if key=='Text' then value=v else rawset(t,key,v) end end})
            H.update(.1)
            assert(type(H.shieldStatus.Text)=='userdata')
            assert(tostring(H.shieldStatus.Text):find('3/5',1,true))
            assert(H.panel.Visible and H.toolHost.Visible and H.armHost.Visible)
        """)

    def test_shield_text_has_its_own_readable_line_from_first_frame(self):
        self.lua.execute("""
            H.update(.1)
            assert(H.shieldStatus and H.shieldStatus.Visible)
            local scale=H.shieldStatus.TextScale
            assert(scale>=.8 and not H.shieldStatus.AutoScaleVertical and not H.shieldStatus.Wrap)
            assert(H.status.Text:find('80%%') and not H.status.Text:find('shield'))
            for _,charges in ipairs({0,1,5}) do
                E.AegisCombat.shieldCharges=function() return charges end
                H.update(.1)
                assert(H.shieldStatus.Text:find(tostring(charges)..'/5',1,true))
                assert(H.shieldStatus.TextScale==scale)
            end
            tool.Prefab.Identifier.Value='aegiscompositetool';H.update(.1)
            assert(not H.shieldStatus.Visible)
        """)

    def test_native_hud_filter_preserves_server_authorization_and_other_components(self):
        self.lua.execute("""
            ci.Item=tool;local p={};assert(nativePatch(ci,p)==false and p.PreventExecution)
            local other={Name='ItemContainer',Item=tool};p={};nativePatch(other,p);assert(not p.PreventExecution)
            other={Name='CustomInterface',Item={Prefab={Identifier={Value='vanilla'}}}}
            p={};nativePatch(other,p);assert(not p.PreventExecution)
        """)

    def test_tool_and_suit_share_one_parent_and_collapse_to_one_tab(self):
        self.lua.execute("""
            H.update(.1);assert(H.panel.Visible and H.toolHost.Visible and H.armHost.Visible)
            assert(H.armHost.RectTransform.Parent==H.panel.RectTransform)
            H.setOpen(false);H.update(.1)
            assert(not H.panel.Visible and H.tab.Visible and not H.armHost.Visible)
            H.tab.OnClicked();H.update(.1);assert(H.panel.Visible and not H.tab.Visible)
        """)

    def test_buttons_use_native_relay_and_have_explicit_active_text(self):
        self.lua.execute("""
            H.update(.1);H.buttons.cut.OnClicked();H.update(.1)
            assert(flags[1] and not flags[2] and not flags[3]);assert(events==1)
            assert(H.buttons.cut.Selected and H.buttons.cut.Text:find('aegishud.on',1,true))
            assert(not H.buttons.weld.Selected and H.buttons.weld.Text:find('aegishud.off',1,true))
        """)

    def test_collapsed_and_unequipped_controls_cannot_send_hidden_clicks(self):
        self.lua.execute("""
            H.update(.1);H.setOpen(false);H.buttons.cut.OnClicked();assert(events==0)
            H.setOpen(true);held=nil;H.update(.1);H.buttons.cut.OnClicked();assert(events==0)
        """)

    def test_one_handed_composite_controls_work_in_either_hand(self):
        self.lua.execute("""
            tool.Prefab.Identifier.Value='aegiscompositetool';local right,left=tool,nil
            owner.Inventory.GetItemInLimbSlot=function(slot) return slot==1 and right or left end
            H.update(.1);assert(H.item==tool and H.toolHost.Visible)
            right=nil;left=tool;H.update(.1);assert(H.item==tool and H.toolHost.Visible)
            H.buttons.cut.OnClicked();assert(flags[1] and not flags[2])
        """)

    def test_one_section_or_no_equipment_updates_visibility(self):
        self.lua.execute("""
            H.update(.1);worn=nil;H.update(.1);assert(H.toolHost.Visible and not H.armHost.Visible)
            held=nil;H.update(.1);assert(not H.panel.Visible and not H.tab.Visible)
            worn=suit;H.update(.1);assert(not H.toolHost.Visible and H.armHost.Visible)
        """)

    def test_pause_round_end_and_disposal_remove_interactive_widgets(self):
        self.lua.execute("""
            H.update(.1);E.Game.Paused=true;H.update(.1);assert(not H.panel.Visible and not H.tab.Visible)
            E.Game.Paused=false;H.update(.1);hooks.roundEnd();assert(not H.panel.Visible)
            H.dispose();assert(H.panel.RectTransform.Parent==nil and H.tab.RectTransform.Parent==nil)
            assert(removed.think and removed.roundEnd and removed.stop)
        """)



class SuitConeLightTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def test_helmet_uses_native_cone_template_follows_head_and_loses_power(self):
        self.lua.execute("""
            local template={cone=true};local sources={};local removed=0;local facing=1;local power=100
            local function source(arg,radius)
                assert(radius==nil or radius>0,"zero-radius light constructor")
                local light={template=arg,Remove=function() removed=removed+1 end}
                sources[#sources+1]=light;return light
            end
            local E={LuaUserData={RegisterType=function() end,CreateStatic=function() return source end},
                Vector2=function(x,y) return {X=x,Y=y} end,Color=function() return {} end,LimbType={Head=1}}
            local owner={AnimController={GetLimb=function()
                return {body={Rotation=math.pi/4},WorldPosition={X=100,Y=200}}
            end}}
            local item={Prefab={ConfigElement={GetChildElement=function(name) assert(name=='LightComponent');return template end}}}
            local s={item=item,owner=owner}
            local G={now=0,energy=function() return power end,
                attachment=function() return {x=10,y=20},0,facing end,
                toolPose=function() return {muzzle={x=30,y=20},angle=0} end}
            require('AegisSuit.lights').install(G,E)
            G.updateLights(s,false)
            assert(s.lights.helmet.template==template and s.lights.helmet.Range>0)
            assert(s.lights.helmet.Enabled and s.lights.helmet.Rotation==math.pi/4)
            assert(s.lights.helmet.Position.X>100 and s.lights.helmet.Position.X<111)
            assert(s.lights.helmet.Position.Y>200 and s.lights.helmet.Position.Y<212)
            facing=-1;G.updateLights(s,false);assert(s.lights.helmet.Rotation==math.pi/4-math.pi)
            power=0;G.updateLights(s,false);assert(s.lights.helmet.Range==650 and not s.lights.helmet.Enabled)
            assert(s.lights.tool.Range>0 and not s.lights.tool.Enabled)
            G.removeLights(s);assert(removed==2 and s.lights==nil)
        """)


class SuitSwimBoostTests(LuaCase):
    mod_directory = 'System-Aegis-No-Headsets'

    def test_boost_only_applies_to_a_powered_impeller_during_the_swim_step(self):
        self.lua.execute("""
            local owner,suit,boost={},{},true
            local power=10
            local G={equipped=function(c) assert(c==owner);return suit end,
                hasImpeller=function() return boost end,
                energy=function() return power end}
            local E={Vector2=function(x,y) return {X=x,Y=y} end}
            local before,after
            G.patch=function(_,class,method,fn,isAfter)
                assert(class=='Barotrauma.HumanoidAnimController' and method=='UpdateSwimming')
                if isAfter then after=fn else before=fn end
            end
            require('AegisSuit.swim').install(G,E);G.installSwimBoost()
            local movement=E.Vector2(2,0)
            local anim={Character=owner,InWater=true,TargetMovement=movement}
            before(anim);assert(anim.TargetMovement.X==3);after(anim);assert(anim.TargetMovement==movement)
            power=0;before(anim);assert(anim.TargetMovement==movement);after(anim)
            power=10;boost=false;before(anim);assert(anim.TargetMovement==movement);after(anim)
            boost=true;anim.InWater=false;before(anim);assert(anim.TargetMovement==movement);after(anim)
        """)

