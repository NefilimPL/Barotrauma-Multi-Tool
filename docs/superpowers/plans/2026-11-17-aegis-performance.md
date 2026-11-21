# Aegis multiplayer performance measurements

**Goal:** measure client frame pacing and server script cost of the current 1.3.17 suit, using a real localhost server and two connected GPU clients, then report observed regressions and limits honestly.

**Scope:** measurement harness and documentation. Preserve existing user changes and packages. Production optimizations only if a measured bottleneck warrants them, with a separate regression and repeat measurement. No external server, Steam install or campaign changes.

**Method:** existing native Harmony Stopwatch recorder adapted to distinct `aegis-perf-*` files; Draw-to-Draw wall intervals (FPS, p50/p95/p99/max, >33/>50 ms), Draw and Update CPU elapsed. 1280x800 windowed, VSync off, inactive-window sleep disabled, same machine/scene across paired phases. Drop first 5 s of each 30 s phase. Native suit update/render and snapshot work remains enabled. Record two clients independently and validate actual work with server/client action counters; do not call a no-op phase an active benchmark.

- [x] Verify binary/content parity, recorder clock and two joined clients, preserve hardware/settings and source hashes.
- [x] Build isolated native scene with two players, six additional suit wearers and visible repair/combat/grip targets. Stabilize actors consistently; refill test resources without bypassing native spending/projectiles/repair.
- [x] Run paired idle/repair/combat/grip/sonar cases, two repeats of common work, plus eight-suit stress and combined sonar. Record server controller cost, simulation wall pace, action duty/counts, client snapshot and render errors.
- [x] Validate sample durations/counters, report FPS/frame percentiles and deltas with caveats. Investigate measured failures, not hypothetical issues.
- [x] Export evidence and reproducible harness, document conclusions, stop only the isolated test processes.

**Limits:** two clients/server share one CPU/GPU. This measures the isolated mod/version and local synchronization, not friends' hardware or Internet latency. Additional suit wearers are native NPCs, not six extra network clients. Frame intervals include recording overhead and platform pacing; native Draw timing is elapsed CPU-side work, not a GPU profiler.

## Evidence and rulings

- Production1.3.17 unchanged. 122-file SHA256 manifest and byte comparisons against the dedicated server and BOTH clients pass. Native client DLL hashes match.
- Final analysis validates22 scenarios per real client, 44 rows, 544508 frames. Every selected window24–27s after5s warmup, >500 frames and >1300 simulation samples, >150 fresh snapshots, eight replicated wearers, authoritative=false, no drawError. Corrected/repeated rows selected last, no empty action scenario counted.
- Ruling: fresh native grip targets and retry only while unlatched avoid synthetic far-teleport interpolation history; original empty grip samples discarded. Inactive grip humans were parking through the line of fire; moved inactive targets out of the scene. Fixed NPCs have AI disabled and native IsBot=false, so use the production mode handler explicitly; original two-active stress samples discarded.
- Corrected physical grip means1.000/2.000 throughout analyzed windows. Eight-repair active mean6.741,6121 repaired condition; eight combat510 native shots; combined eight combat + TWO sonars504 shots,63 per wearer. Both sonar panels powered/visible100% of1500/1499 samples. Counters cover30s, timing/active means25s.
- FPS A/B idle8=556.67/569.74; repair8=197.11/197.72; combat8=300.52/313.07; combat8+sonar2=282.74/288.89. Largest frame142.2639ms in idle_5. 35 frames>33.3ms,16>50ms overall. Server remains~60UPS on average; controller p99 can exceed16.67ms.
- Ruling: report workload cost, NOT a previous-version regression or whole-mod overhead. Draw/Update are CPU-thread elapsed, NOT GPU time or per-tick simulation cost. Single repair phase was active only.141 on average, not a max continuous-repair benchmark. No performance claim for friends' hardware/campaigns.
- Review corrected missing sonar/per-emitter evidence and clarified timing/counter windows, shared hardware and monitor coverage. Process monitor covers840s tofirstdone, excluding final additional sonar verification. JSONL newline normalization fixed during export and revalidated.
- Export: docs/AEGIS-PERFORMANCE.md and docs/aegis-suit/performance/*. Native clients20448/28148 stopped after path checks; dedicated server PTY35673 exit0; process monitor PTY45026 exit0. Prior ZIP remains unchanged.
