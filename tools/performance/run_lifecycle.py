"""Native lifecycle checks on disposable copies; keeps all campaign files private."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import time
import subprocess
from collections import Counter
import xml.etree.ElementTree as ET

import run_native as runner


def lifecycle(output, manifest, processes, campaign_only=False):
    source = runner.ROOT / 'tests/runtime/performance_lifecycle.lua'
    manifest['lifecycle_source_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
    log = 'bmt-life-' + output.name + '.txt'
    folder = runner.ROLES['server'] / runner.SIGNALS
    target = folder / 'Lua/Tests/performance_lifecycle.lua'
    shutil.copy2(source, target)

    def command(text):
        runner.command('server', text, processes)

    def lua(text):
        command('lua ' + text)

    def load():
        lua("BMTLifecycleLog='" + log + "'; dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/performance_lifecycle.lua')")

    def wait(value):
        signal = folder / (log + '.ready')
        record = folder / log

        def acknowledged():
            if record.exists():
                failure = next((line for line in record.read_text(encoding='utf-8-sig').splitlines()
                                if line.startswith('FAIL ')), None)
                if failure:
                    raise RuntimeError(failure)
            return signal.exists() and signal.read_text(encoding='utf-8-sig') == value

        runner.wait_for(acknowledged, processes, 90)
        signal.unlink()

    def rejoin():
        old = processes.pop('A')
        old.terminate();old.wait(timeout=15)
        if old.stdin:
            old.stdin.close()
        # Reap the server connection explicitly instead of racing its UDP timeout
        # and accidentally joining under a duplicate, automatically changed name.
        lua('BMTLifecycle.reapConnection()');wait('disconnected')
        role = runner.ROLES['A']
        for name in ('bmt-perf-ready.txt', 'bmt-perf-installed.txt', 'bmt-perf-command.txt', 'bmt-perf-command-done.txt', 'bmt-perf-error.txt'):
            path = role / name
            if path.exists():
                path.unlink()
        probe = next(p for p in (runner.ROOT / '.runtime').glob('BMTNativeProbe-*.dll')
                     if hashlib.sha256(p.read_bytes()).hexdigest() == manifest['native_probe_sha256'])
        env = os.environ.copy();env['DOTNET_STARTUP_HOOKS'] = str(probe);env['ALSOFT_DRIVERS'] = 'null'
        startup = subprocess.STARTUPINFO();startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow = 0
        with (output / 'A-rejoin-stdout.log').open('w', encoding='utf-8') as stdout, (output / 'A-rejoin-stderr.log').open('w', encoding='utf-8') as stderr:
            child = subprocess.Popen([str(role / 'Barotrauma.exe'), '-connect', 'BMT performance private',
                                      f'127.0.0.1:{runner.PORT}', '-username', 'PerfA', '-skipintro'],
                                     cwd=role, env=env, stdin=subprocess.PIPE, stdout=stdout, stderr=stderr,
                                     startupinfo=startup, creationflags=subprocess.CREATE_NO_WINDOW)
            processes['A'] = child
            manifest['lifecycle_rejoin_pids'] = {'old': old.pid, 'new': child.pid}
            runner.wait_for(lambda: (role / 'bmt-perf-ready.txt').exists(), processes, 180)
            time.sleep(15);command('givecommandperm PerfA all')
            joined = role / runner.SIGNALS / (log + '.joined')
            runner.command('A', "cl_lua assert(Game.Client); Game.Client.SendJoinOngoingRequest(nil); "
                           "local function ready() if Game.RoundStarted then File.Write('LocalMods/MULTI-TOOL-V2/" + log +
                           ".joined','joined') else Timer.Wait(ready,250) end end;ready()", processes)
            runner.wait_for(joined.exists, processes, 120)
            lua('BMTLifecycle.reconnected()');wait('reconnected')
            proof = role / runner.SIGNALS / (log + '.rejoined')
            runner.command('A', "cl_lua local function verifyPack() local c=Character.Controlled; "
                           "local p=c and c.Inventory.GetItemInLimbSlot(InvSlotType.Bag); "
                           "if p and #BMTVacuum.contents(p)==30 then File.Write('LocalMods/MULTI-TOOL-V2/" + log +
                           ".rejoined','PASS native client contents after rejoin') else Timer.Wait(verifyPack,250) end end;verifyPack()", processes)
            runner.wait_for(proof.exists, processes, 60)
            shutil.copy2(proof, output / 'A-rejoined.txt')

    rejoin_failure = None
    try:
        time.sleep(12)
        for role in ('A', 'B'):
            if role in processes:
                command(f'givecommandperm Perf{role} all')
        command('gamemode sandbox')
        command('sub Dugong')
        command('botcount 0')
        command('seed BMT-lifecycle-20261119')
        for cycle in range(0 if campaign_only else 3):
            print(f'Lifecycle round {cycle + 1}/3', flush=True)
            command('start');time.sleep(15);load()
            lua('BMTLifecycle.prepare()');wait('prepared')
            if cycle == 0:
                try:
                    rejoin()
                except TimeoutError as error:
                    # Round cleanup and campaign preservation can still be verified.
                    rejoin_failure = f'Rejoin did not reach its native replication barrier: {error}'
                    print(rejoin_failure, flush=True)
                lua('BMTLifecycle.clearOwned()');wait('removed')
            command('end');time.sleep(1);load()
            lua('BMTLifecycle.waitStopped()');wait('stopped')
        # Preserve both the old fixture and each generated save; never write the load source.
        legacy = runner.ROOT / '.runtime/server/Saves/VacuumVerification20261104.save'
        saves = runner.ROLES['server'] / 'Saves' / output.name
        saves.mkdir(parents=True, exist_ok=False)
        loaded, saved, second = (saves / n for n in ('input.save', 'saved.save', 'saved-again.save'))
        for old, new in ((legacy, loaded), (legacy.with_name(legacy.stem + '_CharacterData.xml'), loaded.with_name('input_CharacterData.xml'))):
            shutil.copy2(old, new)
        assert all(p.resolve().is_relative_to((runner.ROOT / '.runtime').resolve()) for p in (loaded, saved, second))
        if campaign_only:
            # The historical fixture belongs to old test accounts. Match its
            # one stored inventory to the single current client by loopback.
            # Only metadata on the staged XML copy changes.
            chars = loaded.with_name('input_CharacterData.xml')
            doc = ET.parse(chars)
            root = doc.getroot()
            owners = [entry for entry in root if any('bmtvac_20261104_stresspack' in item.get('Tags', '').split(',')
                                                    for item in entry.iter('Item'))]
            if len(owners) != 1 or set(processes) != {'server', 'A'}:
                raise RuntimeError('Campaign fixture needs one saved stress pack and one test client')
            owner = owners[0]
            for other in list(root):
                if other is not owner:
                    root.remove(other)
            owner.attrib.pop('accountid', None)
            owner.set('address', '127.0.0.1')
            doc.write(chars, encoding='utf-8', xml_declaration=True)
            manifest['campaign_fixture_identity'] = 'one stored test character matched by loopback; inventory XML unchanged'
        load();lua(f"BMTLifecycle.loadCampaign('{loaded.as_posix()}','{saved.as_posix()}')")
        wait('loaded')
        lua("BMTLifecycle.verifyLegacy('10000 identities and conditions after native load')")
        wait('legacy-verified')
        lua('BMTLifecycle.saveCampaign()');wait('saved')
        serialized = saved.with_name('saved_CharacterData.xml')
        items = {tag: item for item in ET.parse(serialized).getroot().iter('Item')
                 for tag in item.get('Tags', '').split(',') if tag.startswith('bmtvac_20261104_stressitem')}
        if len(items) != 10000 or abs(float(items['bmtvac_20261104_stressitem10000'].get('conditionpercentage')) - 23) >= .02:
            raise RuntimeError(f'Engine serialized {len(items)} of 10000 expected named items or lost the modified condition')
        # A native round-end autosave may alter its live save path. Preserve
        # and reload the exact snapshot that passed serialization checks.
        checkpoint = saves / 'verified-checkpoint.save'
        shutil.copy2(saved, checkpoint)
        shutil.copy2(serialized, checkpoint.with_name('verified-checkpoint_CharacterData.xml'))
        manifest['campaign_serialized_item_count'] = len(items)
        command('end');time.sleep(1)
        lua('BMTLifecycle.waitStopped()');wait('stopped')
        load();lua(f"BMTLifecycle.loadCampaign('{checkpoint.as_posix()}','{second.as_posix()}')")
        wait('loaded')
        lua("BMTLifecycle.verifyLegacy('10000 identities and conditions after candidate save reload',true)")
        wait('legacy-verified')
        command('end');time.sleep(3)
    finally:
        if (folder / log).exists():
            shutil.copy2(folder / log, output / 'lifecycle.txt')
    rows = (output / 'lifecycle.txt').read_text(encoding='utf-8-sig').splitlines()
    failures = [row for row in rows if row.startswith('FAIL ')]
    if rejoin_failure:
        failures.append(rejoin_failure)
    required = {
        'all four production controllers track real equipped items': 3,
        'native multitool mode helpers and backpack page exist': 3,
        'native pack prepared': 3,
        'round ended and production states cleared': 3,
        'original character survives actual client disconnect': 1,
        '30 native identities and conditions preserved through real disconnect/rejoin': 1,
        'removed item states pruned before round end': 1,
        'native contained helper items removed with their parent': 1,
        'campaign copy loaded into native session': 2,
        '10000 identities and conditions after native load': 1,
        'native campaign save completed': 1,
        '10000 identities and conditions after candidate save reload': 1,
    }
    if campaign_only:
        keep = ('campaign copy', '10000 identities', 'native campaign save')
        required = {name: count for name, count in required.items() if name.startswith(keep)}
    passes = Counter(row[5:] for row in rows if row.startswith('PASS '))
    failures += [f'Missing positive native check: {name} ({passes[name]}/{count})'
                 for name, count in required.items() if passes[name] < count]
    manifest['lifecycle_passes'] = sum(row.startswith('PASS ') for row in rows)
    manifest['lifecycle_failures'] = failures
    print('\n'.join(rows), flush=True)
    if failures:
        raise RuntimeError('Native lifecycle checks failed')


if __name__ == '__main__':
    import msvcrt
    campaign_only = '--campaign-only' in sys.argv
    if campaign_only:
        sys.argv.remove('--campaign-only')
        runner.ROLES.pop('B')
    if '--smoke' not in sys.argv:
        sys.argv.append('--smoke')
    with (runner.ROOT / '.runtime/performance.lock').open('a+b') as lock:
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        runner.main(after_run=lambda output, manifest, processes: lifecycle(output, manifest, processes, campaign_only))
