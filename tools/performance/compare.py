"""Compare repeated, valid native phases from two recorded runs."""
import argparse
from collections import defaultdict
import json
from pathlib import Path
from statistics import median

from analyze import collect


def compare(before, after):
    manifests = [json.loads((Path(folder) / 'manifest.json').read_text(encoding='utf-8')) for folder in (before, after)]
    probes_match = bool(manifests[0].get('probes')) and manifests[0].get('probes') == manifests[1].get('probes')
    if manifests[0].get('probes') and manifests[1].get('probes') and not probes_match:
        raise ValueError('Probe cohorts differ; repeat the workloads with identical probes')
    if manifests[0].get('fixture') != manifests[1].get('fixture'):
        raise ValueError('Additional native fixture scripts or parameters differ')
    if any(manifests[0][key] != manifests[1][key] for key in ('phase_seconds', 'warmup_seconds')):
        raise ValueError('Measurement windows differ')
    roles = [m.get('measurement_roles', ['server', 'A', 'B']) for m in manifests]
    if set(roles[0]) != set(roles[1]):
        raise ValueError('Measurement roles differ; server-only and multiplayer are separate cohorts')
    scenes = []
    for folder in (before, after):
        path = Path(folder) / 'scene.json'
        scenes.append(json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else None)
    scenes_match = scenes[0] is not None and scenes[0] == scenes[1]
    if all(scene is not None for scene in scenes) and not scenes_match:
        raise ValueError('Native scenes differ; repeat with the same seed and fixture')
    groups = []
    invalid = []
    for folder in (before, after):
        group = defaultdict(list)
        for row in collect(folder):
            if not row['valid']:
                invalid.append({'run': Path(folder).name, 'phase': row['phase'], 'role': row['role'], 'reason': row['reason']})
                continue
            key = row['phase'].rsplit('_r', 1)[0], row['role']
            group[key].append(row)
        groups.append(group)
    comparisons = []
    for key in sorted(groups[0].keys() & groups[1].keys()):
        a, b = groups[0][key], groups[1][key]
        item = {'scenario': key[0], 'role': key[1], 'before_repeats': len(a), 'after_repeats': len(b),
                'repeated': len(a) >= 3 and len(b) >= 3}
        for metric in ('rate', 'mean_ms', 'p95_ms', 'p99_ms', 'max_ms', 'cpu_one_core_percent', 'rss_peak_mb',
                       'suit_controller_mean_ms', 'combat_controller_mean_ms', 'headsets_controller_mean_ms',
                       'vacuum_controller_mean_ms', 'native_send_calls', 'native_payload_bytes'):
            for label, values in (('before', a), ('after', b)):
                samples = [row[metric] for row in values if row.get(metric) is not None]
                item[label + '_' + metric] = median(samples) if samples else None
        for label, values in (('before', a), ('after', b)):
            item[label + '_mean_ms_range'] = [min(r['mean_ms'] for r in values), max(r['mean_ms'] for r in values)]
        item['time_change_percent'] = (item['after_mean_ms'] / max(.000001, item['before_mean_ms']) - 1) * 100
        comparisons.append(item)
    return {'before': str(before), 'after': str(after), 'probes_verified': probes_match, 'scenes_verified': scenes_match,
            'comparisons': comparisons, 'invalid': invalid,
            'unmatched_before': sorted(f'{k[1]}:{k[0]}' for k in groups[0].keys() - groups[1].keys()),
            'unmatched_after': sorted(f'{k[1]}:{k[0]}' for k in groups[1].keys() - groups[0].keys())}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    args = parser.parse_args()
    result = compare(args.before, args.after)
    output = args.after / 'comparison.json'
    output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print('Probe manifests match:', result['probes_verified'])
    for row in result['comparisons']:
        if row['role'] != 'B':
            print(f"{row['role']:6} {row['scenario']:48} {row['before_mean_ms']:.3f} -> {row['after_mean_ms']:.3f} ms ({row['time_change_percent']:+.1f}%), repeats={row['before_repeats']}/{row['after_repeats']}")
    print(output)


if __name__ == '__main__':
    main()
