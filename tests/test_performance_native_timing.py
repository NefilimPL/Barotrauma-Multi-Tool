import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.name == 'nt', 'Native probe compiles with Windows PowerShell')
class NativeTimingBoundaryTests(unittest.TestCase):
    def check_buffer(self, commands):
        env = os.environ.copy()
        env['BMT_TIMING_SOURCE'] = str(ROOT / 'tests/runtime/performance/NativeProbe.cs')
        script = "$ErrorActionPreference='Stop'; Add-Type -TypeDefinition ([IO.File]::ReadAllText($env:BMT_TIMING_SOURCE)); " + commands
        result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', script],
                                capture_output=True, text=True, env=env, timeout=45)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_frame_starting_in_warmup_is_excluded_in_full(self):
        self.check_buffer("$b=New-Object 'StartupHook+SampleBuffer'; $b.Record(400,600,200); $b.Record(600,620,20); "
                          "$b.Flush(500,1000); if ($b.Values.Count -ne 1 -or $b.Values[0] -ne 20) {throw 'warmup-crossing frame leaked'}")

    def test_long_teardown_and_next_phase_intervals_are_excluded_despite_delayed_poll(self):
        self.check_buffer("$b=New-Object 'StartupHook+SampleBuffer'; $b.Record(800,900,100); $b.Record(900,1400,500); "
                          "$b.Record(1500,1600,100); $b.Flush(500,1000); "
                          "if ($b.Values.Count -ne 1 -or $b.Values[0] -ne 100 -or $b.PendingCount -ne 0) {throw 'transition contaminated sample'}")

    def test_native_marker_captures_qpc_without_exposing_a_dotnet_type_to_lua(self):
        self.check_buffer("$flags=[Reflection.BindingFlags]'Static,NonPublic'; "
                          "[StartupHook]::MarkerWrite('unrelated.txt','wrong'); "
                          "$before=[Diagnostics.Stopwatch]::GetTimestamp(); "
                          "[StartupHook]::MarkerWrite([IO.Path]::Combine([Environment]::CurrentDirectory,'LocalMods','MULTI-TOOL-V2','bmt-perf-phase.txt'),'test_phase'); "
                          "$after=[Diagnostics.Stopwatch]::GetTimestamp(); "
                          "$phase=[StartupHook].GetField('phase',$flags).GetValue($null); "
                          "$stamp=[StartupHook].GetField('started',$flags).GetValue($null); "
                          "if ($phase -ne 'test_phase' -or $stamp -lt $before -or $stamp -gt $after) {throw 'native QPC boundary missing'}")
