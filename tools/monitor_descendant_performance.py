"""Low-rate Windows process counters for the isolated native benchmark."""
import argparse
import ctypes as c
from ctypes import wintypes as w
import json
from pathlib import Path
import time

ROOT=Path(__file__).resolve().parents[1]


class Memory(c.Structure):
    _fields_=[('cb',w.DWORD),('faults',w.DWORD)]+[(name,c.c_size_t) for name in
        ('peak_rss','rss','peak_paged','paged','peak_nonpaged','nonpaged','pagefile','peak_pagefile','private')]


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--server',type=int,required=True)
    args=parser.parse_args()
    kernel=c.WinDLL('kernel32',use_last_error=True)
    psapi=c.WinDLL('psapi',use_last_error=True)
    kernel.OpenProcess.argtypes=[w.DWORD,w.BOOL,w.DWORD];kernel.OpenProcess.restype=w.HANDLE
    kernel.GetProcessTimes.argtypes=[w.HANDLE]+[c.POINTER(c.c_ulonglong)]*4
    psapi.GetProcessMemoryInfo.argtypes=[w.HANDLE,c.POINTER(Memory),w.DWORD]
    kernel.CloseHandle.argtypes=[w.HANDLE]
    processes={'server':args.server}
    for role in ('A','B'):
        data=(ROOT/f'.runtime/descendant-perf-{role}-pid.txt').read_bytes()
        processes[role]=int(data.decode('utf-16' if data.startswith(b'\xff\xfe') else 'utf-8-sig').strip())
    handles={role:kernel.OpenProcess(0x410,False,pid) for role,pid in processes.items()}
    assert all(handles.values()),'Cannot query isolated processes'
    previous={};start=time.monotonic();phase_at=start;last_phase=None
    output=ROOT/'.runtime/descendant-perf-process.jsonl'
    phase_file=ROOT/'.runtime/vacuum-clients/A/LocalMods/MULTI-TOOL-V2/descendant-perf-phase.txt'
    try:
        with output.open('w',encoding='utf-8',buffering=1) as stream:
            while time.monotonic()-start<900:
                now=time.monotonic();phase=phase_file.read_text(encoding='utf-8-sig').strip()
                if phase!=last_phase: phase_at=now;last_phase=phase
                for role,handle in handles.items():
                    created,exited,kernel_time,user_time=(c.c_ulonglong() for _ in range(4))
                    assert kernel.GetProcessTimes(handle,c.byref(created),c.byref(exited),c.byref(kernel_time),c.byref(user_time))
                    cpu=(kernel_time.value+user_time.value)/10_000_000
                    memory=Memory();memory.cb=c.sizeof(memory)
                    assert psapi.GetProcessMemoryInfo(handle,c.byref(memory),memory.cb)
                    before=previous.get(role);previous[role]=(now,cpu)
                    row={'elapsed_s':round(now-start,3),'phase':phase,'phase_age_s':round(now-phase_at,3),
                         'role':role,'pid':processes[role],'rss_mb':round(memory.rss/1048576,2),
                         'private_mb':round(memory.private/1048576,2),
                         'cpu_one_core_percent':round((cpu-before[1])/(now-before[0])*100,2) if before else None}
                    stream.write(json.dumps(row)+'\n')
                if phase=='done': break
                time.sleep(2)
    finally:
        for handle in handles.values(): kernel.CloseHandle(handle)
    print('Process counters saved:',output)


if __name__=='__main__': main()
