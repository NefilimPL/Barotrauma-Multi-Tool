# Native performance tools

`run_native.py` coordinates a private dedicated server and two actual GPU
clients. Additional wearers are disabled-navigation native humans, not extra
network clients. Every active scenario must prove work for each wearer.

The existing disposable installations are:

- `.runtime/descendant-native` — server;
- `.runtime/vacuum-clients/A` and `B` — clients.

The runner uses localhost ports 27975/27976 and a process lock. It writes only
the disposable installations and a new `output/performance/<UTC>-<label>/`.
It does not operate on the Steam installation or a campaign. Only the two
test accounts receive console permissions in the private server.
Before changing any installation it refuses to start when Barotrauma or a
dedicated server is already running. Close your normal game first; the runner
does not stop existing processes. Keep the Windows desktop and GPU available.

## Commands

From the repository root:

```powershell
# Check native probe startup without beginning a game.
python tools/performance/run_native.py --label smoke --smoke --phase-seconds 10 --repeats 1

# A full production run uses 30-second phases, 5-second warmup, 3 repeats.
python tools/performance/run_native.py --label before --source .runtime/performance-baseline/MULTI-TOOL-V2
python tools/performance/run_native.py --label after

# Prefix filters can be comma-separated. This selects just these suit cases.
python tools/performance/run_native.py --label suit --filter descendantservosuit_idle,descendantservosuit_repair,descendantservosuit_combat

# Same native scene, Vanilla + LuaCs with this mod disabled.
python tools/performance/run_native.py --label no-mod --no-mod

python tools/performance/analyze.py output/performance/<run-id>
python tools/performance/compare.py output/performance/<before> output/performance/<after>

# Separate server-only diagnostics; these have no clients or FPS results.
python tools/performance/run_native.py --label server-check --server-only --filter descendantservosuit_repair_8

# At least 30 minutes sampled mixed load (5 seconds warmup + 1800 measured).
python tools/performance/run_native.py --label soak --filter mixed_stress --phase-seconds 1805 --repeats 1
```

The probe is compiled automatically with Windows PowerShell `Add-Type` into a
versioned DLL in `.runtime/`; no SDK or execution-policy change is needed.
`--source` selects an immutable production baseline. `--probe-source` can
reproduce a previous cohort with its exact client/server Lua and native probe
source. Do not compare different scenarios as if they had equal work.
`--expected-scene <before-run>/scene.json` rejects a different paired scene
before collecting measurements. `--extra-package LocalMods/<name>/filelist.xml`
adds an already installed optional package in each private installation, before
the tested mod. It never installs packages into Steam. Effective configurations
and ordered package names, versions and filelist hashes are retained per role.
Optional-mod results form a separate cohort from the single-mod comparison.
The comparison rejects different probe hashes, native scenes and measurement
roles. Missing historical scene/probe metadata remains explicitly unverified.
Final paired client runs use the process-local OpenAL null driver; their audio
playback/device overhead is outside the measured cohort.

`mixed_stress` equips eight wearers: suit repair and defence, shield and combat
fire, Mk I healing, Mk II hit absorption, vacuum collection and 1000 stored
items. The vacuum's collected loot is periodically removed by the fixture so
collection continues without reaching capacity. Resources are refilled and
actors stabilized just as in the isolated phases. This tests sustained work,
not battery endurance or normal campaign AI. A short mixed pilot is not a soak.

## Files and interpretation

- `manifest.json`: source hashes, probe hashes, roles, intended phases and duration.
- `server.jsonl`: full fixed-step body from native console Update through the
  native coroutine Update, including simulation, networking and Lua; excludes sleep.
- `A.jsonl`, `B.jsonl`: real frame intervals and client Update/Draw wall times.
- `activity.jsonl`: per-wearer actual work, module timings and causal counters.
- `A-evidence.jsonl`, `B-evidence.jsonl`: remote equipment, panel and sonar checks
  in the newer cohort. Older suit probes do not supply these files.
- `process.jsonl`: low-rate CPU/RAM samples; CPU is a percentage of one core.
- `summary.csv`: one row per intended phase and role, including invalid/missing data.
- Logs preserve native/probe errors and failed setup attempts.

The 1 Hz process sampler is separate from frame measurement. Analysis discards
its warmup samples; runs started with an older monitor can lack phase-age
metadata and therefore have no comparable CPU/RAM summary.

Native message counters describe calls and bytes passed to LidgrenServerPeer
Send, before compression and transport framing. They include native entity and
inventory replication as well as Lua messages. They are not wire-byte counters.

Low UPS is retained as evidence. A fast active phase with no actual work is
invalid. A missing client is invalid. Analysis exits nonzero if any intended
role/phase is invalid and retains the other results for diagnosis.

The current native recorder accepts only complete start/end intervals within
the local QPC phase boundaries and after warmup. Samples since the last marker
poll are buffered, so a stalled update crossing the stop timestamp is discarded.
It writes a stop acknowledgement; the fixture waits for native server and both
client acknowledgements before removing entities or preparing the next phase.
Marker polling remains 10 Hz, not per rendered frame. Older archived cohorts
lacked these boundaries and must not establish final p95/p99 improvements.

Both enabled and `--no-mod` controls install the same native proof hooks. The
default disabled control includes idle, vanilla screwdriver repair, SMG fire
and welding; explicit `--filter` still selects a subset. Ring creation and
native projectile launch are counted separately. Wall work requires a change
of the expected sign on the acting tool's wall section, excluding fixture resets
and another wearer's work. Extinguisher consumption remains spray-only proof.
The mixed soak checks every wearer's work in successive 30-second windows;
removed fixture loot is immediately removed from its ownership tracker.

The server metric covers the native fixed-step body bracketed by console Update
and CoroutineManager.Update. CrossThread.ProcessTasks and outer-loop command
polling are outside that body. Frame intervals include the recorder's overhead;
the final cohort still needs native startup/activity and overhead verification.

Historical tools `tools/analyze_descendant_performance.py` and
`tools/analyze_combat_session.py` reproduce their documented older cohorts;
they are not the entry point for these new runs. All runtime Lua/C# files live
under `tests/runtime/performance/`, outside the production package.

`run_lifecycle.py --label <label> --phase-seconds 8 --repeats 1` uses the same
process lock and disposable installations for three native rounds, removal,
an actual client restart/rejoin, and campaign save/load checks. Its Lua source
is `tests/runtime/performance_lifecycle.lua`; all generated campaigns remain
under the owned server's `Saves/<run-id>/`. It uses a historical test campaign
as read-only input and writes new paths. This is functional evidence, not a
frame-rate benchmark. Inspect `lifecycle.txt` and the rejoined client proof;
script creation alone does not establish a passing native run.

`run_dense.py` adds 300 damaged native junction boxes before timing. It
checks the mod's repairable index and waits for the same entities on both
clients. Use the same probe freeze for both sources and pass the first
run's scene manifest to `--expected-scene` for the second run. Report this
as a separate workload from the ordinary item scenes.
