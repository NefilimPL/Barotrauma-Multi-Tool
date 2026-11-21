"""Low-rate Windows CPU/RAM sampling for an owned native benchmark run."""
import argparse
import ctypes as c
from ctypes import wintypes as w
import json
from pathlib import Path
import time


class Memory(c.Structure):
    _fields_ = [('cb', w.DWORD), ('faults', w.DWORD)] + [(name, c.c_size_t) for name in
        ('peak_rss', 'rss', 'peak_paged', 'paged', 'peak_nonpaged', 'nonpaged', 'pagefile', 'peak_pagefile', 'private')]


def monitor(folder):
    folder = Path(folder)
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    pids = json.loads((folder / 'pids.json').read_text(encoding='utf-8'))
    kernel = c.WinDLL('kernel32', use_last_error=True)
    psapi = c.WinDLL('psapi', use_last_error=True)
    kernel.OpenProcess.argtypes = [w.DWORD, w.BOOL, w.DWORD]
    kernel.OpenProcess.restype = w.HANDLE
    kernel.GetProcessTimes.argtypes = [w.HANDLE] + [c.POINTER(c.c_ulonglong)] * 4
    kernel.GetExitCodeProcess.argtypes = [w.HANDLE, c.POINTER(w.DWORD)]
    kernel.CloseHandle.argtypes = [w.HANDLE]
    psapi.GetProcessMemoryInfo.argtypes = [w.HANDLE, c.POINTER(Memory), w.DWORD]
    handles = {role: kernel.OpenProcess(0x1000 | 0x400, False, pid) for role, pid in pids.items()}
    if not all(handles.values()):
        raise OSError('Cannot query benchmark processes')
    previous, phase_at = {}, {}
    started = time.monotonic()
    try:
        with (folder / 'process.jsonl').open('a', encoding='utf-8', buffering=1) as stream:
            while True:
                now = time.monotonic()
                alive = 0
                for role, handle in handles.items():
                    exit_code = w.DWORD()
                    if not kernel.GetExitCodeProcess(handle, c.byref(exit_code)) or exit_code.value != 259:
                        continue
                    alive += 1
                    phase_file = Path(manifest['roles'][role]) / 'LocalMods/System-Aegis/aegis-perf-phase.txt'
                    phase = phase_file.read_text(encoding='utf-8-sig').strip().split('|', 1)[0] if phase_file.exists() else ''
                    if role not in previous or previous[role][2] != phase:
                        phase_at[role] = now
                    values = [c.c_ulonglong() for _ in range(4)]
                    if not kernel.GetProcessTimes(handle, *[c.byref(v) for v in values]):
                        raise OSError('Cannot read process CPU time')
                    cpu = (values[2].value + values[3].value) / 10_000_000
                    memory = Memory()
                    memory.cb = c.sizeof(memory)
                    if not psapi.GetProcessMemoryInfo(handle, c.byref(memory), memory.cb):
                        raise OSError('Cannot read process memory')
                    before = previous.get(role)
                    previous[role] = now, cpu, phase
                    row = {'elapsed_s': round(now - started, 3), 'phase': phase, 'role': role,
                           'phase_age_s': round(now - phase_at[role], 3),
                           'rss_mb': round(memory.rss / 1048576, 2), 'private_mb': round(memory.private / 1048576, 2),
                           'cpu_one_core_percent': round((cpu - before[1]) / (now - before[0]) * 100, 2)
                               if before and before[2] == phase else None}
                    stream.write(json.dumps(row) + '\n')
                if not alive:
                    break
                time.sleep(1)
    finally:
        for handle in handles.values():
            if handle:
                kernel.CloseHandle(handle)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    monitor(parser.parse_args().run)
