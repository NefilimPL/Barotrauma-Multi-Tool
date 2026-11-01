import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'MULTI-TOOL-V2'


class HeadsetContentTests(unittest.TestCase):
    def test_external_headset_emitters_are_not_hidden_by_headgear(self):
        for item in ET.parse(MOD / 'regenerative_headsets.xml').getroot().findall('Item'):
            self.assertEqual(item.find('Wearable/sprite').get('canbehiddenbyotherwearables'), 'false')

    def test_worn_sprite_is_head_sized_without_multiplying_item_scale(self):
        for item in ET.parse(MOD / 'regenerative_headsets.xml').getroot().findall('Item'):
            sprite = item.find('Wearable/sprite')
            height = int(sprite.get('sourcerect').split(',')[3])
            native_height = height * float(sprite.get('scale', '1'))
            self.assertGreaterEqual(native_height, 25)
            self.assertLessEqual(native_height, 50, 'native wearable scale does not include Item.Scale')

    def test_both_items_have_native_unpowered_radio_and_headset_slot(self):
        items = ET.parse(MOD / 'regenerative_headsets.xml').getroot().findall('Item')
        self.assertEqual({i.get('identifier') for i in items}, {'aegisheadset', 'aegisheadsetmk2'})
        for item in items:
            wifi = item.find('WifiComponent')
            self.assertEqual(float(wifi.get('range')), 35000)
            self.assertEqual(wifi.get('LinkToChat').lower(), 'true')
            self.assertIsNone(wifi.find('RequiredItems'))
            self.assertEqual(item.find('Wearable').get('slots'), 'Any,Headset')
            self.assertEqual(item.find('ItemContainer').get('capacity'), '1')
            self.assertEqual(item.find('ItemContainer/Containable').get('items'), 'mobilebattery')

    def test_manifest_has_devices_and_sounds_without_medical_dependencies(self):
        manifest = ET.parse(MOD / 'filelist.xml').getroot()
        refs = [i.get('file', '') for i in manifest]
        self.assertIn('%ModDir%/regenerative_headsets.xml', refs)
        self.assertIn('%ModDir%/headset_sounds.xml', refs)
        self.assertFalse(any('neurotrauma' in r.lower() for r in refs))
        self.assertFalse(manifest.findall('RequiredContentPackage'))

    def test_localized_names_describe_optional_medical_support(self):
        for language in ['Polish.xml', 'English.xml']:
            root = ET.parse(MOD / language).getroot()
            for identifier in ['aegisheadset', 'aegisheadsetmk2']:
                self.assertTrue(root.findtext('entityname.' + identifier))
                self.assertTrue(root.findtext('entitydescription.' + identifier))

    def test_three_power_tiers_and_poweroff_have_real_ogg_files(self):
        sounds = ET.parse(MOD / 'headset_sounds.xml').getroot()
        self.assertEqual({s.get('identifier') for s in sounds},
                         {'aegis_headset_high', 'aegis_headset_low', 'aegis_headset_critical', 'aegis_headset_empty',
                          'aegis_headset_warning_low', 'aegis_headset_warning_critical', 'aegis_headset_warning_empty'})
        for sound in sounds:
            self.assertEqual(sound.tag, sound.get('identifier'), 'SoundPlayer uses the XML element name as its tag')
            file = MOD / sound.get('file').replace('%ModDir%/', '')
            self.assertTrue(file.read_bytes().startswith(b'OggS'))
