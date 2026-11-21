import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'System-Aegis'


class AegisPackageTests(unittest.TestCase):
    def manifest(self):
        self.assertTrue((MOD / 'filelist.xml').is_file(), 'System Aegis package is missing')
        return ET.parse(MOD / 'filelist.xml').getroot()

    def test_separate_release_has_its_own_identity(self):
        manifest = self.manifest()
        self.assertEqual(manifest.get('name'), 'System Aegis')
        self.assertIn(manifest.get('steamworkshopid', ''), ('', '0'))
        self.assertEqual(manifest.get('corepackage', '').lower(), 'false')

    def test_manifest_registers_every_content_definition(self):
        manifest = self.manifest()
        registered = {n.get('file').removeprefix('%ModDir%/') for n in manifest}
        self.assertEqual(registered, {p.name for p in MOD.glob('*.xml') if p.name != 'filelist.xml'})
        for name in registered:
            self.assertTrue((MOD / name).is_file(), name)

    def test_all_custom_prefabs_have_aegis_identifiers(self):
        self.manifest()
        identifiers = []
        for path in MOD.glob('*.xml'):
            root = ET.parse(path).getroot()
            for node in list(root):
                if node.tag in ('Item', 'Affliction') and node.get('identifier'):
                    identifiers.append(node.get('identifier'))
        self.assertEqual(len(identifiers), len(set(i.lower() for i in identifiers)))
        self.assertGreaterEqual(len(identifiers), 23)
        self.assertIn('aegisservosuit', identifiers)
        for identifier in identifiers:
            self.assertTrue(identifier.startswith('aegis'), identifier)

    def test_spawn_documentation_names_existing_items(self):
        self.manifest()
        ids = {n.get('identifier') for p in MOD.glob('*.xml')
               for n in ET.parse(p).getroot().findall('Item') if n.get('identifier')}
        public = {n.get('identifier') for p in MOD.glob('*.xml')
                  for n in ET.parse(p).getroot().findall('Item')
                  if n.get('identifier') and n.get('hideinmenus', '').lower() != 'true'}
        for name in ('README.md', 'docs/spawn-commands.txt', 'docs/PUBLISH.md'):
            text = (ROOT / name).read_text(encoding='utf-8')
            mentioned = set(re.findall(r'\baegis[a-z0-9]+\b', text))
            self.assertTrue(mentioned <= ids, (name, mentioned - ids))
            self.assertTrue(public <= mentioned, (name, public - mentioned))

    def test_public_items_have_branded_english_and_polish_names(self):
        self.manifest()
        for language in ('English', 'Polish'):
            texts = {}
            for path in MOD.glob('*.xml'):
                root = ET.parse(path).getroot()
                if root.tag == 'infotexts' and root.get('language') == language:
                    texts.update((n.tag, n.text) for n in root)
            for path in MOD.glob('*.xml'):
                for item in ET.parse(path).getroot().findall('Item'):
                    if not item.get('identifier') or item.get('hideinmenus', '').lower() == 'true':
                        continue
                    key = 'entityname.' + item.get('identifier')
                    self.assertIn(key, texts, (language, key))
                    self.assertIn('Aegis', texts[key], (language, key))

    def test_lua_modules_resolve_with_exact_filename_case(self):
        self.manifest()
        for path in (MOD / 'Lua').rglob('*.lua'):
            for module in re.findall(r"require\(['\"]([^'\"]+)['\"]\)", path.read_text(encoding='utf-8')):
                relative = Path(*module.split('.')).with_suffix('.lua')
                self.assertTrue((MOD / 'Lua' / relative).is_file(), (path, module))
                actual = (MOD / 'Lua' / relative).resolve().relative_to((MOD / 'Lua').resolve())
                self.assertEqual(actual.as_posix(), relative.as_posix())


if __name__ == '__main__':
    unittest.main()
