import unittest
from PIL import Image
import xml.etree.ElementTree as ET
from pathlib import Path
from lua_support import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'System-Aegis-No-Headsets'
KEYS = ('pirates', 'descendens', 'coalition', 'separatists', 'husk', 'clowns')
FAMILIES = {'suit': 'aegisservosuit', 'servo': 'aegisservomodule', 'impeller': 'aegisimpellermodule'}


def identifier(kind, key):
    return FAMILIES[kind] + ('' if key == 'pirates' else key)


class FactionRulesTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("package.path=... .. '/?.lua;' .. package.path", (MOD / 'Lua').as_posix())
        self.lua.execute("F=require('AegisSuit.factions')")

    def test_existing_red_equipment_is_the_pirate_palette(self):
        self.lua.execute("""
            function item(id) return {Prefab={Identifier={Value=id}},Condition=100} end
            assert(F.key(item('aegisservosuit'))=='pirates')
            assert(F.key(item('aegisservomodule'))=='pirates')
            assert(F.path('pirates','atlas')=='Assets/AegisSuit/suit-v2.png')
            assert(F.path('coalition','atlas')=='Assets/Factions/coalition/suit-v2.png')
        """)

    def test_all_suit_ids_are_recognized_but_other_prefabs_are_rejected(self):
        self.lua.execute("""
            E={Game={IsSingleplayer=true}}
            G=require('AegisSuit.game').new(E)
            for _,id in ipairs(F.suitIds) do
                assert(G.is({Prefab={Identifier={Value=id}},Condition=100}),id)
            end
            assert(#F.suitIds==6)
            assert(not G.is({Prefab={Identifier={Value='aegisservosuit_fake'}}}))
            assert(not G.is({Prefab={Identifier={Value='aegisservomodulecoalition'}}}))
        """)

    def test_authority_indexes_every_suit_palette(self):
        self.lua.execute("""
            local seen={};local count=0
            E={Game={IsSingleplayer=true},Util={GetItemsById=function(id)
                assert(not seen[id],'duplicate identifier query');seen[id]=true
                return {{Prefab={Identifier={Value=id}},Condition=100}}
            end}}
            E.Game.RoundStarted=true
            G=require('AegisSuit.game').new(E)
            G.eachSuit(function(item) assert(G.is(item));count=count+1 end)
            assert(count==6)
            for _,id in ipairs(F.suitIds) do assert(seen[id],id) end
            seen={};G.update(.3)
            for _,id in ipairs(F.suitIds) do assert(seen[id],'update missed '..id) end
        """)

    def test_colored_modules_are_compatible_and_keep_their_own_palette(self):
        self.lua.execute("""
            function part(id) return {Condition=100,MaxCondition=100,Prefab={Identifier={Value=id}}} end
            local slots={}
            local suit={Components={{Name='ItemContainer',Inventory={GetItemAt=function(i) return slots[i] end}}}}
            G=require('AegisSuit.game').new({Game={IsSingleplayer=true}})
            for _,key in ipairs(F.order) do
                slots[2]=part(F.id('servo',key));slots[3]=part(F.id('impeller',key))
                assert(G.hasArm(suit) and G.hasImpeller(suit),key)
                assert(F.key(G.module(suit,'servo'))==key)
                assert(F.key(G.module(suit,'impeller'))==key)
            end
            slots[2]=part('aegisservomodulecoalition');slots[3]=part('aegisimpellermodulehusk')
            assert(F.key(G.module(suit,'servo'))=='coalition')
            assert(F.key(G.module(suit,'impeller'))=='husk')
            slots[2].Condition=0;assert(not G.hasArm(suit))
            slots[2]=slots[3];assert(not G.hasArm(suit))
        """)


class FactionContentTests(unittest.TestCase):
    def items(self):
        path = MOD / 'aegis_factions.xml'
        self.assertTrue(path.is_file(), 'Faction prefabs are missing')
        return {n.get('identifier'): n for n in ET.parse(path).getroot().findall('Item')}

    def test_each_additional_faction_has_suit_servo_and_impeller(self):
        items = self.items()
        self.assertEqual(set(items), {identifier(kind, key) for key in KEYS[1:] for kind in FAMILIES})
        manifest = ET.parse(MOD / 'filelist.xml').getroot()
        self.assertIn('%ModDir%/aegis_factions.xml', {n.get('file') for n in manifest})

    def test_cosmetic_variants_keep_the_original_balance(self):
        items = self.items()
        sources = {'suit': ET.parse(MOD / 'aegis_suit.xml').find('Item')}
        sources.update({kind: ET.parse(MOD / 'aegis_modules.xml').find(f"Item[@identifier='{base}']")
                        for kind, base in FAMILIES.items() if kind != 'suit'})
        for key in KEYS[1:]:
            for kind, source in sources.items():
                candidate = items[identifier(kind, key)]
                for tag in ('Fabricate', 'Deconstruct', 'Body', 'Quality') + (('Price',) if kind != 'suit' else ()):
                    old, new = source.find(tag), candidate.find(tag)
                    self.assertEqual(ET.tostring(old) if old is not None else None,
                                     ET.tostring(new) if new is not None else None, (key, kind, tag))
                for attribute in ('scale', 'addedrepairspeedmultiplier', 'cannotrepairfail'):
                    self.assertEqual(source.get(attribute), candidate.get(attribute), (key, kind, attribute))

    def test_new_items_have_english_and_polish_names_and_descriptions(self):
        items = self.items()
        for language in ('English', 'Polish'):
            texts = {}
            for path in MOD.glob('*.xml'):
                root = ET.parse(path).getroot()
                if root.tag == 'infotexts' and root.get('language') == language:
                    texts.update((n.tag, n.text) for n in root)
            for item_id in items:
                self.assertIn('Aegis', texts.get('entityname.' + item_id, ''), (language, item_id))
                self.assertTrue(texts.get('entitydescription.' + item_id), (language, item_id))

    def test_all_graphic_states_and_module_icons_use_the_matching_palette(self):
        items = self.items()
        for key in KEYS[1:]:
            suit = items[identifier('suit', key)]
            references = [n.get('texture') for n in suit.iter() if n.get('texture', '').startswith('%ModDir%/Assets/')]
            self.assertTrue(references)
            for reference in references:
                self.assertTrue(reference.startswith('%ModDir%/Assets/Factions/' + key + '/')
                                or reference == '%ModDir%/Assets/AegisSuit/empty-seal.png', reference)
                self.assertTrue((MOD / reference.removeprefix('%ModDir%/')).is_file(), reference)
            for kind in ('servo', 'impeller'):
                reference = items[identifier(kind, key)].find('InventoryIcon').get('texture')
                self.assertEqual(reference, '%ModDir%/Assets/Factions/' + key + '/' + kind + '-icon.png')


class FactionRenderingTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("package.path=... .. '/?.lua;' .. package.path", (MOD / 'Lua').as_posix())
        self.lua.execute("""
            sprites={};draws={};renderRects={}
            local function v(x,y) return {X=x,Y=y} end
            local function part(id) return {Condition=100,Prefab={Identifier={Value=id}}} end
            suit=part('aegisservosuitdescendens');arm=part('aegisservomodulecoalition');motor=part('aegisimpellermodulehusk')
            owner={AnimController={Limbs={}}};state={owner=owner,mode='off',hasArm=true,hasImpeller=true}
            package.loaded['AegisSuit.lights']={install=function(g) g.removeLights=function() end end}
            package.loaded['AegisSuit.ui']={install=function(g) g.disposeSuitUI=function() end end}
            local function sprite(path,origin)
                local s={path=path,Origin=origin,SourceRect={Width=512,Height=512}}
                s.Draw=function() draws[#draws+1]=path;renderRects[#renderRects+1]={path=path,rect=s.SourceRect} end
                s.Remove=function() s.removed=true end
                sprites[#sprites+1]=s;return s
            end
            E={Sprite=sprite,Vector2=v,Color={White={}},LuaUserData={CreateEnumTable=function() return {None=0} end},printerror=function() end,
                Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,
                GUI={GUI={Canvas={Rect={Width=800,Height=600}},DrawLine=function() end}}}
            G={now=1,authoritative=true,states={[suit]=state},
                equipped=function() return suit end,owner=function() return owner end,
                module=function(_,kind) return kind=='servo' and arm or motor end,
                mount=function() return {x=0,y=0},0,1 end,attachment=function() return {x=0,y=0} end,
                toolPose=function() return {elbow={x=40,y=20},tip={x=80,y=0},muzzle={x=104,y=0},angle=0} end,
                patch=function(name,_,_,fn) if name=='draw' then draw=fn end end}
            require('AegisSuit.client').install(G,E,'mod')
            function render()
                draws={};renderRects={};draw(owner,{spriteBatch={},cam={WorldToScreen=function() return v(0,0) end}})
                assert(not G.drawError,G.drawError)
            end
        """)

    def test_mixed_modules_render_their_actual_installed_colors(self):
        self.lua.execute("""
            render();local armSeen,fanSeen=false,false
            for _,path in ipairs(draws) do
                if path=='mod/Assets/Factions/coalition/suit-v2.png' then armSeen=true end
                if path=='mod/Assets/Factions/husk/impeller-housing.png' then fanSeen=true end
                assert(path~='mod/Assets/Factions/descendens/suit-v2.png','body paint overrode module paint')
            end
            assert(armSeen and fanSeen)
        """)

    def test_sprite_cache_is_bounded_and_released_on_reload(self):
        self.lua.execute("""
            local F=require('AegisSuit.factions')
            for _,key in ipairs(F.order) do
                arm={Prefab={Identifier={Value=F.id('servo',key)}}}
                motor={Prefab={Identifier={Value=F.id('impeller',key)}}}
                render()
            end
            local n=#sprites;for _=1,100 do render() end
            assert(#sprites==n and n<=15,'sprite allocation per frame')
            G.disposeClient();for _,s in ipairs(sprites) do assert(s.removed,'cached sprite leaked') end
        """)

    def test_mixed_module_draws_use_the_modules_own_frame_coordinates(self):
        self.lua.execute("""
            local F=require('AegisSuit.factions')
            arm.Prefab.Identifier.Value='aegisservomoduleclowns'
            render();local names={'upperLink','lowerLink','emitter'};local found=0
            for _,record in ipairs(renderRects) do
                if record.path=='mod/Assets/Factions/clowns/suit-v2.png' then
                    found=found+1;local r=F.frame('clowns',names[found])
                    assert(record.rect.X==r[1] and record.rect.Y==r[2])
                    assert(record.rect.Width==r[3] and record.rect.Height==r[4])
                end
            end
            assert(found==3)
        """)

    def test_helmet_animation_uses_suit_frame_for_closed_and_open(self):
        self.lua.execute("""
            local F=require('AegisSuit.factions')
            suit.Prefab.Identifier.Value='aegisservosuitclowns'
            local helmet={};E.LimbType={Head=1}
            owner.AnimController={Limbs={{type=1,WearingItems={{WearableComponent={Item=suit},Sprite=helmet}}}}}
            G.state=function() return state end
            G.updateSuitUI=function() end;G.syncSonar=function() end;G.updateLights=function() end
            E.SoundPlayer={PlaySound=function() end}
            for _,open in ipairs({false,true,false}) do
                state.open=open;G.updateClient(.1)
                local r=F.frame('clowns',open and 'helmetOpen' or 'helmetClosed')
                assert(helmet.SourceRect.X==r[1] and helmet.SourceRect.Y==r[2])
                assert(helmet.SourceRect.Width==r[3] and helmet.SourceRect.Height==r[4])
            end
        """)

    def test_removed_modules_do_not_draw_in_any_color(self):
        self.lua.execute("render();state.hasArm=false;state.hasImpeller=false;render();assert(#draws==0)")


class FactionFrameTests(unittest.TestCase):
    atlas_cells = ('torso', 'waist', 'helmetClosed', 'helmetOpen',
                   'upperArm', 'forearm', 'hand', 'thigh',
                   'calf', 'boot', 'upperLink', 'lowerLink',
                   'emitter', 'rotor', None, 'assembled')

    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("package.path=... .. '/?.lua;' .. package.path", (MOD / 'Lua').as_posix())
        self.lua.execute("F=require('AegisSuit.factions')")
        self.factions = self.lua.globals().F

    def test_palette_frames_cover_complete_parts_in_generated_images(self):
        for key in KEYS:
            with Image.open(MOD / self.factions.path(key, 'atlas')) as image:
                alpha = image.getchannel('A').point(lambda a: 255 if a > 16 else 0)
                cell_width, cell_height = image.width // 4, image.height // 4
                for cell, name in enumerate(self.atlas_cells):
                    left, top = cell % 4 * cell_width, cell // 4 * cell_height
                    box = (left, top, left + cell_width, top + cell_height)
                    bounds = alpha.crop(box).getbbox()
                    if name is None:
                        self.assertIsNone(bounds, key)
                        continue
                    self.assertIsNotNone(bounds, (key, name))
                    x, y, w, h = [self.factions.frame(key, name)[i] for i in range(1, 5)]
                    self.assertLessEqual(x, bounds[0] + box[0], (key, name, 'left'))
                    self.assertLessEqual(y, bounds[1] + box[1], (key, name, 'top'))
                    self.assertGreaterEqual(x + w, bounds[2] + box[0], (key, name, 'right'))
                    self.assertGreaterEqual(y + h, bounds[3] + box[1], (key, name, 'bottom'))

    def test_impeller_housings_leave_the_rotating_hub_visible(self):
        for key in KEYS:
            with Image.open(MOD / self.factions.path(key, 'housing')) as housing:
                width, height = housing.size
                center = round(width * .54), height // 2
                self.assertLessEqual(housing.getchannel('A').getpixel(center), 16, key)
            with Image.open(MOD / self.factions.path(key, 'impeller')) as inventory_icon:
                icon_center=round(inventory_icon.width*.54), inventory_icon.height//2
                self.assertGreater(inventory_icon.getchannel('A').getpixel(icon_center), 128, key)

    def test_wearable_rectangles_match_palette_frames(self):
        names = {'Head': 'helmetClosed', 'Torso': 'torso', 'Waist': 'waist',
                 'Arm': 'upperArm', 'Forearm': 'forearm', 'Hand': 'hand',
                 'Thigh': 'thigh', 'Leg': 'calf', 'Foot': 'boot'}
        for path in (MOD / 'aegis_suit.xml', MOD / 'aegis_factions.xml'):
            for item in ET.parse(path).getroot().findall('Item'):
                item_id = item.get('identifier')
                if not item_id.startswith('aegisservosuit'):
                    continue
                key = item_id.removeprefix('aegisservosuit') or 'pirates'
                for node in item.iter('sprite'):
                    if not node.get('texture', '').endswith('/suit-v2.png'):
                        continue
                    limb = node.get('limb', '').removeprefix('Right').removeprefix('Left')
                    name = names[limb]
                    expected = [self.factions.frame(key, name)[i] for i in range(1, 5)]
                    self.assertEqual(list(map(int, node.get('sourcerect').split(','))), expected, (key, limb))

    def test_faction_helmets_use_a_closer_fit(self):
        for filename in ('aegis_suit.xml', 'aegis_factions.xml'):
            for helmet in ET.parse(MOD / filename).findall("Item/Wearable/sprite[@name='Aegis Head']"):
                self.assertLessEqual(float(helmet.get('scale')), .67)
                self.assertEqual(helmet.get('origin'), '0.5,0.5')

    def test_profile_boots_follow_the_native_foot_angle(self):
        for filename in ('aegis_suit.xml', 'aegis_factions.xml'):
            for suit in ET.parse(MOD / filename).findall('Item'):
                identifier = suit.get('identifier', '')
                if not identifier.startswith('aegisservosuit'):
                    continue
                for limb in ('LeftFoot', 'RightFoot'):
                    foot = suit.find(f"Wearable/sprite[@name='Aegis {limb}']")
                    self.assertIsNotNone(foot, (identifier, limb))
                    self.assertEqual(float(foot.get('rotation', '0')), 0, (identifier, limb))

    def test_coalition_shoulders_share_the_atlas_without_separate_badges(self):
        suit = ET.parse(MOD / 'aegis_factions.xml').find("Item[@identifier='aegisservosuitcoalition']")
        atlas = '%ModDir%/' + self.factions.path('coalition', 'atlas')
        plates = {}
        for limb in ('LeftArm', 'RightArm', 'Torso'):
            sprites = [node for node in suit.findall('Wearable/sprite') if node.get('limb') == limb]
            self.assertEqual([node.get('name') for node in sprites], [f'Aegis {limb}'])
            self.assertEqual(sprites[0].get('texture'), atlas)
            plates[limb] = sprites[0].get('sourcerect')
        self.assertEqual(plates['LeftArm'], plates['RightArm'])


class FactionSalesTests(unittest.TestCase):
    sellers = {
        'pirates': ('merchantarmory', ''),
        'descendens': ('merchantresearch', ''),
        'coalition': ('merchantmilitary', 'coalition'),
        'separatists': ('merchantmilitary', 'separatists'),
        'husk': ('merchanthusk', 'huskcult'),
        'clowns': ('merchantclown', 'clowns'),
    }

    def setUp(self):
        self.suits = {}
        for name in ('aegis_suit.xml', 'aegis_factions.xml'):
            for item in ET.parse(MOD / name).getroot().findall('Item'):
                if item.get('identifier') in {identifier('suit', k) for k in KEYS}:
                    self.suits[item.get('identifier')] = item

    def test_each_suit_has_ten_thousand_base_price_and_one_assigned_seller(self):
        self.assertEqual(len(self.suits), 6)
        for key, (seller, faction) in self.sellers.items():
            price = self.suits[identifier('suit', key)].find('Price')
            self.assertEqual(int(price.get('baseprice')), 10000, key)
            self.assertEqual(price.get('canbespecial'), 'false', key)
            self.assertEqual([n.get('storeidentifier') for n in price], [seller], key)
            self.assertEqual(price.get('requiredfaction', ''), faction, key)
            self.assertEqual(float(price[0].get('multiplier', '1')), 1, key)
            self.assertEqual(int(price[0].get('minavailable', price.get('minavailable'))), 1)
            self.assertEqual(int(price[0].get('maxavailable', price.get('maxavailable'))), 1)

    def can_buy(self, key, store, primary, secondary=''):
        # Native PriceInfo defaults and ItemPrefab.CanBeBoughtFrom conditions.
        root = self.suits[identifier('suit', key)].find('Price')
        price = next((n for n in root if n.get('storeidentifier') == store), None)
        if price is None:
            return root.get('sold', 'true') == 'true' and root.get('soldelsewhere', root.get('soldeverywhere', 'false')) == 'true'
        sold = price.get('sold', root.get('sold', 'true')) == 'true'
        faction = price.get('requiredfaction', root.get('requiredfaction', ''))
        return sold and (not faction or faction in (primary, secondary))

    def test_store_and_location_matrix_does_not_leak_suits_to_other_merchants(self):
        stores = ('merchantarmory', 'merchantresearch', 'merchantmilitary', 'merchanthusk',
                  'merchantclown', 'merchantoutpost', 'merchantcity', 'merchantengineering',
                  'merchantmedical', 'merchantmine', 'unknownstore')
        for key, (seller, faction) in self.sellers.items():
            for store in stores:
                for primary in ('coalition', 'separatists', 'huskcult', 'clowns', ''):
                    expected = store == seller and (not faction or faction == primary)
                    self.assertEqual(self.can_buy(key, store, primary), expected, (key, store, primary))

    def test_secondary_cult_faction_allows_only_its_own_seller_and_suit(self):
        for primary in ('coalition', 'separatists'):
            self.assertTrue(self.can_buy('husk', 'merchanthusk', primary, 'huskcult'))
            self.assertFalse(self.can_buy('husk', 'merchantclown', primary, 'huskcult'))
            self.assertTrue(self.can_buy('clowns', 'merchantclown', primary, 'clowns'))
            self.assertFalse(self.can_buy('clowns', 'merchanthusk', primary, 'clowns'))
