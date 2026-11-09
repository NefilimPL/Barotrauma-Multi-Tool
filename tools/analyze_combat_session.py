"""Collect native two-client combat evidence without changing the game package."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/combat/two-client'
PHASES = [
    'single_idle', 'single_fire_A', 'single_fire_B',
    'cluster_idle', 'cluster_fire_A', 'cluster_fire_B',
    'live_single_idle', 'live_single_A', 'live_cluster_idle', 'live_cluster_A',
    'mass_idle_A', 'mass_block_A', 'mass_idle_B', 'mass_block_B',
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for client in ('A', 'B'):
        folder = ROOT / '.runtime/vacuum-clients' / client
        values = [json.loads(line) for line in (folder / 'combat-session-metrics.jsonl').read_text().splitlines()]
        phases = {value['phase']: value for value in values}
        selected = []
        for phase in PHASES:
            value = phases[phase]
            assert value['frame_ms_n'] >= 500, (client, phase, 'too few frames')
            assert 14000 < value['frame_ms_n'] * value['frame_ms_mean'] < 16000, (client, phase, 'incomplete sample')
            events = folder / f'LocalMods/MULTI-TOOL-V2/combat-session-events-{phase}.txt'
            text = events.read_text(encoding='utf-8-sig')
            assert 'authority=false' in text and 'visualError=nil' in text, (client, phase, text)
            assert 'controlled=nil' not in text, (client, phase, 'lost controlled character')
            (OUT / f'client-{client}-events-{phase}.txt').write_text(text, encoding='utf-8')
            selected.append(value)
            rows.append({
                'client': client, 'phase': phase, 'frames': value['frame_ms_n'],
                'fps_mean': round(1000 / value['frame_ms_mean'], 2),
                'frame_mean_ms': value['frame_ms_mean'], 'frame_p95_ms': value['frame_ms_p95'],
                'frame_p99_ms': value['frame_ms_p99'], 'frame_max_ms': value['frame_ms_max'],
                'draw_mean_ms': value['draw_ms_mean'], 'update_mean_ms': value['update_ms_mean'],
                'frames_over_33ms': value['frames_over_33ms'], 'frames_over_50ms': value['frames_over_50ms'],
            })
        (OUT / f'client-{client}-metrics.jsonl').write_text(''.join(json.dumps(value) + '\n' for value in selected), encoding='utf-8')
    with (OUT / 'summary.csv').open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
    server = ROOT / '.runtime/server/LocalMods/MULTI-TOOL-V2'
    counters = {}
    for source in ('combat-session-server.txt', 'combat-session-followup.txt', 'combat-session-shield-stress.txt'):
        content = (server / source).read_text(encoding='utf-8-sig')
        (OUT / source).write_text(content, encoding='utf-8')
        for line in content.splitlines():
            record = dict(token.split('=', 1) for token in line.split())
            counters[record['phase']] = record
    for phase in ('single_fire_A', 'single_fire_B', 'cluster_fire_A', 'cluster_fire_B', 'live_single_A', 'live_cluster_A'):
        assert int(counters[phase]['hit']) >= 35, (phase, 'missing actual hits')
    for phase in ('mass_block_A', 'mass_block_B'):
        value = counters[phase]
        assert int(value['nativeShots']) >= 200 and int(value['shieldhit']) >= 200, value
        assert int(value['activeShieldTicks']) >= 1000 and int(value.get('deadTicks', 0)) == 0, value
    for phase in ('live_single_A', 'live_cluster_A', 'mass_block_A', 'mass_block_B'):
        print(phase, [(row['client'], row['fps_mean'], row['frame_p95_ms']) for row in rows if row['phase'] == phase])
    print(f'Verified {len(PHASES)} phases on each of two real clients; actual hit/shield counters valid.')


if __name__ == '__main__':
    main()
