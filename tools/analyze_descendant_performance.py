"""Validate and export the native 1.3.17 two-client suit benchmark."""
import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/descendant-suit/performance'
PHASES = [
    'idle_observer', 'repair_1', 'combat_1', 'grip_1',
    'idle_1', 'repair_2a', 'idle_2', 'combat_2a', 'idle_3', 'grip_2a',
    'idle_4', 'sonar_2', 'idle_5', 'repair_2b', 'idle_6', 'combat_2b',
    'idle_7', 'repair_8', 'idle_8', 'combat_8', 'combat_8_sonar', 'idle_final',
]


def read(path):
    data = path.read_bytes()
    return data.decode('utf-16' if data.startswith(b'\xff\xfe') else 'utf-8-sig').replace('\r\n','\n')


def records(text):
    return {row['phase']: row for line in text.splitlines() if line.startswith('phase=')
            for row in [dict(token.split('=', 1) for token in line.split())]}


def collect(partial=False):
    source = ROOT / '.runtime/descendant-native/LocalMods/MULTI-TOOL-V2/descendant-perf-server.txt'
    server_text = read(source)
    server = records(server_text)
    rows, selected, events = [], {}, {}
    if not partial:
        assert 'RESULT phases=22 clients=2 production=1.3.17' in server_text, 'server run incomplete'
    phases = [phase for phase in PHASES if phase in server] if partial else PHASES
    for phase in phases:
        s = server[phase]
        assert 24 < float(s['seconds']) < 27, (phase, 'wrong duration')
        assert float(s['ups']) > 55, (phase, 'server slow', s['ups'])
        assert int(s['updates']) > 1300, (phase, 'too few server updates')
        if phase.startswith('repair'):
            assert float(s['repaired']) > 50, (phase, 'no native repairs')
            assert float(s['active_mean']) > .1, (phase, 'inactive repair')
            if phase=='repair_8': assert float(s['active_mean'])>4, (phase,'stress did not activate multiple wearers')
        elif phase.startswith('combat'):
            assert int(s['shots']) > 20, (phase, 'no sustained native shots')
            if phase.startswith('combat_8'): assert int(s['shots'])>300, (phase,'not multiple-wearer sustained fire')
        elif phase.startswith('grip'):
            expected=1 if phase=='grip_1' else 2
            assert float(s['grip_mean']) > expected*.9, (phase, 'no sustained native hold')
        elif phase.startswith('idle'):
            assert float(s['active_mean']) < .1, (phase, 'baseline has active work')
    for role in ('A', 'B'):
        folder = ROOT / '.runtime/vacuum-clients' / role
        all_metrics = [json.loads(line) for line in read(folder/'descendant-perf-metrics.jsonl').splitlines()]
        metrics = {value['phase']: value for value in all_metrics}
        client_text = read(folder/'LocalMods/MULTI-TOOL-V2/descendant-perf-client.txt')
        client = records(client_text)
        validation_path=folder/'LocalMods/MULTI-TOOL-V2/descendant-perf-validation-client.txt'
        validation=records(read(validation_path)) if validation_path.exists() else {}
        if not partial:
            for phase in ('sonar_2','combat_8_sonar'):
                v=validation[phase];n=int(v['samples'])
                assert n>1200 and int(v['powered'])>n*.95 and int(v['visible'])>n*.95, (role,phase,'sonar not powered/visible',v)
        selected[role] = []
        events[role] = client_text
        for phase in phases:
            if partial and (phase not in metrics or phase not in client):
                continue
            m, e = metrics[phase], client[phase]
            assert m['frame_ms_n'] > 500, (role, phase, 'too few frames')
            assert 24000 < m['frame_ms_n']*m['frame_ms_mean'] < 27000, (role, phase, 'incomplete wall sample')
            assert e['authority']=='false' and e['controlled']!='nil' and e['drawError']=='nil', (role, phase, e)
            assert int(e['snapshots']) > 150 and int(e['samples']) > 1300, (role, phase, 'stale client')
            assert float(e['states_mean']) > 7.5, (role, phase, 'wearers not replicated')
            rows.append({
                'client':role, 'phase':phase, 'frames':m['frame_ms_n'],
                'fps_mean':round(1000/m['frame_ms_mean'],2),
                'frame_mean_ms':m['frame_ms_mean'], 'frame_p50_ms':m['frame_ms_p50'],
                'frame_p95_ms':m['frame_ms_p95'], 'frame_p99_ms':m['frame_ms_p99'],
                'frame_max_ms':m['frame_ms_max'], 'draw_mean_ms':m['draw_ms_mean'],
                'update_mean_ms':m['update_ms_mean'], 'frames_over_33ms':m['frames_over_33ms'],
                'frames_over_50ms':m['frames_over_50ms'], 'client_active_mean':float(e['active_mean']),
                'sparks_peak':int(e['sparks_peak']), 'server_controller_mean_ms':float(server[phase]['controller_mean_ms']),
                'server_controller_p95_ms':float(server[phase]['controller_p95_ms']),
                'server_ups':float(server[phase]['ups']),
            })
            selected[role].append(m)
    return rows, selected, events, server_text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--partial', action='store_true', help='Print progress without exporting final evidence.')
    args = parser.parse_args()
    rows, selected, events, server = collect(args.partial)
    if args.partial:
        for row in rows:
            print(row['client'], row['phase'], row['fps_mean'], row['frame_p95_ms'], row['client_active_mean'])
        return
    assert len(rows)==44
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT/'summary.csv').open('w', newline='', encoding='utf-8') as stream:
        writer=csv.DictWriter(stream, fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    for role in ('A','B'):
        (OUT/f'client-{role}-metrics.jsonl').write_text(''.join(json.dumps(v)+'\n' for v in selected[role]),encoding='utf-8')
        (OUT/f'client-{role}-actions.txt').write_text(events[role],encoding='utf-8')
    (OUT/'server.txt').write_text(server,encoding='utf-8')
    for role in ('A','B'):
        folder=ROOT/'.runtime/vacuum-clients'/role/'LocalMods/MULTI-TOOL-V2'
        (OUT/f'client-{role}-sonar-validation.txt').write_text(read(folder/'descendant-perf-validation-client.txt'),encoding='utf-8')
    native=ROOT/'.runtime/descendant-native/LocalMods/MULTI-TOOL-V2'
    validation=read(native/'descendant-perf-validation-server.txt')
    contributors=[dict(token.split('=',1) for token in line.split()) for line in validation.splitlines()
                  if line.startswith('phase=combat_8_sonar ')]
    assert len(contributors)==8 and all(int(c['shots'])>20 for c in contributors), 'Missing per-wearer shots'
    (OUT/'per-wearer-validation.txt').write_text(validation,encoding='utf-8')
    for name in ('hardware.json','process.jsonl'):
        (OUT/name).write_text(read(ROOT/f'.runtime/descendant-perf-{name}'),encoding='utf-8')
    hashes=[]
    for path in sorted((ROOT/'MULTI-TOOL-V2').rglob('*')):
        if not path.is_file(): continue
        data=path.read_bytes();relative=path.relative_to(ROOT/'MULTI-TOOL-V2')
        for runtime in (ROOT/'.runtime/descendant-native',ROOT/'.runtime/vacuum-clients/A',ROOT/'.runtime/vacuum-clients/B'):
            assert (runtime/'LocalMods/MULTI-TOOL-V2'/relative).read_bytes()==data, (runtime,relative)
        hashes.append(hashlib.sha256(data).hexdigest()+'  '+relative.as_posix())
    (OUT/'production-sha256.txt').write_text('\n'.join(hashes)+'\n',encoding='utf-8')
    for phase in PHASES:
        print(phase,[(r['client'],r['fps_mean'],r['frame_p95_ms']) for r in rows if r['phase']==phase])
    print('Validated all 22 phases on BOTH real clients; native work and source parity verified.')


if __name__=='__main__':
    main()
