import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


class CombatContentTests(unittest.TestCase):
    def test_aiming_has_native_crosshair_and_hud_enabled(self):
        item=ET.parse(ROOT/'MULTI-TOOL-V2/combat_tool.xml').getroot().find('Item')
        ranged=item.find('RangedWeapon')
        self.assertEqual(ranged.get('drawhudwhenequipped'),'true')
        self.assertIsNotNone(ranged.find('Crosshair'))
        self.assertIsNotNone(ranged.find('CrosshairPointer'))

    def test_one_shared_power_slot(self):
        item=ET.parse(ROOT/'MULTI-TOOL-V2/combat_tool.xml').getroot().find('Item')
        container=item.find('ItemContainer')
        self.assertEqual(container.get('capacity'),'1')
        self.assertEqual(len(container.findall('SlotIcon')),1)

    def test_weapon_rig_matches_lower_grips_and_inset_lamp(self):
        item=ET.parse(ROOT/'MULTI-TOOL-V2/combat_tool.xml').getroot().find('Item')
        self.assertLess(float(item.get('scale')),.075)
        hold=item.find('Holdable')
        for attribute in ('handle1','handle2'):
            self.assertLess(float(hold.get(attribute).split(',')[1]),0,'grips lie below sprite center')
        lamp=item.findall('LightComponent')[1]
        x,y=map(float,lamp.get('lightoffset').split(','))
        self.assertLess(x,750,'lamp lens is behind energy muzzle')
        self.assertLess(y,0,'lamp is below barrel')
        self.assertEqual(item.find('Sprite').get('compress'),'false')
        for tool in item.findall('RepairTool'):
            x,y=map(float,tool.get('barrelpos').split(','))
            self.assertLess(abs(x),80,'RepairTool barrel position uses display units, not source pixels')

    def test_flashlight_uses_native_directional_cone(self):
        item=ET.parse(ROOT/'MULTI-TOOL-V2/combat_tool.xml').getroot().find('Item')
        light=item.findall('LightComponent')[1]
        self.assertEqual(light.get('directional'),'true')
        self.assertEqual(light.find('LightTexture').get('texture'),'Content/Lights/lightcone.png')
        self.assertEqual(light.find('LightTexture').get('origin'),'0.0,0.5')
        self.assertIn('lightcolor',light.attrib)
