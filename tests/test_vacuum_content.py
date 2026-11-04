import xml.etree.ElementTree as ET
from pathlib import Path
from lua_support import LuaCase, ROOT


class VacuumContentTests(LuaCase):
    def test_pack_uses_native_bag_slot_and_has_worn_torso_sprite(self):
        pack=ET.parse(ROOT/'MULTI-TOOL-V2/vacuum.xml').getroot().find("Item[@identifier='aegisvacuumpack']")
        self.assertIsNotNone(pack.find('Wearable'))
        self.assertEqual(pack.find('Wearable').get('slots'),'Bag')
        self.assertEqual(pack.find('Wearable/sprite').get('limb'),'Torso')
        self.assertNotIn('Any',pack.find('Holdable').get('slots').split(','))

    def test_separate_craftable_parts_and_vacuum_owned_battery(self):
        items={i.get('identifier'):i for i in ET.parse(ROOT/'MULTI-TOOL-V2/vacuum.xml').getroot()}
        vacuum=items['aegisvacuum'];pack=items['aegisvacuumpack'];page=items['aegisvacuumpage']
        self.assertIsNotNone(vacuum.find('Fabricate'))
        self.assertIsNotNone(pack.find('Fabricate'))
        self.assertEqual(vacuum.find('Holdable').get('slots'),'Any,RightHand+LeftHand')
        self.assertEqual(vacuum.find('ItemContainer/Containable').get('items'),'mobilebattery')
        self.assertEqual(pack.find('ItemContainer/Containable').get('items'),'aegisvacuumpage')
        self.assertEqual(page.find('ItemContainer').get('capacity'),'100')
        self.assertEqual(page.find('ItemContainer').get('maxstacksize'),'1')
        self.assertIsNone(page.find('Fabricate'))

    def test_all_three_original_assets_have_real_alpha(self):
        from PIL import Image
        for name in ('backpack','vacuum','suction'):
            with Image.open(ROOT/f'MULTI-TOOL-V2/Assets/Vacuum/{name}.png') as img:
                self.assertEqual(img.mode,'RGBA')
                low,high=img.getchannel('A').getextrema()
                self.assertEqual(low,0)
                self.assertGreater(high,0)

    def test_package_loads_vacuum_and_localized_names(self):
        manifest=ET.parse(ROOT/'MULTI-TOOL-V2/filelist.xml').getroot()
        self.assertIn('%ModDir%/vacuum.xml',[i.get('file') for i in manifest])
        for language in ('Polish','English'):
            root=ET.parse(ROOT/f'MULTI-TOOL-V2/{language}.xml').getroot()
            for tag in ('entityname.aegisvacuum','entityname.aegisvacuumpack'):
                self.assertTrue(root.find(tag).text)
