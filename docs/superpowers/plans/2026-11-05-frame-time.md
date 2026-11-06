# Frame-time optimization implementation plan

> Execute inline with superpowers:executing-plans; one whole-change review at completion.

**Goal:** Reduce spikes from shields, idle tools, passive skills, vacuum scans and inventory UI.
**Spec:** User-approved five-point audit in this conversation (2026-11-05).
**Constraints:** Keep server collision/damage authoritative and current. Preserve costs, five-minute skill rewards, inventory access, filters and native save items. No publishing or commits requested.
**Workspace:** Continue the existing dev checkout; isolated runtime copies remain under .runtime.

### 1. Shield visuals
- [x] RED: stationary shield repeats fewer casts; offscreen shield makes none; moving/expired masks refresh.
- [x] Add world-view rejection and a 0.1-second visual-only occlusion cache, invalidated by movement over 2 units or rotation over 0.01 radians. Keep current sprite pose and gameplay collision.
- [x] Verify shield synchronization and occlusion tests.

### 2. Idle combat tools
- [x] RED: stored/floor tools skip expensive context checks; equipping and dropping take effect next update; bots retain resupply.
- [x] Configure components once per state; cache light references. Use minimal inactive contexts while preserving ownership transitions, permission and resupply.
- [x] Verify combat suite and native device lifecycle.

### 3. Passive skills
- [x] RED: do not enumerate all characters; discover owners from indexed tools and immediate item.equip notifications.
- [x] Check only tool owners per frame. Preserve live eligibility and exact elapsed-time accounting; retain paused progress; clear references and dispose hooks.
- [x] Verify all existing five-minute, battery, cap and switching tests.

### 4. Vacuum loot refresh
- [x] RED: native item inspection budget per update, new loot discovery, cancellation and round reset.
- [x] Refresh candidates in batches of 256 items per think. Keep the last complete candidate list until its replacement is ready; share one refresh across nozzles.
- [x] Verify pickup, filters and reset suites; measure worst update on native items.

### 5. Inventory UI
- [x] RED: repeated snapshots allocate no new widgets; recycled tiles use current rows, icons and actions.
- [x] Retain 40 tiles per open panel, update their data and reuse native image sprites/text.
- [x] Verify contents/filter/search/empty-page transitions and all client tests.

### Finish
- [x] Run full tests, content validation, native probes and independent review.
- [x] Record measurements and limitations; package 1.3.7, verify ZIP matches source.
