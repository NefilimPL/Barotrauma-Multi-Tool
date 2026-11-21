"""Augment the shared native fixture with 300 actual damaged repairable devices."""
import hashlib
import json
import shutil
import sys

import run_native as runner


def prepare_dense(output, manifest, processes):
    source = runner.ROOT / 'tests/runtime/performance_dense.lua'
    mod = runner.ROLES['server'] / runner.SIGNALS
    for role in processes:
        folder = runner.ROLES[role] / runner.SIGNALS
        for name in ('aegis-dense-ready.txt', 'aegis-dense-ids.txt', 'aegis-dense-replica.txt'):
            path = folder / name
            if path.exists():
                path.unlink()
    shutil.copy2(source, mod / 'Lua/Tests/performance_dense.lua')
    runner.command('server', "lua dofile('LocalMods/System-Aegis/Lua/Tests/performance_dense.lua')", processes)
    ready = mod / 'aegis-dense-ready.txt'
    runner.wait_for(ready.exists, processes, 180)
    assert ready.read_text(encoding='utf-8-sig') == '300'
    for role in ('A', 'B'):
        if role not in processes:
            continue
        folder = runner.ROLES[role] / runner.SIGNALS
        shutil.copy2(mod / 'aegis-dense-ids.txt', folder / 'aegis-dense-ids.txt')
        runner.command(role, "cl_lua local ids=File.Read('LocalMods/System-Aegis/aegis-dense-ids.txt'); "
                       "local function verify() local n=0;for id in ids:gmatch('%d+') do "
                       "if Entity.FindEntityByID(tonumber(id)) then n=n+1 end end; "
                       "if n==300 then File.Write('LocalMods/System-Aegis/aegis-dense-replica.txt','300') "
                       "else Timer.Wait(verify,250) end end;verify()", processes)
    replicas = [runner.ROLES[role] / runner.SIGNALS / 'aegis-dense-replica.txt'
                for role in ('A', 'B') if role in processes]
    runner.wait_for(lambda: all(p.exists() and p.read_text(encoding='utf-8-sig') == '300' for p in replicas), processes, 180)
    manifest['fixture'] = {'kind': 'far native damaged junctionboxes', 'count': 300,
                           'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                           'replica_count': {role: 300 for role in ('A', 'B') if role in processes}}
    shutil.copy2(mod / 'aegis-dense-ids.txt', output / 'dense-ids.txt')
    print('Dense fixture: 300 indexed damaged devices; all clients received all IDs', flush=True)


if __name__ == '__main__':
    import msvcrt
    if '--filter' not in sys.argv:
        sys.argv += ['--filter', 'aegisservosuit_repair_8']
    with (runner.ROOT / '.runtime/performance.lock').open('a+b') as lock:
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        runner.main(before_run=prepare_dense)
