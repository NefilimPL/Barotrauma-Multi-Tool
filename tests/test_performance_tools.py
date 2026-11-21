import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import sys
from unittest.mock import patch, Mock
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]


def load_analyzer():
    spec = importlib.util.spec_from_file_location('performance_analyze', ROOT / 'tools/performance/analyze.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PerformanceAnalysisTests(unittest.TestCase):
    def setUp(self):
        self.module = load_analyzer()

    def test_percentiles_and_fps_use_frame_intervals(self):
        result = self.module.statistics([10, 10, 20, 100])
        self.assertEqual(result['p50_ms'], 10)
        self.assertEqual(result['p95_ms'], 100)
        self.assertEqual(result['max_ms'], 100)
        self.assertAlmostEqual(result['mean_ms'], 35)
        self.assertAlmostEqual(result['rate'], 1000 / 35)

    def fixture(self, folder, active=True, evidence=True, ups=40):
        manifest = {'phase_seconds': 30, 'warmup_seconds': 5,
                    'phases': [{'id': 'repair_1_r1', 'item': 'aegisservosuit',
                                'mode': 'repair', 'count': 1, 'active': active}]}
        (folder / 'manifest.json').write_text(json.dumps(manifest), encoding='utf-8')
        for role in ('server', 'A', 'B'):
            row = {'phase': 'repair_1_r1', 'sample_seconds': 25,
                   'tick_ms_n': ups * 25, 'tick_ms_mean': 8, 'tick_ms_p95': 25,
                   'tick_ms_p99': 40, 'tick_ms_max': 60,
                   'frame_ms_n': 2500, 'frame_ms_mean': 10, 'frame_ms_p95': 12,
                   'frame_ms_p99': 20, 'frame_ms_max': 50}
            (folder / f'{role}.jsonl').write_text(json.dumps(row) + '\n', encoding='utf-8')
        activity = {'phase': 'repair_1_r1', 'valid': evidence,
                    'reason': '' if evidence else 'wearer 1 did no work',
                    'work': [100 if evidence else 0]}
        (folder / 'activity.jsonl').write_text(json.dumps(activity) + '\n', encoding='utf-8')

    def test_slow_server_is_retained_as_valid_result(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder, ups=40)
            rows = self.module.collect(folder)
            server = next(row for row in rows if row['role'] == 'server')
            self.assertTrue(server['valid'])
            self.assertEqual(server['rate'], 40)
            self.assertEqual(server['p99_ms'], 40)

    def test_inactive_active_phase_is_explicitly_invalid(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder, evidence=False)
            rows = self.module.collect(folder)
            self.assertTrue(all(not row['valid'] for row in rows))
            self.assertTrue(all('no work' in row['reason'] for row in rows))

    def test_operator_interference_excludes_a_phase_even_with_valid_work(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder)
            path = folder / 'manifest.json'
            manifest = json.loads(path.read_text())
            manifest['excluded_phases'] = {'repair_1_r1': 'read-only diagnostics during measured window'}
            path.write_text(json.dumps(manifest))
            rows = self.module.collect(folder)
            self.assertTrue(all(not row['valid'] for row in rows))
            self.assertTrue(all('diagnostics' in row['reason'] for row in rows))

    def test_missing_client_or_phase_is_reported_without_discarding_other_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder)
            (folder / 'B.jsonl').unlink()
            rows = self.module.collect(folder)
            missing = next(row for row in rows if row['role'] == 'B')
            self.assertFalse(missing['valid'])
            self.assertIn('missing', missing['reason'])
            self.assertTrue(next(row for row in rows if row['role'] == 'A')['valid'])

    def test_incomplete_wall_clock_window_cannot_pass_on_high_fps(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder)
            path = folder / 'A.jsonl'
            row = json.loads(path.read_text())
            row['sample_seconds'] = 5
            path.write_text(json.dumps(row) + '\n')
            result = next(row for row in self.module.collect(folder) if row['role'] == 'A')
            self.assertFalse(result['valid'])
            self.assertIn('window', result['reason'])

    def test_required_replica_evidence_cannot_be_replaced_by_server_activity(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder)
            path = folder / 'manifest.json'
            manifest = json.loads(path.read_text())
            manifest['require_client_evidence'] = True
            path.write_text(json.dumps(manifest))
            rows = self.module.collect(folder)
            self.assertTrue(next(row for row in rows if row['role'] == 'server')['valid'])
            self.assertFalse(next(row for row in rows if row['role'] == 'A')['valid'])
            self.assertIn('replica', next(row for row in rows if row['role'] == 'A')['reason'])

    def test_incapacitated_client_does_not_validate_a_healthy_workload(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder)
            path = folder / 'manifest.json'
            manifest = json.loads(path.read_text())
            manifest.update(require_client_evidence=True, require_replica_health=True)
            path.write_text(json.dumps(manifest))
            for role in ('A', 'B'):
                (folder / f'{role}-evidence.jsonl').write_text(json.dumps({'phase': 'repair_1_r1',
                    'controlled': 1, 'samples': 100, 'equipped_samples': 100, 'can_interact_samples': 0}))
            row = next(r for r in self.module.collect(folder) if r['role'] == 'A')
            self.assertFalse(row['valid'])
            self.assertIn('incapacitated', row['reason'])

    def test_explicit_server_only_cohort_does_not_invent_client_results(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            self.fixture(folder)
            path = folder / 'manifest.json'
            manifest = json.loads(path.read_text())
            manifest['measurement_roles'] = ['server']
            path.write_text(json.dumps(manifest))
            rows = self.module.collect(folder)
            self.assertEqual([r['role'] for r in rows], ['server'])
            self.assertTrue(rows[0]['valid'])

    def compare_module(self):
        sys.path.insert(0, str(ROOT / 'tools/performance'))
        try:
            spec = importlib.util.spec_from_file_location('performance_compare', ROOT / 'tools/performance/compare.py')
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            return module
        finally:
            sys.path.pop(0)

    def test_comparison_rejects_different_native_scenes(self):
        with tempfile.TemporaryDirectory() as tmp:
            before, after = Path(tmp) / 'before', Path(tmp) / 'after'
            for folder, seed in ((before, 'a'), (after, 'b')):
                folder.mkdir()
                self.fixture(folder)
                (folder / 'scene.json').write_text(json.dumps({'seed': seed}), encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'scene'):
                self.compare_module().compare(before, after)

    def test_comparison_rejects_changed_additional_fixture_script(self):
        with tempfile.TemporaryDirectory() as tmp:
            before, after = Path(tmp) / 'before', Path(tmp) / 'after'
            for folder, digest in ((before, 'original'), (after, 'changed')):
                folder.mkdir()
                self.fixture(folder)
                path = folder / 'manifest.json'
                manifest = json.loads(path.read_text())
                manifest['fixture'] = {'source_sha256': digest, 'count': 300}
                path.write_text(json.dumps(manifest))
            with self.assertRaisesRegex(ValueError, 'fixture'):
                self.compare_module().compare(before, after)

    def test_comparison_rejects_server_only_vs_two_clients(self):
        with tempfile.TemporaryDirectory() as tmp:
            before, after = Path(tmp) / 'before', Path(tmp) / 'after'
            for folder in (before, after):
                folder.mkdir()
                self.fixture(folder)
            path = after / 'manifest.json'
            manifest = json.loads(path.read_text())
            manifest['measurement_roles'] = ['server']
            path.write_text(json.dumps(manifest))
            with self.assertRaisesRegex(ValueError, 'roles'):
                self.compare_module().compare(before, after)

    def runner_module(self):
        spec = importlib.util.spec_from_file_location('performance_runner', ROOT / 'tools/performance/run_native.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_optional_package_missing_on_one_role_fails_before_launch(self):
        module = self.runner_module()
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            with self.assertRaises(FileNotFoundError):
                module.package_settings(folder, ['LocalMods/missing/filelist.xml'], False)

    def test_package_inventory_preserves_load_order_and_exact_versions(self):
        module = self.runner_module()
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for relative, name in [('LocalMods/NT/filelist.xml', 'Neurotrauma'),
                                   ('LocalMods/System-Aegis/filelist.xml', 'System Aegis')]:
                target = folder / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(f'<contentpackage name="{name}" modversion="2"/>')
            settings, inventory = module.package_settings(folder, ['LocalMods/NT/filelist.xml'], False)
            self.assertEqual([p.attrib['path'] for p in settings.find('regularpackages')],
                             ['LocalMods/NT/filelist.xml', 'LocalMods/System-Aegis/filelist.xml'])
            self.assertEqual([p['name'] for p in inventory], ['Neurotrauma', 'System Aegis'])
            self.assertTrue(all(p['modversion'] == '2' and len(p['filelist_sha256']) == 64 for p in inventory))

    def test_active_user_game_stops_runner_before_changing_any_installation(self):
        module = self.runner_module()
        with patch.object(sys, 'argv', ['run_native.py', '--label', 'preflight-test']), \
             patch.object(module.subprocess, 'run', return_value=SimpleNamespace(stdout='"Barotrauma.exe","55588","Console","1","123 K"\n')), \
             patch.object(module, 'prepare', side_effect=AssertionError('reached mutable preparation before checking active games')) as prepare, \
             patch.object(module.Path, 'mkdir') as mkdir:
            with self.assertRaisesRegex(RuntimeError, '55588'):
                module.main()
            prepare.assert_not_called()
            mkdir.assert_not_called()

    def test_evidence_copy_failure_still_reaps_every_owned_process(self):
        module = self.runner_module()
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            (folder / 'aegis-perf-metrics.jsonl').write_text('{}')
            processes = {role: Mock() for role in ('server', 'A', 'B')}
            for process in processes.values():
                process.poll.return_value = None
                process.wait.return_value = 0
            streams, monitor = [Mock(), Mock()], Mock()
            monitor.wait.return_value = 0
            with patch.object(module, 'ROLES', {role: folder for role in processes}), \
                 patch.object(module.shutil, 'copy2', side_effect=OSError('copy failed')):
                with self.assertRaisesRegex(OSError, 'copy failed'):
                    module.finalize_run(folder, {}, processes, streams, monitor)
            for process in processes.values():
                process.terminate.assert_called_once()
                process.wait.assert_called()
            for stream in streams:
                stream.close.assert_called_once()
            monitor.wait.assert_called()


if __name__ == '__main__':
    unittest.main()
