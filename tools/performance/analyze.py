"""Run-scoped native performance evidence; slow servers remain valid results."""
import argparse
import csv
import json
import math
from pathlib import Path


def statistics(samples):
    values = sorted(samples)
    if not values or any(not math.isfinite(v) or v < 0 for v in values):
        raise ValueError('Expected finite, nonnegative timing samples')
    mean = sum(values) / len(values)
    return {'samples': len(values), 'mean_ms': mean,
            **{f'p{p}_ms': values[max(0, math.ceil(len(values) * p / 100) - 1)] for p in (50, 95, 99)},
            'max_ms': values[-1], 'rate': 1000 / mean if mean else 0}


def records(path):
    if not path.exists():
        return {}
    rows = [json.loads(line) for line in path.read_text(encoding='utf-8-sig').splitlines() if line.strip()]
    return {row['phase']: row for row in rows}


def collect(folder):
    folder = Path(folder)
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    activity = records(folder / 'activity.jsonl')
    roles = {role: records(folder / f'{role}.jsonl') for role in manifest.get('measurement_roles', ('server', 'A', 'B'))}
    replicas = {role: records(folder / f'{role}-evidence.jsonl') for role in ('A', 'B')}
    process_path = folder / 'process.jsonl'
    processes = [json.loads(line) for line in process_path.read_text(encoding='utf-8').splitlines() if line.strip()] if process_path.exists() else []
    rows = []
    expected = manifest['phase_seconds'] - manifest['warmup_seconds']
    for phase in manifest['phases']:
        name = phase['id']
        proof = activity.get(name)
        for role, samples in roles.items():
            sample = samples.get(name)
            reasons = []
            if name in manifest.get('excluded_phases', {}):
                reasons.append('operator exclusion: ' + manifest['excluded_phases'][name])
            if sample is None:
                reasons.append('missing native phase')
            if proof is None:
                reasons.append('missing activity evidence')
            elif not proof.get('valid'):
                reasons.append(proof.get('reason') or 'activity validation failed')
            if role != 'server' and manifest.get('require_client_evidence'):
                replica = replicas[role].get(name)
                if not replica:
                    reasons.append('missing replica activity evidence')
                elif not replica.get('controlled') or replica.get('draw_error') or replica.get('samples', 0) < 10:
                    reasons.append('replica failed or not controlled')
                elif replica.get('equipped_samples', 0) < replica['samples'] * .9:
                    reasons.append('replica did not receive equipped items')
                elif manifest.get('require_replica_health') and phase['mode'] not in ('heal', 'hit', 'pressure') and replica.get('can_interact_samples', 0) < replica['samples'] * .9:
                    reasons.append('replica fixture remained incapacitated')
                elif phase['count'] >= (1 if role == 'A' else 2):
                    if phase['mode'] == 'panel' and replica.get('panel_snapshots', 0) == 0:
                        reasons.append('replica panel received no snapshots')
                    if phase['mode'] == 'sonar' and replica.get('sonar_visible', 0) < replica['samples'] * .9:
                        reasons.append('replica sonar not powered and visible')
            prefix = 'tick_ms' if role == 'server' else 'frame_ms'
            if sample:
                if manifest.get('require_native_marker') and not sample.get('marker_events'):
                    reasons.append('native phase marker hook did not run')
                seconds = sample.get('sample_seconds', 0)
                if abs(seconds - expected) > max(2, expected * .1):
                    reasons.append('incomplete measurement window')
                if sample.get(prefix + '_n', 0) < 10:
                    reasons.append('too few native samples')
                for suffix in ('mean', 'p95', 'p99', 'max'):
                    value = sample.get(prefix + '_' + suffix)
                    if value is None or not math.isfinite(value) or value < 0:
                        reasons.append('invalid timing ' + suffix)
            row = {'phase': name, 'item': phase['item'], 'mode': phase['mode'],
                   'count': phase['count'], 'role': role,
                   'valid': not reasons, 'reason': '; '.join(reasons)}
            for field, suffix in (('samples', 'n'), ('mean_ms', 'mean'), ('p50_ms', 'p50'),
                                  ('p95_ms', 'p95'), ('p99_ms', 'p99'), ('max_ms', 'max')):
                row[field] = sample.get(prefix + '_' + suffix, 0) if sample else 0
            row['rate'] = (row['samples'] / max(.001, sample.get('sample_seconds', 0)) if role == 'server'
                           else 1000 / max(.001, row['mean_ms'])) if sample else 0
            for module in ('suit', 'combat', 'vacuum', 'headsets'):
                row[module + '_controller_mean_ms'] = (proof.get('controller_ms', {}).get(module, 0) /
                    max(1, proof.get('module_calls', {}).get(module, 0))) if proof and role == 'server' else 0
            process = [p for p in processes if p['phase'] == name and p['role'] == role
                       and p.get('phase_age_s', 0) >= manifest['warmup_seconds']]
            cpu = [p['cpu_one_core_percent'] for p in process if p.get('cpu_one_core_percent') is not None]
            row['cpu_one_core_percent'] = sum(cpu) / len(cpu) if cpu else None
            row['rss_peak_mb'] = max((p['rss_mb'] for p in process), default=None)
            row['private_peak_mb'] = max((p['private_mb'] for p in process), default=None)
            row['native_send_calls'] = proof.get('native_send_calls') if proof and role == 'server' else None
            row['native_payload_bytes'] = proof.get('native_payload_bytes') if proof and role == 'server' else None
            row['network_error'] = proof.get('network_error', '') if proof and role == 'server' else ''
            rows.append(row)
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    rows = collect(args.run)
    with (args.run / 'summary.csv').open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    valid = sum(row['valid'] for row in rows)
    print(f'{valid}/{len(rows)} valid role/phase results; {args.run / "summary.csv"}')
    for row in rows:
        if not row['valid']:
            print(row['role'], row['phase'], row['reason'])
    return 0 if valid == len(rows) else 1


if __name__ == '__main__':
    raise SystemExit(main())
