import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


class CombatContentTests(unittest.TestCase):
    def test_flashlight_uses_native_directional_cone(self):
        item=ET.parse(ROOT/'MULTI-TOOL-V2/combat_tool.xml').getroot().find('Item')
        light=item.findall('LightComponent')[1]
        self.assertEqual(light.get('directional'),'true')
        self.assertEqual(light.find('LightTexture').get('texture'),'Content/Lights/lightcone.png')
        self.assertEqual(light.find('LightTexture').get('origin'),'0.0,0.5')
        self.assertIn('lightcolor',light.attrib)
