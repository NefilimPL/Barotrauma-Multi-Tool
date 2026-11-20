"""Run test-only native server/clients in existing disposable .runtime copies."""
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
PROBES = ROOT / 'tests/runtime/performance'
ROLES = {'server': ROOT / '.runtime/descendant-native',
         'A': ROOT / '.runtime/vacuum-clients/A', 'B': ROOT / '.runtime/vacuum-clients/B'}
PORT = 27975
SIGNALS = Path('LocalMods/MULTI-TOOL-V2')


def write(path, text):
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(text, encoding='utf-8')
    temporary.replace(path)


def ensure_no_game_processes():
    existing = {}
    for executable in ('Barotrauma.exe', 'DedicatedServer.exe'):
        listing = subprocess.run(['tasklist.exe', '/FO', 'CSV', '/NH', '/FI', f'IMAGENAME eq {executable}'],
                                 capture_output=True, text=True, check=True)
        for row in csv.reader(io.StringIO(listing.stdout)):
            if len(row) >= 2 and row[0].lower() in ('barotrauma.exe', 'dedicatedserver.exe'):
                existing[int(row[1])] = row[0]
    if existing:
        raise RuntimeError(f'Game processes are already running: {existing}. Close them before benchmarking; no process was stopped.')


def wait_for(predicate, processes, timeout=120):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        for role in processes:
            error = ROLES[role] / 'bmt-perf-error.txt'
            if error.exists():
                raise RuntimeError(f'{role} native probe error: {error.read_text(encoding="utf-8")}')
        if predicate():
            return
        dead = [(role, p.returncode) for role, p in processes.items() if p.poll() is not None]
        if dead:
            raise RuntimeError(f'Native processes exited: {dead}')
        time.sleep(.25)
    raise TimeoutError('Native readiness timed out')


def command(role, text, processes):
    folder = ROLES[role]
    done = folder / 'bmt-perf-command-done.txt'
    if done.exists():
        done.unlink()
    write(folder / 'bmt-perf-command.txt', text)
    wait_for(lambda: done.exists(), processes, timeout=90)


def wait_complete(processes, max_seconds=18000, phase_timeout=600, capture_folder=None):
    phase_file = ROLES['server'] / SIGNALS / 'bmt-perf-phase.txt'
    started, changed = time.monotonic(), time.monotonic()
    phase, capture_due = None, None
    while time.monotonic() - started < max_seconds:
        for role in processes:
            for error in (ROLES[role] / 'bmt-perf-error.txt', ROLES[role] / SIGNALS / 'bmt-perf-fatal.txt'):
                if error.exists():
                    raise RuntimeError(f'{role} performance probe error: {error.read_text(encoding="utf-8")}')
        dead = [(role, p.poll()) for role, p in processes.items() if p.poll() is not None]
        if dead:
            raise RuntimeError(f'Native processes exited: {dead}')
        current = phase_file.read_text(encoding='utf-8-sig').strip().split('|', 1)[0] if phase_file.exists() else ''
        if current != phase:
            phase, changed = current, time.monotonic()
            print('Phase: ' + (phase or 'preparing/replicating'), flush=True)
            capture_due = (time.monotonic() + 2 if capture_folder and
                           phase.startswith('descendantservosuit_repair_8') and '_hidden_' not in phase else None)
        if capture_due is not None and time.monotonic() >= capture_due:
            write(ROLES['A'] / 'bmt-perf-capture.txt', str((capture_folder / (phase + '-A.png')).resolve()))
            capture_due = None
        if phase == 'done':
            return
        if time.monotonic() - changed > phase_timeout:
            raise TimeoutError(f'Native phase made no progress for {phase_timeout} s: {phase!r}')
        time.sleep(.5)
    raise TimeoutError('Native run exceeded maximum duration')


def package_settings(folder, extra_packages, no_mod):
    settings = ET.Element('contentpackages')
    ET.SubElement(settings, 'corepackage', path='Content/ContentPackages/Vanilla.xml')
    regular = ET.SubElement(settings, 'regularpackages')
    paths = list(extra_packages) + ([] if no_mod else ['LocalMods/MULTI-TOOL-V2/filelist.xml'])
    inventory = []
    for relative in paths:
        path = folder / relative
        data = path.read_bytes()  # Refuse missing packages before launching native processes.
        metadata = ET.fromstring(data)
        ET.SubElement(regular, 'package', path=relative)
        inventory.append({'path': relative, 'name': metadata.get('name'),
                          'modversion': metadata.get('modversion'),
                          'steamworkshopid': metadata.get('steamworkshopid'),
                          'filelist_sha256': hashlib.sha256(data).hexdigest()})
    return settings, inventory


def prepare(output, no_mod=False, source=None, probes=PROBES, extra_packages=()):
    source = Path(source or ROOT / 'MULTI-TOOL-V2').resolve()
    files = [p for p in source.rglob('*') if p.is_file()]
    hashes = {p.relative_to(source).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    for role, folder in ROLES.items():
        if not folder.resolve().is_relative_to((ROOT / '.runtime').resolve()):
            raise ValueError('Runtime escaped workspace')
        executable = folder / ('DedicatedServer.exe' if role == 'server' else 'Barotrauma.exe')
        if not executable.is_file():
            raise FileNotFoundError(executable)
        for name in ('bmt-perf-installed.txt', 'bmt-perf-ready.txt', 'bmt-perf-phase.txt',
                     'bmt-perf-command.txt', 'bmt-perf-command-done.txt', 'bmt-perf-error.txt',
                     'bmt-perf-metrics.jsonl', 'bmt-perf-activity.jsonl', 'bmt-perf-scene-ready.txt'):
            p = folder / name
            if p.exists():
                shutil.copy2(p, output / f'previous-{role}-{name}')
                p.unlink()
        mod = folder / 'LocalMods/MULTI-TOOL-V2'
        autorun = mod / 'Lua/Autorun'
        unexpected = [p for p in autorun.glob('*.lua') if p.relative_to(mod).as_posix() not in hashes]
        if unexpected:
            raise ValueError(f'Unexpected runtime Autorun scripts: {unexpected}')
        previous_manifest = folder / 'bmt-perf-production.json'
        if previous_manifest.exists():
            for relative in json.loads(previous_manifest.read_text(encoding='utf-8')):
                obsolete = (mod / relative).resolve()
                if relative not in hashes and obsolete.is_relative_to(mod.resolve()) and obsolete.is_file():
                    obsolete.unlink()
        for name in ('bmt-perf-phase.txt', 'bmt-perf-activity.jsonl', 'bmt-perf-manifest.json', 'bmt-perf-scene-ready.txt',
                     'bmt-perf-scene.json', 'bmt-perf-client-evidence.jsonl', 'bmt-perf-stopped.txt', 'bmt-perf-fatal.txt'):
            p = mod / name
            if p.exists():
                shutil.copy2(p, output / f'previous-{role}-{name}')
                p.unlink()
        shutil.copytree(source, mod, dirs_exist_ok=True)
        shutil.copytree(probes, mod / 'Lua/Tests/performance', dirs_exist_ok=True)
        write(previous_manifest, json.dumps(hashes, indent=2))
        for relative, expected in hashes.items():
            if hashlib.sha256((mod / relative).read_bytes()).hexdigest() != expected:
                raise ValueError(f'Production hash mismatch: {role}/{relative}')
        config = ET.parse(folder / 'config_player.xml')
        shutil.copy2(folder / 'config_player.xml', output / f'{role}-config-before.xml')
        root = config.getroot()
        root.set('savepath', str(folder / 'Saves'))
        root.set('pauseonfocuslost', 'false')
        root.set('enablesplashscreen', 'false')
        root.set('remotecontenttimeoutseconds', '1')
        packages, inventory = package_settings(folder, extra_packages, no_mod)
        root.remove(root.find('contentpackages'))
        root.append(packages)
        write(output / f'{role}-packages.json', json.dumps(inventory, indent=2))
        graphics = root.find('graphicssettings')
        for key, value in {'width': '1280', 'height': '800', 'vsync': 'false',
                           'framelimit': '0', 'displaymode': 'Windowed'}.items():
            graphics.set(key, value)
        config.write(folder / 'config_player.xml', encoding='utf-8', xml_declaration=True)
        shutil.copy2(folder / 'config_player.xml', output / f'{role}-config-effective.xml')
        if role == 'server':
            settings = ET.parse(folder / 'serversettings.xml')
            for key, value in {'port': str(PORT), 'queryport': str(PORT + 1), 'IsPublic': 'False',
                               'ServerName': 'BMT performance private', 'enableupnp': 'false',
                               'RequireAuthentication': 'False', 'AutoRestart': 'False',
                               'RandomizeSeed': 'False', 'Biome': 'coldcaverns',
                               'MaxPlayers': '16', 'GameModeIdentifier': 'sandbox'}.items():
                settings.getroot().set(key, value)
            settings.write(folder / 'serversettings.xml', encoding='utf-8', xml_declaration=True)
    return hashes


def finalize_run(output, manifest, processes, streams, monitor):
    try:
        for role in processes:
            for name, target in (('bmt-perf-metrics.jsonl', f'{role}.jsonl'),
                                 ('bmt-perf-error.txt', f'{role}-probe-errors.txt'),
                                 ('bmt-perf-console.txt', f'{role}-console.txt'),
                                 ('bmt-perf-client-evidence.jsonl', f'{role}-evidence.jsonl'),
                                 ('bmt-perf-scene.json', 'scene.json'),
                                 ('bmt-perf-activity.jsonl', 'activity.jsonl'),
                                 ('bmt-perf-manifest.json', 'phases.json')):
                local = name in ('bmt-perf-activity.jsonl', 'bmt-perf-manifest.json',
                                 'bmt-perf-client-evidence.jsonl', 'bmt-perf-scene.json')
                source = ROLES[role] / (SIGNALS / name if local else Path(name))
                if source.exists():
                    shutil.copy2(source, output / target)
        phase_manifest = output / 'phases.json'
        if phase_manifest.exists():
            manifest['phases'] = json.loads(phase_manifest.read_text(encoding='utf-8-sig'))
        write(output / 'manifest.json', json.dumps(manifest, indent=2))
        print('Evidence: ' + str(output), flush=True)
    finally:
        # Never let a locked/full evidence destination strand native children.
        failures = []
        for process in processes.values():
            try:
                if process.poll() is None:
                    process.terminate()
            except OSError as error:
                failures.append(str(error))
        for process in processes.values():
            try:
                try:
                    process.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=15)
            except (OSError, subprocess.TimeoutExpired) as error:
                failures.append(str(error))
        for stream in streams:
            try:
                stream.close()
            except OSError as error:
                failures.append(str(error))
        if monitor:
            try:
                try:
                    monitor.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    monitor.terminate()
                    try:
                        monitor.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        monitor.kill()
                        monitor.wait(timeout=5)
            except (OSError, subprocess.TimeoutExpired) as error:
                failures.append(str(error))
        if failures:
            raise RuntimeError('Owned process cleanup failed: ' + '; '.join(failures))


def main(after_run=None, before_run=None):
    global ROLES
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--label', required=True)
    parser.add_argument('--phase-seconds', type=int, default=30)
    parser.add_argument('--repeats', type=int, default=3)
    parser.add_argument('--filter', default='')
    parser.add_argument('--smoke', action='store_true')
    parser.add_argument('--no-mod', action='store_true')
    parser.add_argument('--server-only', action='store_true', help='Explicit separate cohort, no client or FPS claims')
    parser.add_argument('--capture-warmup', action='store_true', help='Capture suit repair during excluded warmup; use current probes')
    parser.add_argument('--source', type=Path, default=ROOT / 'MULTI-TOOL-V2')
    parser.add_argument('--probe-source', type=Path, default=PROBES)
    parser.add_argument('--expected-scene', type=Path, help='Refuse a paired run before sampling if its native scene differs')
    parser.add_argument('--extra-package', action='append', default=[], help='Existing filelist path relative to EACH disposable installation; loaded before the tested mod')
    args = parser.parse_args()
    if args.server_only:
        ROLES = {'server': ROLES['server']}
    if args.no_mod and not args.filter:
        args.filter = 'none_none,screwdriver_repair_8,smg_fire_8,weldingtool_weld_8'
    if not all(c.isalnum() or c in '-_' for c in args.label):
        parser.error('Label must contain letters, digits, hyphen or underscore')
    if args.phase_seconds <= 5 or args.repeats < 1:
        parser.error('Phases must exceed the five-second warmup and repeats must be positive')
    ensure_no_game_processes()
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    output = ROOT / 'output/performance' / f'{stamp}-{args.label}'
    output.mkdir(parents=True, exist_ok=False)
    probes = args.probe_source.resolve()
    source_hash = hashlib.sha256((probes / 'NativeProbe.cs').read_bytes()).hexdigest()
    probe = ROOT / '.runtime' / f'BMTNativeProbe-{source_hash[:16]}.dll'
    if not probe.exists():
        build_env = os.environ.copy()
        build_env['BMT_PROBE_SOURCE'] = str(probes / 'NativeProbe.cs')
        build_env['BMT_PROBE_OUTPUT'] = str(probe)
        subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command',
                        "$ErrorActionPreference='Stop'; Add-Type -TypeDefinition ([IO.File]::ReadAllText($env:BMT_PROBE_SOURCE)) -OutputAssembly $env:BMT_PROBE_OUTPUT -OutputType Library"],
                       check=True, cwd=ROOT, env=build_env)
    hashes = prepare(output, args.no_mod, args.source, probes, args.extra_package)
    manifest = {'label': args.label, 'run_id': output.name, 'phase_seconds': args.phase_seconds,
                'warmup_seconds': 5, 'repeats': args.repeats, 'filter': args.filter,
                'production': hashes, 'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                'source': str(args.source.resolve()),
                'measurement_roles': list(ROLES), 'audio_driver': 'null', 'mod_enabled': not args.no_mod,
                'configured_packages': {role: json.loads((output / f'{role}-packages.json').read_text(encoding='utf-8')) for role in ROLES},
                'probes': {p.relative_to(probes).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in probes.rglob('*') if p.is_file()},
                'native_probe_sha256': hashlib.sha256(probe.read_bytes()).hexdigest(),
                'require_native_marker': 'MarkerWrite' in (probes / 'NativeProbe.cs').read_text(encoding='utf-8'),
                'require_client_evidence': 'bmt-perf-client-evidence.jsonl' in (probes / 'client.lua').read_text(encoding='utf-8'),
                'require_replica_health': 'can_interact_samples' in (probes / 'client.lua').read_text(encoding='utf-8'),
                'roles': {k: str(v) for k, v in ROLES.items()}, 'phases': []}
    write(output / 'manifest.json', json.dumps(manifest, indent=2))
    mode = ROLES['server'] / SIGNALS / 'bmt-perf-server-only.txt'
    if args.server_only:
        write(mode, 'explicit server-only cohort')
    elif mode.exists():
        mode.unlink()
    processes, streams, monitor = {}, [], None
    try:
        for role, folder in ROLES.items():
            env = os.environ.copy()
            env['DOTNET_STARTUP_HOOKS'] = str(probe)
            # Disposable clients must not block on a disconnected WASAPI device.
            env['ALSOFT_DRIVERS'] = 'null'
            startup = subprocess.STARTUPINFO()
            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startup.wShowWindow = 0
            executable = folder / ('DedicatedServer.exe' if role == 'server' else 'Barotrauma.exe')
            stdout = (output / f'{role}-stdout.log').open('w', encoding='utf-8')
            stderr = (output / f'{role}-stderr.log').open('w', encoding='utf-8')
            streams.extend([stdout, stderr])
            arguments = [str(executable)] + ([] if role == 'server' else ['-username', 'Perf' + role, '-skipintro'])
            if role != 'server' and (not args.smoke or after_run is not None):
                arguments = [str(executable), '-connect', 'BMT performance private', f'127.0.0.1:{PORT}',
                             '-username', 'Perf' + role, '-skipintro']
            processes[role] = subprocess.Popen(arguments, cwd=folder, env=env, stdin=subprocess.PIPE,
                                               stdout=stdout, stderr=stderr, startupinfo=startup,
                                               creationflags=subprocess.CREATE_NO_WINDOW)
            print(f'{role} pid={processes[role].pid}', flush=True)
        write(output / 'pids.json', json.dumps({k: p.pid for k, p in processes.items()}))
        monitor = subprocess.Popen([sys.executable, str(Path(__file__).with_name('monitor.py')), str(output)],
                                   cwd=ROOT, creationflags=subprocess.CREATE_NO_WINDOW)
        wait_for(lambda: all((folder / 'bmt-perf-ready.txt').exists() for folder in ROLES.values()), processes, 180)
        print('Native probes ready', flush=True)
        if args.smoke:
            for folder in ROLES.values():
                write(folder / SIGNALS / 'bmt-perf-phase.txt', 'smoke_idle')
            time.sleep(args.phase_seconds)
            for folder in ROLES.values():
                write(folder / SIGNALS / 'bmt-perf-phase.txt', 'done')
            time.sleep(.5)
        else:
            time.sleep(12)
            command('server', 'clientlist', processes)
            if not args.server_only:
                for name in ('PerfA', 'PerfB'):
                    command('server', f'givecommandperm {name} all', processes)
            command('server', 'gamemode sandbox', processes)
            command('server', 'sub Dugong', processes)
            command('server', 'botcount 0', processes)
            command('server', 'seed BMT-performance-20261118', processes)
            command('server', 'start', processes)
            time.sleep(15)
            command('server', "lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/performance/server.lua')", processes)
            wait_for(lambda: (ROLES['server'] / SIGNALS / 'bmt-perf-scene-ready.txt').exists(), processes, 90)
            if not args.server_only:
                for role in ('A', 'B'):
                    command(role, "cl_lua dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/performance/client.lua')", processes)
            time.sleep(2)
            if before_run is not None:
                before_run(output, manifest, processes)
                write(output / 'manifest.json', json.dumps(manifest, indent=2))
            if args.expected_scene:
                actual = json.loads((ROLES['server'] / SIGNALS / 'bmt-perf-scene.json').read_text(encoding='utf-8-sig'))
                expected = json.loads(args.expected_scene.read_text(encoding='utf-8-sig'))
                if actual != expected:
                    raise RuntimeError(f'Native scene mismatch before sampling: expected {expected}, got {actual}')
            command('server', 'lua BMTPerformance.run(' + str(args.phase_seconds) + ',' + str(args.repeats) + ",'" + args.filter + "')", processes)
            wait_complete(processes, phase_timeout=max(600, args.phase_seconds + 120),
                          capture_folder=output if args.capture_warmup else None)
            time.sleep(1)
        if after_run is not None:
            after_run(output, manifest, processes)
    finally:
        finalize_run(output, manifest, processes, streams, monitor)


if __name__ == '__main__':
    import msvcrt
    with (ROOT / '.runtime/performance.lock').open('a+b') as lock:
        lock.seek(0)
        try:
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError:
            raise SystemExit('Another native performance run owns these isolated copies')
        main()
